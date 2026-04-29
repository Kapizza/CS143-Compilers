(*
 *  bad.cl — parse errors that the parser should detect and recover from.
 *  Run with:  myparser bad.cl
 *)

(* no error *)
class A {
};

(* error: b is not a type identifier *)
Class b inherits A {
};

(* error: a is not a type identifier in inherits position *)
Class C inherits a {
};

(* error: keyword inherits is misspelled — 'inherts' is an OBJECTID *)
Class D inherts A {
};

(* error: closing brace is missing — parser should recover at ';' *)
Class E inherits A {
;

(* no error — parser should restart here *)
Class F {
    x : Int <- 5;
};

(* error: feature missing semicolon — should recover at next feature *)
Class G {
    foo() : Int { 1 }
    bar() : Int { 2 };
};

(* error: bad let binding — missing type *)
Class H {
    test() : Int {
        let x <- 3 in x
    };
};

(* error: expression in block missing semicolon *)
Class I {
    test() : Object {
        {
            1 + 2
            3 + 4;
        }
    };
};
