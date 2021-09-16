(** * Combi.Combi.composition : Integer Composition *)
(******************************************************************************)
(*      Copyright (C) 2014-2018 Florent Hivert <florent.hivert@lri.fr>        *)
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
(** * Integer Compositions.

Integer Composition are stored as [seq nat]. We define the following:

- [is_comp s]   == [s] is a composition, ie. [s] doesn't contains any 0
- [is_comp_of_n sm s] == [s] is a composition of sum [sm]
- [intcomp]     == a sigma type for [is_comp]

- [intcompn sm] == a sigma type for the predicate [is_comp_of_n sm].
               this is canonically a [subFinType]

- [rowcomp d]   == the trivial composition
- [rowcompn d]  == the trivial composition as a [intcompn d]

- [colcomp d]   == the composition [[:: 1; 1; ...]]
- [colcompn d]  == the composition [[:: 1; 1; ...]] as a [intcompn d]

Bijection with subsets: Consistently, with permutation starting at 0,
descents are starting at zero and therefore of type ['I_n.-1].
In the following we assume.

- [partsums s]  == sorted sequence of partial sums (excluding the trivial
                   and full sum)
- [descset c]   == the descent set of [c : intcompn n]
- [from_descset d] == the composition (of type [c : intcompn n]) whose
                   descent set is [d : {set 'I_n.-1}].

Compositions and partitions:

- [partn_of_compn n c] == the partition in ['P_n] obtained by sorting
                   [c : intcompn n]
******)
Require Import mathcomp.ssreflect.ssreflect.
From mathcomp Require Import ssrbool ssrfun ssrnat eqtype fintype choice.
From mathcomp Require Import seq bigop path binomial finset.
Require Import tools combclass sorted partition.

Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.


(** ** Definitions and basic properties *)
Section Defs.

Implicit Type s : seq nat.

Definition is_comp s := 0 \notin s.

Lemma is_compP s : reflect (forall i, i \in s -> i != 0) (is_comp s).
Proof.
rewrite /is_comp; apply (iffP idP) => [H0 i iins|H].
- by move: H0; apply contra => /eqP <-.
- by apply/negP => /H.
Qed.

Lemma is_comp1 i : is_comp [:: i] = (i != 0).
Proof. by rewrite /is_comp inE /= eq_sym. Qed.

Lemma is_comp_cons i s : is_comp (i :: s) = (i != 0) && (is_comp s).
Proof. by rewrite /is_comp inE negb_or eq_sym. Qed.

Lemma is_comp_rcons s sn : is_comp (rcons s sn) = (sn != 0) && (is_comp s).
Proof.
by rewrite /is_comp -(mem_rev (rcons _ _)) rev_rcons inE negb_or mem_rev eq_sym.
Qed.

Lemma is_comp_cat s1 s2 : is_comp (s1 ++ s2) = (is_comp s1) && (is_comp s2).
Proof. by rewrite /is_comp mem_cat negb_or. Qed.

(** Compositions and sumn *)
Lemma comp0 s : is_comp s -> sumn s = 0 -> s = [::].
Proof. by rewrite /is_comp; case: s => //= [[|a] l]. Qed.

Lemma size_comp s : is_comp s -> size s <= sumn s.
Proof.
rewrite /is_comp; elim: s => [//= | [|s0] s IHs] //.
rewrite negb_or /= => /IHs/leq_ltn_trans; apply.
by rewrite addSnnS; apply leq_addl.
Qed.

End Defs.


(** * Sigma Types for Compositions *)
Structure intcomp : Type := IntComp {cval :> seq nat; _ : is_comp cval}.
Canonical intcomp_subType := Eval hnf in [subType for cval].
Definition intcomp_eqMixin := Eval hnf in [eqMixin of intcomp by <:].
Canonical intcomp_eqType := Eval hnf in EqType intcomp intcomp_eqMixin.
Definition intcomp_choiceMixin := Eval hnf in [choiceMixin of intcomp by <:].
Canonical intcomp_choiceType :=
  Eval hnf in ChoiceType intcomp intcomp_choiceMixin.
Definition intcomp_countMixin := Eval hnf in [countMixin of intcomp by <:].
Canonical intcomp_countType :=
  Eval hnf in CountType intcomp intcomp_countMixin.

Lemma intcompP (p : intcomp) : is_comp p.
Proof. by case: p. Qed.

#[export] Hint Resolve intcompP : core.


Fixpoint enum_compn_rec aux n : (seq (seq nat)) :=
  if aux is aux'.+1 then
    if n == 0 then [:: [::]]
    else
      flatten [seq [seq i :: p | p <- enum_compn_rec aux' (n - i) ] |
               i <- iota 1 n]
  else [:: [::]].
Definition enum_compn n := enum_compn_rec n n.

Definition is_comp_of_n sm := [pred s | (sumn s == sm) & is_comp s].

Lemma enum_compn_rec_any aux1 aux2 n :
  n <= aux1 -> n <= aux2 -> enum_compn_rec aux1 n = enum_compn_rec aux2 n.
Proof.
elim: aux1 aux2 n => [| aux1 IHaux1] aux2 n /=.
  by rewrite leqn0 => /eqP -> //=; case aux2.
case: (altP (n =P 0)) => [-> | Hn Haux1] //=; first by case aux2.
case: aux2 => [| aux2 /= Haux2].
  by rewrite leqn0 => /eqP H; rewrite H eq_refl in Hn.
rewrite (negbTE Hn); congr flatten; apply eq_in_map => i.
rewrite mem_iota add1n ltnS => /andP [Hi _].
congr map; apply: IHaux1; rewrite leq_subLR.
- by apply: (leq_trans Haux1); rewrite -{1}(add0n aux1) ltn_add2r.
- by apply: (leq_trans Haux2); rewrite -{1}(add0n aux2) ltn_add2r.
Qed.

Lemma enum_compn_any aux n :
  n <= aux -> enum_compn_rec aux n = enum_compn n.
Proof. by rewrite /enum_compn => Hn; apply enum_compn_rec_any. Qed.

Lemma enum_compnE n :
  n != 0 ->
  enum_compn n = flatten [seq [seq i :: p | p <- enum_compn (n - i) ] |
                          i <- iota 1 n].
Proof.
rewrite -(enum_compn_any (leqnSn n)) /= => /negbTE ->.
congr flatten; apply eq_in_map => i.
rewrite mem_iota add1n ltnS => /andP [Hi _].
congr map; apply enum_compn_any.
by rewrite leq_subLR; apply: leq_addl.
Qed.

Lemma enum_compn_allP n : all (is_comp_of_n n) (enum_compn n).
Proof.
rewrite /is_comp_of_n /is_comp /enum_compn.
elim: n {1 3 5}n (leqnn n) => [|aux IHaux] n /=.
  by rewrite /= leqn0 !andbT => /eqP ->.
move=> Hn.
case: (altP (n =P 0)) => [-> //| neq0].
apply/allP => /= lst /flatten_mapP [/= i].
rewrite mem_iota add1n ltnS => /andP [lt0i lein] /mapP [/= s Hs] ->{lst}.
have {}/IHaux/allP/(_ s Hs)/= : n - i <= aux.
  rewrite leq_subLR; apply (leq_trans Hn).
  case: i lt0i {lein Hs} => // i _.
  by rewrite addSnnS; apply leq_addl.
rewrite negb_or => /andP [/eqP ->] ->.
rewrite subnKC // eq_refl /= andbT.
by rewrite eq_sym -lt0n.
Qed.

Lemma enum_compn_countE n :
  forall s, is_comp_of_n n s -> count_mem s (enum_compn n) = 1.
Proof.
rewrite /is_comp_of_n /is_comp /enum_compn.
elim: n {1 3 5}n (leqnn n) => [|aux IHaux] n /=.
  rewrite leqn0 => /eqP -> s.
  rewrite andbC => /andP [/comp0 H /eqP /H{H} ->].
  by rewrite eq_refl.
move=> Hn [|s0 s] /andP [/= ]; first by move=> /eqP <-.
rewrite negb_or => Hsum /andP [s0neq0] Hs.
have /negbTE -> : n != 0.
  move: s0neq0; apply contra => /eqP Hn0.
  by move: Hsum; rewrite Hn0 addn_eq0 => /andP [/eqP ->].
rewrite count_flatten -map_comp.
rewrite (eq_map (f2 := fun i => i == s0 : nat)); first last.
  move=> /= i; rewrite count_map /=.
  case (altP (i =P s0)) => [Heq | /negbTE Hneq].
  - subst s0; rewrite (eq_count (a2 := xpred1 s)); first last.
      by move=> x; rewrite /= -eqseqE /= eq_refl /=.
    rewrite {}IHaux //=.
    + rewrite leq_subLR; apply (leq_trans Hn).
      case: i s0neq0 {Hsum} => // i _.
      by rewrite addSnnS; apply leq_addl.
    + by rewrite Hs andbT -(eqP Hsum) addKn.
  - rewrite (eq_count (a2 := pred0)); first by rewrite count_pred0.
    by move=> t; rewrite /= -eqseqE /= Hneq.
rewrite sumn_pred1_iota add1n ltnS -(eqP Hsum) leq_addr andbT.
by rewrite lt0n eq_sym s0neq0.
Qed.

Lemma enum_compnP n s : (is_comp_of_n n s) = (s \in enum_compn n).
Proof.
apply/idP/idP; last by move/(allP (enum_compn_allP n)).
by rewrite -has_pred1 has_count; move/enum_compn_countE ->.
Qed.


Section CompOfn.

Variable n : nat.


Structure intcompn : Set :=
  IntCompN {cnval :> seq nat; _ : is_comp_of_n n cnval}.
Canonical intcompn_subType := Eval hnf in [subType for cnval].
Definition intcompn_eqMixin := Eval hnf in [eqMixin of intcompn by <:].
Canonical intcompn_eqType := Eval hnf in EqType intcompn intcompn_eqMixin.
Definition intcompn_choiceMixin :=
  Eval hnf in [choiceMixin of intcompn by <:].
Canonical intcompn_choiceType :=
  Eval hnf in ChoiceType intcompn intcompn_choiceMixin.
Definition intcompn_countMixin := Eval hnf in [countMixin of intcompn by <:].
Canonical intcompn_countType :=
  Eval hnf in CountType intcompn intcompn_countMixin.
Canonical intcompn_subCountType := Eval hnf in [subCountType of intcompn].
Let type := sub_finType intcompn_subCountType
                        (enum_compn_allP n) (@enum_compn_countE n).
Canonical intcompn_finType := Eval hnf in [finType of intcompn for type].
Canonical intcompn_subFinType := Eval hnf in [subFinType of intcompn].

Implicit Type (c : intcompn) (d : {set 'I_n.-1}).

Lemma intcompnP c : is_comp c.
Proof using. by case: c => /= c /andP []. Qed.

Hint Resolve intcompnP : core.

Definition intcomp_of_intcompn c := IntComp (intcompnP c).
Coercion intcomp_of_intcompn : intcompn >-> intcomp.

Lemma intcompn_sumn c : sumn c = n.
Proof using. by case: c => /= c /andP [/eqP]. Qed.

Lemma enum_intcompnE : map val (enum {:intcompn}) = enum_compn n.
Proof using. rewrite /=; exact: enum_subE. Qed.

Lemma card_intcompn : #|{:intcompn}| = 2 ^ n.-1.
Proof.
rewrite /= !cardT -!(size_map val) !enumT unlock !subType_seqP /=.
elim/ltn_ind: n => [[_ | i IHi]] /=; first by rewrite expn0.
rewrite enum_compnE // size_allpairs_dep sumn_mapE.
rewrite -{1}(subn0 i.+1) -subSS -/(index_iota _ _) big_add1 /= big_mkord.
transitivity (\sum_(k < i.+1) 2 ^ k.-1).
  rewrite (reindex_inj rev_ord_inj) /=; apply eq_bigr => k _.
  by rewrite !subSS subKn ?IHi // -ltnS.
rewrite big_ord_recl //= expn0 -(mul1n (\sum__ _)) -(predn_exp 2 i).
by rewrite add1n prednK // expn_gt0.
Qed.

Lemma rev_intcompn_spec c : is_comp_of_n n (rev c).
Proof.
by rewrite /is_comp_of_n /is_comp /= mem_rev sumn_rev; case: c.
Qed.
Definition rev_intcompn c := IntCompN (rev_intcompn_spec c).


(** * Bijection with subsets *)
Definition partsums s := [seq sumn (take i s) | i <- iota 1 (size s).-1].
Definition descset c : {set 'I_n.-1} :=
  [set i in pmap insub [seq i.-1 | i <- partsums c]].

Lemma size_partsums s : size (partsums s) = (size s).-1.
Proof. by rewrite size_map size_iota. Qed.

Lemma all_partsums c : all (fun i => 0 < i < n) (partsums c).
Proof.
rewrite all_map; apply/allP => i; rewrite mem_iota add1n.
case: c => [[|c0 c]] /andP [/eqP <-]/=; first by case: i.
rewrite is_comp_cons -lt0n => /andP[Hc0 Hc].
case: i => //= i /ltnSE ltisz.
rewrite (leq_trans Hc0) ?leq_addr //= ltn_add2l {c0 Hc0}.
rewrite -{2}(cat_take_drop i c) sumn_cat -addn1 leq_add2l.
rewrite (drop_nth 0 ltisz) /= (leq_trans _ (leq_addr _ _)) // lt0n.
by move: Hc; apply contra => /eqP <-; exact: mem_nth.
Qed.

Lemma from_descset_spec d :
  is_comp_of_n n (if n is 0 then [::]
                  else pairmap (fun a b => b - a) 0
                               (rcons [seq (val i).+1 | i in d] n)).
Proof.
case: n d => // n0; set n' := n0.+1 => d.
have Hsort : sorted ltn [seq (val i).+1 | i in d].
  rewrite /image_mem /enum_mem -enumT /= sorted_map; apply: sorted_filter.
  - by move => i j k /= /ltn_trans; apply.
  - have /eq_sorted-> :
      relpre nat_of_ord ltn =2 fun i j : 'I_n'.-1 => i < j by [].
    exact: enum_ord_sorted_ltn.
have Hall : all (fun i => 0 < i < n') [seq (val i).+1 | i in d].
  by apply/allP => i /mapP/=[[io Hio /= _ ->]]/=; exact: Hio.
have {}Hsort : sorted ltn (rcons [seq (val i).+1 | i in d] n').
  case: [seq _ | i in _] Hall Hsort => // a l Hall /sorted_rcons; apply.
  by move: Hall => /allP/(_ _ (mem_last _ _))/andP[_].
rewrite /is_comp_of_n /=.
elim/last_ind: [seq _ | i in _] Hsort Hall => [|s sn IHs]/= Hsort Hall.
  by rewrite addn0 subn0 eqxx.
have lt_last : last 0 s < sn.
  move: Hsort {IHs} => /sorted_rconsK.
  case/lastP: s Hall => [/andP[/andP[]]// |s sn1 _].
  rewrite last_rcons -!cats1 -catA => /sorted_catR /=.
  by rewrite andbT.
have {Hsort}/IHs Hrec : sorted ltn (rcons s n').
  case: s Hall Hsort {IHs lt_last} => // a l /allP Hall.
  move/sorted_rconsK/sorted_rconsK/sorted_rcons; apply.
  suff /Hall/andP[] : last a l \in rcons (a :: l) sn by [].
  by rewrite mem_rcons inE mem_last orbT.
move: Hall; rewrite all_rcons => /andP[/= /andP[_ lt_sn_n] {}/Hrec/andP[]].
rewrite -!cats1 !pairmap_cat last_cat !sumn_cat /= !addn0 => /eqP Hsum Hcomp.
apply/andP; split => [{Hcomp}|{Hsum}].
- rewrite -{2}Hsum -addnA eqn_add2l addnC addnBA //; last exact: ltnW.
  by rewrite subnK // ltnW.
- move: Hcomp; rewrite !is_comp_cat => /andP[-> _]/=.
  by rewrite !is_comp1 -!lt0n !subn_gt0 lt_last lt_sn_n.
Qed.
Definition from_descset d := IntCompN (from_descset_spec d).

Lemma diff_nth_sumn_take s i m :
  m <= size s -> i.+1 < m ->
  nth 0 [seq sumn (take i0 s) | i0 <- iota 1 m] i.+1 -
  nth 0 [seq sumn (take i0 s) | i0 <- iota 1 m] i = nth 0 s i.+1.
Proof.
move=> Hm Hi.
rewrite !(nth_map 0) ?size_iota //=; last exact: (ltn_trans _ Hi).
rewrite !nth_iota //=; last exact: (ltn_trans _ Hi).
rewrite !add1n !sumn_take [X in X - _]big_nat_recr //=.
by rewrite addnC addnK.
Qed.

Lemma enum_descsetE s : [seq (val i).+1 | i in descset s] = partsums s.
Proof.
apply: (irr_sorted_eq (ltn_trans) ltnn).
- rewrite sorted_map (eq_sorted (e' := fun i j => val i < val j)).
  rewrite /enum_mem -enumT /= sorted_filter // ?enum_ord_sorted_ltn //.
  by move=> i j k /ltn_trans; apply.
- by move=> i j /=; rewrite ltnS.
- case: s => s /= /andP[_ /is_compP Hcomp].
  apply/(sorted1P 0) => i.
  rewrite size_map size_iota -[nth _ _ _ < _]subn_gt0 => Hi.
  rewrite diff_nth_sumn_take ?leq_pred // lt0n.
  apply: Hcomp; apply: mem_nth.
  by case: (size s) Hi => //= sz /ltn_trans; apply.
move=> i; apply/mapP/idP => [[/= [x Hx]] | Hi].
- rewrite mem_enum /descset inE mem_pmap_sub /=.
  move/mapP => [/= j Hj ->{x Hx} ->{i}].
  by have /= /allP/(_ _ Hj) := all_partsums s; case: j Hj.
- have /= /allP/(_ _ Hi) lt0in := all_partsums s.
  have ltin : i.-1 < n.-1 by case: n i lt0in {Hi} => [|n0][|i].
  exists (Ordinal ltin) => /=; last by case: i lt0in {Hi ltin}.
  rewrite mem_enum /descset inE /= mem_pmap_sub /=.
  by apply/mapP; exists i.
Qed.

Lemma card_descset s : #|descset s| = (size s).-1.
Proof.
have := congr1 size (enum_descsetE s); rewrite size_map cardE => ->.
by rewrite size_partsums.
Qed.

Lemma descsetK : cancel descset from_descset.
Proof.
case => [s Hs]; apply val_inj => /=.
rewrite enum_descsetE /=; move: Hs => /andP [/eqP Hsum Hcomp].
case: n Hsum => [/(comp0 Hcomp) -> // | n0]; set n' := n0.+1 => Hsum {Hcomp}.
case: s Hsum => [|s0 s']//; move Hs: (s0 :: s') => s Hsum.
have -> : rcons (partsums s) n' = [seq sumn (take i s) | i <- iota 1 (size s)].
  rewrite /partsums -{}Hsum -Hs [size (s0 :: s')]/=.
  by rewrite -{2}(addn1 (size s')) iotaD /= map_cat /= take_size cats1.
apply: (eq_from_nth (x0 := 0)) => [|i]; rewrite size_pairmap.
  by rewrite size_map size_iota.
move=> Hi; rewrite (nth_pairmap 0) //; rewrite size_map size_iota in Hi.
case: i Hi => [|i] /= Hi; first by rewrite -Hs /= take0 /= addn0 subn0.
exact: diff_nth_sumn_take.
Qed.

Lemma descset_bij : bijective descset.
Proof.
apply: (inj_card_bij (can_inj descsetK)); rewrite /= card_intcompn.
by rewrite -cardsT -powersetT card_powerset cardsT card_ord.
Qed.

Lemma from_descsetK : cancel from_descset descset.
Proof. by rewrite (bij_can_sym descset_bij); exact: descsetK. Qed.

End CompOfn.

Lemma intcompn0 (sh : intcompn 0) : sh = [::] :> seq nat.
Proof.
case: sh => sh Hsh /=; move: Hsh; rewrite enum_compnP.
by rewrite /enum_compn /= inE => /eqP.
Qed.

Lemma intcompn1 (sh : intcompn 1) : sh = [:: 1] :> seq nat.
Proof.
case: sh => sh Hsh /=; move: Hsh; rewrite enum_compnP.
by rewrite /enum_compn /= inE => /eqP.
Qed.

Lemma intcompn2 (sh : intcompn 2) :
  sh = [:: 2]  :> seq nat \/ sh = [:: 1; 1] :> seq nat.
Proof.
case: sh => sh Hsh /=; move: Hsh; rewrite enum_compnP.
by rewrite /enum_compn /= !inE => /orP [] /eqP ->; [right | left].
Qed.

Definition intcompn_cast m n (eq_mn : m = n) p :=
  let: erefl in _ = n := eq_mn return intcompn n in p.

Lemma intcompn_castE m n (eq_mn : m = n) p :
  val (intcompn_cast eq_mn p) = val p.
Proof. by subst m; case: p. Qed.

Definition rowcomp d := if d is _.+1 then [:: d] else [::].
Fact rowcompnP d : is_comp_of_n d (rowcomp d).
Proof. by case: d => [//= | d]; rewrite /is_comp_of_n /= addn0 eq_refl. Qed.
Canonical rowcompn d : intcompn d := IntCompN (rowcompnP d).

Definition colcomp d := nseq d 1%N.
Fact colcompnP d : is_comp_of_n d (colcomp d).
Proof. by elim: d => [| d]. Qed.
Canonical colcompn d : intcompn d := IntCompN (colcompnP d).


#[export] Hint Resolve intcompP intcompnP : core.

Lemma part_of_comp_subproof n (c : intcompn n) :
  is_part_of_n n (sort geq c).
Proof.
rewrite /is_part_of_n /= sumn_sort intcompn_sumn eq_refl /=.
rewrite is_part_sortedE; apply/andP; split.
- apply sort_sorted => x y; exact: leq_total.
- by rewrite mem_sort -/(is_comp c).
Qed.
Canonical partn_of_compn n (c : intcompn n) :=
  IntPartN (part_of_comp_subproof c).

(*
From mathcomp Require Import finset div.

Lemma card_preim_part_of_compn n (sh : 'P_n) :
  #|[set c | partn_of_compn c == sh]| =
  n`! %/ \prod_(i <- iota 1 n) (count_mem i sh)`!.
Proof.
*)

