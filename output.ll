; ModuleID = 'expr_compiler'
target triple = "x86_64-unknown-linux-gnu"
declare i32 @printf(i8*, ...)
@.str = constant [4 x i8] c"%d\0A\00"

define i32 @getConstant() {
entry:
  %t91 = add i32 100, 0
  ret i32 %t91
L34:
  ret i32 0
}

define i32 @add(i32 %param_p1, i32 %param_q1) {
entry:
  %var_p1 = alloca i32, align 4
  store i32 %param_p1, i32* %var_p1, align 4
  %var_q1 = alloca i32, align 4
  store i32 %param_q1, i32* %var_q1, align 4
  %t93 = load i32, i32* %var_p1, align 4
  %t94 = load i32, i32* %var_q1, align 4
  %t95 = add i32 %t93, %t94
  ret i32 %t95
L35:
  ret i32 0
}

define i32 @square(i32 %param_n1) {
entry:
  %var_n1 = alloca i32, align 4
  store i32 %param_n1, i32* %var_n1, align 4
  %t99 = load i32, i32* %var_n1, align 4
  %t100 = load i32, i32* %var_n1, align 4
  %t101 = mul i32 %t99, %t100
  ret i32 %t101
L36:
  ret i32 0
}

define i32 @sumOfSquares(i32 %param_m1, i32 %param_n2) {
entry:
  %var_m1 = alloca i32, align 4
  store i32 %param_m1, i32* %var_m1, align 4
  %var_n2 = alloca i32, align 4
  store i32 %param_n2, i32* %var_n2, align 4
  %t102 = load i32, i32* %var_m1, align 4
  %t103 = call i32 @square(i32 %t102)
  %t104 = load i32, i32* %var_n2, align 4
  %t105 = call i32 @square(i32 %t104)
  %t106 = add i32 %t103, %t105
  ret i32 %t106
L37:
  ret i32 0
}

define i32 @scopedFn() {
entry:
  %t111 = add i32 111, 0
  %var_x = alloca i32, align 4
  store i32 %t111, i32* %var_x, align 4
  %t112 = load i32, i32* %var_x, align 4
  ret i32 %t112
L38:
  ret i32 0
}

define i32 @sumArray() {
entry:
  %arr_arr = alloca [5 x i32], align 4
  %t114 = add i32 0, 0
  %var_m2 = alloca i32, align 4
  store i32 %t114, i32* %var_m2, align 4
  br label %L39
L39:
  %t115 = load i32, i32* %var_m2, align 4
  %t116 = add i32 5, 0
  %t117 = icmp slt i32 %t115, %t116
  br i1 %t117, label %L41, label %L42
L40:
  %t118 = load i32, i32* %var_m2, align 4
  %t119 = add i32 1, 0
  %t120 = add i32 %t118, %t119
  store i32 %t120, i32* %var_m2, align 4
  br label %L39
L41:
  %t121 = load i32, i32* %var_m2, align 4
  %t122 = load i32, i32* %var_m2, align 4
  %t123 = add i32 1, 0
  %t124 = add i32 %t122, %t123
  %t125 = getelementptr [5 x i32], [5 x i32]* %arr_arr, i32 0, i32 %t121
  store i32 %t124, i32* %t125, align 4
  br label %L40
L42:
  %t126 = add i32 0, 0
  %var_s1 = alloca i32, align 4
  store i32 %t126, i32* %var_s1, align 4
  %t127 = add i32 0, 0
  %var_m3 = alloca i32, align 4
  store i32 %t127, i32* %var_m3, align 4
  br label %L43
L43:
  %t128 = load i32, i32* %var_m3, align 4
  %t129 = add i32 5, 0
  %t130 = icmp slt i32 %t128, %t129
  br i1 %t130, label %L45, label %L46
L44:
  %t131 = load i32, i32* %var_m3, align 4
  %t132 = add i32 1, 0
  %t133 = add i32 %t131, %t132
  store i32 %t133, i32* %var_m3, align 4
  br label %L43
L45:
  %t134 = load i32, i32* %var_s1, align 4
  %t135 = load i32, i32* %var_m3, align 4
  %t136 = getelementptr [5 x i32], [5 x i32]* %arr_arr, i32 0, i32 %t135
  %t137 = load i32, i32* %t136, align 4
  %t138 = add i32 %t134, %t137
  store i32 %t138, i32* %var_s1, align 4
  br label %L44
L46:
  %t139 = load i32, i32* %var_s1, align 4
  ret i32 %t139
L47:
  ret i32 0
}

define i32 @isSorted() {
entry:
  %arr_arr = alloca [5 x i32], align 4
  %t257 = add i32 0, 0
  %t258 = add i32 1, 0
  %t259 = getelementptr [5 x i32], [5 x i32]* %arr_arr, i32 0, i32 %t257
  store i32 %t258, i32* %t259, align 4
  %t260 = add i32 1, 0
  %t261 = add i32 3, 0
  %t262 = getelementptr [5 x i32], [5 x i32]* %arr_arr, i32 0, i32 %t260
  store i32 %t261, i32* %t262, align 4
  %t263 = add i32 2, 0
  %t264 = add i32 5, 0
  %t265 = getelementptr [5 x i32], [5 x i32]* %arr_arr, i32 0, i32 %t263
  store i32 %t264, i32* %t265, align 4
  %t266 = add i32 3, 0
  %t267 = add i32 7, 0
  %t268 = getelementptr [5 x i32], [5 x i32]* %arr_arr, i32 0, i32 %t266
  store i32 %t267, i32* %t268, align 4
  %t269 = add i32 4, 0
  %t270 = add i32 9, 0
  %t271 = getelementptr [5 x i32], [5 x i32]* %arr_arr, i32 0, i32 %t269
  store i32 %t270, i32* %t271, align 4
  %t272 = add i32 1, 0
  %var_sorted = alloca i32, align 4
  store i32 %t272, i32* %var_sorted, align 4
  %t273 = add i32 0, 0
  %var_t1 = alloca i32, align 4
  store i32 %t273, i32* %var_t1, align 4
  br label %L78
L78:
  %t274 = load i32, i32* %var_t1, align 4
  %t275 = add i32 4, 0
  %t276 = icmp slt i32 %t274, %t275
  br i1 %t276, label %L80, label %L81
L79:
  %t277 = load i32, i32* %var_t1, align 4
  %t278 = add i32 1, 0
  %t279 = add i32 %t277, %t278
  store i32 %t279, i32* %var_t1, align 4
  br label %L78
L80:
  %t280 = load i32, i32* %var_t1, align 4
  %t281 = getelementptr [5 x i32], [5 x i32]* %arr_arr, i32 0, i32 %t280
  %t282 = load i32, i32* %t281, align 4
  %t283 = load i32, i32* %var_t1, align 4
  %t284 = add i32 1, 0
  %t285 = add i32 %t283, %t284
  %t286 = getelementptr [5 x i32], [5 x i32]* %arr_arr, i32 0, i32 %t285
  %t287 = load i32, i32* %t286, align 4
  %t288 = icmp sgt i32 %t282, %t287
  br i1 %t288, label %L82, label %L83
L82:
  %t289 = add i32 0, 0
  store i32 %t289, i32* %var_sorted, align 4
  br label %L83
L83:
  br label %L79
L81:
  %t290 = load i32, i32* %var_sorted, align 4
  ret i32 %t290
L84:
  ret i32 0
}

define i32 @main() {
entry:
  %t0 = add i32 10, 0
  %var_a = alloca i32, align 4
  store i32 %t0, i32* %var_a, align 4
  %t1 = add i32 3, 0
  %var_b = alloca i32, align 4
  store i32 %t1, i32* %var_b, align 4
  %t2 = load i32, i32* %var_a, align 4
  %t3 = load i32, i32* %var_b, align 4
  %t4 = add i32 %t2, %t3
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t4)
  %t5 = load i32, i32* %var_a, align 4
  %t6 = load i32, i32* %var_b, align 4
  %t7 = sub i32 %t5, %t6
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t7)
  %t8 = load i32, i32* %var_a, align 4
  %t9 = load i32, i32* %var_b, align 4
  %t10 = mul i32 %t8, %t9
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t10)
  %t11 = load i32, i32* %var_a, align 4
  %t12 = load i32, i32* %var_b, align 4
  %t13 = sdiv i32 %t11, %t12
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t13)
  %t14 = load i32, i32* %var_a, align 4
  %t15 = sub i32 0, %t14
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t15)
  %t16 = load i32, i32* %var_a, align 4
  %t17 = load i32, i32* %var_b, align 4
  %t18 = icmp sgt i32 %t16, %t17
  br i1 %t18, label %L0, label %L2
L0:
  %t19 = add i32 1, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t19)
  br label %L1
L2:
  %t20 = add i32 0, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t20)
  br label %L1
L1:
  %t21 = add i32 5, 0
  %var_x = alloca i32, align 4
  store i32 %t21, i32* %var_x, align 4
  %t22 = add i32 1, 0
  %t23 = sub i32 0, %t22
  %var_y = alloca i32, align 4
  store i32 %t23, i32* %var_y, align 4
  %t24 = add i32 1, 0
  %t25 = sub i32 0, %t24
  %var_z = alloca i32, align 4
  store i32 %t25, i32* %var_z, align 4
  %t26 = load i32, i32* %var_z, align 4
  %t27 = add i32 0, 0
  %t28 = icmp sgt i32 %t26, %t27
  %t29 = alloca i1
  store i1 false, i1* %t29
  br i1 %t28, label %L3, label %L4
L3:
  %t30 = load i32, i32* %var_x, align 4
  %t31 = add i32 0, 0
  %t32 = icmp sgt i32 %t30, %t31
  %t33 = alloca i1
  store i1 true, i1* %t33
  br i1 %t32, label %L6, label %L5
L5:
  %t34 = load i32, i32* %var_y, align 4
  %t35 = add i32 0, 0
  %t36 = icmp sgt i32 %t34, %t35
  store i1 %t36, i1* %t33
  br label %L6
L6:
  %t37 = load i1, i1* %t33
  store i1 %t37, i1* %t29
  br label %L4
L4:
  %t38 = load i1, i1* %t29
  br i1 %t38, label %L7, label %L9
L7:
  %t39 = add i32 1, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t39)
  br label %L8
L9:
  %t40 = add i32 0, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t40)
  br label %L8
L8:
  %t41 = load i32, i32* %var_x, align 4
  %t42 = add i32 0, 0
  %t43 = icmp sgt i32 %t41, %t42
  %t44 = alloca i1
  store i1 true, i1* %t44
  br i1 %t43, label %L11, label %L10
L10:
  %t45 = load i32, i32* %var_y, align 4
  %t46 = add i32 0, 0
  %t47 = icmp sgt i32 %t45, %t46
  store i1 %t47, i1* %t44
  br label %L11
L11:
  %t48 = load i1, i1* %t44
  br i1 %t48, label %L12, label %L14
L12:
  %t49 = add i32 1, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t49)
  br label %L13
L14:
  %t50 = add i32 0, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t50)
  br label %L13
L13:
  %t51 = load i32, i32* %var_x, align 4
  %t52 = add i32 0, 0
  %t53 = icmp slt i32 %t51, %t52
  %t54 = xor i1 %t53, true
  br i1 %t54, label %L15, label %L17
L15:
  %t55 = add i32 1, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t55)
  br label %L16
L17:
  %t56 = add i32 0, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t56)
  br label %L16
L16:
  %t57 = add i32 1, 0
  %var_i1 = alloca i32, align 4
  store i32 %t57, i32* %var_i1, align 4
  %t58 = add i32 0, 0
  %var_sum = alloca i32, align 4
  store i32 %t58, i32* %var_sum, align 4
  br label %L18
L18:
  %t59 = load i32, i32* %var_i1, align 4
  %t60 = add i32 10, 0
  %t61 = icmp sle i32 %t59, %t60
  br i1 %t61, label %L19, label %L20
L19:
  %t62 = load i32, i32* %var_i1, align 4
  %t63 = add i32 6, 0
  %t64 = icmp eq i32 %t62, %t63
  br i1 %t64, label %L21, label %L22
L21:
  br label %L20
L23:
  br label %L22
L22:
  %t65 = load i32, i32* %var_sum, align 4
  %t66 = load i32, i32* %var_i1, align 4
  %t67 = add i32 %t65, %t66
  store i32 %t67, i32* %var_sum, align 4
  %t68 = load i32, i32* %var_i1, align 4
  %t69 = add i32 1, 0
  %t70 = add i32 %t68, %t69
  store i32 %t70, i32* %var_i1, align 4
  br label %L18
L20:
  %t71 = load i32, i32* %var_sum, align 4
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t71)
  %t72 = add i32 1, 0
  %var_j1 = alloca i32, align 4
  store i32 %t72, i32* %var_j1, align 4
  br label %L24
L24:
  %t73 = load i32, i32* %var_j1, align 4
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t73)
  %t74 = load i32, i32* %var_j1, align 4
  %t75 = add i32 1, 0
  %t76 = add i32 %t74, %t75
  store i32 %t76, i32* %var_j1, align 4
  br label %L25
L25:
  %t77 = load i32, i32* %var_j1, align 4
  %t78 = add i32 3, 0
  %t79 = icmp sle i32 %t77, %t78
  br i1 %t79, label %L24, label %L26
L26:
  %t80 = add i32 1, 0
  %var_k1 = alloca i32, align 4
  store i32 %t80, i32* %var_k1, align 4
  br label %L27
L27:
  %t81 = load i32, i32* %var_k1, align 4
  %t82 = add i32 5, 0
  %t83 = icmp sle i32 %t81, %t82
  br i1 %t83, label %L29, label %L30
L28:
  %t84 = load i32, i32* %var_k1, align 4
  %t85 = add i32 1, 0
  %t86 = add i32 %t84, %t85
  store i32 %t86, i32* %var_k1, align 4
  br label %L27
L29:
  %t87 = load i32, i32* %var_k1, align 4
  %t88 = add i32 3, 0
  %t89 = icmp eq i32 %t87, %t88
  br i1 %t89, label %L31, label %L32
L31:
  br label %L28
L33:
  br label %L32
L32:
  %t90 = load i32, i32* %var_k1, align 4
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t90)
  br label %L28
L30:
  %t92 = call i32 @getConstant()
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t92)
  %t96 = add i32 7, 0
  %t97 = add i32 8, 0
  %t98 = call i32 @add(i32 %t96, i32 %t97)
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t98)
  %t107 = add i32 3, 0
  %t108 = add i32 4, 0
  %t109 = call i32 @sumOfSquares(i32 %t107, i32 %t108)
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t109)
  %t110 = add i32 999, 0
  store i32 %t110, i32* %var_x, align 4
  call i32 @scopedFn()
  %t113 = load i32, i32* %var_x, align 4
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t113)
  %t140 = call i32 @sumArray()
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t140)
  %arr_data = alloca [5 x i32], align 4
  %t141 = add i32 0, 0
  %t142 = add i32 3, 0
  %t143 = getelementptr [5 x i32], [5 x i32]* %arr_data, i32 0, i32 %t141
  store i32 %t142, i32* %t143, align 4
  %t144 = add i32 1, 0
  %t145 = add i32 7, 0
  %t146 = getelementptr [5 x i32], [5 x i32]* %arr_data, i32 0, i32 %t144
  store i32 %t145, i32* %t146, align 4
  %t147 = add i32 2, 0
  %t148 = add i32 1, 0
  %t149 = getelementptr [5 x i32], [5 x i32]* %arr_data, i32 0, i32 %t147
  store i32 %t148, i32* %t149, align 4
  %t150 = add i32 3, 0
  %t151 = add i32 9, 0
  %t152 = getelementptr [5 x i32], [5 x i32]* %arr_data, i32 0, i32 %t150
  store i32 %t151, i32* %t152, align 4
  %t153 = add i32 4, 0
  %t154 = add i32 4, 0
  %t155 = getelementptr [5 x i32], [5 x i32]* %arr_data, i32 0, i32 %t153
  store i32 %t154, i32* %t155, align 4
  %t156 = add i32 0, 0
  %t157 = getelementptr [5 x i32], [5 x i32]* %arr_data, i32 0, i32 %t156
  %t158 = load i32, i32* %t157, align 4
  %var_maxVal = alloca i32, align 4
  store i32 %t158, i32* %var_maxVal, align 4
  %t159 = add i32 1, 0
  %var_n3 = alloca i32, align 4
  store i32 %t159, i32* %var_n3, align 4
  br label %L48
L48:
  %t160 = load i32, i32* %var_n3, align 4
  %t161 = add i32 5, 0
  %t162 = icmp slt i32 %t160, %t161
  br i1 %t162, label %L50, label %L51
L49:
  %t163 = load i32, i32* %var_n3, align 4
  %t164 = add i32 1, 0
  %t165 = add i32 %t163, %t164
  store i32 %t165, i32* %var_n3, align 4
  br label %L48
L50:
  %t166 = load i32, i32* %var_n3, align 4
  %t167 = getelementptr [5 x i32], [5 x i32]* %arr_data, i32 0, i32 %t166
  %t168 = load i32, i32* %t167, align 4
  %t169 = load i32, i32* %var_maxVal, align 4
  %t170 = icmp sgt i32 %t168, %t169
  br i1 %t170, label %L52, label %L53
L52:
  %t171 = load i32, i32* %var_n3, align 4
  %t172 = getelementptr [5 x i32], [5 x i32]* %arr_data, i32 0, i32 %t171
  %t173 = load i32, i32* %t172, align 4
  store i32 %t173, i32* %var_maxVal, align 4
  br label %L53
L53:
  br label %L49
L51:
  %t174 = load i32, i32* %var_maxVal, align 4
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t174)
  %arr_mat = alloca [3 x [3 x i32]], align 4
  %t175 = add i32 0, 0
  %var_p2 = alloca i32, align 4
  store i32 %t175, i32* %var_p2, align 4
  br label %L54
L54:
  %t176 = load i32, i32* %var_p2, align 4
  %t177 = add i32 3, 0
  %t178 = icmp slt i32 %t176, %t177
  br i1 %t178, label %L56, label %L57
L55:
  %t179 = load i32, i32* %var_p2, align 4
  %t180 = add i32 1, 0
  %t181 = add i32 %t179, %t180
  store i32 %t181, i32* %var_p2, align 4
  br label %L54
L56:
  %t182 = add i32 0, 0
  %var_q2 = alloca i32, align 4
  store i32 %t182, i32* %var_q2, align 4
  br label %L58
L58:
  %t183 = load i32, i32* %var_q2, align 4
  %t184 = add i32 3, 0
  %t185 = icmp slt i32 %t183, %t184
  br i1 %t185, label %L60, label %L61
L59:
  %t186 = load i32, i32* %var_q2, align 4
  %t187 = add i32 1, 0
  %t188 = add i32 %t186, %t187
  store i32 %t188, i32* %var_q2, align 4
  br label %L58
L60:
  %t189 = load i32, i32* %var_p2, align 4
  %t190 = load i32, i32* %var_q2, align 4
  %t191 = load i32, i32* %var_p2, align 4
  %t192 = add i32 3, 0
  %t193 = mul i32 %t191, %t192
  %t194 = load i32, i32* %var_q2, align 4
  %t195 = add i32 %t193, %t194
  %t196 = add i32 1, 0
  %t197 = add i32 %t195, %t196
  %t198 = getelementptr [3 x [3 x i32]], [3 x [3 x i32]]* %arr_mat, i32 0, i32 %t189, i32 %t190
  store i32 %t197, i32* %t198, align 4
  br label %L59
L61:
  br label %L55
L57:
  %t199 = add i32 0, 0
  %var_trace = alloca i32, align 4
  store i32 %t199, i32* %var_trace, align 4
  %t200 = add i32 0, 0
  %var_p3 = alloca i32, align 4
  store i32 %t200, i32* %var_p3, align 4
  br label %L62
L62:
  %t201 = load i32, i32* %var_p3, align 4
  %t202 = add i32 3, 0
  %t203 = icmp slt i32 %t201, %t202
  br i1 %t203, label %L64, label %L65
L63:
  %t204 = load i32, i32* %var_p3, align 4
  %t205 = add i32 1, 0
  %t206 = add i32 %t204, %t205
  store i32 %t206, i32* %var_p3, align 4
  br label %L62
L64:
  %t207 = load i32, i32* %var_trace, align 4
  %t208 = load i32, i32* %var_p3, align 4
  %t209 = load i32, i32* %var_p3, align 4
  %t210 = getelementptr [3 x [3 x i32]], [3 x [3 x i32]]* %arr_mat, i32 0, i32 %t208, i32 %t209
  %t211 = load i32, i32* %t210, align 4
  %t212 = add i32 %t207, %t211
  store i32 %t212, i32* %var_trace, align 4
  br label %L63
L65:
  %t213 = load i32, i32* %var_trace, align 4
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t213)
  %arr_cube = alloca [2 x [2 x [2 x i32]]], align 4
  %t214 = add i32 0, 0
  %var_total = alloca i32, align 4
  store i32 %t214, i32* %var_total, align 4
  %t215 = add i32 0, 0
  %var_p4 = alloca i32, align 4
  store i32 %t215, i32* %var_p4, align 4
  br label %L66
L66:
  %t216 = load i32, i32* %var_p4, align 4
  %t217 = add i32 2, 0
  %t218 = icmp slt i32 %t216, %t217
  br i1 %t218, label %L68, label %L69
L67:
  %t219 = load i32, i32* %var_p4, align 4
  %t220 = add i32 1, 0
  %t221 = add i32 %t219, %t220
  store i32 %t221, i32* %var_p4, align 4
  br label %L66
L68:
  %t222 = add i32 0, 0
  %var_q3 = alloca i32, align 4
  store i32 %t222, i32* %var_q3, align 4
  br label %L70
L70:
  %t223 = load i32, i32* %var_q3, align 4
  %t224 = add i32 2, 0
  %t225 = icmp slt i32 %t223, %t224
  br i1 %t225, label %L72, label %L73
L71:
  %t226 = load i32, i32* %var_q3, align 4
  %t227 = add i32 1, 0
  %t228 = add i32 %t226, %t227
  store i32 %t228, i32* %var_q3, align 4
  br label %L70
L72:
  %t229 = add i32 0, 0
  %var_r1 = alloca i32, align 4
  store i32 %t229, i32* %var_r1, align 4
  br label %L74
L74:
  %t230 = load i32, i32* %var_r1, align 4
  %t231 = add i32 2, 0
  %t232 = icmp slt i32 %t230, %t231
  br i1 %t232, label %L76, label %L77
L75:
  %t233 = load i32, i32* %var_r1, align 4
  %t234 = add i32 1, 0
  %t235 = add i32 %t233, %t234
  store i32 %t235, i32* %var_r1, align 4
  br label %L74
L76:
  %t236 = load i32, i32* %var_p4, align 4
  %t237 = load i32, i32* %var_q3, align 4
  %t238 = load i32, i32* %var_r1, align 4
  %t239 = load i32, i32* %var_p4, align 4
  %t240 = add i32 4, 0
  %t241 = mul i32 %t239, %t240
  %t242 = load i32, i32* %var_q3, align 4
  %t243 = add i32 2, 0
  %t244 = mul i32 %t242, %t243
  %t245 = add i32 %t241, %t244
  %t246 = load i32, i32* %var_r1, align 4
  %t247 = add i32 %t245, %t246
  %t248 = getelementptr [2 x [2 x [2 x i32]]], [2 x [2 x [2 x i32]]]* %arr_cube, i32 0, i32 %t236, i32 %t237, i32 %t238
  store i32 %t247, i32* %t248, align 4
  %t249 = load i32, i32* %var_total, align 4
  %t250 = load i32, i32* %var_p4, align 4
  %t251 = load i32, i32* %var_q3, align 4
  %t252 = load i32, i32* %var_r1, align 4
  %t253 = getelementptr [2 x [2 x [2 x i32]]], [2 x [2 x [2 x i32]]]* %arr_cube, i32 0, i32 %t250, i32 %t251, i32 %t252
  %t254 = load i32, i32* %t253, align 4
  %t255 = add i32 %t249, %t254
  store i32 %t255, i32* %var_total, align 4
  br label %L75
L77:
  br label %L71
L73:
  br label %L67
L69:
  %t256 = load i32, i32* %var_total, align 4
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t256)
  %t291 = call i32 @isSorted()
  %t292 = add i32 1, 0
  %t293 = icmp eq i32 %t291, %t292
  %t294 = alloca i1
  store i1 false, i1* %t294
  br i1 %t293, label %L85, label %L86
L85:
  %t295 = load i32, i32* %var_maxVal, align 4
  %t296 = add i32 0, 0
  %t297 = icmp sgt i32 %t295, %t296
  store i1 %t297, i1* %t294
  br label %L86
L86:
  %t298 = load i1, i1* %t294
  br i1 %t298, label %L87, label %L89
L87:
  %t299 = add i32 1, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t299)
  br label %L88
L89:
  %t300 = add i32 0, 0
  call i32 (i8*, ...) @printf(i8* getelementptr ([4 x i8], [4 x i8]* @.str, i32 0, i32 0), i32 %t300)
  br label %L88
L88:
  ret i32 0
}
