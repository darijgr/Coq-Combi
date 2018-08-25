Require Import mathcomp.ssreflect.ssreflect.
From mathcomp Require Import ssrfun ssrbool eqtype ssrnat seq path choice.
From mathcomp Require Import finset fintype finfun tuple bigop ssralg ssrint.
From mathcomp Require Import fingroup perm zmodp binomial order.
From mathcomp Require Export finmap.
From SsrMultinomials Require Import ssrcomplements monalg.


Set Implicit Arguments.
Unset Strict Implicit.
Unset Printing Implicit Defensive.

Reserved Notation "f ::| g" (at level 20).
Reserved Notation "f *w* g" (at level 40, left associativity).
Reserved Notation "{ 'shalg' G [ K ] }"
  (at level 0, K, G at level 2, format "{ 'shalg'  G [ K ] }").

Import GRing.Theory.
Local Open Scope ring_scope.

(* Missing lemma in malg *)
Lemma scale_malgC (R : ringType) (A : choiceType) r a :
  r *: << a >> = << r *g a >> :> {malg R[A]}.
Proof.
Admitted.

Section MakeLinear.

Context {R : ringType}.
Context {A B : choiceType}.
Implicit Type f g : A -> {malg R[B]}.
Implicit Type m : A -> B.
Implicit Type (r : R).
Implicit Type (a : A) (b : B).
Implicit Type (x : {malg R[A]}) (y : {malg R[B]}).

Definition linmalg f x : {malg R[B]} :=
  \sum_(u : msupp x)  x@_(val u) *: f (val u).

(* The following proof require to go through enum      *)
(* This is not practical in complicated cases as below *)
Lemma linmalgB f a : linmalg f << a >> = f a.
Proof.
rewrite /linmalg /index_enum -enumT msuppU oner_eq0 enum_fset1 big_seq1 /=.
by rewrite mcoeffU eq_refl scale1r.
Qed.

(* Hard to prove due to the use of the old fset library *)
Lemma linmalg_is_linear f : linear (linmalg f).
Proof.
rewrite /linmalg => r /= a1 a2.
rewrite scaler_sumr.
apply/eqP/malgP => b.
Admitted.

Lemma linmalgE f g : f =1 g -> linmalg f =1 linmalg g.
Proof.
rewrite /linmalg => H x.
apply: eq_bigr => /= a _ /=.
by rewrite H.
Qed.

Canonical linmalg_additive f := Additive  (linmalg_is_linear f).
Canonical linmalg_linear f   := AddLinear (linmalg_is_linear f).

End MakeLinear.

Lemma linmalg_id (R : ringType) (A : choiceType) (f : A -> {malg R[A]}) :
  (f =1 fun a => << a >>) -> linmalg f =1 id.
Proof.
rewrite /linmalg=> H x.
rewrite [RHS]monalgE; apply eq_bigr => a _.
by rewrite H scale_malgC.
Qed.

Section MakeBilinearDef.

Context {R : ringType}.
Context {A B C : choiceType}.
Implicit Type (r : R).
Implicit Type (a : A) (b : B).
Implicit Type (x : {malg R[A]}) (y : {malg R[B]}).

Variable f g : A -> B -> {malg R[C]}.

Definition bilinmalg f x y : {malg R[C]} :=
  linmalg (fun v => (linmalg (f v)) y) x.
Definition bilinmalgr_head k f p q := let: tt := k in bilinmalg f q p.

Notation bilinmalgr := (bilinmalgr_head tt).

Local Notation "a *w* b" := (bilinmalg f a b).

Lemma bilinmalgP x y :
  x *w* y = \sum_(u : msupp x) \sum_(v : msupp y)
             x@_(val u) * y@_(val v) *: f (val u) (val v).
Proof.
rewrite /bilinmalg/linmalg; apply eq_bigr => a _.
rewrite scaler_sumr; apply eq_bigr => b _.
by rewrite scalerA.
Qed.

Lemma bilinmalgrP x y : bilinmalgr f y x = x *w* y.
Proof. by []. Qed.

Lemma bilinmalgE : f =2 g -> bilinmalg f =2 bilinmalg g.
Proof.
rewrite /bilinmalg => H x y /=.
apply: linmalgE => a.
exact: linmalgE => b.
Qed.

Lemma bilinmalgr_is_linear y : linear (bilinmalgr f y).
Proof. by move=> r x1 x2; rewrite !bilinmalgrP /bilinmalg linearP. Qed.

Canonical bilinmalgr_additive p := Additive (bilinmalgr_is_linear p).
Canonical bilinmalgr_linear p := Linear (bilinmalgr_is_linear p).

Lemma bilinmalgBB a b : << a >> *w* << b >> = f a b.
Proof. by rewrite /bilinmalg !linmalgB. Qed.

Lemma bilinmalgBA a y : << a >> *w* y = linmalg (f a) y.
Proof. by rewrite /bilinmalg linmalgB. Qed.

End MakeBilinearDef.

Notation bilinmalgr := (bilinmalgr_head tt).

(* possibility: not require a commutative ring but use the opposite ring *)
Lemma bilinmalgC (A B C : choiceType) (R : comRingType)
      (f : A -> B -> {malg R[C]}) x y :
  bilinmalgr (fun a b => f b a) x y = (bilinmalg f) x y.
Proof.
rewrite bilinmalgrP !bilinmalgP exchange_big /=.
apply: eq_bigr => a _; apply: eq_bigr => b _.
by rewrite mulrC.
Qed.

Section MakeBilinear.

Context {R : comRingType}.
Context {A B C : choiceType}.
Implicit Type (r : R).
Implicit Type (a : A) (b : B).
Implicit Type (x : {malg R[A]}) (y : {malg R[B]}).

Variable f : A -> B -> {malg R[C]}.

Local Notation "a *w* b" := (bilinmalg f a b).

Lemma bilinmalg_is_linear x : linear (bilinmalg f x).
Proof. by move=> r x1 x2; rewrite -![_ *w* _]bilinmalgC linearP. Qed.

Canonical bilinmalg_additive p := Additive (bilinmalg_is_linear p).
Canonical bilinmalg_linear p := Linear (bilinmalg_is_linear p).

End MakeBilinear.


Section ShuffleAlgebraDef.

Variable (A : choiceType) (R : comRingType).

Definition shalg := {malg R[seq A]}.
Definition shalg_of (_ : phant A) (_ : phant R) := shalg.

End ShuffleAlgebraDef.

Bind Scope ring_scope with shalg.
Bind Scope ring_scope with shalg_of.

Notation "{ 'shalg' R [ A ] }" :=
  (@shalg_of _ _ (Phant A) (Phant R)) : type_scope.

Section ShuffleAlgebra.

Variable (A : choiceType) (R : comRingType).

Implicit Type a b : A.
Implicit Type u v : seq A.
Implicit Type f g : {shalg R[A]}.

Notation "<< z *g k >>" := (mkmalgU k z).
Notation "<< k >>" := << 1 *g k >> : ring_scope.

Definition consl (a : A) := linmalg (fun u => (<< a :: u >> : {shalg R[A]})).

Local Notation "a ::| f" := (consl a f).

Lemma conslE a v : a ::| << v >> = << a :: v >>.
Proof. exact: linmalgB. Qed.

Lemma consl_is_linear a : linear (consl a).
Proof. exact: linmalg_is_linear. Qed.

Canonical consl_additive a := Additive  (consl_is_linear a).
Canonical consl_linear a   := AddLinear (consl_is_linear a).

Lemma consl0 a : a ::| 0 = 0. Proof. exact: raddf0. Qed.
Lemma conslD a q1 q2 : a ::| (q1 + q2) = a ::| q1 + a ::| q2.
Proof. exact: raddfD. Qed.
Lemma consl_sum a I r (P : pred I) (q : I -> {shalg R[A]}) :
  a ::| (\sum_(i <- r | P i) q i) = \sum_(i <- r | P i) a ::| (q i).
Proof. exact: raddf_sum. Qed.
Lemma conslZ a r q : a ::| (r *: q) = r *: (a ::| q).
Proof. by rewrite linearZ. Qed.


Fixpoint shufflew_aux a u shu v :=
  if v is b :: v' then (a ::| (shu v )) + (b ::| (shufflew_aux a u shu v'))
  else a ::| << u >>.

Fixpoint shufflew u v :=
  if u is a :: u' then shufflew_aux a u' (shufflew u') v
  else << v >>.

Lemma shuffleNilw v : shufflew [::] v = << v >>.
Proof. by []. Qed.

Lemma  shufflewNil v : shufflew v [::] = << v >>.
Proof. by case: v => [| i v] //=; rewrite conslE. Qed.

Lemma shufflewCons a u b v :
  shufflew (a :: u) (b :: v) =
  (a ::| (shufflew u (b :: v))) + (b ::| (shufflew (a :: u) v)).
Proof. by []. Qed.

Lemma shufflewC u v : shufflew u v = shufflew v u.
Proof.
elim: u v => [| a u IHu] v /=; first by rewrite shufflewNil.
elim: v => [| b v IHv] //=; first exact: conslE.
rewrite addrC; congr (consl _ _ + consl _ _) => //.
by rewrite IHu.
Qed.


Definition shuffle : {shalg R[A]} -> {shalg R[A]} -> {shalg R[A]} :=
  locked (bilinmalg shufflew).

Local Notation "f *w* g" := (shuffle f g).

Lemma shuffleC : commutative shuffle.
Proof.
rewrite /shuffle; unlock => f g.
rewrite -bilinmalgC /= -/shufflew.
rewrite (bilinmalgE (g := shufflew)) // => u v.
exact: shufflewC.
Qed.

Lemma shuffleE u v : << u >> *w* << v >> = shufflew u v.
Proof. by rewrite /shuffle; unlock; rewrite bilinmalgBB. Qed.

Lemma shufflenill : left_id << [::] >> shuffle.
Proof.
by rewrite /shuffle=> f; unlock; rewrite /bilinmalg linmalgB linmalg_id.
Qed.
Lemma shufflenilr : right_id << [::] >> shuffle.
Proof. by move=> f; rewrite shuffleC shufflenill. Qed.

Lemma shuffle_is_linear f : linear (shuffle f).
Proof. rewrite /shuffle; unlock; exact: linearP. Qed.
Canonical shuffle_additive p := Additive (shuffle_is_linear p).
Canonical shuffle_linear p := Linear (shuffle_is_linear p).

Lemma shuffle0r p : p *w* 0 = 0. Proof. exact: raddf0. Qed.
Lemma shuffleNr p q : p *w* (- q) = - (p *w* q).
Proof. exact: raddfN. Qed.
Lemma shuffleDr p q1 q2 : p *w* (q1 + q2) = p *w* (q1) + p *w* (q2).
Proof. exact: raddfD. Qed.
Lemma shuffleMnr p q n : p *w* (q *+ n) = p *w* q *+ n.
Proof. exact: raddfMn. Qed.
Lemma shuffle_sumr p I r (P : pred I) (q : I -> {shalg R[A]}) :
  p *w* (\sum_(i <- r | P i) q i) = \sum_(i <- r | P i) p *w* (q i).
Proof. exact: raddf_sum. Qed.
Lemma shuffleZr r p q : p *w* (r *: q) = r *: (p *w* q).
Proof. by rewrite linearZ. Qed.

Lemma shuffle0l p : 0 *w* p = 0.
Proof. by rewrite shuffleC linear0. Qed.
Lemma shuffleNl p q : (- q) *w* p = - (q *w* p).
Proof. by rewrite ![_ *w* p]shuffleC linearN. Qed.
Lemma shuffleDl p q1 q2 : (q1 + q2) *w* p = q1 *w* p + q2 *w* p.
Proof. by rewrite ![_ *w* p]shuffleC linearD. Qed.
Lemma shuffleBl p q1 q2 : (q1 - q2) *w* p = q1 *w* p - q2 *w* p.
Proof. by rewrite ![_ *w* p]shuffleC linearB. Qed.
Lemma shuffleMnl p q n : (q *+ n) *w* p = q *w* p *+ n.
Proof. by rewrite ![_ *w* p]shuffleC linearMn. Qed.
Lemma shuffle_suml p I r (P : pred I) (q : I -> {shalg R[A]}) :
  (\sum_(i <- r | P i) q i) *w* p = \sum_(i <- r | P i) (q i) *w* p.
Proof.
rewrite ![_ *w* p]shuffleC linear_sum /=.
apply eq_bigr => i _; exact: shuffleC.
Qed.
Lemma shuffleZl p r q : (r *: q) *w* p = r *: (q *w* p).
Proof. by rewrite ![_ *w* p]shuffleC linearZ. Qed.


Lemma shuffleCons a u b v :
  << a :: u >> *w* << b :: v >> =
    (a ::| (<< u >> *w* << b :: v >>)) + (b ::| (<< a :: u >> *w* << v >>)).
Proof. rewrite !shuffleE; exact: shufflewCons. Qed.

Lemma shuffleconsl a b f g :
  a ::| f *w* b ::| g = a ::| (f *w* b ::| g) + b ::| (a ::| f *w* g).
Proof.
(* raddf_sum expands g along (monalgE g) in \sum_(i : msupp g) _ *)
rewrite (monalgE g); rewrite !shuffle_sumr !consl_sum -(monalgE g) -big_split /=.
apply eq_bigr => vs _; move: (fsval vs) => v {vs}.
rewrite -[<< g@_v *g _ >>]scale_malgC.
rewrite !shuffleZr !conslZ /= -scalerDr; congr ( _ *: _) => {g}.

rewrite (monalgE f); rewrite !shuffle_suml !consl_sum -(monalgE f) -big_split /=.
apply eq_bigr => us _; move: (fsval us) => u {us}.
rewrite -[<< f@_u *g _ >>]scale_malgC.
rewrite !shuffleZl !conslZ -scalerDr; congr ( _ *: _) => {f}.
by rewrite shuffleCons addrC.
Qed.

Lemma shuffle_auxA u v w :
  << u >> *w* (<< v >> *w* << w >>) = (<< u >> *w* << v >>) *w* << w >>.
Proof.
elim: u v w => /= [| a u IHu] v w; first by rewrite ?(shufflenill, shufflenilr).
elim: v w => /= [| b v IHv] w; first by rewrite ?(shufflenill, shufflenilr).
elim: w => /= [| c w IHw]; first by rewrite ?(shufflenill, shufflenilr).
rewrite -!conslE.
rewrite !shuffleconsl ?shuffleDr ?shuffleDl.
rewrite !shuffleconsl ?shuffleDr ?shuffleDl.
rewrite [X in X + _ = _]addrC [RHS]addrC -!addrA.
congr (_ + _); rewrite !conslE.
- by rewrite IHv.
- rewrite [LHS]addrA [RHS]addrC -[RHS]addrA.
  congr (_ + _).
- by rewrite -conslD -shuffleDr -shuffleCons IHu.
- by rewrite -conslD IHw -shuffleDl shuffleCons.
Qed.

Lemma shuffleA : associative shuffle.
Proof.
move=> a b c.
rewrite (monalgE c) ?(shuffle_sumr, shuffle_suml).
apply eq_bigr => ws _; move: (val ws) => w {ws}.
rewrite -[<< c@_w *g _ >>]scale_malgC ?(shuffleZr, shuffleZl).
congr ( _ *: _) => {c}.
rewrite (monalgE b) ?(shuffle_sumr, shuffle_suml).
apply eq_bigr => vs _; move: (val vs) => v {vs}.
rewrite -[<< b@_v *g _ >>]scale_malgC ?(shuffleZr, shuffleZl).
congr ( _ *: _) => {b}.
rewrite (monalgE a) ?(shuffle_sumr, shuffle_suml).
apply eq_bigr => us _; move: (val us) => u {us}.
rewrite -[<< a@_u *g _ >>]scale_malgC ?(shuffleZr, shuffleZl).
by rewrite shuffle_auxA.
Qed.

Lemma shuffle_distr : left_distributive shuffle +%R.
Proof. move=> a b c; exact: shuffleDl. Qed.

Lemma malgnil_eq0 : << [::] >> != 0 :> {shalg R[A]}.
Proof. by apply/malgP => /(_ [::]) /eqP; rewrite !mcoeffsE oner_eq0. Qed.

Lemma shuffle_scalAl r f g : r *: (f *w* g) = (r *: f) *w* g.
Proof. by rewrite shuffleZl. Qed.
Lemma shuffle_scalAr r f g : r *: (f *w* g) = f *w* (r *: g).
Proof. by rewrite shuffleZr. Qed.

Canonical shalg_eqType := [eqType of {shalg R[A]}].
Canonical shalg_choiceType := [choiceType of {shalg R[A]}].
Canonical shalg_zmodType := [zmodType of {shalg R[A]}].
Canonical shalg_lmodType := [lmodType R of {shalg R[A]}].

Definition shalg_ringRingMixin :=
  ComRingMixin (R := [zmodType of {shalg R[A]}])
               shuffleA shuffleC shufflenill shuffle_distr malgnil_eq0.
Canonical shalg_ringType :=
  Eval hnf in RingType {shalg R[A]} shalg_ringRingMixin.
Canonical shalg_comRingType := ComRingType {shalg R[A]} shuffleC.
Canonical shalg_LalgType := LalgType R {shalg R[A]} shuffle_scalAl.
Canonical shalg_algType := CommAlgType R {shalg R[A]}.

Lemma shalg_mulE f g : f * g = f *w* g.
Proof. by []. Qed.

End ShuffleAlgebra.


Section Tests.

Lemma bla2 : (<<[:: 2]>> : {shalg int[nat]}) * <<[:: 2]>> = 2%:R *: <<[:: 2; 2]>>.
Proof.
rewrite shalg_mulE shuffleCons shufflenill shufflenilr conslE.
by rewrite -[in 2%:R]addn1 natrD scalerDl scale1r.
Qed.

End Tests.
