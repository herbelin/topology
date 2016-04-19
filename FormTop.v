Require Import Frame.
Set Asymmetric Patterns.

(** Formal topologies. *)

(** Formal topologies as defined in

    [1]
    Inductively generated formal topologies.
    Thierry Coquand, Giovanni Sambin, Jan Smith, Silvio Valentini.
    2000.
    http://www.math.unipd.it/~silvio/papers/WorkInProg/tig000615.pdf

    I highly suggest reading their paper alongside this module!
    I will refer to it as [1].
*)

Definition compose {S T U} (F : S -> T -> Prop)
  (G : T -> U -> Prop) (s : S) (u : U) : Prop :=
    exists t, F s t /\ G t u.

Module FormTop.

Generalizable All Variables.

Section Defn.

(** We assume we have some type [S] equipped
    with a partial order. *)
Context {S} {le : S -> S -> Prop} {PO : PreO.t S le}.

(** States that [c] is less than or equal to the minimum of
    [a] and [b]. *)
Definition down (a b c : S) : Prop :=
  le c a /\ le c b.

(** Definition 2.1 of [1].
    Definition of when the [Cov] relation is indeed a formal cover.
    Here, the [Cov] relation means the little triangle that is
    seen in the literature. *)
Class t { Cov : S -> (S -> Prop) -> Prop } :=
  { refl : forall (a : S) (U : S -> Prop), U a -> Cov a U
  ; trans : forall (a : S) (U V : S -> Prop), 
       Cov a U 
     -> (forall (a' : S), U a' -> Cov a' V)
     -> Cov a V
  ; le_left : forall (a b : S) (U : S -> Prop)
     , le a b -> Cov b U -> Cov a U
  ; le_right : forall (a : S) (U V : S -> Prop)
    , Cov a U -> Cov a V
    -> Cov a (fun c => exists u v, U u /\ V v /\ down u v c)
  }.

Arguments t : clear implicits.

(** Definition of a formal cover that also has a positivity predicate. *)
Record tPos { Cov : S -> (S -> Prop) -> Prop } {Pos : S -> Prop} :=
  { cov :> t Cov
  ; mono : forall a U, Pos a -> Cov a U -> exists b, U b /\ Pos b
  ; positive : forall a U, (Pos a -> Cov a U) -> Cov a U
  }.

Arguments tPos : clear implicits.

Lemma monotone {Cov} : t Cov
  -> forall (U V : S -> Prop)
  , (forall a : S, U a -> V a)
  -> forall a, Cov a U -> Cov a V.
Proof.
intros. eauto using trans, refl.
Qed.

Lemma subset_equiv {Cov} : t Cov
  -> forall (U V : S -> Prop)
  , (forall a : S, U a <-> V a)
  -> forall a, Cov a U <-> Cov a V.
Proof.
intros. split; apply monotone; firstorder.
Qed.

(** Inductively generated formal topologies. See section
    3 of [1]. *)

Variable I : S -> Type.
Variable C : forall (s : S), I s -> (S -> Prop).

Definition stable (Cov : S -> (S -> Prop) -> Prop) :=
  forall a b U V, Cov a U -> Cov b V
  -> forall c, le c a -> le c b ->
    Cov c (fun s => exists u v, U u /\ V v /\ down u v s).

Definition localized := forall (a c : S),
  le a c -> forall (i : I c),
  exists (j : I a),
  (forall s, C a j s -> exists u, C c i u /\ down a u s).

(** Given the axiom set [I] and [C], this generates the
    formal cover corresponding to that axiom set. *)
Inductive GCov : S -> (S -> Prop) -> Prop :=
  | grefl : forall (a : S) (U : S -> Prop), U a -> GCov a U
  | gle_left : forall (a b : S) (U : S -> Prop)
     , le a b -> GCov b U -> GCov a U
  | ginfinity : forall (a : S) (i : I a) (U : S -> Prop),
     (forall u, C a i u -> GCov u U) -> GCov a U.

Hypothesis loc : localized. 

Lemma gmonotone : forall (a : S) (U V : S -> Prop),
  (forall u, U u -> V u) -> GCov a U -> GCov a V.
Proof.
intros. induction H0.
- apply grefl. apply H. assumption.
- eapply gle_left. eassumption. apply IHGCov.
  assumption.
- eapply ginfinity. intros. apply H1. apply H2.
  apply H.
Qed.

Lemma gsubset_equiv : forall (U V : S -> Prop)
  , (forall a : S, U a <-> V a)
  -> forall a, GCov a U <-> GCov a V.
Proof.
intros. split; apply gmonotone; intro; apply H; assumption.
Qed.

(** Proposition 3.5 of [1] *)
Lemma le_infinity : forall (a c : S), le a c ->
  forall (i : I c) (U : S -> Prop), 
  (forall u v, C c i v -> down a v u -> GCov u U)
  -> GCov a U.
Proof.
unfold localized in loc.
intros. destruct (loc a c H i).
apply (ginfinity _ x).
intros.
specialize (H1 u H2).
destruct H1. destruct H1.
eapply H0. 2:eassumption. assumption.
Qed.

Lemma GCov_stable : stable GCov.
Proof.
unfold localized in loc.
unfold stable. intros. generalize dependent c.
induction H.
- induction H0; intros.
  + apply grefl. exists a. exists a0. unfold down. intuition.
  + apply IHGCov. apply H2. 
    eapply PreO.le_trans; eassumption.
  + pose proof (loc c a0 H3 i) as loc1.
    destruct loc1 as [j loc'].
    apply (ginfinity _ j).

    intros. specialize (loc' u H4).
    destruct loc'. destruct H5. destruct H6.
    eapply H1. eassumption.
    eapply PreO.le_trans. apply H6. assumption.
    assumption.
- intros. 
  apply IHGCov. eapply PreO.le_trans. apply H2. apply H. 
  apply H3.
- intros. pose proof (loc c a H2 i) as loc1.
  destruct loc1 as [j loc'].
  apply (ginfinity _ j).

  intros. specialize (loc' u H4).
  destruct loc'. destruct H5. destruct H6.
  eapply H1. eassumption. assumption.
  eapply PreO.le_trans. apply H6. assumption.
Qed.

(** Theorem 3.6 of [1].
    In fact, the formal cover that we defined based on the axiom set 
    indeed satistifes the requirements of being a formal topology. *)
Instance GCov_formtop : t GCov.
Proof.
unfold localized in loc.
constructor.
- apply grefl.
- intros. induction H.
  + apply H0. assumption.
  + eapply gle_left. apply H. apply IHGCov.
    apply H0.
  + apply (ginfinity _ i). intros. apply H1; assumption.
- apply gle_left.
- intros.
  pose proof GCov_stable as stab.
  unfold stable in stab.
  eapply GCov_stable. eassumption. eassumption.
  apply PreO.le_refl. apply PreO.le_refl.
Qed.


End Defn.

Arguments t {S} _ _ : clear implicits.
Arguments localized {S} le {I} C : clear implicits.
Arguments GCov {S} le {I} C _ _ : clear implicits.

Require Import Morphisms RelationClasses Basics.
Instance t_proper {S : Type} : 
  Proper ((eq ==> eq ==> iff) ==> (eq ==> eq ==> iff) ==> iff) (@t S).
Proof.
Admitted.


Section Localize.

Context {S : Type} {le : S -> S -> Prop}.
Variable (PO : PreO.t S le).
Variable (Ix : S -> Type) (C : forall s, Ix s -> (S -> Prop)).

Definition IxL (a : S) := 
  { i : sigT (fun c => Ix c) | match i with
    | existT c k => le a c end }.

Definition CL (a : S) : IxL a -> S -> Prop := 
  fun i => match i with
  | exist (existT c k) _ => fun z => exists u, C c k u /\ @down _ le a u z
  end.

Theorem Llocalized : localized le CL.
Proof.
unfold localized.
intros. destruct i. simpl in *. destruct x.
exists (exist (fun i' => match i' with existT c k => le a c end) 
  (existT _ x i) (PreO.le_trans _ _ _ H y)).
simpl. intros.
destruct H0 as (u & Cxiu & downaus).
exists s. split. exists u. split. assumption. unfold down in *.
  destruct downaus.
  split. eapply PreO.le_trans. apply H0. apply H.
  assumption.
  unfold down in *. destruct downaus.
  split; [assumption | apply PreO.le_refl].
Qed.

End Localize.

Section ToFrame.
Context {S : Type}.
Variable (le : S -> S -> Prop) (Cov : S -> (S -> Prop) -> Prop).

Definition Sat (U : S -> Prop) (s : S) : Prop :=
  Cov s U.

Definition leA (U V : S -> Prop) : Prop := forall s, Sat U s -> Sat V s.
Definition eqA (U V : S -> Prop) : Prop := forall s, Sat U s <-> Sat V s.

Definition minA (U V : S -> Prop) (s : S) : Prop :=
  exists u v, U u /\ V v /\ @down _ le u v s.

Definition maxA (U V : S -> Prop) (s : S) : Prop := U s \/ V s.

Definition supA I (f : I -> (S -> Prop)) (s : S) : Prop := exists i, f i s.

Definition LOps : Lattice.Ops (S -> Prop) :=
  {| Lattice.le := leA
  ;  Lattice.eq := eqA
  ;  Lattice.max := maxA
  ;  Lattice.min := minA
  |}.

Instance LOps' : Lattice.Ops (S -> Prop) := LOps.

Definition FOps : Frame.Ops (S -> Prop) := 
  {| Frame.LOps := LOps
   ; Frame.sup := supA
  |}.

Instance FOps' : Frame.Ops (S -> Prop) := FOps.

Hypothesis PO : PreO.t S le.
Hypothesis tS : @t S le Cov. 

Theorem FramePreO : PreO.t (S -> Prop) leA.
Proof.
constructor; unfold leA, Sat; intros.
- assumption.
- apply H0. apply H. assumption.
Qed.

Require Import Morphisms SetoidClass.

Theorem FramePO : PO.t (S -> Prop) leA eqA.
Proof.
constructor; unfold eqA, Sat; intros.
- apply FramePreO.
- unfold leA, Sat. solve_proper.
- unfold leA, Sat in *. intuition.
Qed.

Theorem FrameLatt : Lattice.t (S -> Prop) LOps.
Proof.
constructor; intros.
- apply FramePO.
- simpl. repeat intro. unfold eqA, Sat in *.
  split; intros. 
  + eapply trans. apply H1.
    unfold maxA in *.
    intros. destruct H2. apply (monotone tS y).
    auto. apply H. apply refl. assumption.
    apply (monotone tS y0). auto.
    apply H0.  apply refl. assumption.
  + eapply trans. apply H1.
    unfold maxA in *.
    intros. destruct H2. apply (monotone tS x).
    auto. apply H. apply refl. assumption.
    apply (monotone tS x0). auto.
    apply H0.  apply refl. assumption.
- constructor.
  + simpl. unfold leA, maxA, Sat. intros.
    apply trans with l. assumption.
    intros. apply refl. auto.
  + simpl. unfold leA, maxA, Sat. intros.
    apply trans with r. assumption.
    intros. apply refl. auto.
  + simpl. unfold leA, maxA, Sat. intros.
    apply trans with (fun s0 => l s0 \/ r s0). assumption.
    intros. destruct H2. 
      apply H. apply refl. assumption.
      apply H0. apply refl. assumption.
- simpl. repeat intro. unfold eqA, minA, Sat in *. 
  split; intros.
  + eapply trans. apply H1. simpl. intros.
    destruct H2 as (u & v & xu & x0v & downuva).
    destruct downuva.
    apply le_right. 
    apply H. eapply le_left. apply H2. apply refl. assumption.
    apply H0. eapply le_left. apply H3. apply refl. assumption.
  + eapply trans. apply H1. simpl. intros.
    destruct H2 as (u & v & xu & x0v & downuva).
    destruct downuva.
    apply le_right. 
    apply H. eapply le_left. apply H2. apply refl. assumption.
    apply H0. eapply le_left. apply H3. apply refl. assumption.
- simpl. constructor; unfold leA, minA, Sat; intros.
  + eapply trans. eassumption. simpl. intros. 
    destruct H0 as (u & v & lu & rv & (ua & va)).
    eapply le_left. apply ua. apply refl. assumption.
  + eapply trans. eassumption. simpl. intros. 
    destruct H0 as (u & v & lu & rv & (ua & va)).
    eapply le_left. apply va. apply refl. assumption.
  + eapply trans. eassumption. intros.
    apply le_right. 
    apply H. apply refl. assumption.
    apply H0. apply refl. assumption.
Qed.

Theorem Frame : Frame.t (S -> Prop) FOps.
Proof.
constructor; intros.
- apply FrameLatt.
- simpl. unfold eqA, supA, Sat, pointwise_relation. repeat intro.
  split; intros; (eapply trans; [eassumption|]); intros.
  + simpl in *. destruct H1. eapply trans. apply -> (H x0).
    apply refl. assumption.
    intros. apply refl. exists x0. assumption.
  + simpl in *. destruct H1. eapply trans. apply <- (H x0).
    apply refl. assumption.
    intros. apply refl. exists x0. assumption.
- simpl. unfold supA. constructor; unfold leA, Sat; intros.
  + apply trans with (f i). assumption.
    intros. apply refl. exists i. assumption.
  + eapply trans. eassumption. simpl. intros.
    destruct H1. apply (H x a'). apply refl. assumption.
- simpl. unfold minA, supA, eqA, Sat. intros.
  split; intros. 
  + eapply trans. eassumption. simpl. intros.
    destruct H0 as (u & v & xu & (i & fiv) & downuva).
    apply refl. exists i. exists u. exists v. tauto. 
  + eapply trans. eassumption. simpl. intros.
    destruct H0 as (i & u & v & xu & fiv & downuva).
    apply refl. exists u. exists v. split. assumption.
    split. exists i. assumption. assumption.
Qed. 

End ToFrame.

Section Subspace.
Context {S : Type} {leS : S -> S -> Prop}.
Hypothesis POS : PreO.t S leS.
Variable Cov : S -> (S -> Prop) -> Prop.

Definition SubspaceCov (V : S -> Prop) (a : S)
  (U : S -> Prop) : Prop := Cov a (fun s => V s \/ U s).

Theorem TSubspace (V : S -> Prop) : FormTop.t leS Cov 
  -> FormTop.t leS (SubspaceCov V).
Proof.
intros FTS. constructor; unfold SubspaceCov; intros.
- apply refl. right. assumption.
- eapply trans. apply H. clear H. simpl. intros.
  destruct H. apply refl. left. assumption.
  apply H0. assumption.
- apply le_left with b; assumption.
- pose proof (le_right a _ _ H H0). 
  eapply trans. apply H1.
  clear H1. simpl. intros. 
  destruct H1 as (u & v & VUu & VVv & (ua & va)).
  destruct VUu. apply (le_left _ _ _ ua).
  apply refl. left.  assumption.
  destruct VVv. apply (le_left _ _ _ va).
  apply refl. left. assumption.
  apply refl. right. exists u. exists v. unfold down. auto.
Qed.

End Subspace.

Section GSubspace.
Context {S leS} {POS : PreO.t S leS}.
Context {Ix : S -> Type}.
Variable C : forall s, Ix s -> S -> Prop.

Definition SubspaceC (V : S -> Prop) (s : S) (ix : Ix s) (s' : S) : Prop :=
  V s' \/ C s ix s'.

End GSubspace.

End FormTop.


(** Formal topologies presented with a minimum operation
    rather than just a partial order. Most of the material
    is pretty similar to the module above.

    One good reference for this presentation is

    [2]
    Formal topology and domains.
    Giovanni Sambin.
    2000.
    http://www.math.unipd.it/~sambin/txt/ftd.pdf
 *)
Module FormTopM.

Generalizable All Variables.

Section Defn.
Context {S} {dotS : S -> S -> S}.

Definition ops : MeetLat.Ops S :=
  {| MeetLat.le := fun x y => dotS x y = x
   ; MeetLat.eq := eq
   ; MeetLat.min := dotS
  |}.

Instance ops' : MeetLat.Ops S := ops.

Definition le := MeetLat.le.
Definition dot := MeetLat.min.

Context {ML : MeetLat.t S ops}.

Require Import SetoidClass Morphisms.

Class t { Cov : S -> (S -> Prop) -> Prop } :=
  { refl : forall (a : S) (U : S -> Prop), U a -> Cov a U
  ; trans : forall (a : S) (U V : S -> Prop), 
       Cov a U 
     -> (forall (a' : S), U a' -> Cov a' V)
     -> Cov a V
  ; dot_left : forall (a b : S) (U : S -> Prop)
     , Cov a U -> Cov (dot a b) U
  ; dot_right : forall (a : S) (U V : S -> Prop)
    , Cov a U -> Cov a V
    -> Cov a (fun c => exists u v, U u /\ V v /\ MeetLat.eq c (dot u v))
  }.

Arguments t : clear implicits.

Lemma monotone {Cov} : t Cov
  -> forall (U V : S -> Prop)
  , (forall a : S, U a -> V a)
  -> forall a, Cov a U -> Cov a V.
Proof.
intros. eauto using trans, refl.
Qed.

Lemma subset_equiv {Cov} : t Cov
  -> forall (U V : S -> Prop)
  , (forall a : S, U a <-> V a)
  -> forall a, Cov a U <-> Cov a V.
Proof.
intros. split; apply monotone; firstorder.
Qed.

Definition asFormTop `(tCov : t Cov) : FormTop.t le Cov.
Proof.
constructor; intros.
- apply refl. assumption.
- eapply trans. eassumption. assumption.
- assert (MeetLat.min a b = a). apply (PO.le_antisym (le := MeetLat.le)). 
  + apply (@PreO.min_l _ _ _ b).
    apply MeetLat.min_ok.
  + apply (@PreO.min_greatest _ _ a b).
    apply MeetLat.min_ok. apply PreO.le_refl. assumption.
  + rewrite <- H1. rewrite MeetLat.min_comm. 
    apply dot_left. assumption. 
- pose (UV := (fun c => exists u v, U u /\ V v /\ MeetLat.eq c (MeetLat.min u v))).
  apply monotone with UV. assumption.
  unfold UV. intros.
  destruct H1 as [u [v [Uv [Vv downP]]]].
  exists u. exists v. split. assumption. split. assumption.
  unfold FormTop.down. repeat rewrite downP.
  split. apply MeetLat.min_ok. apply MeetLat.min_ok. 
  unfold UV. apply dot_right; assumption.
Qed.

(** Inductively generated formal topologies for this formulation. *)

Variable I : S -> Type.
Variable C : forall (s : S), I s -> (S -> Prop).

Definition stable (Cov : S -> (S -> Prop) -> Prop) :=
  forall a b U V, Cov a U -> Cov b V
  -> Cov (dot a b) (fun s => exists u v, U u /\ V v /\ MeetLat.eq s (dot u v)).

Definition localized := forall (b c : S),
  forall (i : I c), let a := dot b c in
  exists (j : I a),
  (forall s, C a j s -> exists u, C c i u /\ MeetLat.le s (dot a u)).

Inductive GCov : S -> (S -> Prop) -> Prop :=
  | grefl : forall (a : S) (U : S -> Prop), U a -> GCov a U
  | gdot_left : forall (a b : S) (U : S -> Prop)
     , GCov a U -> GCov (dot a b) U
  | ginfinity : forall (a : S) (i : I a) (U : S -> Prop),
     (forall u, C a i u -> GCov u U) -> GCov a U.

Hypothesis loc : localized.

Lemma localized_asFormTop : FormTop.localized MeetLat.le C.
Proof.
unfold FormTop.localized, localized in *.
intros.
specialize (loc a c i).
unfold dot, MeetLat.min in *. simpl in *.
rewrite H in loc.
destruct loc.
exists x. intros. specialize (H0 s H1).
destruct H0. exists x0. destruct H0. split. assumption.
unfold FormTop.down.
unfold dot in x. simpl in x.
change dotS with (MeetLat.min) in *.
change (@eq S) with (MeetLat.eq) in *.
split.
apply PO.le_antisym. apply MeetLat.min_l. apply MeetLat.min_ok.
apply PreO.le_refl. rewrite <- H2. rewrite MeetLat.min_comm.
rewrite <- MeetLat.min_assoc. apply MeetLat.min_l.
apply PO.le_antisym. apply MeetLat.min_l. apply MeetLat.min_ok.
apply PreO.le_refl. rewrite <- H2. rewrite MeetLat.min_assoc.
apply MeetLat.min_r.
Qed.

Lemma gmonotone : forall (a : S) (U V : S -> Prop),
  (forall u, U u -> V u) -> GCov a U -> GCov a V.
Proof.
intros. induction H0.
- apply grefl. apply H. assumption.
- eapply gdot_left. apply IHGCov. assumption.
- eapply ginfinity. intros. apply H1. apply H2.
  apply H.
Qed.

Lemma gsubset_equiv : forall (U V : S -> Prop)
  , (forall a : S, U a <-> V a)
  -> forall a, GCov a U <-> GCov a V.
Proof.
intros. split; apply gmonotone; intro; apply H; assumption.
Qed.

Lemma dot_infinity : forall (b c : S), let a := dot b c in
  forall (i : I c) (U : S -> Prop), 
  (forall v, C c i v -> GCov (dot a v) U)
  -> GCov a U.
Proof.
unfold localized in loc.
intros. destruct (loc b c i).
apply (ginfinity _ x).
intros.
specialize (H0 u H1).
destruct H0. destruct H0.
simpl in H2. 
replace dotS with MeetLat.min in H2 by reflexivity.
rewrite <- H2.
rewrite MeetLat.min_comm.
apply gdot_left. 
apply H. assumption.
Qed.


Lemma GCov_stable : stable GCov.
Proof.
unfold localized in loc.
unfold stable. intros.
induction H.
- induction H0; intros.
  + apply grefl. exists a. exists a0. intuition.
  + unfold dot. rewrite MeetLat.min_assoc. 
    apply gdot_left. apply IHGCov.
  + pose proof (loc a a0 i) as loc1.
    destruct loc1 as [j loc'].
    apply (ginfinity _ j).

    intros. specialize (loc' u H2).
    destruct loc'. destruct H3.
    simpl in H4.
    replace dotS with dot in H4 by reflexivity.
    rewrite <- H4. unfold dot.
    rewrite MeetLat.min_comm.
    apply gdot_left.
    rewrite <- MeetLat.min_assoc.
    rewrite (MeetLat.min_comm a0 x).
    rewrite MeetLat.min_assoc.
    apply gdot_left. 
    apply H1. assumption.
- intros. unfold dot. rewrite <- MeetLat.min_assoc.
  rewrite (MeetLat.min_comm b0 b).
  rewrite MeetLat.min_assoc. apply gdot_left.
  apply IHGCov.
- intros. pose proof (loc b a i) as loc1.
  destruct loc1 as [j loc'].
  unfold dot. rewrite MeetLat.min_comm.
  apply (ginfinity _ j).

  intros. specialize (loc' u H2).
  destruct loc'. destruct H3. simpl in H4.

 replace dotS with dot in H4 by reflexivity.
    rewrite <- H4. unfold dot.
    rewrite MeetLat.min_comm.
    apply gdot_left.
    rewrite <- MeetLat.min_assoc.
    rewrite (MeetLat.min_comm a x).
    rewrite MeetLat.min_assoc.
    apply gdot_left.
    rewrite MeetLat.min_comm.
    apply H1. assumption.  
Qed.

Theorem GCov_formtop : t GCov.
Proof.
unfold localized in loc.
constructor.
- apply grefl.
- intros. induction H.
  + apply H0. assumption.
  + eapply gdot_left. apply IHGCov. apply H0.
  + apply (ginfinity _ i). intros. apply H1; assumption.
- apply gdot_left.
- intros.
  pose proof GCov_stable as stab.
  unfold stable in stab.
  pose proof GCov_stable.
  replace a with (dot a a).
  eapply H1. eassumption. eassumption.
  pose proof (MeetLat.min_idempotent a) as ida.
  simpl in ida. apply ida.
Qed.
End Defn.

End FormTopM.

(** Information bases, which are the predicative versions of
    Scott domains. Perhaps, see Definition 1.9 of [2].
    Though my formulation is a little different; I build off
    of a pre-existing notion of a meet semi-lattice.

    Also, I directly show that this formal topology is
    inductively generated by generating it with an axiom set. *)
Module InfoBase. 
Section InfoBase.

Generalizable All Variables.

Context {S : Type} `{PO : PO.t S leS eqS}.

(** The axiom set essentially says that if [s <= t], then
    [s] is covered by the singleton set [{t}]. *)
Definition Ix (s : S) : Type := { t : S & leS s t }.
Definition C (s : S) (s' : Ix s) s'' : Prop := eqS (projT1 s') s''.

(** This axiom set is localized. *)
Definition loc : FormTop.localized leS C.
Proof.
pose proof (@PO.t_equiv _ _ _ PO) as eqEquiv.
unfold FormTop.localized. intros. simpl.
unfold Ix, C in *.
destruct i. simpl.
assert (leS a a).
apply PreO.le_refl.
exists (existT _ a H0).
intros.  simpl in *. 
exists x. split. reflexivity.
split. 
rewrite H1. apply PreO.le_refl.
rewrite <- H1.
eapply PreO.le_trans. eapply H. eassumption.
Qed.

Definition Cov (s : S) (U : S -> Prop) : Prop :=
  exists t, U t /\ leS s t.

(** The covering relation for information bases,
    which we derive from the axiom set above. *)
Definition GCov := @FormTop.GCov _ leS Ix C.

Require Import Morphisms SetoidClass.
Theorem CovEquiv : forall s U, Cov s U <-> GCov s U.
Proof.
intros. unfold Cov, GCov. split; intros.
- destruct H as (t & Ut & st).
  apply FormTop.ginfinity with (existT _ t st).
  unfold C. simpl. intros.
  apply FormTop.gle_left with t.
  rewrite H. apply PreO.le_refl.
  apply FormTop.grefl. assumption.
- induction H. 
  + exists a. split. assumption. apply PreO.le_refl.
  + destruct IHGCov as (t & Ut & bt).
    exists t. split. assumption. eapply PreO.le_trans; eassumption.
  + destruct i. unfold C in *. simpl in *.
    assert (eqS x x) as eqx. reflexivity.
    specialize (H x eqx).
    specialize (H0 x eqx). destruct H0 as (t & Ut & xt).
    exists t. split. assumption. eapply PreO.le_trans; eassumption.
Qed.

(** The proof that [Cov] is a valid formal topology. *)
Instance isCovG : FormTop.t leS GCov := 
  FormTop.GCov_formtop Ix C loc.

Require Import Morphisms.
Instance isCov : FormTop.t leS Cov.
Proof.
assert ((eq ==> eq ==> iff)%signature Cov GCov).
pose proof CovEquiv.
simpl_relation. rewrite H. apply isCovG.
Qed.

End InfoBase.
End InfoBase.

(** Here we intend to define the formal topology for the lower real
    numbers, realizing that the lower real numbers can be made into 
    a formal topology by showing that they are an information base,
    taking the rational numbers, together with the
    maximum operation, as the meet semilattice for an information base.
*)

Module LowerR.
Require Import QArith QArith.Qminmax.

Definition opsU : MeetLat.Ops Q := 
  {| MeetLat.le := Qle ; MeetLat.eq := Qeq; MeetLat.min := Qmin |}.

Definition ops : MeetLat.Ops Q := 
  {| MeetLat.le := fun x y => x >= y ; MeetLat.eq := Qeq; MeetLat.min := Qmax |}.

Instance UML : MeetLat.t Q opsU.
Proof.
constructor. constructor. constructor. 
- intros; apply Qle_refl.
- intros. eapply Qle_trans; eassumption.
- solve_proper.
- intros; apply Qle_antisym; assumption.
- solve_proper.
- intros. constructor; simpl.
  + apply Q.le_min_l. 
  + apply Q.le_min_r. 
  + intros. apply Q.min_glb; assumption.
Qed.

Instance ML : MeetLat.t Q ops.
Proof.
constructor. constructor. constructor. 
- intros; apply Qle_refl.
- simpl. intros. eapply Qle_trans; eassumption.
- simpl. solve_proper.
- intros; apply Qle_antisym; assumption.
- solve_proper.
- intros. constructor; simpl.
  + apply Q.le_max_l. 
  + apply Q.le_max_r. 
  + intros. apply Q.max_lub; assumption.
Qed.

Definition Ix := @InfoBase.Ix Q (fun x y => x >= y).
Definition C := @InfoBase.C Q (fun x y => x >= y).

Definition Cov := @InfoBase.Cov Q (fun x y => x >= y).

Definition isCov := @InfoBase.isCov Q (fun x y => x >= y) Qeq (@MeetLat.PO _ _ ML).

Instance Cov_isCov : FormTop.t (fun x y => x >= y) Cov
  := isCov.


Definition Cov' (a : Q) (U : Q -> Prop) :=
  forall u, a < u -> Cov u U.

Definition Ix' (a : Q) := option Q.

Definition C' (a : Q) (p : Ix' a) : Q -> Prop := match p with
  | None => fun u => a < u
  | Some l => fun l' => l <= a -> l == l'
  end.

Require Import Qnn.
Definition Cov'Equiv : forall a U,
  Cov' a U <-> @FormTop.GCov _ (fun x y => x >= y) Ix' C' a U.
Proof.
intros. unfold Cov'. split; intros.
- apply FormTop.ginfinity with None. simpl.
  intros. unfold Cov, InfoBase.Cov in H.
  specialize (H u H0). destruct H as (t & Ut & ut).
  apply FormTop.gle_left with t. assumption.
  apply FormTop.grefl. assumption.
- generalize dependent u. 
  induction H; intros.
  + exists a. split. assumption. apply Qlt_le_weak. assumption.
  + apply IHGCov. eapply Qle_lt_trans; eassumption.
  + destruct i; simpl in *. 
    * apply (H0 (Qmin a q)). intros. symmetry.
      apply Q.min_r_iff. assumption.
      eapply Qle_lt_trans. apply Q.le_min_l. assumption.
    * destruct (Qbetween a u H1) as (mid & mida & midu).
      apply H0 with mid; assumption.
Qed.

(* Think: how can this be generalized? *)
(* Now I could use the previous proof instead. *)
Theorem isCov' : FormTop.t (fun x y => x >= y) Cov'.
Proof.
constructor; unfold Cov'; intros.
- apply FormTop.le_left with a.
  apply Qlt_le_weak. assumption. apply FormTop.refl.
  assumption.
- destruct (Qbetween a u H1) as (mid & mida & midu).
  unfold Cov, InfoBase.Cov in *.
  specialize (H mid mida). destruct H as (t & Ut & lt).
  eapply H0.
  apply Ut. eapply Qle_lt_trans. apply lt. assumption.
- apply H0. eapply Qle_lt_trans; eassumption.
- apply FormTop.le_right; auto.
Qed.

End LowerR.

(** A definition of concrete topological spaces. These are formal topologies
    which are related to a type of points in the expected way, through a
    relation which I call [In]. See Definition 1.2 in [1]. Their relation
    which I call [In] looks like [||-], and they read as "lies in" or
    "forces".
*)
Module Concrete. 
Section Concrete.

Variable X S : Type.
Variable In : X -> S -> Prop.

Definition le := (map_op (fun (s : S) (x : X) => In x s)
            (pointwise_op (fun (_ : X) (P Q : Prop) => P -> Q))).

Instance SPO : PO.t S le _ := PO.map (fun s x => In x s) (PO.subset X).

Instance SubsetFrameOps : Frame.Ops (X -> Prop) := Frame.subset_ops X.

Record t : Type :=
  { here : forall x, { s | In x s }
  ; local : forall (a b : S) x, In x a -> In x b 
          -> { c | In x c /\ @FormTop.down S (map_op (fun s x => In x s) L.le) a b c }
  }.

(** Every concrete topological space can be presented as an
    inductively generated formal topology. See Section 4.4
    of [1]. *)
Definition Ix (a : S) : Type := sig (fun (g : forall (x : X), In x a -> S) 
  => forall (x : X) (prf : In x a), In x (g x prf)).

Definition C (a : S) (i : Ix a) : S -> Prop := match i with
  | exist g _ => fun s => exists (x : X) (prf : In x a), s = g x prf
  end.

Theorem loc : t -> FormTop.localized (map_op (fun s x => In x s) L.le) C.
Proof.
intros conc. destruct conc.
unfold FormTop.localized. simpl.
intros. unfold Ix in *. destruct i as [g Pg].
assert (forall x prf, In x (g x (H x prf))) as Pg'.
intros. apply Pg.
pose (fun x xina => local0 a (g x (H x xina)) x xina
  (Pg' x xina)) as g'.
assert (forall x prf, In x (proj1_sig (g' x prf))) as Pg''.
intros. destruct (g' x prf).
simpl. destruct a0. assumption.
exists (exist _ (fun x prf => proj1_sig (g' x prf)) Pg''). 

unfold C. intros.
destruct H0 as [x [prf img]].
exists (g x (H x prf)). split. exists x. exists (H x prf).
reflexivity.
destruct (g' x prf). simpl in *. destruct a0. subst.
assumption. 
Qed.

End Concrete.
End Concrete.

(** An inductively generated formal topology for the Cantor space.
    See Section 4.1 of [1]. *)
Module Cantor.

Variable A : Type.

Definition S := list A.

Definition Ix (s : S) := True.

Require Import Coq.Lists.List.

Definition C (s : S) (_ : True) (s' : S) : Prop := exists b,
  s' = s ++ (b :: nil).

Definition LE {A} (xs ys : list A) : Prop := exists zs,
  xs = ys ++ zs.

Lemma LE_PO {A : Type} : PO.t (list A) LE eq.
Proof.
constructor; intros.
- constructor; unfold LE; intros.
  + exists nil. rewrite app_nil_r. reflexivity.
  + destruct H. destruct H0.
    exists (x1 ++ x0). rewrite H. rewrite H0.
    rewrite app_assoc. reflexivity.
- unfold Morphisms.Proper, Morphisms.respectful. 
  unfold LE in *. intros. subst. reflexivity. 
- unfold LE in *.  destruct H. destruct H0.
  rewrite H0 in H. rewrite <- app_assoc in H.
  rewrite <- app_nil_r in H at 1.
  apply app_inv_head in H.
  symmetry in H. apply app_eq_nil in H.
  destruct H.  subst. rewrite app_nil_r.
  reflexivity.
Defined.

Definition Cov := FormTop.GCov LE C.

Theorem loc : FormTop.localized LE C.
Proof.
unfold FormTop.localized.
intros.  unfold Ix in *. destruct i. exists I.
intros. unfold C in *. destruct H0.
simpl in H.
unfold LE in H. destruct H.
destruct x0.
- subst.
  exists (c ++ x :: nil). split. exists x. reflexivity.
  unfold FormTop.down. split; simpl; unfold LE.
  exists (x :: nil). reflexivity.
  exists nil. repeat rewrite app_nil_r. reflexivity.
- exists (c ++ a0 :: nil). split. exists a0. reflexivity.
  unfold FormTop.down. split; simpl; unfold LE.
  exists (x :: nil). assumption. exists (x0 ++ x :: nil).
  rewrite <- app_assoc. simpl.
  rewrite H0. rewrite H. rewrite <- app_assoc. reflexivity.
Qed.

End Cantor.

(** Product spaces for inductively generated formal topologies.
    See Section 4.3 of [1]. *)
Module Product.

Generalizable All Variables.
Section Product.

Variable S T : Type.
Context `{POS : PreO.t S leS}. 
Context `{POT : PreO.t T leT}.
Variable IS : S -> Type.
Variable IT : T -> Type.
Variable CS : forall s, IS s -> (S -> Prop).
Variable CT : forall t, IT t -> (T -> Prop).

Definition Ix (p : S * T) : Type := match p with
  (s, t) => (IS s * T + S * IT t)%type end.

Definition C (p : S * T) : Ix p -> S * T -> Prop
  := match p as p' return Ix p' -> S * T -> Prop with (a, b) =>
  fun pI open => let (z, w) := open in match pI with
    | inl (sI, t) => CS a sI z /\ w = b
    | inr (s, tI) => z = a /\ CT b tI w
    end
  end.

Definition PO := PreO.product POS POT.

Theorem loc : 
    FormTop.localized leS CS
  -> FormTop.localized leT CT
  -> FormTop.localized (prod_op leS leT) C.
Proof.
intros. unfold FormTop.localized in *.
intros. destruct a as [sa ta], c as [sc tc]. 
destruct H1.
simpl in H1, H2, i.
destruct i as [[sI t]|[s tI]].
- specialize (H sa sc H1 sI).
  destruct H. unfold Ix in *.
  exists (inl (x, t)).
  intros. destruct s as [su tu].
  simpl in H3. destruct H3.
  specialize (H _ H3).
  destruct H as [u [CSu downu]].
  simpl. exists (u, tc). split. split. assumption. reflexivity.
  subst. destruct downu.
  unfold FormTop.down. split.
  simpl. split. assumption. apply PreO.le_refl.
  simpl. split. assumption. assumption.
- specialize (H0 ta tc H2 tI).
  destruct H0. unfold Ix in *.
  exists (inr (s, x)).
  intros. destruct s0 as [su tu].
  simpl in H3. destruct H3.
  specialize (H0 _ H4).
  destruct H0 as [u [CTu downu]].
  simpl. exists (sc, u). split. split. reflexivity. assumption.
  subst. destruct downu.
  unfold FormTop.down. split.
  simpl. split. apply PreO.le_refl. assumption.
  simpl. red. eauto. 
Qed.

Definition Cov := FormTop.GCov (prod_op leS leT) C.

Hypothesis locS : FormTop.localized leS CS.
Hypothesis locT : FormTop.localized leT CT.

Theorem isCov : FormTop.t (prod_op leS leT) Cov.
Proof.
apply (@FormTop.GCov_formtop (S * T) (prod_op leS leT)
  PO Ix C (loc locS locT)).
Qed.

Let CovS := FormTop.GCov leS CS.
Let CovT := FormTop.GCov leT CT.

Lemma factors : forall a b U V, CovS a U -> CovT b V -> 
  Cov (a, b) (fun p => let (a', b') := p in U a' /\ V b').
Proof.
intros. induction H.
- induction H0.
  + apply FormTop.grefl. split; assumption.
  + eapply FormTop.gle_left. 2:apply IHGCov.
    split; simpl. apply PreO.le_refl. assumption.
  + apply FormTop.ginfinity with (inr (a, i)).
    intros. simpl in H2. destruct u. destruct H2. 
    subst. apply H1. assumption.
- apply FormTop.gle_left with (b0, b). split; simpl.
  assumption. apply PreO.le_refl.
  apply IHGCov.
- apply FormTop.ginfinity with (inl (i, b)).
  intros. simpl in H2. destruct u. destruct H2. 
  subst. apply H1. assumption.
Qed.

Lemma unfactors1 : forall ab U, Cov ab U
  -> CovS (fst ab) (fun s => exists b', U (s, b')).
Proof.
intros. induction H.
- apply FormTop.grefl. destruct a. exists t. assumption.
- destruct a, b, H. simpl in *. 
  apply FormTop.gle_left with s0. assumption.
  assumption.
- destruct a. destruct i.
  + destruct p. apply FormTop.ginfinity with i.
    intros. apply (H0 (u, t)). simpl. simpl in H1.
    intuition.
  + destruct p. simpl.

pose proof locS. pose proof locT.
Admitted.

Lemma unfactors2 : forall ab U, Cov ab U
  -> CovT (snd ab) (fun t' => exists a', U (a', t')).
Proof.
intros. induction H.
- apply FormTop.grefl. destruct a. exists s. assumption.
- destruct a, b, H. simpl in *. 
  apply FormTop.gle_left with t0. assumption.
  assumption.
- destruct a. destruct i.
  + destruct p. simpl. 
    pose proof locS. pose proof locT.
    admit.
  + destruct p. apply FormTop.ginfinity with i.
    intros. apply (H0 (s, u)). simpl. simpl in H1.
    intuition.
Admitted.


End Product.
End Product.

(** Continuous maps. *)
Module Cont.
Generalizable All Variables.

Section Cont.

Context {S} `{POS : PreO.t S leS}.
Context {T} `{POT : PreO.t T leT}.

Context {CovS : S -> (S -> Prop) -> Prop}.
Context {CovT : T -> (T -> Prop) -> Prop}.

Record t {F : S -> T -> Prop} : Prop :=
  { here : forall a, CovS a (fun s => exists t, F s t)
  ; le_left : forall a b c, leS a c -> F c b -> F a b
  ; local : forall {a b c}, F a b -> F a c
    -> CovS a (fun s => exists bc, @FormTop.down _ leT b c bc /\ F s bc)
  ; cov : forall {a b} V, F a b -> CovT b V
    -> CovS a (fun s => exists t, V t /\ F s t)
  }.

Arguments t F : clear implicits.

(** Convert a continuous map for formal topologies to a 
    frame homomorphism (i.e., continuous map on locales)
  *)
Definition frame (F : S -> T -> Prop) (U : T -> Prop) (s : S) : Prop :=
  exists t', U t' /\ F s t'.

Hypothesis FTS : FormTop.t leS CovS. 
Hypothesis FTT : FormTop.t leT CovT.
Let FrameS := FormTop.Frame leS CovS POS FTS.
Let FrameT := FormTop.Frame leT CovT POT FTT.

Variable F : S -> T -> Prop.
Hypothesis cont : t F.

Instance POFS : PO.t (S -> Prop) (FormTop.leA CovS) (FormTop.eqA CovS).
Proof.
eapply FormTop.FramePO. eassumption.
Qed.

Instance POFT : PO.t (T -> Prop) (FormTop.leA CovT) (FormTop.eqA CovT).
Proof.
eapply FormTop.FramePO. eassumption.
Qed.

Theorem monotone : PreO.morph (FormTop.leA CovT) (FormTop.leA CovS)
   (frame F).
Proof.
unfold PreO.morph. intros. unfold frame.
simpl. unfold FormTop.leA, FormTop.Sat.
intros. simpl in H. unfold FormTop.leA, FormTop.Sat in H.
apply (FormTop.trans _ _ _ H0). intros.
destruct H1 as [t' [at' Fa't']].
apply (cov cont _ Fa't'). apply H. apply FormTop.refl.
assumption.
Qed.

Require Import Morphisms SetoidClass.

Theorem toLattice : 
   L.morph (FormTop.LOps leT CovT) (FormTop.LOps leS CovS) (frame F).
Proof.
constructor.
  + constructor.
     * apply monotone.
     * repeat intro. split; apply monotone; simpl in H;
       rewrite H; apply PreO.le_refl.
  + intros. unfold frame. simpl. unfold FormTop.eqA, FormTop.Sat.
    intros. apply (FormTop.subset_equiv _). clear s.
    intros. unfold FormTop.maxA. split; intros.
    * destruct H as [t' [abt' Fa't']].
      destruct abt'; [left | right]; exists t'; tauto.
    * firstorder.
  + intros. unfold frame. simpl. apply PO.le_antisym;
    unfold FormTop.leA, FormTop.Sat; intros.
    * apply (FormTop.trans _ _ _ H). clear s H.
      intros. unfold FormTop.minA in H.
      destruct H as (t' & (u & v & au & bv & downuv) & Fat).
      destruct downuv as (ut' & vt').
      unfold FormTop.minA.
      apply FormTop.le_right;
      apply (cov cont _ Fat).
      apply FormTop.le_left with u. assumption.
      apply FormTop.refl. assumption.
      apply FormTop.le_left with v. assumption.
      apply FormTop.refl. assumption.
    * apply (FormTop.trans _ _ _ H). clear s H.
      intros. unfold FormTop.minA in *.
      destruct H as (u & v & (t1 & at1 & Fut1)
        & (t2 & bt2 & Fvt2) & (ua' & va')).
      pose proof (le_left cont _ _ _ ua' Fut1) as Fat1.
      pose proof (le_left cont _ _ _ va' Fvt2) as Fat2.
      pose proof (local cont Fat1 Fat2).
      refine (FormTop.monotone _ _ _ _ _ H).
      intros.
      destruct H0 as (bc & downbc & fabc).
      exists bc. split. exists t1. exists t2. auto. assumption.
Qed.

Theorem toFrame : Frame.morph 
  (FormTop.FOps leT CovT) (FormTop.FOps leS CovS) (frame F).
Proof.
constructor.
- apply toLattice.
- unfold frame. simpl. intros.
  unfold FormTop.eqA, FormTop.Sat.
  apply (FormTop.subset_equiv FTS).
  intros; split; intros.
  + destruct H as (t' & (i & git) & Fat).
    exists i. exists t'. auto.
  + destruct H as (i & t' & git' & Fat').
    exists t'. split. exists i. assumption. assumption.
- unfold frame. simpl. unfold FormTop.eqA, FormTop.Sat.
  intros. split; intros. unfold FormTop.supA.
  apply FormTop.refl. exists (fun _ => True). constructor.
  unfold FormTop.supA.
  pose proof (here cont s).
  eapply FormTop.trans. apply H0. clear H0. simpl.
  intros. destruct H0. apply FormTop.refl.
  exists x. split. exists (fun _ => True). constructor. assumption.
Qed.

Definition toCmap : Frame.cmap (FormTop.FOps leS CovS)
  (FormTop.FOps leT CovT) :=
  {| Frame.finv := frame F
   ; Frame.cont := toFrame |}.

End Cont.

Arguments t {S} leS {T} leT CovS CovT F : clear implicits.

Section Morph.

Context {S} `{POS : PreO.t S leS}.
Context `{FTS : FormTop.t S leS CovS}.

Definition id (s t : S) := leS s t.

Theorem t_id : t leS leS CovS CovS id.
Proof.
constructor; intros; unfold id in *.
- eapply FormTop.refl. exists a. apply PreO.le_refl.
- eapply PreO.le_trans; eassumption.
- apply FormTop.refl. exists a. split.
  split; eassumption. apply PreO.le_refl.
- eapply FormTop.trans with (fun b' => b = b').
  eapply FormTop.le_left. eassumption.
  apply FormTop.refl. reflexivity. 
  intros. subst. eapply FormTop.monotone. eassumption.
  2:eassumption. intros. exists a0. split. assumption.
  apply PreO.le_refl.
Qed.

Context {T} `{POT : PreO.t T leT}.
Context {U} `{POU : PreO.t U leU}.
Context `{FTT : FormTop.t T leT CovT}.
Context `{FTU : FormTop.t U leU CovU}.

(*
Everything in s maps to u
iff there is some subset T such that
  everything in s maps to T and
  everything in T maps to u
*)

Theorem t_compose : forall (F : S -> T -> Prop) (G : T -> U -> Prop),
    t leS leT CovS CovT F
  -> t leT leU CovT CovU G
  -> t leS leU CovS CovU (compose F G).
Proof.
intros. constructor; intros.
- pose proof (here H a).
  eapply FormTop.trans. eassumption.
  simpl. intros. destruct H2. 
  pose proof (here H0 x).
  pose proof (cov H _ H2 H3).
  refine (FormTop.monotone _ _ _ _ _ H4).
  intros. destruct H5 as [t1 [[u Gt1u] Fa0t1]].
  exists u. unfold compose. exists t1. split; assumption.
- unfold compose in *.
  intros. 
  destruct H2 as [t1 [Fat1 Gt1b]]. 
  exists t1. split. eapply (le_left H). eassumption.
  assumption. assumption.
- unfold compose in *.
  destruct H1 as [t1 [Fat1 Gt1b]]. 
  destruct H2 as [t2 [Fat2 Gt2b]].
  pose proof (local H Fat1 Fat2).
  eapply FormTop.trans.
  eassumption. simpl. intros.
  destruct H2 as (tt & downtt & Fatt).
  apply (FormTop.monotone _)
  with (fun s => exists t' : T,
    (fun t'' => exists bc : U, @FormTop.down _ leU b c bc /\ G t'' bc) t' 
    /\ F s t'). firstorder.
  eapply (cov H). eassumption.
  destruct downtt.
  apply (local H0).
  eapply (le_left H0). eapply H2. eassumption.
  eapply (le_left H0). eapply H3. eassumption.
- unfold compose. intros.
  destruct H1 as [t [Fat Gtb]].
  apply (FormTop.monotone _)
    with (fun s => exists t1 : T, (exists u : U, V u /\ G t1 u) /\ F s t1).
  firstorder.
  apply (cov H _ Fat).
  apply (cov H0 _ Gtb). assumption.
Qed.

End Morph.

Section Products. 
Context {S} `{POS : PreO.t S leS}.
Context {IS} {CS : forall (s : S), IS s -> (S -> Prop)}.
Variable locS : FormTop.localized leS CS.
Let CovS := FormTop.GCov leS CS.

Definition diagonal (p : S) (out : S * S) : Prop :=
  let (out1, out2) := out in leS p out1 /\ leS p out2.

Lemma t_diagonal : t leS (prod_op leS leS)
  CovS (@Product.Cov _ _ leS leS IS IS CS CS) diagonal.
Proof.
pose proof (FormTop.GCov_formtop IS CS locS) as FTS.
constructor; intros; unfold diagonal, CovS in *.
- apply FormTop.refl. exists (a, a). split; apply PreO.le_refl.
- destruct b. destruct H0.
  split; eauto using PreO.le_trans. 
- destruct b, c. destruct H, H0.
  apply FormTop.refl. exists (a, a).
  split. split; unfold prod_op; simpl; split; assumption.
  split; apply PreO.le_refl.
- generalize dependent a. induction H0; intros.
  + apply FormTop.refl. exists a. 
    split. assumption. assumption. 
  + apply IHGCov. destruct a, b, H. simpl in *. 
    destruct H1. split; eauto using PreO.le_trans.
  + destruct a. simpl in *. destruct H1. destruct i.
    * destruct p. unfold FormTop.localized in locS. 
      specialize (locS a0 s H1 i).
      destruct locS.
      apply FormTop.ginfinity with x.
      intros.
      specialize (H3 _ H4).
      destruct H3. destruct H3. 
      apply H0 with (x0, s0).
      auto. destruct H5. eauto using PreO.le_trans.
    * destruct p. unfold FormTop.localized in locS. 
      specialize (locS a0 s0 H2 i).
      destruct locS.
      apply FormTop.ginfinity with x.
      intros.
      specialize (H3 _ H4).
      destruct H3. destruct H3. 
      apply H0 with (s, x0).
      auto. destruct H5. eauto using PreO.le_trans.
Qed.
  

Context {T} `{POT : PreO.t T leT}.
Context {IT} {CT : forall (t : T), IT t -> (T -> Prop)}.
Variable locT : FormTop.localized leT CT.
Let CovT := FormTop.GCov leT CT.

Definition proj_L (p : S * T) (out : S) : Prop :=
  let (s1, t1) := p in leS s1 out.

Lemma t_proj_L : t (prod_op leS leT) leS 
  (@Product.Cov _ _ leS leT IS IT CS CT) CovS proj_L.
Proof.
pose proof (Product.isCov _ _ _ _ _ _ locS locT) as FTST.
constructor; intros; unfold proj_L in *.
- apply FormTop.refl. destruct a. exists s. apply PreO.le_refl.
- destruct c, a.  destruct H. simpl in H, H1. 
  eapply PreO.le_trans; eassumption.
- destruct a. apply FormTop.refl. 
  exists s. split. split; assumption. apply PreO.le_refl. 
- destruct a. generalize dependent s. induction H0; intros.
  + apply FormTop.refl. exists a. firstorder.
  + apply FormTop.le_left with (b, t0).
    split; simpl. eapply PreO.le_trans; eassumption. 
    apply PreO.le_refl.
    apply IHGCov. apply PreO.le_refl.
  + unfold FormTop.localized in locS. 
    specialize (locS _ _ H1 i).
    destruct locS.
    apply FormTop.ginfinity with (inl (x, t0)). 
    intros. simpl in *. destruct u. destruct H3.
    subst.
    specialize (H2 _ H3). destruct H2 as (u & Caiu & downu).
    eapply H0. eassumption.
    destruct downu. assumption.
Qed.

Definition proj_R (p : S * T) (out : T) : Prop :=
  let (s1, t1) := p in leT t1 out.

Lemma t_proj_R : t (prod_op leS leT) leT 
  (@Product.Cov _ _ leS leT IS IT CS CT) CovT proj_R.
Proof.
pose proof (Product.isCov _ _ _ _ _ _ locS locT) as FTST.
constructor; intros; unfold proj_R in *.
- apply FormTop.refl. destruct a. exists t0. apply PreO.le_refl.
- destruct c, a.  destruct H. simpl in H, H1. 
  eauto using PreO.le_trans.
- destruct a. apply FormTop.refl. 
  exists t0. split. split; assumption. apply PreO.le_refl. 
- destruct a. generalize dependent t0. induction H0; intros.
  + apply FormTop.refl. exists a. firstorder.
  + apply FormTop.le_left with (s, b).
    (** We would like
        eauto using (PreO.le_refl, PreO.le_trans)
        to work here, but it is dumb! *)
    split; simpl. apply PreO.le_refl. 
    eapply PreO.le_trans; eassumption. 
    apply IHGCov. apply PreO.le_refl.
  + unfold FormTop.localized in locT. 
    specialize (locT _ _ H1 i).
    destruct locT.
    apply FormTop.ginfinity with (inr (s, x)). 
    intros. simpl in *. destruct u. destruct H3.
    subst.
    specialize (H2 _ H4). destruct H2 as (u & Caiu & downu).
    eapply H0. eassumption.
    destruct downu. assumption.
Qed.

Context {A} `{POA : PreO.t A leA}.
Context {IA} {CA : forall (t : A), IA t -> (A -> Prop)}.
Variable locA : FormTop.localized leA CA.
Let CovA := FormTop.GCov leA CA.

Context {B} `{POB : PreO.t B leB}.
Context {IB} {CB : forall (t : B), IB t -> (B -> Prop)}.
Variable locB : FormTop.localized leB CB.
Let CovB := FormTop.GCov leB CB.

Definition parallel (F : S -> A -> Prop) (G : T -> B -> Prop)
  (p : S * T) (out : A * B) : Prop :=
  let (s, t) := p in let (a, b) := out in
   F s a /\ G t b.

Theorem t_parallel (F : S -> A -> Prop) (G : T -> B -> Prop)
  : t leS leA CovS CovA F
  -> t leT leB CovT CovB G
  -> t (prod_op leS leT) (prod_op leA leB)
      (@Product.Cov _ _ leS leT IS IT CS CT)
      (@Product.Cov _ _ leA leB IA IB CA CB)
      (parallel F G).
Proof.
intros ContF ContG.
constructor; intros; unfold parallel in *.
- apply FormTop.gmonotone with
  (fun s : S * T => let (s', t') := s in 
  (fun s'' => exists a, F s'' a) s' /\ (fun t'' => exists b, G t'' b) t').
  intros. destruct a, u. 
  destruct H as ((? & ?) & (? & ?)). exists (x, x0).
  intuition. destruct a. apply Product.factors; try assumption.
  apply (here ContF). apply (here ContG).
- destruct c, b, a. destruct H; simpl in *.
  destruct H0. split.
  eapply (le_left ContF); eassumption.
  eapply (le_left ContG); eassumption.
- destruct a, b, c.
  destruct H, H0.
  pose proof (local ContF H H0).
  pose proof (local ContG H1 H2).
Admitted.

End Products.
End Cont.

Arguments Cont.t {S} leS {T} leT CovS CovT F : clear implicits.

Module One.
Section One.

Definition Cov (_ : True) (U : True -> Prop) : Prop := U I.

Require Import Morphisms.
Theorem CovEquiv : (eq ==> eq ==> iff)%signature Cov (@InfoBase.Cov _ (fun _ _ => True)).
Proof.
simpl_relation.
intros. unfold Cov, InfoBase.Cov. split; intros.
- exists I. tauto.
- destruct H as ([] & Ut & _). assumption.
Qed.

Instance MLOne : MeetLat.t True MeetLat.one_ops := MeetLat.one.
Instance POOne : PO.t True (fun _ _ => True) (fun _ _ => True) := @MeetLat.PO _ _ MLOne.

Instance FTOne : FormTop.t (@MeetLat.le _ MeetLat.one_ops) Cov.
Proof.
rewrite CovEquiv.
apply InfoBase.isCov.
Qed.

Instance one_ops : MeetLat.Ops True := MeetLat.one_ops.

Require Import Morphisms.
Definition FTtoFrame : 
  Frame.morph (FormTop.FOps MeetLat.le Cov) Frame.prop_ops (fun U => U I).
Proof.
simpl. unfold Cov.
constructor.
- constructor.
  + constructor. simpl. unfold FormTop.leA, FormTop.Sat, Cov.
    unfold PreO.morph. intros. auto.
    simpl_relation. simpl in *. unfold FormTop.eqA, FormTop.Sat in *.
    apply H. constructor.
  + simpl. unfold FormTop.maxA. tauto.
  + simpl. unfold FormTop.minA. unfold FormTop.down. intros.
    split; intros. destruct H as ([] & [] & au & bv & _).
    auto. exists I. exists I. tauto.
- simpl. unfold FormTop.supA. tauto.
- simpl. unfold FormTop.supA. split; intros []; intros. 
  exists True. constructor. exists (fun _ => True). constructor.
Qed.

Context {S leS eqS} {POS : PO.t S leS eqS}.
Variable CovS : S -> (S -> Prop) -> Prop.

Definition Point (f : S -> Prop) := Cont.t MeetLat.le leS Cov CovS (fun _ => f).

Hypothesis FTS : FormTop.t leS CovS.

Instance FrameS : Frame.t (S -> Prop) (FormTop.FOps leS CovS)
  := FormTop.Frame leS CovS _ FTS.

Instance FrameOne : Frame.t (True -> Prop) (FormTop.FOps MeetLat.le Cov)
  := FormTop.Frame MeetLat.le Cov _ FTOne.

Definition toFPoint (f : S -> Prop) (pointf : Point f) :
  Frame.cmap Frame.prop_ops (FormTop.FOps leS CovS) :=
  {| Frame.finv := fun x => Cont.frame (fun _ => f) x I 
  ; Frame.cont := Frame.morph_compose _ _
    (Cont.toFrame FTOne FTS (fun _ => f) pointf) FTtoFrame |}.

End One.
End One.

Module InfoBaseCont.
Section InfoBaseCont.

Generalizable All Variables.

Require Import Morphisms.

Context {S} `{MLS : MeetLat.t S}.
Context {T} `{MLT : MeetLat.t T}.

Record pt {F : T -> Prop} : Prop :=
  { pt_local : forall {a b}, F a -> F b -> F (MeetLat.min a b)
  ; pt_le_right : forall a b, MeetLat.le a b -> F a -> F b
  ; pt_here : exists c, F c
  }.

Arguments pt : clear implicits.

Instance pt_proper : Proper ((eq ==> iff) ==> iff) pt.
Proof.
Admitted.


Lemma sc_monotone : forall (f : S -> T),
  PreO.scott_cont f ->
  forall x y : S, MeetLat.le x y -> MeetLat.le (f x) (f y).
Proof.
intros. 
unfold PreO.scott_cont in H.
pose (g := fun b : bool => if b then x else y).
specialize (H _ g).
assert (@PreO.directed _ MeetLat.le _ g).
unfold PreO.directed.
intros.
exists y. destruct i, j; simpl; split; 
  assumption || apply PreO.le_refl.
specialize (H H1 y).
assert (@PreO.sup _ MeetLat.le _ g y).
constructor.
intros. destruct i; simpl. assumption. apply PreO.le_refl.
intros. specialize (H2 false). simpl in H2.
assumption.
specialize (H H2).
destruct H.
specialize (sup_ge true). simpl in sup_ge.
apply sup_ge.
Qed.

(** I have no idea whether this is in fact
    a good definition *)
Record t {F : S -> T -> Prop} :=
  { le_left : forall a b c, MeetLat.le a b -> F b c -> F a c
  ; le_right :  forall a b c,  F a b -> MeetLat.le b c -> F a c
  ; local : forall {a b c}, F a b -> F a c -> F a (MeetLat.min b c)
  ; here : forall s, exists t, F s t
  }.

Arguments t : clear implicits.


Let CovS : S -> (S -> Prop) -> Prop := @InfoBase.Cov _ MeetLat.le.
Let CovT : T -> (T -> Prop) -> Prop := @InfoBase.Cov _ MeetLat.le.

Theorem cont : forall (F : S -> T -> Prop),
  t F
  -> Cont.t MeetLat.le MeetLat.le CovS CovT F.
Proof.
intros. constructor; intros.
- unfold CovS, InfoBase.Cov. exists a. 
  split. apply (here H). apply PreO.le_refl.
- eapply (le_left H); eassumption. 
- unfold CovS, InfoBase.Cov. exists a. 
  split. exists (MeetLat.min b c). split. 
  split; apply MeetLat.min_ok. apply local; assumption.
  apply PreO.le_refl.
- unfold CovT, CovS, InfoBase.Cov in *. 
  destruct H1 as (t0 & Vt0 & bt0).
  exists a. split. exists t0. split. assumption.
  apply (le_right H) with b; assumption.
  apply PreO.le_refl.
Qed.

End InfoBaseCont.

Arguments t {_} {_} {_} {_} F.
Arguments pt {_} {_} F.

Section Compose.

Context {S : Type} {SOps} {MLS : MeetLat.t S SOps}.

Instance OneOps : MeetLat.Ops True := MeetLat.one_ops.

Theorem to_pt : forall (F : True -> S -> Prop), t F ->
  pt (F I).
Proof.
intros. constructor; intros.
- apply (local H); assumption. 
- eapply (le_right H); eassumption. 
- apply (here H).
Qed.

Theorem from_pt : forall (F : S -> Prop), pt F -> t (fun _ => F).
Proof.
intros. constructor; intros.
- assumption.
- eapply (pt_le_right H); eassumption.
- apply (pt_local H); assumption.
- apply (pt_here H).
Qed.

Context {T TOps} {MLT : MeetLat.t T TOps}.
Context {U UOps} {MLU : MeetLat.t U UOps}.

Theorem t_compose (F : S -> T -> Prop) (G : T -> U -> Prop)
  : t F -> t G
  -> t (compose F G).
Proof.
intros HF HG.
constructor; unfold compose; intros.
- destruct H0 as (t & Fbt & Gtc).
  exists t. split. 
  + eapply (le_left HF); eassumption.
  + assumption.
- destruct H as (t & Fat & Gtb).
  exists t. split. assumption. eapply (le_right HG); eassumption.
- destruct H as (t & Fat & Gtb).
  destruct H0 as (t' & Fat' & Gt'c).
  exists (MeetLat.min t t'). split. 
  + apply (local HF); assumption.
  + apply (local HG); eapply (le_left HG). 
    apply MeetLat.min_l. assumption. 
    apply MeetLat.min_r. assumption. 
- destruct (here HF s). destruct (here HG x).
  exists x0. exists x. auto.
Qed.

End Compose.

Section EvalPt.

Context {S SOps} {MLS : MeetLat.t S SOps}.
Context {T TOps} {MLT : MeetLat.t T TOps}.

Definition eval (F : S -> T -> Prop) (x : S -> Prop) (t : T) : Prop :=
  exists s, x s /\ F s t.

Require Import Morphisms.
Theorem eval_pt (F : S -> T -> Prop) (x : S -> Prop)
  : pt x -> t F -> pt (eval F x).
Proof.
intros Hx HF.
pose proof (t_compose (fun _ => x) F (from_pt _ Hx) HF).
apply to_pt in H. 
eapply pt_proper. 2: eassumption. simpl_relation.
Qed.

End EvalPt.

End InfoBaseCont.

Arguments InfoBaseCont.t {S} SOps {T} TOps F : rename, clear implicits.

Module IGCont.
Section IGCont.
Generalizable All Variables.
Context {S} `{POS : PreO.t S leS}.
Context {IS : S -> Type}.
Variable CS : forall (s : S), IS s -> (S -> Prop).
Variable locS : FormTop.localized leS CS.
Let CovS := FormTop.GCov leS CS.

Context {T} `{POT : PreO.t T leT}.
Context {IT : T -> Type}.
Variable CT : forall (t : T), IT t -> (T -> Prop).
Variable locT : FormTop.localized leT CT.
Let CovT := FormTop.GCov leT CT.

Record t {F : S -> T -> Prop} :=
  { here : forall s, exists t, F s t
  ; local : forall a b c, F a b -> F a c ->
       CovS a (fun s => exists d, @FormTop.down _ leT b c d /\ F s d)
  ; le_left : forall a b c, leS a c -> F c b -> F a b
  ; le_right :  forall a b c,  F a b -> leT b c -> F a c
  ; ax_right : forall a b (j : IT b), F a b -> 
     CovS a (fun s => exists d, CT b j d /\ F s d)
  }.

Arguments t : clear implicits.

Theorem cont : forall F, t F -> Cont.t leS leT CovS CovT F.
Proof.
pose proof (FormTop.GCov_formtop IS CS locS) as FTS.
intros. constructor; intros.
- apply FormTop.grefl. apply (here H).
- eapply le_left; eassumption.
- apply local; assumption.
- generalize dependent a. induction H1; intros.
  + apply FormTop.grefl. exists a. split; assumption.
  + apply IHGCov. eapply le_right; eassumption.
  + pose proof (ax_right H _ _ i H2).
    apply (@FormTop.trans S leS CovS FTS _ _ _ H3).  
    intros. destruct H4 as (d & CTaid & Fad).
    eapply H1; eassumption.
Qed.

Theorem converse : forall F, Cont.t leS leT CovS CovT F -> t F.
Proof.
intros.
constructor; intros.
Abort. 


End IGCont.
End IGCont.

Arguments IGCont.t {S} leS {IS} CS
                   {T} leT {IT} CT F : clear implicits.

Module Discrete.
Section Discrete.

Generalizable All Variables.

Variable A : Type.

Hypothesis deceq : forall a a' : A, {a = a'} + {a <> a'}.

Definition Ix := @InfoBase.Ix _ (@Logic.eq A).
Definition C := @InfoBase.C _ (@Logic.eq A).
Definition CovI := @InfoBase.Cov _ (@Logic.eq A).

(** Woops I should have a positivity predicate to say that the
    "None" is covered by nothing *)
Definition Cov (a : A) (U : A -> Prop) : Prop := U a.

Require Import Morphisms.
Theorem CovEquiv : (eq ==> eq ==> iff)%signature CovI Cov.
Proof.
simpl_relation. unfold Cov, CovI, InfoBase.Cov.
split; intros.
- destruct H as (t & xt & leat). subst.  assumption. 
-  exists y. auto.
Qed.

Instance FTproper : Proper _ FormTop.t := @FormTop.t_proper A.
Instance discretePO : PO.t A Logic.eq Logic.eq := PO.discrete A.

Instance isCov : FormTop.t Logic.eq Cov.
Proof.
rewrite <- CovEquiv.
apply InfoBase.isCov.
Qed.

End Discrete.

Section FinFunc.

Context {A B : Type}.
Hypothesis deceqA : forall a a' : A, {a = a'} + {a <> a'}.
Hypothesis deceqB : forall b b' : B, {b = b'} + {b <> b'}.

Definition discrF (f : A -> B) (x : A) (y : B) : Prop := f x = y.

Instance POB : PO.t B Logic.eq Logic.eq := PO.discrete B.

Ltac inv H := inversion H; clear H; subst.

Theorem fCont (f : A -> B) :
  Cont.t Logic.eq Logic.eq (Cov A) (Cov B) (discrF f).
Proof.
constructor; unfold Cov; intros.
- exists (f a). constructor.
- subst. assumption.
- inv H. inv H0. exists (f a). split.
  split; reflexivity. constructor.
- exists b. auto.
Qed.

End FinFunc.

End Discrete.

Module ConcFunc.
Section ConcFunc.
Generalizable All Variables.
Context {S} `{Conc1 : Concrete.t A S In1}.
Context {T} `{Conc2 : Concrete.t B T In2}.

Let leS := Concrete.le A S In1.
Let CovS := @FormTop.GCov S leS
   (Concrete.Ix A S In1) (Concrete.C A S In1).

Let leT := Concrete.le B T In2.
Let CovT := @FormTop.GCov T leT
   (Concrete.Ix B T In2) (Concrete.C B T In2).

Definition cmap (f : A -> B) (g : S -> T -> Prop) := 
  forall (t : T) (a : A), In2 (f a) t <-> (exists s, g s t /\ In1 a s).

Theorem cont : forall f g, cmap f g
  -> Cont.t leS leT CovS CovT g.
Proof.
intros. unfold cmap in H. constructor; intros.
Abort.

End ConcFunc.
End ConcFunc.

Module LPRFuncs.
Require Import QArith.

Definition lift_binop (op : Q -> Q -> Q) (args : Q * Q) (result : Q) : Prop :=
  let (l, r) := args in (result < op l r).

Definition plusL := lift_binop Qplus.

Definition plusU (addends : Q * Q) (sum : Q) :  Prop :=
  let (l, r) := addends in (l + r <= sum).

Require Import QArith.Qminmax.

Theorem lift_binop_cont_ib : forall op
  (le_compat : forall a a' b b', a <= a' -> b <= b' -> op a b <= op a' b'), 
  InfoBaseCont.t (MeetLat.product_ops LowerR.ops LowerR.ops)
  LowerR.ops (lift_binop op).
Proof.
intros. constructor; unfold lift_binop; intros;
repeat match goal with
| [ a : (_ * _)%type |- _ ] => destruct a
| [ H : MeetLat.le (_, _) (_, _) |- _ ] => destruct H
end; simpl in *.
- eapply Qlt_le_trans. apply H0. 
  apply le_compat; assumption.
- eapply Qle_lt_trans; eassumption.
- apply Q.max_lub_lt; assumption.
- exists (op q q0 - 1). apply Qlt_minus_iff.
  ring_simplify. reflexivity.
Qed.

Theorem lift_binop_cont : forall op
  (le_compat : forall a a' b b', a <= a' -> b <= b' -> op a b <= op a' b'),
  IGCont.t (prod_op (fun x y => x >= y) (fun x y => x >= y)) 
           (Product.C _ _ _ _ LowerR.C' LowerR.C')
           (fun x y => x >= y) LowerR.C'
           (lift_binop op).
Proof.
intros.
constructor; intros.
- destruct s as (a & b). exists (op a b - 1).
  apply Qlt_minus_iff. ring_simplify.
  reflexivity.
- destruct a as (a1 & a2). simpl in *.
  apply FormTop.grefl. exists (Qmax b c).
  split. split; [apply Q.le_max_l | apply Q.le_max_r ].
  simpl. apply Q.max_lub_lt; assumption.
- destruct a, c. simpl in *. unfold prod_op in *.
  destruct H as (pr1 & pr2). simpl in *.
  eapply Qlt_le_trans. apply H0. apply le_compat; assumption.
- destruct a as (a1 & a2). simpl in *.
  eapply Qle_lt_trans; eassumption.
- destruct a as (a1 & a2). 
  simpl; apply FormTop.grefl; destruct j; simpl in *.
  + exists (Qmin q b). split. symmetry. apply Q.min_l_iff. assumption.
    eapply Qle_lt_trans. apply Q.le_min_r. assumption.
  + destruct (Qnn.Qbetween b (op a1 a2) H) as (mid & between).
    exists mid. apply between.
Qed.

Record LReal :=
  { lbound :> Q -> Prop
  ; dclosed : forall q, lbound q -> forall q', q' <= q -> lbound q'
  ; uopen : forall q, lbound q -> exists q', (q < q') /\ lbound q'
  ; nonempty : exists q, lbound q
  }.

Definition LRle (x y : LReal) : Prop := forall q, x q -> y q.
Definition LReq (x y : LReal) : Prop := LRle x y /\ LRle y x.

Require Import Coq.Sets.Ensembles ProofIrrelevance.

Definition LReal_eq_compat (x y : LReal) :
  LReq x y -> x = y.
Proof.
intros H. unfold LReq, LRle in H. destruct H.
destruct x, y; simpl in *.
assert (lbound0 = lbound1).
apply Extensionality_Ensembles. unfold Same_set, Included, In.
split; assumption.
induction H1.
replace dclosed0 with dclosed1 by apply proof_irrelevance.
replace uopen0 with uopen1 by apply proof_irrelevance.
replace nonempty0 with nonempty1 by apply proof_irrelevance.
reflexivity.
Qed.

Require Import Coq.Program.Basics.

Instance LReal_proper (x : LReal) : Proper (Qle --> impl) (lbound x).
Proof.
unfold Proper, respectful, impl, flip. intros.
eapply dclosed; eassumption.
Qed.

Instance LReal_proper2 (x : LReal) : Proper (Qeq ==> iff) (lbound x).
Proof.
unfold Proper, respectful. intros. split; intros; 
  (eapply dclosed; [eassumption| rewrite H; apply Qle_refl]).
Qed.

Require Import Qnn.

Definition pt_to_LReal (x : Q -> Prop) (ptx : @InfoBaseCont.pt _ LowerR.ops x) 
  : LReal.
Proof.
refine ({| lbound := fun q => exists u, q < u /\ x u |}); intros.
- destruct H as (u & qu & xu).
  exists u. split. eapply Qle_lt_trans; eassumption. assumption.
- destruct H as (u & qu & xu).
  pose proof (Qbetween q u qu).
  destruct H as (mid & midl & midu).
  exists mid. split.  assumption. exists u. split. apply midu.
  assumption.
- destruct (InfoBaseCont.pt_here ptx) as (l & xl).
  exists (l - 1). exists l. split. rewrite Qlt_minus_iff. ring_simplify.
  reflexivity. assumption.
Defined.

Require Import Morphisms SetoidClass.
Definition LReal_to_pt (x : LReal) : @InfoBaseCont.pt _ LowerR.ops (lbound x).
Proof.
constructor; intros.
- simpl. destruct (Q.max_dec a b); setoid_rewrite q; assumption.
- eapply dclosed; eassumption.
- destruct (nonempty x) as (l & xl).
  exists l. assumption.
Qed.

Theorem plus_contU : InfoBaseCont.t (MeetLat.product_ops LowerR.opsU LowerR.opsU)
  LowerR.opsU plusU.
Proof.
constructor; unfold plusL; intros.
- destruct a, b. destruct H. simpl in *.
  eapply Qle_trans; [|eassumption].
  apply Qplus_le_compat; eassumption.
- destruct a. simpl in *. eapply Qle_trans; eassumption.
- destruct a. simpl. apply Q.min_glb; assumption.
- destruct s. exists (q + q0). apply Qle_refl.
Qed.

End LPRFuncs.

Module Bundled.

Delimit Scope loc_scope with loc.
Open Scope loc.

(* Inductively-generated formal topology *)
Class IGT {S : Type} : Type :=
  { le : S -> S -> Prop
  ; PO :> PreO.t S le
  ; Ix : S -> Type
  ; C : forall s, Ix s -> (S -> Prop)
  ; localized : FormTop.localized le C
  }.

Arguments IGT : clear implicits.

Generalizable All Variables.

Definition Cov `(X : IGT A) := FormTop.GCov le C.

Instance IGTFT `(X : IGT A) : FormTop.t le (Cov X) :=
  @FormTop.GCov_formtop _ _ PO _ _ localized.

Definition InfoBase {A : Type} {ops : MeetLat.Ops A}
  (ML : MeetLat.t A ops) : IGT A :=
  {| PO := PO.PreO
  ; localized := @InfoBase.loc _ _ _ MeetLat.PO
  |}.

Definition One : IGT _ := InfoBase MeetLat.one.

Definition times `(LA : IGT A) `(LB : IGT B) : IGT _ :=
 let POA : PreO.t A _ := PO in let POB : PreO.t B _ := PO in
  {| PO := Product.PO A B
  ; localized := Product.loc _ _ _ _ _ _ localized localized
  |}.

Infix "**" := times (at level 80) : loc_scope.

Record cmap `{LA : IGT A} `{LB : IGT B} : Type :=
  { mp : A -> B -> Prop
  ; mp_ok : Cont.t le le (Cov LA) (Cov LB) mp
  }.

Arguments cmap {A} LA {B} LB : clear implicits.

Infix "~>" := cmap (at level 60) : loc_scope.

Definition id `{LA : IGT A} : LA ~> LA := 
  {| mp := Cont.id
  ; mp_ok := Cont.t_id |}.

Definition comp `{LA : IGT A} 
  `{LB : IGT B} `{LD : IGT D} (f : LA ~> LB) (g : LB ~> LD) : LA ~> LD :=
  {| mp := compose (mp f) (mp g)
  ; mp_ok := Cont.t_compose (mp f) (mp g) (mp_ok f) (mp_ok g)
  |}.

End Bundled.

Module JoinTop.

Section JoinTop.
(** We assume we have some type [S] equipped
    with a partial order. *)
Context {S} {ops : JoinLat.Ops S} {JL : JoinLat.t S ops}.

Variable bot : S.
Variable Cov : S -> (S -> Prop) -> Prop.


Class t : Prop :=
  { FT :> FormTop.t JoinLat.le Cov
  ; bot_ok : @PreO.bottom _ JoinLat.le bot
  ; bot_Cov : forall U, Cov bot U
  ; join_left : forall a b U, Cov a U -> Cov b U -> Cov (JoinLat.max a b) U
  }.

Hypothesis FTS : t.
(** Check properties we expect to hold *)

Definition singleton (s s' : S) : Prop := s = s'.

Lemma join_right : forall a b c, Cov a (singleton b)
  -> Cov a (singleton (JoinLat.max b c)).
Proof.
intros. eapply FormTop.trans. apply H. clear H. clear a.
intros a sba. unfold singleton in sba. subst.
apply FormTop.le_left with (JoinLat.max a c).
apply JoinLat.max_ok.
apply FormTop.refl. reflexivity.
Qed.

End JoinTop.


(** Given a formal topology, we can always produce a join-closed formal
    topology by taking "free join" elements (i.e., the free monoid, a list)
    and interpreting the cover relation accordingly.
*)
Require Import Coq.Lists.List.
Section Joinify.
Context {S} {le : S -> S -> Prop} {PO : PreO.t S le}.

Definition leL (xs ys : list S) : Prop := forall x,
  List.In x xs -> exists y, le x y /\ List.In y ys.

Definition eqL (xs ys : list S) : Prop := leL xs ys /\ leL ys xs.

Definition joinL (xs ys : list S) : list S := xs ++ ys.

Definition ops' : JoinLat.Ops (list S) :=
  {| JoinLat.le := leL
  ;  JoinLat.eq := eqL
  ;  JoinLat.max := joinL
  |}.

Instance ops : JoinLat.Ops (list S) := ops'.

Require Import Morphisms.

Instance joinPreO : PreO.t (list S) JoinLat.le.
Proof.
constructor; intros.
- simpl. unfold leL. intros. exists x0.
  split. apply PreO.le_refl. assumption.
- simpl in *. unfold leL in *. intros. 
  destruct (H x0 H1). destruct H2. 
  destruct (H0 x1 H3). destruct H4. 
  exists x2. split. eapply PreO.le_trans; eassumption.
  assumption.
Qed.

Instance joinPO : PO.t (list S) JoinLat.le JoinLat.eq.
Proof.
constructor.
- apply joinPreO.
- repeat intro. simpl in *.
  destruct H, H0. split;
  replace leL with JoinLat.le in * by reflexivity;
  eauto using (PreO.le_trans).
- intros. split; assumption.
Qed. 

Lemma joinLE : forall (xs ys xs' ys' : list S), leL xs xs' -> leL ys ys'
  -> leL (xs ++ ys) (xs' ++ ys').
Proof.
unfold leL in *.
intros.
apply in_app_iff in H1.
destruct H1 as [In1 | In2].
- destruct (H x In1). exists x0. rewrite in_app_iff. destruct H1. auto.
- destruct (H0 x In2). exists x0. rewrite in_app_iff. destruct H1. auto.
Qed.


Theorem JL : JoinLat.t (list S) ops.
Proof.
constructor.
- apply joinPO.
- repeat intro. simpl in *. unfold joinL.
  unfold eqL in *. destruct H, H0.
  auto using joinLE.
- intros. simpl. unfold joinL. constructor; unfold leL; intros.
  + exists x. split. apply PreO.le_refl. apply in_app_iff. auto.
  + exists x. split. apply PreO.le_refl. apply in_app_iff. auto.
  + apply in_app_iff in H1. destruct H1; [apply H | apply H0]; assumption.
Qed.

Variable Cov : S -> (S -> Prop) -> Prop.

Definition LCov (a : list S) (U : list S -> Prop) : Prop :=
  forall s : S, In s a -> Cov s (fun s' => exists xs, In s' xs /\ U xs).

Instance joinify : FormTop.t le Cov -> t nil LCov.
Proof.
intros FTS.
constructor.
- constructor.
  + unfold LCov. intros. apply FormTop.refl.
    exists a. split; assumption.
  + unfold LCov. intros. eapply FormTop.trans.
    eapply H. assumption. simpl.
    clear s H1. intros.
    destruct H1 as (xs & Inxs & Uxs).
    eapply H0. eassumption. assumption.
  + simpl. unfold LCov. intros. unfold leL in *.
    specialize (H s H1). destruct H as (y & sy & Inyb).
    apply FormTop.le_left with y. assumption.
    apply H0. assumption.
  + unfold LCov. intros.
    pose proof (fun (s' : S) (insa : In s' a) =>
      FormTop.le_right s' _ _ (H s' insa) (H0 s' insa)).
    eapply FormTop.monotone. eassumption. 2: apply (H2 s H1). simpl.
    intros. destruct H3 as 
      (u & v & (xs & Inxs & Uxs) & (ys & Inys & Vys) & downuva).
    exists (cons a0 nil). split. unfold In. left. reflexivity.
    exists xs. exists ys. split. assumption. split. assumption. 
    destruct downuva as (ua & va).
    split; unfold leL; intros x inx; simpl in inx; destruct inx; subst;
    match goal with
    | [ H: In ?x ?xs  |- exists y, _ /\ In y ?xs ] => exists x; tauto
    end.
- unfold PreO.bottom. simpl. unfold leL. intros.
  apply in_nil in H. contradiction.
- unfold LCov. intros. apply in_nil in H. contradiction.
- unfold LCov. simpl. unfold joinL. intros.
  apply in_app_iff in H1. destruct H1.
  + apply H; assumption.
  + apply H0; assumption.
Qed.

End Joinify.

End JoinTop.
