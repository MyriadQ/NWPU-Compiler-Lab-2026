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

void dump_buffer(FILE *src){
    fflush(src);
    rewind(src);
    char chunk[4096];
    size_t n;
    while((n = fread(chunk, 1, sizeof(chunk), src)) > 0){
        fwrite(chunk, 1, n, ir_file);
    }
    fclose(src);
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
      char *cond; //i1 register from condition
      FILE *saved_file;// ir_file to restore
      FILE *true_body; //capture true-block (if-else only)
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
        // Defer the br i1 — we don't yet know if ELSE follows.
        // Remember the condition; capture the true-body into a tmpfile.
        $$.cond       = $3;
        $$.l_true     = new_label();
        $$.l_end      = new_label();
        $$.l_false    = NULL;        // allocated lazily in if_else_prefix, we don't know wether else exist yet
        $$.saved_file = ir_file;
        $$.true_body  = NULL;
        ir_file = tmpfile();         // body writes here, not into output.ll, store temporary to check for wether else exist 
    }
    ;

if_else_prefix:
    if_cond '{' program '}' ELSE {
        // True body has been captured into ir_file (a tmpfile).
        // Stash it, allocate l_false, and start a fresh tmpfile for the false body.
        $$ = $1;
        $$.l_false   = new_label();
        $$.true_body = ir_file;
        ir_file = tmpfile();
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
        // Restore the outer ir_file. The current ir_file holds the false body.
        FILE *false_body = ir_file;
        ir_file = $1.saved_file;

        // Now that we know it's an if/else, emit the deferred conditional branch.
        fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                $1.cond, $1.l_true, $1.l_false);

        // True block: label, replay buffered body, jump to end.
        fprintf(ir_file, "%s:\n", $1.l_true);
        dump_buffer($1.true_body);
        fprintf(ir_file, "  br label %%%s\n", $1.l_end);

        // False block: label, replay buffered body, jump to end.
        fprintf(ir_file, "%s:\n", $1.l_false);
        dump_buffer(false_body);
        fprintf(ir_file, "  br label %%%s\n", $1.l_end);

        // Merge.
        fprintf(ir_file, "%s:\n", $1.l_end);

        free($1.l_true);
        free($1.l_false);
        free($1.l_end);
    }
    | if_cond '{' program '}' {
        // if-only: the false target is l_end directly — no dummy block.
        FILE *body = ir_file;
        ir_file = $1.saved_file;

        fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                $1.cond, $1.l_true, $1.l_end);

        fprintf(ir_file, "%s:\n", $1.l_true);
        dump_buffer(body);
        fprintf(ir_file, "  br label %%%s\n", $1.l_end);

        fprintf(ir_file, "%s:\n", $1.l_end);

        free($1.l_true);
        free($1.l_end);
        // $1.l_false is NULL in the if-only path — nothing to free.
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
