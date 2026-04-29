%{
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

extern int yylex();
extern int line_no;
void yyerror(const char *s);

int tmp_counter = 0;
int label_counter = 0;
FILE *ir_file;

char* new_tmp() {
    char *name = malloc(16);
    sprintf(name, "%%t%d", tmp_counter++);
    return name;
}

char* new_label() {
    char *name = malloc(16);
    sprintf(name, "L%d", label_counter++); // No % here!
    return name;
}

void declare_printf() {
    fprintf(ir_file, "declare i32 @printf(i8*, ...)\n");
    fprintf(ir_file, "@.str = constant [4 x i8] c\"%%d\\0A\\00\"\n");
}

void gen_print_int(const char *value_reg) {
    fprintf(ir_file, "  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %s)\n", value_reg);
}

typedef struct var_entry {
    char *name;
    char *alloca_reg;
    struct var_entry *next;
} var_entry;
var_entry *sym_table = NULL;

char* get_var_alloca(const char *name) {
    for (var_entry *e = sym_table; e; e = e->next) {
        if (strcmp(e->name, name) == 0)
            return e->alloca_reg;
    }
    char *reg = malloc(16);
    sprintf(reg, "%%var_%s", name);
    fprintf(ir_file, "  %s = alloca i32, align 4\n", reg);
    var_entry *new_entry = malloc(sizeof(var_entry));
    new_entry->name = strdup(name);
    new_entry->alloca_reg = reg;
    new_entry->next = sym_table;
    sym_table = new_entry;
    return reg;
}
%}

%union {
    int num;
    char *ident;
    char *reg;
    struct{
      char *l_true;
      char *l_false;
      char *l_end;
    } labels;
}

%token PRINT
%token INTEGER
%token IDENT
%token IF
%token ELSE
%token EQ
%token NE
%token GE
%token LE
%nonassoc '>' '<' EQ NE GE LE
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%type<reg> expr
%type<reg> stmt
%type<num> INTEGER
%type<ident> IDENT

%type<labels> if_cond
%type<labels> if_else_prefix

%%

program:
    program stmt
    | /* empty */
    ;
if_cond:
    IF '(' expr ')' {
        $$.l_true = new_label();
        $$.l_false = new_label();
        $$.l_end = new_label();

        // Branch to true or false blocks
        fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n", $3, $$.l_true, $$.l_false);

        // Start the true block so the next 'program' writes here
        fprintf(ir_file, "%s:\n", $$.l_true);
    }
    ;

if_else_prefix:
    if_cond '{' program '}' ELSE {
        // Jump to the end label after the true block finishes
        fprintf(ir_file, "  br label %%%s\n", $1.l_end);

        // Start the false block so the ELSE 'program' writes here
        fprintf(ir_file, "%s:\n", $1.l_false);

        // Pass the labels up to the final rule
        $$ = $1;
    }
    ;

stmt:
    IDENT '=' expr ';' {
        char *var_alloca = get_var_alloca($1);
        fprintf(ir_file, "  store i32 %s, i32* %s, align 4\n", $3, var_alloca);
        $$ = $3;
        free($1);
    }
    | PRINT expr ';' {
        gen_print_int($2);
        $$ = $2;
    }
    | if_else_prefix '{' program '}' {
        // Jump to the end label after the false block finishes
        fprintf(ir_file, "  br label %%%s\n", $1.l_end);

        // Create the final merge point
        fprintf(ir_file, "%s:\n", $1.l_end);

        // Free allocated label strings
        free($1.l_true);
        free($1.l_false);
        free($1.l_end);
    }
    | if_cond '{' program '}' {
        // 1. Close the 'true' block by jumping to the end
        fprintf(ir_file, "  br label %%%s\n", $1.l_end);

        // 2. In an 'if-only', the 'false' branch and the 'end' 
        
        fprintf(ir_file, "%s:\n", $1.l_false);
        fprintf(ir_file, "  br label %%%s\n", $1.l_end);
        fprintf(ir_file, "%s:\n", $1.l_end);

        // 3. Clean up memory
        free($1.l_true);
        free($1.l_false);
        free($1.l_end);
    }
    ;

expr:
    INTEGER {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = add i32 %d, 0\n", $$, $1);
    }
    | IDENT {
        char *var_alloca = get_var_alloca($1);
        $$ = new_tmp();
        fprintf(ir_file, "  %s = load i32, i32* %s, align 4\n", $$, var_alloca);
        free($1);
    }
    | '-' expr %prec UMINUS {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = sub i32 0, %s\n", $$, $2);
    }
    | expr '+' expr {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = add i32 %s, %s\n", $$, $1, $3);
    }
    | expr '-' expr {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = sub i32 %s, %s\n", $$, $1, $3);
    }
    | expr '*' expr {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = mul i32 %s, %s\n", $$, $1, $3);
    }
    | expr '/' expr {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = sdiv i32 %s, %s\n", $$, $1, $3);
    }
    | '(' expr ')' {
        $$ = $2;
    }
    | expr '>' expr {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp sgt i32 %s, %s\n", $$, $1, $3);
    }
    | expr '<' expr {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp slt i32 %s, %s\n", $$, $1, $3);
    }
    | expr EQ expr {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp eq i32 %s, %s\n", $$, $1, $3);
    }
    | expr NE expr {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp ne i32 %s, %s\n", $$, $1, $3);
    }
    | expr GE expr {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp sge i32 %s, %s\n", $$, $1, $3);
    }
    | expr LE expr {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp sle i32 %s, %s\n", $$, $1, $3);
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s\n", line_no, s);
}

int main(int argc, char **argv) {
    ir_file = fopen("output.ll", "w");
    if (!ir_file) {
        perror("Cannot open output.ll");
        return 1;
    }
    fprintf(ir_file, "; ModuleID = 'expr_compiler'\n");
    fprintf(ir_file, "target triple = \"x86_64-unknown-linux-gnu\"\n");
    declare_printf();
    fprintf(ir_file, "\ndefine i32 @main() {\n");

    yyparse();

    fprintf(ir_file, "  ret i32 0\n");
    fprintf(ir_file, "}\n");
    fclose(ir_file);
    return 0;
}
