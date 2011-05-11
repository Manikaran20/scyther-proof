theory "TLS_paulson_cert_auto"
imports
  "../ESPLogic"
begin

role C
where "C =
  [ Send ''1'' {| sLAV ''C'', sLN ''nc'', sLN ''sid'', sLN ''pc'' |}
  , Recv ''2'' {| sLMV ''ns'', sLN ''sid'', sLMV ''ps'' |}
  , Send ''3'' {| Enc {| sLC ''TT0'', sLN ''pms'' |} ( sPK ''S'' ),
                  Enc {| sLC ''TT1'',
                         Hash {| sLC ''TT2'', sLMV ''ns'', sLAV ''S'', sLN ''pms'' |}
                      |}
                      ( sSK ''C'' ),
                  Enc {| sLC ''TT3'', sLN ''sid'',
                         Hash {| sLC ''TT4'', sLC ''PRF'', sLN ''pms'', sLN ''nc'',
                                 sLMV ''ns''
                              |},
                         sLN ''nc'', sLN ''pc'', sLAV ''C'', sLMV ''ns'', sLMV ''ps'',
                         sLAV ''S''
                      |}
                      ( Hash {| sLC ''clientKey'', sLN ''nc'', sLMV ''ns'',
                                Hash {| sLC ''TT4'', sLC ''PRF'', sLN ''pms'', sLN ''nc'',
                                        sLMV ''ns''
                                     |}
                             |}
                      )
               |}
  , Recv ''4'' ( Enc {| sLC ''TT3'', sLN ''sid'',
                        Hash {| sLC ''TT4'', sLC ''PRF'', sLN ''pms'', sLN ''nc'',
                                sLMV ''ns''
                             |},
                        sLN ''nc'', sLN ''pc'', sLAV ''C'', sLMV ''ns'', sLMV ''ps'',
                        sLAV ''S''
                     |}
                     ( Hash {| sLC ''serverKey'', sLN ''nc'', sLMV ''ns'',
                               Hash {| sLC ''TT4'', sLC ''PRF'', sLN ''pms'', sLN ''nc'',
                                       sLMV ''ns''
                                    |}
                            |}
                     )
               )
  ]"

role S
where "S =
  [ Recv ''1'' {| sLAV ''C'', sLMV ''nc'', sLMV ''sid'', sLMV ''pc''
               |}
  , Send ''2'' {| sLN ''ns'', sLMV ''sid'', sLN ''ps'' |}
  , Recv ''3'' {| Enc {| sLC ''TT0'', sLMV ''pms'' |} ( sPK ''S'' ),
                  Enc {| sLC ''TT1'',
                         Hash {| sLC ''TT2'', sLN ''ns'', sLAV ''S'', sLMV ''pms'' |}
                      |}
                      ( sSK ''C'' ),
                  Enc {| sLC ''TT3'', sLMV ''sid'',
                         Hash {| sLC ''TT4'', sLC ''PRF'', sLMV ''pms'', sLMV ''nc'',
                                 sLN ''ns''
                              |},
                         sLMV ''nc'', sLMV ''pc'', sLAV ''C'', sLN ''ns'', sLN ''ps'',
                         sLAV ''S''
                      |}
                      ( Hash {| sLC ''clientKey'', sLMV ''nc'', sLN ''ns'',
                                Hash {| sLC ''TT4'', sLC ''PRF'', sLMV ''pms'', sLMV ''nc'',
                                        sLN ''ns''
                                     |}
                             |}
                      )
               |}
  , Send ''4'' ( Enc {| sLC ''TT3'', sLMV ''sid'',
                        Hash {| sLC ''TT4'', sLC ''PRF'', sLMV ''pms'', sLMV ''nc'',
                                sLN ''ns''
                             |},
                        sLMV ''nc'', sLMV ''pc'', sLAV ''C'', sLN ''ns'', sLN ''ps'',
                        sLAV ''S''
                     |}
                     ( Hash {| sLC ''serverKey'', sLMV ''nc'', sLN ''ns'',
                               Hash {| sLC ''TT4'', sLC ''PRF'', sLMV ''pms'', sLMV ''nc'',
                                       sLN ''ns''
                                    |}
                            |}
                     )
               )
  ]"

protocol TLS
where "TLS = { C, S }"

locale atomic_TLS_state = atomic_state TLS
locale TLS_state = reachable_state TLS

lemma (in atomic_TLS_state) auto_nc:
  assumes facts:
    "roleMap r tid0 = Some C"
    "LN ''nc'' tid0 : knows t"
  shows "predOrd t (St(tid0, C_1)) (Ln(LN ''nc'' tid0))"
using facts proof(sources! " LN ''nc'' tid0 ")
  case C_1_nc note facts = facts this[simplified]
  thus ?thesis by force
next
  case C_3_nc note facts = facts this[simplified]
  thus ?thesis by force
qed (insert facts, ((clarsimp, order?))+)?

lemma (in atomic_TLS_state) auto_sid:
  assumes facts:
    "roleMap r tid0 = Some C"
    "LN ''sid'' tid0 : knows t"
  shows "predOrd t (St(tid0, C_1)) (Ln(LN ''sid'' tid0))"
using facts proof(sources! " LN ''sid'' tid0 ")
  case C_1_sid note facts = facts this[simplified]
  thus ?thesis by force
qed (insert facts, ((clarsimp, order?))+)?

lemma (in atomic_TLS_state) auto_ns:
  assumes facts:
    "roleMap r tid0 = Some S"
    "LN ''ns'' tid0 : knows t"
  shows "predOrd t (St(tid0, S_2)) (Ln(LN ''ns'' tid0))"
using facts proof(sources! " LN ''ns'' tid0 ")
  case S_2_ns note facts = facts this[simplified]
  thus ?thesis by force
next
  case S_4_ns note facts = facts this[simplified]
  thus ?thesis by force
qed (insert facts, ((clarsimp, order?))+)?

lemma (in atomic_TLS_state) auto_C_sk_S:
  assumes facts:
    "roleMap r tid0 = Some C"
    "s(|AV ''S'' tid0|) ~: Compromised"
    "SK ( s(|AV ''S'' tid0|) ) : knows t"
  shows "False"
using facts proof(sources! " SK ( s(|AV ''S'' tid0|) ) ")
qed (insert facts, ((clarsimp, order?))+)?

lemma (in atomic_TLS_state) auto_S_sk_C:
  assumes facts:
    "roleMap r tid0 = Some S"
    "s(|AV ''C'' tid0|) ~: Compromised"
    "SK ( s(|AV ''C'' tid0|) ) : knows t"
  shows "False"
using facts proof(sources! " SK ( s(|AV ''C'' tid0|) ) ")
qed (insert facts, ((clarsimp, order?))+)?

lemma (in atomic_TLS_state) auto_C_sec_pms:
  assumes facts:
    "roleMap r tid0 = Some C"
    "s(|AV ''C'' tid0|) ~: Compromised"
    "s(|AV ''S'' tid0|) ~: Compromised"
    "(tid0, C_3) : steps t"
    "LN ''pms'' tid0 : knows t"
  shows "False"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis proof(sources! " LN ''pms'' tid0 ")
    case C_3_pms note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: auto_C_sk_S intro: event_predOrdI)
  qed (insert facts, ((clarsimp, order?))+)?
qed

lemma (in atomic_TLS_state) auto_S_sec_pms:
  assumes facts:
    "roleMap r tid0 = Some S"
    "s(|AV ''C'' tid0|) ~: Compromised"
    "s(|AV ''S'' tid0|) ~: Compromised"
    "(tid0, S_3) : steps t"
    "s(|MV ''pms'' tid0|) : knows t"
  shows "False"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis proof(sources! "
                   Enc {| LC ''TT1'',
                          Hash {| LC ''TT2'', LN ''ns'' tid0, s(|AV ''S'' tid0|),
                                  s(|MV ''pms'' tid0|)
                               |}
                       |}
                       ( SK ( s(|AV ''C'' tid0|) ) ) ")
    case fake note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: auto_S_sk_C intro: event_predOrdI)
  next
    case (C_3_enc tid1) note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: auto_C_sec_pms intro: event_predOrdI)
  qed (insert facts, ((clarsimp, order?))+)?
qed

lemma (in TLS_state) weak_atomicity:
  "complete (t,r,s) atomicAnn"
proof (cases rule: complete_atomicAnnI[completeness_cases_rule])
  case (C_2_ns t r s tid0 \<alpha>) note facts = this
  then interpret state: atomic_state TLS t r s
    by unfold_locales assumption+
  let ?s' = "extendS s \<alpha>"
  show ?case using facts
  by (fastsimp simp: atomicAnn_def dest: state.extract_knows_hyps)
next
  case (C_2_ps t r s tid0 \<alpha>) note facts = this
  then interpret state: atomic_state TLS t r s
    by unfold_locales assumption+
  let ?s' = "extendS s \<alpha>"
  show ?case using facts
  by (fastsimp simp: atomicAnn_def dest: state.extract_knows_hyps)
next
  case (S_1_nc t r s tid0 \<alpha>) note facts = this
  then interpret state: atomic_state TLS t r s
    by unfold_locales assumption+
  let ?s' = "extendS s \<alpha>"
  show ?case using facts
  by (fastsimp simp: atomicAnn_def dest: state.extract_knows_hyps)
next
  case (S_1_pc t r s tid0 \<alpha>) note facts = this
  then interpret state: atomic_state TLS t r s
    by unfold_locales assumption+
  let ?s' = "extendS s \<alpha>"
  show ?case using facts
  by (fastsimp simp: atomicAnn_def dest: state.extract_knows_hyps)
next
  case (S_1_sid t r s tid0 \<alpha>) note facts = this
  then interpret state: atomic_state TLS t r s
    by unfold_locales assumption+
  let ?s' = "extendS s \<alpha>"
  show ?case using facts
  by (fastsimp simp: atomicAnn_def dest: state.extract_knows_hyps)
next
  case (S_3_pms t r s tid0 \<alpha>) note facts = this
  then interpret state: atomic_state TLS t r s
    by unfold_locales assumption+
  let ?s' = "extendS s \<alpha>"
  show ?case using facts
  proof(sources! "
      Enc {| LC ''TT0'', ?s'(|MV ''pms'' tid0|) |}
          ( PK ( ?s'(|AV ''S'' tid0|) ) ) ")
  qed (insert facts, ((clarsimp, order?) | (fastsimp simp: atomicAnn_def dest: state.extract_knows_hyps))+)?
qed

lemma (in atomic_TLS_state) C_clientKey_sec:
  assumes facts:
    "roleMap r tid0 = Some C"
    "s(|AV ''S'' tid0|) ~: Compromised"
    "Hash {| LC ''clientKey'', LN ''nc'' tid0, s(|MV ''ns'' tid0|),
             Hash {| LC ''TT4'', LC ''PRF'', LN ''pms'' tid0, LN ''nc'' tid0,
                     s(|MV ''ns'' tid0|)
                  |}
          |} : knows t"
  shows "False"
using facts proof(sources! "
                Hash {| LC ''clientKey'', LN ''nc'' tid0, s(|MV ''ns'' tid0|),
                        Hash {| LC ''TT4'', LC ''PRF'', LN ''pms'' tid0, LN ''nc'' tid0,
                                s(|MV ''ns'' tid0|)
                             |}
                     |} ")
  case fake note facts = facts this[simplified]
  thus ?thesis proof(sources! "
                   Hash {| LC ''TT4'', LC ''PRF'', LN ''pms'' tid0, LN ''nc'' tid0,
                           s(|MV ''ns'' tid0|)
                        |} ")
    case fake note facts = facts this[simplified]
    thus ?thesis proof(sources! " LN ''pms'' tid0 ")
      case C_3_pms note facts = facts this[simplified]
      thus ?thesis by (fastsimp dest: auto_C_sk_S intro: event_predOrdI)
    qed (insert facts, ((clarsimp, order?))+)?
  next
    case (S_4_hash tid1) note facts = facts this[simplified]
    thus ?thesis proof(sources! "
                     Hash {| LC ''serverKey'', LN ''nc'' tid0, LN ''ns'' tid1,
                             Hash {| LC ''TT4'', LC ''PRF'', LN ''pms'' tid0, LN ''nc'' tid0,
                                     LN ''ns'' tid1
                                  |}
                          |} ")
    qed (insert facts, ((clarsimp, order?))+)?
  qed (insert facts, ((clarsimp, order?))+)?
qed (insert facts, ((clarsimp, order?))+)?

lemma (in atomic_TLS_state) C_serverKey_sec:
  assumes facts:
    "roleMap r tid0 = Some C"
    "s(|AV ''S'' tid0|) ~: Compromised"
    "Hash {| LC ''serverKey'', LN ''nc'' tid0, s(|MV ''ns'' tid0|),
             Hash {| LC ''TT4'', LC ''PRF'', LN ''pms'' tid0, LN ''nc'' tid0,
                     s(|MV ''ns'' tid0|)
                  |}
          |} : knows t"
  shows "False"
using facts proof(sources! "
                Hash {| LC ''serverKey'', LN ''nc'' tid0, s(|MV ''ns'' tid0|),
                        Hash {| LC ''TT4'', LC ''PRF'', LN ''pms'' tid0, LN ''nc'' tid0,
                                s(|MV ''ns'' tid0|)
                             |}
                     |} ")
  case fake note facts = facts this[simplified]
  thus ?thesis proof(sources! "
                   Hash {| LC ''TT4'', LC ''PRF'', LN ''pms'' tid0, LN ''nc'' tid0,
                           s(|MV ''ns'' tid0|)
                        |} ")
    case fake note facts = facts this[simplified]
    thus ?thesis proof(sources! " LN ''pms'' tid0 ")
      case C_3_pms note facts = facts this[simplified]
      thus ?thesis by (fastsimp dest: auto_C_sk_S intro: event_predOrdI)
    qed (insert facts, ((clarsimp, order?))+)?
  next
    case C_3_hash note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: C_clientKey_sec intro: event_predOrdI)
  qed (insert facts, ((clarsimp, order?))+)?
qed (insert facts, ((clarsimp, order?))+)?

lemma (in atomic_TLS_state) S_clientKey_sec:
  assumes facts:
    "roleMap r tid0 = Some S"
    "s(|AV ''C'' tid0|) ~: Compromised"
    "s(|AV ''S'' tid0|) ~: Compromised"
    "(tid0, S_4) : steps t"
    "Hash {| LC ''clientKey'', s(|MV ''nc'' tid0|), LN ''ns'' tid0,
             Hash {| LC ''TT4'', LC ''PRF'', s(|MV ''pms'' tid0|),
                     s(|MV ''nc'' tid0|), LN ''ns'' tid0
                  |}
          |} : knows t"
  shows "False"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis proof(sources! "
                   Hash {| LC ''clientKey'', s(|MV ''nc'' tid0|), LN ''ns'' tid0,
                           Hash {| LC ''TT4'', LC ''PRF'', s(|MV ''pms'' tid0|),
                                   s(|MV ''nc'' tid0|), LN ''ns'' tid0
                                |}
                        |} ")
    case fake note facts = facts this[simplified]
    thus ?thesis proof(sources! "
                     Hash {| LC ''TT4'', LC ''PRF'', s(|MV ''pms'' tid0|),
                             s(|MV ''nc'' tid0|), LN ''ns'' tid0
                          |} ")
      case fake note facts = facts this[simplified]
      thus ?thesis by (fastsimp dest: auto_S_sec_pms intro: event_predOrdI)
    next
      case S_4_hash note facts = facts this[simplified]
      thus ?thesis proof(sources! "
                       Hash {| LC ''serverKey'', s(|MV ''nc'' tid0|), LN ''ns'' tid0,
                               Hash {| LC ''TT4'', LC ''PRF'', s(|MV ''pms'' tid0|),
                                       s(|MV ''nc'' tid0|), LN ''ns'' tid0
                                    |}
                            |} ")
      qed (insert facts, ((clarsimp, order?))+)?
    qed (insert facts, ((clarsimp, order?))+)?
  qed (insert facts, ((clarsimp, order?))+)?
qed

lemma (in atomic_TLS_state) S_serverKey_sec:
  assumes facts:
    "roleMap r tid0 = Some S"
    "s(|AV ''C'' tid0|) ~: Compromised"
    "s(|AV ''S'' tid0|) ~: Compromised"
    "(tid0, S_4) : steps t"
    "Hash {| LC ''serverKey'', s(|MV ''nc'' tid0|), LN ''ns'' tid0,
             Hash {| LC ''TT4'', LC ''PRF'', s(|MV ''pms'' tid0|),
                     s(|MV ''nc'' tid0|), LN ''ns'' tid0
                  |}
          |} : knows t"
  shows "False"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis proof(sources! "
                   Enc {| LC ''TT3'', s(|MV ''sid'' tid0|),
                          Hash {| LC ''TT4'', LC ''PRF'', s(|MV ''pms'' tid0|),
                                  s(|MV ''nc'' tid0|), LN ''ns'' tid0
                               |},
                          s(|MV ''nc'' tid0|), s(|MV ''pc'' tid0|), s(|AV ''C'' tid0|),
                          LN ''ns'' tid0, LN ''ps'' tid0, s(|AV ''S'' tid0|)
                       |}
                       ( Hash {| LC ''clientKey'', s(|MV ''nc'' tid0|), LN ''ns'' tid0,
                                 Hash {| LC ''TT4'', LC ''PRF'', s(|MV ''pms'' tid0|),
                                         s(|MV ''nc'' tid0|), LN ''ns'' tid0
                                      |}
                              |}
                       ) ")
    case fake note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: S_clientKey_sec intro: event_predOrdI)
  next
    case (C_3_enc tid1) note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: C_serverKey_sec intro: event_predOrdI)
  qed (insert facts, ((clarsimp, order?))+)?
qed

lemma (in atomic_TLS_state) C_ni_synch:
  assumes facts:
    "roleMap r tid1 = Some C"
    "s(|AV ''C'' tid1|) ~: Compromised"
    "s(|AV ''S'' tid1|) ~: Compromised"
    "(tid1, C_4) : steps t"
  shows
    "? tid2.
       roleMap r tid2 = Some S &
       s(|AV ''C'' tid2|) = s(|AV ''C'' tid1|) &
       s(|AV ''S'' tid2|) = s(|AV ''S'' tid1|) &
       s(|MV ''nc'' tid2|) = LN ''nc'' tid1 &
       s(|MV ''ns'' tid1|) = LN ''ns'' tid2 &
       s(|MV ''pc'' tid2|) = LN ''pc'' tid1 &
       s(|MV ''pms'' tid2|) = LN ''pms'' tid1 &
       s(|MV ''ps'' tid1|) = LN ''ps'' tid2 &
       s(|MV ''sid'' tid2|) = LN ''sid'' tid1 &
       predOrd t (St(tid1, C_1)) (St(tid2, S_1)) &
       predOrd t (St(tid1, C_3)) (St(tid2, S_3)) &
       predOrd t (St(tid1, C_2)) (St(tid1, C_3)) &
       predOrd t (St(tid2, S_2)) (St(tid1, C_2)) &
       predOrd t (St(tid2, S_4)) (St(tid1, C_4)) &
       predOrd t (St(tid2, S_1)) (St(tid2, S_2)) &
       predOrd t (St(tid2, S_3)) (St(tid2, S_4))"
proof -
  note_prefix_closed facts = facts note facts = this
  have f1: "roleMap r tid1 = Some C" using facts by (auto intro: event_predOrdI)
  have f2: "LN ''sid'' tid1 : knows t" using facts by (auto intro: event_predOrdI)
  note facts = facts auto_sid[OF f1 f2, simplified]
  thus ?thesis proof(sources! "
                   Enc {| LC ''TT3'', LN ''sid'' tid1,
                          Hash {| LC ''TT4'', LC ''PRF'', LN ''pms'' tid1, LN ''nc'' tid1,
                                  s(|MV ''ns'' tid1|)
                               |},
                          LN ''nc'' tid1, LN ''pc'' tid1, s(|AV ''C'' tid1|),
                          s(|MV ''ns'' tid1|), s(|MV ''ps'' tid1|), s(|AV ''S'' tid1|)
                       |}
                       ( Hash {| LC ''serverKey'', LN ''nc'' tid1, s(|MV ''ns'' tid1|),
                                 Hash {| LC ''TT4'', LC ''PRF'', LN ''pms'' tid1, LN ''nc'' tid1,
                                         s(|MV ''ns'' tid1|)
                                      |}
                              |}
                       ) ")
    case fake note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: C_serverKey_sec intro: event_predOrdI)
  next
    case (S_4_enc tid2) note facts = facts this[simplified]
    have f1: "roleMap r tid2 = Some S" using facts by (auto intro: event_predOrdI)
    have f2: "LN ''ns'' tid2 : knows t" using facts by (auto intro: event_predOrdI)
    note facts = facts auto_ns[OF f1 f2, simplified]
    thus ?thesis proof(sources! "
                     Enc {| LC ''TT0'', LN ''pms'' tid1 |}
                         ( PK ( s(|AV ''S'' tid1|) ) ) ")
      case fake note facts = facts this[simplified]
      thus ?thesis by (fastsimp dest: auto_C_sec_pms intro: event_predOrdI)
    next
      case C_3_enc note facts = facts this[simplified]
      thus ?thesis by force
    qed (insert facts, ((clarsimp, order?))+)?
  qed (insert facts, ((clarsimp, order?))+)?
qed

lemma (in atomic_TLS_state) S_ni_synch:
  assumes facts:
    "roleMap r tid2 = Some S"
    "s(|AV ''C'' tid2|) ~: Compromised"
    "s(|AV ''S'' tid2|) ~: Compromised"
    "(tid2, S_4) : steps t"
  shows
    "? tid1.
       roleMap r tid1 = Some C &
       s(|AV ''C'' tid2|) = s(|AV ''C'' tid1|) &
       s(|AV ''S'' tid2|) = s(|AV ''S'' tid1|) &
       s(|MV ''nc'' tid2|) = LN ''nc'' tid1 &
       s(|MV ''ns'' tid1|) = LN ''ns'' tid2 &
       s(|MV ''pc'' tid2|) = LN ''pc'' tid1 &
       s(|MV ''pms'' tid2|) = LN ''pms'' tid1 &
       s(|MV ''ps'' tid1|) = LN ''ps'' tid2 &
       s(|MV ''sid'' tid2|) = LN ''sid'' tid1 &
       predOrd t (St(tid1, C_1)) (St(tid2, S_1)) &
       predOrd t (St(tid1, C_3)) (St(tid2, S_3)) &
       predOrd t (St(tid1, C_2)) (St(tid1, C_3)) &
       predOrd t (St(tid2, S_2)) (St(tid1, C_2)) &
       predOrd t (St(tid2, S_1)) (St(tid2, S_2)) &
       predOrd t (St(tid2, S_3)) (St(tid2, S_4))"
proof -
  note_prefix_closed facts = facts note facts = this
  thus ?thesis proof(sources! "
                   Enc {| LC ''TT3'', s(|MV ''sid'' tid2|),
                          Hash {| LC ''TT4'', LC ''PRF'', s(|MV ''pms'' tid2|),
                                  s(|MV ''nc'' tid2|), LN ''ns'' tid2
                               |},
                          s(|MV ''nc'' tid2|), s(|MV ''pc'' tid2|), s(|AV ''C'' tid2|),
                          LN ''ns'' tid2, LN ''ps'' tid2, s(|AV ''S'' tid2|)
                       |}
                       ( Hash {| LC ''clientKey'', s(|MV ''nc'' tid2|), LN ''ns'' tid2,
                                 Hash {| LC ''TT4'', LC ''PRF'', s(|MV ''pms'' tid2|),
                                         s(|MV ''nc'' tid2|), LN ''ns'' tid2
                                      |}
                              |}
                       ) ")
    case fake note facts = facts this[simplified]
    thus ?thesis by (fastsimp dest: S_clientKey_sec intro: event_predOrdI)
  next
    case (C_3_enc tid3) note facts = facts this[simplified]
    have f1: "roleMap r tid3 = Some C" using facts by (auto intro: event_predOrdI)
    have f2: "LN ''nc'' tid3 : knows t" using facts by (auto intro: event_predOrdI)
    note facts = facts auto_nc[OF f1 f2, simplified]
    have f1: "roleMap r tid2 = Some S" using facts by (auto intro: event_predOrdI)
    have f2: "LN ''ns'' tid2 : knows t" using facts by (auto intro: event_predOrdI)
    note facts = facts auto_ns[OF f1 f2, simplified]
    thus ?thesis by force
  qed (insert facts, ((clarsimp, order?))+)?
qed

end