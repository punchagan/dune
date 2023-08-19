(** Emit warnings that respect dune's conventions *)

open Import

type context =
  | Build of Path.Build.t
  | Source of Source_tree.Dir.t
  | Source_dir of Path.Source.t
  | Dune_project of Dune_project.t

(** [emit w ctx f] will call [f] if [w] is enabled in [ctx]. [f] should
    generate the warning corresponding to [w] *)
val emit : Warning.t -> context -> (unit -> unit Memo.t) -> unit Memo.t
