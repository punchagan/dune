Test that installed binaries are visible in dependent packages

  $ make_lockdir
  $ make_lockpkg test <<EOF
  > (version 0.0.1)
  > (build
  >  (progn
  >   (write-file foo "#!/bin/sh\necho from test package")
  >   (run chmod +x foo)
  >   (write-file libxxx "")
  >   (write-file lib_rootxxx "")
  >   (write-file test.install
  >    "\| bin: [ "foo" ]
  >    "\| lib: [ "libxxx" ]
  >    "\| lib_root: [ "lib_rootxxx" ]
  >    "\| share_root: [ "lib_rootxxx" ]
  >   )))
  > EOF

  $ make_lockpkg usetest <<EOF
  > (version 0.0.1)
  > (depends test)
  > (build
  >  (progn
  >   (run foo)
  >   (run mkdir -p %{prefix})))
  > EOF

  $ build_pkg usetest
  from test package

  $ show_pkg_targets test
  
  /bin
  /bin/foo
  /cookie
  /lib
  /lib/lib_rootxxx
  /lib/test
  /lib/test/libxxx
  /share
  /share/lib_rootxxx
  $ show_pkg_cookie test
  { files =
      [ (LIB,
         [ In_build_dir
             "_private/default/.pkg/test.0.0.1-9c502b954310c290a553a3c76bcaddd1/target/lib/test/libxxx"
         ])
      ; (LIB_ROOT,
         [ In_build_dir
             "_private/default/.pkg/test.0.0.1-9c502b954310c290a553a3c76bcaddd1/target/lib/lib_rootxxx"
         ])
      ; (BIN,
         [ In_build_dir
             "_private/default/.pkg/test.0.0.1-9c502b954310c290a553a3c76bcaddd1/target/bin/foo"
         ])
      ; (SHARE_ROOT,
         [ In_build_dir
             "_private/default/.pkg/test.0.0.1-9c502b954310c290a553a3c76bcaddd1/target/share/lib_rootxxx"
         ])
      ]
  ; variables = []
  }

It should also be visible in the workspace:

  $ make_dune_project 3.9

  $ cat >dune <<EOF
  > (rule
  >  (with-stdout-to testout (run sh %{bin:foo})))
  > EOF

  $ dune build ./testout && cat _build/default/testout
  from test package
