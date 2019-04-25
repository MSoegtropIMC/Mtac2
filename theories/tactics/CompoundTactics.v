From Mtac2 Require Import Base Tactics ImportedTactics Datatypes List Logic Abstract Sorts.
Import Sorts.S.
Import M. Import M.notations.
Import ListNotations.
Import ProdNotations.

Require Import Strings.String.

Set Implicit Arguments.
Unset Strict Implicit.

Module CT.

Definition SimpleRewriteNoOccurrence : Exception. constructor. Qed.
Definition simple_rewrite A {x y : A} (p : x = y) : tactic := fun g=>
  gT <- goal_type g;
  r <- T.abstract_from_term x gT;
  match r with
  | mSome r =>
    newG <- evar (r y);
    T.exact (eq_rect y _ newG x (eq_sym p)) g;;
    ret [m: (m: tt, AnyMetavar Typeₛ _ newG)]
  | mNone => M.raise SimpleRewriteNoOccurrence
  end.

Import TacticsBase.T.notations.
Definition CVariablizeNoOccurrence : Exception. constructor. Qed.
Definition cvariabilize_base {A} (fail: bool) (t: A) (name:name) (cont: A -> tactic) : tactic :=
  gT <- T.goal_type;
  r <- T.abstract_from_term t gT;
  match r with
  | mSome r =>
    T.cpose_base name t (fun x =>
      T.change (r x);;
      cont x
    )
  | mNone =>
    if fail then M.raise CVariablizeNoOccurrence
    else T.cpose_base name t (fun x =>
      T.change ((fun _=>gT) x);;
      cont x
    )
  end.

Definition destruct {A : Type} (n : A) : tactic :=
  mif M.is_var n then
    T.destruct n
  else
    cvariabilize_base false n (FreshFromStr "dn") (fun x=>T.destruct x).

Program Definition destruct_eq {A} (t: A) : tactic :=
  cvariabilize_base false t (FreshFromStr "v") (fun var=>
    T.cassert_base (FreshFromStr "eqn") (fun (eqnv : t = var)=>
      T.cmove_back eqnv (T.destruct var))
      |1> T.reflexivity
  ).

Module notations.

Notation "'uid' v" := (fun v:unit=>unit) (at level 0).
Notation "'variabilize' t 'as' v" :=
  (
    cvariabilize_base false t (FreshFrom (uid v)) (fun _=>T.idtac)
  ) (at level 0, t at next level, v at next level).

End notations.
End CT.