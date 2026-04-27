Regression: under [(implicit_transitive_deps false)], a transitive
link-only library must not invalidate the consumer when the consumer
cannot see it through [-I] or [-H].

[link_only_lib] is a transitive dep of [main]: [main] depends on
[intermediate_lib] which declares [link_only_lib]. With
[(implicit_transitive_deps false)], [link_only_lib]'s modules are
not on [main]'s [-I] path; [main]'s source cannot reference
[Link_only_module] at all. The per-module dependency computation
in #14116 must therefore not surface [link_only_lib] as a
compile-rule dep — an earlier iteration of that PR did, via a
glob over the lib's objdir, causing spurious [Main] recompiles
when [link_only_module] changed.

Reported by @nojb in
https://github.com/ocaml/dune/pull/14116#issuecomment-4323883194.

  $ cat > dune-project <<EOF
  > (lang dune 3.23)
  > (implicit_transitive_deps false)
  > EOF

  $ cat > dune <<EOF
  > (library
  >  (name link_only_lib)
  >  (wrapped false)
  >  (modules link_only_module))
  > (library
  >  (name intermediate_lib)
  >  (wrapped false)
  >  (modules intermediate_module)
  >  (libraries link_only_lib))
  > (executable
  >  (name main)
  >  (modules main)
  >  (libraries intermediate_lib))
  > EOF

  $ cat > link_only_module.ml <<EOF
  > let x = 42
  > EOF

  $ cat > intermediate_module.ml <<EOF
  > let x = 42
  > EOF

  $ cat > main.ml <<EOF
  > let _ = Intermediate_module.x
  > EOF

  $ dune build ./main.exe

Edit [link_only_module]. [Main] doesn't reference it, and the
compiler cannot see [link_only_lib] under
[(implicit_transitive_deps false)], so [Main] must not be
recompiled (the executable may still relink because
[link_only_module.cmx] changes, but [Main.cmo] / [Main.cmx] must
not):

  $ cat > link_only_module.ml <<EOF
  > let x = 43
  > EOF
  $ dune build ./main.exe
  $ dune trace cat | jq -s 'include "dune"; [.[] | targetsMatchingFilter(test("dune__exe__Main"))]'
  []
