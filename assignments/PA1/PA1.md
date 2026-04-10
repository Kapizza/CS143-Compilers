# CS143 — Programming Assignment 1
## Stack Machine Interpreter in Cool

---

## Table of Contents
1. [Problem Overview](#1-problem-overview)
2. [Command Reference](#2-command-reference)
3. [Design](#3-design)
4. [Class Breakdown](#4-class-breakdown)
5. [Key Algorithms](#5-key-algorithms)
6. [Worked Example](#6-worked-example)
7. [How to Build and Test](#7-how-to-build-and-test)
8. [README Questions](#8-readme-questions)

---

## 1. Problem Overview

The goal is to write a **stack machine interpreter** in Cool — the teaching language used throughout CS143. A stack machine has exactly one data structure: a single stack. All operations read from and write to that stack.

Input is a sequence of single-line commands. The interpreter must:
- print a `>` prompt before each command,
- execute the command,
- keep running until it reads `x`.

---

## 2. Command Reference

| Command | Effect |
|---------|--------|
| `<int>` | Push the non-negative integer onto the stack |
| `+`     | Push the symbol `+` onto the stack |
| `s`     | Push the symbol `s` onto the stack |
| `e`     | **Evaluate** the top of the stack (see below) |
| `d`     | **Display** all stack contents, top first, one per line |
| `x`     | Exit the interpreter |

### The `e` (evaluate) command in detail

| Top of stack | Action |
|---|---|
| `+` | Pop `+`; pop `A` (new top); pop `B`; push `A + B` |
| `s` | Pop `s`; pop `fst`; pop `snd`; push `fst` then `snd` (swap) |
| integer | Do nothing |
| empty | Do nothing |

---

## 3. Design

### Stack representation

Cool has no built-in array or mutable list, so the stack is modelled as a **singly-linked list** of `StackNode` objects.

```
top of stack
    │
    ▼
┌─────────┐     ┌─────────┐     ┌─────────┐
│ val: "s"│────▶│ val: "2"│────▶│ val: "1"│────▶ void (bottom)
└─────────┘     └─────────┘     └─────────┘
```

- `stack` (an attribute of `Main`) always points to the **top** node.
- An empty stack is represented by `stack = void`.
- **Push**: allocate a new node whose `next` is the old top; update `stack`.
- **Pop**: save the top value, advance `stack` to `next`, return the saved value.

### Value representation

All stack elements — integers, `+`, and `s` — are stored as **strings**. This keeps the node type uniform (`StackNode` needs only a single `String val` field) and avoids the need for a discriminator subclass hierarchy for this assignment.

### String ↔ Integer conversion

The provided `atoi.cl` (`A2I` class) handles all conversions:
- `a2i(s)` converts a string to an `Int`.
- `i2a(i)` converts an `Int` back to a string.

A single shared `A2I` instance (`converter`) is reused for every arithmetic operation.

---

## 4. Class Breakdown

### `StackNode`

| Member | Kind | Description |
|---|---|---|
| `val`  | attribute | The stored value (`"42"`, `"+"`, or `"s"`) |
| `next` | attribute | Link to the node below; `void` at the bottom |
| `init(v, n)` | method | Pseudo-constructor — sets fields, returns `self` |
| `getVal()`   | method | Returns `val` |
| `getNext()`  | method | Returns `next` |

Cool does not allow constructor arguments, so `init` acts as a post-allocation initialiser. The idiom `(new StackNode).init(v, n)` allocates and initialises in one expression.

### `Main` (inherits `IO`)

| Member | Kind | Description |
|---|---|---|
| `stack`     | attribute | Head (top) of the stack; `void` when empty |
| `converter` | attribute | Shared `A2I` instance |
| `push(v)`   | method | Prepend a new node with value `v` |
| `pop()`     | method | Remove and return the top value |
| `display()` | method | Print each element, top to bottom |
| `evaluate()`| method | Execute the top-of-stack command |
| `main()`    | method | Read-eval loop — entry point |

Inheriting `IO` means `out_string()` and `in_string()` are available directly without a separate IO object.

---

## 5. Key Algorithms

### push

```
Before:  stack ──▶ [old top] ──▶ ...
After:   stack ──▶ [v] ──▶ [old top] ──▶ ...
```

```cool
push(v : String) : Object {
    stack <- (new StackNode).init(v, stack)
};
```

### pop

```cool
pop() : String {
    let top : String <- stack.getVal() in
    {
        stack <- stack.getNext();
        top;
    }
};
```

### evaluate — addition

```
Before:  [+] [A] [B] [...]
Step 1 — pop '+':          [A] [B] [...]
Step 2 — a = pop():        [B] [...]        a = A
Step 3 — b = pop():        [...]            b = B
Step 4 — push(a + b):      [A+B] [...]
```

### evaluate — swap

```
Before:  [s] [fst] [snd] [...]
Step 1 — pop 's':          [fst] [snd] [...]
Step 2 — fst = pop():      [snd] [...]
Step 3 — snd = pop():      [...]
Step 4 — push(fst):        [fst] [...]
Step 5 — push(snd):        [snd] [fst] [...]   ← swapped ✓
```

The trick is that we push `fst` **first** so that `snd` ends up on top.

---

## 6. Worked Example

Input from `stack.test`:

```
e         → stack empty, nothing happens
e         → stack empty, nothing happens
1         → push "1"          stack: [1]
+         → push "+"          stack: [+ 1]
2         → push "2"          stack: [2 + 1]
s         → push "s"          stack: [s 2 + 1]
d         → display ──────────────────────────── output: s / 2 / + / 1
e         → swap: pop s, swap 2 and +  stack: [+ 2 1]
e         → add:  pop +, 2+1=3         stack: [3]
d         → display ──────────────────────────── output: 3
...
x         → exit
```

Expected output (prompts omitted for clarity):
```
s
2
+
1
3
s
s
s
1
+
3
4
```

---

## 7. How to Build and Test

```bash
# Compile
gmake compile

# Run against stack.test and diff with reference
gmake test

# Run interactively
coolc stack.cl atoi.cl
spim -file stack.s
```

---

## 8. README Questions

**1. Describe your implementation of the stack machine.**

The stack is a singly-linked list of `StackNode` objects, each holding a string value and a pointer to the node below. The `Main` class provides `push` and `pop` helpers and a `main` read-eval loop that reads one command per line, dispatching to `display` or `evaluate` as needed. All values (integers, `+`, `s`) are stored uniformly as strings; `A2I` handles conversion only when arithmetic is required.

**2. Three things I like about Cool.**

1. **Simple, clean syntax.** The `let ... in` and `if ... then ... else ... fi` constructs are readable and unambiguous.
2. **Everything is an object.** Uniform dispatch via inheritance makes it easy to extend the interpreter to new command types.
3. **Explicit `isvoid` check.** Having a first-class way to test for null (void) without exceptions makes list traversal safe and explicit.

**3. Three things I dislike about Cool.**

1. **No built-in collections.** No arrays or lists forces manual linked-list management for even simple tasks.
2. **No constructor arguments.** The `init()` pseudo-constructor pattern is verbose and error-prone — forgetting to call `init` leaves an object in an undefined state.
3. **Verbosity of if-else chains.** Nested `if ... else if ...` requires matching `fi fi fi ...` at the end, which is easy to miscount and hard to read at a glance.
