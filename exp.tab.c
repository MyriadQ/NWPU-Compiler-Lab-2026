/* A Bison parser, made by GNU Bison 3.8.2.  */

/* Bison implementation for Yacc-like parsers in C

   Copyright (C) 1984, 1989-1990, 2000-2015, 2018-2021 Free Software Foundation,
   Inc.

   This program is free software: you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation, either version 3 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program.  If not, see <https://www.gnu.org/licenses/>.  */

/* As a special exception, you may create a larger work that contains
   part or all of the Bison parser skeleton and distribute that work
   under terms of your choice, so long as that work isn't itself a
   parser generator using the skeleton or a modified version thereof
   as a parser skeleton.  Alternatively, if you modify or redistribute
   the parser skeleton itself, you may (at your option) remove this
   special exception, which will cause the skeleton and the resulting
   Bison output files to be licensed under the GNU General Public
   License without this special exception.

   This special exception was added by the Free Software Foundation in
   version 2.2 of Bison.  */

/* C LALR(1) parser skeleton written by Richard Stallman, by
   simplifying the original so-called "semantic" parser.  */

/* DO NOT RELY ON FEATURES THAT ARE NOT DOCUMENTED in the manual,
   especially those whose name start with YY_ or yy_.  They are
   private implementation details that can be changed or removed.  */

/* All symbols defined below should begin with yy or YY, to avoid
   infringing on user name space.  This should be done even for local
   variables, as they might otherwise be expanded by user macros.
   There are some unavoidable exceptions within include files to
   define necessary library symbols; they are noted "INFRINGES ON
   USER NAME SPACE" below.  */

/* Identify Bison output, and Bison version.  */
#define YYBISON 30802

/* Bison version string.  */
#define YYBISON_VERSION "3.8.2"

/* Skeleton name.  */
#define YYSKELETON_NAME "yacc.c"

/* Pure parsers.  */
#define YYPURE 0

/* Push parsers.  */
#define YYPUSH 0

/* Pull parsers.  */
#define YYPULL 1




/* First part of user prologue.  */
#line 1 "exp.y"

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

#line 340 "exp.tab.c"

# ifndef YY_CAST
#  ifdef __cplusplus
#   define YY_CAST(Type, Val) static_cast<Type> (Val)
#   define YY_REINTERPRET_CAST(Type, Val) reinterpret_cast<Type> (Val)
#  else
#   define YY_CAST(Type, Val) ((Type) (Val))
#   define YY_REINTERPRET_CAST(Type, Val) ((Type) (Val))
#  endif
# endif
# ifndef YY_NULLPTR
#  if defined __cplusplus
#   if 201103L <= __cplusplus
#    define YY_NULLPTR nullptr
#   else
#    define YY_NULLPTR 0
#   endif
#  else
#   define YY_NULLPTR ((void*)0)
#  endif
# endif

#include "exp.tab.h"
/* Symbol kind.  */
enum yysymbol_kind_t
{
  YYSYMBOL_YYEMPTY = -2,
  YYSYMBOL_YYEOF = 0,                      /* "end of file"  */
  YYSYMBOL_YYerror = 1,                    /* error  */
  YYSYMBOL_YYUNDEF = 2,                    /* "invalid token"  */
  YYSYMBOL_PRINT = 3,                      /* PRINT  */
  YYSYMBOL_INTEGER = 4,                    /* INTEGER  */
  YYSYMBOL_IDENT = 5,                      /* IDENT  */
  YYSYMBOL_IF = 6,                         /* IF  */
  YYSYMBOL_ELSE = 7,                       /* ELSE  */
  YYSYMBOL_WHILE = 8,                      /* WHILE  */
  YYSYMBOL_DO = 9,                         /* DO  */
  YYSYMBOL_FOR = 10,                       /* FOR  */
  YYSYMBOL_EQ = 11,                        /* EQ  */
  YYSYMBOL_NE = 12,                        /* NE  */
  YYSYMBOL_GE = 13,                        /* GE  */
  YYSYMBOL_LE = 14,                        /* LE  */
  YYSYMBOL_AND = 15,                       /* AND  */
  YYSYMBOL_OR = 16,                        /* OR  */
  YYSYMBOL_NOT = 17,                       /* NOT  */
  YYSYMBOL_INT_TYPE = 18,                  /* INT_TYPE  */
  YYSYMBOL_RETURN = 19,                    /* RETURN  */
  YYSYMBOL_BREAK = 20,                     /* BREAK  */
  YYSYMBOL_CONTINUE = 21,                  /* CONTINUE  */
  YYSYMBOL_22_ = 22,                       /* '>'  */
  YYSYMBOL_23_ = 23,                       /* '<'  */
  YYSYMBOL_24_ = 24,                       /* '+'  */
  YYSYMBOL_25_ = 25,                       /* '-'  */
  YYSYMBOL_26_ = 26,                       /* '*'  */
  YYSYMBOL_27_ = 27,                       /* '/'  */
  YYSYMBOL_UMINUS = 28,                    /* UMINUS  */
  YYSYMBOL_29_ = 29,                       /* ','  */
  YYSYMBOL_30_ = 30,                       /* '('  */
  YYSYMBOL_31_ = 31,                       /* ')'  */
  YYSYMBOL_32_ = 32,                       /* '{'  */
  YYSYMBOL_33_ = 33,                       /* '}'  */
  YYSYMBOL_34_ = 34,                       /* '['  */
  YYSYMBOL_35_ = 35,                       /* ']'  */
  YYSYMBOL_36_ = 36,                       /* '='  */
  YYSYMBOL_37_ = 37,                       /* ';'  */
  YYSYMBOL_YYACCEPT = 38,                  /* $accept  */
  YYSYMBOL_program = 39,                   /* program  */
  YYSYMBOL_stmts = 40,                     /* stmts  */
  YYSYMBOL_param_list_opt = 41,            /* param_list_opt  */
  YYSYMBOL_param_list = 42,                /* param_list  */
  YYSYMBOL_func_def = 43,                  /* func_def  */
  YYSYMBOL_44_1 = 44,                      /* $@1  */
  YYSYMBOL_if_cond = 45,                   /* if_cond  */
  YYSYMBOL_if_else_prefix = 46,            /* if_else_prefix  */
  YYSYMBOL_dim_list = 47,                  /* dim_list  */
  YYSYMBOL_idx_list = 48,                  /* idx_list  */
  YYSYMBOL_arg_list = 49,                  /* arg_list  */
  YYSYMBOL_stmt = 50,                      /* stmt  */
  YYSYMBOL_51_2 = 51,                      /* $@2  */
  YYSYMBOL_52_3 = 52,                      /* $@3  */
  YYSYMBOL_53_4 = 53,                      /* $@4  */
  YYSYMBOL_54_5 = 54,                      /* $@5  */
  YYSYMBOL_55_6 = 55,                      /* $@6  */
  YYSYMBOL_56_7 = 56,                      /* $@7  */
  YYSYMBOL_57_8 = 57,                      /* $@8  */
  YYSYMBOL_sc_and_mid = 58,                /* sc_and_mid  */
  YYSYMBOL_sc_or_mid = 59,                 /* sc_or_mid  */
  YYSYMBOL_cond = 60,                      /* cond  */
  YYSYMBOL_expr = 61                       /* expr  */
};
typedef enum yysymbol_kind_t yysymbol_kind_t;




#ifdef short
# undef short
#endif

/* On compilers that do not define __PTRDIFF_MAX__ etc., make sure
   <limits.h> and (if available) <stdint.h> are included
   so that the code can choose integer types of a good width.  */

#ifndef __PTRDIFF_MAX__
# include <limits.h> /* INFRINGES ON USER NAME SPACE */
# if defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stdint.h> /* INFRINGES ON USER NAME SPACE */
#  define YY_STDINT_H
# endif
#endif

/* Narrow types that promote to a signed type and that can represent a
   signed or unsigned integer of at least N bits.  In tables they can
   save space and decrease cache pressure.  Promoting to a signed type
   helps avoid bugs in integer arithmetic.  */

#ifdef __INT_LEAST8_MAX__
typedef __INT_LEAST8_TYPE__ yytype_int8;
#elif defined YY_STDINT_H
typedef int_least8_t yytype_int8;
#else
typedef signed char yytype_int8;
#endif

#ifdef __INT_LEAST16_MAX__
typedef __INT_LEAST16_TYPE__ yytype_int16;
#elif defined YY_STDINT_H
typedef int_least16_t yytype_int16;
#else
typedef short yytype_int16;
#endif

/* Work around bug in HP-UX 11.23, which defines these macros
   incorrectly for preprocessor constants.  This workaround can likely
   be removed in 2023, as HPE has promised support for HP-UX 11.23
   (aka HP-UX 11i v2) only through the end of 2022; see Table 2 of
   <https://h20195.www2.hpe.com/V2/getpdf.aspx/4AA4-7673ENW.pdf>.  */
#ifdef __hpux
# undef UINT_LEAST8_MAX
# undef UINT_LEAST16_MAX
# define UINT_LEAST8_MAX 255
# define UINT_LEAST16_MAX 65535
#endif

#if defined __UINT_LEAST8_MAX__ && __UINT_LEAST8_MAX__ <= __INT_MAX__
typedef __UINT_LEAST8_TYPE__ yytype_uint8;
#elif (!defined __UINT_LEAST8_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST8_MAX <= INT_MAX)
typedef uint_least8_t yytype_uint8;
#elif !defined __UINT_LEAST8_MAX__ && UCHAR_MAX <= INT_MAX
typedef unsigned char yytype_uint8;
#else
typedef short yytype_uint8;
#endif

#if defined __UINT_LEAST16_MAX__ && __UINT_LEAST16_MAX__ <= __INT_MAX__
typedef __UINT_LEAST16_TYPE__ yytype_uint16;
#elif (!defined __UINT_LEAST16_MAX__ && defined YY_STDINT_H \
       && UINT_LEAST16_MAX <= INT_MAX)
typedef uint_least16_t yytype_uint16;
#elif !defined __UINT_LEAST16_MAX__ && USHRT_MAX <= INT_MAX
typedef unsigned short yytype_uint16;
#else
typedef int yytype_uint16;
#endif

#ifndef YYPTRDIFF_T
# if defined __PTRDIFF_TYPE__ && defined __PTRDIFF_MAX__
#  define YYPTRDIFF_T __PTRDIFF_TYPE__
#  define YYPTRDIFF_MAXIMUM __PTRDIFF_MAX__
# elif defined PTRDIFF_MAX
#  ifndef ptrdiff_t
#   include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  endif
#  define YYPTRDIFF_T ptrdiff_t
#  define YYPTRDIFF_MAXIMUM PTRDIFF_MAX
# else
#  define YYPTRDIFF_T long
#  define YYPTRDIFF_MAXIMUM LONG_MAX
# endif
#endif

#ifndef YYSIZE_T
# ifdef __SIZE_TYPE__
#  define YYSIZE_T __SIZE_TYPE__
# elif defined size_t
#  define YYSIZE_T size_t
# elif defined __STDC_VERSION__ && 199901 <= __STDC_VERSION__
#  include <stddef.h> /* INFRINGES ON USER NAME SPACE */
#  define YYSIZE_T size_t
# else
#  define YYSIZE_T unsigned
# endif
#endif

#define YYSIZE_MAXIMUM                                  \
  YY_CAST (YYPTRDIFF_T,                                 \
           (YYPTRDIFF_MAXIMUM < YY_CAST (YYSIZE_T, -1)  \
            ? YYPTRDIFF_MAXIMUM                         \
            : YY_CAST (YYSIZE_T, -1)))

#define YYSIZEOF(X) YY_CAST (YYPTRDIFF_T, sizeof (X))


/* Stored state numbers (used for stacks). */
typedef yytype_uint8 yy_state_t;

/* State numbers in computations.  */
typedef int yy_state_fast_t;

#ifndef YY_
# if defined YYENABLE_NLS && YYENABLE_NLS
#  if ENABLE_NLS
#   include <libintl.h> /* INFRINGES ON USER NAME SPACE */
#   define YY_(Msgid) dgettext ("bison-runtime", Msgid)
#  endif
# endif
# ifndef YY_
#  define YY_(Msgid) Msgid
# endif
#endif


#ifndef YY_ATTRIBUTE_PURE
# if defined __GNUC__ && 2 < __GNUC__ + (96 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_PURE __attribute__ ((__pure__))
# else
#  define YY_ATTRIBUTE_PURE
# endif
#endif

#ifndef YY_ATTRIBUTE_UNUSED
# if defined __GNUC__ && 2 < __GNUC__ + (7 <= __GNUC_MINOR__)
#  define YY_ATTRIBUTE_UNUSED __attribute__ ((__unused__))
# else
#  define YY_ATTRIBUTE_UNUSED
# endif
#endif

/* Suppress unused-variable warnings by "using" E.  */
#if ! defined lint || defined __GNUC__
# define YY_USE(E) ((void) (E))
#else
# define YY_USE(E) /* empty */
#endif

/* Suppress an incorrect diagnostic about yylval being uninitialized.  */
#if defined __GNUC__ && ! defined __ICC && 406 <= __GNUC__ * 100 + __GNUC_MINOR__
# if __GNUC__ * 100 + __GNUC_MINOR__ < 407
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")
# else
#  define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN                           \
    _Pragma ("GCC diagnostic push")                                     \
    _Pragma ("GCC diagnostic ignored \"-Wuninitialized\"")              \
    _Pragma ("GCC diagnostic ignored \"-Wmaybe-uninitialized\"")
# endif
# define YY_IGNORE_MAYBE_UNINITIALIZED_END      \
    _Pragma ("GCC diagnostic pop")
#else
# define YY_INITIAL_VALUE(Value) Value
#endif
#ifndef YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
# define YY_IGNORE_MAYBE_UNINITIALIZED_END
#endif
#ifndef YY_INITIAL_VALUE
# define YY_INITIAL_VALUE(Value) /* Nothing. */
#endif

#if defined __cplusplus && defined __GNUC__ && ! defined __ICC && 6 <= __GNUC__
# define YY_IGNORE_USELESS_CAST_BEGIN                          \
    _Pragma ("GCC diagnostic push")                            \
    _Pragma ("GCC diagnostic ignored \"-Wuseless-cast\"")
# define YY_IGNORE_USELESS_CAST_END            \
    _Pragma ("GCC diagnostic pop")
#endif
#ifndef YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_BEGIN
# define YY_IGNORE_USELESS_CAST_END
#endif


#define YY_ASSERT(E) ((void) (0 && (E)))

#if !defined yyoverflow

/* The parser invokes alloca or malloc; define the necessary symbols.  */

# ifdef YYSTACK_USE_ALLOCA
#  if YYSTACK_USE_ALLOCA
#   ifdef __GNUC__
#    define YYSTACK_ALLOC __builtin_alloca
#   elif defined __BUILTIN_VA_ARG_INCR
#    include <alloca.h> /* INFRINGES ON USER NAME SPACE */
#   elif defined _AIX
#    define YYSTACK_ALLOC __alloca
#   elif defined _MSC_VER
#    include <malloc.h> /* INFRINGES ON USER NAME SPACE */
#    define alloca _alloca
#   else
#    define YYSTACK_ALLOC alloca
#    if ! defined _ALLOCA_H && ! defined EXIT_SUCCESS
#     include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
      /* Use EXIT_SUCCESS as a witness for stdlib.h.  */
#     ifndef EXIT_SUCCESS
#      define EXIT_SUCCESS 0
#     endif
#    endif
#   endif
#  endif
# endif

# ifdef YYSTACK_ALLOC
   /* Pacify GCC's 'empty if-body' warning.  */
#  define YYSTACK_FREE(Ptr) do { /* empty */; } while (0)
#  ifndef YYSTACK_ALLOC_MAXIMUM
    /* The OS might guarantee only one guard page at the bottom of the stack,
       and a page size can be as small as 4096 bytes.  So we cannot safely
       invoke alloca (N) if N exceeds 4096.  Use a slightly smaller number
       to allow for a few compiler-allocated temporary stack slots.  */
#   define YYSTACK_ALLOC_MAXIMUM 4032 /* reasonable circa 2006 */
#  endif
# else
#  define YYSTACK_ALLOC YYMALLOC
#  define YYSTACK_FREE YYFREE
#  ifndef YYSTACK_ALLOC_MAXIMUM
#   define YYSTACK_ALLOC_MAXIMUM YYSIZE_MAXIMUM
#  endif
#  if (defined __cplusplus && ! defined EXIT_SUCCESS \
       && ! ((defined YYMALLOC || defined malloc) \
             && (defined YYFREE || defined free)))
#   include <stdlib.h> /* INFRINGES ON USER NAME SPACE */
#   ifndef EXIT_SUCCESS
#    define EXIT_SUCCESS 0
#   endif
#  endif
#  ifndef YYMALLOC
#   define YYMALLOC malloc
#   if ! defined malloc && ! defined EXIT_SUCCESS
void *malloc (YYSIZE_T); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
#  ifndef YYFREE
#   define YYFREE free
#   if ! defined free && ! defined EXIT_SUCCESS
void free (void *); /* INFRINGES ON USER NAME SPACE */
#   endif
#  endif
# endif
#endif /* !defined yyoverflow */

#if (! defined yyoverflow \
     && (! defined __cplusplus \
         || (defined YYSTYPE_IS_TRIVIAL && YYSTYPE_IS_TRIVIAL)))

/* A type that is properly aligned for any stack member.  */
union yyalloc
{
  yy_state_t yyss_alloc;
  YYSTYPE yyvs_alloc;
};

/* The size of the maximum gap between one aligned stack and the next.  */
# define YYSTACK_GAP_MAXIMUM (YYSIZEOF (union yyalloc) - 1)

/* The size of an array large to enough to hold all stacks, each with
   N elements.  */
# define YYSTACK_BYTES(N) \
     ((N) * (YYSIZEOF (yy_state_t) + YYSIZEOF (YYSTYPE)) \
      + YYSTACK_GAP_MAXIMUM)

# define YYCOPY_NEEDED 1

/* Relocate STACK from its old location to the new one.  The
   local variables YYSIZE and YYSTACKSIZE give the old and new number of
   elements in the stack, and YYPTR gives the new location of the
   stack.  Advance YYPTR to a properly aligned location for the next
   stack.  */
# define YYSTACK_RELOCATE(Stack_alloc, Stack)                           \
    do                                                                  \
      {                                                                 \
        YYPTRDIFF_T yynewbytes;                                         \
        YYCOPY (&yyptr->Stack_alloc, Stack, yysize);                    \
        Stack = &yyptr->Stack_alloc;                                    \
        yynewbytes = yystacksize * YYSIZEOF (*Stack) + YYSTACK_GAP_MAXIMUM; \
        yyptr += yynewbytes / YYSIZEOF (*yyptr);                        \
      }                                                                 \
    while (0)

#endif

#if defined YYCOPY_NEEDED && YYCOPY_NEEDED
/* Copy COUNT objects from SRC to DST.  The source and destination do
   not overlap.  */
# ifndef YYCOPY
#  if defined __GNUC__ && 1 < __GNUC__
#   define YYCOPY(Dst, Src, Count) \
      __builtin_memcpy (Dst, Src, YY_CAST (YYSIZE_T, (Count)) * sizeof (*(Src)))
#  else
#   define YYCOPY(Dst, Src, Count)              \
      do                                        \
        {                                       \
          YYPTRDIFF_T yyi;                      \
          for (yyi = 0; yyi < (Count); yyi++)   \
            (Dst)[yyi] = (Src)[yyi];            \
        }                                       \
      while (0)
#  endif
# endif
#endif /* !YYCOPY_NEEDED */

/* YYFINAL -- State number of the termination state.  */
#define YYFINAL  2
/* YYLAST -- Last index in YYTABLE.  */
#define YYLAST   314

/* YYNTOKENS -- Number of terminals.  */
#define YYNTOKENS  38
/* YYNNTS -- Number of nonterminals.  */
#define YYNNTS  24
/* YYNRULES -- Number of rules.  */
#define YYNRULES  66
/* YYNSTATES -- Number of states.  */
#define YYNSTATES  163

/* YYMAXUTOK -- Last valid token kind.  */
#define YYMAXUTOK   277


/* YYTRANSLATE(TOKEN-NUM) -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex, with out-of-bounds checking.  */
#define YYTRANSLATE(YYX)                                \
  (0 <= (YYX) && (YYX) <= YYMAXUTOK                     \
   ? YY_CAST (yysymbol_kind_t, yytranslate[YYX])        \
   : YYSYMBOL_YYUNDEF)

/* YYTRANSLATE[TOKEN-NUM] -- Symbol number corresponding to TOKEN-NUM
   as returned by yylex.  */
static const yytype_int8 yytranslate[] =
{
       0,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
      30,    31,    26,    24,    29,    25,     2,    27,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,    37,
      23,    36,    22,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,    34,     2,    35,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,    32,     2,    33,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     2,     2,     2,     2,
       2,     2,     2,     2,     2,     2,     1,     2,     3,     4,
       5,     6,     7,     8,     9,    10,    11,    12,    13,    14,
      15,    16,    17,    18,    19,    20,    21,    28
};

#if YYDEBUG
/* YYRLINE[YYN] -- Source line where rule number YYN was defined.  */
static const yytype_int16 yyrline[] =
{
       0,   351,   351,   352,   353,   357,   358,   374,   375,   380,
     386,   406,   405,   468,   491,   501,   506,   513,   518,   543,
     550,   557,   563,   567,   581,   599,   608,   614,   620,   630,
     639,   628,   655,   670,   678,   654,   696,   705,   695,   720,
     726,   741,   777,   797,   816,   835,   840,   845,   850,   855,
     860,   865,   878,   891,   896,   900,   908,   912,   918,   922,
     926,   930,   934,   938,   941,   961,   970
};
#endif

/** Accessing symbol of state STATE.  */
#define YY_ACCESSING_SYMBOL(State) YY_CAST (yysymbol_kind_t, yystos[State])

#if YYDEBUG || 0
/* The user-facing name of the symbol whose (internal) number is
   YYSYMBOL.  No bounds checking.  */
static const char *yysymbol_name (yysymbol_kind_t yysymbol) YY_ATTRIBUTE_UNUSED;

/* YYTNAME[SYMBOL-NUM] -- String name of the symbol SYMBOL-NUM.
   First, the terminals, then, starting at YYNTOKENS, nonterminals.  */
static const char *const yytname[] =
{
  "\"end of file\"", "error", "\"invalid token\"", "PRINT", "INTEGER",
  "IDENT", "IF", "ELSE", "WHILE", "DO", "FOR", "EQ", "NE", "GE", "LE",
  "AND", "OR", "NOT", "INT_TYPE", "RETURN", "BREAK", "CONTINUE", "'>'",
  "'<'", "'+'", "'-'", "'*'", "'/'", "UMINUS", "','", "'('", "')'", "'{'",
  "'}'", "'['", "']'", "'='", "';'", "$accept", "program", "stmts",
  "param_list_opt", "param_list", "func_def", "$@1", "if_cond",
  "if_else_prefix", "dim_list", "idx_list", "arg_list", "stmt", "$@2",
  "$@3", "$@4", "$@5", "$@6", "$@7", "$@8", "sc_and_mid", "sc_or_mid",
  "cond", "expr", YY_NULLPTR
};

static const char *
yysymbol_name (yysymbol_kind_t yysymbol)
{
  return yytname[yysymbol];
}
#endif

#define YYPACT_NINF (-99)

#define yypact_value_is_default(Yyn) \
  ((Yyn) == YYPACT_NINF)

#define YYTABLE_NINF (-1)

#define yytable_value_is_error(Yyn) \
  0

/* YYPACT[STATE-NUM] -- Index in YYTABLE of the portion describing
   STATE-NUM.  */
static const yytype_int16 yypact[] =
{
     -99,   215,   -99,    31,    74,   -26,   -17,   -99,     4,    22,
      31,    -7,     8,   -99,    17,    25,   -99,   -99,   -12,    31,
      31,    27,    -2,    31,    31,    60,    38,   -99,    33,    81,
     132,   224,   -99,   -99,   -99,   -99,     1,    45,   -99,   271,
      31,    31,    31,    31,   -99,    72,   100,   287,   254,   228,
      31,    31,    38,    38,    38,    38,    43,    58,    38,   -99,
      77,   102,   119,    31,   -22,   -99,    97,   116,   -99,   109,
     -99,    49,    49,   -99,   -99,   -99,    31,    91,   -99,   -99,
     266,   232,   -99,    62,   216,   -99,   128,   -99,   -99,   -99,
      31,    31,    31,    31,    31,    31,    83,   136,    31,   142,
     120,   123,   124,   246,   163,   -99,   164,   -99,   -99,   287,
     -99,   -99,   -99,   -99,   287,   287,   287,   287,   287,   287,
     -99,   165,   -99,   -99,   250,   -99,   -99,   154,   -99,   -99,
     143,   -99,   149,   114,   177,   -99,   157,   181,   -99,   -99,
     160,    38,   -99,   -99,   155,    38,     9,   174,   -99,    96,
     -99,   -99,   150,   186,   -99,   161,    31,   279,   -99,   168,
     -99,   193,   -99
};

/* YYDEFACT[STATE-NUM] -- Default reduction number in state STATE-NUM.
   Performed when YYTABLE does not specify something else to do.  Zero
   means the default is an error.  */
static const yytype_int8 yydefact[] =
{
       4,     0,     1,     0,     0,     0,     0,    36,     0,     0,
       0,     0,     0,     3,     0,     0,     2,    56,    57,     0,
       0,     0,     0,     0,     0,     0,     0,    29,     0,     0,
       0,     0,    39,    40,     4,     4,     0,    64,    58,     0,
       0,     0,     0,     0,    22,     0,     0,    19,     0,     0,
       0,     0,     0,     0,     0,     0,     0,    55,     0,     6,
       0,     7,     0,     0,     0,    24,     0,     0,    65,     0,
      63,    59,    60,    61,    62,    25,     0,     0,    17,    21,
       0,     0,    53,     0,    55,    51,    52,    43,    44,    13,
       0,     0,     0,     0,     0,     0,     0,     0,     0,     0,
       0,     8,     0,     0,     0,    27,    42,    41,    66,    20,
      26,    18,    28,    54,    49,    50,    48,    47,    46,    45,
      30,     0,    37,     5,     0,     9,    11,     0,    15,    23,
       0,    14,     0,     0,     0,    32,     0,     0,    16,     6,
       0,     0,     6,    10,     0,     0,     0,     0,    31,     0,
      33,    12,     0,     0,    38,     0,     0,     0,    34,     0,
       6,     0,    35
};

/* YYPGOTO[NTERM-NUM].  */
static const yytype_int16 yypgoto[] =
{
     -99,    98,   -98,   -99,   -99,   -99,   -99,   -99,   -99,   -99,
     187,   170,     0,   -99,   -99,   -99,   -99,   -99,   -99,   -99,
     -99,   -99,   -44,    -3
};

/* YYDEFGOTO[NTERM-NUM].  */
static const yytype_uint8 yydefgoto[] =
{
       0,     1,    97,   100,   101,    13,   136,    14,    15,    64,
      25,    46,   123,    58,   132,   141,   153,   159,    28,   134,
      54,    55,    56,    57
};

/* YYTABLE[YYPACT[STATE-NUM]] -- What to do in state STATE-NUM.  If
   positive, shift that token.  If negative, reduce the rule whose
   number is the opposite.  If YYTABLE_NINF, syntax error.  */
static const yytype_uint8 yytable[] =
{
      21,    16,    17,    18,    26,    17,    18,    31,    82,    83,
      85,    86,   104,    27,    96,   105,    38,    39,    36,    47,
      48,    49,    23,    19,    87,    88,    19,    30,    20,    45,
      32,    20,    68,    47,    29,    17,    18,    71,    72,    73,
      74,   144,    17,    18,   147,    33,   150,    80,    81,    34,
      84,    40,    41,    42,    43,    52,    19,    35,    87,    88,
     103,    20,   161,    19,    44,    59,    16,    16,    53,    90,
      91,    92,    93,   109,    89,    42,    43,    87,    88,    50,
      94,    95,    40,    41,    42,    43,    60,   114,   115,   116,
     117,   118,   119,   113,    50,   124,    51,   146,    87,    88,
       3,   149,     4,     5,    22,     6,     7,     8,    23,    75,
      24,    87,    88,    98,   120,     9,    10,    11,    12,     3,
      99,     4,     5,   102,     6,     7,     8,   152,   110,    76,
     106,    77,    66,    67,     9,    10,    11,    12,    76,     3,
     108,     4,     5,    87,     6,     7,     8,   125,    62,   107,
      63,   126,   127,   157,   121,    10,    11,    12,     3,   128,
       4,     5,    61,     6,     7,     8,    62,   130,    63,   122,
     133,   131,   137,   121,    10,    11,    12,     3,   138,     4,
       5,   139,     6,     7,     8,   140,   143,   154,   148,   142,
     145,   155,   121,    10,    11,    12,     3,   156,     4,     5,
     160,     6,     7,     8,     0,    37,    69,   151,     0,     0,
       0,   121,    10,    11,    12,     2,     0,     0,     3,     0,
       4,     5,     0,     6,     7,     8,   162,    90,    91,    92,
      93,     0,     0,     9,    10,    11,    12,     0,    94,    95,
      40,    41,    42,    43,     0,     0,     0,    70,    40,    41,
      42,    43,    40,    41,    42,    43,    40,    41,    42,    43,
       0,    65,     0,     0,     0,    79,     0,     0,     0,   112,
      40,    41,    42,    43,    40,    41,    42,    43,    40,    41,
      42,    43,     0,   129,     0,     0,     0,   135,     0,    78,
      40,    41,    42,    43,     0,    40,    41,    42,    43,     0,
       0,   111,    70,    40,    41,    42,    43,     0,     0,     0,
     158,    40,    41,    42,    43
};

static const yytype_int16 yycheck[] =
{
       3,     1,     4,     5,    30,     4,     5,    10,    52,    53,
      54,    55,    34,    30,    58,    37,    19,    20,    30,    22,
      23,    24,    34,    25,    15,    16,    25,     5,    30,    31,
      37,    30,    31,    36,    30,     4,     5,    40,    41,    42,
      43,   139,     4,     5,   142,    37,    37,    50,    51,    32,
      53,    24,    25,    26,    27,    17,    25,    32,    15,    16,
      63,    30,   160,    25,    37,    32,    66,    67,    30,    11,
      12,    13,    14,    76,    31,    26,    27,    15,    16,    34,
      22,    23,    24,    25,    26,    27,     5,    90,    91,    92,
      93,    94,    95,    31,    34,    98,    36,   141,    15,    16,
       3,   145,     5,     6,    30,     8,     9,    10,    34,    37,
      36,    15,    16,    36,    31,    18,    19,    20,    21,     3,
      18,     5,     6,     4,     8,     9,    10,    31,    37,    29,
      33,    31,    34,    35,    18,    19,    20,    21,    29,     3,
      31,     5,     6,    15,     8,     9,    10,     5,    34,    33,
      36,    31,    29,   156,    18,    19,    20,    21,     3,    35,
       5,     6,    30,     8,     9,    10,    34,     4,    36,    33,
       5,     7,    18,    18,    19,    20,    21,     3,    35,     5,
       6,    32,     8,     9,    10,     8,     5,    37,    33,    32,
      30,     5,    18,    19,    20,    21,     3,    36,     5,     6,
      32,     8,     9,    10,    -1,    18,    36,    33,    -1,    -1,
      -1,    18,    19,    20,    21,     0,    -1,    -1,     3,    -1,
       5,     6,    -1,     8,     9,    10,    33,    11,    12,    13,
      14,    -1,    -1,    18,    19,    20,    21,    -1,    22,    23,
      24,    25,    26,    27,    -1,    -1,    -1,    31,    24,    25,
      26,    27,    24,    25,    26,    27,    24,    25,    26,    27,
      -1,    37,    -1,    -1,    -1,    37,    -1,    -1,    -1,    37,
      24,    25,    26,    27,    24,    25,    26,    27,    24,    25,
      26,    27,    -1,    37,    -1,    -1,    -1,    37,    -1,    35,
      24,    25,    26,    27,    -1,    24,    25,    26,    27,    -1,
      -1,    35,    31,    24,    25,    26,    27,    -1,    -1,    -1,
      31,    24,    25,    26,    27
};

/* YYSTOS[STATE-NUM] -- The symbol kind of the accessing symbol of
   state STATE-NUM.  */
static const yytype_int8 yystos[] =
{
       0,    39,     0,     3,     5,     6,     8,     9,    10,    18,
      19,    20,    21,    43,    45,    46,    50,     4,     5,    25,
      30,    61,    30,    34,    36,    48,    30,    30,    56,    30,
       5,    61,    37,    37,    32,    32,    30,    48,    61,    61,
      24,    25,    26,    27,    37,    31,    49,    61,    61,    61,
      34,    36,    17,    30,    58,    59,    60,    61,    51,    32,
       5,    30,    34,    36,    47,    37,    39,    39,    31,    49,
      31,    61,    61,    61,    61,    37,    29,    31,    35,    37,
      61,    61,    60,    60,    61,    60,    60,    15,    16,    31,
      11,    12,    13,    14,    22,    23,    60,    40,    36,    18,
      41,    42,     4,    61,    34,    37,    33,    33,    31,    61,
      37,    35,    37,    31,    61,    61,    61,    61,    61,    61,
      31,    18,    33,    50,    61,     5,    31,    29,    35,    37,
       4,     7,    52,     5,    57,    37,    44,    18,    35,    32,
       8,    53,    32,     5,    40,    30,    60,    40,    33,    60,
      37,    33,    31,    54,    37,     5,    36,    61,    31,    55,
      32,    40,    33
};

/* YYR1[RULE-NUM] -- Symbol kind of the left-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr1[] =
{
       0,    38,    39,    39,    39,    40,    40,    41,    41,    42,
      42,    44,    43,    45,    46,    47,    47,    48,    48,    49,
      49,    50,    50,    50,    50,    50,    50,    50,    50,    51,
      52,    50,    53,    54,    55,    50,    56,    57,    50,    50,
      50,    50,    50,    58,    59,    60,    60,    60,    60,    60,
      60,    60,    60,    60,    60,    60,    61,    61,    61,    61,
      61,    61,    61,    61,    61,    61,    61
};

/* YYR2[RULE-NUM] -- Number of symbols on the right-hand side of rule RULE-NUM.  */
static const yytype_int8 yyr2[] =
{
       0,     2,     2,     2,     0,     2,     0,     0,     1,     2,
       4,     0,     9,     4,     5,     3,     4,     3,     4,     1,
       3,     4,     3,     5,     3,     4,     5,     4,     5,     0,
       0,     9,     0,     0,     0,    18,     0,     0,    11,     2,
       2,     4,     4,     2,     2,     3,     3,     3,     3,     3,
       3,     2,     2,     2,     3,     1,     1,     1,     2,     3,
       3,     3,     3,     3,     2,     3,     4
};


enum { YYENOMEM = -2 };

#define yyerrok         (yyerrstatus = 0)
#define yyclearin       (yychar = YYEMPTY)

#define YYACCEPT        goto yyacceptlab
#define YYABORT         goto yyabortlab
#define YYERROR         goto yyerrorlab
#define YYNOMEM         goto yyexhaustedlab


#define YYRECOVERING()  (!!yyerrstatus)

#define YYBACKUP(Token, Value)                                    \
  do                                                              \
    if (yychar == YYEMPTY)                                        \
      {                                                           \
        yychar = (Token);                                         \
        yylval = (Value);                                         \
        YYPOPSTACK (yylen);                                       \
        yystate = *yyssp;                                         \
        goto yybackup;                                            \
      }                                                           \
    else                                                          \
      {                                                           \
        yyerror (YY_("syntax error: cannot back up")); \
        YYERROR;                                                  \
      }                                                           \
  while (0)

/* Backward compatibility with an undocumented macro.
   Use YYerror or YYUNDEF. */
#define YYERRCODE YYUNDEF


/* Enable debugging if requested.  */
#if YYDEBUG

# ifndef YYFPRINTF
#  include <stdio.h> /* INFRINGES ON USER NAME SPACE */
#  define YYFPRINTF fprintf
# endif

# define YYDPRINTF(Args)                        \
do {                                            \
  if (yydebug)                                  \
    YYFPRINTF Args;                             \
} while (0)




# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)                    \
do {                                                                      \
  if (yydebug)                                                            \
    {                                                                     \
      YYFPRINTF (stderr, "%s ", Title);                                   \
      yy_symbol_print (stderr,                                            \
                  Kind, Value); \
      YYFPRINTF (stderr, "\n");                                           \
    }                                                                     \
} while (0)


/*-----------------------------------.
| Print this symbol's value on YYO.  |
`-----------------------------------*/

static void
yy_symbol_value_print (FILE *yyo,
                       yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  FILE *yyoutput = yyo;
  YY_USE (yyoutput);
  if (!yyvaluep)
    return;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/*---------------------------.
| Print this symbol on YYO.  |
`---------------------------*/

static void
yy_symbol_print (FILE *yyo,
                 yysymbol_kind_t yykind, YYSTYPE const * const yyvaluep)
{
  YYFPRINTF (yyo, "%s %s (",
             yykind < YYNTOKENS ? "token" : "nterm", yysymbol_name (yykind));

  yy_symbol_value_print (yyo, yykind, yyvaluep);
  YYFPRINTF (yyo, ")");
}

/*------------------------------------------------------------------.
| yy_stack_print -- Print the state stack from its BOTTOM up to its |
| TOP (included).                                                   |
`------------------------------------------------------------------*/

static void
yy_stack_print (yy_state_t *yybottom, yy_state_t *yytop)
{
  YYFPRINTF (stderr, "Stack now");
  for (; yybottom <= yytop; yybottom++)
    {
      int yybot = *yybottom;
      YYFPRINTF (stderr, " %d", yybot);
    }
  YYFPRINTF (stderr, "\n");
}

# define YY_STACK_PRINT(Bottom, Top)                            \
do {                                                            \
  if (yydebug)                                                  \
    yy_stack_print ((Bottom), (Top));                           \
} while (0)


/*------------------------------------------------.
| Report that the YYRULE is going to be reduced.  |
`------------------------------------------------*/

static void
yy_reduce_print (yy_state_t *yyssp, YYSTYPE *yyvsp,
                 int yyrule)
{
  int yylno = yyrline[yyrule];
  int yynrhs = yyr2[yyrule];
  int yyi;
  YYFPRINTF (stderr, "Reducing stack by rule %d (line %d):\n",
             yyrule - 1, yylno);
  /* The symbols being reduced.  */
  for (yyi = 0; yyi < yynrhs; yyi++)
    {
      YYFPRINTF (stderr, "   $%d = ", yyi + 1);
      yy_symbol_print (stderr,
                       YY_ACCESSING_SYMBOL (+yyssp[yyi + 1 - yynrhs]),
                       &yyvsp[(yyi + 1) - (yynrhs)]);
      YYFPRINTF (stderr, "\n");
    }
}

# define YY_REDUCE_PRINT(Rule)          \
do {                                    \
  if (yydebug)                          \
    yy_reduce_print (yyssp, yyvsp, Rule); \
} while (0)

/* Nonzero means print parse trace.  It is left uninitialized so that
   multiple parsers can coexist.  */
int yydebug;
#else /* !YYDEBUG */
# define YYDPRINTF(Args) ((void) 0)
# define YY_SYMBOL_PRINT(Title, Kind, Value, Location)
# define YY_STACK_PRINT(Bottom, Top)
# define YY_REDUCE_PRINT(Rule)
#endif /* !YYDEBUG */


/* YYINITDEPTH -- initial size of the parser's stacks.  */
#ifndef YYINITDEPTH
# define YYINITDEPTH 200
#endif

/* YYMAXDEPTH -- maximum size the stacks can grow to (effective only
   if the built-in stack extension method is used).

   Do not make this value too large; the results are undefined if
   YYSTACK_ALLOC_MAXIMUM < YYSTACK_BYTES (YYMAXDEPTH)
   evaluated with infinite-precision integer arithmetic.  */

#ifndef YYMAXDEPTH
# define YYMAXDEPTH 10000
#endif






/*-----------------------------------------------.
| Release the memory associated to this symbol.  |
`-----------------------------------------------*/

static void
yydestruct (const char *yymsg,
            yysymbol_kind_t yykind, YYSTYPE *yyvaluep)
{
  YY_USE (yyvaluep);
  if (!yymsg)
    yymsg = "Deleting";
  YY_SYMBOL_PRINT (yymsg, yykind, yyvaluep, yylocationp);

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  YY_USE (yykind);
  YY_IGNORE_MAYBE_UNINITIALIZED_END
}


/* Lookahead token kind.  */
int yychar;

/* The semantic value of the lookahead symbol.  */
YYSTYPE yylval;
/* Number of syntax errors so far.  */
int yynerrs;




/*----------.
| yyparse.  |
`----------*/

int
yyparse (void)
{
    yy_state_fast_t yystate = 0;
    /* Number of tokens to shift before error messages enabled.  */
    int yyerrstatus = 0;

    /* Refer to the stacks through separate pointers, to allow yyoverflow
       to reallocate them elsewhere.  */

    /* Their size.  */
    YYPTRDIFF_T yystacksize = YYINITDEPTH;

    /* The state stack: array, bottom, top.  */
    yy_state_t yyssa[YYINITDEPTH];
    yy_state_t *yyss = yyssa;
    yy_state_t *yyssp = yyss;

    /* The semantic value stack: array, bottom, top.  */
    YYSTYPE yyvsa[YYINITDEPTH];
    YYSTYPE *yyvs = yyvsa;
    YYSTYPE *yyvsp = yyvs;

  int yyn;
  /* The return value of yyparse.  */
  int yyresult;
  /* Lookahead symbol kind.  */
  yysymbol_kind_t yytoken = YYSYMBOL_YYEMPTY;
  /* The variables used to return semantic value and location from the
     action routines.  */
  YYSTYPE yyval;



#define YYPOPSTACK(N)   (yyvsp -= (N), yyssp -= (N))

  /* The number of symbols on the RHS of the reduced rule.
     Keep to zero when no symbol should be popped.  */
  int yylen = 0;

  YYDPRINTF ((stderr, "Starting parse\n"));

  yychar = YYEMPTY; /* Cause a token to be read.  */

  goto yysetstate;


/*------------------------------------------------------------.
| yynewstate -- push a new state, which is found in yystate.  |
`------------------------------------------------------------*/
yynewstate:
  /* In all cases, when you get here, the value and location stacks
     have just been pushed.  So pushing a state here evens the stacks.  */
  yyssp++;


/*--------------------------------------------------------------------.
| yysetstate -- set current state (the top of the stack) to yystate.  |
`--------------------------------------------------------------------*/
yysetstate:
  YYDPRINTF ((stderr, "Entering state %d\n", yystate));
  YY_ASSERT (0 <= yystate && yystate < YYNSTATES);
  YY_IGNORE_USELESS_CAST_BEGIN
  *yyssp = YY_CAST (yy_state_t, yystate);
  YY_IGNORE_USELESS_CAST_END
  YY_STACK_PRINT (yyss, yyssp);

  if (yyss + yystacksize - 1 <= yyssp)
#if !defined yyoverflow && !defined YYSTACK_RELOCATE
    YYNOMEM;
#else
    {
      /* Get the current used size of the three stacks, in elements.  */
      YYPTRDIFF_T yysize = yyssp - yyss + 1;

# if defined yyoverflow
      {
        /* Give user a chance to reallocate the stack.  Use copies of
           these so that the &'s don't force the real ones into
           memory.  */
        yy_state_t *yyss1 = yyss;
        YYSTYPE *yyvs1 = yyvs;

        /* Each stack pointer address is followed by the size of the
           data in use in that stack, in bytes.  This used to be a
           conditional around just the two extra args, but that might
           be undefined if yyoverflow is a macro.  */
        yyoverflow (YY_("memory exhausted"),
                    &yyss1, yysize * YYSIZEOF (*yyssp),
                    &yyvs1, yysize * YYSIZEOF (*yyvsp),
                    &yystacksize);
        yyss = yyss1;
        yyvs = yyvs1;
      }
# else /* defined YYSTACK_RELOCATE */
      /* Extend the stack our own way.  */
      if (YYMAXDEPTH <= yystacksize)
        YYNOMEM;
      yystacksize *= 2;
      if (YYMAXDEPTH < yystacksize)
        yystacksize = YYMAXDEPTH;

      {
        yy_state_t *yyss1 = yyss;
        union yyalloc *yyptr =
          YY_CAST (union yyalloc *,
                   YYSTACK_ALLOC (YY_CAST (YYSIZE_T, YYSTACK_BYTES (yystacksize))));
        if (! yyptr)
          YYNOMEM;
        YYSTACK_RELOCATE (yyss_alloc, yyss);
        YYSTACK_RELOCATE (yyvs_alloc, yyvs);
#  undef YYSTACK_RELOCATE
        if (yyss1 != yyssa)
          YYSTACK_FREE (yyss1);
      }
# endif

      yyssp = yyss + yysize - 1;
      yyvsp = yyvs + yysize - 1;

      YY_IGNORE_USELESS_CAST_BEGIN
      YYDPRINTF ((stderr, "Stack size increased to %ld\n",
                  YY_CAST (long, yystacksize)));
      YY_IGNORE_USELESS_CAST_END

      if (yyss + yystacksize - 1 <= yyssp)
        YYABORT;
    }
#endif /* !defined yyoverflow && !defined YYSTACK_RELOCATE */


  if (yystate == YYFINAL)
    YYACCEPT;

  goto yybackup;


/*-----------.
| yybackup.  |
`-----------*/
yybackup:
  /* Do appropriate processing given the current state.  Read a
     lookahead token if we need one and don't already have one.  */

  /* First try to decide what to do without reference to lookahead token.  */
  yyn = yypact[yystate];
  if (yypact_value_is_default (yyn))
    goto yydefault;

  /* Not known => get a lookahead token if don't already have one.  */

  /* YYCHAR is either empty, or end-of-input, or a valid lookahead.  */
  if (yychar == YYEMPTY)
    {
      YYDPRINTF ((stderr, "Reading a token\n"));
      yychar = yylex ();
    }

  if (yychar <= YYEOF)
    {
      yychar = YYEOF;
      yytoken = YYSYMBOL_YYEOF;
      YYDPRINTF ((stderr, "Now at end of input.\n"));
    }
  else if (yychar == YYerror)
    {
      /* The scanner already issued an error message, process directly
         to error recovery.  But do not keep the error token as
         lookahead, it is too special and may lead us to an endless
         loop in error recovery. */
      yychar = YYUNDEF;
      yytoken = YYSYMBOL_YYerror;
      goto yyerrlab1;
    }
  else
    {
      yytoken = YYTRANSLATE (yychar);
      YY_SYMBOL_PRINT ("Next token is", yytoken, &yylval, &yylloc);
    }

  /* If the proper action on seeing token YYTOKEN is to reduce or to
     detect an error, take that action.  */
  yyn += yytoken;
  if (yyn < 0 || YYLAST < yyn || yycheck[yyn] != yytoken)
    goto yydefault;
  yyn = yytable[yyn];
  if (yyn <= 0)
    {
      if (yytable_value_is_error (yyn))
        goto yyerrlab;
      yyn = -yyn;
      goto yyreduce;
    }

  /* Count tokens shifted since error; after three, turn off error
     status.  */
  if (yyerrstatus)
    yyerrstatus--;

  /* Shift the lookahead token.  */
  YY_SYMBOL_PRINT ("Shifting", yytoken, &yylval, &yylloc);
  yystate = yyn;
  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END

  /* Discard the shifted token.  */
  yychar = YYEMPTY;
  goto yynewstate;


/*-----------------------------------------------------------.
| yydefault -- do the default action for the current state.  |
`-----------------------------------------------------------*/
yydefault:
  yyn = yydefact[yystate];
  if (yyn == 0)
    goto yyerrlab;
  goto yyreduce;


/*-----------------------------.
| yyreduce -- do a reduction.  |
`-----------------------------*/
yyreduce:
  /* yyn is the number of a rule to reduce with.  */
  yylen = yyr2[yyn];

  /* If YYLEN is nonzero, implement the default value of the action:
     '$$ = $1'.

     Otherwise, the following line sets YYVAL to garbage.
     This behavior is undocumented and Bison
     users should not rely upon it.  Assigning to YYVAL
     unconditionally makes the parser a bit smaller, and it avoids a
     GCC warning that YYVAL may be used uninitialized.  */
  yyval = yyvsp[1-yylen];


  YY_REDUCE_PRINT (yyn);
  switch (yyn)
    {
  case 7: /* param_list_opt: %empty  */
#line 374 "exp.y"
                  { pending_param_count = 0; }
#line 1515 "exp.tab.c"
    break;

  case 9: /* param_list: INT_TYPE IDENT  */
#line 380 "exp.y"
                     {
          pending_param_count = 0;
          pending_params[pending_param_count++] = strdup((yyvsp[0].ident));//make a fresh copy of the identifier to store in pending_param[]
          free((yyvsp[0].ident)); //release the original that lexer allocated -> we only use the copy from now
      }
#line 1525 "exp.tab.c"
    break;

  case 10: /* param_list: param_list ',' INT_TYPE IDENT  */
#line 386 "exp.y"
                                    {
          pending_params[pending_param_count++] = strdup((yyvsp[0].ident));
          free((yyvsp[0].ident));
      }
#line 1534 "exp.tab.c"
    break;

  case 11: /* $@1: %empty  */
#line 406 "exp.y"
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
        fprintf(fn_file, "\ndefine i32 @%s(%s) {\nentry:\n", (yyvsp[-3].ident), sig);

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
        register_function((yyvsp[-3].ident), pending_param_count);
    }
#line 1578 "exp.tab.c"
    break;

  case 12: /* func_def: INT_TYPE IDENT '(' param_list_opt ')' $@1 '{' stmts '}'  */
#line 447 "exp.y"
    {
        //if the function does have return -> create a dead block and store the return to satisfy LLVM rule whereas each block must have a terminator
        fprintf(ir_file, "  ret i32 0\n}\n");   // fallthrough return (dead if explicit return exists) -> line 481
        //During the entire function body, ir_file was pointing at fn_file. 
        // This line switches it back to main_buf.
        ir_file   = main_buf; 
        //restore the sym_table for main since function is done                 
        sym_table = saved_sym_table;          
        arr_table = saved_arr_table;            
        free((yyvsp[-7].ident)); //this is the function name string -> free since we finished function
    }
#line 1594 "exp.tab.c"
    break;

  case 13: /* if_cond: IF '(' cond ')'  */
#line 468 "exp.y"
                    {
        // Defer the br i1 — we don't yet know if ELSE follows.
        // Remember the condition; capture the true-body into a tmpfile.
        (yyval.labels).cond       = (yyvsp[-1].reg); //cond
        (yyval.labels).l_true     = new_label();
        (yyval.labels).l_end      = new_label();
        (yyval.labels).l_false    = NULL;        // allocated lazily in if_else_prefix, we don't know wether else exist yet
        (yyval.labels).saved_file = ir_file;
        (yyval.labels).true_body  = NULL;
        ir_file = tmpfile();         // body writes here, not into output.ll, store temporary to check for wether else exist 
    }
#line 1610 "exp.tab.c"
    break;

  case 14: /* if_else_prefix: if_cond '{' program '}' ELSE  */
#line 491 "exp.y"
                                 {
        // True body has been captured into ir_file (a tmpfile).
        // Stash it, allocate l_false, and start a fresh tmpfile for the false body.
        (yyval.labels) = (yyvsp[-4].labels);
        (yyval.labels).l_false   = new_label();
        (yyval.labels).true_body = ir_file;
        ir_file = tmpfile();
    }
#line 1623 "exp.tab.c"
    break;

  case 15: /* dim_list: '[' INTEGER ']'  */
#line 501 "exp.y"
                    {
        (yyval.dimlist).sizes    = malloc(sizeof(int) * 8);
        (yyval.dimlist).sizes[0] = (yyvsp[-1].num);
        (yyval.dimlist).count    = 1;
    }
#line 1633 "exp.tab.c"
    break;

  case 16: /* dim_list: dim_list '[' INTEGER ']'  */
#line 506 "exp.y"
                               {
        (yyval.dimlist) = (yyvsp[-3].dimlist);
        (yyval.dimlist).sizes[(yyval.dimlist).count] = (yyvsp[-1].num);
        (yyval.dimlist).count++;
    }
#line 1643 "exp.tab.c"
    break;

  case 17: /* idx_list: '[' expr ']'  */
#line 513 "exp.y"
                 {
        (yyval.idxlist).regs    = malloc(sizeof(char*) * 8);
        (yyval.idxlist).regs[0] = (yyvsp[-1].reg);
        (yyval.idxlist).count   = 1;
    }
#line 1653 "exp.tab.c"
    break;

  case 18: /* idx_list: idx_list '[' expr ']'  */
#line 518 "exp.y"
                            {
        (yyval.idxlist) = (yyvsp[-3].idxlist);
        (yyval.idxlist).regs[(yyval.idxlist).count] = (yyvsp[-1].reg);
        (yyval.idxlist).count++;
    }
#line 1663 "exp.tab.c"
    break;

  case 19: /* arg_list: expr  */
#line 543 "exp.y"
           {
          (yyval.reg) = malloc(strlen((yyvsp[0].reg)) + 8);
          sprintf((yyval.reg), "i32 %s", (yyvsp[0].reg));
      }
#line 1672 "exp.tab.c"
    break;

  case 20: /* arg_list: arg_list ',' expr  */
#line 550 "exp.y"
                        {
          (yyval.reg) = malloc(strlen((yyvsp[-2].reg)) + strlen((yyvsp[0].reg)) + 16);
          sprintf((yyval.reg), "%s, i32 %s", (yyvsp[-2].reg), (yyvsp[0].reg));
          free((yyvsp[-2].reg));
      }
#line 1682 "exp.tab.c"
    break;

  case 21: /* stmt: IDENT '=' expr ';'  */
#line 557 "exp.y"
                       {
        char *var_alloca = get_var_alloca((yyvsp[-3].ident));
        fprintf(ir_file, "  store i32 %s, i32* %s, align 4\n", (yyvsp[-1].reg), var_alloca);
        (yyval.reg) = (yyvsp[-1].reg);
        free((yyvsp[-3].ident));
    }
#line 1693 "exp.tab.c"
    break;

  case 22: /* stmt: PRINT expr ';'  */
#line 563 "exp.y"
                     {
        gen_print_int((yyvsp[-1].reg));
        (yyval.reg) = (yyvsp[-1].reg);
    }
#line 1702 "exp.tab.c"
    break;

  case 23: /* stmt: INT_TYPE IDENT '=' expr ';'  */
#line 567 "exp.y"
                                  {
        // explicit variable declaration with initializer: int a = 5;
        // get_var_alloca allocates the variable if not yet declared, then store the value
        char *var_alloca = get_var_alloca((yyvsp[-3].ident));
        fprintf(ir_file, "  store i32 %s, i32* %s, align 4\n", (yyvsp[-1].reg), var_alloca);
        (yyval.reg) = (yyvsp[-1].reg);
        free((yyvsp[-3].ident));
    }
#line 1715 "exp.tab.c"
    break;

  case 24: /* stmt: RETURN expr ';'  */
#line 581 "exp.y"
                      {
        fprintf(ir_file, "  ret i32 %s\n", (yyvsp[-1].reg)); //ret is LLVM way of ending a function aka terminator
        char *dead = new_label(); //dead label is used to solve the problem of function return
        fprintf(ir_file, "%s:\n", dead);  // dead block keeps IR well-formed after ret
        (yyval.reg) = NULL;
    }
#line 1726 "exp.tab.c"
    break;

  case 25: /* stmt: IDENT '(' ')' ';'  */
#line 599 "exp.y"
                        {
        fprintf(ir_file, "  call i32 @%s()\n", (yyvsp[-3].ident));
        free((yyvsp[-3].ident));
        (yyval.reg) = NULL;
    }
#line 1736 "exp.tab.c"
    break;

  case 26: /* stmt: IDENT '(' arg_list ')' ';'  */
#line 608 "exp.y"
                                 {
        fprintf(ir_file, "  call i32 @%s(%s)\n", (yyvsp[-4].ident), (yyvsp[-2].reg));
        free((yyvsp[-4].ident));
        free((yyvsp[-2].reg));  // arg string has been spliced into the IR; no longer needed
        (yyval.reg) = NULL;
    }
#line 1747 "exp.tab.c"
    break;

  case 27: /* stmt: INT_TYPE IDENT dim_list ';'  */
#line 614 "exp.y"
                                  {
        declare_array_nd((yyvsp[-2].ident), (yyvsp[-1].dimlist).sizes, (yyvsp[-1].dimlist).count);
        free((yyvsp[-2].ident));
        free((yyvsp[-1].dimlist).sizes);
        (yyval.reg) = NULL;
    }
#line 1758 "exp.tab.c"
    break;

  case 28: /* stmt: IDENT idx_list '=' expr ';'  */
#line 620 "exp.y"
                                  {
        char *ptr = new_tmp();
        build_gep(ptr, (yyvsp[-4].ident), (yyvsp[-3].idxlist).regs);
        fprintf(ir_file, "  store i32 %s, i32* %s, align 4\n", (yyvsp[-1].reg), ptr);
        free((yyvsp[-4].ident));
        free((yyvsp[-3].idxlist).regs);
        (yyval.reg) = ptr;
    }
#line 1771 "exp.tab.c"
    break;

  case 29: /* $@2: %empty  */
#line 630 "exp.y"
      {
          char *cond_label = new_label();
          char *body_label = new_label();
          char *end_label  = new_label();
          fprintf(ir_file, "  br label %%%s\n", cond_label);
          fprintf(ir_file, "%s:\n", cond_label);
          push_labels(cond_label, body_label, end_label);
      }
#line 1784 "exp.tab.c"
    break;

  case 30: /* $@3: %empty  */
#line 639 "exp.y"
      {
          char *cond_label, *body_label, *end_label;
          peek_labels(&cond_label, &body_label, &end_label);
          fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                  (yyvsp[-1].reg), body_label, end_label);
          fprintf(ir_file, "%s:\n", body_label);
      }
#line 1796 "exp.tab.c"
    break;

  case 31: /* stmt: WHILE '(' $@2 cond ')' $@3 '{' stmts '}'  */
#line 647 "exp.y"
      {
          char *cond_label, *body_label, *end_label;
          pop_labels(&cond_label, &body_label, &end_label);
          fprintf(ir_file, "  br label %%%s\n", cond_label);
          fprintf(ir_file, "%s:\n", end_label);
          (yyval.reg) = NULL;
      }
#line 1808 "exp.tab.c"
    break;

  case 32: /* $@4: %empty  */
#line 655 "exp.y"
      {
          char *var_alloca = get_var_alloca((yyvsp[-3].ident));
          fprintf(ir_file, "  store i32 %s, i32* %s, align 4\n", (yyvsp[-1].reg), var_alloca);

          char *cond_label   = new_label();
          char *update_label = new_label();
          char *body_label   = new_label();
          char *end_label    = new_label();

          fprintf(ir_file, "  br label %%%s\n", cond_label);
          fprintf(ir_file, "%s:\n", cond_label);
          push_for_labels(cond_label, update_label, body_label, end_label);
          free((yyvsp[-3].ident));
      }
#line 1827 "exp.tab.c"
    break;

  case 33: /* $@5: %empty  */
#line 670 "exp.y"
      {
          char *cond_label, *update_label, *body_label, *end_label;
          peek_for_labels(&cond_label, &update_label, &body_label, &end_label);
          fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                  (yyvsp[-1].reg), body_label, end_label);
          fprintf(ir_file, "%s:\n", update_label);
      }
#line 1839 "exp.tab.c"
    break;

  case 34: /* $@6: %empty  */
#line 678 "exp.y"
      {
          char *var_alloca = get_var_alloca((yyvsp[-3].ident));
          fprintf(ir_file, "  store i32 %s, i32* %s, align 4\n", (yyvsp[-1].reg), var_alloca);
          char *cond_label, *update_label, *body_label, *end_label;
          peek_for_labels(&cond_label, &update_label, &body_label, &end_label);
          fprintf(ir_file, "  br label %%%s\n", cond_label);
          fprintf(ir_file, "%s:\n", body_label);
          free((yyvsp[-3].ident));
      }
#line 1853 "exp.tab.c"
    break;

  case 35: /* stmt: FOR '(' IDENT '=' expr ';' $@4 cond ';' $@5 IDENT '=' expr ')' $@6 '{' stmts '}'  */
#line 688 "exp.y"
      {
          char *cond_label, *update_label, *body_label, *end_label;
          pop_for_labels(&cond_label, &update_label, &body_label, &end_label);
          fprintf(ir_file, "  br label %%%s\n", update_label);
          fprintf(ir_file, "%s:\n", end_label);
          (yyval.reg) = NULL;
      }
#line 1865 "exp.tab.c"
    break;

  case 36: /* $@7: %empty  */
#line 696 "exp.y"
      {
          char *body_label = new_label();
          char *cond_label = new_label();
          char *end_label  = new_label();
          fprintf(ir_file, "  br label %%%s\n", body_label);
          fprintf(ir_file, "%s:\n", body_label);
          push_labels(cond_label, body_label, end_label);
      }
#line 1878 "exp.tab.c"
    break;

  case 37: /* $@8: %empty  */
#line 705 "exp.y"
      {
          char *cond_label, *body_label, *end_label;
          peek_labels(&cond_label, &body_label, &end_label);
          fprintf(ir_file, "  br label %%%s\n", cond_label);
          fprintf(ir_file, "%s:\n", cond_label);
      }
#line 1889 "exp.tab.c"
    break;

  case 38: /* stmt: DO $@7 '{' stmts '}' $@8 WHILE '(' cond ')' ';'  */
#line 712 "exp.y"
      {
          char *cond_label, *body_label, *end_label;
          pop_labels(&cond_label, &body_label, &end_label);
          fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                  (yyvsp[-2].reg), body_label, end_label);
          fprintf(ir_file, "%s:\n", end_label);
          (yyval.reg) = NULL;
      }
#line 1902 "exp.tab.c"
    break;

  case 39: /* stmt: BREAK ';'  */
#line 720 "exp.y"
                {
        fprintf(ir_file, "  br label %%%s\n", stack_end[stack_top - 1]);
        char *dead = new_label();
        fprintf(ir_file, "%s:\n", dead);
        (yyval.reg) = NULL;
    }
#line 1913 "exp.tab.c"
    break;

  case 40: /* stmt: CONTINUE ';'  */
#line 726 "exp.y"
                   {
        fprintf(ir_file, "  br label %%%s\n", stack_continue[stack_top - 1]);
        char *dead = new_label();
        fprintf(ir_file, "%s:\n", dead);
        (yyval.reg) = NULL;
    }
#line 1924 "exp.tab.c"
    break;

  case 41: /* stmt: if_else_prefix '{' program '}'  */
#line 741 "exp.y"
                                     {
        // Restore the outer ir_file. The current ir_file holds the false body.
        FILE *false_body = ir_file;
        ir_file = (yyvsp[-3].labels).saved_file;

        // Now that we know it's an if/else, emit the deferred conditional branch.
        fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                (yyvsp[-3].labels).cond, (yyvsp[-3].labels).l_true, (yyvsp[-3].labels).l_false);

        // True block: label, replay buffered body, jump to end.
        fprintf(ir_file, "%s:\n", (yyvsp[-3].labels).l_true);
        dump_buffer((yyvsp[-3].labels).true_body);
        fprintf(ir_file, "  br label %%%s\n", (yyvsp[-3].labels).l_end);

        // False block: label, replay buffered body, jump to end.
        fprintf(ir_file, "%s:\n", (yyvsp[-3].labels).l_false);
        dump_buffer(false_body);
        fprintf(ir_file, "  br label %%%s\n", (yyvsp[-3].labels).l_end);

        // Merge.
        fprintf(ir_file, "%s:\n", (yyvsp[-3].labels).l_end);

        free((yyvsp[-3].labels).l_true);
        free((yyvsp[-3].labels).l_false);
        free((yyvsp[-3].labels).l_end);
    }
#line 1955 "exp.tab.c"
    break;

  case 42: /* stmt: if_cond '{' program '}'  */
#line 777 "exp.y"
                              {
        // if-only: the false target is l_end directly — no dummy block.
        FILE *body = ir_file;
        ir_file = (yyvsp[-3].labels).saved_file;

        fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                (yyvsp[-3].labels).cond, (yyvsp[-3].labels).l_true, (yyvsp[-3].labels).l_end);

        fprintf(ir_file, "%s:\n", (yyvsp[-3].labels).l_true);
        dump_buffer(body);
        fprintf(ir_file, "  br label %%%s\n", (yyvsp[-3].labels).l_end);

        fprintf(ir_file, "%s:\n", (yyvsp[-3].labels).l_end);

        free((yyvsp[-3].labels).l_true);
        free((yyvsp[-3].labels).l_end);
        // $1.l_false is NULL in the if-only path — nothing to free.
    }
#line 1978 "exp.tab.c"
    break;

  case 43: /* sc_and_mid: cond AND  */
#line 797 "exp.y"
             {
        char *rhs_label   = new_label();
        char *merge_label = new_label();
        char *sc_slot     = new_tmp();

        /* alloca an i1 slot — default to false (short-circuit case) */
        fprintf(ir_file, "  %s = alloca i1\n", sc_slot);
        fprintf(ir_file, "  store i1 false, i1* %s\n", sc_slot);

        /* if LHS true → go evaluate RHS; if LHS false → skip to merge */
        fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                (yyvsp[-1].reg), rhs_label, merge_label);
        fprintf(ir_file, "%s:\n", rhs_label);

        (yyval.scdata).sc_slot     = sc_slot;
        (yyval.scdata).merge_label = merge_label;
    }
#line 2000 "exp.tab.c"
    break;

  case 44: /* sc_or_mid: cond OR  */
#line 816 "exp.y"
            {
        char *rhs_label   = new_label();
        char *merge_label = new_label();
        char *sc_slot     = new_tmp();

        /* alloca an i1 slot — default to true (short-circuit case) */
        fprintf(ir_file, "  %s = alloca i1\n", sc_slot);
        fprintf(ir_file, "  store i1 true, i1* %s\n", sc_slot);

        /* if LHS true → skip RHS, go to merge; if LHS false → evaluate RHS */
        fprintf(ir_file, "  br i1 %s, label %%%s, label %%%s\n",
                (yyvsp[-1].reg), merge_label, rhs_label);
        fprintf(ir_file, "%s:\n", rhs_label);

        (yyval.scdata).sc_slot     = sc_slot;
        (yyval.scdata).merge_label = merge_label;
    }
#line 2022 "exp.tab.c"
    break;

  case 45: /* cond: expr '<' expr  */
#line 836 "exp.y"
    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = icmp slt i32 %s, %s\n", (yyval.reg), (yyvsp[-2].reg), (yyvsp[0].reg));
    }
#line 2031 "exp.tab.c"
    break;

  case 46: /* cond: expr '>' expr  */
#line 841 "exp.y"
    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = icmp sgt i32 %s, %s\n", (yyval.reg), (yyvsp[-2].reg), (yyvsp[0].reg));
    }
#line 2040 "exp.tab.c"
    break;

  case 47: /* cond: expr LE expr  */
#line 846 "exp.y"
    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = icmp sle i32 %s, %s\n", (yyval.reg), (yyvsp[-2].reg), (yyvsp[0].reg));
    }
#line 2049 "exp.tab.c"
    break;

  case 48: /* cond: expr GE expr  */
#line 851 "exp.y"
    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = icmp sge i32 %s, %s\n", (yyval.reg), (yyvsp[-2].reg), (yyvsp[0].reg));
    }
#line 2058 "exp.tab.c"
    break;

  case 49: /* cond: expr EQ expr  */
#line 856 "exp.y"
    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = icmp eq i32 %s, %s\n", (yyval.reg), (yyvsp[-2].reg), (yyvsp[0].reg));
    }
#line 2067 "exp.tab.c"
    break;

  case 50: /* cond: expr NE expr  */
#line 861 "exp.y"
    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = icmp ne i32 %s, %s\n", (yyval.reg), (yyvsp[-2].reg), (yyvsp[0].reg));
    }
#line 2076 "exp.tab.c"
    break;

  case 51: /* cond: sc_and_mid cond  */
#line 866 "exp.y"
    {
    /* $1 = scdata from mid-rule, $2 = RHS i1 result */

    /* store RHS result into the slot */
    fprintf(ir_file, "  store i1 %s, i1* %s\n", (yyvsp[0].reg), (yyvsp[-1].scdata).sc_slot);
    fprintf(ir_file, "  br label %%%s\n", (yyvsp[-1].scdata).merge_label);

    /* merge block — load the final result */
    fprintf(ir_file, "%s:\n", (yyvsp[-1].scdata).merge_label);
    (yyval.reg) = new_tmp();
    fprintf(ir_file, "  %s = load i1, i1* %s\n", (yyval.reg), (yyvsp[-1].scdata).sc_slot);
    }
#line 2093 "exp.tab.c"
    break;

  case 52: /* cond: sc_or_mid cond  */
#line 879 "exp.y"
    {
    /* $1 = scdata from mid-rule, $2 = RHS i1 result */

    /* store RHS result into the slot */
    fprintf(ir_file, "  store i1 %s, i1* %s\n", (yyvsp[0].reg), (yyvsp[-1].scdata).sc_slot);
    fprintf(ir_file, "  br label %%%s\n", (yyvsp[-1].scdata).merge_label);

    /* merge block — load the final result */
    fprintf(ir_file, "%s:\n", (yyvsp[-1].scdata).merge_label);
    (yyval.reg) = new_tmp();
    fprintf(ir_file, "  %s = load i1, i1* %s\n", (yyval.reg), (yyvsp[-1].scdata).sc_slot);
    }
#line 2110 "exp.tab.c"
    break;

  case 53: /* cond: NOT cond  */
#line 892 "exp.y"
    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = xor i1 %s, true\n", (yyval.reg), (yyvsp[0].reg));
    }
#line 2119 "exp.tab.c"
    break;

  case 54: /* cond: '(' cond ')'  */
#line 897 "exp.y"
    {
        (yyval.reg) = (yyvsp[-1].reg);
    }
#line 2127 "exp.tab.c"
    break;

  case 55: /* cond: expr  */
#line 901 "exp.y"
    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = icmp ne i32 %s, 0\n", (yyval.reg), (yyvsp[0].reg));
    }
#line 2136 "exp.tab.c"
    break;

  case 56: /* expr: INTEGER  */
#line 908 "exp.y"
            {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = add i32 %d, 0\n", (yyval.reg), (yyvsp[0].num));
    }
#line 2145 "exp.tab.c"
    break;

  case 57: /* expr: IDENT  */
#line 912 "exp.y"
            {
        char *var_alloca = get_var_alloca((yyvsp[0].ident));
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = load i32, i32* %s, align 4\n", (yyval.reg), var_alloca);
        free((yyvsp[0].ident));
    }
#line 2156 "exp.tab.c"
    break;

  case 58: /* expr: '-' expr  */
#line 918 "exp.y"
                            {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = sub i32 0, %s\n", (yyval.reg), (yyvsp[0].reg));
    }
#line 2165 "exp.tab.c"
    break;

  case 59: /* expr: expr '+' expr  */
#line 922 "exp.y"
                    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = add i32 %s, %s\n", (yyval.reg), (yyvsp[-2].reg), (yyvsp[0].reg));
    }
#line 2174 "exp.tab.c"
    break;

  case 60: /* expr: expr '-' expr  */
#line 926 "exp.y"
                    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = sub i32 %s, %s\n", (yyval.reg), (yyvsp[-2].reg), (yyvsp[0].reg));
    }
#line 2183 "exp.tab.c"
    break;

  case 61: /* expr: expr '*' expr  */
#line 930 "exp.y"
                    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = mul i32 %s, %s\n", (yyval.reg), (yyvsp[-2].reg), (yyvsp[0].reg));
    }
#line 2192 "exp.tab.c"
    break;

  case 62: /* expr: expr '/' expr  */
#line 934 "exp.y"
                    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = sdiv i32 %s, %s\n", (yyval.reg), (yyvsp[-2].reg), (yyvsp[0].reg));
    }
#line 2201 "exp.tab.c"
    break;

  case 63: /* expr: '(' expr ')'  */
#line 938 "exp.y"
                   {
        (yyval.reg) = (yyvsp[-1].reg);
    }
#line 2209 "exp.tab.c"
    break;

  case 64: /* expr: IDENT idx_list  */
#line 941 "exp.y"
                     {
        char *ptr = new_tmp();
        char *val = new_tmp();
        build_gep(ptr, (yyvsp[-1].ident), (yyvsp[0].idxlist).regs);
        fprintf(ir_file, "  %s = load i32, i32* %s, align 4\n", val, ptr);
        free((yyvsp[-1].ident));
        free((yyvsp[0].idxlist).regs);
        (yyval.reg) = val;
    }
#line 2223 "exp.tab.c"
    break;

  case 65: /* expr: IDENT '(' ')'  */
#line 961 "exp.y"
                    {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = call i32 @%s()\n", (yyval.reg), (yyvsp[-2].ident));
        free((yyvsp[-2].ident));
    }
#line 2233 "exp.tab.c"
    break;

  case 66: /* expr: IDENT '(' arg_list ')'  */
#line 970 "exp.y"
                             {
        (yyval.reg) = new_tmp();
        fprintf(ir_file, "  %s = call i32 @%s(%s)\n", (yyval.reg), (yyvsp[-3].ident), (yyvsp[-1].reg));
        free((yyvsp[-3].ident));
        free((yyvsp[-1].reg));  // arg string spliced into IR; $$ carries the result register up instead
    }
#line 2244 "exp.tab.c"
    break;


#line 2248 "exp.tab.c"

      default: break;
    }
  /* User semantic actions sometimes alter yychar, and that requires
     that yytoken be updated with the new translation.  We take the
     approach of translating immediately before every use of yytoken.
     One alternative is translating here after every semantic action,
     but that translation would be missed if the semantic action invokes
     YYABORT, YYACCEPT, or YYERROR immediately after altering yychar or
     if it invokes YYBACKUP.  In the case of YYABORT or YYACCEPT, an
     incorrect destructor might then be invoked immediately.  In the
     case of YYERROR or YYBACKUP, subsequent parser actions might lead
     to an incorrect destructor call or verbose syntax error message
     before the lookahead is translated.  */
  YY_SYMBOL_PRINT ("-> $$ =", YY_CAST (yysymbol_kind_t, yyr1[yyn]), &yyval, &yyloc);

  YYPOPSTACK (yylen);
  yylen = 0;

  *++yyvsp = yyval;

  /* Now 'shift' the result of the reduction.  Determine what state
     that goes to, based on the state we popped back to and the rule
     number reduced by.  */
  {
    const int yylhs = yyr1[yyn] - YYNTOKENS;
    const int yyi = yypgoto[yylhs] + *yyssp;
    yystate = (0 <= yyi && yyi <= YYLAST && yycheck[yyi] == *yyssp
               ? yytable[yyi]
               : yydefgoto[yylhs]);
  }

  goto yynewstate;


/*--------------------------------------.
| yyerrlab -- here on detecting error.  |
`--------------------------------------*/
yyerrlab:
  /* Make sure we have latest lookahead translation.  See comments at
     user semantic actions for why this is necessary.  */
  yytoken = yychar == YYEMPTY ? YYSYMBOL_YYEMPTY : YYTRANSLATE (yychar);
  /* If not already recovering from an error, report this error.  */
  if (!yyerrstatus)
    {
      ++yynerrs;
      yyerror (YY_("syntax error"));
    }

  if (yyerrstatus == 3)
    {
      /* If just tried and failed to reuse lookahead token after an
         error, discard it.  */

      if (yychar <= YYEOF)
        {
          /* Return failure if at end of input.  */
          if (yychar == YYEOF)
            YYABORT;
        }
      else
        {
          yydestruct ("Error: discarding",
                      yytoken, &yylval);
          yychar = YYEMPTY;
        }
    }

  /* Else will try to reuse lookahead token after shifting the error
     token.  */
  goto yyerrlab1;


/*---------------------------------------------------.
| yyerrorlab -- error raised explicitly by YYERROR.  |
`---------------------------------------------------*/
yyerrorlab:
  /* Pacify compilers when the user code never invokes YYERROR and the
     label yyerrorlab therefore never appears in user code.  */
  if (0)
    YYERROR;
  ++yynerrs;

  /* Do not reclaim the symbols of the rule whose action triggered
     this YYERROR.  */
  YYPOPSTACK (yylen);
  yylen = 0;
  YY_STACK_PRINT (yyss, yyssp);
  yystate = *yyssp;
  goto yyerrlab1;


/*-------------------------------------------------------------.
| yyerrlab1 -- common code for both syntax error and YYERROR.  |
`-------------------------------------------------------------*/
yyerrlab1:
  yyerrstatus = 3;      /* Each real token shifted decrements this.  */

  /* Pop stack until we find a state that shifts the error token.  */
  for (;;)
    {
      yyn = yypact[yystate];
      if (!yypact_value_is_default (yyn))
        {
          yyn += YYSYMBOL_YYerror;
          if (0 <= yyn && yyn <= YYLAST && yycheck[yyn] == YYSYMBOL_YYerror)
            {
              yyn = yytable[yyn];
              if (0 < yyn)
                break;
            }
        }

      /* Pop the current state because it cannot handle the error token.  */
      if (yyssp == yyss)
        YYABORT;


      yydestruct ("Error: popping",
                  YY_ACCESSING_SYMBOL (yystate), yyvsp);
      YYPOPSTACK (1);
      yystate = *yyssp;
      YY_STACK_PRINT (yyss, yyssp);
    }

  YY_IGNORE_MAYBE_UNINITIALIZED_BEGIN
  *++yyvsp = yylval;
  YY_IGNORE_MAYBE_UNINITIALIZED_END


  /* Shift the error token.  */
  YY_SYMBOL_PRINT ("Shifting", YY_ACCESSING_SYMBOL (yyn), yyvsp, yylsp);

  yystate = yyn;
  goto yynewstate;


/*-------------------------------------.
| yyacceptlab -- YYACCEPT comes here.  |
`-------------------------------------*/
yyacceptlab:
  yyresult = 0;
  goto yyreturnlab;


/*-----------------------------------.
| yyabortlab -- YYABORT comes here.  |
`-----------------------------------*/
yyabortlab:
  yyresult = 1;
  goto yyreturnlab;


/*-----------------------------------------------------------.
| yyexhaustedlab -- YYNOMEM (memory exhaustion) comes here.  |
`-----------------------------------------------------------*/
yyexhaustedlab:
  yyerror (YY_("memory exhausted"));
  yyresult = 2;
  goto yyreturnlab;


/*----------------------------------------------------------.
| yyreturnlab -- parsing is finished, clean up and return.  |
`----------------------------------------------------------*/
yyreturnlab:
  if (yychar != YYEMPTY)
    {
      /* Make sure we have latest lookahead translation.  See comments at
         user semantic actions for why this is necessary.  */
      yytoken = YYTRANSLATE (yychar);
      yydestruct ("Cleanup: discarding lookahead",
                  yytoken, &yylval);
    }
  /* Do not reclaim the symbols of the rule whose action triggered
     this YYABORT or YYACCEPT.  */
  YYPOPSTACK (yylen);
  YY_STACK_PRINT (yyss, yyssp);
  while (yyssp != yyss)
    {
      yydestruct ("Cleanup: popping",
                  YY_ACCESSING_SYMBOL (+*yyssp), yyvsp);
      YYPOPSTACK (1);
    }
#ifndef yyoverflow
  if (yyss != yyssa)
    YYSTACK_FREE (yyss);
#endif

  return yyresult;
}

#line 978 "exp.y"


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
