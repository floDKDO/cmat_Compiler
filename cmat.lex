%{
#include "define.h"

%}

ID                  [a-zA-Z][a-zA-Z0-9]*
COMMENT             "//".*|\/\*([^\*]|\*[^\/])*\*\/
INT                 0|[1-9][0-9]*
FLOAT               ([0-9]+\.|\.[0-9])[0-9]*([eE][+-]?[0-9]+)?(f|F)?
STR                 \"([^\"\\]|\\.)*\"

%%

\;                  {return SEMICOL;}
,                   {return COMMA;}

=                   {return EQUAL;}
\+                  {return PLUS;}
\-                  {return MINUS;}
\*                  {return MULT;}
\/                  {return DIV;}
"++"                {return INCR;}
"--"                {return DECR;}

int                 {return INT;}
float               {return FLOAT;}
if                  {return IF;}
else                {return ELSE;}
while               {return WHILE;}
for                 {return FOR;}
return              {return RETURN;}

\(                  {return O_PAREN;}
\)                  {return C_PAREN;}
main                {return MAIN;}
printf              {return PRINTF;}
print               {return PRINT;}
printmat            {return PRINTMAT;}

matrix              {return MATRIX;}
~                   {return TILDE;}
\[                  {return O_CROCH;}
\]                  {return C_CROCH;}
".."                {return INTERV;}

{ID}                {return IDENT;}
{INT}               {return C_INT;}
{FLOAT}             {return C_FLOAT;}
{STR}               {return C_STR;}

{COMMENT}           {/*Ignore*/; }

%%
