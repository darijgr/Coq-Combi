Require Import ssreflect ssrbool ssrfun ssrnat eqtype seq.

Set Implicit Arguments.
Unset Strict Implicit.

Section Braces.

  Inductive Brace : Set :=
    | Open : Brace | Close : Brace.

  Definition eqb b1 b2 :=
    match b1, b2 with
      | Open, Open | Close, Close => true
      | _, _ => false
    end.

  Lemma eqbP : Equality.axiom eqb.
  Proof.
    move=> n m; apply: (iffP idP) => [|<-]; last by elim n.
    elim: n; elim m; by [].
  Qed.

  Canonical brace_eqMixin := EqMixin eqbP.
  Canonical brace_eqType := Eval hnf in EqType Brace brace_eqMixin.

End Braces.


Section mParam.

  Variable m : nat.
  Implicit Type h n : nat.
  Implicit Type w : seq Brace.
  Implicit Type l : seq (seq Brace).

Section mDyckRec.


  Fixpoint m_dyck_height h w : bool :=
  match w with
    (* I'd rather not use h == 0 here because of extraction *)
    | nil => if h is 0 then true else false
    | Open::tlb => m_dyck_height (m + h) tlb
    | Close::tlb => if h is h'.+1 then m_dyck_height h' tlb else false
  end.

  Definition m_dyck := (m_dyck_height 0).

  Notation "m_dyck( h )" := (m_dyck_height h) (at level 2).

  (* The following allows to use w \in m_dyck which prevent simplifitation of *)
  (* expression such as (Open :: w \in m_dyck(h)) to (w \in m_dyck(m + 3)) .  *)
  (* On switch back to simplification by rewriting inE (see lemma belows).    *)
  Canonical m_dyck_height_app_pred h := ApplicativePred (m_dyck_height h).
  Canonical m_dyck_app_pred h := ApplicativePred m_dyck.

  Lemma open_m_dyck_height w h: (Open :: w) \in m_dyck(h) <-> w \in m_dyck(m + h).
  Proof. by rewrite inE. Qed.

  Lemma open_m_dyck w: (Open :: w) \in m_dyck <-> w \in m_dyck(m).
  Proof. by rewrite /m_dyck inE /= addn0. Qed.

  Lemma close_m_dyck_height w h: (Close :: w) \in m_dyck(h.+1) <-> w \in m_dyck(h).
  Proof. by rewrite inE. Qed.

  Lemma m_dyck_height_unique w h1 h2:
    w \in m_dyck(h1) -> w \in m_dyck(h2) -> h1 == h2.
  Proof.
    elim: w h1 h2 => [|[] w IHw] h1 h2 /=.
     case h1; case h2; by [].
     rewrite -(eqn_add2l m); by apply IHw.
     case: h1 => h1; case: h2 => h2 //=; rewrite eqSS; by apply IHw.
  Qed.

  Lemma cat_m_dyck_height w1 w2 h1 h2 :
    w1 \in m_dyck(h1) -> w2 \in m_dyck(h2) -> (w1 ++ w2) \in m_dyck(h1 + h2).
  Proof.
    elim: w1 w2 h1 h2 => [|[] w1 IHw1] w2 h1 h2 //=; first by case h1.
     rewrite ?open_m_dyck_height addnA; by apply IHw1.
     rewrite ?close_m_dyck_height; case: h1 => h1 //=; by apply IHw1.
  Qed.

  Fixpoint cut_to_height h w : seq Brace * seq Brace :=
  match w with
    | nil => (nil, nil)
    | Open :: tlw => let (w1, w2) := cut_to_height (m + h) tlw in
                     (Open :: w1, w2)
    | Close::tlw =>
      if h is h'.+1
      then let (w1, w2) := cut_to_height h' tlw in (Close :: w1, w2)
      else (nil, tlw)
  end.

  Remark cut_equiv_m_dyck_height w h :
    w \in m_dyck(h) <->
    ( (cut_to_height h w).1 == w /\ (cut_to_height h (w ++ [:: Close ])).1 == w ).
  Proof.
    elim: w h => [|[] w IHw] /=.
    - case=> [| h]; split; by move=> // [].
    - move=> h; move: IHw => /(_ (m + h)).
      elim (cut_to_height (m + h) w) => w1 w2 ->.
      by elim (cut_to_height (m + h) (w ++ [:: Close])).
    - case=> [| h] //; first by split; move=> // [].
      move: IHw => /(_ h).
      elim (cut_to_height h w) => w1 w2 ->.
      by elim (cut_to_height h (w ++ [:: Close])).
  Qed.

  Lemma cut_to_height_factor w hw h :
    w \in m_dyck(hw) -> hw > h ->
          let (w1, w2) := cut_to_height h w in w == w1 ++ Close :: w2.
  Proof.
    elim: w hw h => [|[] w IHw hw h] //= ; first by case.
    - move: IHw => /(_ (m + hw) (m + h)).
      elim (cut_to_height (m + h) w) => w1 w2 IHw.
      by rewrite (ltn_add2l m) in IHw.
    - case: hw => hw; case: h => h //=.
      move: IHw => /(_ hw h); by elim (cut_to_height h w).
  Qed.

  Lemma cut_m_dyck_height w hw h :
    w \in m_dyck(hw) -> hw > h ->
    let (w1, w2) := cut_to_height h w in w1 \in m_dyck(h) /\ w2 \in m_dyck(hw - S h).
  Proof.
    elim: w hw h => [|[] w IHw [] hw h Hd] //=; first by case.
    - move: IHw => /(_ (m + hw.+1) (m + h)).
      elim (cut_to_height (m + h) w) => w1 w2 IHw Hlt /=.
      rewrite -addnS (subnDl m) in IHw; apply IHw; first by apply Hd.
      by rewrite leq_add2l.
    - case: h => h; first by rewrite subn1 //=.
      move: IHw => /(_ hw h Hd).
      elim (cut_to_height h w) => w1 w2 IHw /=; by apply IHw.
  Qed.

  Lemma m_dyck_factor_eq_cut w hw h wa1 wa2 :
    w \in m_dyck(hw) -> hw > h ->
    wa1 \in m_dyck(h) -> w == wa1 ++ Close :: wa2 ->
    let (wb1, wb2) := cut_to_height h w
    in wa1 == wb1 /\ wa2 == wb2.
  Proof.
    elim: w hw h wa1 wa2 => [|x w IHw] hw h wa1 wa2; first by case wa1.
    case: x => Hd Hp; case: wa1 => [|[] wa1 Hdwa1 /= Heq] //=.
    - move: IHw => /(_ (m + hw) (m + h) wa1 wa2 Hd _ Hdwa1) {Hd Hdwa1}.
      elim (cut_to_height (m + h) w) => w1 w2.
      rewrite (ltn_add2l m) => IHw; by apply (IHw Hp).

    - move: h Hp => [] Hp Hdw /= Happ //=; by rewrite eq_sym.

    - move: hw h Hp Hd Hdwa1 => [] //= hw [] //= hwa1 Hlt Hdw Hdwa1.
      move: IHw => /(_ hw hwa1 wa1 wa2 Hdw _ Hdwa1) {Hdw Hdwa1}.
      elim (cut_to_height hwa1 w) => w1 w2; by apply.
  Qed.


  Definition join (T : Set) (b : T) := foldr (fun s1 s2 => s1 ++ b :: s2).

  Lemma join_m_dyck_height l w hw :
    all (mem m_dyck) l -> w \in m_dyck(hw) -> join Close w l \in m_dyck((size l) + hw).
  Proof.
    elim: l w hw => //= w l IHl w0 hw0 //= /andP [] Hdw Hld Hdw0.
    rewrite -(add0n (_ + hw0)); apply cat_m_dyck_height; first by [].
    by apply IHl.
  Qed.

  Fixpoint mult_cut n w :=
    if n is n'.+1
    then let (w1, w2) := cut_to_height 0 w in
         let (l, wr) := mult_cut n' w2 in (w1 :: l, wr)
    else (nil, w).

  CoInductive mult_cut_spec n w : seq (seq Brace) * seq Brace -> Prop :=
    MMultCutSpec l wr of
        size l == n & all (mem m_dyck) l & wr \in m_dyck & w == (join Close wr l)
        : mult_cut_spec n w (l, wr).

  Lemma mult_cutP n w : w \in m_dyck(n) -> mult_cut_spec n w (mult_cut n w).
  Proof.
    elim: n w => [| n IHn w H] /=; first by rewrite -/m_dyck.
    move: (ltn0Sn n) => Hpos.
    move: (cut_m_dyck_height H Hpos) (cut_to_height_factor H Hpos) => {H Hpos}.
    elim (cut_to_height 0 w) => w1 w2 [] Hdw1 Hdw2 Hcat.
    rewrite subn1 succnK in Hdw2; rewrite -/m_dyck in Hdw1.
    move/IHn: Hdw2; case => l wr Hlen Hld Hwr Hjoinl.
    constructor => //=; first by rewrite Hld Hdw1.
    by rewrite (eqP Hcat) (eqP Hjoinl).
  Qed.

  Lemma mult_cut_spec_unique n w l wr:
    mult_cut_spec n w (l, wr) -> (l, wr) = (mult_cut n w).
  Proof.
    move=> [] {wr l}.
    elim: n w => [| n IHn ] w l wr Hlen //.
    by move: (size0nil (eqP Hlen)) => -> _ _ /= /eqP ->.
    case: l Hlen => w0 l //= Hlen /andP [] Hw0d Halld Hwrd Hjoinl.
    rewrite eqSS in Hlen; move: (join_m_dyck_height Halld Hwrd).
    rewrite addn0 (eqP Hlen) -close_m_dyck_height => Wdn.
    move: {Wdn} (cat_m_dyck_height Hw0d Wdn) => Wdn.
    rewrite -(eqP Hjoinl) in Wdn.
    move: {Wdn Hw0d Hjoinl} (m_dyck_factor_eq_cut Wdn (ltn0Sn _) Hw0d Hjoinl).
    elim (cut_to_height 0 w) => _ _ [] /eqP <- /eqP <-.
    set wl := (join _ _ _).
    move: IHn => /(_ wl l wr Hlen Halld Hwrd (eq_refl _)) {Halld Hwrd}.
    by elim: (mult_cut n wl) => l0 wr0 [] -> ->.
  Qed.


  Definition m_factor w := mult_cut m (behead w).

  CoInductive m_factor_spec w : seq (seq Brace) * seq Brace -> Prop :=
    MFactorSpec l wr of (size l == m) & (all (mem m_dyck) l) & wr \in m_dyck &
                (w == Open :: (join Close wr l)) : m_factor_spec w (l, wr).

  Lemma m_factorP w :
    w \in m_dyck -> (w != [::]) -> m_factor_spec w (m_factor w).
  Proof.
    rewrite /m_factor /m_dyck; case: w => [| [] w] //=.
    rewrite open_m_dyck => Hd _;  by case: (mult_cutP Hd).
  Qed.

  Theorem m_factor_spec_unique w l wr :
    m_factor_spec w (l, wr) -> (l, wr) = (m_factor w).
  Proof.
    rewrite /m_factor /m_dyck => H.
    apply mult_cut_spec_unique; case: {l wr} H => l wr Hsz Halld Hwrd Hjoin.
    by rewrite (eqP Hjoin) in Hwrd *.
  Qed.

End mDyckRec.

Section Induction.

  Lemma in_seq_size_lt_join l ww wr:
    ww \in l -> size ww < size (Open :: join Close wr l).
  Proof.
    elim: l => //= w0 l IHl; rewrite size_cat in_cons.
    case/orP => [{IHl} /eqP <- |].
    - by rewrite ltnS; apply leq_addr.
    - move/IHl => {IHl} H; apply (ltn_trans H) => {H} /=.
      by rewrite addnS ?ltnS; apply leq_addl.
  Qed.

  Lemma init_size_lt_join l wr:
    size wr < size (Open :: join Close wr l).
  Proof.
    rewrite /join; elim: l => //= w0 l IHl.
    apply (ltn_trans IHl) => {IHl}.
    rewrite size_cat /= addnS ?ltnS; apply leq_addl.
  Qed.

  Variable P : seq Brace -> Type.

  Hypothesis (Pnil : P [::])
             (Pcons : forall w l wr, m_factor_spec w (l, wr) ->
                                (forall ww, ww \in l -> P ww) -> P wr ->
                                P w).

  Inductive all_has_P : seq (seq Brace) -> Type :=
    | AllHasNil : P [::] -> all_has_P [::]
    | AllHasCons : forall w l, P w -> all_has_P l -> all_has_P (w :: l).

  Lemma all_has_P_in l : (all_has_P l) -> (forall w, w \in l -> P w).
  Proof.
    elim => //= {l} w l HPw _ Hin w0.
    rewrite in_cons => /orP; case: (altP (w =P w0)); first by move=> <-.
    move=> Hdiff Hw0in; apply Hin; case: Hw0in Hdiff => // /eqP ->.
    by rewrite eq_refl.
  Qed.
  Lemma all_in_has_P l : (forall w, w \in l -> P w) -> (all_has_P l).
  Proof.
    elim: l => [_| w l IHl Hin]; first by apply AllHasNil.
    apply AllHasCons; first by apply Hin; rewrite in_cons eq_refl.
    apply IHl => w0 Hw0inl. apply Hin; by rewrite in_cons Hw0inl orbC.
  Qed.

  Definition dyck_lt_size w' w := w' \in m_dyck /\ size w' < size w.

  (* This lemma factors out the sort Prop elimination of the induction *)
  Lemma factor_dyck_lt_size w :
    w \in m_dyck -> w != [::] -> let (l, wr) := m_factor w in
      m_factor_spec w (l, wr) /\
      (dyck_lt_size wr w) /\
      (forall ww, ww \in l -> dyck_lt_size ww w).
  Proof.
    move=> Hdyck Hnnil; move: (m_factorP Hdyck Hnnil).
    move Heqfct : (m_factor w) => C; elim: C Heqfct => l wr Heqfct Hfact.
    split; first by exact Hfact.
    move: {Hnnil} (m_factor_spec_unique Hfact).
    (* The following elimination is only legible in sort Prop *)
    case Hfact => l0 w0 _ Halld Hwwd Hcat; rewrite Heqfct => Heq.
    move: Heq Halld Hcat Hwwd => [] -> -> {l0 w0} Halld Hcat Hwwd.
    split; first split; first by exact Hwwd.
    - by rewrite (eqP Hcat); apply init_size_lt_join.
    - move=> ww Hwwinl; split; first by apply (allP Halld).
    - by rewrite (eqP Hcat); apply in_seq_size_lt_join.
  Qed.

  Lemma m_dyck_ind_rec w :
    (forall w', dyck_lt_size w' w -> w' \in m_dyck -> P w') -> w \in m_dyck -> P w.
  Proof.
    case: (altP (w =P [::])); first by move=> -> _ _; apply Pnil.
    move=> Hnnil HltP Hdyck; move: (factor_dyck_lt_size Hdyck Hnnil).
    case (m_factor w) => l wr [] Hfact [] Hwrdlt Hww.
    apply (Pcons Hfact) => {Hfact}.
    - by move=> ww Hwinl; apply HltP; apply Hww.
    - rewrite /dyck_lt_size in Hwrdlt; move: (Hwrdlt) => [] Hwrd Hsz; by apply HltP.
  Qed.

  Require Import Coq.Arith.Wf_nat.

  Lemma Rwf : well_founded dyck_lt_size.
  Proof.
    apply (well_founded_lt_compat _ size);
    rewrite /dyck_lt_size => x y [] _ H; by apply /ltP.
  Qed.

  Definition dyck_ind : forall w, w \in m_dyck -> P w
    := Fix Rwf (fun ww => ww \in m_dyck -> P ww) m_dyck_ind_rec.


End Induction.

(* 
Lemma forall w1 w2, w1 \in

Check dyck_ind.

Check (fun P : (seq Brace) -> Set => @dyck_ind P).

Definition dyck_size : forall w, w \in m_dyck -> nat.
Proof.
  apply (@dyck_ind (fun w => nat) 0).
  move=> w l wr H recL recwr.
  apply (@foldr (seq Brace) nat).
  
  (fun ww i => recL ww _) recwr l).

  
dyck_ind
     : forall P : seq Brace -> Type,
       P [::] ->
       (forall w l (wr : seq Brace),
        m_factor_spec w (l, wr) ->
        (forall ww : seq_eqType brace_eqType, ww \in l -> P ww) ->
        P wr -> P w) -> forall w, w \in m_dyck -> P w

nat_rect
     : forall P : nat -> Type,
       P 0 -> (forall n : nat, P n -> P (S n)) -> forall n : nat, P n

nat_rec =
fun P : nat -> Set => nat_rect P
     : forall P : nat -> Set,
       P 0 -> (forall n : nat, P n -> P (S n)) -> forall n : nat, P n
*)
  
Section Prefixes.

  Variable T : eqType.
  Implicit Type a : T.
  Implicit Type s : seq T.

  Definition prefixes s := scanl rcons [::] s.

  Lemma scanl_rcons a sr s :
    scanl rcons (a :: sr) s == [seq a :: i | i <- scanl rcons sr s].
  Proof. elim: s sr => //= b s IHs sr; by rewrite (eqP (IHs _)). Qed.

  Lemma prefixes_cons a s : prefixes (a :: s) == [:: a] :: [seq a :: i | i <- prefixes s].
  Proof.
    rewrite /prefixes; case: s => [| b s] //=.
    by rewrite (eqP (scanl_rcons _ _ _)).
  Qed.

  Lemma prefix_take s :
    prefixes s == mkseq (fun n => take n.+1 s) (size s).
  Proof.
    elim: s => //= a s IHs.
    rewrite (eqP (prefixes_cons _ _)) (eqP IHs) => {IHs} /=.
    apply /eqP; apply (eq_from_nth (x0 := [::])) => [|i Hil]; apply /eqP.
    by rewrite /= eqSS ?size_map ?size_iota.
    case: i Hil => [|i] /= Hil; first by rewrite take0.
    rewrite /= ltnS ?size_map ?size_iota in Hil.
    move: nth_map => /(_ _ [::]) ->; last by rewrite size_mkseq.
    move: nth_map => /(_ _ 0) ->; last by rewrite size_iota.
    by rewrite nth_mkseq // nth_iota.
  Qed.

End Prefixes.

(* Eval compute in prefixes [:: Open ; Close ; Close ]. *)

Section mDyckPrefix.

  Notation nOpen := (count_mem Open).
  Notation nClose := (count_mem Close).
  Definition brace_bal h w :=  m * (nOpen w) + h == nClose w.
  Definition brace_pos h w :=  m * (nOpen w) + h >= nClose w.

  Definition m_dyck_prefix_height h w := brace_bal h w && all (brace_pos h) (prefixes w).
  Definition m_dyck_prefix := (m_dyck_prefix_height 0).

  Lemma m_dyck_height_equiv : m_dyck_prefix_height =2 m_dyck_height.
  Proof.
    rewrite /m_dyck_prefix_height /eqrel /prefixes /brace_pos /brace_bal => h w.
    elim: w h => [|[] w IHw h] /=; first by case => //=; rewrite muln0.
    - rewrite -IHw add0n mulnDr muln1 [m + _] addnC -addnA => {IHw}; bool_congr.
      rewrite (eqP (scanl_rcons _ _ _)) /= all_map; apply eq_all; rewrite /eqfun => l /=.
      by rewrite add0n mulnDr muln1 [m + _] addnC -addnA.
    - case: h => [|h] /=; rewrite ?addn0 add0n muln0; first by rewrite andbF.
      rewrite -IHw add0n add1n addnS eqSS /= => {IHw}; bool_congr.
      rewrite (eqP (scanl_rcons _ _ _)) /= all_map; apply eq_all; rewrite /eqfun => l /=.
      by rewrite add0n add1n addnS.
  Qed.

  Theorem m_dyck_equiv : m_dyck_prefix =1 m_dyck.
  Proof.
    rewrite /m_dyck_prefix /m_dyck /eqfun.
    by apply m_dyck_height_equiv.
  Qed.

  Definition is_m_dyck_prefix_height h w :=
    (brace_bal h w) /\ forall n, brace_pos h (take n.+1 w).
  Definition is_m_dyck_prefix w := is_m_dyck_prefix_height 0 w.

  Lemma m_positive_equiv h w :
    (forall n, brace_pos h (take n.+1 w)) <-> all (brace_pos h) (prefixes w).
  Proof.
    rewrite (eqP (prefix_take _)) /mkseq /preim all_map /preim.
    split => [H | b n]; first by apply /allP => HH _ //=.
    case: (ltnP n (size w)) => Hn.
    - move: (allP b n) => /= Hb {b}; apply Hb; by rewrite mem_iota add0n.
    - rewrite take_oversize; last by apply (leq_trans Hn).
      move: (allP b (size w).-1) => //= {b}.
      case: w Hn => //= [a w] _.
      rewrite take_size; apply => {a}.
      rewrite in_cons mem_iota; by case (size w) => /=.
  Qed.

  Lemma m_positiveP h w :
    reflect (forall n, brace_pos h (take n.+1 w)) (all (brace_pos h) (prefixes w)).
  Proof. apply: (iffP idP); apply m_positive_equiv. Qed.

  Lemma m_dyck_prefix_heightP h w :
    reflect (is_m_dyck_prefix_height h w) (m_dyck_prefix_height h w).
  Proof.
    rewrite /is_m_dyck_prefix_height /m_dyck_prefix_height.
    apply: (iffP idP); rewrite m_positive_equiv.
    move=> H; split; apply (andP H).
    move=> [] H1 H2; by rewrite H1.
  Qed.

  Theorem m_dyck_prefixP w :
    reflect (is_m_dyck_prefix w) (m_dyck_prefix w).
  Proof.
    rewrite /is_m_dyck_prefix /m_dyck_prefix.
    by apply m_dyck_prefix_heightP.
  Qed.

  Theorem m_dyckP w :
    reflect (is_m_dyck_prefix w) (m_dyck w).
  Proof. rewrite -m_dyck_equiv; apply m_dyck_prefixP.  Qed.

End mDyckPrefix.


(* Experiment with SSReflect tuple *)
Require Import tuple.

Section DyckTuple.

  Notation m1tuple := ((m.+1).-tuple (seq Brace)).

  Lemma mult_cut_size n w : size ((mult_cut n w).1) == n.
  Proof.
    elim: n w => //= n IHw w.
    elim (cut_to_height 0 w) => w1 w2.
    move: (IHw w2); by elim (mult_cut n w2).
  Qed.

  Definition m_tuple_factor (w : seq Brace) : m1tuple :=
    let w0 := behead w in
    cons_tuple ((mult_cut m w0).2) (Tuple (mult_cut_size m w0)).

  CoInductive m_tuple_factor_spec w : m1tuple -> Prop :=
    MTupleFactorSpec (t : m1tuple) of
                all (mem m_dyck) t &
                w == Open :: (join Close (thead t) (behead t))
    : m_tuple_factor_spec w t.

  Theorem m_dyck_factorP w :
    w <> [::] -> w \in m_dyck -> m_tuple_factor_spec w (m_tuple_factor w).
  Proof.
    case: w => [| [] w _] //=.
    rewrite open_m_dyck /m_tuple_factor /m_factor /cons_tuple /= => Hd.
    constructor.
    rewrite /tval.
    by move: (mult_cutP Hd); case => /= l wr _ Halld Hwrd _; apply /andP.
    rewrite /thead (tnth_nth [::]) => /=.
    by move: (mult_cutP Hd); case => /= l wr _ _ _ H; rewrite (eqP H).
  Qed.

End DyckTuple.

End mParam.

Lemma dyck_zero_unique :
  forall (w : list Brace), w \in (m_dyck 0) -> w == nseq (size w) Open.
Proof.
  apply dyck_ind => //=.
  move=> w l wr Hfact.
  move: (m_factor_spec_unique Hfact) => Hfactor.
  rewrite Hfactor in Hfact.
  case: Hfact Hfactor => l0 w0 Hsz Halld Hwr0d Hjoin Heq.
  by move: Heq Hsz Halld Hwr0d Hjoin => [] <- <- {l0 w0} /nilP -> /= _ _ /eqP -> _.
Qed.


(*

 Eval compute in ((nseq 13 Open) \in m_dyck 0).

Let hat := [:: Open; Close].
Let d := Open :: hat ++ Close :: hat.
Eval compute in m_dyck 1 hat.
Eval compute in m_dyck 1 d.

Eval compute in tval (m_tuple_factor 1 d).
Eval compute in (m_factor 1 d).
*)

(*

Extract Inductive bool => "bool" [ "true" "false" ].
Extract Inductive list => "list" [ "[]" "(::)" ].
Extract Inductive prod => "(*)"  [ "(,)" ].
(*
Extract Inductive nat => "Big_int.big_int"
  [ "Big_int.zero_big_int" "Big_int.succ_big_int" ] "(fun fO fS n ->
    let one = Big_int.unit_big_int in
    if n = Big_int.zero_big_int then fO () else fS (Big_int.sub_big_int n one))".
*)

Extract Inductive nat => "int"
  [ "0" "(fun x -> x + 1)" ]
  "(fun zero succ n -> if n=0 then zero () else succ (n-1))".

Extract Inlined Constant plus => "( + )".
Extract Constant mult => "( * )".
Extract Constant eqn => "( = )".
Extract Constant nat_eqType => "( = )".
Extract Constant eq_op => "(fun eq -> eq)".
*)

Extraction Inline addn addn_rec.
Extraction "mdycktuple.ml" m_tuple_factor.
Extraction "mdyck.ml" m_dyck m_factor.
