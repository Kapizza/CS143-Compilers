# CS143 — Compilers

Stanford CS143 programming assignments solved in Cool (Classroom Object-Oriented Language).

---

## Setup (WSL on Windows)

### Step 1 — Install WSL

In PowerShell (run as Administrator), if not already done:
```powershell
wsl --install
```
Restart when prompted. This installs Ubuntu by default.

### Step 2 — Run the setup script

Open your WSL terminal and run:
```bash
cd /mnt/c/path/to/CS143-Compilers
bash setup-wsl.sh
source ~/.bashrc
```

This installs `coolc`, `spim`, and all required build tools.
Tools are installed to `/usr/class/bin/`.

### Step 3 — Compile and run PA1

```bash
cd /mnt/c/path/to/CS143-Compilers/assignments/PA1
coolc stack.cl atoi.cl        # compile → stack.s
spim -file stack.s            # run interactively
gmake test                    # run against stack.test and diff with reference
# Note: CLASSDIR is set to /usr/class in the Makefile
```

### Step 4 — Compile and run PA2

```bash
cd /mnt/c/path/to/CS143-Compilers/assignments/PA2
make lexer                    # build the lexer via flex + g++
./lexer test.cl               # lex a Cool source file and print tokens
make dotest                   # run lexer on test.cl via Makefile target
```

### Step 5 — Compile and run PA3

```bash
cd /mnt/c/path/to/CS143-Compilers/assignments/PA3
make parser LIB=''            # build the parser (yywrap is a macro, -lfl not needed)
./myparser good.cl            # parse a valid Cool file and print the AST
./myparser bad.cl             # parse an invalid file and print error messages
make dotest                   # run both test files via Makefile target
```

---

## Assignments

| # | Topic | Directory |
|---|-------|-----------|
| PA1 | Stack machine interpreter in Cool | [assignments/PA1/](assignments/PA1/) |
| PA2 | Lexical analyzer (flex) | [assignments/PA2/](assignments/PA2/) |
| PA3 | Parser (bison) | [assignments/PA3/](assignments/PA3/) |

---

## Acknowledgments

**Assignment specification PDFs** (PA1.pdf, PA2.pdf, PA3.pdf) are from the official
[Stanford CS143 course](https://web.stanford.edu/class/cs143/) and are included here
for reference only. All rights belong to Stanford University.

**Starter/skeleton files** (Makefiles, skeleton `.y`, `.flex`, `.cl`, support headers) are the
official course-provided starting files from Stanford CS143, mirrored at
[rsanders/coursera-cs143-mac](https://github.com/rsanders/coursera-cs143-mac).

---

## PA2 — Lexical Analyzer

Implemented in [assignments/PA2/cool.flex](assignments/PA2/cool.flex) using flex.

### Design

**Comments**
- Block comments `(* ... *)` use an exclusive `COMMENT` start condition with a `comment_depth` counter to support arbitrary nesting.
- Line comments `--` are handled by a single regex that consumes the rest of the line.
- An unmatched `*)` outside any comment returns an `ERROR` token.

**Keywords**
- All 16 Cool keywords are matched case-insensitively using per-character `[aA]`-style alternations.
- `true` and `false` are special: only matched when the first letter is lowercase (per the Cool spec), using `t[rR][uU][eE]` / `f[aA][lL][sS][eE]`.
- Because keywords are listed before the identifier rules, flex's longest-match rule ensures `classX` becomes `OBJECTID` while `class ` becomes `CLASS`.

**Identifiers**
- Type identifiers (`TYPEID`) begin with an uppercase letter: `[A-Z]{ALNUM}*`.
- Object identifiers (`OBJECTID`) begin with a lowercase letter: `[a-z]{ALNUM}*`.

**Strings**
- An exclusive `STRING` start condition collects characters into `string_buf` (max 1025 bytes).
- Escape sequences `\n`, `\t`, `\b`, `\f`, `\\`, `\"` are translated; any other `\c` maps to `c`.
- Escaped newline `\\\n` counts as a literal newline in the string and increments `curr_lineno`.
- Errors (null byte, string too long, unterminated, EOF inside string) set a `string_error` flag so cascading errors are suppressed until the closing quote.

**Error recovery**
- Any unrecognized character falls through to the catch-all rule and is returned as `ERROR` with the character as the message.

### Test cases (`test.cl`)
The provided `test.cl` is a cellular automaton program containing several intentional lexical errors:
- Single-quoted character literal (`'.'`) — not valid in Cool.
- `num_cells[]` — square brackets are not valid Cool syntax.
- Unclosed `let` / `while` — the missing closing paren and `}` mean EOF is reached inside a string or block.

---

## PA3 — Parser

Implemented in [assignments/PA3/cool.y](assignments/PA3/cool.y) using Bison.

### Design

**Grammar structure**

Non-terminals added on top of the skeleton:

| Non-terminal | Description |
|---|---|
| `feature_list` / `feature` | Class body: methods and attributes |
| `formal_list` / `formal` | Comma-separated parameter lists (possibly empty) |
| `case_list` / `case_branch` | One or more typed `case` branches |
| `block_list` | Semicolon-terminated expression sequences inside `{ }` |
| `actuals` | Comma-separated argument lists (possibly empty) |
| `let_body` | Recursive let binding list plus the body expression |
| `expression` | All 20+ Cool expression forms |

All list rules are left-recursive (Bison preference).

**Operator precedence** (lowest → highest)

| Level | Operator(s) | Associativity |
|---|---|---|
| 1 | `in` (let body delimiter) | non-assoc |
| 2 | `<-` | right |
| 3 | `not` | left |
| 4 | `<` `=` `<=` | non-assoc |
| 5 | `+` `-` | left |
| 6 | `*` `/` | left |
| 7 | `isvoid` | left |
| 8 | `~` | left |
| 9 | `@` | left |
| 10 | `.` | left |

**Let ambiguity**

The Cool manual states that a `let` expression extends as far to the right as possible.
This is implemented via a separate `let_body` non-terminal that recursively consumes
additional comma-separated bindings before reaching the `in` clause.
Declaring `IN` at the lowest precedence level means every operator outranks it, so
Bison always shifts an operator into the body rather than reducing early.
The grammar compiles with **0 shift/reduce and 0 reduce/reduce conflicts**.

**Error recovery**

| Location | Rule |
|---|---|
| Class list | `class_list : class_list error ';'` |
| Class header | `class : CLASS error '{' … '}'` and `CLASS TYPEID INHERITS error '{' … '}'` |
| Feature list | `feature_list : feature_list error ';'` |
| Block expression | `block_list : block_list error ';'` |
| Let binding | `let_body : error IN expression` and `error ',' let_body` |

### Test cases

`good.cl` exercises every legal grammar construct: classes with and without inheritance,
attributes (with and without initializers), methods with multiple formals, all expression
forms (assignment, self/dynamic/static dispatch, if/while/case/let, block, new, isvoid,
all arithmetic and comparison operators, `not`, `~`, parenthesized expressions, and all
atom types).

`bad.cl` exercises error recovery: lowercase class/parent name, misspelled keyword,
missing closing brace, missing feature semicolon, malformed let binding, and a block
expression missing its semicolon.
