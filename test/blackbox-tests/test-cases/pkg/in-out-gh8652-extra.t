Reproduces the dune-self-build cycle (#8652 manifestation). Names match
dune's own setup, with one simplification: in real dune-self-build, base's
workspace_depends targets `dune-configurator` (a separate workspace pkg),
which reaches `dune`'s install file via transitive package_deps machinery.
Here we collapse the chain by having base workspace_depends directly on
`dune` -- the pkg containing the executable that uses ocaml_inotify.

  $ cat > dune-project << EOF
  > (lang dune 3.22)
  > (package (name dune) (allow_empty) (depends base))
  > EOF

  $ cat > dune-workspace << EOF
  > (lang dune 3.22)
  > EOF
  $ enable_pkg
  $ make_lockdir

  $ mkdir base-src
  $ cat > base-src/dune-project << EOF
  > (lang dune 3.22)
  > (package (name base))
  > EOF
  $ cat > base-src/dune << EOF
  > (library (public_name base))
  > EOF
  $ cat > base-src/base.ml << EOF
  > let hello = "hello from base"
  > EOF
  $ make_lockpkg base <<EOF
  > (version 0.0.1)
  > (workspace_depends dune)
  > (dune)
  > (source (copy $PWD/base-src))
  > EOF

  $ mkdir ppx_expect-src
  $ cat > ppx_expect-src/dune-project << EOF
  > (lang dune 3.22)
  > (package (name ppx_expect))
  > EOF
  $ cat > ppx_expect-src/dune << EOF
  > (library (public_name ppx_expect) (libraries base))
  > EOF
  $ cat > ppx_expect-src/ppx_expect.ml << EOF
  > let greeting = Base.hello ^ " via ppx_expect"
  > EOF
  $ make_lockpkg ppx_expect <<EOF
  > (version 0.0.1)
  > (depends base)
  > (dune)
  > (source (copy $PWD/ppx_expect-src))
  > EOF

Orphan workspace lib (no public_name, no package). Uses (libraries unix)
to force fallback findlib to walk lockdir paths.

  $ mkdir -p vendor/ocaml-inotify
  $ cat > vendor/ocaml-inotify/dune << EOF
  > (library (name ocaml_inotify) (libraries unix))
  > EOF
  $ cat > vendor/ocaml-inotify/ocaml_inotify.ml << EOF
  > let tag = "inotify"
  > EOF

Public executable in package `dune` that depends on the orphan -- mirrors
dune's bin/main.exe -> dune_scheduler -> ocaml_inotify chain.

  $ mkdir bin
  $ cat > bin/dune << EOF
  > (executable (name main) (public_name dune) (package dune) (libraries ocaml_inotify))
  > EOF
  $ cat > bin/main.ml << EOF
  > let () = print_endline Ocaml_inotify.tag
  > EOF

  $ dune build 2>&1
  Error: Dependency cycle between:
     _build/default/dune.install
  -> _build/_private/default/.pkg/base.0.0.1-25ad249b4871f392a283a69bc22e4611/target
  -> _build/_private/default/.pkg/ppx_expect.0.0.1-0c2f1b0f7bc72df3e681e02a6d5921d3/target
  -> library "ocaml_inotify" in _build/default/vendor/ocaml-inotify
  -> _build/install/default/bin/dune
  -> _build/default/dune.install
  -> required by alias all
  -> required by alias default
  [1]
