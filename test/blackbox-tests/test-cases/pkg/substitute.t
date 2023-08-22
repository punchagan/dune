The test-source folder has a file to use substitution on.

  $ mkdir test-source
  $ cat >test-source/foo.ml.in <<EOF
  > This file will be fed to the substitution mechanism
  > EOF
  $ mkdir dune.lock
  $ cat >dune.lock/lock.dune <<EOF
  > (lang package 0.1)
  > EOF
  $ cat >dune.lock/test.pkg <<EOF
  > (source (copy $PWD/test-source))
  > (build
  >  (progn
  >   (substitute foo.ml.in foo.ml)
  >   (system "cat foo.ml")))
  > EOF

This should take the `foo.ml.in`, do the substitutions and create `foo.ml`:

  $ dune build _build/_private/.pkg/test/target/
  This file will be fed to the substitution mechanism

This should also work with any other filename combination:

  $ cat >test-source/foo.ml.template <<EOF
  > This is using a different file suffix
  > EOF
  $ cat >dune.lock/test.pkg <<EOF
  > (source (copy $PWD/test-source))
  > (build
  >  (progn
  >   (substitute foo.ml.template not-a-prefix)
  >   (system "cat not-a-prefix")))
  > EOF

This should take the `foo.ml.template`, do the substitution and create
`foo.ml`, thus be more flexible that the OPAM `substs` field:

  $ dune build _build/_private/.pkg/test/target/
  This is using a different file suffix

Undefined variables, how do they substitute?

  $ cat >test-source/variables.ml.in <<EOF
  > We substitute this '%%{var}%%' into '%{var}%'
  > EOF
  $ cat >dune.lock/test.pkg <<EOF
  > (source (copy $PWD/test-source))
  > (build
  >  (progn
  >   (substitute variables.ml.in variables.ml)
  >   (system "cat variables.ml")))
  > EOF
  $ dune build _build/_private/.pkg/test/target/
  We substitute this '%{var}%' into ''

Now with variables set

  $ cat >test-source/defined.ml.in <<EOF
  > We substitute '%%{name}%%' into '%{name}%' and '%%{_:name}%%' into '%{_:name}%'
  > And '%%{version}%%' is set to '%{version}%'
  > There is also some paths set:
  > '%%{lib}%%' is '%{lib}%'
  > '%%{lib_root}%%' is '%{lib_root}%'
  > '%%{libexec}%%' is '%{libexec}%'
  > '%%{libexec_root}%%' is '%{libexec_root}%'
  > '%%{bin}%%' is '%{bin}%'
  > '%%{sbin}%%' is '%{sbin}%'
  > '%%{toplevel}%%' is '%{toplevel}%'
  > '%%{share}%%' is '%{share}%'
  > '%%{share_root}%%' is '%{share_root}%'
  > '%%{etc}%%' is '%{etc}%'
  > '%%{doc}%%' is '%{doc}%'
  > '%%{stublibs}%%' is '%{stublibs}%'
  > '%%{man}%%' is '%{man}%'
  > Finally, '%%{custom}%%' is '%{custom}%'
  > EOF
  $ cat >dune.lock/test.pkg <<EOF
  > (source (copy $PWD/test-source))
  > (build
  >  (progn
  >   (withenv
  >    ((= custom defined-here))
  >    (substitute defined.ml.in defined.ml))
  >   (system "cat defined.ml")))
  > EOF
  $ dune build _build/_private/.pkg/test/target/
  We substitute '%{name}%' into 'test' and '%{_:name}%' into 'test'
  And '%{version}%' is set to 'dev'
  There is also some paths set:
  '%{lib}%' is '_build/default/.pkg/test/target/lib/test'
  '%{lib_root}%' is '_build/default/.pkg/test/target/lib'
  '%{libexec}%' is '_build/default/.pkg/test/target/lib/test'
  '%{libexec_root}%' is '_build/default/.pkg/test/target/lib'
  '%{bin}%' is '_build/default/.pkg/test/target/bin'
  '%{sbin}%' is '_build/default/.pkg/test/target/sbin'
  '%{toplevel}%' is '_build/default/.pkg/test/target/lib/toplevel'
  '%{share}%' is '_build/default/.pkg/test/target/share/test'
  '%{share_root}%' is '_build/default/.pkg/test/target/share'
  '%{etc}%' is '_build/default/.pkg/test/target/etc/test'
  '%{doc}%' is '_build/default/.pkg/test/target/doc/test'
  '%{stublibs}%' is '_build/default/.pkg/test/target/lib/stublibs'
  '%{man}%' is '_build/default/.pkg/test/target/man'
  Finally, '%{custom}%' is 'defined-here'

It is also possible to use variables of your dependencies:

  $ mkdir dependency-source
  $ cat >dune.lock/dependency.pkg <<EOF
  > (source (copy $PWD/dependency-source))
  > EOF
  $ cat >dune.lock/test.pkg <<EOF
  > (source (copy $PWD/test-source))
  > ; adding deps breaks cat
  > ;(deps dependency)
  > (build
  >  (progn
  >   (substitute dependencies.ml.in dependencies.ml)
  >   (system "cat dependencies.ml")))
  > EOF
  $ cat >test-source/dependencies.ml.in <<EOF
  > There is also some paths set:
  > '%%{dependency:lib}%%' is '%{dependency:lib}%'
  > EOF
  $ dune build _build/_private/.pkg/test/target/
  There is also some paths set:
  '%{dependency:lib}%' is '_build/default/.pkg/test/target/lib/test'
