Test that we produce an error message when a non-local package depends on a
local package.

  $ mkrepo
  $ add_mock_repo_if_needed

  $ mkpkg remote <<EOF
  > depends: [
  >  "local_b"
  > ]
  > EOF

  $ cat > dune-project <<EOF
  > (lang dune 3.13)
  > (package
  >  (name local_a)
  >  (depends remote))
  > (package
  >  (name local_b))
  > EOF

  $ dune pkg lock
  Solution for dune.lock
  
  Dependencies common to all supported platforms:
  - remote.0.0.1
