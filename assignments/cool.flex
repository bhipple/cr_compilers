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
TYPE_IDENTIFIER [A-Z][A-Za-z_]*
OBJ_IDENTIFIER  [a-z][A-Za-z_]*

ESCAPED_STR_CHARS   \\[btnf]

WHITESPACE      [ \t\f\r\v]+

%x STRING
%x COMMENT
%x BR_COMMENT

%%

{WHITESPACE}            { /* nom nom nom */ }
\n                      { ++curr_lineno;}

 /*
  *  Nested comments
  */
\-\-                    { BEGIN(COMMENT); }
<COMMENT>[^\n]          { /* eat it */ }
<COMMENT>\n             { BEGIN(INITIAL); ++curr_lineno; }

\(\*                    { BEGIN(BR_COMMENT); ++comment_depth; }
<BR_COMMENT>\(\*        { ++comment_depth; }
<BR_COMMENT>\*\)        { --comment_depth; if(comment_depth == 0) { BEGIN(INITIAL); }}
<BR_COMMENT>[^\*\)\n]   { /* eat it */ }
<BR_COMMENT>\n          { ++curr_lineno; }

 /*
  *  The multiple-character operators.
  */
{DARROW}                { return (DARROW); }
(?i:ISVOID)             { return ISVOID; }
\.                      { return "."; }
(?i:NOT)                { return NOT; }

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
\"                      { BEGIN(STRING); memset(&string_buf[0], 0, sizeof(string_buf)); }
<STRING>\"              {
                          strcat(string_buf, yytext);
                          if(string_buf[strlen(string_buf)-2] == '\\') {
                              yymore();
                          }
                          else {
                              // Kill the ending "
                              string_buf[strlen(string_buf)-1] = '\0';

                              cool_yylval.symbol = strTable.add_string(string_buf);
                              BEGIN(INITIAL);
                              return STR_CONST;
                          }
                        }
<STRING>[^"\n]+         { strcat(string_buf, yytext); }
<STRING>[\n]            {
                        if(yytext[yyleng-2] != '\\') {
                            cool_yylval.error_msg = "Newline in string requires \\";
                            return ERROR;
                        } else {
                            strcat(string_buf, yytext);
                        }
                        }
 /*
\"[^"\n]*               {
                        if(yytext[yyleng-1] == '\\')
                            yymore();
                        else {
                            cool_yylval.symbol = strTable.add_string(yytext);
                            return STR_CONST;
                        }
                        }
 */

{DIGIT}+                {
                        cool_yylval.symbol = intTable.add_int(atoi(yytext));
                        return INT_CONST;
                        }
%%
