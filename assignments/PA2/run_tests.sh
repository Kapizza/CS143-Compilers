#!/bin/bash
# Lexer test suite for PA2 Cool scanner.
# Run from the PA2 directory: bash run_tests.sh
# Requires ./lexer to be already built (make lexer).

LEXER=./lexer
PASS=0
FAIL=0

# ── helpers ─────────────────────────────────────────────────────────────────

# run_test <description> <cool-source> <expected-substring>
#   Passes if expected-substring appears anywhere in lexer output.
run_test() {
    local desc="$1"
    local src="$2"
    local expected="$3"
    local tmpfile
    tmpfile=$(mktemp /tmp/cool_test_XXXXXX.cl)
    printf '%s' "$src" > "$tmpfile"
    local output
    output=$($LEXER "$tmpfile" 2>&1)
    rm -f "$tmpfile"
    if echo "$output" | grep -qF "$expected"; then
        echo "  PASS  $desc"
        PASS=$((PASS + 1))
    else
        echo "  FAIL  $desc"
        echo "        expected to find : $expected"
        echo "        actual output    : $output"
        FAIL=$((FAIL + 1))
    fi
}

# run_absent <description> <cool-source> <absent-substring>
#   Passes if absent-substring does NOT appear in lexer output.
run_absent() {
    local desc="$1"
    local src="$2"
    local absent="$3"
    local tmpfile
    tmpfile=$(mktemp /tmp/cool_test_XXXXXX.cl)
    printf '%s' "$src" > "$tmpfile"
    local output
    output=$($LEXER "$tmpfile" 2>&1)
    rm -f "$tmpfile"
    if echo "$output" | grep -qF "$absent"; then
        echo "  FAIL  $desc"
        echo "        did not expect   : $absent"
        echo "        actual output    : $output"
        FAIL=$((FAIL + 1))
    else
        echo "  PASS  $desc"
        PASS=$((PASS + 1))
    fi
}

echo "======================================"
echo " Cool Lexer Test Suite"
echo "======================================"

# ── 1. Keywords (case-insensitive) ──────────────────────────────────────────
echo ""
echo "--- Keywords ---"
run_test "class keyword lowercase"   "class"    "CLASS"
run_test "class keyword uppercase"   "CLASS"    "CLASS"
run_test "class keyword mixed"       "ClAsS"    "CLASS"
run_test "else keyword"              "else"     "ELSE"
run_test "fi keyword"                "fi"       "FI"
run_test "if keyword"                "IF"       "IF"
run_test "in keyword"                "In"       "IN"
run_test "inherits keyword"          "inherits" "INHERITS"
run_test "let keyword"               "LET"      "LET"
run_test "loop keyword"              "Loop"     "LOOP"
run_test "pool keyword"              "pool"     "POOL"
run_test "then keyword"              "THEN"     "THEN"
run_test "while keyword"             "While"    "WHILE"
run_test "case keyword"              "case"     "CASE"
run_test "esac keyword"              "ESAC"     "ESAC"
run_test "of keyword"                "of"       "OF"
run_test "new keyword"               "New"      "NEW"
run_test "isvoid keyword"            "isvoid"   "ISVOID"
run_test "not keyword"               "NoT"      "NOT"

# keyword followed by identifier chars → OBJECTID, not keyword
run_test "class prefix is OBJECTID"  "classX"   "OBJECTID classX"
run_test "in prefix is OBJECTID"     "inFoo"    "OBJECTID inFoo"
run_absent "classX is not CLASS"     "classX"   "CLASS"

# ── 2. Boolean constants ─────────────────────────────────────────────────────
echo ""
echo "--- Boolean constants ---"
run_test "true lowercase"            "true"     "BOOL_CONST true"
run_test "true mixed case"           "tRuE"     "BOOL_CONST true"
run_test "false lowercase"           "false"    "BOOL_CONST false"
run_test "false mixed case"          "fAlSe"    "BOOL_CONST false"
# Must start with lowercase — uppercase T makes it a TYPEID
run_test "True is TYPEID not bool"   "True"     "TYPEID True"
run_absent "True is not BOOL_CONST"  "True"     "BOOL_CONST"
run_test "False is TYPEID not bool"  "False"    "TYPEID False"

# ── 3. Integer constants ─────────────────────────────────────────────────────
echo ""
echo "--- Integer constants ---"
run_test "single digit"              "0"        "INT_CONST 0"
run_test "multi digit"               "12345"    "INT_CONST 12345"
run_test "large int"                 "99999999" "INT_CONST 99999999"

# ── 4. Identifiers ───────────────────────────────────────────────────────────
echo ""
echo "--- Identifiers ---"
run_test "type id uppercase start"   "MyClass"  "TYPEID MyClass"
run_test "type id all caps"          "FOO"      "TYPEID FOO"
run_test "object id lowercase start" "myVar"    "OBJECTID myVar"
run_test "object id with digits"     "x1y2"     "OBJECTID x1y2"
run_test "object id with underscore" "my_var"   "OBJECTID my_var"
run_test "SELF_TYPE is TYPEID"       "SELF_TYPE" "TYPEID SELF_TYPE"
run_test "self is OBJECTID"          "self"     "OBJECTID self"

# ── 5. Operators ─────────────────────────────────────────────────────────────
echo ""
echo "--- Operators ---"
run_test "DARROW =>"    "=>"  "DARROW"
run_test "ASSIGN <-"    "<-"  "ASSIGN"
run_test "LE <="        "<="  "LE"
run_test "plus +"       "+"   "'+'"
run_test "minus -"      "-"   "'-'"
run_test "times *"      "*"   "'*'"
run_test "divide /"     "/"   "'/'"
run_test "less than <"  "<"   "'<'"
run_test "equals ="     "="   "'='"
run_test "tilde ~"      "~"   "'~'"
run_test "at @"         "@"   "'@'"
run_test "dot ."        "."   "'.'"
run_test "comma ,"      ","   "','"
run_test "semicolon ;"  ";"   "';'"
run_test "colon :"      ":"   "':'"
run_test "lbrace {"     "{"   "'{'"
run_test "rbrace }"     "}"   "'}'"
run_test "lparen ("     "("   "'('"
run_test "rparen )"     ")"   "')'"

# ── 6. String constants ───────────────────────────────────────────────────────
echo ""
echo "--- String constants ---"
run_test "empty string"              '""'           'STR_CONST ""'
run_test "simple string"             '"hello"'      'STR_CONST "hello"'
run_test "escape \\n in string"      '"a\nb"'       'STR_CONST "a\nb"'
run_test "escape \\t in string"      '"a\tb"'       'STR_CONST "a\tb"'
run_test "escape \\b in string"      '"a\bb"'       'STR_CONST "a\bb"'
run_test "escape \\f in string"      '"a\fb"'       'STR_CONST "a\fb"'
run_test "escape \\\\ in string"     '"a\\b"'       'STR_CONST "a\\b"'
run_test 'escape \" in string'       '"a\"b"'       'STR_CONST "a\"b"'
run_test 'escape \\0 becomes 0'      '"a\0b"'       'STR_CONST "a0b"'
run_test "escaped newline is newline" '"a\
b"'  'STR_CONST "a\nb"'

# ── 7. Comments ──────────────────────────────────────────────────────────────
echo ""
echo "--- Comments ---"
run_test "line comment ignored"      $'-- foo bar\n42' "INT_CONST 42"
run_test "block comment ignored"     "(* hello *) 42" "INT_CONST 42"
run_test "nested block comment"      "(* (* inner *) outer *) 42" "INT_CONST 42"
run_absent "comment content hidden"  "(* secret *) 42" "OBJECTID secret"
run_test "line comment no newline"   "-- only comment"  ""   # no tokens → output just has #name

# ── 8. Whitespace ────────────────────────────────────────────────────────────
echo ""
echo "--- Whitespace ---"
run_test "spaces ignored"            "  42  "   "INT_CONST 42"
run_test "tabs ignored"              "	42	"  "INT_CONST 42"
run_test "newlines count lines"      "42
99" "#2 INT_CONST 99"

# ── 9. Error: invalid characters ─────────────────────────────────────────────
echo ""
echo "--- Error: invalid characters ---"
run_test "hash is error"             "#"   'ERROR "#"'
run_test "bang is error"             "!"   'ERROR "!"'
run_test "dollar is error"           '$'   'ERROR "$"'
run_test "caret is error"            "^"   'ERROR "^"'
run_test "ampersand is error"        "&"   'ERROR "&"'
run_test "lbracket is error"         "["   'ERROR "["'
run_test "rbracket is error"         "]"   'ERROR "]"'
run_test "backslash is error"        "\\"  'ERROR "\\"'
run_test "single quote is error"     "'"   "ERROR \"'\""
run_test "greater-than is error"     ">"   'ERROR ">"'

# ── 10. Error: unmatched *) ───────────────────────────────────────────────────
echo ""
echo "--- Error: unmatched *) ---"
run_test "unmatched *)"              "*)"  'ERROR "Unmatched *)"'
run_test "unmatched *) after token"  "42 *)" 'ERROR "Unmatched *)"'

# ── 11. Error: EOF in comment ────────────────────────────────────────────────
echo ""
echo "--- Error: EOF in comment ---"
run_test "EOF in block comment"          "(*"           'ERROR "EOF in comment"'
run_test "EOF in nested comment"         "(* (* *)"     'ERROR "EOF in comment"'
run_test "comment content before EOF"    "(* hello"     'ERROR "EOF in comment"'

# ── 12. Error: unterminated string ───────────────────────────────────────────
echo ""
echo "--- Error: unterminated string ---"
# Unescaped newline inside a string
run_test "unescaped newline in string" "\"hello
world\""  'ERROR "Unterminated string constant"'
# Lexing resumes: next line's tokens should still appear
run_test "resume after unterminated string" "\"bad
42"  'INT_CONST 42'

# ── 13. Error: EOF in string ─────────────────────────────────────────────────
echo ""
echo "--- Error: EOF in string ---"
run_test "EOF in string"             '"hello'   'ERROR "EOF in string constant"'
run_test "EOF in empty string"       '"'        'ERROR "EOF in string constant"'

# ── 14. Error: string too long ───────────────────────────────────────────────
echo ""
echo "--- Error: string too long ---"
# Build a string with 1025 'a' characters (one over the 1024-char limit)
LONG_STR='"'
LONG_STR+=$(python3 -c "print('a'*1025, end='')")
LONG_STR+='"'
run_test "string too long"           "$LONG_STR" 'ERROR "String constant too long"'

# A string of exactly 1024 chars should be fine
OK_STR='"'
OK_STR+=$(python3 -c "print('a'*1024, end='')")
OK_STR+='"'
run_test "string exactly 1024 chars ok" "$OK_STR" 'STR_CONST'
run_absent "1024-char string not too long" "$OK_STR" 'String constant too long'

# ── 15. Error: null character in string ─────────────────────────────────────
echo ""
echo "--- Error: null character in string ---"
# Shell command substitution strips null bytes, so write the file directly via Python
null_tmpfile=$(mktemp /tmp/cool_test_XXXXXX.cl)
python3 -c "open('$null_tmpfile','wb').write(b'\"a\x00b\"')"
null_output=$($LEXER "$null_tmpfile" 2>&1)
rm -f "$null_tmpfile"
if echo "$null_output" | grep -qF 'ERROR "String contains null character"'; then
    echo "  PASS  null byte in string"
    PASS=$((PASS + 1))
else
    echo "  FAIL  null byte in string"
    echo "        expected to find : ERROR \"String contains null character\""
    echo "        actual output    : $null_output"
    FAIL=$((FAIL + 1))
fi

# ── 16. Mixed / regression ───────────────────────────────────────────────────
echo ""
echo "--- Mixed / regression ---"
run_test "class def tokens"  \
    "class Foo inherits Bar { x : Int; };" \
    "TYPEID Foo"
run_test "method call chain" \
    "self.foo().bar" \
    "OBJECTID foo"
run_test "let expression"    \
    "let x : Int <- 0 in x" \
    "ASSIGN"
run_test "arrow in case"     \
    "case x of y : Int => y; esac" \
    "DARROW"
run_test "nested comments don't swallow code" \
    "(* comment *) class (* another *) Foo {}" \
    "TYPEID Foo"

# ── Summary ──────────────────────────────────────────────────────────────────
echo ""
echo "======================================"
echo " Results: $PASS passed, $FAIL failed"
echo "======================================"
[ $FAIL -eq 0 ] && exit 0 || exit 1
