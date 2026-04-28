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
