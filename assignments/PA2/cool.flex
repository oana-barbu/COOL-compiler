/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%option noyywrap

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

int comment_depth = 0;
bool string_too_long() {
	return string_buf_ptr == &string_buf[MAX_STR_CONST - 1];
}

%}

%x LINE_COMMENT
/* 
 * MLC is short for multi-line comment 
 */
%x MLC 
%x STRING
%x STRING_ERROR

/*
 * Define names for regular expressions here.
 */

DIGIT       	[0-9]
LETTER      	[a-zA-Z]
INTEGER     	{DIGIT}+
WHITESPACE  	(\ |\f|\r|\t|\v)
NEWLINE			\n
OBJECTID    	[a-z]({LETTER}|{DIGIT}|_)*
TYPEID      	[A-Z]({LETTER}|{DIGIT}|_)*
SINGLE_OP   	"+"|"-"|"*"|"/"|"~"|"."|"@"|"<"|"="
DELIMITER   	"("|")"|"{"|"}"|";"|","|":"

CLASS       	?i:class
ELSE        	?i:ELSE
FALSE      	 	f(?i:alse)
FI          	?i:fi
IF          	?i:if
IN          	?i:in
INHERITS    	?i:inherits
ISVOID      	?i:isvoid
LET         	?i:let
LOOP        	?i:loop
POOL        	?i:pool
THEN        	?i:then
WHILE       	?i:while
CASE        	?i:case
ESAC        	?i:esac
NEW         	?i:new
OF          	?i:of
NOT         	?i:not
TRUE 		    t(?i:rue)
LE 				<=
ASSIGN			<-
DARROW			=>

%%

{NEWLINE} 					{ ++curr_lineno; }
{WHITESPACE}				;

 /*
  *  Single-line comments
  */

"--"						{ BEGIN(LINE_COMMENT); }
<LINE_COMMENT>.				;
<LINE_COMMENT>{NEWLINE}		{ ++curr_lineno;
							  BEGIN(INITIAL); }

 /*
  *  Nested comments
  */

<INITIAL,MLC>"(*"			{ ++comment_depth;
							  BEGIN(MLC); }

"*)"						{ cool_yylval.error_msg = "Unmatched *)";
							  return (ERROR); }

<MLC>"*)"					{ --comment_depth;
							  if (comment_depth == 0) BEGIN(INITIAL); }

<MLC><<EOF>>				{ BEGIN(INITIAL);
							  cool_yylval.error_msg = "EOF in comment";
							  return (ERROR); }

<MLC>.						;
<MLC>{NEWLINE}				{ ++curr_lineno; }


 /*
  *  The multiple-character operators.
  */
{DARROW}					{ return (DARROW); }
{LE}						{ return (LE); }
{ASSIGN}					{ return (ASSIGN);}

 /*
  *  The single-character operators and delimiters.
  */

{SINGLE_OP}|{DELIMITER}		{ return int(yytext[0]); }

 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */

{CLASS}			{ return (CLASS); }
{ELSE}			{ return (ELSE); }
{FI}			{ return (FI); }
{IF}			{ return (IF); }
{IN}			{ return (IN); }
{INHERITS}		{ return (INHERITS); }
{ISVOID}		{ return (ISVOID); }
{LET}			{ return (LET); }
{LOOP}			{ return (LOOP); }
{POOL}			{ return (POOL); }
{THEN}			{ return (THEN); }
{WHILE}			{ return (WHILE); }
{CASE}			{ return (CASE); }
{ESAC}			{ return (ESAC); }
{NEW}			{ return (NEW); }
{OF}			{ return (OF); }
{NOT}			{ return (NOT); }

{TRUE}			{ cool_yylval.boolean = true;
				  return BOOL_CONST; }
{FALSE}			{ cool_yylval.boolean = false;
				  return BOOL_CONST; }

 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */

\"					{ string_buf_ptr = string_buf;
					  BEGIN(STRING); }
<STRING><<EOF>>		{ BEGIN(INITIAL);
					  cool_yylval.error_msg = "EOF in string constant";
					  return (ERROR); }	
<STRING>\0			{ BEGIN(STRING_ERROR);
					  cool_yylval.error_msg = "String contains null character";
					  return (ERROR); }	
<STRING>\"			{ BEGIN(INITIAL);
					  *string_buf_ptr = '\0';
					  cool_yylval.symbol = stringtable.add_string(string_buf);
					  return (STR_CONST); }
<STRING>"\\".		{ if (string_too_long()) {
						BEGIN(STRING_ERROR);
						cool_yylval.error_msg = "String constant too long";
					  	return (ERROR);
					  }
					  if (yytext[1] == '\0') {
					  	BEGIN(STRING_ERROR);
						cool_yylval.error_msg = "String contains null character";
					  	return (ERROR);
					  }
					  switch (yytext[1]) {
					  	case 'n':
					  		*string_buf_ptr++ = '\n';
					  		break;
					  	case 't':
					  		*string_buf_ptr++ = '\t';
					  		break;
					  	case 'b':
					  		*string_buf_ptr++ = '\b';
					  		break;
					  	case 'f':
					  		*string_buf_ptr++ = '\f';
					  		break;
					  	default:
					  		*string_buf_ptr++ = yytext[1];
					  }
					}
<STRING>\\{NEWLINE} 	{ if (string_too_long()) {
							BEGIN(STRING_ERROR);
							cool_yylval.error_msg = "String constant too long";
					  		return (ERROR);
					  	  }
						  *string_buf_ptr++ = '\n';
						  ++curr_lineno;
						}
<STRING>{NEWLINE}	{ ++curr_lineno;
					  BEGIN(INITIAL);
					  cool_yylval.error_msg = "Unterminated string constant";
					  return (ERROR); }	

<STRING>.			{ if (string_too_long()) {
						BEGIN(STRING_ERROR);
						cool_yylval.error_msg = "String constant too long";
						return (ERROR);
					  }
					  *string_buf_ptr++ = yytext[0];
					}
<STRING_ERROR>{NEWLINE}	{ ++curr_lineno;
						  BEGIN(INITIAL); }
<STRING_ERROR>\"		{ BEGIN(INITIAL); }
<STRING_ERROR>.			;

 /*
  *  Integer constants.
  */

{INTEGER}		{ cool_yylval.symbol = inttable.add_string(yytext); 
				  return INT_CONST; }

 /*
  *  Identifiers.
  */

{TYPEID}		{ cool_yylval.symbol = idtable.add_string(yytext); 
				  return TYPEID; }

{OBJECTID}		{ cool_yylval.symbol = idtable.add_string(yytext); 
				  return OBJECTID; }

.				{ cool_yylval.error_msg = &yytext[0];
				  return (ERROR); }

%%
