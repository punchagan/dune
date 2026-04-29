This test demonstrates a bug where changing a cram test from a directory test
to a file test causes a build failure because the old directory-style
.corrected path remains in _build.

  $ cat > dune-project << EOF
  > (lang dune 3.24)
  > (cram enable)
  > EOF

First, create a directory cram test and run it:

  $ mkdir mytest.t
  $ cat > mytest.t/run.t << EOF
  >   $ echo hello
  > EOF

  $ dune runtest mytest.t
  File "mytest.t/run.t", line 1, characters 0-0:
  --- mytest.t/run.t
  +++ mytest.t/run.t.corrected
  @@ -1 +1,2 @@
     $ echo hello
  +  hello
  [1]

Now change it from a directory cram test to a file cram test:

  $ rm -r mytest.t
  $ cat > mytest.t << EOF
  >   $ echo goodbye
  > EOF

Try to run it. This fails because the old .corrected directory is still in
_build:

  $ dune runtest mytest.t
  File "mytest.t", line 1, characters 0-0:
  --- mytest.t
  +++ mytest.t.corrected
  @@ -1 +1,2 @@
     $ echo goodbye
  +  goodbye
  Error: rename(_build/default/mytest.t.corrected): Is a directory
  -> required by alias mytest
  [1]
