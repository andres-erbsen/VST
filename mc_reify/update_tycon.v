Require Import floyd.proofauto.
Require Import funcs.
Require Import types.
Require Import reify.
Require Import MirrorCore.Lambda.ExprCore.

Definition initialized_temp (id : positive) (t : PTree.t (type * bool)) :=
match (t ! id) with
| Some (ty, _) =>
  PTree.set id (ty, true) t
| None => t
end.


Fixpoint update_temp (t : PTree.t (type * bool)) (s : statement) :=
 match s with
 | Sskip | Scontinue | Sbreak => t
 | Sassign e1 e2 => t (*already there?*)
 | Sset id e2 => (initialized_temp id t)
 | Ssequence s1 s2 => let t' := update_temp t s1 in
                      update_temp t' s2
 | Sifthenelse b s1 s2 => join_te (update_temp t s1) (update_temp t s2)
 | Sloop _ _ => t
 | Sswitch e ls => update_temp_labeled t ls
 | Scall (Some id) _ _ => (initialized_temp id t)
 | _ => t  (* et cetera *)
end
with update_temp_labeled (t : PTree.t (type * bool)) (ls : labeled_statements) :=
       match ls with
         | LSnil => t
         | LScons _ s ls' =>
           join_te (update_temp t s) (update_temp_labeled t ls')
       end.

Lemma initialized_temp_eq : forall t v r gt gs i,
initialized i (mk_tycontext t v r gt gs) = mk_tycontext (initialized_temp i t) v r gt gs.
Proof.
intros.
unfold initialized, temp_types, initialized_temp. simpl. destruct (t ! i); auto.
destruct p; auto.
Qed.

Lemma update_temp_eq : forall t v r gt gs s,
update_tycon (mk_tycontext t v r gt gs) s = (mk_tycontext (update_temp t s) v r gt gs)
with
update_temp_labeled_eq : forall t v r gt gs s,
join_tycon_labeled s (mk_tycontext t v r gt gs) = (mk_tycontext (update_temp_labeled t s) v r gt gs).
Proof.
intros. 
destruct s; intros;
simpl; try rewrite initialized_temp_eq; try reflexivity.
destruct o; try rewrite initialized_temp_eq; auto.
repeat rewrite update_temp_eq. reflexivity.
unfold join_tycon. 
repeat rewrite update_temp_eq. reflexivity.
repeat rewrite update_temp_labeled_eq. reflexivity.

intros.
destruct s; intros; simpl; try reflexivity.
unfold join_tycon. repeat rewrite update_temp_eq.
rewrite update_temp_labeled_eq. reflexivity.
Qed.

Definition update_tycon_tac (e : expr typ func) (args : list (expr typ func))
	: expr typ func :=
match e with
    | (Inj (inr (Smx (fupdate_tycon)))) => 
      match args with
          | [App (Inj (inr (Smx (ftycontext t v r gt)))) gs; (Inj (inr (Smx (fstatement s))))] => 
            App (Inj (inr (Smx (ftycontext (update_temp t s) v r gt)))) gs
          | _ =>  AppN.apps e args
      end
    | _ => AppN.apps e args
end.

Instance MA : MentionsAny (expr typ func) := {
  mentionsAny := ExprCore.mentionsAny
}.