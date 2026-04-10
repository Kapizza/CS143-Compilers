(*
 * ============================================================
 *  CS143  —  Programming Assignment 1
 *  Stack Machine Interpreter
 * ============================================================
 *
 *  OVERVIEW
 *  --------
 *  This file implements a tiny interpreter for a stack-based
 *  command language in the Cool programming language.
 *
 *  Supported commands (one per line):
 *
 *    <int>   Push the non-negative integer onto the stack.
 *    +       Push the symbol '+' onto the stack.
 *    s       Push the symbol 's' onto the stack.
 *    e       Evaluate the top of the stack:
 *              • top = '+'  →  pop '+', pop A, pop B, push A+B
 *              • top = 's'  →  pop 's', swap the next two items
 *              • top = int  →  do nothing (stack unchanged)
 *              • empty      →  do nothing
 *    d       Display the stack contents, top first, one per line.
 *    x       Exit the interpreter gracefully.
 *
 *  DATA STRUCTURE
 *  --------------
 *  Cool has no built-in array or list type, so the stack is
 *  represented as a singly-linked list of StackNode objects.
 *  Each node stores its value as a String (integers are kept
 *  in string form so that '+' and 's' can live on the same
 *  stack without a separate discriminator class).
 *
 *      top of stack
 *          │
 *          ▼
 *      ┌───────┐    ┌───────┐    ┌───────┐
 *      │ val   │───▶│ val   │───▶│ val   │───▶ void
 *      └───────┘    └───────┘    └───────┘
 *
 *  CLASSES
 *  -------
 *    StackNode   —  a single node in the linked-list stack
 *    Main        —  interpreter loop + stack operations
 *    A2I         —  string ↔ integer helpers  (atoi.cl)
 *
 * ============================================================
 *)


(* ============================================================
 *  CLASS  StackNode
 * ============================================================
 *  One element of the stack.  Because Cool does not support
 *  mutable constructors, we use an explicit init() method to
 *  set fields and return 'self', allowing call-chaining:
 *
 *      (new StackNode).init("42", existingTop)
 *
 *  Attributes
 *  ----------
 *    val  : String     — the stored value (a numeral, "+", or "s")
 *    next : StackNode  — pointer to the element below; void at bottom
 * ============================================================ *)
class StackNode {

    val  : String;      (* value stored at this position          *)
    next : StackNode;   (* link to the node directly below; void
                           when this is the bottom of the stack   *)

    (* ----------------------------------------------------------
     *  init  —  pseudo-constructor
     *
     *  Sets both fields and returns self so the caller can write
     *  the whole allocation + initialisation in one expression.
     *
     *  Parameters
     *    v  the value to store in this node
     *    n  the node that will sit directly below this one
     *       (pass the current stack top when pushing)
     * ---------------------------------------------------------- *)
    init(v : String, n : StackNode) : StackNode {
        {
            val  <- v;
            next <- n;
            self;          (* return self for call-chaining *)
        }
    };

    (* Simple accessors — keep fields private to the class. *)
    getVal()  : String    { val  };
    getNext() : StackNode { next };

};


(* ============================================================
 *  CLASS  Main
 * ============================================================
 *  The entry point of the Cool runtime.  Inheriting IO gives
 *  direct access to out_string() and in_string() without
 *  needing a separate IO object.
 *
 *  Attributes
 *  ----------
 *    stack     : StackNode  — head (top) of the linked-list stack;
 *                             void when the stack is empty
 *    converter : A2I        — single shared instance for all
 *                             string ↔ integer conversions
 * ============================================================ *)
class Main inherits IO {

    stack     : StackNode;              (* top of the stack; void = empty *)
    converter : A2I <- new A2I;         (* reused for every numeric op    *)


    (* ----------------------------------------------------------
     *  push  —  add a new element on top of the stack
     *
     *  Creates a fresh StackNode whose 'next' points to the
     *  current top, then updates the stack head pointer.
     *
     *  Parameter  v  the string value to push
     * ---------------------------------------------------------- *)
    push(v : String) : Object {
        stack <- (new StackNode).init(v, stack)
        (*
         * Before:  stack ──▶ [old top] ──▶ ...
         * After:   stack ──▶ [v] ──▶ [old top] ──▶ ...
         *)
    };


    (* ----------------------------------------------------------
     *  pop  —  remove and return the top element
     *
     *  Saves the top value, advances the head pointer to the
     *  next node, then returns the saved value.
     *
     *  NOTE: The caller must never pop an empty stack.
     *        (The assignment guarantees valid input, so no
     *         guard is needed here.)
     * ---------------------------------------------------------- *)
    pop() : String {
        let top : String <- stack.getVal() in   (* save before unlinking *)
        {
            stack <- stack.getNext();           (* advance head pointer  *)
            top;                                (* return the saved value *)
        }
    };


    (* ----------------------------------------------------------
     *  display  —  print every element of the stack, top first
     *
     *  Walks the linked list from head to tail, printing each
     *  value on its own line.  An empty stack produces no output.
     * ---------------------------------------------------------- *)
    display() : Object {
        let cur : StackNode <- stack in         (* start at the top *)
            while not (isvoid cur) loop
            {
                out_string(cur.getVal());       (* print the value   *)
                out_string("\n");               (* one item per line *)
                cur <- cur.getNext();           (* descend the list  *)
            }
            pool
    };


    (* ----------------------------------------------------------
     *  evaluate  —  execute the top-of-stack command
     *
     *  Three cases:
     *
     *  1. top = '+'
     *       Pop '+', pop A (new top), pop B (next), push A+B.
     *       Both A and B must be integer strings; we use A2I
     *       to convert them and i2a to convert the result back.
     *
     *       Before:  [+] [A] [B] ...
     *       After:   [A+B] ...
     *
     *  2. top = 's'
     *       Pop 's', pop fst (new top), pop snd (next),
     *       then push fst back first and snd on top — so the
     *       two values are exchanged.
     *
     *       Before:  [s] [fst] [snd] ...
     *       After:   [snd] [fst] ...
     *
     *       Push order: push(fst) then push(snd)
     *         → snd ends up on top  ✓
     *
     *  3. top = integer  OR  stack is empty
     *       Do nothing.  Return 0 as a dummy Object value.
     * ---------------------------------------------------------- *)
    evaluate() : Object {
        if isvoid stack then 0   (* empty stack — nothing to evaluate *)
        else
            let top : String <- stack.getVal() in

                (* ── case 1: addition ─────────────────────────── *)
                if top = "+" then
                {
                    pop();   (* discard the '+' operator node *)

                    let a : Int <- converter.a2i(pop()) in   (* first  operand *)
                    let b : Int <- converter.a2i(pop()) in   (* second operand *)
                        push(converter.i2a(a + b));          (* push sum       *)
                }

                (* ── case 2: swap ──────────────────────────────── *)
                else if top = "s" then
                {
                    pop();   (* discard the 's' operator node *)

                    let fst : String <- pop() in   (* element that was 2nd from top *)
                    let snd : String <- pop() in   (* element that was 3rd from top *)
                    {
                        push(fst);   (* fst goes down one level  *)
                        push(snd);   (* snd rises to the top  ✓  *)
                    };
                }

                (* ── case 3: integer on top — no-op ───────────── *)
                else 0

                fi fi   (* close the two nested if-else expressions *)
        fi
    };


    (* ----------------------------------------------------------
     *  main  —  the interpreter's read-eval loop
     *
     *  Repeatedly:
     *    1. Print the '>' prompt.
     *    2. Read one line of input (in_string strips the newline).
     *    3. Dispatch to the appropriate handler.
     *    4. Stop when the command is 'x'.
     *
     *  All unrecognised tokens are treated as integers and pushed
     *  directly (the assignment guarantees they will be valid
     *  unsigned integer strings).
     * ---------------------------------------------------------- *)
    main() : Object {
        let stop : Bool   <- false in   (* loop-exit flag        *)
        let cmd  : String <- ""    in   (* current input command *)
            while not stop loop
            {
                out_string(">");            (* prompt  *)
                cmd <- in_string();         (* read one line *)

                if      cmd = "x" then stop <- true   (* exit            *)
                else if cmd = "d" then display()       (* display stack   *)
                else if cmd = "e" then evaluate()      (* evaluate top    *)
                else if cmd = "+" then push("+")       (* push '+' token  *)
                else if cmd = "s" then push("s")       (* push 's' token  *)
                else                   push(cmd)       (* push integer    *)
                fi fi fi fi fi;
            }
            pool
    };

};
