(** * Combi.MPoly.MurnaghanNakayama : Murnaghan-Nakayama rule *)
(******************************************************************************)
(*      Copyright (C) 2021-2021 Florent Hivert <florent.hivert@lri.fr>        *)
(*                                                                            *)
(*  Distributed under the terms of the GNU General Public License (GPL)       *)
(*                                                                            *)
(*    This code is distributed in the hope that it will be useful,            *)
(*    but WITHOUT ANY WARRANTY; without even the implied warranty of          *)
(*    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU       *)
(*    General Public License for more details.                                *)
(*                                                                            *)
(*  The full text of the GPL is available at:                                 *)
(*                                                                            *)
(*                  http://www.gnu.org/licenses/                              *)
(******************************************************************************)
(** * The Murnaghan–Nakayama rule

 ******)
Require Import mathcomp.ssreflect.ssreflect.
From mathcomp Require Import ssrfun ssrbool eqtype ssrnat seq choice fintype.
From mathcomp Require Import tuple finfun finset binomial order.
From mathcomp Require Import bigop ssralg ssrint path perm fingroup.
From SsrMultinomials Require Import ssrcomplements freeg mpoly.
From SsrMultinomials Require monalg.

Require Import sorted tools ordtype permuted partition skewpart.
Require Import antisym Schur_mpoly Schur_altdef sympoly homogsym.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Local Open Scope ring_scope.
Import GRing.Theory.


Local Reserved Notation "''a_' k"
      (at level 8, k at level 2, format "''a_' k").
Local Reserved Notation "m # s"
      (at level 40, left associativity, format "m # s").


Section BigPMap.
Variables (R : Type) (idx : R).
Local Notation "1" := idx.
Variable (op : Monoid.law idx).
Local Notation "*%M" := op (at level 0).
Local Notation "x * y" := (op x y).
Variable I : Type.

Lemma big_pmap J (h : J -> option I) r F :
  \big[*%M/1]_(i <- pmap h r) F i = \big[*%M/1]_(j <- r) oapp F idx (h j).
Proof.
elim: r => [| r0 r IHr]/=; first by rewrite !big_nil.
rewrite /= big_cons; case: (h r0) => [i|] /=; last by rewrite Monoid.mul1m.
by rewrite big_cons IHr.
Qed.

End BigPMap.


Section MultAlternSymp.

Variable n0 : nat.
Variable R : comRingType.

Local Notation n := n0.+1.
Local Notation rho := (rho n).
Local Notation "''a_' k" := (@alternpol n R 'X_[k]).

Lemma mult_altern_symp_pol p d :
  'a_(mpart p + rho) * (symp_pol n R d.+1) =
   \sum_(i < n) 'a_(mpart p + rho + U_(i) *+ d.+1).
Proof.
rewrite /alternpol mulr_suml [RHS]exchange_big /=; apply eq_bigr => s _.
rewrite -scaler_sumr -scalerAl; congr (_ *: _).
rewrite -(issymP _ (symp_sym n R d.+1) s) -msymM -linear_sum /=; congr msym.
rewrite /symp_pol mulr_sumr; apply eq_bigr => i _.
by rewrite !mpolyXD mpolyXn.
Qed.

Lemma mult_altern_oapp p d :
  is_part p -> size p <= n ->
  'a_(mpart p + rho) * (symp_pol n R d.+1) =
  \sum_(i < n) oapp (fun ph => (-1) ^+ ph.2.-1 *: 'a_(mpart ph.1 + rho)) 0
   (add_ribbon p d.+1 i).
Proof.
move=> partp szp; rewrite mult_altern_symp_pol.
apply eq_bigr => i _ /=.
case Hrib : add_ribbon => [[sh h]|] /=.
  by rewrite (alt_straight_add_ribbon _ partp szp Hrib).
by rewrite (alt_straight_add_ribbon0 _ partp szp) // Hrib.
Qed.

Lemma mult_altern_pmap p d :
  is_part p -> size p <= n ->
  'a_(mpart p + rho) * (symp_pol n R d.+1) =
  \sum_(psh <- pmap (add_ribbon p d.+1) (iota 0 n))
   (-1) ^+ (psh.2).-1 *: 'a_(mpart psh.1 + rho).
Proof.
move=> partp szp; rewrite mult_altern_oapp //.
rewrite -(big_mkord xpredT (fun i => oapp _ 0 (add_ribbon p d.+1 i))).
by rewrite big_pmap /index_iota subn0.
Qed.


Section Lift.

Variable (m : nat) (la : 'P_m).
Hypothesis (szla : size la <= n).
Variable nbox : nat.
Local Notation "'Pr" := 'P_(nbox.+1 + m).

Local Definition val_id : ('Pr * nat) -> seq nat* nat :=
  fun p => let: (sh, h) := p in (val sh, h).

Fact add_ribbon_intpartn_spec pos :
  { res : option ('Pr * nat) | omap val_id res = add_ribbon la nbox.+1 pos }.
Proof.
case Hrib: (add_ribbon la nbox.+1 pos) => [[sh h]|].
- have:= is_part_of_add_ribbon (intpartnP _) Hrib.
  rewrite sumn_intpartn => Hres.
  by exists (Some (IntPartN Hres, h)).
- by exists None.
Qed.
Definition add_ribbon_intpartn (pos : nat) : option ('Pr * nat) :=
  let: exist res _ := add_ribbon_intpartn_spec pos in res.

Lemma add_ribbon_intpartnE pos :
  add_ribbon la nbox.+1 pos =omap val_id (add_ribbon_intpartn pos).
Proof. by rewrite /add_ribbon_intpartn; case: add_ribbon_intpartn_spec. Qed.
Lemma add_ribbon_intpartnP pos res h :
  add_ribbon_intpartn pos = Some (res, h) ->
  add_ribbon la nbox.+1 pos = Some (val res, h).
Proof. by move/(congr1 (omap val_id)); rewrite add_ribbon_intpartnE /=. Qed.

End Lift.

End MultAlternSymp.


Section MultSymsSympIDomain.

Variable n0 : nat.
Local Notation n := n0.+1.
Variable (R : idomainType).
Local Notation SF := {sympoly R[n]}.

Lemma syms_sympM_oapp_idomain d (la : 'P_d) m :
  m != 0%N -> size la <= n ->
  's[la] * 'p_m =
  \sum_(i < n) oapp (fun ph => (-1) ^+ ph.2.-1 *: 's[ph.1]) 0
   (add_ribbon_intpartn la m.-1 i) :> SF.
Proof.
case: m => // m _ szla; apply val_inj.
rewrite /= !raddf_sum /=.
apply: (mulfI (alt_rho_non0 n _)).
rewrite mulrA alt_SchurE //= mult_altern_oapp //.
rewrite mulr_sumr; apply eq_bigr => mu _.
rewrite add_ribbon_intpartnE.
case Haddrib: add_ribbon_intpartn => [[sh h]|]/=; last by rewrite mulr0.
move/add_ribbon_intpartnP in Haddrib.
rewrite -scalerAr alt_SchurE //.
by rewrite (size_add_ribbon Haddrib) geq_max szla ltn_ord.
Qed.

End MultSymsSympIDomain.


Section MultSymsSymp.

Variable n0 : nat.
Variable R : comRingType.
Local Notation n := n0.+1.
Local Notation SF := {sympoly R[n]}.

Lemma syms_sympM_oapp_size d (la : 'P_d) m :
  m != 0%N -> size la <= n ->
  's[la] * 'p_m =
  \sum_(i < n) oapp (fun ph => (-1) ^+ ph.2.-1 *: 's[ph.1]) 0
   (add_ribbon_intpartn la m.-1 i) :> SF.
Proof.
move=> Hm szla.
rewrite -(map_syms [rmorphism of intr]) -(map_symp [rmorphism of intr]).
rewrite -rmorphM syms_sympM_oapp_idomain // rmorph_sum /=.
apply eq_bigr => i _.
case: add_ribbon_intpartn => [p|]/=; last by rewrite rmorph0.
by rewrite scale_map_sympoly rmorphX rmorphN1 map_syms.
Qed.
Lemma syms_sympM_oapp d (la : 'P_d) m :
  m != 0%N ->
  's[la] * 'p_m =
  \sum_(i < n) oapp (fun ph => (-1) ^+ ph.2.-1 *: 's[ph.1]) 0
   (add_ribbon_intpartn la m.-1 i) :> SF.
Proof.
move=> Hm.
case: (leqP (size la) n) => [/syms_sympM_oapp_size-> // | szla].
rewrite syms_oversize // mul0r; apply/esym/big1 => /= i _.
case Haddrib: add_ribbon_intpartn => [[sh h]|]//=.
move/add_ribbon_intpartnP in Haddrib.
rewrite syms_oversize ?scaler0 //.
by rewrite (size_add_ribbon Haddrib) leq_max szla.
Qed.

Lemma syms_sympM_pmap d (la : 'P_d) m :
  m != 0%N ->
  's[la] * 'p_m =
  \sum_(ph <- pmap (add_ribbon_intpartn la m.-1) (iota 0 n))
   (-1) ^+ ph.2.-1 *: 's[ph.1] :> SF.
Proof.
move=> Hm; rewrite syms_sympM_oapp //.
by rewrite big_pmap -[n in iota 0 n](subn0 n) -/(index_iota 0 n) big_mkord.
Qed.

Lemma syms_sympM d (la : 'P_d) m :
  m != 0%N ->
  's[la] * 'p_m =
  \sum_(sh : 'P_(m + d) | ribbon la sh)
   (-1) ^+ (ribbon_height la sh).-1 *: 's[sh] :> SF.
Proof.
move=> Hm.
case: (ltnP n (size la)) => szla.
  rewrite syms_oversize // mul0r; apply/esym/big1 => /= i.
  move=> /ribbon_included/includedP [/(leq_trans szla)/syms_oversize -> _].
    by rewrite scaler0.
rewrite (syms_sympM_oapp_size Hm szla).
case: m Hm => // m _.
rewrite (bigID (fun i : 'I_n => add_ribbon_intpartn la m i)) /=.
rewrite [X in _ + X = _]big1 ?addr0; last by move=> i; case: add_ribbon_intpartn.
rewrite [RHS](bigID (fun sh => size (val sh) <= n)) /=.
rewrite [X in _ = _ + X]big1 ?addr0; first last => [mu /andP[_]|].
  by rewrite -ltnNge => /syms_oversize ->; rewrite scaler0.
have ribbon_stop_subproof (mu : 'P_(m.+1 + d)) :
  (if size mu <= n then (mindropeq la mu).-1 else 0%N) < n.
  case: (leqP (size mu) n) => // szmu.
  case: mindropeq (mindropeq_leq la mu) => // md /= /leq_trans; apply.
  by rewrite geq_max szla szmu.
pose ribbon_stop mu := Ordinal (ribbon_stop_subproof mu).
rewrite (reindex_omap ribbon_stop
          (omap fst \o (add_ribbon_intpartn la m))) /=; first last => [i|].
  case Haddrib: add_ribbon_intpartn => [[res h]|]//= _.
  move/add_ribbon_intpartnP in Haddrib.
  congr Some; apply val_inj => /=.
  rewrite (size_add_ribbon Haddrib) geq_max szla ltn_ord /=.
  rewrite (ribbon_on_mindropeq (intpartnP la) _ (add_ribbon_onP Haddrib)) //.
  exact: (is_part_add_ribbon _ Haddrib).
apply esym; apply: eq_big => mu.
  rewrite andbC; case leqP => Hszmu /=; first last.
  + case Haddrib: add_ribbon_intpartn => [[res h]|] //=; first last.
    move/add_ribbon_intpartnP in Haddrib.
    case (altP (_ =P Some mu)) => // [[Heq]].
    have := size_add_ribbon Haddrib; rewrite {res Haddrib}Heq /= => Heq.
    by move: Hszmu; rewrite Heq leq_max 2!ltnNge szla.
  + apply esym; case: (boolP (ribbon la mu)) => [Hrib | Hnrib].
    * have := ribbon_addE (intpartnP la) (intpartnP mu) Hrib.
      rewrite sumn_diff_shape ?ribbon_included // !sumn_intpartn addnK.
      rewrite add_ribbon_intpartnE.
      case Haddrib: add_ribbon_intpartn => [[res h]|]//=.
      by move=> [/val_inj ->]; rewrite eqxx.
    * case Haddrib: add_ribbon_intpartn => [[res h]|]//=.
      move/add_ribbon_intpartnP in Haddrib.
      apply/negP => /eqP [] Heq.
      by move: Hnrib; rewrite -{}Heq (add_ribbonP _ Haddrib).
move=> /andP[Hrib ->].
have:= ribbon_addE (intpartnP la) (intpartnP mu) Hrib.
rewrite sumn_diff_shape ?ribbon_included // !sumn_intpartn addnK.
rewrite add_ribbon_intpartnE.
by case Haddrib: add_ribbon_intpartn => [[res h]|]//= [/val_inj -> <-].
Qed.

End MultSymsSymp.


(** MN_coeff should only be used when [sumn la == sumn mu]. *)
Fixpoint MN_coeff (la mu : seq nat) : int :=
  if mu is m0 :: m then
    foldr (fun sh acc =>
             if ribbon sh la then
               MN_coeff sh m * (-1) ^+ (ribbon_height sh la).-1 + acc
             else acc)
          0 (enum_partn (sumn m))
  else 1.

Lemma MN_coeff0 : MN_coeff [::] [::] = 1.
Proof. by []. Qed.

Lemma MN_coeff_recE la m0 mu :
  MN_coeff la (m0 :: mu) =
  \sum_(sh : 'P_(sumn mu) | ribbon sh la)
   MN_coeff sh mu * (-1) ^+ (ribbon_height sh la).-1.
Proof.
apply esym; transitivity (
                \sum_(sh <- enum_partn (sumn mu) | ribbon sh la)
                 MN_coeff sh mu * (-1) ^+ (ribbon_height sh la).-1).
  by rewrite -enum_intpartnE [LHS]big_mkcond [RHS]big_mkcond big_map big_enum.
rewrite big_mkcond /=; elim: enum_partn => [| p0 p] /=; first by rewrite big_nil.
by rewrite big_cons => ->; case: (ribbon p0 la); rewrite //= add0r.
Qed.


Section Tests.
(** Tests :
[
sage: s(p[2,1,1])
-s[1, 1, 1, 1] - s[2, 1, 1] + s[3, 1] + s[4]
]
*****)
Goal ([seq x | x <- [seq (p, MN_coeff p [:: 2; 1; 1]) | p <- enum_partn 4]
               & x.2 != 0%R] =
      [:: ([:: 4], Posz 1);
      ([:: 3; 1], Posz 1);
      ([:: 2; 1; 1], Negz 0);
      ([:: 1; 1; 1; 1], Negz 0)])%N.
Proof. by []. Abort.

(** Tests :
[
sage: s(p[4,2,1,1])
s[1, 1, 1, 1, 1, 1, 1, 1] + s[2, 1, 1, 1, 1, 1, 1] - s[3, 1, 1, 1, 1, 1] - 2*s[3, 3, 2] - s[4, 1, 1, 1, 1] + 2*s[4, 2, 1, 1] - s[5, 1, 1, 1] - s[6, 1, 1] + s[7, 1] + s[8]
]
*****)
Goal ([seq x | x <- [seq (p, MN_coeff p [:: 4; 2; 1; 1]) | p <- enum_partn 8]
               & x.2 != 0%R] =
      [:: ([:: 8], Posz 1);
      ([:: 7; 1], Posz 1);
      ([:: 3; 3; 2], Negz 1);
      ([:: 6; 1; 1], Negz 0);
      ([:: 4; 2; 1; 1], Posz 2);
      ([:: 5; 1; 1; 1], Negz 0);
      ([:: 4; 1; 1; 1; 1], Negz 0);
      ([:: 3; 1; 1; 1; 1; 1], Negz 0);
      ([:: 2; 1; 1; 1; 1; 1; 1], Posz 1);
      ([:: 1; 1; 1; 1; 1; 1; 1; 1], Posz 1)])%N.
Proof. by []. Abort.

End Tests.

Section MNRule.

Variable n0 : nat.
Local Notation n := n0.+1.

Theorem MN_coeffP_int d (la : 'P_d) :
  'p[la] = \sum_(sh : 'P_d) MN_coeff sh la *: 's[sh] :> {sympoly int[n]}.
Proof.
rewrite /prod_symp /prod_gen.
case: la => la /= /andP [/eqP <-{d} /in_part_non0].
elim: la => [/=|l0 la IHla] Hall.
  rewrite big_nil (big_pred1 (rowpartn 0)) ?scale1r ?syms0 //.
  by move=> i /=; rewrite intpartn0 eqxx.
rewrite big_cons {}IHla; first last.
  by move=> i iinla; apply: Hall; rewrite inE {}iinla orbT.
under [RHS]eq_bigr do rewrite MN_coeff_recE.
rewrite mulr_sumr.
have {Hall} l0n0 : l0 != 0%N by apply: Hall; rewrite inE eqxx.
under eq_bigr do rewrite mulrC -scalerAl syms_sympM // scaler_sumr.
rewrite (exchange_big_dep xpredT) //=; apply: eq_bigr => mu _.
rewrite scaler_suml; apply eq_bigr => nu _.
by rewrite scalerA.
Qed.

Variable R : comRingType.

Theorem MN_coeffP d (la : 'P_d) :
  'p[la] = \sum_(sh : 'P_d) (MN_coeff sh la)%:~R *: 's[sh] :> {sympoly R[n]}.
Proof.
rewrite -(map_symp_prod [rmorphism of intr]) MN_coeffP_int rmorph_sum /=.
by under [LHS]eq_bigr do rewrite scale_map_sympoly map_syms.
Qed.

Theorem MN_coeff_homogP d (la : 'P_d) :
  'hp[la] = \sum_(sh : 'P_d) (MN_coeff sh la)%:~R *: 'hs[sh] :> {homsym R[n, d]}.
Proof.
apply val_inj => /=; apply val_inj => /=.
have /= := congr1 val (MN_coeffP la); rewrite /prod_symp => ->.
by rewrite !raddf_sum.
Qed.

End MNRule.



(** MN_coeff should only be used when [sumn la == sumn mu]. *)
Fixpoint MN_coeff_rec (la mu nu : seq nat) : int :=
  if mu is m0 :: m then
    foldr (fun pair acc =>
             MN_coeff_rec la m pair.1 * (-1) ^+ pair.2.-1 + acc)
          0
          [seq x | x <- pmap (add_ribbon nu m0) (iota 0 (size la))
                   & included x.1 la]
  else (la == nu).
Definition MN_coeff_fast la mu := MN_coeff_rec la mu [::].

Section Tests.

(* Compute MN_coeff_rec [:: 3; 3; 1; 1]%N [:: 5; 2; 1]%N [::]. *)

(** Tests :
[
sage: s(p[3, 3, 1, 1]).coefficient([5, 2, 1])
-2
]
*****)
Goal MN_coeff_fast [:: 5; 2; 1]%N [:: 3; 3; 1; 1]%N = - 2%:R.
Proof. by []. Abort.
(** Tests :
[
sage: s(p[5, 2, 1]).coefficient([3, 3, 1, 1])
1
]
*****)
Goal MN_coeff_fast [:: 3; 3; 1; 1]%N [:: 5; 2; 1]%N = 1%:R.
Proof. by []. Abort.

(** Tests :
[
sage: s(p[6, 5, 5, 4, 2, 1]).coefficient([12, 5, 2, 2, 1, 1])
4
]
*****)
Goal MN_coeff_fast [:: 12; 5; 2; 2; 1; 1]%N [:: 6; 5; 5; 4; 2; 1]%N = 4%:R.
Proof. by []. Abort.
(** Tests :
[
sage: s(p[6, 5, 5, 4, 2, 1]).coefficient([12, 5, 3, 1, 1, 1])
-2
]
*****)
Goal MN_coeff_fast [:: 12; 5; 3; 1; 1; 1]%N [:: 6; 5; 5; 4; 2; 1]%N = - 2%:R.
Proof. by []. Abort.
Goal MN_coeff_fast [:: 12; 5; 3; 2; 1]%N [:: 6; 5; 5; 4; 2; 1]%N = - 3%:R.
Proof. by []. Abort.
Goal MN_coeff_fast [:: 12; 5; 4; 1; 1]%N [:: 6; 5; 5; 4; 2; 1]%N = 2%:R.
Proof. by []. Abort.
Goal MN_coeff_fast [:: 12; 5; 4; 2]%N [:: 6; 5; 5; 4; 2; 1]%N = 4%:R.
Proof. by []. Abort.

End Tests.


