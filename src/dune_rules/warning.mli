(** General warning mechanism for dune rules *)

open Import

type t

val create
  :  default:(Syntax.Version.t -> Config.Toggle.t)
  -> name:string
  -> since:Syntax.Version.t
  -> t

module Settings : sig
  (** Settings to disable/enable specific warnings in a project *)

  type warning := t
  type t

  val to_dyn : t -> Dyn.t
  val empty : t
  val decode : t Dune_sexp.Decoder.t
  val active : t -> warning -> Syntax.Version.t -> Config.Toggle.t
end

(** Warn whenever [(name <name>)]) is missing from the [dune-project] file *)
val missing_project_name : t
