theory "nsl_cert_auto"
imports
  "../ESPLogic"
begin

role I
where "I =
  [ Send ''1'' ( Enc {| sLC ''1'', sLN ''ni'', sLAV ''I'' |}
                     ( sPK ''R'' )
               )
  , Recv ''2'' ( Enc {| sLC ''2'', sLN ''ni'', sLMV ''nr'',
                        sLAV ''R''
                     |}
                     ( sPK ''I'' )
               )
  , Send ''3'' ( Enc {| sLC ''3'', sLMV ''nr'' |} ( sPK ''R'' ) )
  ]"

role R
where "R =
  [ Recv ''1'' ( Enc {| sLC ''1'', sLMV ''ni'', sLAV ''I'' |}
                     ( sPK ''R'' )
               )
  , Send ''2'' ( Enc {| sLC ''2'', sLMV ''ni'', sLN ''nr'',
                        sLAV ''R''
                     |}
                     ( sPK ''I'' )
               )
  , Recv ''3'' ( Enc {| sLC ''3'', sLN ''nr'' |} ( sPK ''R'' ) )
  ]"

protocol ns_public
where "ns_public = { I, R }"

locale atomic_ns_public_state = atomic_state ns_public
locale ns_public_state = reachable_state ns_public

lemma (in atomic_ns_public_state) auto_I_sk_I:
  assumes facts:
    "roleMap r tid0 = Some I"
    "s(|AV ''I'' tid0|) ~: Compromised"
    "SK ( s(|AV ''I'' tid0|) ) : knows t"
  shows "False"
using facts proof(sources! " SK ( s(|AV ''I'' tid0|) ) ")
qed (insert facts, ((clarsimp, order?))+)?

lemma (in atomic_ns_public_state) auto_I_sk_R:
  assumes facts:
    "roleMap r tid0 = Some I"
    "s(|AV ''R'' tid0|) ~: Compromised"
    "SK ( s(|AV ''R'' tid0|) ) : knows t"
  shows "False"
using facts proof(sources! " SK ( s(|AV ''R'' tid0|) ) ")
qed (insert facts, ((clarsimp, order?))+)?

lemma (in atomic_ns_public_state) auto_R_sk_I:
  assumes facts:
    "roleMap r tid0 = Some R"
    "s(|AV ''I'' tid0|) ~: Compromised"
    "SK ( s(|AV ''I'' tid0|) ) : knows t"
  shows "False"
using facts proof(sources! " SK ( s(|AV ''I'' tid0|) ) ")
qed (insert facts, ((clarsimp, order?))+)?

lemma (in atomic_ns_public_state) auto_I_sec_ni:
  assumes facts:
    "roleMap r tid0 = Some I"
    "s(|AV ''I'' tid0|) ~: Compromised"
    "s(|AV ''R'' tid0|) ~: Compromised"
    "(tid0, I_1) : steps t"
    "LN ''ni'' tid0 : knows t"
  shows "False"
using facts proof(sources! " LN ''ni'' tid0 ")
  case I_1_ni note facts = facts this[simplified]
  thus ?thesis by (fastsimp dest: auto_I_sk_R intro: event_predOrdI)
next
  case (I_3_nr tid1) note facts = facts this[simplified]
  thus ?thesis proof(sources! "
                   Enc {| LC ''2'', LN ''ni'' tid1, LN ''ni'' tid0, s(|AV ''R'' tid1|)
                       |}
                       ( PK ( s(|AV ''I'' tid1|) ) ) ")
  qed (insert facts, ((clarsimp, order?))+)?
next
  case (R_2_ni tid1) note facts = facts this[simplified]
  thus ?thesis proof(sources! "
                   Enc {| LC ''1'', LN ''ni'' tid0, s(|AV ''I'' tid1|) |}
                       ( PK ( s(|AV ''R'' tid1|) ) ) ")
    case I_1_enc note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: auto_I_sk_I intro: event_predOrdI)
  qed (insert facts, ((clarsimp, order?))+)?
qed

lemma (in atomic_ns_public_state) auto_R_sec_nr:
  assumes facts:
    "roleMap r tid0 = Some R"
    "s(|AV ''I'' tid0|) ~: Compromised"
    "s(|AV ''R'' tid0|) ~: Compromised"
    "(tid0, R_2) : steps t"
    "LN ''nr'' tid0 : knows t"
  shows "False"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis proof(sources! " LN ''nr'' tid0 ")
    case (I_3_nr tid1) note facts = facts this[simplified]
    thus ?thesis proof(sources! "
                     Enc {| LC ''2'', LN ''ni'' tid1, LN ''nr'' tid0, s(|AV ''R'' tid1|)
                         |}
                         ( PK ( s(|AV ''I'' tid1|) ) ) ")
      case R_2_enc note facts = facts this[simplified]
      thus ?thesis by (fastsimp dest: auto_I_sk_R intro: event_predOrdI)
    qed (insert facts, ((clarsimp, order?))+)?
  next
    case (R_2_ni tid1) note facts = facts this[simplified]
    thus ?thesis proof(sources! "
                     Enc {| LC ''1'', LN ''nr'' tid0, s(|AV ''I'' tid1|) |}
                         ( PK ( s(|AV ''R'' tid1|) ) ) ")
    qed (insert facts, ((clarsimp, order?))+)?
  next
    case R_2_nr note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: auto_R_sk_I intro: event_predOrdI)
  qed
qed

lemma (in atomic_ns_public_state) auto_I_sec_nr:
  assumes facts:
    "roleMap r tid0 = Some I"
    "s(|AV ''I'' tid0|) ~: Compromised"
    "s(|AV ''R'' tid0|) ~: Compromised"
    "(tid0, I_2) : steps t"
    "s(|MV ''nr'' tid0|) : knows t"
  shows "False"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis proof(sources! "
                   Enc {| LC ''2'', LN ''ni'' tid0, s(|MV ''nr'' tid0|),
                          s(|AV ''R'' tid0|)
                       |}
                       ( PK ( s(|AV ''I'' tid0|) ) ) ")
    case fake note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: auto_I_sec_ni intro: event_predOrdI)
  next
    case (R_2_enc tid1) note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: auto_R_sec_nr intro: event_predOrdI)
  qed (insert facts, ((clarsimp, order?))+)?
qed

lemma (in ns_public_state) weak_atomicity:
  "complete (t,r,s) atomicAnn"
proof (cases rule: complete_atomicAnnI[completeness_cases_rule])
  case (I_2_nr t r s tid0 \<alpha>) note facts = this
  then interpret state: atomic_state ns_public t r s
    by unfold_locales assumption+
  let ?s' = "extendS s \<alpha>"
  show ?case using facts
  proof(sources! "
      Enc {| LC ''2'', LN ''ni'' tid0, ?s'(|MV ''nr'' tid0|),
             ?s'(|AV ''R'' tid0|)
          |}
          ( PK ( ?s'(|AV ''I'' tid0|) ) ) ")
  qed (insert facts, ((clarsimp, order?) | (fastsimp simp: atomicAnn_def dest: state.extract_knows_hyps))+)?
next
  case (R_1_ni t r s tid0 \<alpha>) note facts = this
  then interpret state: atomic_state ns_public t r s
    by unfold_locales assumption+
  let ?s' = "extendS s \<alpha>"
  show ?case using facts
  proof(sources! "
      Enc {| LC ''1'', ?s'(|MV ''ni'' tid0|), ?s'(|AV ''I'' tid0|) |}
          ( PK ( ?s'(|AV ''R'' tid0|) ) ) ")
  qed (insert facts, ((clarsimp, order?) | (fastsimp simp: atomicAnn_def dest: state.extract_knows_hyps))+)?
qed

lemma (in atomic_ns_public_state) I_ni_secrecy:
  assumes facts:
    "roleMap r tid0 = Some I"
    "s(|AV ''I'' tid0|) ~: Compromised"
    "s(|AV ''R'' tid0|) ~: Compromised"
    "(tid0, I_3) : steps t"
    "LN ''ni'' tid0 : knows t"
  shows "False"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis by (fastsimp dest: auto_I_sec_ni intro: event_predOrdI)
qed

lemma (in atomic_ns_public_state) R_ni_secrecy:
  assumes facts:
    "roleMap r tid0 = Some R"
    "s(|AV ''I'' tid0|) ~: Compromised"
    "s(|AV ''R'' tid0|) ~: Compromised"
    "(tid0, R_3) : steps t"
    "s(|MV ''ni'' tid0|) : knows t"
  shows "False"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis proof(sources! "
                   Enc {| LC ''3'', LN ''nr'' tid0 |} ( PK ( s(|AV ''R'' tid0|) ) ) ")
    case fake note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: auto_R_sec_nr intro: event_predOrdI)
  next
    case (I_3_enc tid1) note facts = facts this[simplified]
    thus ?thesis proof(sources! "
                     Enc {| LC ''2'', LN ''ni'' tid1, LN ''nr'' tid0, s(|AV ''R'' tid0|)
                         |}
                         ( PK ( s(|AV ''I'' tid1|) ) ) ")
      case fake note facts = facts this[simplified]
      thus ?thesis by (fastsimp dest: auto_R_sec_nr intro: event_predOrdI)
    next
      case R_2_enc note facts = facts this[simplified]
      thus ?thesis by (fastsimp dest: auto_I_sec_ni intro: event_predOrdI)
    qed (insert facts, ((clarsimp, order?))+)?
  qed (insert facts, ((clarsimp, order?))+)?
qed

lemma (in atomic_ns_public_state) I_nr_secrecy:
  assumes facts:
    "roleMap r tid0 = Some I"
    "s(|AV ''I'' tid0|) ~: Compromised"
    "s(|AV ''R'' tid0|) ~: Compromised"
    "(tid0, I_3) : steps t"
    "s(|MV ''nr'' tid0|) : knows t"
  shows "False"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis by (fastsimp dest: auto_I_sec_nr intro: event_predOrdI)
qed

lemma (in atomic_ns_public_state) R_nr_secrecy:
  assumes facts:
    "roleMap r tid0 = Some R"
    "s(|AV ''I'' tid0|) ~: Compromised"
    "s(|AV ''R'' tid0|) ~: Compromised"
    "(tid0, R_3) : steps t"
    "LN ''nr'' tid0 : knows t"
  shows "False"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis by (fastsimp dest: auto_R_sec_nr intro: event_predOrdI)
qed

lemma (in atomic_ns_public_state) I_ni_agree:
  assumes facts:
    "roleMap r tid1 = Some I"
    "s(|AV ''I'' tid1|) ~: Compromised"
    "s(|AV ''R'' tid1|) ~: Compromised"
    "(tid1, I_3) : steps t"
  shows
    "? tid2.
       roleMap r tid2 = Some R &
       s(|AV ''I'' tid2|) = s(|AV ''I'' tid1|) &
       s(|AV ''R'' tid2|) = s(|AV ''R'' tid1|) &
       s(|MV ''ni'' tid2|) = LN ''ni'' tid1 &
       s(|MV ''nr'' tid1|) = LN ''nr'' tid2"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis proof(sources! "
                   Enc {| LC ''2'', LN ''ni'' tid1, s(|MV ''nr'' tid1|),
                          s(|AV ''R'' tid1|)
                       |}
                       ( PK ( s(|AV ''I'' tid1|) ) ) ")
    case fake note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: auto_I_sec_ni intro: event_predOrdI)
  next
    case (R_2_enc tid2) note facts = facts this[simplified]
    thus ?thesis by force
  qed (insert facts, ((clarsimp, order?))+)?
qed

lemma (in atomic_ns_public_state) R_ni_agree:
  assumes facts:
    "roleMap r tid1 = Some R"
    "s(|AV ''I'' tid1|) ~: Compromised"
    "s(|AV ''R'' tid1|) ~: Compromised"
    "(tid1, R_3) : steps t"
  shows
    "? tid2.
       roleMap r tid2 = Some I &
       s(|AV ''I'' tid2|) = s(|AV ''I'' tid1|) &
       s(|AV ''R'' tid2|) = s(|AV ''R'' tid1|) &
       s(|MV ''ni'' tid1|) = LN ''ni'' tid2 &
       s(|MV ''nr'' tid2|) = LN ''nr'' tid1"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis proof(sources! "
                   Enc {| LC ''3'', LN ''nr'' tid1 |} ( PK ( s(|AV ''R'' tid1|) ) ) ")
    case fake note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: auto_R_sec_nr intro: event_predOrdI)
  next
    case (I_3_enc tid2) note facts = facts this[simplified]
    thus ?thesis proof(sources! "
                     Enc {| LC ''2'', LN ''ni'' tid2, LN ''nr'' tid1, s(|AV ''R'' tid1|)
                         |}
                         ( PK ( s(|AV ''I'' tid2|) ) ) ")
      case fake note facts = facts this[simplified]
      thus ?thesis by (fastsimp dest: auto_R_sec_nr intro: event_predOrdI)
    next
      case R_2_enc note facts = facts this[simplified]
      thus ?thesis by force
    qed (insert facts, ((clarsimp, order?))+)?
  qed (insert facts, ((clarsimp, order?))+)?
qed

end