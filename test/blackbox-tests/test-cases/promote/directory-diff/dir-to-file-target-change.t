Non-optional diff with a directory target that changes to a file target between
builds. This exercises the Copy path in register_intermediate.

  $ cat > dune-project <<'EOF'
  > (lang dune 3.24)
  > (using directory-targets 0.1)
  > EOF

Start with a rule that produces a directory target, diffed against an expected
directory:

  $ mkdir -p expected/node
  $ printf 'child\n' > expected/node/file

  $ cat > dune <<'EOF'
  > (rule
  >  (targets (dir actual))
  >  (action (system "mkdir -p actual/node && printf 'different\n' > actual/node/file")))
  > 
  > (rule
  >  (alias runtest)
  >  (action (diff expected actual)))
  > EOF

  $ dune runtest
  File "expected/node/file", line 1, characters 0-0:
  --- expected/node/file
  +++ actual/node/file
  @@ -1 +1 @@
  -child
  +different
  [1]

Now change the rule so that it produces a file target instead of a directory,
and update expected accordingly:

  $ rm -r expected
  $ printf 'expected-content\n' > expected

  $ cat > dune <<'EOF'
  > (rule
  >  (with-stdout-to actual (echo "actual-content\n")))
  > 
  > (rule
  >  (alias runtest)
  >  (action (diff expected actual)))
  > EOF

  $ dune runtest
  Error: _build/.promotion-staging/expected: Is a directory
  -> required by alias runtest in dune:4
  File "expected", line 1, characters 0-0:
  --- expected
  +++ actual
  @@ -1 +1 @@
  -expected-content
  +actual-content
  [1]
