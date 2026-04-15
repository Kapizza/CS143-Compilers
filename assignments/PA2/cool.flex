/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/* Nesting depth for (* ... *) comments */
static int comment_depth = 0;

/* Set to true after a string error; suppresses further actions until
 * the closing quote (or newline/EOF) so we don't emit cascading errors. */
static bool string_error = false;

%}

/*
 * Define names for regular expressions here.
 */

DARROW   =>
ASSIGN   <-
LE       <=
DIGIT    [0-9]
ALNUM    [a-zA-Z0-9_]

/* Suppress yywrap so we don't need libfl */
%option noyywrap

/* Exclusive start conditions */
%x COMMENT
%x STRING

%%

 /*
  *  Nested block comments  (* ... *)
  *  We track depth so that (* (* *) *) is handled correctly.
  */
"(*"              { comment_depth = 1; BEGIN(COMMENT); }
<COMMENT>"(*"     { comment_depth++; }
<COMMENT>"*)"     { if (--comment_depth == 0) BEGIN(INITIAL); }
<COMMENT>\n       { curr_lineno++; }
<COMMENT><<EOF>>  {
                      cool_yylval.error_msg = "EOF in comment";
                      BEGIN(INITIAL);
                      return (ERROR);
                  }
<COMMENT>.        { /* skip comment body */ }

 /* Single-line comments: -- to end of line */
"--"[^\n]*        { /* skip */ }

 /* Unmatched close-comment outside any comment */
"*)"              {
                      cool_yylval.error_msg = "Unmatched *)";
                      return (ERROR);
                  }

 /*
  *  The multiple-character operators.
  */
{DARROW}          { return (DARROW); }
{ASSIGN}          { return (ASSIGN); }
{LE}              { return (LE); }

 /*
  * Keywords - case-insensitive (each letter matched in both cases).
  * true and false are special: only match when the first letter is lowercase.
  */
[cC][lL][aA][sS][sS]              { return (CLASS); }
[eE][lL][sS][eE]                  { return (ELSE); }
[fF][iI]                          { return (FI); }
[iI][fF]                          { return (IF); }
[iI][nN]                          { return (IN); }
[iI][nN][hH][eE][rR][iI][tT][sS] { return (INHERITS); }
[lL][eE][tT]                      { return (LET); }
[lL][oO][oO][pP]                  { return (LOOP); }
[pP][oO][oO][lL]                  { return (POOL); }
[tT][hH][eE][nN]                  { return (THEN); }
[wW][hH][iI][lL][eE]             { return (WHILE); }
[cC][aA][sS][eE]                  { return (CASE); }
[eE][sS][aA][cC]                  { return (ESAC); }
[oO][fF]                          { return (OF); }
[nN][eE][wW]                      { return (NEW); }
[iI][sS][vV][oO][iI][dD]         { return (ISVOID); }
[nN][oO][tT]                      { return (NOT); }

 /* Boolean literals - must start with lowercase */
t[rR][uU][eE]    { cool_yylval.boolean = 1; return (BOOL_CONST); }
f[aA][lL][sS][eE] { cool_yylval.boolean = 0; return (BOOL_CONST); }

 /*
  * Integer constants — any run of digits.
  * (Do not check whether the value fits; store the raw text.)
  */
{DIGIT}+          {
                      cool_yylval.symbol = inttable.add_string(yytext);
                      return (INT_CONST);
                  }

 /*
  * Identifiers.
  * Type identifiers begin with an uppercase letter.
  * Object identifiers begin with a lowercase letter.
  * Because keywords are listed above, the longest-match rule ensures
  * "classX" becomes OBJECTID while "class " becomes CLASS.
  */
[A-Z]{ALNUM}*     {
                      cool_yylval.symbol = idtable.add_string(yytext);
                      return (TYPEID);
                  }

[a-z]{ALNUM}*     {
                      cool_yylval.symbol = idtable.add_string(yytext);
                      return (OBJECTID);
                  }

 /*
  *  String constants.
  *  We collect characters into string_buf.  Escape sequences are
  *  translated here.  Errors (null byte, too long, unterminated) are
  *  reported and scanning resumes after the end of the bad string.
  */
\"                {
                      string_buf_ptr = string_buf;
                      string_error = false;
                      BEGIN(STRING);
                  }

 /* Closing quote — emit the token (unless an error already occurred) */
<STRING>\"        {
                      BEGIN(INITIAL);
                      if (!string_error) {
                          *string_buf_ptr = '\0';
                          cool_yylval.symbol = stringtable.add_string(string_buf);
                          return (STR_CONST);
                      }
                      /* If string_error is set we already returned ERROR;
                       * just silently resume in INITIAL. */
                  }

 /* Unescaped newline inside a string — unterminated */
<STRING>\n        {
                      curr_lineno++;
                      BEGIN(INITIAL);
                      if (!string_error) {
                          cool_yylval.error_msg = "Unterminated string constant";
                          return (ERROR);
                      }
                  }

 /* EOF inside a string */
<STRING><<EOF>>   {
                      BEGIN(INITIAL);
                      if (!string_error) {
                          cool_yylval.error_msg = "EOF in string constant";
                          return (ERROR);
                      }
                  }

 /* Escaped newline — counts as a literal newline character in the string */
<STRING>\\\n      {
                      curr_lineno++;
                      if (!string_error) {
                          if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                              string_error = true;
                              cool_yylval.error_msg = "String constant too long";
                              return (ERROR);
                          }
                          *string_buf_ptr++ = '\n';
                      }
                  }

 /* Named escape sequences */
<STRING>\\n       {
                      if (!string_error) {
                          if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                              string_error = true;
                              cool_yylval.error_msg = "String constant too long";
                              return (ERROR);
                          }
                          *string_buf_ptr++ = '\n';
                      }
                  }
<STRING>\\t       {
                      if (!string_error) {
                          if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                              string_error = true;
                              cool_yylval.error_msg = "String constant too long";
                              return (ERROR);
                          }
                          *string_buf_ptr++ = '\t';
                      }
                  }
<STRING>\\b       {
                      if (!string_error) {
                          if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                              string_error = true;
                              cool_yylval.error_msg = "String constant too long";
                              return (ERROR);
                          }
                          *string_buf_ptr++ = '\b';
                      }
                  }
<STRING>\\f       {
                      if (!string_error) {
                          if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                              string_error = true;
                              cool_yylval.error_msg = "String constant too long";
                              return (ERROR);
                          }
                          *string_buf_ptr++ = '\f';
                      }
                  }

 /* Any other escape: \c → c  (includes \\ → \, \" → ", \0 → '0', etc.) */
<STRING>\\.       {
                      if (!string_error) {
                          if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                              string_error = true;
                              cool_yylval.error_msg = "String constant too long";
                              return (ERROR);
                          }
                          *string_buf_ptr++ = yytext[1];
                      }
                  }

 /* Literal null byte — forbidden inside strings */
<STRING>[\000]    {
                      if (!string_error) {
                          string_error = true;
                          cool_yylval.error_msg = "String contains null character";
                          return (ERROR);
                      }
                  }

 /* Ordinary string character */
<STRING>.         {
                      if (!string_error) {
                          if (string_buf_ptr - string_buf >= MAX_STR_CONST - 1) {
                              string_error = true;
                              cool_yylval.error_msg = "String constant too long";
                              return (ERROR);
                          }
                          *string_buf_ptr++ = yytext[0];
                      }
                  }

 /*
  * Whitespace — track line numbers, otherwise ignore.
  */
\n                { curr_lineno++; }
[ \f\r\t\v]+      { /* skip */ }

 /*
  * Single-character tokens: operators and punctuation.
  * The ASCII value of the character itself is the token code.
  */
[+\-*/<=~{}();:.,@] { return yytext[0]; }

 /*
  * Anything that didn't match above is an illegal character.
  * Return it as an ERROR token.
  */
.                 {
                      cool_yylval.error_msg = yytext;
                      return (ERROR);
                  }

%%
