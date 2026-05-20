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
/* ── [FUNC 1/14] Output buffers ────────────────────────────────────────────
   fn_file:       accumulates all user-defined function IR during parsing
   main_buf:      accumulates @main body IR during parsing
   actual_output: the real output.ll; nothing written here until after yyparse()
   IR is routed through ir_file which switches between these at runtime.
   ────────────────────────────────────────────────────────────────────────── */
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
/* ── [FUNC 2/14] dump_buffer_to / dump_buffer ──────────────────────────────
   Pour a scratch-pad tmpfile into a destination file.
   dump_buffer_to: fflush → rewind → fread/fwrite loop → fclose (used in main)
   dump_buffer:    thin wrapper that always targets the current ir_file
   Used by: main() for final assembly, if/else rules for body replay.
   ────────────────────────────────────────────────────────────────────────── */
// only used in main, dump scratch pad files into destination file
void dump_buffer_to(FILE *src, FILE *dst){
    fflush(src); //make sure nothing stuck in memory
    rewind(src); //go back to beginning of scratch pad
    char chunk[4096];
    size_t n;
    while((n = fread(chunk, 1, sizeof(chunk), src)) > 0){
        fwrite(chunk, 1, n, dst); //read a chunk, write it to dst repeat til emmpty
    }
    fclose(src); //dispose the scratch
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

/* ── [FUNC 3/14] Scope isolation storage ───────────────────────────────────
   When func_def mid-rule fires, @main's sym/arr tables are parked here and
   sym_table / arr_table are cleared to give the function a fresh scope.
   Restored in the func_def closing action after the body is fully parsed.
   ────────────────────────────────────────────────────────────────────────── */
// saved when entering a function definition, restored on exit to prevent scope bleed
var_entry *saved_sym_table = NULL;
arr_entry *saved_arr_table = NULL;

/* ── [FUNC 4/14] Parameter staging array ───────────────────────────────────
   Global notepad filled by param_list as each "int name" token is scanned.
   func_def mid-rule reads and frees these to build the LLVM signature string
   and emit alloca+store for each param before the body is parsed.
   Reset to 0 at the start of every param_list (non-empty) or param_list_opt (empty).
   ────────────────────────────────────────────────────────────────────────── */
// temporary storage for parameter names collected during param_list parsing.
// param_list rules push names here; the func_def mid-rule action reads and consumes them.
// MAX_PARAMS caps how many parameters a single function may declare.
#define MAX_PARAMS 16
char *pending_params[MAX_PARAMS];  // strdup'd parameter name strings, e.g. "a", "b"
int   pending_param_count = 0;     // how many entries are currently in pending_params

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

/* ── [FUNC 5/14] Function symbol table ─────────────────────────────────────
   func_entry / func_table: linked list of every declared function and its
   parameter count.  register_function() appends one entry per func_def.
   Used at call sites to look up the callee and emit the correct LLVM call IR.
   ────────────────────────────────────────────────────────────────────────── */
// symbol table for functions — tracks declared function names and their parameter counts
// so that call sites can be validated and the correct LLVM call IR can be emitted
typedef struct func_entry {
    char *name;      // function name
    int   n_params;  // number of parameters (always 0 with no argument)
    struct func_entry *next;
} func_entry;
func_entry *func_table = NULL;

/* ── [FUNC 6/14] register_function ─────────────────────────────────────────
   Called once at the end of the func_def mid-rule action (after param setup).
   Prepends a new func_entry to func_table so call sites can look it up.
   ────────────────────────────────────────────────────────────────────────── */
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
char *stack_continue[MAX_NEST]; // continue target: cond for while/do-while, update for for
int stack_top = 0;

void push_labels(char *c, char *b, char *e) {
    stack_cond[stack_top]     = c;
    stack_body[stack_top]     = b;
    stack_end[stack_top]      = e;
    stack_continue[stack_top] = c; // continue → re-check condition
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
    stack_cond[stack_top]     = c;
    stack_update[stack_top]   = u;
    stack_body[stack_top]     = b;
    stack_end[stack_top]      = e;
    stack_continue[stack_top] = u; // continue → run update then re-check condition
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
    /* ── [IF-ELSE 1/5] labels struct ─────────────────────────────────────────
       State bag passed between if_cond → if_else_prefix → stmt final actions.
       cond:       i1 register from the condition (e.g. %t2)
       l_true:     label for the true block (allocated in if_cond)
       l_false:    label for the false block (NULL until ELSE is confirmed)
       l_end:      merge label after both branches (allocated in if_cond) -> the block that the next instruction lives cuz every br have to jump to a label
       saved_file: the ir_file active before the if — restored in final action
       true_body:  tmpfile holding true-body IR (stashed in if_else_prefix only)
       ────────────────────────────────────────────────────────────────────── */
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
    struct {                 // for short-circuit mid-rule
        char *sc_slot;       // alloca register holding i1 result
        char *merge_label;   // label to jump to after both sides
    } scdata;
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
%token BREAK
%token CONTINUE
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
%type<scdata> sc_and_mid
%type<scdata> sc_or_mid
// arg_list builds a comma-separated LLVM argument string (e.g. "i32 %t0, i32 %t1")
%type<reg> arg_list


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

/* ── [FUNC 7/14] param_list_opt / param_list ────────────────────────────────
   Grammar rules that fill pending_params[] before func_def's mid-rule fires.
   param_list_opt: handles zero params (resets count) or delegates to param_list.
   param_list:     first INT_TYPE IDENT resets + pushes; each subsequent one appends.
   Why reset inside param_list too: if non-empty, param_list_opt's empty branch
   never fires, so the count from the previous function would carry over.
   ────────────────────────────────────────────────────────────────────────── */
// These rules collect the declared parameter names into pending_params[] as the parser
// reads the function signature, e.g. int add(int a, int b).
// param_list_opt wraps param_list so that zero-parameter functions still reset the count.
param_list_opt: //either list is empty - in this case reset param count, or have a param list
    // having reset in empty block solve the issue of having 2 function f1(int a) and f2(int b) 
    // when we reach f2 the count is still 1(from the f1) and it will take param_list without resetting -> this lead to compiler misunderstood it to have 2 param
      /* empty */ { pending_param_count = 0; }  
    | param_list
    ;

param_list:
      // first parameter: reset counter and push the name
      INT_TYPE IDENT {
          pending_param_count = 0;
          pending_params[pending_param_count++] = strdup($2);//make a fresh copy of the identifier to store in pending_param[]
          free($2); //release the original that lexer allocated -> we only use the copy from now
      }
      // each additional parameter: just push the name (counter is already live)
    | param_list ',' INT_TYPE IDENT {
          pending_params[pending_param_count++] = strdup($4);
          free($4);
      }
    ;

/* ── [FUNC 8/14] func_def rule ──────────────────────────────────────────────
   The single rule that compiles any function definition.
   Mid-rule action (fires BEFORE '{' stmts '}'):
     A) Build LLVM signature string from pending_params[]
     B) Write "define i32 @name(...) { entry:" directly to fn_file
     C) Save+clear sym/arr tables for scope isolation; redirect ir_file → fn_file
     D) Alloca+store each param into a writable stack slot; register in sym_table
     E) register_function() records the function for call-site use
   Closing action (fires AFTER '{' stmts '}'):
     - Emit fallthrough "ret i32 0\n}" (dead if explicit return already exists)
     - Restore ir_file → main_buf and sym/arr tables to @main's versions
   ────────────────────────────────────────────────────────────────────────── */
func_def:
    INT_TYPE IDENT '(' param_list_opt ')'
    {
        //The goal is to build a string like "i32 %param_a, i32 %param_b" that gets inserted into the LLVM function header.
        char sig[512] = "";
        for (int i = 0; i < pending_param_count; i++) {
            if (i > 0) strcat(sig, ", ");
            char part[64];
            sprintf(part, "i32 %%param_%s", pending_params[i]);  // %% → literal % in output
            strcat(sig, part);
        }
        //This is the header of the function aka int add(int a, int b) but in LLVM language
        fprintf(fn_file, "\ndefine i32 @%s(%s) {\nentry:\n", $2, sig);

        // isolate scope — same as no-arg version
        // saving the main symbol table -> then set current sym_table to use with function
        saved_sym_table = sym_table;  sym_table = NULL; 
        saved_arr_table = arr_table;  arr_table = NULL;
        ir_file = fn_file; //redirect the ir_file into function file, which will start writing the body of function in LLVM

        // for each parameter: alloca a stack slot, store the incoming value, register in sym_table
        // this lets the body treat parameters exactly like local variables (load/store via get_var_alloca)
        // LLVM parameters like %param_a are SSA values (cannot be reassigned directly) -> solution is to create stack slot for each param
        for (int i = 0; i < pending_param_count; i++) {
            //create a register name for each stack slot
            char *reg = malloc(strlen(pending_params[i]) + 8);
            sprintf(reg, "%%var_%s", pending_params[i]);
            // allocate and store the parameter
            fprintf(ir_file, "  %s = alloca i32, align 4\n", reg);
            fprintf(ir_file, "  store i32 %%param_%s, i32* %s, align 4\n",
                    pending_params[i], reg);
            //This part simply register the name to the sym_table
            var_entry *e = malloc(sizeof(var_entry));
            e->name       = strdup(pending_params[i]);
            e->alloca_reg = reg;
            e->next       = sym_table;
            sym_table     = e;
            free(pending_params[i]);  // done with this name; it now lives in sym_table
        }
        register_function($2, pending_param_count);
    }
    '{' stmts '}'
    //The below code open fires after stmts means that the whole function body is done
    {
        //if the function does have return -> create a dead block and store the return to satisfy LLVM rule whereas each block must have a terminator
        fprintf(ir_file, "  ret i32 0\n}\n");   // fallthrough return (dead if explicit return exists) -> line 481
        //During the entire function body, ir_file was pointing at fn_file. 
        // This line switches it back to main_buf.
        ir_file   = main_buf; 
        //restore the sym_table for main since function is done                 
        sym_table = saved_sym_table;          
        arr_table = saved_arr_table;            
        free($2); //this is the function name string -> free since we finished function
    }
    ;

/* ── [IF-ELSE 2/5] if_cond rule ─────────────────────────────────────────────
   Fires as soon as IF '(' cond ')' is reduced — before any body is parsed.
   Allocates l_true and l_end (needed regardless of ELSE), leaves l_false NULL.
   Parks the current ir_file into saved_file, then redirects ir_file to a fresh
   tmpfile so the true body is captured there instead of going to the real output.
   The deferred br i1 is NOT written yet — we don't know if ELSE follows.
   ────────────────────────────────────────────────────────────────────────── */
if_cond:
    IF '(' cond ')' {
        // Defer the br i1 — we don't yet know if ELSE follows.
        // Remember the condition; capture the true-body into a tmpfile.
        $$.cond       = $3; //cond
        $$.l_true     = new_label();
        $$.l_end      = new_label();
        $$.l_false    = NULL;        // allocated lazily in if_else_prefix, we don't know wether else exist yet
        $$.saved_file = ir_file;
        $$.true_body  = NULL;
        ir_file = tmpfile();         // body writes here, not into output.ll, store temporary to check for wether else exist 
    }
    ;

/* ── [IF-ELSE 3/5] if_else_prefix rule ──────────────────────────────────────
   Fires only when ELSE follows the closing '}' of the true body.
   Copies all fields from if_cond ($1 → $$), then:
     - Allocates l_false now that the else branch is confirmed
     - Stashes the current ir_file (body_tmp1, the true-body scratch pad) into true_body
     - Opens a second tmpfile for the false body; redirects ir_file to it
   If no ELSE token appears, Bison takes the if_cond stmt path instead (IF-ELSE 5/5)
   and this rule never fires.
   ────────────────────────────────────────────────────────────────────────── */
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

/* ── [FUNC 9/14] arg_list rule ──────────────────────────────────────────────
   Builds the LLVM argument string for call instructions, e.g. "i32 %t0, i32 %t1".
   Left-recursive: first expr creates initial string; each ',' appends to it.
   The accumulated string is passed up via $$ and spliced into stmt/expr call rules.
   Nested calls (f(g(x), y)) work because inner calls fully reduce before arg_list builds.
   ────────────────────────────────────────────────────────────────────────── */
// arg_list builds the LLVM argument string that gets spliced directly into a call instruction.
// Goal: turn the arguments of e.g. add(3, 4) into the string "i32 %t0, i32 %t1" so the final
// emitted IR is:  call i32 @add(i32 %t0, i32 %t1)
//
// The rule is left-recursive: the first argument creates the initial string, then each additional
// comma fires the second alternative which appends to it. The old string is freed each time
// because $$ is a brand new allocation that replaces it.
//
// Nested calls like f(g(x), y) work naturally — g(x) is an expr that fully reduces to a
// single %tN register BEFORE f's arg_list ever starts building, so there is no ordering issue.
arg_list:
      // First (or only) argument: wrap the %tN register in its LLVM type to get e.g. "i32 %t0".
      expr {
          $$ = malloc(strlen($1) + 8);
          sprintf($$, "i32 %s", $1);
      }
      // Each additional argument: concatenate ", i32 %tN" onto the running string.
      // $1 = the string built so far, $3 = register from the new expr.
      // free($1) because $$ is a fresh allocation that fully replaces the old string.
    | arg_list ',' expr {
          $$ = malloc(strlen($1) + strlen($3) + 16);
          sprintf($$, "%s, i32 %s", $1, $3);
          free($1);
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
    /* ── [FUNC 10/14] return statement ───────────────────────────────────────
       Emits "ret i32 %tN" then immediately opens a dead label.
       The dead label absorbs the unconditional "ret i32 0" that func_def's
       closing action always emits — without it two terminators would share a
       block, which LLVM rejects.
       ────────────────────────────────────────────────────────────────────── */
    | RETURN expr ';' {
        fprintf(ir_file, "  ret i32 %s\n", $2); //ret is LLVM way of ending a function aka terminator
        char *dead = new_label(); //dead label is used to solve the problem of function return
        fprintf(ir_file, "%s:\n", dead);  // dead block keeps IR well-formed after ret
        $$ = NULL;
    }
    /* ── [FUNC 11/14] Statement calls (no-arg and with-arg) ──────────────────
       Called for side effects only — return value is discarded ($$ = NULL).
       Both variants still emit "call i32" (not "call void") because the callee
       is declared as "define i32"; a type mismatch would make lli reject the IR.
       No-arg:   IDENT '(' ')' ';'
       With-arg: IDENT '(' arg_list ')' ';'  — arg_list builds the argument string
       ────────────────────────────────────────────────────────────────────── */
    // Statement call with no arguments e.g. reset();
    // The return value is intentionally discarded — we call the function for its side effects only.
    // $$ = NULL because there is no value to pass up the parse tree.
    // Note: we still emit "call i32", not "call void", because the callee is declared as
    // "define i32". A type mismatch in the call would make lli reject the IR.
    | IDENT '(' ')' ';' {
        fprintf(ir_file, "  call i32 @%s()\n", $1);
        free($1);
        $$ = NULL;
    }
    // Statement call with arguments e.g. printSum(10, 20);
    // $3 is the complete LLVM argument string assembled by arg_list e.g. "i32 %t0, i32 %t1".
    // Again, return value is discarded ($$ = NULL) but "call i32" is still used — not "call void" —
    // because the return type must match the callee's declaration, regardless of whether we use it.
    | IDENT '(' arg_list ')' ';' {
        fprintf(ir_file, "  call i32 @%s(%s)\n", $1, $3);
        free($1);
        free($3);  // arg string has been spliced into the IR; no longer needed
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
    | BREAK ';' {
        fprintf(ir_file, "  br label %%%s\n", stack_end[stack_top - 1]);
        char *dead = new_label();
        fprintf(ir_file, "%s:\n", dead);
        $$ = NULL;
    }
    | CONTINUE ';' {
        fprintf(ir_file, "  br label %%%s\n", stack_continue[stack_top - 1]);
        char *dead = new_label();
        fprintf(ir_file, "%s:\n", dead);
        $$ = NULL;
    }
    /* ── [IF-ELSE 4/5] stmt: full if-else final action ──────────────────────
       Fires after both bodies are fully parsed. Emits everything in the correct
       LLVM order in a single shot:
         1. Restore ir_file from saved_file (back to main_buf)
         2. Emit deferred "br i1 %cond, label %l_true, label %l_false"
         3. l_true: label + dump true-body (body_tmp1) + "br label %l_end"
         4. l_false: label + dump false-body (body_tmp2) + "br label %l_end"
         5. l_end: merge label — execution from both branches converges here
       ────────────────────────────────────────────────────────────────────── */
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
    /* ── [IF-ELSE 5/5] stmt: if-only final action ───────────────────────────
       Fires when NO ELSE follows — Bison took this path instead of if_else_prefix.
       l_false is NULL (never allocated), so the false branch of br jumps directly
       to l_end, skipping the body entirely:
         1. Restore ir_file from saved_file
         2. Emit "br i1 %cond, label %l_true, label %l_end"  (no l_false needed)
         3. l_true: label + dump body (body_tmp1) + "br label %l_end"
         4. l_end: merge label
       Only l_true and l_end are freed — l_false was never created.
       ────────────────────────────────────────────────────────────────────── */
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
sc_and_mid:
    cond AND {
        char *rhs_label   = new_label();
        char *merge_label = new_label();
        char *sc_slot     = new_tmp();

        /* alloca an i1 slot — default to false (short-circuit case) */
        fprintf(ir_file, "  %s = alloca i1\n", sc_slot);
        fprintf(ir_file, "  store i1 false, i1* %s\n", sc_slot);

        /* if LHS true → go evaluate RHS; if LHS false → skip to merge */
        fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                $1, rhs_label, merge_label);
        fprintf(ir_file, "%s:\n", rhs_label);

        $$.sc_slot     = sc_slot;
        $$.merge_label = merge_label;
    }
    ;
sc_or_mid:
    cond OR {
        char *rhs_label   = new_label();
        char *merge_label = new_label();
        char *sc_slot     = new_tmp();

        /* alloca an i1 slot — default to true (short-circuit case) */
        fprintf(ir_file, "  %s = alloca i1\n", sc_slot);
        fprintf(ir_file, "  store i1 true, i1* %s\n", sc_slot);

        /* if LHS true → skip RHS, go to merge; if LHS false → evaluate RHS */
        fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                $1, merge_label, rhs_label);
        fprintf(ir_file, "%s:\n", rhs_label);

        $$.sc_slot     = sc_slot;
        $$.merge_label = merge_label;
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
    | sc_and_mid cond %prec AND
    {
    /* $1 = scdata from mid-rule, $2 = RHS i1 result */

    /* store RHS result into the slot */
    fprintf(ir_file, "  store i1 %s, i1* %s\n", $2, $1.sc_slot);
    fprintf(ir_file, "  br label %%%s\n", $1.merge_label);

    /* merge block — load the final result */
    fprintf(ir_file, "%s:\n", $1.merge_label);
    $$ = new_tmp();
    fprintf(ir_file, "  %s = load i1, i1* %s\n", $$, $1.sc_slot);
    }
    | sc_or_mid cond %prec OR
    {
    /* $1 = scdata from mid-rule, $2 = RHS i1 result */

    /* store RHS result into the slot */
    fprintf(ir_file, "  store i1 %s, i1* %s\n", $2, $1.sc_slot);
    fprintf(ir_file, "  br label %%%s\n", $1.merge_label);

    /* merge block — load the final result */
    fprintf(ir_file, "%s:\n", $1.merge_label);
    $$ = new_tmp();
    fprintf(ir_file, "  %s = load i1, i1* %s\n", $$, $1.sc_slot);
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
    /* ── [FUNC 12/14] Expression calls (no-arg and with-arg) ────────────────
       Called as part of an expression — return value is KEPT.
       new_tmp() allocates a fresh %tN register; $$ carries it up so parent rules
       (e.g. assignment, arithmetic) can use the returned value.
       No-arg:   IDENT '(' ')'
       With-arg: IDENT '(' arg_list ')'  — arg_list string freed after splicing
       ────────────────────────────────────────────────────────────────────── */
    // Expression call with no arguments e.g. x = getVal();
    // Unlike statement calls, the return value is KEPT. new_tmp() allocates a fresh %tN register,
    // and the call result is assigned to it. $$ is set to that register so the parent rule
    // (e.g. an assignment like x = getVal()) can read and use the returned value.
    | IDENT '(' ')' {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = call i32 @%s()\n", $$, $1);
        free($1);
    }
    // Expression call with arguments e.g. x = add(3, 4);
    // $3 is the complete LLVM argument string from arg_list e.g. "i32 %t0, i32 %t1".
    // new_tmp() creates a register to hold the return value; $$ carries it up the parse tree
    // so the parent rule can use it (e.g. store it into a variable, or pass it to another expr).
    | IDENT '(' arg_list ')' {
        $$ = new_tmp();
        fprintf(ir_file, "  %s = call i32 @%s(%s)\n", $$, $1, $3);
        free($1);
        free($3);  // arg string spliced into IR; $$ carries the result register up instead
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

    /* ── [FUNC 13/14] Buffer setup ───────────────────────────────────────────
       Create two scratch-pad tmpfiles before parsing starts.
       ir_file defaults to main_buf so all top-level statements go there.
       func_def will temporarily redirect ir_file to fn_file for each function body.
       ────────────────────────────────────────────────────────────────────── */
    // set up separate buffers: fn_file for user functions, main_buf for @main body
    fn_file  = tmpfile();
    main_buf = tmpfile();
    ir_file  = main_buf;  // all main-body IR goes here by default during parsing

    yyparse();  // entire compilation happens here; func_def redirects ir_file to fn_file as needed

    /* ── [FUNC 14/14] Final assembly ─────────────────────────────────────────
       Pour the scratch pads into output.ll in the correct LLVM module order:
         1. fn_file  → user-defined functions (must precede @main)
         2. @main header literal
         3. main_buf → @main body
         4. ret i32 0 + closing brace
       This is the payoff of the two-buffer architecture: parse order is
       decoupled from the output order required by LLVM.
       ────────────────────────────────────────────────────────────────────── */
    // flush in correct order: user functions must appear before @main in LLVM IR
    dump_buffer_to(fn_file, actual_output); // pour functions into output.ll
    fprintf(actual_output, "\ndefine i32 @main() {\n");
    fprintf(actual_output, "entry:\n");
    dump_buffer_to(main_buf, actual_output); //pour main content into output.ll
    fprintf(actual_output, "  ret i32 0\n");
    fprintf(actual_output, "}\n");

    fclose(actual_output);
    return 0;
}
