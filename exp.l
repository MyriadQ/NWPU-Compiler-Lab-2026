%{
#include "exp.tab.h"
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

int line_no = 1;

static char *comment_buf = NULL;
static size_t comment_len = 0;
static size_t comment_cap = 0;

static void reset_comment(void);
static void append_comment(const char *text, size_t len);
%}

%option noyywrap
%x BLOCK

digit       [0-9]
integer     {digit}+
identifier  [a-zA-Z_][a-zA-Z0-9_]*

%%

{integer}       { yylval.num = atoi(yytext); return INTEGER; }
"print"         { return PRINT; }
"if"            { return IF;  }
"else"          { return ELSE;}
"while"         { return WHILE; }
"do"            { return DO; }
"for"           { return FOR; }
{identifier}    { yylval.ident = strdup(yytext); return IDENT; }
"//"[^\n]*      { return COMMENT; }
"/*"            { reset_comment(); append_comment(yytext, yyleng); BEGIN(BLOCK); }
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
[ \t]           {             }
"\n"            { line_no++;  }
.               { fprintf(stderr, "Unrecognized character '%c' at line %d\n", yytext[0], line_no); }

<BLOCK>"*/"     { append_comment(yytext, yyleng); reset_comment(); BEGIN(INITIAL); return BLOCK_COMMENT; }
<BLOCK>\n       { append_comment(yytext, yyleng); line_no++; }
<BLOCK>.        { append_comment(yytext, yyleng); }
<BLOCK><<EOF>>  { reset_comment(); BEGIN(INITIAL); return INVALID; }

%%

static void reset_comment(void)
{
    free(comment_buf);
    comment_buf = NULL;
    comment_len = 0;
    comment_cap = 0;
}

static void append_comment(const char *text, size_t len)
{
    size_t needed = comment_len + len + 1;
    char *new_buf;

    if (needed > comment_cap) {
        size_t new_cap = comment_cap == 0 ? needed : comment_cap;

        while (new_cap < needed) {
            new_cap *= 2;
        }

        new_buf = realloc(comment_buf, new_cap);
        if (new_buf == NULL) {
            fprintf(stderr, "out of memory\n");
            exit(EXIT_FAILURE);
        }

        comment_buf = new_buf;
        comment_cap = new_cap;
    }

    memcpy(comment_buf + comment_len, text, len);
    comment_len += len;
    comment_buf[comment_len] = '\0';
}
