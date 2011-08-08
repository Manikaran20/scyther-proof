{-# LANGUAGE DeriveDataTypeable #-}
module Scyther.Formula (
-- * Data Types
    Atom(..)
  , Formula(..)

-- ** Construction
  , substAtom
  , relabelTIDs

-- ** Queries
  , hasQuantifiers
  , conjuncts
  , conjunctionToAtoms
  , isTypingFormula
  , destTypingFormula
  , atomTIDs
  , findRole

-- * Pretty Printing
  , isaCompr
  , isaUncompr
  , sptAtom
  , isaAtom
  , isaFormula
  , sptFormula
) where

import Data.Maybe
import Data.Data

import Control.Applicative as App
import Control.Monad
import Control.Monad.State
import Control.Monad.Reader

import Text.Isar

import Scyther.Protocol
import Scyther.Message
import Scyther.Equalities as E
import Scyther.Event
import Scyther.Typing

------------------------------------------------------------------------------
-- Data Types
------------------------------------------------------------------------------

-- | A representable logical atom.
data Atom =
    AFalse                  -- ^ 'False' in Isabelle.
  | AEq AnyEq               -- ^ An equality
  | AEv Event               -- ^ An event must have happened.
  | AEvOrd (Event, Event)   -- ^ An event order.
  | ACompr Message          -- ^ A compromised agent variable.
  | AUncompr Message        -- ^ An uncompromised agent variable.
  | AHasType MVar Type      -- ^ A claim that a variable is of the given type;
  | ATyping Typing          -- ^ A claim that the current state of a protocol is
                            --   approximated by the given typing.
  | AReachable Protocol     -- ^ A claim that the current state is reachable.
  deriving( Eq, Show, Ord, Data, Typeable )

-- | A representable logical formula. Currently these are monotonic formula.
data Formula = 
    FAtom Atom
  | FConj Formula Formula
  | FExists (Either TID AgentId) Formula
  deriving( Eq, Show, Ord, Data, Typeable )

-- Queries on the structure of the formula
------------------------------------------

-- | A formula is a single atom claiming well-typedness.
isTypingFormula :: Formula -> Bool
isTypingFormula = isJust . destTypingFormula

-- | Extract the typing from a singleton well-typedness formula.
destTypingFormula :: Formula -> Maybe Typing
destTypingFormula (FAtom (ATyping typ)) = return typ
destTypingFormula _                     = mzero

-- | Relabel quantified TIDs according to the given list of labels.
relabelTIDs :: [TID] -> Formula -> Formula
relabelTIDs tids0 formula = 
  runReader (evalStateT (go formula) tids0) (Mapping E.empty)
  where
  go (FAtom atom) = FAtom <$> ((substAtom . getMappingEqs) <$> ask <*> pure atom)
  go (FConj l r)  = FConj <$> go l <*> go r
  go (FExists (Left tid) inner) = do
    tids <- get
    case tids of
      []         -> error "relabelTIDs: out of labels"
      tid':tids' -> do 
         put tids'
         FExists (Left tid') <$> local (addTIDMapping tid tid') (go inner)
  go (FExists q@(Right _) inner) = FExists q <$> go inner


-- | Compute the threads associated to the given atom.
atomTIDs :: Atom -> [TID]
atomTIDs AFalse         = mzero
atomTIDs (ATyping _)    = mzero
atomTIDs (AReachable _) = mzero
atomTIDs (AEv    e)     = evTIDs e
atomTIDs (AEvOrd ord)   = evOrdTIDs ord
atomTIDs (ACompr m)     = msgTIDs m
atomTIDs (AUncompr m)   = msgTIDs m
atomTIDs (AHasType v _) = return $ mvarTID v
atomTIDs (AEq eq)       = anyEqTIDs eq
    

-- Substitution
---------------

-- | Substitute all variables in an atom.
-- 
-- NOTE: A 'HasType' atom will only have its thread identifier substituted, but
-- not the whole message variable.
substAtom :: Equalities -> Atom -> Atom
substAtom eqs atom = case atom of
  AFalse         -> atom
  AEq eq         -> AEq      $ substAnyEq   eqs eq
  AEv ev         -> AEv      $ substEv      eqs ev
  AEvOrd ord     -> AEvOrd   $ substEvOrd   eqs ord
  ACompr m       -> ACompr   $ substMsg     eqs m
  AUncompr m     -> AUncompr $ substMsg     eqs m
  AHasType mv ty -> AHasType (mapMVar (substLocalId eqs) mv) ty
  ATyping _      -> atom
  AReachable _   -> atom


-- Queries
----------

{-
-- | True iff the atom is a well-typedness atom.
isTypeInvariant :: Atom -> Bool
isTypeInvariant (ATyping _) = True
isTypeInvariant _           = False
-}

-- | True iff the formula does contain an existential quantifier.
hasQuantifiers :: Formula -> Bool
hasQuantifiers = isNothing . conjunctionToAtoms

-- | Convert a formula consisting of conjunctions only to a list of atoms. Uses
-- 'fail' for error reporting.
conjunctionToAtoms :: MonadPlus m => Formula -> m [Atom]
conjunctionToAtoms (FAtom a)     = return [a]
conjunctionToAtoms (FConj f1 f2) = 
  (++) `liftM` conjunctionToAtoms f1 `ap` conjunctionToAtoms f2
conjunctionToAtoms _             = 
  fail "conjunctionToAtoms: existential quantifier encountered."

-- | Split all toplevel conjunctions.
conjuncts :: Formula -> [Formula]
conjuncts (FConj f1 f2) = conjuncts f1 ++ conjuncts f2
conjuncts f             = pure f

-- | Find the first conjoined thread to role equality for this thread, if there
-- is any.
findRole :: TID -> Formula -> Maybe Role
findRole tid = go
  where
    go (FAtom (AEq (TIDRoleEq (tid', role))))
        | tid == tid' = return role
        | otherwise   = mzero
    go (FAtom _)     = mzero
    go (FConj f1 f2) = go f1 `mplus` go f2
    go (FExists v f)
        | Left tid == v = mzero
        | otherwise     = go f


------------------------------------------------------------------------------
-- Pretty Printing
------------------------------------------------------------------------------

-- | A compromised agent variable in Isar format.
isaCompr :: IsarConf -> Message -> Doc
isaCompr conf m = text "RLKR" <> parens (isar conf m) <-> isaIn conf <-> text "reveals t"

-- | An uncompromised agent variable in Isar format.
isaUncompr :: IsarConf -> Message -> Doc
isaUncompr conf m = text "RLKR" <> parens (isar conf m) <-> isaNotIn conf <-> text "reveals t"

-- | A compromised agent variable in security protocol theory format.
sptCompr :: Message -> Doc
sptCompr m = text "compromised" <> parens (sptMessage m)

-- | An uncompromised agent variable in security protocol theory format.
sptUncompr :: Message -> Doc
sptUncompr m = text "uncompromised" <> parens (sptMessage m)

-- | Pretty print an atom in Isar format.
isaAtom :: IsarConf -> Mapping -> Atom -> Doc
isaAtom conf mapping atom = case atom of
    AFalse         -> text "False"
    AEq eq         -> ppIsar eq
    AEv ev         -> isaEvent    conf mapping ev
    AEvOrd ord     -> isaEventOrd conf mapping ord
    ACompr av      -> isaCompr   conf av
    AUncompr av    -> isaUncompr conf av
    AHasType mv ty -> let tid     = mvarTID mv
                          optRole = threadRole tid (getMappingEqs mapping)
                      in ppIsar mv <-> isaIn conf <-> 
                         isaType conf optRole ty <-> ppIsar (mvarTID mv) <-> 
                         isaExecutionSystemState conf
    ATyping _      -> text "well-typed"
    AReachable p   -> 
      text "(t,r,s)" <-> isaIn conf <-> text "reachable" <-> text (protoName p)
  where
    ppIsar :: Isar a => a -> Doc
    ppIsar = isar conf


-- | Pretty print an atom in security protocol theory format.
sptAtom :: Mapping -> Atom -> Doc
sptAtom mapping atom = case atom of
    AFalse         -> text "False"
    AEq eq         -> sptAnyEq eq
    AEv ev         -> sptEvent    mapping ev
    AEvOrd (e1,e2) -> sptEventOrd mapping [e1,e2]
    ACompr av      -> sptCompr   av
    AUncompr av    -> sptUncompr av
    AHasType mv ty -> let optRole = threadRole (mvarTID mv) (getMappingEqs mapping)
                      in  sptMVar mv <-> text "::" <-> sptType optRole ty
    ATyping typ    -> sptTyping typ
    AReachable p   -> text "reachable" <-> text (protoName p)


-- | A formula in Isar format.
isaFormula :: IsarConf -> Mapping -> Formula -> Doc
isaFormula conf = pp
  where
    ppIsar :: Isar a => a -> Doc
    ppIsar = isar conf
    
    pp m (FAtom atom)  = isaAtom conf m atom
    pp m (FConj f1 f2) = sep [pp m f1 <-> isaAnd conf, pp m f2]
    pp m (FExists v f) = parens $
        sep [ isaExists conf <-> (either ppIsar ppIsar v) <> char '.'
            , nest 2 $ pp m' f
            ]
      where
        m' = case v of
               Left tid -> maybe id (addTIDRoleMapping tid) (findRole tid f) m
               Right _  -> m

-- | A formula in security protocol theory format.
sptFormula :: Mapping -> Formula -> Doc
sptFormula = pp
  where
    pp m (FAtom atom)  = sptAtom m atom
    pp m (FConj f1 f2) = sep [pp m f1 <-> char '&', pp m f2]
    pp m (FExists v f) = parens $
        sep [ char '?' <-> (either sptTID sptAgentId v) <> char '.'
            , nest 2 $ pp m' f
            ]
      where
        m' = case v of
               Left tid -> maybe id (addTIDRoleMapping tid) (findRole tid f) m
               Right _  -> m

