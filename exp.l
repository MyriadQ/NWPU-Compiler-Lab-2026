%{
#include "exp.tab.h"
#include <stdio.h>

int line_no = 1;
%}

%option noyywrap

digit       [0-9]
integer     {digit}+
identifier  [a-zA-Z_][a-zA-Z0-9_]*

%%

{integer}       { yylval.num = atoi(yytext); return INTEGER; }
"print"         { return PRINT;    }
"if"            { return IF;       } 
"else"          { return ELSE;     }
"while"         { return WHILE;    }
"do"            { return DO;       }
"for"           { return FOR;      }
"int"           { return INT_TYPE; }
{identifier}    { yylval.ident = strdup(yytext); return IDENT; }
"="             { return '='; }
";"             { return ';'; }
"+"             { return '+'; }
"-"             { return '-'; }
"*"             { return '*'; }
"/"             { return '/'; }
"("             { return '('; }
")"             { return ')'; }
">"             { return '>'; }
"<"             { return '<'; }
"=="            { return EQ;  }
"!="            { return NE;  }
">="            { return GE;  }
"<="            { return LE;  }
"&&"            { return AND; }
"||"            { return OR;  }
"!"             { return NOT; }
"{"             { return '{'; }
"}"             { return '}'; }
"["             { return '['; }
"]"             { return ']'; }
"//".*          {              }
"/*"([^*]|\*+[^*/])*\*+"/"  {   }
[ \t]           {             }
"\n"            { line_no++;  }
.               { fprintf(stderr, "Unrecognized character '%c' at line %d\n", yytext[0], line_no); }


%%