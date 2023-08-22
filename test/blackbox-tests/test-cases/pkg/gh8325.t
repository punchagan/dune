Things should be the same whether dependencies are specified or not.

  $ mkdir dune.lock
  $ cat >dune.lock/lock.dune <<EOF
  > (lang package 0.1)
  > EOF

If we have a package we depend on

  $ mkdir dependency-source
  $ cat >dune.lock/dependency.pkg <<EOF
  > (source (copy $PWD/dependency-source))
  > EOF

And we have a package we want to build

  $ mkdir test-source
  $ cat >dune.lock/test.pkg <<EOF
  > (source (copy $PWD/test-source))
  > (build
  >  (system "command -v cat > /dev/null 2>&1 || echo no cat"))
  > EOF
  $ dune build _build/_private/.pkg/test/target/

Now it fails since adding the dependency modified PATH.

  $ cat >dune.lock/test.pkg <<EOF
  > (source (copy $PWD/test-source))
  > ; adding deps breaks cat
  > (deps dependency)
  > (build
  >  (system "command -v cat > /dev/null 2>&1 || echo no cat"))
  > EOF
  $ dune build _build/_private/.pkg/test/target/
