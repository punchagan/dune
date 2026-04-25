open Stdune

(** Add values for expanding [%{name}] for a package *)
val add_self_to_filter_env
  :  OpamPackage.t
  -> (OpamTypes.full_variable -> OpamVariable.variable_contents option)
  -> OpamTypes.full_variable
  -> OpamVariable.variable_contents option

(** Convert a selected opam package to a package that dune can save to the lock
    directory.

    [local_packages] is the set of workspace package names; deps resolving to
    one of these are recorded in the [Pkg.t]'s [workspace_depends] field
    instead of [depends], so consumers can route them through the workspace
    install tree rather than expecting a locked entry. *)
val opam_package_to_lock_file_pkg
  :  Solver_env.t
  -> Solver_stats.Updater.t
  -> Package_version.t Package_name.Map.t
  -> OpamPackage.t
  -> pinned:bool
  -> local_packages:Package_name.Set.t
  -> Resolved_package.t
  -> portable_lock_dir:bool
  -> (Lock_dir.Pkg.t, User_message.t) result
