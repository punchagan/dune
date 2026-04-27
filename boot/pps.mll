{
  let b = Buffer.create 512
}

rule pp = parse
 | "let%expect_test" { skip lexbuf }
 | "let%test_module" { skip_module 0 lexbuf }
 | _ as c { Buffer.add_char b c; pp lexbuf }
 | eof { () }

and skip = parse
  | ";;" { pp lexbuf }
  | _ { skip lexbuf }
  | eof { failwith "unterminated let%expect_test" }

and skip_module depth = parse
  | '(' { skip_module (depth + 1) lexbuf }
  | ')' { if depth = 1 then skip lexbuf else skip_module (depth - 1) lexbuf }
  | _ { skip_module depth lexbuf }
  | eof { failwith "unterminated let%test_module" }

{
  let pp s =
    let lb = Lexing.from_string s in
    Buffer.clear b;
    pp lb;
    Buffer.contents b
}
