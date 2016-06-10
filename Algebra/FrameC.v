Require Import Coq.Classes.CMorphisms Coq.Classes.CRelationClasses.

Set Universe Polymorphism.
Generalizable All Variables.

Definition prod_op {A B} (fA : crelation A) (fB : crelation B)
   (x y : A * B) := (fA (fst x) (fst y) * fB (snd x) (snd y))%type.

Definition map_op {A B} 
  (f : A -> B) (P : crelation B) (x y : A) : Type := 
  P (f x) (f y).

Definition pointwise_op {A} {B : A -> Type} 
  (P : forall a, crelation (B a))
  (f g : forall a, B a) := forall a, P a (f a) (g a).

(** A tour of algebraic structures. Most of them are things related to
    orders or latices.
    Each definition follows a relatively rigid pattern.
    Each algebraic structure is defined in its own module. 
    For instance, preorders are defined in the Module [PreO].
    The type which defines the algebraic structure for preorders
    is called [t], which outside the module looks like [PreO.t].

    Let's be concrete. The type [Qnn] of non-negative rational numbers
    has a relation [Qnnle : Qnn -> Qnn -> Prop] which represents a
    preorder. Therefore, we can make an instance
    [H : PO.t Qnn Qnnle] which gives evidence that [Qnnle] is in fact
    a preorder.

    Within the module [PreO] (and for most algebraic structures), we have a
    type [morph] which gives evidence that some function in fact is a morphism
    in that category of algebraic structure; that is, it preserves the structure
    for whatever algebraic structure we defined. We always prove that the identity
    function is a morphism [morph_id] and that morphisms are closed under 
    composition [morph_compose].
 
    At the end we give examples or building blocks for the algebraic structure.
    There's usually trivial examples of these structures over base types which
    have only one or two elements. There is usually a way to form products,
    and often, given an algebraic structure on [B] and a function [f : A -> B],
    we can define the algebraic structure on [A] by asking whether it holds
    pointwise in [B].

    Just given a preorder, we can define what it means for something to be
    a top element or bottom, max or min, infimum or supremum, and so these
    definitions are given in the [PO] module. Many algebraic structures are
    then closed under these operations, in which case there will be functions
    that are defined that implement the given operation. For instance, for
    meet-semilattices, we have an operation for minimums.
*)
    

(** Preorders: types which have a "<=" relation which is reflexitive and
    transitive *)
Module PreO.
  (** The relation [le] (read: Less than or Equal) is a preorder when
      it is reflexive [le_refl] and transitive [le_trans]. *)
  Class t {A : Type} {le : crelation A} : Type := 
    { le_refl : forall x, le x x
    ; le_trans : forall x y z, le x y -> le y z -> le x z
    }.

  Arguments t {A} le : clear implicits.

  Instance PreOrder_I `{tle : t A leA} : PreOrder leA.
  Proof.
  constructor.
  - unfold Reflexive. apply le_refl.
  - unfold Transitive. apply le_trans.
  Qed.
  
  (** A morphism of preorders is just a monotonic function. That is,
      it preserves ordering. *)
  Definition morph `(leA : crelation A) `(leB : crelation B) 
   `(f : A -> B) : Type :=
    forall a b, leA a b -> leB (f a) (f b).

  Section Facts.

  Context `{le : crelation A}.
  Context (tA : t le).
  Infix "<=" := le.

  Lemma morph_id : morph le le (fun x => x).
  Proof. 
    unfold morph; auto.
  Qed.

  Lemma morph_compose `(tB : t B leB) `(tC : t C leC)
    : forall (f : A -> B) (g : B -> C), 
     morph le leB f -> morph leB leC g -> morph le leC (fun x => g (f x)).
  Proof.
    unfold morph; auto.
  Qed.

  (** [top t] holds if [t] is bigger than everything *)
  Definition top (t : A) : Type := forall a, a <= t.

  (** [bottom b] holds if [b] is smaller than everything *)
  Definition bottom (b : A) : Type := forall a, b <= a.

  (** [max l r m] holds if [m] is the maximum of [l] and [r]. *)
  Record max {l r m : A} : Type :=
  { max_l     : l <= m
  ; max_r     : r <= m
  ; max_least : forall m', l <= m' -> r <= m' -> m <= m'
  }.

  Arguments max : clear implicits.

  (** [max] is commutative *)
  Lemma max_comm : forall l r m, max l r m -> max r l m.
  Proof.
  intros. destruct X; constructor; auto. 
  Qed.

  (** [min l r m] holds if [m] is the minimum of [l] and [r] *)
  Record min {l r m : A} : Type :=
  { min_l        : m <= l
  ; min_r        : m <= r
  ; min_greatest : forall m', m' <= l -> m' <= r -> m' <= m
  }.

  Global Arguments min : clear implicits.

  (** [min] is commutative *)
  Lemma min_comm : forall l r m, min l r m -> min r l m.
  Proof.
  intros. destruct X; constructor; auto.
  Qed.

  Require Coq.Setoids.Setoid.

  (** [min] is associative, phrased in a relational manner,
      i.e., minima are associative when they exist *)
  Lemma min_assoc : forall a b c, 
    forall bc, min b c bc ->
    forall ab, min a b ab ->
    forall abc, iffT (min a bc abc) (min ab c abc).
  Proof.
  intros a b c bc BC ab AB abc. split; intros ABC.
  - constructor. 
    + apply (min_greatest AB).
      * apply (min_l ABC). 
      * rewrite (min_r ABC). apply (min_l BC). 
    + rewrite (min_r ABC). apply (min_r BC).
    + intros m' H H0. apply (min_greatest ABC).
      * rewrite H. apply (min_l AB).
      * apply (min_greatest BC).  rewrite H. apply (min_r AB).
        assumption.
  - constructor. 
    + rewrite (min_l ABC). apply (min_l AB).
    + apply (min_greatest BC).
      * rewrite (min_l ABC). apply (min_r AB).
      * apply (min_r ABC). 
    + intros m' H H0. apply (min_greatest ABC).
      * apply (min_greatest AB). 
        assumption. rewrite H0. apply (min_l BC).
      * rewrite H0. apply (min_r BC).
  Qed.

  Lemma min_idempotent : forall a, min a a a.
  Proof.
  intros. constructor.
  - reflexivity.
  - reflexivity.
  - intros. assumption.
  Qed.

  (** [sup f m] holds when [m] is the supremum of all
      values indexed by [f]. *)
  Record sup {I : Type} (f : I -> A) (m : A) : Type :=
  { sup_ge : forall i, f i <= m
  ; sup_least : forall m', (forall i, f i <= m') -> m <= m'
  }.

  (** [inf f m] holds when [m] is the infimum of all
      values indexed by [f]. *)
  Record inf {I : Type} (f : I -> A) (m : A) : Type :=
  { inf_le : forall i, m <= f i
  ; inf_greatest : forall m', (forall i, m' <= f i) -> m' <= m
  }.

  (** A directed subset of [A] is one where every two
      elements have a common upper bound. *)
  Definition directed {I} (f : I -> A) :=
    forall i j : I, { k : A & prod (f i <= k) (f j <= k) }.

  End Facts.

  Definition scott_cont `{tA : t A leA} 
  `{tB : t B leB} (f : A -> B) :=
  forall I (g : I -> A), @directed _ leA _ g
  -> forall m, @sup _ leA _ g m 
  -> @sup _ leB _ (fun i => f (g i)) (f m).

  (** [True], the one-element type, has a trivial preorder *)
  Definition one : t (fun (_ : True) _ => True).
  Proof. constructor; auto.
  Qed.

  Require Bool.Bool.

  (** The preorder on booleans given by False < True *)
  Definition two : t Bool.leb.
  Proof. constructor. 
  - intros; auto. destruct x; simpl; trivial.
  - destruct x, y, z; auto. simpl in *. congruence.
  Qed.

  Require Coq.Arith.Le.
  Definition Nat : t le.
  Proof. constructor; [ apply Le.le_refl | apply Le.le_trans ].
  Qed.

  Definition discrete (A : Type) : t (@Logic.eq A).
  Proof. constructor; auto. intros; subst; auto. Qed.

  (** Product preorders *)
  Definition product `(tA : t A leA) `(tB : t B leB) 
   : t (prod_op leA leB).
  Proof. constructor.
   - destruct x. split; apply le_refl.
   - unfold prod_op; intros x y z H H0. 
     destruct x, y, z; simpl in *.
     destruct H, H0.
     split; etransitivity; eassumption.
  Qed.

  (** Given a preorder on [B] and a function [f : A -> B],
      we form a preorder on [A] by asking about their order
      when mapped into [B] by [f]. *)
  Definition map `(f : A -> B) `(tB : t B leB) 
    : t (fun x y => leB (f x) (f y)).
  Proof. constructor; intros.
  - apply le_refl.
  - eapply le_trans; eauto.
  Qed.

  (** It's probably easiest to explain the simply-typed
      version of this: Given a preorder on [B], we can 
      form a preorder on functions of type [A -> B] by saying
      [f <= g] (where [f, g : A -> B]) whenever
      the relation holds pointwise, i.e., for all [a : A],
      we have [f a <= g a]. *)
  Definition pointwise {A} {B : A -> Type} 
    {leB : forall a, B a -> B a -> Type}
    (tB : forall a, t (leB a)) 
    : @t (forall a, B a) (pointwise_op leB).
  Proof. 
    unfold pointwise_op; constructor; intros. 
    - apply le_refl.
    - eapply le_trans; eauto.
  Qed.

  Definition morph_pointwise {A B C} `{tC : t C leC} (f : B -> A)
    : morph (pointwise_op (fun _ => leC)) (pointwise_op (fun _ => leC))
      (fun g b => g (f b)).
  Proof.
    unfold morph, pointwise_op. intros a b H a'; simpl in *; apply H. 
  Qed. 

  (** The type of propositions forms a preorder, where "<=" is
      implication. *)
  Local Instance prop : t (fun (P Q : Prop) => P -> Q).
  Proof. 
    constructor; auto.
  Qed.

  Local Instance type : t arrow.
  Proof.
    constructor; intros.
     - exact (fun x => x).
     - exact (fun x => X0 (X x)).
  Defined.
    

  (** Subsets, in type theory defined as propositional functions,
      i.e., subsets on [A] are functions of type [f : A -> Prop],
      form a preorder ordered by subset inclusion. This is actually just
      the preorder on propositions applied pointwise to functions. *)
  Require Import Algebra.SetsC.

  Local Instance subset (A : Type) : @t (Subset A) _ := pointwise (fun _ => type).

End PreO.

Arguments PreO.max {A} {le} _ _ _ : clear implicits.

(** Partial orders: We take a preorder, but also have an equality relation [eq]
    such that [eq x y] exactly when both [le x y] and [le y x]. *)
Module PO.
  Class t {A : Type} {le : crelation A} {eq : crelation A} : Type :=
  { PreO :> PreO.t le
  ; le_proper : Proper (eq ==> eq ==> iffT) le
  ; le_antisym : forall x y, le x y -> le y x -> eq x y
  }.

  Arguments t {A} le eq : clear implicits.

  Section Morph.
  Context `{tA : t A leA eqA} `{tB : t B leB eqB}.

  Record morph {f : A -> B} : Type :=
   { f_PreO : PreO.morph leA leB f
   ; f_eq : Proper (eqA ==> eqB) f
   }.

  Arguments morph : clear implicits.
  
  End Morph.

  Arguments morph {_} leA eqA {_} leB eqB f.

  Section Facts.
  Context `{tA : t A leA eqA}.

  (** The equality relation of a partial order must form an
      equivalence relation. *)
  Definition eq_refl : Reflexive eqA. 
  Proof. unfold Reflexive. 
    intros. apply le_antisym; apply PreO.le_refl.
  Qed.

  Definition eq_sym : Symmetric eqA.
  Proof. 
  unfold Symmetric. intros x y H. apply le_antisym. eapply le_proper.
  apply eq_refl. apply H. apply PreO.le_refl. eapply le_proper.
  apply H. apply eq_refl. apply PreO.le_refl.
  Qed.

  Definition eq_trans : Transitive eqA.
  Proof.
    unfold Transitive.
    intros x y z H H0. apply le_antisym. eapply le_proper. apply H. 
    apply eq_refl. eapply le_proper. apply H0. apply eq_refl.
    apply PreO.le_refl. eapply le_proper. apply eq_refl. apply H.
    eapply le_proper. apply eq_refl. apply H0. apply PreO.le_refl.
  Qed.

  Lemma max_unique : forall l r m m'
   , PreO.max (le := leA) l r m 
   -> PreO.max (le := leA) l r m' 
   -> eqA m m'.
  Proof.
  intros l r m m' H H0. apply PO.le_antisym.
  - apply H; apply H0.
  - apply H0; apply H.
  Qed.

  Lemma min_unique : forall l r m m'
   , PreO.min (le := leA) l r m 
   -> PreO.min (le := leA) l r m' 
   -> eqA m m'.
  Proof.
  intros l r m m' H H0. apply PO.le_antisym.
  - apply H0; apply H. 
  - apply H; apply H0.
  Qed.

  End Facts.

  Instance t_equiv `{tA : t A leA eqA} : Equivalence eqA.
  Proof. 
    constructor; [apply eq_refl | apply eq_sym | apply eq_trans ].
  Qed.

  Lemma morph_id `{tA : t A leA eqA} : morph leA eqA leA eqA (fun x : A => x).
  Proof. constructor.
    - apply PreO.morph_id. 
    - solve_proper.
  Qed.

  Lemma morph_compose `{tA : t A leA eqA} `{tB : t B leB eqB} `{tC : t C leC eqC}
    : forall (f : A -> B) (g : B -> C), morph leA eqA leB eqB f 
    -> morph leB eqB leC eqC g -> morph leA eqA leC eqC (fun x => g (f x)).
  Proof.
    intros f g H H0. destruct H, H0. constructor; intros.
    - apply (PreO.morph_compose (leB := leB)); eauto using PreO; apply PreO.
    - solve_proper.
  Qed.

  Instance le_properI `(tA : t A leA eqA) 
    : Proper (eqA ==> eqA ==> iffT) leA.
  Proof. intros. apply le_proper. Qed.

  (** Morphisms must respect the equality relations on both their
      source (domain) and target (codomain). *)
  Instance morph_properI `(tA : t A leA eqA) `(tB : t B leB eqB) (f : A -> B)
    : morph leA eqA leB eqB f -> Proper (eqA ==> eqB) f.
  Proof. 
    intros H. destruct H. unfold Proper, respectful. apply f_eq0. 
  Qed.

  (** Now we will extend the preorders we had to partial orders
      in the obvious ways. There's really nothing interesting
      here. *)

  Definition eq_PreO {S} (le : crelation S) (x y : S) : Type :=
    (le x y * le y x)%type.

  Definition fromPreO {S} (le : crelation S) `{POS : PreO.t S le}
    : PO.t le (eq_PreO le).
  Proof.
  constructor.
  - assumption.
  - unfold Proper, respectful, eq_PreO; intros x y H x' y' H0.
(** Broken in Coq
    destruct H, H0; split; intros; eauto using PreO.le_trans.
  - unfold eq_PreO. auto.
  Qed.
*)
  Admitted.

  Definition one : t (fun (_ : True) _ => True) (fun _ _ => True).
  Proof. 
    constructor; intros; auto.
    - apply PreO.one.
    - unfold Proper, respectful. intuition.
  Qed.

  Definition two : t Bool.leb Logic.eq.
  Proof. 
    constructor; intros. 
    - apply PreO.two. 
    - solve_proper. 
    - destruct x, y; auto.
  Qed.

  Definition Nat : t le Logic.eq.
  Proof.
  constructor; intros.
  - apply PreO.Nat.
  - solve_proper.
  - apply Le.le_antisym; assumption.
  Qed.

  Definition discrete (A : Type) : t (@Logic.eq A) Logic.eq.
  Proof.
  constructor; intros.
  - apply PreO.discrete.
  - solve_proper.
  - assumption.
  Qed.

  Definition product `(tA : t A leA eqA) `(tB : t B leB eqB) 
    : t (prod_op leA leB) (prod_op eqA eqB).
  Proof. constructor; intros.
   - apply PreO.product; apply PreO.
   - unfold prod_op, Proper, respectful. intros. 
(** Proof broken...
     intuition;
     (eapply le_proper; 
      [ ((eapply eq_sym; eassumption) || eassumption) 
      | ((eapply eq_sym; eassumption) || eassumption) 
      | eassumption ]).
   - unfold prod_op. destruct H, H0. split; apply le_antisym; intuition.
  Qed.
*)
  Admitted.

  Definition map `(f : A -> B) `(tB : t B leB eqB) : t
    (map_op f leB) (map_op f eqB).
  Proof. constructor; intros.
  - apply (PreO.map f PreO).
  - unfold map_op; split; simpl in *; intros. 
    + rewrite <- X. rewrite <- X0. assumption.
    + rewrite X. rewrite X0. assumption.
  - unfold map_op; eapply le_antisym; eauto.
  Qed.

  Definition pointwise {A} {B : A -> Type}
    {leB eqB : forall a, crelation (B a)}
    (tB : forall a, t (leB a) (eqB a)) : @t (forall a, B a) (pointwise_op leB)
     (pointwise_op eqB).
  Proof. 
  constructor; intros.
  - apply (PreO.pointwise (fun _ => PreO)).  
  - unfold pointwise_op. split; simpl in *; intros. 
    rewrite <- X0. rewrite <- X. apply X1.
    rewrite X0. rewrite X. apply X1.
  - unfold pointwise_op. eauto using le_antisym.
  Qed.

  Definition morph_pointwise {A B C} `{tC : t C leC eqC} (f : B -> A)
    : morph (pointwise_op (fun _ => leC)) (pointwise_op (fun _ => eqC))
            (pointwise_op (fun _ => leC)) (pointwise_op (fun _ => eqC))
      (fun g b => g (f b)).
  Proof.
  constructor; intros; simpl in *; intros.
  - apply PreO.morph_pointwise. 
  - unfold pointwise_op in *. unfold Proper, respectful.
    intros. firstorder.
  Qed. 

  Local Instance prop : t (fun (P Q : Prop) => P -> Q) (fun P Q => P <-> Q).
  Proof. 
  constructor; intuition. apply PreO.prop.
  split; simpl in *; intros; intuition.
  Qed.

  Local Instance type : t arrow iffT.
  Proof. 
  constructor; intuition. apply PreO.type.
  split; simpl in *; intros unfold iffT; firstorder.
  split; assumption.
  Qed.

  Local Instance subset (A : Type) : @t (A -> Type) _ _ := pointwise (fun _ => type).
 
End PO.

(** Join semi-lattices, or directed sets. Here we take a partial order
    and add on a maximum operation. Natural numbers are
    one of many examples. We will often generalize sequences, which
    are functions of type (nat -> A), to nets, which are functions of
    type (I -> A), where I is a directed set. *)
Module JoinLat.

  Class Ops {A} : Type :=
  { le : crelation A
  ; eq : crelation A
  ; max : A -> A -> A
  }. 

  Arguments Ops : clear implicits.

  (** When do the operations [le], [eq], and [max] actually represent
      a join semi-lattice? We need [le] and [eq] to be a partial order,
      and we need our [max] operation to actually implement a maximum. *)
  Class t {A : Type} {O : Ops A} : Type :=
  { PO :> PO.t le eq
  ; max_proper : Proper (eq ==> eq ==> eq) max
  ; max_ok : forall l r, PreO.max (le := le) l r (max l r)
  }.

  Arguments t : clear implicits.

  Instance max_properI `(tA : t A)
    : Proper (eq ==> eq ==> eq) max.
  Proof. intros. apply max_proper. Qed.

  Record morph `{OA : Ops A} `{OB : Ops B}
    {f : A -> B} : Type :=
   { f_PO : PO.morph le eq le eq f
   ; f_max : forall a b, eq (f (max a b)) (max (f a) (f b))
   }.

  Arguments morph {A} OA {B} OB f.

  (** A morphism on join semi-lattices respects the equality relation
      on its source and target. *)
  Lemma f_eq {A B OA OB} {tA : t A OA} {tB : t B OB} {f : A -> B} : 
  morph OA OB f -> Proper (eq ==> eq) f.
  Proof. 
    unfold Proper, respectful. intros H x y xy. apply (PO.f_eq (f_PO H)).
    assumption.
  Qed.

  Lemma morph_id {A OA} (tA : t A OA) 
    : morph OA OA (fun x => x).
  Proof.
  constructor; intros.
  - apply PO.morph_id.
  - apply PO.eq_refl.
  Qed.

  Lemma morph_compose {A B C OA OB OC} 
    (tA : t A OA) (tB : t B OB) (tC : t C OC)
    : forall f g, morph OA OB f 
           -> morph OB OC g 
           -> morph OA OC (fun x => g (f x)).
  Proof.
  intros. constructor; intros.
  - eapply PO.morph_compose; eapply f_PO; eassumption.
  - rewrite <- (f_max X0). rewrite (f_eq X0). reflexivity.
    apply (f_max X).
  Qed.

  (** Max is very boring for the one-point set *)
  Definition one_ops : Ops True :=
    {| le := fun _ _ => True
     ; eq := fun _ _ => True
     ; max := fun _ _ => I
    |}.

  Definition one : t True one_ops.
  Proof. 
  constructor; intros; auto; unfold Proper, respectful; simpl; auto.
  - apply PO.one. 
  - destruct l, r. constructor; tauto.
  Qed.

  (** Max for booleans is the boolean OR. *)
  Definition two_ops : Ops bool :=
    {| le := Bool.leb
     ; eq := Logic.eq
     ; max := orb
    |}.

  Definition two : t bool two_ops.
  Proof. constructor; intros; (
    apply PO.two || solve_proper
    ||
   (try constructor;
  repeat match goal with
  | [ b : bool |- _ ] => destruct b
  end; simpl; auto)).
  Qed. 

  Local Instance Nat_ops : Ops nat :=
    {| le := Peano.le
     ; eq := Logic.eq
     ; max := Peano.max
    |}.

  Require Max.
  Local Instance Nat : t nat Nat_ops.
  Proof. constructor; intros.
  - apply PO.Nat.
  - solve_proper.
  - constructor. simpl. apply Max.le_max_l. apply Max.le_max_r.
    apply Max.max_lub.
  Qed.

  (** Max for propositions is the propositional OR, i.e., disjunction *)
  Local Instance prop_ops : Ops Prop :=
    {| le := fun P Q : Prop => P -> Q
     ; eq := fun P Q : Prop => P <-> Q
     ; max := fun P Q : Prop => P \/ Q
    |}.

  Local Instance prop : t Prop prop_ops.
  Proof. 
    constructor; simpl; intros; constructor; simpl; firstorder.
  Qed.

  Definition pointwise_ops {A B} (O : forall a : A, Ops (B a)) : Ops (forall a, B a) :=
    {| le := pointwise_op (fun a => @le _ (O a))
     ; eq := pointwise_op (fun a => @eq _ (O a))
     ; max :=  (fun f g a => @max _ (O a) (f a) (g a))
    |}.

  Definition pointwise 
    `(tB : forall (a : A), t (B a) (OB a)) : 
     t (forall a, B a) (pointwise_ops OB).
  Proof. constructor; simpl; intros.
    - apply PO.pointwise; intros. eapply @PO; apply tB.
    - unfold respectful, Proper, pointwise_op. intros.
      apply max_proper. apply X. apply X0.
    - constructor; unfold pointwise_op; simpl; intros; apply max_ok.
      apply X. apply X0.
  Qed.

  Definition morph_pointwise {C OC} {tC : t C OC} `(f : B -> A)
    : morph (pointwise_ops (fun _ => OC)) (pointwise_ops (fun _ => OC))
      (fun g b => g (f b)).
  Proof.
  constructor; intros; simpl in *; intros.
  - apply PO.morph_pointwise.
  - unfold pointwise_op. intros. apply PO.eq_refl. 
  Qed. 

  Local Instance subset (A : Type) : t (A -> Prop) (pointwise_ops (fun _ => prop_ops)) 
    := pointwise (fun _ => prop).

  Definition product_ops `(OA : Ops A) `(OB : Ops B) : Ops (A * B) :=
    {| le := prod_op le le
     ; eq := prod_op eq eq
     ; max := fun (x y : A * B) => (max (fst x) (fst y), max (snd x) (snd y))
    |}.

  Definition product {A OA B OB} (tA : t A OA) (tB : t B OB) 
   : t (A * B) (product_ops OA OB).
  Proof. constructor;
    (apply PO.product; apply PO) ||
    (simpl; intros; 
     constructor; unfold prod_op in *; simpl; intros;
    repeat match goal with
    | [ p : (_ * _)%type |- _ ] => destruct p; simpl in *
    | [ p : _ /\ _ |- _ ] => destruct p; simpl in *
    | [  |- (_ * _)%type ] => split
    | [ |- _ ] => eapply PreO.max_l; apply max_ok
    | [ |- _ ] => eapply PreO.max_r; apply max_ok
    | [ |- _ ] => apply max_proper; assumption
    end).
   eapply PreO.max_least. apply max_ok. assumption. assumption.
   eapply PreO.max_least. apply max_ok. assumption. assumption.
   Qed. 
   
End JoinLat.

(** A meet semi-lattice is literally a join semi-lattice turned
    upside-down. Instead of having a [max] operation, it has a [min].
    The code is essentially copied from [JoinLat]. *)
Module MeetLat.

  Class Ops {A} : Type :=
  { le : crelation A
  ; eq : crelation A
  ; min : A -> A -> A
  }.

  Local Infix "<=" := le.
  Local Infix "===" := eq (at level 70).

  Arguments Ops : clear implicits.

  Class t {A : Type} {O : Ops A} : Type :=
  { PO :> PO.t le eq
  ; min_proper : Proper (eq ==> eq ==> eq) min
  ; min_ok : forall l r, PreO.min (le := le) l r (min l r)
  }.

  Arguments t : clear implicits.

  Instance min_properI `(tA : t A)
    : Proper (eq ==> eq ==> eq) min.
  Proof. intros. apply min_proper. Qed.

  Record morph `{OA : Ops A} `{OB : Ops B}
    {f : A -> B} : Type :=
   { f_PO : PO.morph le eq le eq f
   ; f_min : forall a b, f (min a b) === min (f a) (f b)
   }.

  Arguments morph {A} OA {B} OB f.

  Lemma f_eq {A B OA OB} {tA : t A OA} {tB : t B OB} {f : A -> B} : 
  morph OA OB f -> Proper (eq ==> eq) f.
  Proof. 
    unfold Proper, respectful. intros H x y xy. apply (PO.f_eq (f_PO H)).
    assumption.
  Qed.

  Lemma morph_id {A OA} (tA : t A OA) 
    : morph OA OA (fun x => x).
  Proof.
  constructor; intros.
  - apply PO.morph_id.
  - apply PO.eq_refl.
  Qed.

  Lemma morph_compose {A B C OA OB OC} 
    (tA : t A OA) (tB : t B OB) (tC : t C OC)
    : forall f g, morph OA OB f 
           -> morph OB OC g 
           -> morph OA OC (fun x => g (f x)).
  Proof.
  intros. constructor; intros.
  - eapply PO.morph_compose; eapply f_PO; eassumption.
  - rewrite <- (f_min X0). rewrite (f_eq X0). reflexivity.
    apply (f_min X).
  Qed.

  Section Props.
  Context `{tA : t A}.

  Lemma min_l : forall l r, min l r <= l.
  Proof. 
  intros. eapply PreO.min_l. apply min_ok.
  Qed.

  Lemma min_r : forall l r, min l r <= r.
  Proof. 
  intros. eapply PreO.min_r. apply min_ok.
  Qed.

  Lemma min_comm : forall l r, min l r === min r l.
  Proof.
  intros.
  apply PO.min_unique with l r.
  - apply min_ok.
  - apply PreO.min_comm. apply min_ok.
  Qed.

  Lemma min_assoc : forall a b c, 
    min a (min b c) === min (min a b) c.
  Proof. 
  intros.
  apply PO.min_unique with a (min b c).
  - apply min_ok.
  - eapply (snd (PreO.min_assoc _ a b c _ _ _ _ _)). apply min_ok.
  Unshelve. apply min_ok. apply min_ok.
  Qed.

  Lemma min_idempotent : forall a, min a a === a.
  Proof.
  intros. apply PO.min_unique with a a.
  apply min_ok. apply PreO.min_idempotent. apply PO.PreO.
  Qed.

  End Props.

  Definition one_ops : Ops True :=
    {| le := fun _ _ => True
     ; eq := fun _ _ => True
     ; min := fun _ _ => I
    |}.

  Definition one : t True one_ops.
  Proof. 
  constructor; intros; auto; unfold Proper, respectful; simpl; auto.
  - apply PO.one. 
  - destruct l, r. constructor; tauto.
  Qed.

  Definition two_ops : Ops bool :=
    {| le := Bool.leb
     ; eq := Logic.eq
     ; min := andb
    |}.

  Definition two : t bool two_ops.
  Proof. constructor; intros; (
    apply PO.two || solve_proper
    ||
   (try constructor;
  repeat match goal with
  | [ b : bool |- _ ] => destruct b
  end; simpl; auto)).
  Qed. 

  Local Instance prop_ops : Ops Prop :=
    {| le := fun P Q : Prop => P -> Q
     ; eq := fun P Q : Prop => P <-> Q
     ; min := fun P Q : Prop => P /\ Q
    |}.

  Local Instance prop : t Prop prop_ops.
  Proof. 
    constructor; simpl; intros; constructor; simpl; firstorder.
  Qed.

  Definition pointwise_ops {A B} (O : forall a : A, Ops (B a)) : Ops (forall a, B a) :=
    {| le := pointwise_op (fun a => @le _ (O a))
     ; eq := pointwise_op (fun a => @eq _ (O a))
     ; min :=  (fun f g a => @min _ (O a) (f a) (g a))
    |}.

  Definition pointwise 
    `(tB : forall (a : A), t (B a) (OB a)) : 
     t (forall a, B a) (pointwise_ops OB).
  Proof. constructor; simpl; intros.
    - apply PO.pointwise; intros. eapply @PO; apply tB.
    - unfold respectful, Proper, pointwise_op. intros.
      apply min_proper; auto.
    - constructor; unfold pointwise_op; simpl; intros; apply min_ok; auto.
  Qed.

  Definition morph_pointwise {C OC} {tC : t C OC} `(f : B -> A)
    : morph (pointwise_ops (fun _ => OC)) (pointwise_ops (fun _ => OC))
      (fun g b => g (f b)).
  Proof.
  constructor; intros; simpl in *; intros.
  - apply PO.morph_pointwise.
  - unfold pointwise_op. intros. apply PO.eq_refl. 
  Qed. 

  Local Instance subset (A : Type) : t (A -> Prop) (pointwise_ops (fun _ => prop_ops)) 
    := pointwise (fun _ => prop).

  Definition product_ops `(OA : Ops A) `(OB : Ops B) : Ops (A * B) :=
    {| le := prod_op le le
     ; eq := prod_op eq eq
     ; min := fun (x y : A * B) => (min (fst x) (fst y), min (snd x) (snd y))
    |}.

  Definition product {A OA B OB} (tA : t A OA) (tB : t B OB) 
   : t (A * B) (product_ops OA OB).
  Proof. constructor;
    (apply PO.product; apply PO) ||
    (simpl; intros; 
     constructor; unfold prod_op in *; simpl; intros;
    repeat match goal with
    | [ p : (_ * _)%type |- _ ] => destruct p; simpl
    | [ p : _ /\ _ |- _ ] => destruct p; simpl
    | [  |- (_ * _)%type ] => split
    | [ |- _ ] => eapply PreO.min_l; apply min_ok
    | [ |- _ ] => eapply PreO.min_r; apply min_ok
    | [ |- _ ] => apply min_proper; assumption
    end).
   eapply PreO.min_greatest. apply min_ok. assumption. assumption.
   eapply PreO.min_greatest. apply min_ok. assumption. assumption.
   Qed. 

  Lemma sc_monotone {A OA B OB} (tA : t A OA) (tB : t B OB) : forall (f : A -> B),
      PreO.scott_cont f ->
      forall x y : A, x <= y -> f x <= f y.
  Proof.
    intros f H x y xy. 
    unfold PreO.scott_cont in H.
    pose (g := fun b : bool => if b then x else y).
    specialize (H _ g).
    assert (@PreO.directed _ MeetLat.le _ g).
    unfold PreO.directed.
    intros.
    exists y. destruct i, j; simpl; split; 
         assumption || apply PreO.le_refl.
    specialize (H X y).
    assert (@PreO.sup _ MeetLat.le _ g y).
    constructor.
    intros. destruct i; simpl. assumption. reflexivity.
    intros m' X0. specialize (X0 false). simpl in X0.
    assumption.
    specialize (H X0).
    destruct H.
    specialize (sup_ge true). simpl in sup_ge.
    apply sup_ge.
  Qed.
   
End MeetLat.


(** A lattice is both a join semi-lattice and a meet semi-lattice;
    it has both a [max] operation and a [min] operation. Again,
    this is basically just copied from the two modules above. *)
Module Lattice.

  Class Ops {A} : Type :=
    { le : crelation A
    ; eq : crelation A
    ; max : A -> A -> A
    ; min : A -> A -> A
    }.

  Arguments Ops : clear implicits.

  Class t {A : Type} {O : Ops A} : Type :=
  { PO :> PO.t le eq
  ; max_proper : Proper (eq ==> eq ==> eq) max
  ; max_ok : forall l r, PreO.max (le := le) l r (max l r)
  ; min_proper : Proper (eq ==> eq ==> eq) min
  ; min_ok : forall l r, PreO.min (le := le) l r (min l r)
  }.

  Arguments t : clear implicits.

   Definition toMeetLatOps' {A} (ops : Ops A) : MeetLat.Ops A :=
    {| MeetLat.le := le
     ; MeetLat.eq := eq
     ; MeetLat.min := min
    |}.

  Instance toMeetLatOps {A} : Ops A -> MeetLat.Ops A
    := toMeetLatOps'.

  Instance toMeetLat {A ops} : t A ops -> MeetLat.t A (toMeetLatOps ops).
  Proof.
  intros. constructor.
  - apply PO.
  - apply min_proper.
  - apply min_ok.
  Qed.

  Definition toJoinLatOps' {A} (ops : Ops A) : JoinLat.Ops A :=
    {| JoinLat.le := le
     ; JoinLat.eq := eq
     ; JoinLat.max := max
    |}.

  Instance toJoinLatOps {A} : Ops A -> JoinLat.Ops A
    := toJoinLatOps'.

  Instance toJoinLat {A ops} : t A ops -> JoinLat.t A (toJoinLatOps ops).
  Proof.
  intros. constructor.
  - apply PO.
  - apply max_proper.
  - apply max_ok.
  Qed.

  Instance max_properI `(tA : t A)
    : Proper (eq ==> eq ==> eq) max.
  Proof. intros. apply max_proper. Qed.

  Instance min_properI `(tA : t A)
    : Proper (eq ==> eq ==> eq) min.
  Proof. intros. apply min_proper. Qed.

  Record morph `{OA : Ops A} `{OB : Ops B}
    {f : A -> B} : Type :=
   { f_PO : PO.morph le eq le eq f
   ; f_max : forall a b, eq (f (max a b)) (max (f a) (f b))
   ; f_min : forall a b, eq (f (min a b)) (min (f a) (f b))
   }.

  Arguments morph {A} OA {B} OB f.

  Lemma f_eq {A B OA OB} {tA : t A OA} {tB : t B OB} {f : A -> B} : 
  morph OA OB f -> Proper (eq ==> eq) f.
  Proof. 
    unfold Proper, respectful. intros H x y xy. apply (PO.f_eq (f_PO H)).
    assumption.
  Qed.

  Lemma morph_id {A OA} (tA : t A OA) 
    : morph OA OA (fun x => x).
  Proof.
  constructor; intros.
  - apply PO.morph_id.
  - apply PO.eq_refl.
  - apply PO.eq_refl.
  Qed.

  Lemma morph_compose {A B C OA OB OC} 
    (tA : t A OA) (tB : t B OB) (tC : t C OC)
    : forall f g, morph OA OB f 
           -> morph OB OC g 
           -> morph OA OC (fun x => g (f x)).
  Proof.
  intros. constructor; intros.
  - eapply PO.morph_compose; eapply f_PO; eassumption.
  - rewrite <- (f_max X0). rewrite (f_eq X0). reflexivity.
    apply (f_max X).
  - rewrite <- (f_min X0). rewrite (f_eq X0). reflexivity.
    apply (f_min X).
  Qed.

  Definition one_ops : Ops True :=
    {| le := fun _ _ => True
     ; eq := fun _ _ => True
     ; max := fun _ _ => I
     ; min := fun _ _ => I
    |}.

  Definition one : t True one_ops.
  Proof. 
  constructor; intros; auto; unfold Proper, respectful; simpl; auto.
  - apply PO.one. 
  - destruct l, r. constructor; tauto.
  - destruct l, r. constructor; tauto.
  Qed.

  Definition two_ops : Ops bool :=
    {| le := Bool.leb
     ; eq := Logic.eq
     ; max := orb
     ; min := andb
    |}.

  Definition two : t bool two_ops.
  Proof. constructor; intros; (
    apply PO.two || solve_proper
    ||
   (try constructor;
  repeat match goal with
  | [ b : bool |- _ ] => destruct b
  end; simpl; auto)).
  Qed. 

  Local Instance prop_ops : Ops Prop :=
    {| le := fun P Q : Prop => P -> Q
     ; eq := fun P Q : Prop => P <-> Q
     ; max := fun P Q : Prop => P \/ Q
     ; min := fun P Q : Prop => P /\ Q
    |}.

  Local Instance prop : t Prop prop_ops.
  Proof. 
    constructor; simpl; intros; constructor; simpl; firstorder.
  Qed.

  Definition pointwise_ops {A B} (O : forall a : A, Ops (B a)) : Ops (forall a, B a) :=
    {| le := pointwise_op (fun a => @le _ (O a))
     ; eq := pointwise_op (fun a => @eq _ (O a))
     ; max :=  (fun f g a => @max _ (O a) (f a) (g a))
     ; min :=  (fun f g a => @min _ (O a) (f a) (g a))
    |}.

  Definition pointwise 
    `(tB : forall (a : A), t (B a) (OB a)) : 
     t (forall a, B a) (pointwise_ops OB).
  Proof. constructor; simpl; intros.
    - apply PO.pointwise; intros. eapply @PO; apply tB.
    - unfold respectful, Proper, pointwise_op. intros.
      apply max_proper. apply X. apply X0.
    - constructor; unfold pointwise_op; simpl; intros; apply max_ok.
      apply X. apply X0.
    - unfold respectful, Proper, pointwise_op. intros.
      apply min_proper. apply X. apply X0.
    - constructor; unfold pointwise_op; simpl; intros; apply min_ok.
      apply X. apply X0.
  Qed.

  Definition morph_pointwise {C OC} {tC : t C OC} `(f : B -> A)
    : morph (pointwise_ops (fun _ => OC)) (pointwise_ops (fun _ => OC))
      (fun g b => g (f b)).
  Proof.
  constructor; intros; simpl in *; intros.
  - apply PO.morph_pointwise.
  - unfold pointwise_op. intros. apply PO.eq_refl. 
  - unfold pointwise_op. intros. apply PO.eq_refl.
  Qed. 

  Local Instance subset (A : Type) : t (A -> Prop) (pointwise_ops (fun _ => prop_ops)) 
    := pointwise (fun _ => prop).

  Definition product_ops `(OA : Ops A) `(OB : Ops B) : Ops (A * B) :=
    {| le := prod_op le le
     ; eq := prod_op eq eq
     ; max := fun (x y : A * B) => (max (fst x) (fst y), max (snd x) (snd y))
     ; min := fun (x y : A * B) => (min (fst x) (fst y), min (snd x) (snd y))
    |}.

  Definition product {A OA B OB} (tA : t A OA) (tB : t B OB) 
   : t (A * B) (product_ops OA OB).
  Proof. constructor;
    (apply PO.product; apply PO) ||
    (simpl; intros; 
     constructor; unfold prod_op in *; simpl; intros;
    repeat match goal with
    | [ p : (_ * _)%type |- _ ] => destruct p; simpl
    | [ p : _ /\ _ |- _ ] => destruct p; simpl
    | [  |- (_ * _)%type ] => split
    | [ |- _ ] => eapply PreO.max_l; apply max_ok
    | [ |- _ ] => eapply PreO.max_r; apply max_ok
    | [ |- _ ] => eapply PreO.min_l; apply min_ok
    | [ |- _ ] => eapply PreO.min_r; apply min_ok
    | [ |- _ ] => apply max_proper; assumption
    | [ |- _ ] => apply min_proper; assumption
    end).
   eapply PreO.max_least. apply max_ok. assumption. assumption.
   eapply PreO.max_least. apply max_ok. assumption. assumption.
   eapply PreO.min_greatest. apply min_ok. assumption. assumption.
   eapply PreO.min_greatest. apply min_ok. assumption. assumption.
   Qed. 
   
End Lattice.

Module L := Lattice.

(** A frame represents the essence of the algebraic structure of topologies,
    without the requirement that this algebraic structure be formed by
    subsets of an underlying space. The frame is just the algebra itself.
    A frame has a supremum operation, which corresponds to the fact that
    topologies are closed under arbitrary union.
    We call elements of a frame "opens" to indicate that they are reminiscent
    of open sets.

    Frames are also often referred to as locales. They're the same things, but
    are used to indicate opposite categories. The category of frames is the
    opposite of the category of locales. We do this because continuous functions
    are, in a sense, "backwards". A continuous function in topology 
    [f : A -> B] is defined by its inverse image which takes open sets in
    [B] to open sets in [A]. So a continuous function from [A] to [B] corresponds
    to a frame homomorphism from the frame representing the topology of [B] to the
    frame representing the topology of [A]. A frame homomorphism is a morphism
    in the category of frames. The morphisms of the category of locales are called
    continuous maps, and since it's the opposite category, a continuous 
    function from [A] to [B] corresponds to a continuous map from the locale
    for [A] to the locale for [B].
    *)
Module Frame.
  Class Ops {A} :=
   { LOps :> L.Ops A
   ; sup : forall {Ix : Type}, (Ix -> A) -> A
   }.

  Arguments Ops : clear implicits.

  Class t {A} {OA : Ops A}: Type :=
  { L :> L.t A LOps
  ; sup_proper : forall {Ix : Type},
     Proper (pointwise_relation _ L.eq ==> L.eq) (@sup _ _ Ix)
  ; sup_ok :  forall {Ix : Type} (f : Ix -> A), PreO.sup (le := L.le) f (sup f)
  ; sup_distr : forall x {Ix : Type} (f : Ix -> A)
    , L.eq (L.min x (sup f)) (sup (fun i => L.min x (f i)))
  }.

  Arguments t : clear implicits.
  Section Facts.
  Context {A OA} {tA : t A OA}.

  Definition sup_proper_u : forall {Ix : Type} (f g : Ix -> A),
    (forall (i : Ix), L.eq (f i) (g i)) -> L.eq (sup f) (sup g).
  Proof.
  intros. apply sup_proper. unfold pointwise_relation.
  assumption.
  Qed.


  (** Every frame must have a top and bottom element. *)

  Definition top : A := sup (fun a => a).

  Definition top_ok : PreO.top (le := L.le) top.
  Proof. 
    unfold PreO.top. simpl. pose proof (sup_ok (fun a => a)) as H.
    destruct H. apply sup_ge.
  Qed.

  Definition bottom : A := sup (fun contra : False => False_rect _ contra).

  Definition bottom_ok : PreO.bottom (le := L.le) bottom.
  Proof.
    unfold PreO.bottom. intros. 
    apply (PreO.sup_least (fun contra : False => False_rect _ contra)).
    apply sup_ok. intros; contradiction.
  Qed.

  End Facts.
  Section Morph. 
  Context {A OA} {tA : t A OA}.
  Context {B OB} {tB : t B OB}.

  Record morph {f : A -> B} : Type :=
  { f_L : L.morph LOps LOps f
  ; f_sup : forall {Ix : Type} (g : Ix -> A), L.eq (f (sup g)) (sup (fun i => f (g i)))
  ; f_top : L.eq (f top) top
  }.

  Arguments morph : clear implicits.

  Lemma f_eq {f : A -> B} :
    morph f -> Proper (L.eq ==> L.eq) f.
  Proof. 
    intros H. apply (L.f_eq (f_L H)).
  Qed.

  Lemma f_bottom {f : A -> B} : morph f -> L.eq (f bottom) bottom.
  Proof.
  intros MF. unfold bottom. rewrite (f_sup MF). apply sup_proper.
  unfold pointwise_relation. intros. contradiction.
  Qed.

  End Morph.

  Arguments morph {A} OA {B} OB f.

  Section MorphProps.
  Context {A OA} {tA : t A OA}.

  Lemma morph_id : morph OA OA (fun x => x).
  Proof. 
   intros. constructor. apply L.morph_id. apply L.
   reflexivity. reflexivity.
  Qed.

  Lemma morph_compose {B OB} {tB : t B OB}
    {C OC} {tC : t C OC}
     (f : A -> B) (g : B -> C)
     : morph OA OB f 
     -> morph OB OC g 
     -> morph OA OC (fun x => g (f x)).
  Proof. intros. constructor.
  - eapply L.morph_compose; (apply L || (eapply f_L; eassumption)).
  - intros. rewrite <- (f_sup X0). rewrite (f_eq X0).
    reflexivity. rewrite (f_sup X). reflexivity.
  - rewrite <- (f_top X0). rewrite (f_eq X0).
    reflexivity. rewrite (f_top X). reflexivity.
  Qed.

  End MorphProps.

  Definition one_ops : Ops True :=
    {| LOps := L.one_ops
     ; sup := fun _ _ => I
    |}.

  Definition one : t True one_ops.
  Proof. constructor; intros; auto.
  - apply L.one.
  - unfold Proper, respectful. intros. reflexivity.
  - constructor; trivial.
  Qed.

  (** Propositions form a frame, where supremum is given by the
      existential quantifier. *)
  Local Instance prop_ops : Ops Prop :=
    {| LOps := L.prop_ops
     ; sup := (fun _ f => exists i, f i)
    |}.

  Local Instance prop : t Prop prop_ops.
  Proof. constructor; simpl; intros.
  - apply L.prop.
  - constructor; unfold pointwise_relation in X; simpl in X;
     intros [??]; eexists; apply X; eassumption.
  - constructor; simpl; intros.
    + exists i. assumption.
    + destruct H0. apply (H x). assumption.
  - split; intros. 
    + destruct H as (xa & i & fia). exists i. intuition.
    + destruct H as (i & xa & fia). split. assumption.
      exists i. assumption.
  Qed.

  Definition pointwise_ops `(OB : forall a : A, Ops (B a))
    : Ops (forall a, B a) :=
    {| LOps := L.pointwise_ops (fun _ => LOps)
     ; sup := fun _ f => fun x => sup (fun i => f i x)
    |}.

  Definition pointwise `(forall a : A, t (B a) (OB a))
    : t (forall a, B a) (pointwise_ops OB).
  Proof. constructor.
  - apply L.pointwise. intros. apply L.
  - simpl. unfold Proper, respectful, pointwise_relation, pointwise_op.
    intros. apply sup_proper. unfold pointwise_relation.
    intros a'. apply X.
  - constructor; simpl; unfold pointwise_op; intros.
    pose proof (@sup_ok _ _ (H a) Ix (fun i => f i a)).
    apply X.
    pose proof (@sup_ok _ _ (H a) Ix (fun i => f i a)).
    apply X0. intros. apply X.
  - simpl. unfold pointwise_op. intros.
    apply (sup_distr (t := H a)).
  Qed.

  Lemma sup_pointwise {A} {OA} {X : t A OA} {Ix Ix'} (f : Ix -> A) (g : Ix' -> A)
  : (forall (i : Ix), { j : Ix' & L.le (f i) (g j) })
  -> L.le (sup f) (sup g).
  Proof.
  intros H. eapply PreO.sup_least. apply sup_ok. intros.
  destruct (H i). eapply PreO.le_trans. eassumption.
  apply PreO.sup_ge. apply sup_ok.
  Qed.

  Definition morph_pointwise {A B C OC} {tC : t C OC} (f : B -> A)
    : morph (pointwise_ops (fun _ : A => OC)) (pointwise_ops (fun _ : B => OC))
      (fun g b => g (f b)).
  Proof.
  constructor; intros; simpl in *; intros.
  - apply L.morph_pointwise.
  - unfold pointwise_op. intros. apply PO.eq_refl. 
  - unfold pointwise_op. intros. apply PO.le_antisym.
    + apply sup_pointwise. intros. exists (fun b => i (f b)).
      apply PreO.le_refl. 
    + apply sup_pointwise. intros. exists (fun _ => i a). apply PreO.le_refl.
  Qed. 

  Definition subset_ops A : Ops (A -> Prop) := pointwise_ops (fun _ => prop_ops).
  
  Definition subset (A : Type) : t (A -> Prop) (subset_ops A):= 
     pointwise (fun _ : A => prop).

  (** [cmap] represents a continuous map on locales. It is just a
      package for a frame homomorphism running in the opposite direction. *)
  Record cmap {A OA} {B OB} := 
  { finv :> B -> A
  ; cont : morph OB OA finv
  }.

  Arguments cmap {A} OA {B} OB.

  (** A point in [A] is a continuous map from the frame representing
      a space with one point ([Prop]) to [A]. *)
  Definition point {A} (OA : Ops A) := cmap prop_ops OA.

  (** Every function [f : A -> B] is continuous on the topology
      which includes all subsets. *)
  Definition subset_map {A B} (f : A -> B) : cmap (subset_ops A) (subset_ops B).
  Proof.
  refine ( {| finv P x := P (f x) |}).
  apply morph_pointwise.
  Defined.

  Definition cmap_compose {A B C OA OB OC} 
    {tA : t A OA} {tB : t B OB} {tC : t C OC}
    (f : cmap OA OB) (g : cmap OB OC) : cmap OA OC.
  Proof. refine (
  {| finv x := finv f (finv g x) |}
  ). eapply morph_compose; eapply cont.
  Defined. 

End Frame.

(** A definition of commutative and idempotent semigroups.
    This is effectively a semi-lattice (it can be a join semi-lattice
    or a meet semi-lattice depending on your attitude) defined
    solely in terms of its min or max operation.
*)
Module CommIdemSG.

Generalizable All Variables.

Require Import SetoidClass Coq.Classes.Morphisms.

(** [dot] is a binary operation which is commutative, idempotent, and
    associative. It is effectively a max or min. *)
Class t {A} {eq : A -> A -> Prop} {dot : A -> A -> A} :=
  { eq_equiv :> Equivalence eq
  ; dot_proper :> Proper (eq ==> eq ==> eq) dot
  ; dot_idempotent : forall a, eq (dot a a) a
  ; dot_comm : forall a b, eq (dot a b) (dot b a)
  ; dot_assoc : forall a b c, eq (dot a (dot b c)) (dot (dot a b) c)
  }.

Arguments t : clear implicits.

Section Facts.
Context `{tA : t A eql dot}.

(** Here we define a "<=" relation which makes the [dot] a
    [min] operation for a meet semi-lattice *)
Definition ops : MeetLat.Ops A :=
  {| MeetLat.le := fun x y => eql (dot x y) x
   ; MeetLat.eq := eql
   ; MeetLat.min := dot
  |}.

Instance ops' : MeetLat.Ops A := ops.

(** Next, we prove successively, that these definitions using
    the [dot] operator indeed define a preorder, a partial order,
    and finally a meet semi-lattice. *)
Theorem asPreO : PreO.t MeetLat.le.
Proof.
constructor; simpl; intros.
- apply dot_idempotent.
- rewrite <- H. rewrite <- H0 at 2.
  rewrite dot_assoc. reflexivity.
Qed.

Theorem asPO : PO.t MeetLat.le eql.
Proof.
constructor.
- apply asPreO.
- repeat intro; simpl; split; intros. 
  rewrite <- H, <- H0. assumption.
  rewrite H, H0. assumption.
- simpl. intros. rewrite <- H. rewrite <- H0 at 2.
  rewrite dot_comm. reflexivity.
Qed.

Instance asMeetLat : MeetLat.t A ops.
Proof.
constructor. 
- apply asPO.
- unfold CMorphisms.Proper, CMorphisms.respectful; intros. 
  simpl in *. rewrite X, X0. reflexivity.
- intros. constructor; simpl; intros.
  + rewrite dot_comm. rewrite dot_assoc.
    rewrite dot_idempotent. reflexivity.
  + rewrite <- dot_assoc. rewrite dot_idempotent.
    reflexivity.
  + rewrite <- H at 2. rewrite <- H0 at 2.
    rewrite (dot_comm l r). rewrite dot_assoc.
    reflexivity.
Qed.

End Facts.
End CommIdemSG.