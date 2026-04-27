Testing that the bootstrap preprocessor strips let%test_module blocks.

  $ init_bootstrap

  $ mkdir -p src/a

  $ cat > src/a/a.ml <<EOF
  > module Root = Root
  > let x = 42
  > let%test_module "tests" =
  >   (module struct
  >     let%expect_test "inner test" =
  >       print_int x;
  >       [%expect {| 42 |}]
  >     ;;
  >     let helper () = x + 1
  >     let%expect_test "another" =
  >       print_int (helper ());
  >       [%expect {| 43 |}]
  >     ;;
  >   end)
  > ;;
  > let () = Printf.printf "x = %d\n" x
  > EOF

  $ make_module src/a/root.ml

  $ cat > src/a/dune <<EOF
  > (library
  >  (name a))
  > EOF

CR-soon Alizter: Currently the bootstrap does not handle %test_module, it
should strip this.

  $ create_dune a <<EOF
  > let () = Printf.printf "Hello, x = %d" A.x
  > EOF
  ocamllex -q -o boot/pps.ml boot/pps.mll
  ocamlc -output-complete-exe -intf-suffix .dummy -g -o .duneboot.exe -I boot -I +unix unix.cma boot/pps.ml boot/types.ml boot/libs.ml boot/duneboot.ml
  ./.duneboot.exe
  cd _boot && /OCAMLOPT -c -g -no-alias-deps -w -49-23-53 -alert -unstable -I +unix -I +threads a.ml
  File "a.ml", line 4, characters 4-15:
  4 | let%test_module "tests" =
          ^^^^^^^^^^^
  Error: Uninterpreted extension 'test_module'.
  [2]
