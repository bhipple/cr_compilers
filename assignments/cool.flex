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
char *string_buf_ptr = &string_buf[0];

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */
#include <iostream>

int comment_depth = 0;

IdTable idTable;
IntTable intTable;
StrTable strTable;

%}

/*
 * Define names for regular expressions here.
 */

DARROW          =>
DIGIT           [0-9]
TYPE_IDENTIFIER [A-Z][A-Za-z_0-9]*
OBJ_IDENTIFIER  [a-z][A-Za-z_0-9]*

ESCAPED_STR_CHARS   \\[btnf]

WHITESPACE      [ \t\f\r\v]+

%x STRING
%x BADSTRING
%x COMMENT
%x BR_COMMENT

%%

{WHITESPACE}            { /* nom nom nom */ }
\n                      { ++curr_lineno;}

 /*
  *  Nested comments
  */
\*\)                    {
                            cool_yylval.error_msg = "Unmatched *)";
                            return ERROR;
                        }
\-\-                    { BEGIN(COMMENT); }
<COMMENT>[^\n]          { /* eat it */ }
<COMMENT>\n             { BEGIN(INITIAL); ++curr_lineno; }

\(\*                    { BEGIN(BR_COMMENT); ++comment_depth; }
<BR_COMMENT>\\\(\*      { /* escaping the \(* */ }
<BR_COMMENT>\\\*\)      { /* escaping the \*) */}
<BR_COMMENT>\(\*        { ++comment_depth; }
<BR_COMMENT>\*\)        {
                            --comment_depth;
                            if(comment_depth == 0) {
                                BEGIN(INITIAL);
                            }
                        }
<BR_COMMENT><<EOF>>     {
                            BEGIN(INITIAL);
                            cool_yylval.error_msg = "EOF in comment";
                            return ERROR;
                        }
<BR_COMMENT>\\          { /* eat it */ }
<BR_COMMENT>[^\\\*\)\n] { /* eat it */ }
<BR_COMMENT>\*          { }
<BR_COMMENT>\n          { ++curr_lineno; }

 /*
  *  The multiple-character operators.
  */
{DARROW}                { return DARROW; }
(?i:ISVOID)             { return ISVOID; }
(?i:NOT)                { return NOT; }
\<=                     { return LE; }
\<-                     { return ASSIGN; }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */
SELF_TYPE               { }

(?i:CLASS)              { return CLASS; }
(?i:ELSE)               { return ELSE; }
(?i:IF)                 { return IF; }
(?i:FI)                 { return FI; }
(?i:IN)                 { return IN; }
(?i:INHERITS)           { return INHERITS; }
(?i:LET)                { return LET; }
(?i:LOOP)               { return LOOP; }
(?i:POOL)               { return POOL; }
(?i:THEN)               { return THEN; }
(?i:WHILE)              { return WHILE; }
(?i:CASE)               { return CASE; }
(?i:ESAC)               { return ESAC; }
(?i:OF)                 { return OF; }
(?i:NEW)                { return NEW; }

t[Rr][Uu][Ee]           { cool_yylval.boolean = true;
                            return BOOL_CONST; }
f[Aa][Ll][Ss][Ee]       { cool_yylval.boolean = false;
                            return BOOL_CONST; }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for
  *  \n \t \b \f, the result is c.
  *
  */
\"                      {
                            BEGIN(STRING);
                            memset(&string_buf[0], 0, sizeof(string_buf));
                        }
<STRING>\"              {
                            BEGIN(INITIAL);
                            if(strlen(string_buf_ptr) >= MAX_STR_CONST) {
                                cool_yylval.error_msg = "String constant too long";
                                return ERROR;
                            }
                            else {
                                cool_yylval.symbol = strTable.add_string(string_buf);
                                return STR_CONST;
                            }
                        }
<STRING>\n              {
                            // Correct path handled by the case below
                            BEGIN(INITIAL);
                            cool_yylval.error_msg = "Unterminated string constant";
                            return ERROR;
                        }
<STRING><<EOF>>         {
                            BEGIN(INITIAL);
                            cool_yylval.error_msg = "EOF in string constant";
                            return ERROR;
                        }
<STRING>\0              {
                            BEGIN(BADSTRING);
                            cool_yylval.error_msg = "Null character in string.";
                            return ERROR;
                        }
<STRING>\\              {
                            char c = yyinput();
                            if(c == 'b') {
                                string_buf[strlen(string_buf)] = '\b';
                            }
                            else if(c == 't') {
                                string_buf[strlen(string_buf)] = '\t';
                            }
                            else if(c == 'n' || c == '\n') {
                                string_buf[strlen(string_buf)] = '\n';
                            }
                            else if(c == 'f') {
                                string_buf[strlen(string_buf)] = '\f';
                            }
                            else if(c == '\0') {
                                BEGIN(BADSTRING);
                                cool_yylval.error_msg = "String contains escaped null character.";
                                return ERROR;
                            }
                            else {
                                string_buf[strlen(string_buf)] = c;
                            }
                        }
<STRING>[^"\n\0\\]+     {
                            strcat(string_buf, yytext);
                        }

<BADSTRING>["\n]        { BEGIN(INITIAL); }
<BADSTRING>[^"\n]+      { }

 /* Operators */
\+                      { return '+'; }
\-                      { return '-'; }
\*                      { return '*'; }
\.                      { return '.'; }
\(                      { return '('; }
\)                      { return ')'; }
\{                      { return '{'; }
\}                      { return '}'; }
;                       { return ';'; }
:                       { return ':'; }
@                       { return '@'; }
,                       { return ','; }
\/                      { return '/'; }
~                       { return '~'; }
\<                      { return '<'; }
=                       { return '='; }

 /* The rest */
{TYPE_IDENTIFIER}       {
                            cool_yylval.symbol = strTable.add_string(yytext);
                            return TYPEID;
                        }
{OBJ_IDENTIFIER}        {
                            cool_yylval.symbol = strTable.add_string(yytext);
                            return OBJECTID;
                        }
{DIGIT}+                {
                            cool_yylval.symbol = intTable.add_int(atoi(yytext));
                            return INT_CONST;
                        }

 /* Characters not in the language */
[!#$%^&_>?`\[\]\\|_]    {
                            cool_yylval.error_msg = yytext;
                            return ERROR;
                        }
%%
