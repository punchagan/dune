(** Install layout machinery for [(deps (package ...))].

    Scoped install layout materialised under
    [_build/install/<context>/.packages/<digest>/] containing only the declared
    package dependencies. The consumer side (queries, env construction) lives
    here, low in the dependency stack; the producer side ([gen_rules] for the
    directory and the data resolver callback) lives in [install_rules], which
    is high in the stack and has access to install entries. The two are
    connected by an [Fdecl] seam: [install_rules] calls [set_entry_resolver]
    at module init. *)

open Import

(** How an install layout entry is materialized at the layout destination. *)
type entry_kind =
  | Symlink of Path.t (** symlink from this source path to the layout dst *)
  | Inline_content of string (** write this content to the layout dst *)

type entry =
  { kind : entry_kind
  ; relative : Path.Source.t
  }

(** Must be called during initialization to wire up install entry resolution.
    Called from [install_rules]. *)
val set_entry_resolver : (Context_name.t -> Package.Name.t -> entry list Memo.t) -> unit

(** Files that would be in the layout for a set of packages. Consumers use
    this to set up file-level dependencies. *)
val files : Context_name.t -> Package.Name.t list -> Path.t list Memo.t

(** The [lib] subdirectory of the layout for a set of packages. Suitable for
    adding to [OCAMLPATH]. *)
val lib_root : Context_name.t -> Package.Name.t list -> Path.Build.t

(** Extra OCAMLPATH paths beyond [lib_root] needed so that consumers of
    the layout can resolve the layout libraries' [requires] via findlib.
    For each workspace package, returns paths to its transitive lockdir
    dependencies' library roots. *)
val extra_ocamlpath : Context_name.t -> Package.Name.t list -> Path.t list Memo.t

(** Wire up [extra_ocamlpath] resolution. Called from [install_rules]
    (which has [Dune_load] access to look up [Package.depends]). *)
val set_extra_ocamlpath_resolver
  :  (Context_name.t -> Package.Name.t -> Path.t list Memo.t)
  -> unit

module Key : sig
  type encoded = Digest.t

  module Decoded : sig
    type t = private { packages : Package.Name.t list }
  end

  val decode : encoded -> Decoded.t
end

(** The memoized entries computation. Exposed for [install_rules]'s
    [gen_rules] which materializes the layout into rules
    (symlinks for [Symlink] entries, [write_file] for [Inline_content]). *)
val entries_memo
  : ( Context_name.t * Digest.t
    , (entry_kind * Path.Build.t * Path.Source.t) list )
      Memo.Table.t
