open Import
open Memo.O

type context =
  | Build of Path.Build.t
  | Source of Source_tree.Dir.t
  | Source_dir of Path.Source.t
  | Dune_project of Dune_project.t

let emit t context f =
  (let+ dir =
     match context with
     | Source src -> Memo.return src
     | Source_dir src -> Source_tree.nearest_dir src
     | Dune_project project -> Source_tree.nearest_dir (Dune_project.root project)
     | Build dir ->
       let src_dir = Path.Build.drop_build_context_exn dir in
       Source_tree.nearest_dir src_dir
   in
   match Source_tree.Dir.status dir with
   | Vendored -> `Inactive
   | _ -> `Project (Source_tree.Dir.project dir))
  >>= function
  | `Inactive -> Memo.return ()
  | `Project project ->
    let warnings = Dune_project.warnings project in
    let version = Dune_project.dune_version project in
    (match Warning.Settings.active warnings t version with
     | `Disabled -> Memo.return ()
     | `Enabled -> f ())
;;
