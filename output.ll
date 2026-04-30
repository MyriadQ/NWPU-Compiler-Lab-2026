; ModuleID = 'expr_compiler'
target triple = "x86_64-unknown-linux-gnu"
declare i32 @printf(i8*, ...)
@.str = constant [4 x i8] c"%d\0A\00"

define i32 @main() {
  %t0 = add i32 10, 0
  %var_a = alloca i32, align 4
  store i32 %t0, i32* %var_a, align 4
  %t1 = load i32, i32* %var_a, align 4
  %t2 = add i32 50, 0
  %t3 = icmp slt i32 %t1, %t2
  br i1 %t3, label %L0, label %L1
L0:
  %t4 = add i32 1, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t4)
  br label %L1
L1:
  ret i32 0
}
