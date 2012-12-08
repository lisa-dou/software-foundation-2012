(** * Equiv: Program Equivalence *)

(* $Date: 2012-04-06 19:32:51 -0400 (Fri, 06 Apr 2012) $ *)


Require Export Imp.

(** *** Some general advice for working on problems

    - We've tried to make sure that most of the Coq proofs we ask you
      to do are similar to proofs that we've provided.  Before
      starting to work on the homework problems, take the time to work
      through our proofs (both informally, on paper, and in Coq) and
      make sure you understand them in detail.  This will save you a
      lot of time.

    - The Coq proofs we're doing now are sufficiently complicated that
      it is more or less impossible to complete them simply by
      "following your nose" or random hacking.  You need to start with
      an idea about why the property is true and how the proof is
      going to go.  The best way to do this is to write out at least a
      sketch of an informal proof on paper -- one that intuitively
      convinces you of the truth of the theorem -- before starting to
      work on the formal one.

    - Use automation to save work!  Some of the proofs in this
      chapter's exercises are pretty long if you try to write out all
      the cases explicitly. *)

(* ####################################################### *)
(** * Behavioral Equivalence *)

(** In the last chapter, we investigated the correctness of a very
    simple program transformation: the [optimize_0plus] function.  The
    programming language we were considering was the first version of
    the language of arithmetic expressions -- with no variables -- so
    in that setting it was very easy to define what it _means_ for a
    program transformation to be correct: it should always yield a
    program that evaluates to the same number as the original.  

    To go further and talk about the correctness of program
    transformations in the full Imp language, we need to consider the
    role of variables and state. *)

(* ####################################################### *)
(** ** Definitions *)

(** For [aexp]s and [bexp]s with variables, the definition we want is
    clear.  We say
    that two [aexp]s or [bexp]s are _behaviorally equivalent_ if they
    evaluate to the same result _in every state_. *)
 
Definition aequiv (a1 a2 : aexp) : Prop :=
  forall (st:state), 
    aeval st a1 = aeval st a2.

Definition bequiv (b1 b2 : bexp) : Prop :=
  forall (st:state), 
    beval st b1 = beval st b2.

(** For commands, the situation is a little more subtle.  We can't
    simply say "two commands are behaviorally equivalent if they
    evaluate to the same ending state whenever they are started in the
    same initial state," because some commands (in some starting
    states) don't terminate in any final state at all!  What we need
    instead is this: two commands are behaviorally equivalent if, for
    any given starting state, they either both diverge or both
    terminate in the same final state.  A compact way to express this
    is "if the first one terminates in a particular state then so does
    the second, and vice versa." *)

Definition cequiv (c1 c2 : com) : Prop :=
  forall (st st' : state), 
    (c1 / st || st') <-> (c2 / st || st').

(** **** Exercise: 2 stars, optional (pairs_equiv) *)
(** Which of the following pairs of programs are equivalent? Write
    "yes" or "no" for each one.

(a)
    WHILE (BLe (ANum 1) (AId X)) DO 
      X ::= APlus (AId X) (ANum 1) 
    END
    and
    WHILE (BLe (ANum 2) (AId X)) DO 
      X ::= APlus (AId X) (ANum 1) 
    END
(* no *)

(b) 
    WHILE BTrue DO 
      WHILE BFalse DO X ::= APlus (AId X) (ANum 1) END 
    END
and
    WHILE BFalse DO 
      WHILE BTrue DO X ::= APlus (AId X) (ANum 1) END 
    END

(* yes *)
 [] *)

(** **** Exercise: 3 stars (equiv_classes) *)

(** Given the following programs, group together those that are
    equivalent in [Imp].  For example, if you think programs (a)
    through (h) are all equivalent to each other, but not to (i), your
    answer should look like this: {a,b,c,d,e,f,g,h} {i}.

(a)
    WHILE X > 0 DO
      X ::= X + 1
    END

(b)
    IFB X = 0 THEN
      X ::= X + 1;
      Y ::= 1
    ELSE
      Y ::= 0
    FI;
    X ::= X - Y;
    Y ::= 0

(c)
    SKIP

(d)
    WHILE X <> 0 DO
      X ::= X * Y + 1
    END

(e)
    Y ::= 0

(f)
    Y ::= X + 1;
    WHILE X <> Y DO
      Y ::= X + 1
    END

(g)
    WHILE BTrue DO
      SKIP
    END

(h)
    WHILE X <> X DO
      X ::= X + 1
    END

(i)
    WHILE X <> Y DO
      X ::= Y + 1
    END

(* FILL IN HERE *)
[] *)


(* ####################################################### *)

(** ** Examples *)

(** Here are some simple examples of equivalences of arithmetic
    and boolean expressions. *)

Theorem aequiv_example:
  aequiv (AMinus (AId X) (AId X)) (ANum 0).
Proof.
  intros st. simpl. apply minus_diag.  
Qed.

Theorem bequiv_example:
  bequiv (BEq (AMinus (AId X) (AId X)) (ANum 0)) BTrue. 
Proof. 
  intros st. unfold beval.
  rewrite aequiv_example. reflexivity.
Qed.

(** For examples of command equivalence, let's start by looking at
    some trivial program transformations involving [SKIP]: *)

Theorem skip_left: forall c,
  cequiv 
     (SKIP; c) 
     c.
Proof. 
  (* WORKED IN CLASS *)
  intros c st st'.
  split; intros H.
  Case "->". 
    inversion H. subst. 
    inversion H2. subst. 
    assumption.
  Case "<-". 
    apply E_Seq with st.
    apply E_Skip. 
    assumption.  
Qed.

(** **** Exercise: 2 stars (skip_right) *)
Theorem skip_right: forall c,
  cequiv 
    (c; SKIP) 
    c.
Proof. 
  intros c st st'.
   split;intros H.
  Case "->".
   inversion H. subst.
   inversion H5. subst. assumption.
  Case "<-".
   apply E_Seq with st'. 
   assumption.
   apply E_Skip.
Qed.
 
(** Similarly, here is a simple transformations that simplifies [IFB]
    commands: *)

Theorem IFB_true_simple: forall c1 c2,
  cequiv 
    (IFB BTrue THEN c1 ELSE c2 FI) 
    c1.
Proof. 
  intros c1 c2. 
  split; intros H.
  Case "->".
    inversion H; subst. assumption. inversion H5.
  Case "<-".
    apply E_IfTrue. reflexivity. assumption.  Qed.

(** Of course, few programmers would be tempted to write a conditional
    whose guard is literally [BTrue].  A more interesting case is when
    the guard is _equivalent_ to true:

   _Theorem_: If [b] is equivalent to [BTrue], then [IFB b THEN c1
   ELSE c2 FI] is equivalent to [c1].

   _Proof_: 

     - ([->]) We must show, for all [st] and [st'], that if [IFB b
       THEN c1 ELSE c2 FI / st || st'] then [c1 / st || st'].

       Proceed by cases on the rules that could possibly have been
       used to show [IFB b THEN c1 ELSE c2 FI / st || st'], namely
       [E_IfTrue] and [E_IfFalse].

       - Suppose the final rule rule in the derivation of [IFB b THEN
         c1 ELSE c2 FI / st || st'] was [E_IfTrue].  We then have, by
         the premises of [E_IfTrue], that [c1 / st || st'].  This is
         exactly what we set out to prove.

       - On the other hand, suppose the final rule in the derivation
         of [IFB b THEN c1 ELSE c2 FI / st || st'] was [E_IfFalse].
         We then know that [beval st b = false] and [c2 / st || st'].

         Recall that [b] is equivalent to [BTrue], i.e. forall [st],
         [beval st b = beval st BTrue].  In particular, this means
         that [beval st b = true], since [beval st BTrue = true].  But
         this is a contradiction, since [E_IfFalse] requires that
         [beval st b = false].  Thus, the final rule could not have
         been [E_IfFalse].

     - ([<-]) We must show, for all [st] and [st'], that if [c1 / st
       || st'] then [IFB b THEN c1 ELSE c2 FI / st || st'].

       Since [b] is equivalent to [BTrue], we know that [beval st b] =
       [beval st BTrue] = [true].  Together with the assumption that
       [c1 / st || st'], we can apply [E_IfTrue] to derive [IFB b THEN
       c1 ELSE c2 FI / st || st'].  []

   Here is the formal version of this proof: *)

Theorem IFB_true: forall b c1 c2,
     bequiv b BTrue  ->
     cequiv 
       (IFB b THEN c1 ELSE c2 FI) 
       c1.
Proof.
  intros b c1 c2 Hb.
  split; intros H.
  Case "->".
    inversion H; subst.
    SCase "b evaluates to true".
      assumption.
    SCase "b evaluates to false (contradiction)".
      rewrite Hb in H5.
      inversion H5.
  Case "<-".
    apply E_IfTrue; try assumption.
    rewrite Hb. reflexivity.  Qed.

(** **** Exercise: 2 stars, recommended (IFB_false) *)
Theorem IFB_false: forall b c1 c2,
  bequiv b BFalse  ->
  cequiv 
    (IFB b THEN c1 ELSE c2 FI) 
    c2.
Proof.
  intros b c1 c2 Hb.
  split; intros H.
  Case "->".
    inversion H; subst.
    SCase "b evaluates to true".
       rewrite Hb in H5.
       inversion H5.      
    SCase "b evaluates to false (contradiction)".
       assumption.      
  Case "<-".
    apply E_IfFalse;try assumption.
    rewrite Hb. reflexivity.  Qed.

(** **** Exercise: 3 stars (swap_if_branches) *)
Theorem swap_if_branches: forall b e1 e2,
  cequiv
    (IFB b THEN e1 ELSE e2 FI)
    (IFB BNot b THEN e2 ELSE e1 FI).
Proof.
   intros b e1 e2 st st'.
   split;intros H.
   Case "->".
       inversion H. subst. 
    SCase "b is true".      
      apply E_IfFalse. simpl.   rewrite H5. reflexivity.
      assumption.
    SCase "b is false".
      subst. apply E_IfTrue.  simpl. rewrite H5. simpl. reflexivity.
      assumption.
   Case "<-".
      inversion H. subst.
      SCase "b is false".
       apply E_IfFalse;try assumption. 
       inversion H5. unfold negb in H1. destruct (beval st b).
       inversion H1. reflexivity.
      SCase "b is true".
        apply E_IfTrue;try assumption.
        subst. inversion H5. unfold negb in H1. destruct (beval st b).
       reflexivity.  inversion H1.
Qed.

(** For [WHILE] loops, we can give a similar pair of theorems.  A loop
    whose guard is equivalent to [BFalse] is equivalent to [SKIP],
    while a loop whose guard is equivalent to [BTrue] is equivalent to
    [WHILE BTrue DO SKIP END] (or any other non-terminating program).
    The first of these facts is easy. *)

Theorem WHILE_false : forall b c,
     bequiv b BFalse ->
     cequiv
       (WHILE b DO c END)
       SKIP.
Proof. 
  intros b c Hb. split; intros H.
  Case "->".
    inversion H; subst.
    SCase "E_WhileEnd".
      apply E_Skip.
    SCase "E_WhileLoop".
      rewrite Hb in H2. inversion H2.
  Case "<-".
    inversion H; subst.
    apply E_WhileEnd.
    rewrite Hb.
    reflexivity.  Qed.

(** **** Exercise: 2 stars (WHILE_false_informal) *)
(** Write an informal proof of [WHILE_false].

(* FILL IN HERE *)
[]
*)

(** To prove the second fact, we need an auxiliary lemma stating that
    [WHILE] loops whose guards are equivalent to [BTrue] never
    terminate:

    _Lemma_: If [b] is equivalent to [BTrue], then it cannot be the
    case that [(WHILE b DO c END) / st || st'].

    _Proof_: Suppose that [(WHILE b DO c END) / st || st'].  We show,
    by induction on a derivation of [(WHILE b DO c END) / st || st'],
    that this assumption leads to a contradiction.  

      - Suppose [(WHILE b DO c END) / st || st'] is proved using rule
        [E_WhileEnd].  Then by assumption [beval st b = false].  But
        this contradicts the assumption that [b] is equivalent to
        [BTrue].

      - Suppose [(WHILE b DO c END) / st || st'] is proved using rule
        [E_WhileLoop].  Then we are given the induction hypothesis
        that [(WHILE b DO c END) / st || st'] is contradictory, which
        is exactly what we are trying to prove!

      - Since these are the only rules that could have been used to
        prove [(WHILE b DO c END) / st || st'], the other cases of
        the induction are immediately contradictory. [] *)

Lemma WHILE_true_nonterm : forall b c st st',
     bequiv b BTrue ->
     ~( (WHILE b DO c END) / st || st' ).
Proof. 
  (* WORKED IN CLASS *)
  intros b c st st' Hb.
  intros H.
  remember (WHILE b DO c END) as cw.
  ceval_cases (induction H) Case;
    (* Most rules don't apply, and we can rule them out 
       by inversion *)
    inversion Heqcw; subst; clear Heqcw.
  (* The two interesting cases are the ones for WHILE loops: *)
  Case "E_WhileEnd". (* contradictory -- b is always true! *)
unfold bequiv in Hb.
    rewrite Hb in H. inversion H.
  Case "E_WhileLoop". (* immediate from the IH *)
    apply IHceval2. reflexivity.  Qed.

(** **** Exercise: 2 stars, optional (WHILE_true_nonterm_informal) *)
(** Explain what the lemma [WHILE_true_nonterm] means in English.

(* FILL IN HERE *)
*)
(** [] *)

(** **** Exercise: 2 stars, recommended (WHILE_true) *)
(** Hint: You'll want to use [WHILE_true_nonterm] here. *)

Theorem WHILE_true: forall b c,
     bequiv b BTrue  ->
     cequiv 
       (WHILE b DO c END)
       (WHILE BTrue DO SKIP END).
Proof. 
    intros. unfold cequiv. intros st st'. split;intro. 
Case "->".
  apply WHILE_true_nonterm with (st:=st)(st':=st') in H0.
  inversion H0. assumption. 
Case "<-".
  inversion H0; subst.
  SCase "b=false".
    inversion H5.
  SCase "b=true".
    inversion H4;subst.
    apply WHILE_true_nonterm with (b:=BTrue)(c:=SKIP)(st:=st'0)(st':=st') in H0.
    inversion H0.
    unfold bequiv. intros. reflexivity. 
Qed.

Theorem loop_unrolling: forall b c,
  cequiv
    (WHILE b DO c END)
    (IFB b THEN (c; WHILE b DO c END) ELSE SKIP FI).
Proof.
  (* WORKED IN CLASS *)
  intros b c st st'.
  split; intros Hce.
  Case "->".
    inversion Hce; subst.  
    SCase "loop doesn't run".
      apply E_IfFalse. assumption. apply E_Skip.
    SCase "loop runs".
      apply E_IfTrue. assumption.
      apply E_Seq with (st' := st'0). assumption. assumption.
  Case "<-".
    inversion Hce; subst.
    SCase "loop runs".
      inversion H5; subst.
      apply E_WhileLoop with (st' := st'0). 
      assumption. assumption. assumption.
    SCase "loop doesn't run".
      inversion H5; subst. apply E_WhileEnd. assumption.  Qed.

(** **** Exercise: 2 stars, optional (seq_assoc) *)
Theorem seq_assoc : forall c1 c2 c3,
  cequiv ((c1;c2);c3) (c1;(c2;c3)).
Proof.
  unfold cequiv. intros.
  split;intros.
Case "->".
  inversion H. subst. inversion H2. subst.
  apply E_Seq with (st':=st'1).
  assumption. apply E_Seq with (st':=st'0).
  assumption. assumption.
Case "<-".
 inversion H. subst. inversion H5. subst.
 apply E_Seq with (st':=st'1).
 apply E_Seq with (st':=st'0).
 assumption. assumption. assumption.
Qed.


(** ** The Functional Equivalence Axiom *)

(** Finally, let's look at simple equivalences involving assignments.
    For example, we might expect to be able to show that [X ::= AId X]
    is equivalent to [SKIP].  However, when we try to show it, we get
    stuck in an interesting way. *)

Theorem identity_assignment_first_try : forall (X:id),
  cequiv (X ::= AId X) SKIP.
Proof. 
   intros. split; intro H.
     Case "->". 
       inversion H; subst.  simpl.
       replace (update st X (st X)) with st.  
       constructor. 
       (* Here we're stuck. The goal looks reasonable,
          but in fact it is not provable!  If we look back
          at the set of lemmas we proved about [update] in
          the last chapter, we can see that lemma
          [update_same] almost does the job, but not quite:
          it says that the original and updated states
          agree at all values, but this is not the same
          thing as saying that they are [=] in Coq's
          sense! *)
Admitted.

(** What is going on here?  Recall that our states are just
    functions from identifiers to values.  For Coq, functions are only
    equal when their definitions are syntactically the same, modulo
    simplification.  (This is the only way we can legally apply the
    [refl_equal] constructor of the inductively defined proposition
    [eq]!) In practice, for functions built up by repeated uses of the
    [update] operation, this means that two functions can be proven
    equal only if they were constructed using the _same_ [update]
    operations, applied in the same order.  In the theorem above, the
    sequence of updates on the first parameter [cequiv] is one longer
    than for the second parameter, so it is no wonder that the
    equality doesn't hold. *)

(** This problem is actually quite general. If we try to prove other
    simple facts, such as
    cequiv (X ::= APlus (AId X ANum 1) ; 
            X ::= APlus (AId X ANum 1))
           (X ::= APlus (AId X ANum 2))
    or
    cequiv (X ::= ANum 1; Y ::= ANum 2) 
           (y ::= ANum 2; X ::= ANum 1)
  
    we'll get stuck in the same way: we'll have two functions that
    behave the same way on all inputs, but cannot be proven to be [eq]
    to each other.

    The reasoning principle we would like to use in these situations
    is called _functional extensionality_:
                        forall x, f x = g x
                        -------------------
                               f = g
    Although this principle is not derivable in Coq's built-in logic,
    it is safe to add it as an additional _axiom_.  *)

Axiom functional_extensionality : forall {X Y: Type} {f g : X -> Y},
    (forall (x: X), f x = g x) ->  f = g.

(** It can be shown that adding this axiom doesn't introduce any
    inconsistencies into Coq.  (In this way, it is similar to adding
    one of the classical logic axioms, such as [excluded_middle].) *)

(** With the benefit of this axiom we can prove our theorem.  *)

Theorem identity_assignment : forall (X:id),
  cequiv
    (X ::= AId X)
    SKIP.
Proof. 
   intros. split; intro H.
     Case "->". 
       inversion H; subst. simpl.
       replace (update st X (st X)) with st.  
       constructor. 
       apply functional_extensionality. intro. 
       rewrite update_same; reflexivity.  
     Case "<-".
       inversion H; subst. 
       assert (st' = (update st' X (st' X))).
          apply functional_extensionality. intro. 
          rewrite update_same; reflexivity.
       rewrite H0 at 2. 
       constructor. reflexivity.
Qed.

(** **** Exercise: 2 stars, recommended (assign_aequiv) *)
Theorem assign_aequiv : forall X e,
  aequiv (AId X) e -> 
  cequiv SKIP (X ::= e).
Proof.
  Proof.
  unfold cequiv.  intros. split; intro H2.
Case "->".
  inversion H2. subst. 
  assert (st'=(update st' X (aeval st' e))).
  unfold aequiv in H.
  rewrite <-H.
  simpl. apply functional_extensionality. intro.
  rewrite update_same. reflexivity. reflexivity.
  rewrite H0 at 2. constructor. reflexivity.
Case "<-".
  inversion H2. subst.
  replace (update st X (aeval st e))  with st.
  constructor.
  unfold aequiv in H. rewrite <-H. simpl.
  apply functional_extensionality. intro.
  rewrite update_same. reflexivity. reflexivity.
Qed.


(** **** Exercise: 2 stars, optional (functional_extensionality_failed_false) *)

(** As we just mentioned, functional extensionality doesn't add
    any inconsistencies into Coq. However, consider the following
    theorem.  Inspired by it, we present an attempt to prove
    [False]. Briefly explain why it will fail. *)

Theorem feff_1 : true = false -> False.
Proof.
  intros. inversion H.
Qed.

Lemma feff_2 : empty_state = update empty_state X 0.
Proof.
  apply functional_extensionality. intros.
  destruct x as [n]. destruct n as [| n'].
  Case "x = AId 0". reflexivity.
  Case "x = AId (S n')". reflexivity.
Qed.
Check true.
Check bool.
Print bool.
(*
Lemma feff_3 : empty_state = update empty_state X 0 -> False.
Proof.
  intros.
 inversion H. (* And this makes no progress! *)
Qed. 
*)

(** If we were able to prove [feff_3], then together with [feff_2],
    a proof of [False] is immediate. Explain why the
    [inversion H] fails, though it works in [feff_1]. *)

(* FILL IN HERE *)

(* ####################################################### *)
(** * Properties of Behavioral Equivalence *)

(** We now turn to developing some of the properties of the program
    equivalences we have defined. *)

(* ####################################################### *)
(** ** Behavioral Equivalence is an Equivalence *)

(** First, we verify that the equivalences on [aexps], [bexps], and
    [com]s really are _equivalences_ -- i.e., that they are reflexive,
    symmetric, and transitive: *)

Lemma refl_aequiv : forall (a : aexp), aequiv a a.
Proof.
  intros a st. reflexivity.  Qed.

Lemma sym_aequiv : forall (a1 a2 : aexp), 
  aequiv a1 a2 -> aequiv a2 a1.
Proof.
  intros a1 a2 H. intros st. symmetry. apply H.  Qed.

Lemma trans_aequiv : forall (a1 a2 a3 : aexp), 
  aequiv a1 a2 -> aequiv a2 a3 -> aequiv a1 a3. 
Proof.
  unfold aequiv. intros a1 a2 a3 H12 H23 st.
  rewrite (H12 st). rewrite (H23 st). reflexivity.  Qed.

Lemma refl_bequiv : forall (b : bexp), bequiv b b.
Proof.
  unfold bequiv. intros b st. reflexivity.  Qed.

Lemma sym_bequiv : forall (b1 b2 : bexp), 
  bequiv b1 b2 -> bequiv b2 b1.
Proof.
  unfold bequiv. intros b1 b2 H. intros st. symmetry. apply H.  Qed.

Lemma trans_bequiv : forall (b1 b2 b3 : bexp), 
  bequiv b1 b2 -> bequiv b2 b3 -> bequiv b1 b3. 
Proof.
  unfold bequiv. intros b1 b2 b3 H12 H23 st.
  rewrite (H12 st). rewrite (H23 st). reflexivity.  Qed.

Lemma refl_cequiv : forall (c : com), cequiv c c.
Proof.
  unfold cequiv. intros c st st'. apply iff_refl.  Qed.

Lemma sym_cequiv : forall (c1 c2 : com), 
  cequiv c1 c2 -> cequiv c2 c1.
Proof.
  unfold cequiv. intros c1 c2 H st st'.
  assert (c1 / st || st' <-> c2 / st || st') as H'. 
    SCase "Proof of assertion". apply H.
  apply iff_sym. assumption.
Qed.

Lemma iff_trans : forall (P1 P2 P3 : Prop), 
  (P1 <-> P2) -> (P2 <-> P3) -> (P1 <-> P3).
Proof.
  intros P1 P2 P3 H12 H23.
  inversion H12. inversion H23.
  split; intros A. 
    apply H1. apply H. apply A.
    apply H0. apply H2. apply A.  Qed.

Lemma trans_cequiv : forall (c1 c2 c3 : com), 
  cequiv c1 c2 -> cequiv c2 c3 -> cequiv c1 c3. 
Proof.
  unfold cequiv. intros c1 c2 c3 H12 H23 st st'.
  apply iff_trans with (c2 / st || st'). apply H12. apply H23.  Qed.

(* ########################################################*)
(** ** Behavioral Equivalence is a Congruence *)

(** Less obviously, behavioral equivalence is also a _congruence_.
    That is, the equivalence of two subprograms implies the
    equivalence of the larger programs in which they are embedded:
              aequiv a1 a1'
      -----------------------------
      cequiv (i ::= a1) (i ::= a1')
 
              cequiv c1 c1'    
              cequiv c2 c2'
         ------------------------
         cequiv (c1;c2) (c1';c2')
    ...and so on.  (Note that we are using the inference rule notation
    here not as part of a definition, but simply to write down some
    valid implications in a readable format. We prove these
    implications below.) *)
 
(** We will see a concrete example of why these congruence
    properties are important in the following section (in the proof of
    [fold_constants_com_sound]), but the main idea is that they allow
    us to replace a small part of a large program with an equivalent
    small part and know that the whole large programs are equivalent
    _without_ doing an explicit proof about the non-varying parts --
    i.e., the "proof burden" of a small change to a large program is
    proportional to the size of the change, not the program. *)

Theorem CAss_congruence : forall i a1 a1',
  aequiv a1 a1' ->
  cequiv (CAss i a1) (CAss i a1').
Proof.
  intros i a1 a2 Heqv st st'.
  split; intros Hceval.
  Case "->".
    inversion Hceval. subst. apply E_Ass. 
    rewrite Heqv. reflexivity.
  Case "<-".
    inversion Hceval. subst. apply E_Ass.
    rewrite Heqv. reflexivity.  Qed.

(** The congruence property for loops is a little more interesting,
    since it requires induction.

    _Theorem_: Equivalence is a congruence for [WHILE] -- that is, if
    [b1] is equivalent to [b1'] and [c1] is equivalent to [c1'], then
    [WHILE b1 DO c1 END] is equivalent to [WHILE b1' DO c1' END].

    _Proof_: Suppose [b1] is equivalent to [b1'] and [c1] is
    equivalent to [c1'].  We must show, for every [st] and [st'], that
    [WHILE b1 DO c1 END / st || st'] iff [WHILE b1' DO c1' END / st
    || st'].  We consider the two directions separately.

      - ([->]) We show that [WHILE b1 DO c1 END / st || st'] implies
        [WHILE b1' DO c1' END / st || st'], by induction on a
        derivation of [WHILE b1 DO c1 END / st || st'].  The only
        nontrivial cases are when the final rule in the derivation is
        [E_WhileEnd] or [E_WhileLoop].

          - [E_WhileEnd]: In this case, the form of the rule gives us
            [beval st b1 = false] and [st = st'].  But then, since
            [b1] and [b1'] are equivalent, we have [beval st b1' =
            false], and [E-WhileEnd] applies, giving us [WHILE b1' DO
            c1' END / st || st'], as required.

          - [E_WhileLoop]: The form of the rule now gives us [beval st
            b1 = true], with [c1 / st || st'0] and [WHILE b1 DO c1
            END / st'0 || st'] for some state [st'0], with the
            induction hypothesis [WHILE b1' DO c1' END / st'0 ||
            st'].  

            Since [c1] and [c1'] are equivalent, we know that [c1' /
            st || st'0].  And since [b1] and [b1'] are equivalent, we
            have [beval st b1' = true].  Now [E-WhileLoop] applies,
            giving us [WHILE b1' DO c1' END / st || st'], as
            required.

      - ([<-]) Similar. [] *)

Theorem CWhile_congruence : forall b1 b1' c1 c1',
  bequiv b1 b1' -> cequiv c1 c1' ->
  cequiv (WHILE b1 DO c1 END) (WHILE b1' DO c1' END).
Proof.
  (* WORKED IN CLASS *)
  unfold bequiv,cequiv.
  intros b1 b1' c1 c1' Hb1e Hc1e st st'.
  split; intros Hce.
  Case "->".
    remember (WHILE b1 DO c1 END) as cwhile.
    induction Hce; inversion Heqcwhile; subst.
    SCase "E_WhileEnd".
      apply E_WhileEnd. rewrite <- Hb1e. apply H.
    SCase "E_WhileLoop".
      apply E_WhileLoop with (st' := st').
      SSCase "show loop runs". rewrite <- Hb1e. apply H.
      SSCase "body execution". 
        apply (Hc1e st st').  apply Hce1. 
      SSCase "subsequent loop execution".
        apply IHHce2. reflexivity.
  Case "<-".
    remember (WHILE b1' DO c1' END) as c'while.
    induction Hce; inversion Heqc'while; subst.
    SCase "E_WhileEnd".
      apply E_WhileEnd. rewrite -> Hb1e. apply H.
    SCase "E_WhileLoop".
      apply E_WhileLoop with (st' := st').
      SSCase "show loop runs". rewrite -> Hb1e. apply H.
      SSCase "body execution". 
        apply (Hc1e st st').  apply Hce1. 
      SSCase "subsequent loop execution".
        apply IHHce2. reflexivity.  Qed.

(** **** Exercise: 3 stars, optional (CSeq_congruence) *)
Theorem CSeq_congruence : forall c1 c1' c2 c2',
  cequiv c1 c1' -> cequiv c2 c2' ->
  cequiv (c1;c2) (c1';c2').
Proof. 
  unfold cequiv.
  intros.
  split;intros.
Case "->".
  remember (c1;c2) as cseq.  
  induction H1; inversion Heqcseq;subst.  
  apply E_Seq with (st':=st').
  apply H. assumption. apply (H0 st' st''). assumption.
Case "<-".
  remember (c1';c2') as cseq.
  induction H1; inversion Heqcseq;subst.
  apply E_Seq with (st':=st').
  apply H. assumption.
  apply (H0 st' st''). assumption.
Qed.

(** **** Exercise: 3 stars (CIf_congruence) *)
Theorem CIf_congruence : forall b b' c1 c1' c2 c2',
  bequiv b b' -> cequiv c1 c1' -> cequiv c2 c2' ->
  cequiv (IFB b THEN c1 ELSE c2 FI) (IFB b' THEN c1' ELSE c2' FI).
Proof.
  unfold cequiv.
  intros.
  split;intros.
Case "->".
  remember (IFB b THEN c1 ELSE c2 FI) as cif.
  induction H2;inversion Heqcif;subst.
  SCase "E_IfTrue".
     apply E_IfTrue. rewrite <-H2. symmetry. apply H.
     apply H0. assumption.
  SCase "E_IfFalse".
    apply E_IfFalse. rewrite <-H2. symmetry. apply H.
     apply H1. assumption.
Case "<-".
  remember (IFB b' THEN c1' ELSE c2' FI) as cif.
  induction H2;inversion Heqcif;subst.
  SCase "E_IfTrue".
     apply E_IfTrue. rewrite <-H2. apply H.
     apply H0. assumption.
  SCase "E_IfFalse".
    apply E_IfFalse. rewrite <-H2.  apply H.
     apply H1. assumption.
Qed.

(** For example, here are two equivalent programs and a proof of their
    equivalence... *)

Example congruence_example:
  cequiv
    (X ::= ANum 0;
     IFB (BEq (AId X) (ANum 0))
     THEN
       Y ::= ANum 0
     ELSE
       Y ::= ANum 42
     FI)
    (X ::= ANum 0;
     IFB (BEq (AId X) (ANum 0))
     THEN
       Y ::= AMinus (AId X) (AId X)   (* <--- changed here *)
     ELSE
       Y ::= ANum 42
     FI).
Proof.
  apply CSeq_congruence. 
    apply refl_cequiv. 
    apply CIf_congruence.
      apply refl_bequiv.
      apply CAss_congruence. unfold aequiv. simpl. 
        symmetry. apply minus_diag.
      apply refl_cequiv. 
Qed.

(* ####################################################### *)
(** * Case Study: Constant Folding *)

(** A _program transformation_ is a function that takes a program
    as input and produces some variant of the program as its
    output.  Compiler optimizations such as constant folding are
    a canonical example, but there are many others. *)

(* ####################################################### *)
(** ** Soundness of Program Transformations *)

(** A program transformation is _sound_ if it preserves the
    behavior of the original program.
 
    We can define a notion of soundness for translations of
    [aexp]s, [bexp]s, and [com]s. *)

Definition atrans_sound (atrans : aexp -> aexp) : Prop :=
  forall (a : aexp),
    aequiv a (atrans a).

Definition btrans_sound (btrans : bexp -> bexp) : Prop :=
  forall (b : bexp),
    bequiv b (btrans b).

Definition ctrans_sound (ctrans : com -> com) : Prop :=
  forall (c : com),
    cequiv c (ctrans c).

(* ######################################################## *)
(** ** The Constant-Folding Transformation *)

(** An expression is _constant_ when it contains no variable
    references.
 
    Constant folding is an optimization that finds constant
    expressions and replaces them by their values. *)

Fixpoint fold_constants_aexp (a : aexp) : aexp :=
  match a with
  | ANum n       => ANum n
  | AId i        => AId i
  | APlus a1 a2  => 
      match (fold_constants_aexp a1, fold_constants_aexp a2) with
      | (ANum n1, ANum n2) => ANum (n1 + n2)
      | (a1', a2') => APlus a1' a2'
      end
  | AMinus a1 a2 => 
      match (fold_constants_aexp a1, fold_constants_aexp a2) with
      | (ANum n1, ANum n2) => ANum (n1 - n2)
      | (a1', a2') => AMinus a1' a2'
      end
  | AMult a1 a2  => 
      match (fold_constants_aexp a1, fold_constants_aexp a2) with
      | (ANum n1, ANum n2) => ANum (n1 * n2)
      | (a1', a2') => AMult a1' a2'
      end
  end.

Example fold_aexp_ex1 :
    fold_constants_aexp 
      (AMult (APlus (ANum 1) (ANum 2)) (AId X)) 
  = AMult (ANum 3) (AId X).
Proof. reflexivity. Qed.

(** Note that this version of constant folding doesn't eliminate
    trivial additions, etc. -- we are focusing attention on a single
    optimization for the sake of simplicity.  It is not hard to
    incorporate other ways of simplifying expressions; the definitions
    and proofs just get longer. *)

Example fold_aexp_ex2 :
    fold_constants_aexp 
      (AMinus (AId X) (APlus (AMult (ANum 0) (ANum 6)) (AId Y)))
  = AMinus (AId X) (APlus (ANum 0) (AId Y)).
Proof. reflexivity. Qed.

(** Not only can we lift [fold_constants_aexp] to [bexp]s (in the
    [BEq] and [BLe] cases), we can also find constant _boolean_
    expressions and reduce them in-place. *)

Fixpoint fold_constants_bexp (b : bexp) : bexp :=
  match b with
  | BTrue        => BTrue
  | BFalse       => BFalse
  | BEq a1 a2  => 
      match (fold_constants_aexp a1, fold_constants_aexp a2) with
      | (ANum n1, ANum n2) => if beq_nat n1 n2 then BTrue else BFalse
      | (a1', a2') => BEq a1' a2'
      end
  | BLe a1 a2  => 
      match (fold_constants_aexp a1, fold_constants_aexp a2) with
      | (ANum n1, ANum n2) => if ble_nat n1 n2 then BTrue else BFalse
      | (a1', a2') => BLe a1' a2'
      end
  | BNot b1  => 
      match (fold_constants_bexp b1) with
      | BTrue => BFalse
      | BFalse => BTrue
      | b1' => BNot b1'
      end
  | BAnd b1 b2  => 
      match (fold_constants_bexp b1, fold_constants_bexp b2) with
      | (BTrue, BTrue) => BTrue
      | (BTrue, BFalse) => BFalse
      | (BFalse, BTrue) => BFalse
      | (BFalse, BFalse) => BFalse
      | (b1', b2') => BAnd b1' b2'
      end
  end.

Example fold_bexp_ex1 :
    fold_constants_bexp (BAnd BTrue (BNot (BAnd BFalse BTrue)))
  = BTrue.
Proof. reflexivity. Qed.

Example fold_bexp_ex2 :
    fold_constants_bexp 
      (BAnd (BEq (AId X) (AId Y)) 
            (BEq (ANum 0) 
                 (AMinus (ANum 2) (APlus (ANum 1) (ANum 1)))))
  = BAnd (BEq (AId X) (AId Y)) BTrue.
Proof. reflexivity. Qed.

(** To fold constants in a command, we apply the appropriate folding
    functions on all embedded expressions. *)

Fixpoint fold_constants_com (c : com) : com :=
  match c with
  | SKIP      => 
      SKIP
  | i ::= a  => 
      CAss i (fold_constants_aexp a)
  | c1 ; c2  => 
      (fold_constants_com c1) ; (fold_constants_com c2)
  | IFB b THEN c1 ELSE c2 FI => 
      match fold_constants_bexp b with
      | BTrue => fold_constants_com c1
      | BFalse => fold_constants_com c2
      | b' => IFB b' THEN fold_constants_com c1 
                     ELSE fold_constants_com c2 FI
      end
  | WHILE b DO c END => 
      match fold_constants_bexp b with
      | BTrue => WHILE BTrue DO SKIP END
      | BFalse => SKIP
      | b' => WHILE b' DO (fold_constants_com c) END
      end
  end.

Example fold_com_ex1 :
  fold_constants_com 
    (X ::= APlus (ANum 4) (ANum 5);
     Y ::= AMinus (AId X) (ANum 3);
     IFB BEq (AMinus (AId X) (AId Y)) (APlus (ANum 2) (ANum 4)) THEN
       SKIP 
     ELSE
       Y ::= ANum 0
     FI;
     IFB BLe (ANum 0) (AMinus (ANum 4) (APlus (ANum 2) (ANum 1))) THEN
       Y ::= ANum 0
     ELSE
       SKIP 
     FI;
     WHILE BEq (AId Y) (ANum 0) DO 
       X ::= APlus (AId X) (ANum 1) 
     END) =
  (X ::= ANum 9;
   Y ::= AMinus (AId X) (ANum 3);
   IFB BEq (AMinus (AId X) (AId Y)) (ANum 6) THEN
     SKIP 
   ELSE
     (Y ::= ANum 0) 
   FI;
   Y ::= ANum 0;
   WHILE BEq (AId Y) (ANum 0) DO 
     X ::= APlus (AId X) (ANum 1) 
   END).
Proof. reflexivity. Qed.

(* ################################################### *)
(** ** Soundness of Constant Folding *)

(** Now we need to show that what we've done is correct.  Here's
    the proof for arithmetic expressions: *)

Theorem fold_constants_aexp_sound : 
  atrans_sound fold_constants_aexp.
Proof.
  unfold atrans_sound. intros a. unfold aequiv. intros st.
  aexp_cases (induction a) Case; simpl;
    (* ANum and AId follow immediately *)
    try reflexivity;
    (* APlus, AMinus, and AMult follow from the IH
       and the observation that
              aeval st (APlus a1 a2) 
            = ANum ((aeval st a1) + (aeval st a2)) 
            = aeval st (ANum ((aeval st a1) + (aeval st a2)))
       (and similarly for AMinus/minus and AMult/mult) *)
    try (destruct (fold_constants_aexp a1);
         destruct (fold_constants_aexp a2);
         rewrite IHa1; rewrite IHa2; reflexivity). Qed.
                                                      
(** **** Exercise: 3 stars, optional (fold_bexp_BEq_informal) *)
(** Here is an informal proof of the [BEq] case of the soundness
    argument for boolean expression constant folding.  Read it
    carefully and compare it to the formal proof that follows.  Then
    fill in the [BLe] case of the formal proof (without looking at the
    [BEq] case, if possible).

   _Theorem_: The constant folding function for booleans,
   [fold_constants_bexp], is sound.

   _Proof_: We must show that [b] is equivalent to [fold_constants_bexp],
   for all boolean expressions [b].  Proceed by induction on [b].  We
   show just the case where [b] has the form [BEq a1 a2].

   In this case, we must show 
       beval st (BEq a1 a2) 
     = beval st (fold_constants_bexp (BEq a1 a2)).
   There are two cases to consider:

     - First, suppose [fold_constants_aexp a1 = ANum n1] and
       [fold_constants_aexp a2 = ANum n2] for some [n1] and [n2].

       In this case, we have
           fold_constants_bexp (BEq a1 a2) 
         = if beq_nat n1 n2 then BTrue else BFalse
       and
           beval st (BEq a1 a2) 
         = beq_nat (aeval st a1) (aeval st a2).
       By the soundness of constant folding for arithmetic
       expressions (Lemma [fold_constants_aexp_sound]), we know
           aeval st a1 
         = aeval st (fold_constants_aexp a1) 
         = aeval st (ANum n1) 
         = n1
       and
           aeval st a2 
         = aeval st (fold_constants_aexp a2) 
         = aeval st (ANum n2) 
         = n2,
       so
           beval st (BEq a1 a2) 
         = beq_nat (aeval a1) (aeval a2)
         = beq_nat n1 n2.
       Also, it is easy to see (by considering the cases [n1 = n2] and
       [n1 <> n2] separately) that
           beval st (if beq_nat n1 n2 then BTrue else BFalse)
         = if beq_nat n1 n2 then beval st BTrue else beval st BFalse
         = if beq_nat n1 n2 then true else false
         = beq_nat n1 n2.
       So
           beval st (BEq a1 a2) 
         = beq_nat n1 n2.
         = beval st (if beq_nat n1 n2 then BTrue else BFalse),
]]         
       as required.

     - Otherwise, one of [fold_constants_aexp a1] and
       [fold_constants_aexp a2] is not a constant.  In this case, we
       must show
           beval st (BEq a1 a2) 
         = beval st (BEq (fold_constants_aexp a1)
                         (fold_constants_aexp a2)),
       which, by the definition of [beval], is the same as showing
           beq_nat (aeval st a1) (aeval st a2) 
         = beq_nat (aeval st (fold_constants_aexp a1))
                   (aeval st (fold_constants_aexp a2)).
       But the soundness of constant folding for arithmetic
       expressions ([fold_constants_aexp_sound]) gives us
         aeval st a1 = aeval st (fold_constants_aexp a1)
         aeval st a2 = aeval st (fold_constants_aexp a2),
       completing the case.  []
*)

Theorem fold_constants_bexp_sound: 
  btrans_sound fold_constants_bexp.
Proof.
  unfold btrans_sound. intros b. unfold bequiv. intros st.
  bexp_cases (induction b) Case; 
    (* BTrue and BFalse are immediate *)
    try reflexivity. 
  Case "BEq". 
    (* Doing induction when there are a lot of constructors makes
       specifying variable names a chore, but Coq doesn't always
       choose nice variable names.  We can rename entries in the
       context with the [rename] tactic: [rename a into a1] will
       change [a] to [a1] in the current goal and context. *)
    rename a into a1. rename a0 into a2. simpl.
    remember (fold_constants_aexp a1) as a1'. 
    remember (fold_constants_aexp a2) as a2'.
    replace (aeval st a1) with (aeval st a1') by
       (subst a1'; rewrite <- fold_constants_aexp_sound; reflexivity).
    replace (aeval st a2) with (aeval st a2') by
       (subst a2'; rewrite <- fold_constants_aexp_sound; reflexivity).
    destruct a1'; destruct a2'; try reflexivity.
      (* The only interesting case is when both a1 and a2 
         become constants after folding *)
      simpl. destruct (beq_nat n n0); reflexivity.
  Case "BLe". 
     rename a into a1. rename a0 into a2. simpl.
    remember (fold_constants_aexp a1) as a1'. 
    remember (fold_constants_aexp a2) as a2'.
     
    replace (aeval st a1) with (aeval st a1') by
       (subst a1'; rewrite <- fold_constants_aexp_sound; reflexivity).
    replace (aeval st a2) with (aeval st a2') by
       (subst a2'; rewrite <- fold_constants_aexp_sound; reflexivity).
    destruct a1'; destruct a2'; try reflexivity.
simpl. destruct (ble_nat n n0); reflexivity.
  Case "BNot". 
    simpl. remember (fold_constants_bexp b) as b'. 
    rewrite IHb.
    destruct b'; reflexivity. 
  Case "BAnd". 
    simpl. 
    remember (fold_constants_bexp b1) as b1'. 
    remember (fold_constants_bexp b2) as b2'.
    rewrite IHb1. rewrite IHb2.
    destruct b1'; destruct b2'; reflexivity.  Qed.


(** **** Exercise: 3 stars (fold_constants_com_sound) *)
(** Complete the [WHILE] case of the following proof. *)

Theorem fold_constants_com_sound : 
  ctrans_sound fold_constants_com.
Proof. 
  unfold ctrans_sound. intros c. 
  com_cases (induction c) Case; simpl.
  Case "SKIP". apply refl_cequiv.
  Case "::=". apply CAss_congruence. apply fold_constants_aexp_sound.
  Case ";". apply CSeq_congruence; assumption.
  Case "IFB". 
    assert (bequiv b (fold_constants_bexp b)).
      SCase "Pf of assertion". apply fold_constants_bexp_sound.
    remember (fold_constants_bexp b) as b'.
    destruct b';
      (* If the optimization doesn't eliminate the if, then the result
         is easy to prove from the IH and fold_constants_bexp_sound *)
      try (apply CIf_congruence; assumption).
    SCase "b always true".
      apply trans_cequiv with c1; try assumption.
      apply IFB_true; assumption.
    SCase "b always false".
      apply trans_cequiv with c2; try assumption.
      apply IFB_false; assumption.
  Case "WHILE".
 assert (bequiv b (fold_constants_bexp b)).
      SCase "Pf of assertion". apply fold_constants_bexp_sound.
      remember (fold_constants_bexp b) as b'.
      destruct b';try (apply CWhile_congruence; assumption).
     SCase "b always true".
      apply WHILE_true. 
      assumption.
      apply WHILE_false. assumption.
Qed.

(* ########################################################## *)
(** *** Soundness of (0 + n) Elimination, Redux *)

(** **** Exercise: 4 stars, optional (optimize_0plus) *)
(** Recall the definition [optimize_0plus] from Imp.v:
    Fixpoint optimize_0plus (e:aexp) : aexp := 
      match e with
      | ANum n => 
          ANum n
      | APlus (ANum 0) e2 => 
          optimize_0plus e2
      | APlus e1 e2 => 
          APlus (optimize_0plus e1) (optimize_0plus e2)
      | AMinus e1 e2 => 
          AMinus (optimize_0plus e1) (optimize_0plus e2)
      | AMult e1 e2 => 
          AMult (optimize_0plus e1) (optimize_0plus e2)
      end.
   Note that this function is defined over the old [aexp]s,
   without states.

   Write a new version of this function that accounts for variables,
   and analogous ones for [bexp]s and commands:
     optimize_0plus_aexp
     optimize_0plus_bexp
     optimize_0plus_com
   Prove that these three functions are sound, as we did for
   [fold_constants_*].  Make sure you use the congruence lemmas in
   the proof of [optimize_0plus_com] (otherwise it will be _long_!).

   Then define an optimizer on commands that first folds
   constants (using [fold_constants_com]) and then eliminates [0 + n]
   terms (using [optimize_0plus_com]).

   - Give a meaningful example of this optimizer's output.

   - Prove that the optimizer is sound.  (This part should be _very_
     easy.)  *)

Fixpoint optimize_0plus_aexp (e:aexp) : aexp := 
  match e with
    | ANum n => 
      ANum n
    | AId X => AId X
    | APlus (ANum 0) e2 => 
      optimize_0plus_aexp e2
    | APlus e1 e2 => 
      APlus (optimize_0plus_aexp e1) (optimize_0plus_aexp e2)
    | AMinus e1 e2 => 
      AMinus (optimize_0plus_aexp e1) (optimize_0plus_aexp e2)
    | AMult e1 e2 => 
      AMult (optimize_0plus_aexp e1) (optimize_0plus_aexp e2)
  end.

Fixpoint optimize_0plus_bexp (e:bexp) : bexp :=
  match e with
    | BTrue => BTrue
    | BFalse => BFalse
    | BEq a1 a2 => BEq (optimize_0plus_aexp a1) (optimize_0plus_aexp a2)
    | BLe a1 a2 => BLe (optimize_0plus_aexp a1) (optimize_0plus_aexp a2)
    | BNot b1 => BNot (optimize_0plus_bexp b1)
    | BAnd b1 b2 => BAnd (optimize_0plus_bexp b1) (optimize_0plus_bexp b2)
  end.

Fixpoint optimize_0plus_com (c : com) : com :=
  match c with
    | SKIP => SKIP
    | i ::= a => i ::= (optimize_0plus_aexp a)
    | c1 ; c2 => (optimize_0plus_com c1); (optimize_0plus_com c2)
    | IFB b THEN c1 ELSE c2 FI =>
      IFB (optimize_0plus_bexp b)
      THEN (optimize_0plus_com c1)
      ELSE (optimize_0plus_com c2)
      FI
    | WHILE b DO c END => WHILE (optimize_0plus_bexp b) DO (optimize_0plus_com c) END
    
  end.

Theorem optimize_0plus_aexp_sound : atrans_sound optimize_0plus_aexp.
Proof.
  intro; unfold aequiv; intros.
  aexp_cases (induction a) Case; simpl; auto.
  destruct a1; try destruct n; simpl; auto.
Qed.

Theorem optimize_0plus_bexp_sound: 
  btrans_sound optimize_0plus_bexp.
Proof.
  intro; unfold bequiv; intros.
  bexp_cases (induction b) Case; auto.
  simpl.
  remember (optimize_0plus_aexp a); remember (optimize_0plus_aexp a0).
  replace (aeval st a) with (aeval st a1).
  replace (aeval st a0) with (aeval st a2).
  auto.
  rewrite Heqa2.
  symmetry.
  apply optimize_0plus_aexp_sound.
  rewrite Heqa1.
  symmetry.
  apply optimize_0plus_aexp_sound.

  simpl.
  remember (optimize_0plus_aexp a); remember (optimize_0plus_aexp a0).
  replace (aeval st a) with (aeval st a1).
  replace (aeval st a0) with (aeval st a2).
  auto.
  rewrite Heqa2.
  symmetry.
  apply optimize_0plus_aexp_sound.
  rewrite Heqa1.
  symmetry.
  apply optimize_0plus_aexp_sound.

  simpl.
  remember (optimize_0plus_bexp b).
  replace (beval st b) with (beval st b0).
  auto.

  simpl.
  remember (optimize_0plus_bexp b1); remember (optimize_0plus_bexp b2).
  replace (beval st b1) with (beval st b).
  replace (beval st b2) with (beval st b0).
  auto.
Qed.

Theorem optimize_0plus_com_sound : 
  ctrans_sound optimize_0plus_com.
Proof.
  unfold ctrans_sound. intros c.
  com_cases (induction c) Case; simpl.
  apply refl_cequiv.
  apply CAss_congruence.
  apply optimize_0plus_aexp_sound.
  apply CSeq_congruence; auto.
  assert (bequiv b (optimize_0plus_bexp b)).
  apply optimize_0plus_bexp_sound.
  remember (optimize_0plus_bexp b) as b'.
  destruct b';
    try (apply CIf_congruence; auto).
  
  assert (bequiv b (optimize_0plus_bexp b)).
  apply optimize_0plus_bexp_sound.
  remember (optimize_0plus_bexp b) as b'.
  apply CWhile_congruence; auto.
Qed.

Definition optimizer (c : com) : com :=
  optimize_0plus_com (fold_constants_com c).

Theorem optimizer_sound : ctrans_sound optimizer.
Proof.
  unfold ctrans_sound, optimizer; intros.
  apply trans_cequiv with (fold_constants_com c).
  apply fold_constants_com_sound.
  apply optimize_0plus_com_sound.
Qed.

(* ####################################################### *)
(** * Proving That Programs Are _Not_ Equivalent *)

(** Suppose that [c1] is a command of the form [X ::= a1; Y ::= a2]
    and [c2] is the command [X ::= a1; Y ::= a2'], where [a2'] is
    formed by substituting [a1] for all occurrences of [X] in [a2].
    For example, [c1] and [c2] might be:
       c1  =  (X ::= 42 + 53; 
               Y ::= Y + X)
       c2  =  (X ::= 42 + 53; 
               Y ::= Y + (42 + 53))
    Clearly, this _particular_ [c1] and [c2] are equivalent.  Is this
    true in general? *)

(** We will see in a moment that it is not, but it is worthwhile
    to pause, now, and see if you can find a counter-example on your
    own. *)

(** Here, formally, is the function that substitutes an arithmetic
    expression for each occurrence of a given variable in another
    expression: *)

Fixpoint subst_aexp (i : id) (u : aexp) (a : aexp) : aexp :=
  match a with
  | ANum n       => ANum n
  | AId i'       => if beq_id i i' then u else AId i'
  | APlus a1 a2  => APlus (subst_aexp i u a1) (subst_aexp i u a2)
  | AMinus a1 a2 => AMinus (subst_aexp i u a1) (subst_aexp i u a2)
  | AMult a1 a2  => AMult (subst_aexp i u a1) (subst_aexp i u a2)
  end.

Example subst_aexp_ex :
  subst_aexp X (APlus (ANum 42) (ANum 53)) (APlus (AId Y) (AId X)) =
  (APlus (AId Y) (APlus (ANum 42) (ANum 53))).
Proof. reflexivity.  Qed.

(** And here is the property we are interested in, expressing the
    claim that commands [c1] and [c2] as described above are
    always equivalent.  *)

Definition subst_equiv_property := forall i1 i2 a1 a2,
  cequiv (i1 ::= a1; i2 ::= a2)
         (i1 ::= a1; i2 ::= subst_aexp i1 a1 a2).

(** Sadly, the property does _not_ always hold. 

    _Theorem_: It is not the case that, for all [i1], [i2], [a1],
    and [a2],
         cequiv (i1 ::= a1; i2 ::= a2)
                (i1 ::= a1; i2 ::= subst_aexp i1 a1 a2).
]] 
    _Proof_: Suppose, for a contradiction, that for all [i1], [i2],
    [a1], and [a2], we have
      cequiv (i1 ::= a1; i2 ::= a2) 
             (i1 ::= a1; i2 ::= subst_aexp i1 a1 a2).
    Consider the following program:
         X ::= APlus (AId X) (ANum 1); Y ::= AId X
    Note that
         (X ::= APlus (AId X) (ANum 1); Y ::= AId X)
         / empty_state || st1,
    where [st1 = { X |-> 1, Y |-> 1 }].

    By our assumption, we know that
        cequiv (X ::= APlus (AId X) (ANum 1); Y ::= AId X)
               (X ::= APlus (AId X) (ANum 1); Y ::= APlus (AId X) (ANum 1))
    so, by the definition of [cequiv], we have
        (X ::= APlus (AId X) (ANum 1); Y ::= APlus (AId X) (ANum 1))
        / empty_state || st1.
    But we can also derive
        (X ::= APlus (AId X) (ANum 1); Y ::= APlus (AId X) (ANum 1))
        / empty_state || st2,
    where [st2 = { X |-> 1, Y |-> 2 }].  Note that [st1 <> st2]; this
    is a contradiction, since [ceval] is deterministic!  [] *)

Theorem subst_inequiv : 
  ~ subst_equiv_property.
Proof.
  unfold subst_equiv_property.
  intros Contra.

  (* Here is the counterexample: assuming that [subst_equiv_property]
     holds allows us to prove that these two programs are
     equivalent... *)
  remember (X ::= APlus (AId X) (ANum 1); 
            Y ::= AId X) 
      as c1.
  remember (X ::= APlus (AId X) (ANum 1); 
            Y ::= APlus (AId X) (ANum 1)) 
      as c2.
  assert (cequiv c1 c2) by (subst; apply Contra).

  (* ... allows us to show that the command [c2] can terminate 
     in two different final states: 
        st1 = {X |-> 1, Y |-> 1} 
        st2 = {X |-> 1, Y |-> 2}. *)
  remember (update (update empty_state X 1) Y 1) as st1.
  remember (update (update empty_state X 1) Y 2) as st2.
  assert (H1: c1 / empty_state || st1);
  assert (H2: c2 / empty_state || st2);
  try (subst;
       apply E_Seq with (st' := (update empty_state X 1)); 
       apply E_Ass; reflexivity).
  apply H in H1.

  (* Finally, we use the fact that evaluation is deterministic
     to obtain a contradiction. *)
  assert (Hcontra: st1 = st2)
    by (apply (ceval_deterministic c2 empty_state); assumption).
  assert (Hcontra': st1 Y = st2 Y)
    by (rewrite Hcontra; reflexivity).
  subst. inversion Hcontra'.  Qed.

(** **** Exercise: 4 stars, optional (better_subst_equiv) *)
(** The equivalence we had in mind above was not complete nonsense --
    it was actually almost right.  To make it correct, we just need to
    exclude the case where the variable [X] occurs in the
    right-hand-side of the first assignment statement. 

*)

Inductive var_not_used_in_aexp (X:id) : aexp -> Prop :=
  | VNUNum: forall n, var_not_used_in_aexp X (ANum n)
  | VNUId: forall Y, X <> Y -> var_not_used_in_aexp X (AId Y)
  | VNUPlus: forall a1 a2, 
      var_not_used_in_aexp X a1 ->
      var_not_used_in_aexp X a2 ->
      var_not_used_in_aexp X (APlus a1 a2)
  | VNUMinus: forall a1 a2, 
      var_not_used_in_aexp X a1 ->
      var_not_used_in_aexp X a2 ->
      var_not_used_in_aexp X (AMinus a1 a2)
  | VNUMult: forall a1 a2, 
      var_not_used_in_aexp X a1 ->
      var_not_used_in_aexp X a2 ->
      var_not_used_in_aexp X (AMult a1 a2).

Lemma aeval_weakening : forall i st a ni,
  var_not_used_in_aexp i a ->
  aeval (update st i ni) a = aeval st a.
Proof.
 intros.
 induction H;simpl.

Case "ANum".
  reflexivity.
Case "AId".
  apply update_neq. apply not_eq_beq_id_false. assumption.
Case "APlus". rewrite IHvar_not_used_in_aexp1. 
              rewrite IHvar_not_used_in_aexp2. reflexivity.
Case "AMinus". rewrite IHvar_not_used_in_aexp1. 
              rewrite IHvar_not_used_in_aexp2. reflexivity.
Case "AMult".  rewrite IHvar_not_used_in_aexp1. 
              rewrite IHvar_not_used_in_aexp2. reflexivity.
Qed.

(** Using [var_not_used_in_aexp], formalize and prove a correct verson
    of [subst_equiv_property]. *)
Definition subst_equiv_property_correct := forall i1 i2 a1 a2,
  var_not_used_in_aexp i1 a1 ->
  cequiv (i1 ::= a1; i2 ::= a2)
  (i1 ::= a1; i2 ::= subst_aexp i1 a1 a2).

Theorem subst_equiv : subst_equiv_property_correct.
Proof.
  unfold subst_equiv_property_correct, cequiv.
  intros; split; intros; inversion H0; subst; 
   clear H0; inversion H3; subst; clear H3; inversion H6; subst; clear H6.
  apply E_Seq with (update st i1 (aeval st a1)).
  apply E_Ass; auto.
  apply E_Ass.
  induction a2; simpl; auto.
  remember (beq_id i1 i).
  destruct b; simpl; auto.
  apply beq_id_eq in Heqb; subst.
  rewrite update_eq.
  apply aeval_weakening; auto.

  apply E_Seq with (update st i1 (aeval st a1)).
  apply E_Ass; auto.
  apply E_Ass.
  induction a2; simpl; auto.
  remember (beq_id i1 i).
  destruct b; simpl; auto.
  apply beq_id_eq in Heqb; subst.
  rewrite update_eq.
  symmetry.
  apply aeval_weakening; auto.
Qed.

(** **** Exercise: 3 stars, recommended (inequiv_exercise) *)
Theorem inequiv_exercise: 
  ~ cequiv (WHILE BTrue DO SKIP END) SKIP.
Proof.
  unfold not. intros.
  unfold cequiv in H.
  assert (SKIP/empty_state||empty_state).
  constructor.
  apply H with (st:=empty_state)(st':=empty_state) in H0.
  apply loop_never_stops with (st:=empty_state)(st':=empty_state) in H0.
  assumption.
Qed.

(** * Extended exercise: Non-deterministic Imp *)

(** As we have seen (in theorem [ceval_deterministic] in the Imp
    chapter), Imp's evaluation relation is deterministic.  However,
    _non_-determinism is an important part of the definition of many
    real programming languages. For example, in many imperative
    languages (such as C and its relatives), the order in which
    function arguments are evaluated is unspecified.  The program
    fragment
      x = 0;
      f(++x, x);
    might call [f] with arguments [(1, 0)] or [(1, 1)], depending how
    the compiler chooses to order things.  This can be a little
    confusing for programmers, but it gives the compiler writer useful
    freedom.

    In this exercise, we will extend Imp with a simple
    non-deterministic command and study how this change affects
    program equivalence.  The new command has the syntax [HAVOC X],
    where [X] is an identifier. The effect of executing [HAVOC X] is
    to assign an _arbitrary_ number to the variable [X],
    non-deterministically. For example, after executing the program:
      HAVOC Y;
      Z ::= Y * 2
    the value of [Y] can be any number, while the value of [Z] is
    twice that of [Y] (so [Z] is always even). Note that we are not
    saying anything about the /probabilities/ of the outcomes -- just
    that there are (infinitely) many different outcomes that can
    possibly happen after executing this non-deterministic code.

    In a sense a variable on which we do [HAVOC] roughly corresponds
    to an unitialized variable in the C programming language. After
    the [HAVOC] the variable holds a fixed but arbitrary number.  Most
    sources of nondeterminism in language definitions are there
    precisely because programmers don't care which choice is made (and
    so it is good to leave it open to the compiler to choose whichever
    will run faster).

    We call this new language _Himp_ (``Imp extended with [HAVOC]''). *)

Module Himp.

(** To formalize the language, we first add a clause to the definition of
   commands. *)

Inductive com : Type :=
  | CSkip : com
  | CAss : id -> aexp -> com
  | CSeq : com -> com -> com
  | CIf : bexp -> com -> com -> com
  | CWhile : bexp -> com -> com
  | CHavoc : id -> com.                (* <---- new *)

Tactic Notation "com_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "SKIP" | Case_aux c "::=" | Case_aux c ";"
  | Case_aux c "IFB" | Case_aux c "WHILE" | Case_aux c "HAVOC" ].

Notation "'SKIP'" :=
  CSkip.
Notation "X '::=' a" :=
  (CAss X a) (at level 60).
Notation "c1 ; c2" :=
  (CSeq c1 c2) (at level 80, right associativity).
Notation "'WHILE' b 'DO' c 'END'" :=
  (CWhile b c) (at level 80, right associativity).
Notation "'IFB' e1 'THEN' e2 'ELSE' e3 'FI'" :=
  (CIf e1 e2 e3) (at level 80, right associativity).
Notation "'HAVOC' l" := (CHavoc l) (at level 60).

(** **** Exercise: 2 stars (himp_ceval) *)
(** Now, we must extend the operational semantics. We have provided
   a template for the [ceval] relation below, specifying the big-step
   semantics. What rule(s) must be added to the definition of [ceval]
   to formalize the behavior of the [HAVOC] command? *)

Reserved Notation "c1 '/' st '||' st'" (at level 40, st at level 39).

Inductive ceval : com -> state -> state -> Prop :=
  | E_Skip : forall st : state, SKIP / st || st
  | E_Ass : forall (st : state) (a1 : aexp) (n : nat) (X : id),
            aeval st a1 = n -> (X ::= a1) / st || update st X n
  | E_Seq : forall (c1 c2 : com) (st st' st'' : state),
            c1 / st || st' -> c2 / st' || st'' -> (c1 ; c2) / st || st''
  | E_IfTrue : forall (st st' : state) (b1 : bexp) (c1 c2 : com),
               beval st b1 = true ->
               c1 / st || st' -> (IFB b1 THEN c1 ELSE c2 FI) / st || st'
  | E_IfFalse : forall (st st' : state) (b1 : bexp) (c1 c2 : com),
                beval st b1 = false ->
                c2 / st || st' -> (IFB b1 THEN c1 ELSE c2 FI) / st || st'
  | E_WhileEnd : forall (b1 : bexp) (st : state) (c1 : com),
                 beval st b1 = false -> (WHILE b1 DO c1 END) / st || st
  | E_WhileLoop : forall (st st' st'' : state) (b1 : bexp) (c1 : com),
                  beval st b1 = true ->
                  c1 / st || st' ->
                  (WHILE b1 DO c1 END) / st' || st'' ->
                  (WHILE b1 DO c1 END) / st || st''
(* FILL IN HERE *)

  where "c1 '/' st '||' st'" := (ceval c1 st st').

Tactic Notation "ceval_cases" tactic(first) ident(c) :=
  first;
  [ Case_aux c "E_Skip" | Case_aux c "E_Ass" | Case_aux c "E_Seq"
  | Case_aux c "E_IfTrue" | Case_aux c "E_IfFalse"
  | Case_aux c "E_WhileEnd" | Case_aux c "E_WhileLoop"
(* FILL IN HERE *)
].

(** As a sanity check, the following claims should be provable for
   your definition: *)

Example havoc_example1 : (HAVOC X) / empty_state || update empty_state X 0.
Proof.
(* FILL IN HERE *) Admitted.

Example havoc_example2 :
  (SKIP; HAVOC Z) / empty_state || update empty_state Z 42.
Proof.
(* FILL IN HERE *) Admitted.
(** [] *)

(** Finally, we repeat the definition of command equivalence from above: *)

Definition cequiv (c1 c2 : com) : Prop := forall st st' : state,
  c1 / st || st' <-> c2 / st || st'.

(** This definition still makes perfect sense in the case of always
    terminating programs, so let's apply it to prove some
    non-deterministic programs equivalent or non-equivalent. *)

(** **** Exercise: 3 stars (havoc_swap) *)
(** Are the following two programs equivalent? *)

Definition pXY :=
  HAVOC X; HAVOC Y.

Definition pYX :=
  HAVOC Y; HAVOC X.

(** If you think they are equivalent, prove it. If you think they are
    not, prove that. *)

Theorem pXY_cequiv_pYX :
  cequiv pXY pYX \/ ~cequiv pXY pYX.
Proof. (* FILL IN HERE *) Admitted.

(** **** Exercise: 4 stars (havoc_copy) *)
(** Are the following two programs equivalent? *)

Definition ptwice :=
  HAVOC X; HAVOC Y.

Definition pcopy :=
  HAVOC X; Y ::= AId X.

(** If you think they are equivalent, then prove it. If you think they
    are not, then prove that.  (Hint: You may find the [assert] tactic
    useful.) *)

Theorem ptwice_cequiv_pcopy :
  cequiv ptwice pcopy \/ ~cequiv ptwice pcopy.
Proof. (* FILL IN HERE *) Admitted.
(** [] *)

(** The definition of program equivalence we are using here has some
    subtle consequences on programs that may loop forever.  What
    [cequiv] says is that the set of possible _terminating_ outcomes
    of two equivalent programs is the same. However, in a language
    with non-determinism, like Himp, some programs always terminate,
    some programs always diverge, and some programs can
    non-deterministically terminate in some runs and diverge in
    others. The final part of the following optional exercise
    illustrates this phenomenon.
*)

(** **** Exercise: 5 stars, optional (havoc_diverge) *)
(** Prove the following program equivalences and non-equivalences, and
    try to understand why the [cequiv] definition has the behavior it
    has on these examples. *)

Definition p1 : com :=
  WHILE (BNot (BEq (AId X) (ANum 0))) DO
    HAVOC Y;
    X ::= APlus (AId X) (ANum 1)
  END.

Definition p2 : com :=
  WHILE (BNot (BEq (AId X) (ANum 0))) DO
    SKIP
  END.


Theorem p1_p2_equiv : cequiv p1 p2.
Proof. (* FILL IN HERE *) Admitted.

Definition p3 : com :=
  Z ::= ANum 1;
  WHILE (BNot (BEq (AId X) (ANum 0))) DO
    HAVOC X;
    HAVOC Z
  END.

Definition p4 : com :=
  X ::= (ANum 0);
  Z ::= (ANum 1).


Theorem p3_p4_inequiv : ~ cequiv p3 p4.
Proof. (* FILL IN HERE *) Admitted.

Definition p5 : com :=
  WHILE (BNot (BEq (AId X) (ANum 1))) DO
    HAVOC X
  END.

Definition p6 : com :=
  X ::= ANum 1.


Theorem p5_p6_equiv : cequiv p5 p6.
Proof. (* FILL IN HERE *) Admitted.
(** [] *)

End Himp.

(* ####################################################### *)
(** * Doing Without Extensionality (Optional) *)

(** Purists might object to using the [functional_extensionality]
    axiom.  In general, it can be quite dangerous to add axioms,
    particularly several at once (as they may be mutually
    inconsistent). In fact, [functional_extensionality] and
    [excluded_middle] can both be assumed without any problems, but
    some Coq users prefer to avoid such "heavyweight" general
    techniques, and instead craft solutions for specific problems that
    stay within Coq's standard logic.

    For our particular problem here, rather than extending the
    definition of equality to do what we want on functions
    representing states, we could instead give an explicit notion of
    _equivalence_ on states.  For example: *)

Definition stequiv (st1 st2 : state) : Prop :=
  forall (X:id), st1 X = st2 X. 

Notation "st1 '~' st2" := (stequiv st1 st2) (at level 30).

(** It is easy to prove that [stequiv] is an _equivalence_ (i.e., it
   is reflexive, symmetric, and transitive), so it partitions the set
   of all states into equivalence classes. *)

(** **** Exercise: 1 star, optional (stequiv_refl) *)
Lemma stequiv_refl : forall (st : state), 
  st ~ st.
Proof.
 unfold stequiv.
  intros.
  auto.
Qed.

(** **** Exercise: 1 star, optional (stequiv_sym) *)
Lemma stequiv_sym : forall (st1 st2 : state), 
  st1 ~ st2 <-> 
  st2 ~ st1.
Proof. 
  unfold stequiv.
  intros;  split; intros; symmetry; apply H.
Qed.
   
(** **** Exercise: 1 star, optional (stequiv_trans) *)
Lemma stequiv_trans : forall (st1 st2 st3 : state), 
  st1 ~ st2 -> 
  st2 ~ st3 -> 
  st1 ~ st3.
Proof.  
unfold stequiv.
  intros.
  assert (st1 X = st2 X); auto.
  rewrite H1; auto.
Qed.

(** Another useful fact... *)
(** **** Exercise: 1 star, optional (stequiv_update) *)
Lemma stequiv_update : forall (st1 st2 : state),
  st1 ~ st2 -> 
  forall (X:id) (n:nat),
  update st1 X n ~ update st2 X n. 
Proof.
   unfold stequiv.
  intros.
  remember (beq_id X X0).
  destruct b; simpl.
  apply beq_id_eq in Heqb; subst.
  rewrite update_eq; rewrite update_eq; auto.
  symmetry in Heqb.
  rewrite update_neq; auto.
  rewrite update_neq; auto.
Qed.

(** It is then straightforward to show that [aeval] and [beval] behave
    uniformly on all members of an equivalence class: *)

(** **** Exercise: 2 stars, optional (stequiv_aeval) *)
Lemma stequiv_aeval : forall (st1 st2 : state), 
  st1 ~ st2 ->
  forall (a:aexp), aeval st1 a = aeval st2 a. 
Proof.
  intros.
  aexp_cases (induction a) Case; simpl; auto.
Qed.

(** **** Exercise: 2 stars, optional (stequiv_beval) *)
Lemma stequiv_beval : forall (st1 st2 : state), 
  st1 ~ st2 ->
  forall (b:bexp), beval st1 b = beval st2 b. 
Proof.
  intros.
  bexp_cases (induction b) Case; simpl; auto.
  rewrite (stequiv_aeval st1 st2); auto.
  rewrite (stequiv_aeval st1 st2); auto.
  rewrite (stequiv_aeval st1 st2); auto.
  rewrite (stequiv_aeval st1 st2); auto.
  rewrite IHb; auto.
  rewrite IHb1; rewrite IHb2; auto.
Qed.

(** We can also characterize the behavior of [ceval] on equivalent
    states (this result is a bit more complicated to write down
    because [ceval] is a relation). *)

Lemma stequiv_ceval: forall (st1 st2 : state),
  st1 ~ st2 ->
  forall (c: com) (st1': state),
    (c / st1 || st1') ->
    exists st2' : state,
    ((c / st2 || st2') /\  st1' ~ st2').
Proof.
  intros st1 st2 STEQV c st1' CEV1. generalize dependent st2. 
  induction CEV1; intros st2 STEQV.  
  Case "SKIP".
    exists st2. split.  
      constructor. 
      assumption.
  Case ":=".
    exists (update st2 X n). split. 
       constructor.  rewrite <- H. symmetry.  apply stequiv_aeval. 
       assumption. apply stequiv_update.  assumption.
  Case ";".
    destruct (IHCEV1_1 st2 STEQV) as [st2' [P1 EQV1]].
    destruct (IHCEV1_2 st2' EQV1) as [st2'' [P2 EQV2]]. 
    exists st2''.  split.
      apply E_Seq with st2';  assumption. 
      assumption.
  Case "IfTrue".
    destruct (IHCEV1 st2 STEQV) as [st2' [P EQV]].
    exists st2'.  split. 
      apply E_IfTrue.  rewrite <- H. symmetry. apply stequiv_beval. 
      assumption. assumption. assumption.
  Case "IfFalse".
    destruct (IHCEV1 st2 STEQV) as [st2' [P EQV]].
    exists st2'. split. 
     apply E_IfFalse. rewrite <- H. symmetry. apply stequiv_beval. 
     assumption.  assumption. assumption.
  Case "WhileEnd".
    exists st2. split.
      apply E_WhileEnd. rewrite <- H. symmetry. apply stequiv_beval. 
      assumption. assumption. 
  Case "WhileLoop".
    destruct (IHCEV1_1 st2 STEQV) as [st2' [P1 EQV1]].
    destruct (IHCEV1_2 st2' EQV1) as [st2'' [P2 EQV2]].
    exists st2''. split. 
      apply E_WhileLoop with st2'.  rewrite <- H. symmetry. 
      apply stequiv_beval. assumption. assumption. assumption.
      assumption.
Qed.

(** Now we need to redefine [cequiv] to use [~] instead of [=].  It is
    not completely trivial to do this in a way that keeps the
    definition simple and symmetric, but here is one approach (thanks
    to Andrew McCreight). We first define a looser variant of [||]
    that "folds in" the notion of equivalence. *)
    
Reserved Notation "c1 '/' st '||'' st'" (at level 40, st at level 39).

Inductive ceval' : com -> state -> state -> Prop :=
  | E_equiv : forall c st st' st'',
    c / st || st' -> 
    st' ~ st'' ->
    c / st ||' st''
  where   "c1 '/' st '||'' st'" := (ceval' c1 st st').

(** Now the revised definition of [cequiv'] looks familiar: *)

Definition cequiv' (c1 c2 : com) : Prop :=
  forall (st st' : state),
    (c1 / st ||' st') <-> (c2 / st ||' st').

(** A sanity check shows that the original notion of command
   equivalence is at least as strong as this new one.  (The converse
   is not true, naturally.) *)

Lemma cequiv__cequiv' : forall (c1 c2: com),
  cequiv c1 c2 -> cequiv' c1 c2.
Proof. 
  unfold cequiv, cequiv'; split; intros. 
    inversion H0 ; subst.  apply E_equiv with st'0.  
    apply (H st st'0); assumption. assumption. 
    inversion H0 ; subst.  apply E_equiv with st'0.  
    apply (H st st'0). assumption. assumption.
Qed.

(** **** Exercise: 2 stars, optional (identity_assignment') *)
(** Finally, here is our example once more... (You can complete the
    proof.) *)

Example identity_assignment' :
  cequiv' SKIP (X ::= AId X).
Proof.
    unfold cequiv'.  intros.  split; intros. 
    Case "->".
      inversion H; subst; clear H. inversion H0; subst.   
      apply E_equiv with (update st'0 X (st'0 X)). 
      constructor. reflexivity.  apply stequiv_trans with st'0.  
      unfold stequiv. intros. apply update_same. 
      reflexivity. assumption. 
    Case "<-".  
       inversion H; subst; clear H.
  inversion H0; subst; clear H0.
  apply E_equiv with st.
  constructor; auto.
  unfold stequiv in H1.
  unfold stequiv; intros.
  rewrite <- (H1 X).
  remember (beq_id Imp.X X).
  destruct b.
  apply beq_id_eq in Heqb; subst.
  rewrite update_eq.
  auto.
  rewrite update_neq; auto.
Qed.

(** On the whole, this explicit equivalence approach is considerably
    harder to work with than relying on functional
    extensionality. (Coq does have an advanced mechanism called
    "setoids" that makes working with equivalences somewhat easier, by
    allowing them to be registered with the system so that standard
    rewriting tactics work for them almost as well as for equalities.)
    But it is worth knowing about, because it applies even in
    situations where the equivalence in question is _not_ over
    functions.  For example, if we chose to represent state mappings
    as binary search trees, we would need to use an explicit
    equivalence of this kind. *)

(* ####################################################### *)
(** * Additional Exercises *)

(** **** Exercise: 4 stars, optional (for_while_equiv) *)
(** This exercise extends the optional [add_for_loop] exercise from
    Imp.v, where you were asked to extend the language of commands
    with C-style [for] loops.  Prove that the command:
      for (c1 ; b ; c2) {
          c3
      }
    is equivalent to:
       c1 ; 
       WHILE b DO
         c3 ;
         c2
       END
*)

Module Add_For_Loop.

Inductive com : Type :=
  | CSkip : com
  | CAss : id -> aexp -> com
  | CSeq : com -> com -> com
  | CIf : bexp -> com -> com -> com
  | CWhile : bexp -> com -> com
  | CFor : com -> bexp -> com -> com ->com.

Inductive ceval : state -> com -> state -> Prop :=
  | CESkip : forall st,
      ceval st CSkip st
  | CEAss  : forall st a1 n l,
      aeval st a1 = n ->
      (CAss l a1) / st || (update st l n)
  | CESeq : forall c1 c2 st st' st'',
      c1 / st  || st' ->
      c2 / st' || st'' ->
      (CSeq c1 c2) / st || st''
  | CEIfTrue : forall st st' b1 c1 c2,
      beval st b1 = true ->
      c1 / st || st' ->
      (CIf b1 c1 c2) / st ||  st'
  | CEIfFalse : forall st st' b1 c1 c2,
      beval st b1 = false ->
      c2 / st || st' ->
      (CIf b1 c1 c2) / st || st'
  | CEWhileEnd : forall b1 st c1,
      beval st b1 = false ->
      (CWhile b1 c1) / st || st
  | CEWhileLoop : forall st st' st'' b1 c1,
      beval st b1 = true ->
      c1 / st || st' ->
      (CWhile b1 c1) / st' || st'' ->
      (CWhile b1 c1) / st || st''
(*new added*)
  | CEForEnd : forall c1 c2 c3 b1 st st',
      c1 / st || st' ->
      beval st' b1 = false ->
      (CFor c1 b1 c2 c3) / st || st'
  | CEForWhile : forall c1 c2 c3 b1 st st1 st2 st3 st',
      c1 / st || st1 ->
      beval st1 b1 = true ->
      c3 / st1 || st2 ->
      c2 / st2 || st3 ->
      (CWhile b1 (CSeq c3 c2)) / st3 || st' ->
      (CFor c1 b1 c2 c3) / st || st'

  where "c1 '/' st '||' st'" := (ceval st c1 st').

Theorem for_while_eq : forall c1 c2 c3 b st st',
  (CSeq c1 (CWhile b (CSeq c3 c2))) / st || st' <->
  (CFor c1 b c2 c3) / st || st'.
Proof.
  intros. split; intros.
  Case "->". inversion H; subst. inversion H5; subst.
    apply CEForEnd. apply H3. apply H6.
    inversion H6; subst. eapply CEForWhile. apply H3. 
     apply H2. apply H7. apply H10. apply H8.
  Case "<-". inversion H; subst.
    eapply CESeq. apply H6. apply CEWhileEnd. apply H7.
    eapply CESeq. apply H4. eapply CEWhileLoop. apply H6.
    eapply CESeq. apply H8. apply H9. apply H10.
Qed.

End Add_For_Loop.

(** **** Exercise: 3 stars, optional (swap_noninterfering_assignments) *)
Theorem swap_noninterfering_assignments: forall l1 l2 a1 a2,
  l1 <> l2 -> 
  var_not_used_in_aexp l1 a2 ->
  var_not_used_in_aexp l2 a1 ->
  cequiv
    (l1 ::= a1; l2 ::= a2)
    (l2 ::= a2; l1 ::= a1).
Proof. 
(* Hint: You'll need [functional_extensionality] *)
unfold cequiv.
intros.
split.
Case "->".
  intros.
  inversion H2;subst. inversion H5;subst. inversion H8;subst.
  apply E_Seq with (st':=update st l2 (aeval st a2)).
  apply E_Ass. reflexivity.
  assert (update (update st l1 (aeval st a1)) l2 (aeval (update st l1 (aeval st a1)) a2)
= update (update st l2 (aeval st a2)) l1 (aeval st a1)).
  apply aeval_weakening with (i:=l1)(a:=a2)(ni:=(aeval st a1))(st:=st) in H0.
  rewrite H0.
  apply functional_extensionality. intros.
  apply update_permute.
  apply not_eq_beq_id_false.
  assumption.
  rewrite H3.
  constructor. 
  apply aeval_weakening with (i:=l2)(a:=a1)(ni:=(aeval st a2))(st:=st) in H1.
  assumption.
Case "<-".
  intros.
  inversion H2;subst. inversion H5;subst. inversion H8;subst. 
  apply E_Seq with (st':=update st l1 (aeval st a1)).
  apply E_Ass. reflexivity.
  assert (update (update st l2 (aeval st a2)) l1 (aeval (update st l2 (aeval st a2)) a1)
= update (update st l1 (aeval st a1)) l2 (aeval st a2)).
  apply aeval_weakening with (i:=l2)(a:=a1)(ni:=(aeval st a2))(st:=st) in H1.
  rewrite H1.
  apply functional_extensionality. intros.
  apply update_permute.
  apply not_eq_beq_id_false. 
  unfold not.  unfold not in H. intros. apply H. rewrite H3. auto.
  rewrite H3.
  constructor.
  apply aeval_weakening with (i:=l1)(a:=a2)(ni:=(aeval st a1))(st:=st) in H0.
  assumption.
Qed.
  
