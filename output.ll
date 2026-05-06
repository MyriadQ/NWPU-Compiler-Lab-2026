; ModuleID = 'expr_compiler'
target triple = "x86_64-unknown-linux-gnu"
declare i32 @printf(i8*, ...)
@.str = constant [4 x i8] c"%d\0A\00"

define i32 @main() {
entry:
  %t0 = add i32 0, 0
  %var_x = alloca i32, align 4
  store i32 %t0, i32* %var_x, align 4
  br label %L0
L0:
  %t1 = load i32, i32* %var_x, align 4
  %t2 = add i32 1, 0
  %t3 = add i32 %t1, %t2
  store i32 %t3, i32* %var_x, align 4
  br label %L1
L1:
  %t4 = load i32, i32* %var_x, align 4
  %t5 = add i32 5, 0
  %t6 = icmp slt i32 %t4, %t5
  br i1 %t6, label %L0, label %L2
L2:
  %t7 = load i32, i32* %var_x, align 4
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t7)
  ret i32 0
}
