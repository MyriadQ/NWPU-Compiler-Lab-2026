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
// function must be top level, outside of main()
FILE *fn_file = NULL; //capture user function definition
FILE *main_buf = NULL; //capture main body code
FILE *actual_output = NULL;  //the actual output.ll written at very end

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
// only used in main
void dump_buffer_to(FILE *src, FILE *dst){
    fflush(src);
    rewind(src);
    char chunk[4096];
    size_t n;
    while((n = fread(chunk, 1, sizeof(chunk), src)) > 0){
        fwrite(chunk, 1, n, dst);
    }
    fclose(src);
}
// if else logic did not change and still use it
void dump_buffer(FILE *src){
    dump_buffer_to(src, ir_file);
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
    char *reg = malloc(strlen(name) + 8);
    sprintf(reg, "%%var_%s", name);
    fprintf(ir_file, "  %s = alloca i32, align 4\n", reg);
    var_entry *new_entry = malloc(sizeof(var_entry));
    new_entry->name = strdup(name);
    new_entry->alloca_reg = reg;
    new_entry->next = sym_table;
    sym_table = new_entry;
    return reg;
}

// symbol table for arrays — tracks all declared arrays and their LLVM register info
typedef struct arr_entry {
    char *name;          // array name
    int  *dims;          // a dynamic array that will hold any dimension size for the desired array e.g. [3,4,5] a 3D array with 5 rows, 4 columns and 3 depths
    int  ndims;          // number of array dimensions e.g. 3
    char *alloca_reg;    // memory location (LLVM register for example %arr_arr)
    struct arr_entry *next;
} arr_entry;
arr_entry *arr_table = NULL;

// saved when entering a function definition, restored on exit to prevent scope bleed
var_entry *saved_sym_table = NULL;
arr_entry *saved_arr_table = NULL;

// we are building LLVM type array string recursively for example dims=[2,3,4] -> "[2 x [3 x [4 x i32]]]" 
void build_type_str(int *dims, int ndims, char *buf) {
    if (ndims == 1) {
        sprintf(buf, "[%d x i32]", dims[0]);
    }
    else {
        char inner[512];
        build_type_str(dims + 1, ndims - 1, inner);  // inner recursion
        sprintf(buf, "[%d x %s]", dims[0], inner);
    }
}

// unified array declaration for any dimensions
void declare_array_nd(const char *name, int *dims, int ndims) {

    // checks if that array is already decalred so as not to overwrite
    for (arr_entry *e = arr_table; e; e = e->next)
        if (strcmp(e->name, name) == 0) return;
    
    // if not then go on with declaration
    char *reg = malloc(strlen(name) + 8);
    sprintf(reg, "%%arr_%s", name);

    // calling build_type_str method
    char type_str[512];
    build_type_str(dims, ndims, type_str);

    fprintf(ir_file, "  %s = alloca %s, align 4\n", reg, type_str);

    arr_entry *e = malloc(sizeof(arr_entry));
    e->name      = strdup(name);
    e->dims      = malloc(sizeof(int) * ndims);
    memcpy(e->dims, dims, sizeof(int) * ndims);
    e->ndims     = ndims;
    e->alloca_reg = reg;
    e->next      = arr_table;
    arr_table    = e;
}

// getting array allocated register
char* get_arr_alloca(const char *name) {
    for (arr_entry *e = arr_table; e; e = e->next)
        if (strcmp(e->name, name) == 0)
            return e->alloca_reg;
    fprintf(stderr, "Undeclared array: %s\n", name);
    return NULL;
}

// llvm getelementptr for any dimensions
void build_gep(char *ptr_reg, const char *arr_name, char **indices) {

    arr_entry *found = NULL;
    for (arr_entry *e = arr_table; e; e = e->next)
        if (strcmp(e->name, arr_name) == 0) { found = e; break; }
    if (!found) return;

    char type_str[512];
    build_type_str(found->dims, found->ndims, type_str);

    fprintf(ir_file, "  %s = getelementptr %s, %s* %s, i32 0",
            ptr_reg, type_str, type_str, found->alloca_reg);

    for (int i = 0; i < found->ndims; i++)
        fprintf(ir_file, ", i32 %s", indices[i]);

    fprintf(ir_file, "\n");
}

// symbol table for functions — tracks declared function names and their parameter counts
// so that call sites can be validated and the correct LLVM call IR can be emitted
typedef struct func_entry {
    char *name;      // function name
    int   n_params;  // number of parameters (always 0 with no argument)
    struct func_entry *next;
} func_entry;
func_entry *func_table = NULL;

// prepend a new function entry to func_table; called once per function definition
void register_function(const char *name, int n_params) {
    func_entry *e = malloc(sizeof(func_entry));
    e->name     = strdup(name);
    e->n_params = n_params;
    e->next     = func_table;
    func_table  = e;
}

#define MAX_NEST 64
char *stack_cond[MAX_NEST];
char *stack_body[MAX_NEST];
char *stack_end[MAX_NEST];
char *stack_update[MAX_NEST];
int stack_top = 0;

void push_labels(char *c, char *b, char *e) {
    stack_cond[stack_top] = c;
    stack_body[stack_top] = b;
    stack_end[stack_top]  = e;
    stack_top++;
}

void peek_labels(char **c, char **b, char **e) {
    *c = stack_cond[stack_top - 1];
    *b = stack_body[stack_top - 1];
    *e = stack_end[stack_top - 1];
}

void pop_labels(char **c, char **b, char **e) {
    stack_top--;
    *c = stack_cond[stack_top];
    *b = stack_body[stack_top];
    *e = stack_end[stack_top];
}

void push_for_labels(char *c, char *u, char *b, char *e) {
    stack_cond[stack_top]   = c;
    stack_update[stack_top] = u;
    stack_body[stack_top]   = b;
    stack_end[stack_top]    = e;
    stack_top++;
}

void peek_for_labels(char **c, char **u, char **b, char **e) {
    *c = stack_cond[stack_top - 1];
    *u = stack_update[stack_top - 1];
    *b = stack_body[stack_top - 1];
    *e = stack_end[stack_top - 1];
}

void pop_for_labels(char **c, char **u, char **b, char **e) {
    stack_top--;
    *c = stack_cond[stack_top];
    *u = stack_update[stack_top];
    *b = stack_body[stack_top];
    *e = stack_end[stack_top];
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
      char *cond;//i1 register from condition
      FILE *saved_file;// ir_file to restore
      FILE *true_body;//capture true-block (if-else only)
    } labels;
    struct {                 // for dim_list rule
        int *sizes;          // array of dimension sizes
        int  count;          // how many dimensions
    } dimlist;
    struct {                 // for idx_list rule
        char **regs;         // array of index registers
        int    count;        // how many indices
    } idxlist;
}

%token PRINT
%token INTEGER
%token IDENT
%token IF
%token ELSE
%token WHILE
%token DO
%token FOR
%token EQ
%token NE
%token GE
%token LE
%token AND
%token OR
%token NOT
%token INT_TYPE
%token RETURN
%expect 1 // 1 from if/else dangling-else ambiguity
%left OR
%left AND
%right NOT
%nonassoc '>' '<' EQ NE GE LE
%left '+' '-'
%left '*' '/'
%nonassoc UMINUS

%type<reg> expr
%type<reg> stmt
%type<reg> cond
%type<num> INTEGER
%type<ident> IDENT
%type<labels> if_cond
%type<labels> if_else_prefix
%type<dimlist> dim_list
%type<idxlist> idx_list


%%

program:
    program stmt
    | program func_def
    | /* empty */
    ;

stmts:
      stmts stmt
    | /* empty */
    ;

func_def:
    INT_TYPE IDENT '(' ')'
    {
        /* mid-rule: emit function header into fn_file and isolate scope */
        fprintf(fn_file, "\ndefine i32 @%s() {\nentry:\n", $2);
        saved_sym_table = sym_table;  sym_table = NULL;  // snapshot and clear var table
        saved_arr_table = arr_table;  arr_table = NULL;  // snapshot and clear arr table
        ir_file = fn_file;                               // redirect IR into fn_file
        register_function($2, 0);
    }
    '{' stmts '}'
    {
        fprintf(ir_file, "  ret i32 0\n}\n");   // fallthrough return
        ir_file   = main_buf;                   // restore IR to main body buffer
        sym_table = saved_sym_table;            // restore var scope
        arr_table = saved_arr_table;            // restore arr scope
        free($2);
    }
    ;

if_cond:
    IF '(' cond ')' {
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
dim_list:
    '[' INTEGER ']' {
        $$.sizes    = malloc(sizeof(int) * 8);
        $$.sizes[0] = $2;
        $$.count    = 1;
    }
    | dim_list '[' INTEGER ']' {
        $$ = $1;
        $$.sizes[$$.count] = $3;
        $$.count++;
    }
    ;
idx_list:
    '[' expr ']' {
        $$.regs    = malloc(sizeof(char*) * 8);
        $$.regs[0] = $2;
        $$.count   = 1;
    }
    | idx_list '[' expr ']' {
        $$ = $1;
        $$.regs[$$.count] = $3;
        $$.count++;
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
    | INT_TYPE IDENT '=' expr ';' {
        // explicit variable declaration with initializer: int a = 5;
        // get_var_alloca allocates the variable if not yet declared, then store the value
        char *var_alloca = get_var_alloca($2);
        fprintf(ir_file, "  store i32 %s, i32* %s, align 4\n", $4, var_alloca);
        $$ = $4;
        free($2);
    }
    | RETURN expr ';' {
        fprintf(ir_file, "  ret i32 %s\n", $2);
        char *dead = new_label();
        fprintf(ir_file, "%s:\n", dead);  // dead block keeps IR well-formed after ret
        $$ = NULL;
    }
    | IDENT '(' ')' ';' {
        // call a function as a statement, discarding return value
        fprintf(ir_file, "  call void @%s()\n", $1);
        free($1);
        $$ = NULL;
    }
    | INT_TYPE IDENT dim_list ';' {
        declare_array_nd($2, $3.sizes, $3.count);
        free($2);
        free($3.sizes);
        $$ = NULL;
    }
    | IDENT idx_list '=' expr ';' {
        char *ptr = new_tmp();
        build_gep(ptr, $1, $2.regs);
        fprintf(ir_file, "  store i32 %s, i32* %s, align 4\n", $4, ptr);
        free($1);
        free($2.regs);
        $$ = ptr;
    }
    | WHILE
      '('
      {
          char *cond_label = new_label();
          char *body_label = new_label();
          char *end_label  = new_label();
          fprintf(ir_file, "  br label %%%s\n", cond_label);
          fprintf(ir_file, "%s:\n", cond_label);
          push_labels(cond_label, body_label, end_label);
      }
      cond ')'
      {
          char *cond_label, *body_label, *end_label;
          peek_labels(&cond_label, &body_label, &end_label);
          fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                  $4, body_label, end_label);
          fprintf(ir_file, "%s:\n", body_label);
      }
      '{' stmts '}'
      {
          char *cond_label, *body_label, *end_label;
          pop_labels(&cond_label, &body_label, &end_label);
          fprintf(ir_file, "  br label %%%s\n", cond_label);
          fprintf(ir_file, "%s:\n", end_label);
          $$ = NULL;
      }
    | FOR '(' IDENT '=' expr ';'
      {
          char *var_alloca = get_var_alloca($3);
          fprintf(ir_file, "  store i32 %s, i32* %s, align 4\n", $5, var_alloca);

          char *cond_label   = new_label();
          char *update_label = new_label();
          char *body_label   = new_label();
          char *end_label    = new_label();

          fprintf(ir_file, "  br label %%%s\n", cond_label);
          fprintf(ir_file, "%s:\n", cond_label);
          push_for_labels(cond_label, update_label, body_label, end_label);
          free($3);
      }
      cond ';'
      {
          char *cond_label, *update_label, *body_label, *end_label;
          peek_for_labels(&cond_label, &update_label, &body_label, &end_label);
          fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                  $8, body_label, end_label);
          fprintf(ir_file, "%s:\n", update_label);
      }
      IDENT '=' expr ')'
      {
          char *var_alloca = get_var_alloca($11);
          fprintf(ir_file, "  store i32 %s, i32* %s, align 4\n", $13, var_alloca);
          char *cond_label, *update_label, *body_label, *end_label;
          peek_for_labels(&cond_label, &update_label, &body_label, &end_label);
          fprintf(ir_file, "  br label %%%s\n", cond_label);
          fprintf(ir_file, "%s:\n", body_label);
          free($11);
      }
      '{' stmts '}'
      {
          char *cond_label, *update_label, *body_label, *end_label;
          pop_for_labels(&cond_label, &update_label, &body_label, &end_label);
          fprintf(ir_file, "  br label %%%s\n", update_label);
          fprintf(ir_file, "%s:\n", end_label);
          $$ = NULL;
      }
    | DO
      {
          char *body_label = new_label();
          char *cond_label = new_label();
          char *end_label  = new_label();
          fprintf(ir_file, "  br label %%%s\n", body_label);
          fprintf(ir_file, "%s:\n", body_label);
          push_labels(cond_label, body_label, end_label);
      }
      '{' stmts '}'
      {
          char *cond_label, *body_label, *end_label;
          peek_labels(&cond_label, &body_label, &end_label);
          fprintf(ir_file, "  br label %%%s\n", cond_label);
          fprintf(ir_file, "%s:\n", cond_label);
      }
      WHILE '(' cond ')' ';'
      {
          char *cond_label, *body_label, *end_label;
          pop_labels(&cond_label, &body_label, &end_label);
          fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                  $9, body_label, end_label);
          fprintf(ir_file, "%s:\n", end_label);
          $$ = NULL;
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

cond:
    expr '<' expr
    {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp slt i32 %s, %s\n", $$, $1, $3);
    }
    | expr '>' expr
    {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp sgt i32 %s, %s\n", $$, $1, $3);
    }
    | expr LE expr
    {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp sle i32 %s, %s\n", $$, $1, $3);
    }
    | expr GE expr
    {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp sge i32 %s, %s\n", $$, $1, $3);
    }
    | expr EQ expr
    {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp eq i32 %s, %s\n", $$, $1, $3);
    }
    | expr NE expr
    {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp ne i32 %s, %s\n", $$, $1, $3);
    }
    | cond AND cond
    {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = and i1 %s, %s\n", $$, $1, $3);
    }
    | cond OR cond
    {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = or i1 %s, %s\n", $$, $1, $3);
    }
    | NOT cond
    {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = xor i1 %s, true\n", $$, $2);
    }
    | '(' cond ')'
    {
        $$ = $2;
    }
    | expr
    {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = icmp ne i32 %s, 0\n", $$, $1);
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
    | IDENT idx_list {
        char *ptr = new_tmp();
        char *val = new_tmp();
        build_gep(ptr, $1, $2.regs);
        fprintf(ir_file, "  %s = load i32, i32* %s, align 4\n", val, ptr);
        free($1);
        free($2.regs);
        $$ = val;
    }
    | IDENT '(' ')' {
        // call a function and capture its i32 return value as an expression
        $$ = new_tmp();
        fprintf(ir_file, "  %s = call i32 @%s()\n", $$, $1);
        free($1);
    }
    ;

%%

void yyerror(const char *s) {
    fprintf(stderr, "Error at line %d: %s\n", line_no, s);
}

int main(int argc, char **argv) {
    // open the real output file — nothing is written here during parsing
    actual_output = fopen("output.ll", "w");
    if (!actual_output) { perror("Cannot open output.ll"); return 1; }

    // module-level declarations go directly to output.ll (always first, order is fixed)
    ir_file = actual_output;
    fprintf(ir_file, "; ModuleID = 'expr_compiler'\n");
    fprintf(ir_file, "target triple = \"x86_64-unknown-linux-gnu\"\n");
    declare_printf();

    // set up separate buffers: fn_file for user functions, main_buf for @main body
    fn_file  = tmpfile();
    main_buf = tmpfile();
    ir_file  = main_buf;  // all main-body IR goes here by default during parsing

    yyparse();  // entire compilation happens here; func_def redirects ir_file to fn_file as needed

    // flush in correct order: user functions must appear before @main in LLVM IR
    dump_buffer_to(fn_file, actual_output);
    fprintf(actual_output, "\ndefine i32 @main() {\n");
    fprintf(actual_output, "entry:\n");
    dump_buffer_to(main_buf, actual_output);
    fprintf(actual_output, "  ret i32 0\n");
    fprintf(actual_output, "}\n");

    fclose(actual_output);
    return 0;
}
