{-# LANGUAGE TypeSynonymInstances, DeriveDataTypeable #-}
-- | Building typing invariants for security protocol in order to enable
-- verification in an untyped model.
module Scyther.Typing (
  -- * Data types
    Type(..)
  , Typing(..)

  -- ** Construction typings
  , mscTyping

  -- ** Pretty Printing
  , isaType
  , isaOptType
  , sptType
  , sptOptType
  , sptTyping
) where

import qualified Data.Set as S
import qualified Data.Map as M
import Data.DAG.Simple
import Data.Data

import Control.Basics
import Control.Monad.State

import Scyther.Protocol
import Scyther.Message
import qualified Scyther.Equalities as E
import Text.Isar


data Type =
    AgentT 
  | ConstT Id
  | NonceT Role Id
  | HashT Type
  | EncT  Type Type
  | TupT Type Type
  | SymKT Type Type
  | AsymPKT Type
  | AsymSKT Type
  | KnownT RoleStep
  | SumT Type Type
  deriving( Eq, Ord, Show, Data, Typeable )

-- | A type assignment for variables of several roles.
data Typing = 
    WeaklyAtomic
  | Typing (M.Map (Id, Role) Type)
  deriving( Eq, Ord, Show, Data, Typeable )

-- | Compute a typing from the message sequence chart of the protocol
-- implicitly given by the corresponding labels.
--
-- FIXME: This is quite a hack and could be done much better: do it!
mscTyping :: Protocol -> Maybe Typing
mscTyping proto = 
    fmap Typing $ (`execStateT` M.empty) $ foldM typeStep E.empty steps
  where
    roleeqs = M.fromList $ zip [1..] (protoRoles proto)
    rolemap = M.fromList $ zip (protoRoles proto) [1..]
    steps = map (second (rolemap M.!)) . toposort $ protoOrd proto

    typeStep eqs (Send _ _, _) = do
        return eqs
    typeStep eqs (recv@(Recv lR ptR), tidR) =
        case [ send | send@(Send lS _, _) <- steps, lS == lR ] of
          []                   -> do
              -- no matching send: assume intruder knows all message variables
              -- in the received pattern that are not yet mapped.
              sequence_ $ do PMVar v <- S.toList $ subpatterns ptR
                             return (knownAtRecv v)
              return eqs
          ((Send _ ptS, tidS):_) -> do
              eqs' <- lift $ E.solve [E.MsgEq (inst tidR ptR, inst tidS ptS)] eqs
              mapM_ typeMVar (E.getMVarEqs eqs')
              -- variables not mapped yet are mapped to they known type.
              sequence_ $ do PMVar v <- S.toList $ subpatterns ptR
                             return (knownAtRecv v)
              return eqs'
          _ -> error "mscTyping: the impossible happened"
      where
        typeMVar (MVar (LocalId (v, vTid)), m) 
          | vTid == tidR && PMVar v `S.member` splitpatterns ptR =
              noteType (KnownT recv)
          | otherwise = 
              noteType $ maybe (KnownT recv) (SumT (KnownT recv)) (typeMsg m)
          where
            noteType = modify . M.insertWith keepSimpler (v, roleeqs M.! vTid)
            -- prefer non-sum-types and then the existing one
            keepSimpler _  x@(KnownT _) = x
            keepSimpler x@(KnownT _) _  = x
            keepSimpler _            x  = x

        knownAtRecv v = 
            modify (M.insertWith keepExisting (v, roleeqs M.! tidR) (KnownT recv))
          where
            keepExisting _new old = old
 
        typeMsg (MFresh (Fresh fr)) = pure $ NonceT (roleeqs M.! lidTID fr) (lidId fr)
        typeMsg (MConst c)    = pure $ ConstT c
        typeMsg (MAVar _)     = pure $ AgentT
        typeMsg (MMVar _)     = Nothing
        typeMsg (MHash m)     = HashT   <$> typeMsg m
        typeMsg (MTup m1 m2)  = TupT    <$> typeMsg m1 <*> typeMsg m2
        typeMsg (MEnc m1 m2)  = EncT    <$> typeMsg m1 <*> typeMsg m2
        typeMsg (MSymK m1 m2) = SymKT   <$> typeMsg m1 <*> typeMsg m2
        typeMsg (MAsymPK m)   = AsymPKT <$> typeMsg m
        typeMsg (MAsymSK m)   = AsymSKT <$> typeMsg m
        typeMsg (MAgent _)    = error $ "mscTyping: agent variable encountered"
        typeMsg (MInvKey _)   = error $ "mscTyping: key inversion encountered"
        typeMsg (MShrK _ _)   = error $ "mscTyping: bi-directional shared key encountered"

-- | Pretty print a type in Isar syntax; paramatrized over the role of the
-- variable that this type describes. This role is used for abbreviating role
-- steps by the 'role_label' constant symbols defined in Isabelle.
isaType :: IsarConf -> Maybe Role -> Type -> Doc
isaType conf optRole = go
  where
  go ty = case ty of
    AgentT        -> text "AgentT"
    ConstT i      -> parens $ text "ConstT" <-> isar conf i
    NonceT role i -> parens $ text "NonceT" <-> text (roleName role) <-> isar conf i
    HashT ty1     -> parens $ text "HashT" <-> go ty1
    EncT ty1 ty2  -> parens $ text "EncT" <-> go ty1 <-> go ty2
    TupT ty1 ty2  -> parens $ text "TupT" <-> go ty1 <-> go ty2
    AsymPKT ty1   -> parens $ text "PKT" <-> go ty1
    AsymSKT ty1   -> parens $ text "SKT" <-> go ty1
    SymKT ty1 ty2 -> parens $ text "KT" <-> go ty1 <-> go ty2
    KnownT step   -> parens $ text "KnownT" <-> isaRoleStep conf optRole step
    SumT ty1 ty2  -> parens $ text "SumT" <-> go ty1 <-> go ty2

-- | Pretty print a type that may be a weak atomicity type.
isaOptType :: IsarConf -> Maybe Role -> Maybe Type -> Doc
isaOptType _    _       Nothing   = text "weakly_atomic"
isaOptType conf optRole (Just ty) = isaType conf optRole ty

-- | Pretty print a type in security protocol theory format. If the role is
-- given then the type describes a variable of this role. The steps of this
-- role are abbreviated accordingly.
sptType :: Maybe Role -> Type -> Doc
sptType optRole = go
  where
  go ty = case ty of
    AgentT        -> text "Agent"
    ConstT i      -> text $ "'" ++ getId i ++ "'"
    NonceT role i -> text $ getId i ++ "@" ++ roleName role
    HashT ty1     -> text "h" <> parens (go ty1)
    EncT ty1 ty2  -> braces (go ty1) <> go ty2
    TupT ty1 ty2  -> parens (go ty1 <> comma <-> go ty2)
    AsymPKT ty1   -> text "pk" <> parens (go ty1)
    AsymSKT ty1   -> text "sk" <> parens (go ty1)
    SymKT ty1 ty2 -> text "k"  <> parens (go ty1 <> comma <-> go ty2)
    KnownT step   -> text "Known@" <> sptRoleStep optRole step
    SumT ty1 ty2  -> sep [parens (go ty1) <-> text "|", parens (go ty2)]

-- | Pretty print a type that may be a weak atomicity type in the security
-- protocol theory format.
sptOptType :: Maybe Role -> Maybe Type -> Doc
sptOptType _       Nothing   = text "weakly-atomic"
sptOptType optRole (Just ty) = sptType optRole ty


sptTyping :: Typing -> Doc
sptTyping WeaklyAtomic = text "weakly-atomic"
sptTyping (Typing typ) = vcat . map ppTyEq . M.toList $ typ
  where
    ppTyEq ((v,role),ty) = 
      sep [ text $ getId v ++ "@" ++ roleName role
          , nest 2 $ text "::" <-> sptType (Just role) ty ]

instance Isar Type where
  isar conf = isaType conf Nothing

instance Isar Typing where
  isar _    WeaklyAtomic = text "weakly-atomic"
  isar conf (Typing typ) = 
    ($$ rbrack) . vcat . zipWith (<->) seps . map ppTyEq . M.toList $ typ
    where
    seps = map char $ '[' : repeat ','
    ppTyEq ((v,role),ty) = parens $
      sep [ parens (text (roleName role) <> comma <-> isar conf v) <> comma
          , isaType conf (Just role) ty ]

