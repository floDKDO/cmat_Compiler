%{
#include "cmat.tab.h"
%}

%option nounput
%option noyywrap

ID                  [a-zA-Z_][a-zA-Z0-9_]*
COMMENT             "//".*|\/\*[^*]*\*+(?:[^\/*][^*]*\*+)*\/
INT                 0|[1-9][0-9]*
FLOAT               ([0-9]+\.[^\.]|\.[0-9])[0-9]*([eE][+-]?[0-9]+)?(f|F)?
STR                 \"([^\"\\]|\\.)*\"
WHITESPACE          [ \t\n\v\f\r]+

%%

[\;,=\+\-\*\/\(\)\{\}~\[\]&|^!<>]     {return yytext[0];}

"++"                			{return INCR;}
"--"                			{return DECR;}
"<=" 					        {return LE;}
">=" 					        {return GE;}
"==" 					        {return EQ;}
"!=" 					        {return NE;}
"+=" 					        {return PLUS_ASSIGN;}
"-=" 					        {return MINUS_ASSIGN;}
"*=" 					        {return MULT_ASSIGN;}
"/=" 					        {return DIV_ASSIGN;}
"%=" 					        {return MOD_ASSIGN;}
"&=" 					        {return AND_ASSIGN;}
"^=" 					        {return XOR_ASSIGN;}
"|=" 					        {return OR_ASSIGN;}
"&&" 					        {return LOGICAL_AND;}
"||" 					        {return LOGICAL_OR;} 	


int                 			{return INT;}
float               			{return FLOAT;}
if                  			{return IF;}
else                			{return ELSE;}
while               			{return WHILE;}
for                 			{return FOR;}
return              			{return RETURN;}

main                			{return MAIN;}
printf              			{return PRINTF;}
print               			{return PRINT;}
printmat            			{return PRINTMAT;}

matrix              			{return MATRIX;}
".."               		        {return INTERV_OP;}

{ID}                			{strcpy(yylval.nom, yytext); return IDENT;}
{INT}               			{yylval.constante_entiere=atoi(yytext); return C_INT;}
{FLOAT}             			{yylval.constante_flottante=atof(yytext); return C_FLOAT;}
{STR}               			{strcpy(yylval.constante_caractere, yytext); return C_STR;}

{COMMENT}           			{/*Ignore*/;}
{WHITESPACE}        			{/*Ignore*/;}

.                               {fprintf(stderr, "Lexical error, character unknown : \'%c\'\n", yytext[0]);}

%%
