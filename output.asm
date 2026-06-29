	.text
	.intel_syntax noprefix
	.file	"output.ll"
	.globl	getConstant                     # -- Begin function getConstant
	.p2align	4, 0x90
	.type	getConstant,@function
getConstant:                            # @getConstant
	.cfi_startproc
# %bb.0:                                # %entry
	mov	eax, 100
	ret
.Lfunc_end0:
	.size	getConstant, .Lfunc_end0-getConstant
	.cfi_endproc
                                        # -- End function
	.globl	add                             # -- Begin function add
	.p2align	4, 0x90
	.type	add,@function
add:                                    # @add
	.cfi_startproc
# %bb.0:                                # %entry
                                        # kill: def $esi killed $esi def $rsi
                                        # kill: def $edi killed $edi def $rdi
	mov	dword ptr [rsp - 4], edi
	mov	dword ptr [rsp - 8], esi
	lea	eax, [rdi + rsi]
	ret
.Lfunc_end1:
	.size	add, .Lfunc_end1-add
	.cfi_endproc
                                        # -- End function
	.globl	square                          # -- Begin function square
	.p2align	4, 0x90
	.type	square,@function
square:                                 # @square
	.cfi_startproc
# %bb.0:                                # %entry
	mov	eax, edi
	mov	dword ptr [rsp - 4], edi
	imul	eax, edi
	ret
.Lfunc_end2:
	.size	square, .Lfunc_end2-square
	.cfi_endproc
                                        # -- End function
	.globl	sumOfSquares                    # -- Begin function sumOfSquares
	.p2align	4, 0x90
	.type	sumOfSquares,@function
sumOfSquares:                           # @sumOfSquares
	.cfi_startproc
# %bb.0:                                # %entry
	push	rbx
	.cfi_def_cfa_offset 16
	sub	rsp, 16
	.cfi_def_cfa_offset 32
	.cfi_offset rbx, -16
	mov	dword ptr [rsp + 12], edi
	mov	dword ptr [rsp + 8], esi
	call	square@PLT
	mov	ebx, eax
	mov	edi, dword ptr [rsp + 8]
	call	square@PLT
	add	eax, ebx
	add	rsp, 16
	.cfi_def_cfa_offset 16
	pop	rbx
	.cfi_def_cfa_offset 8
	ret
.Lfunc_end3:
	.size	sumOfSquares, .Lfunc_end3-sumOfSquares
	.cfi_endproc
                                        # -- End function
	.globl	scopedFn                        # -- Begin function scopedFn
	.p2align	4, 0x90
	.type	scopedFn,@function
scopedFn:                               # @scopedFn
	.cfi_startproc
# %bb.0:                                # %entry
	mov	dword ptr [rsp - 4], 111
	mov	eax, 111
	ret
.Lfunc_end4:
	.size	scopedFn, .Lfunc_end4-scopedFn
	.cfi_endproc
                                        # -- End function
	.globl	sumArray                        # -- Begin function sumArray
	.p2align	4, 0x90
	.type	sumArray,@function
sumArray:                               # @sumArray
	.cfi_startproc
# %bb.0:                                # %entry
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset rbp, -16
	mov	rbp, rsp
	.cfi_def_cfa_register rbp
	sub	rsp, 32
	mov	dword ptr [rbp - 4], 0
	cmp	dword ptr [rbp - 4], 5
	jge	.LBB5_3
	.p2align	4, 0x90
.LBB5_2:                                # %L41
                                        # =>This Inner Loop Header: Depth=1
	movsxd	rax, dword ptr [rbp - 4]
	lea	ecx, [rax + 1]
	mov	dword ptr [rbp + 4*rax - 24], ecx
	inc	dword ptr [rbp - 4]
	cmp	dword ptr [rbp - 4], 5
	jl	.LBB5_2
.LBB5_3:                                # %L42
	mov	rcx, rsp
	lea	rax, [rcx - 16]
	mov	rsp, rax
	mov	dword ptr [rcx - 16], 0
	mov	rdx, rsp
	lea	rcx, [rdx - 16]
	mov	rsp, rcx
	mov	dword ptr [rdx - 16], 0
	cmp	dword ptr [rcx], 5
	jge	.LBB5_6
	.p2align	4, 0x90
.LBB5_5:                                # %L45
                                        # =>This Inner Loop Header: Depth=1
	movsxd	rdx, dword ptr [rcx]
	mov	edx, dword ptr [rbp + 4*rdx - 24]
	add	dword ptr [rax], edx
	inc	dword ptr [rcx]
	cmp	dword ptr [rcx], 5
	jl	.LBB5_5
.LBB5_6:                                # %L46
	mov	eax, dword ptr [rax]
	mov	rsp, rbp
	pop	rbp
	.cfi_def_cfa rsp, 8
	ret
.Lfunc_end5:
	.size	sumArray, .Lfunc_end5-sumArray
	.cfi_endproc
                                        # -- End function
	.globl	isSorted                        # -- Begin function isSorted
	.p2align	4, 0x90
	.type	isSorted,@function
isSorted:                               # @isSorted
	.cfi_startproc
# %bb.0:                                # %entry
	movabs	rax, 12884901889
	mov	qword ptr [rsp - 20], rax
	movabs	rax, 30064771077
	mov	qword ptr [rsp - 12], rax
	mov	dword ptr [rsp - 4], 9
	mov	dword ptr [rsp - 24], 1
	mov	dword ptr [rsp - 28], 0
	jmp	.LBB6_1
	.p2align	4, 0x90
.LBB6_4:                                # %L83
                                        #   in Loop: Header=BB6_1 Depth=1
	inc	dword ptr [rsp - 28]
.LBB6_1:                                # %L78
                                        # =>This Inner Loop Header: Depth=1
	cmp	dword ptr [rsp - 28], 3
	jg	.LBB6_5
# %bb.2:                                # %L80
                                        #   in Loop: Header=BB6_1 Depth=1
	movsxd	rax, dword ptr [rsp - 28]
	mov	ecx, dword ptr [rsp + 4*rax - 20]
	inc	eax
	cdqe
	cmp	ecx, dword ptr [rsp + 4*rax - 20]
	jle	.LBB6_4
# %bb.3:                                # %L82
                                        #   in Loop: Header=BB6_1 Depth=1
	mov	dword ptr [rsp - 24], 0
	jmp	.LBB6_4
.LBB6_5:                                # %L81
	mov	eax, dword ptr [rsp - 24]
	ret
.Lfunc_end6:
	.size	isSorted, .Lfunc_end6-isSorted
	.cfi_endproc
                                        # -- End function
	.globl	main                            # -- Begin function main
	.p2align	4, 0x90
	.type	main,@function
main:                                   # @main
	.cfi_startproc
# %bb.0:                                # %entry
	push	rbp
	.cfi_def_cfa_offset 16
	.cfi_offset rbp, -16
	mov	rbp, rsp
	.cfi_def_cfa_register rbp
	push	r15
	push	r14
	push	rbx
	push	rax
	.cfi_offset rbx, -40
	.cfi_offset r14, -32
	.cfi_offset r15, -24
	mov	dword ptr [rbp - 28], 10
	mov	dword ptr [rbp - 32], 3
	mov	rbx, qword ptr [rip + .str@GOTPCREL]
	mov	rdi, rbx
	mov	esi, 13
	xor	eax, eax
	call	printf@PLT
	mov	esi, dword ptr [rbp - 28]
	sub	esi, dword ptr [rbp - 32]
	mov	rdi, rbx
	xor	eax, eax
	call	printf@PLT
	mov	esi, dword ptr [rbp - 28]
	imul	esi, dword ptr [rbp - 32]
	mov	rdi, rbx
	xor	eax, eax
	call	printf@PLT
	mov	eax, dword ptr [rbp - 28]
	cdq
	idiv	dword ptr [rbp - 32]
	mov	rdi, rbx
	mov	esi, eax
	xor	eax, eax
	call	printf@PLT
	xor	esi, esi
	sub	esi, dword ptr [rbp - 28]
	mov	rdi, rbx
	xor	eax, eax
	call	printf@PLT
	mov	eax, dword ptr [rbp - 28]
	cmp	eax, dword ptr [rbp - 32]
	jle	.LBB7_2
# %bb.1:                                # %L0
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	mov	esi, 1
	jmp	.LBB7_3
.LBB7_2:                                # %L2
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	xor	esi, esi
.LBB7_3:                                # %L1
	xor	eax, eax
	call	printf@PLT
	mov	rax, rsp
	lea	r14, [rax - 16]
	mov	rsp, r14
	mov	dword ptr [rax - 16], 5
	mov	rax, rsp
	lea	rbx, [rax - 16]
	mov	rsp, rbx
	mov	dword ptr [rax - 16], -1
	mov	rax, rsp
	lea	rsp, [rax - 16]
	mov	dword ptr [rax - 16], -1
	mov	rcx, rsp
	lea	rax, [rcx - 16]
	mov	rsp, rax
	mov	byte ptr [rcx - 16], 0
	mov	cl, 1
	test	cl, cl
	jne	.LBB7_7
# %bb.4:                                # %L3
	mov	rdx, rsp
	lea	rcx, [rdx - 16]
	mov	rsp, rcx
	cmp	dword ptr [r14], 0
	mov	byte ptr [rdx - 16], 1
	jg	.LBB7_6
# %bb.5:                                # %L5
	cmp	dword ptr [rbx], 0
	setg	byte ptr [rcx]
.LBB7_6:                                # %L6
	movzx	ecx, byte ptr [rcx]
	mov	byte ptr [rax], cl
.LBB7_7:                                # %L4
	cmp	byte ptr [rax], 1
	jne	.LBB7_9
# %bb.8:                                # %L7
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	mov	esi, 1
	jmp	.LBB7_10
.LBB7_9:                                # %L9
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	xor	esi, esi
.LBB7_10:                               # %L8
	xor	eax, eax
	call	printf@PLT
	mov	rcx, rsp
	lea	rax, [rcx - 16]
	mov	rsp, rax
	cmp	dword ptr [r14], 0
	mov	byte ptr [rcx - 16], 1
	jg	.LBB7_12
# %bb.11:                               # %L10
	cmp	dword ptr [rbx], 0
	setg	byte ptr [rax]
.LBB7_12:                               # %L11
	cmp	byte ptr [rax], 1
	jne	.LBB7_14
# %bb.13:                               # %L12
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	mov	esi, 1
	jmp	.LBB7_15
.LBB7_14:                               # %L14
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	xor	esi, esi
.LBB7_15:                               # %L13
	xor	eax, eax
	call	printf@PLT
	cmp	dword ptr [r14], 0
	js	.LBB7_17
# %bb.16:                               # %L15
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	mov	esi, 1
	jmp	.LBB7_18
.LBB7_17:                               # %L17
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	xor	esi, esi
.LBB7_18:                               # %L16
	xor	eax, eax
	call	printf@PLT
	mov	rcx, rsp
	lea	rax, [rcx - 16]
	mov	rsp, rax
	mov	dword ptr [rcx - 16], 1
	mov	rdx, rsp
	lea	rcx, [rdx - 16]
	mov	rsp, rcx
	mov	dword ptr [rdx - 16], 0
	cmp	dword ptr [rax], 10
	jg	.LBB7_22
	.p2align	4, 0x90
.LBB7_20:                               # %L19
                                        # =>This Inner Loop Header: Depth=1
	cmp	dword ptr [rax], 6
	je	.LBB7_22
# %bb.21:                               # %L22
                                        #   in Loop: Header=BB7_20 Depth=1
	mov	edx, dword ptr [rax]
	add	dword ptr [rcx], edx
	inc	dword ptr [rax]
	cmp	dword ptr [rax], 10
	jle	.LBB7_20
.LBB7_22:                               # %L20
	mov	esi, dword ptr [rcx]
	mov	rbx, qword ptr [rip + .str@GOTPCREL]
	mov	rdi, rbx
	xor	eax, eax
	call	printf@PLT
	mov	rax, rsp
	lea	r15, [rax - 16]
	mov	rsp, r15
	mov	dword ptr [rax - 16], 1
	.p2align	4, 0x90
.LBB7_23:                               # %L24
                                        # =>This Inner Loop Header: Depth=1
	mov	esi, dword ptr [r15]
	mov	rdi, rbx
	xor	eax, eax
	call	printf@PLT
	mov	eax, dword ptr [r15]
	inc	eax
	mov	dword ptr [r15], eax
	cmp	eax, 4
	jl	.LBB7_23
# %bb.24:                               # %L26
	mov	rax, rsp
	lea	r15, [rax - 16]
	mov	rsp, r15
	mov	dword ptr [rax - 16], 1
	mov	rbx, qword ptr [rip + .str@GOTPCREL]
	jmp	.LBB7_25
	.p2align	4, 0x90
.LBB7_28:                               # %L28
                                        #   in Loop: Header=BB7_25 Depth=1
	inc	dword ptr [r15]
.LBB7_25:                               # %L27
                                        # =>This Inner Loop Header: Depth=1
	cmp	dword ptr [r15], 6
	jge	.LBB7_29
# %bb.26:                               # %L29
                                        #   in Loop: Header=BB7_25 Depth=1
	cmp	dword ptr [r15], 3
	je	.LBB7_28
# %bb.27:                               # %L32
                                        #   in Loop: Header=BB7_25 Depth=1
	mov	esi, dword ptr [r15]
	mov	rdi, rbx
	xor	eax, eax
	call	printf@PLT
	jmp	.LBB7_28
.LBB7_29:                               # %L30
	call	getConstant@PLT
	mov	rbx, qword ptr [rip + .str@GOTPCREL]
	mov	rdi, rbx
	mov	esi, eax
	xor	eax, eax
	call	printf@PLT
	mov	edi, 7
	mov	esi, 8
	call	add@PLT
	mov	rdi, rbx
	mov	esi, eax
	xor	eax, eax
	call	printf@PLT
	mov	edi, 3
	mov	esi, 4
	call	sumOfSquares@PLT
	mov	rdi, rbx
	mov	esi, eax
	xor	eax, eax
	call	printf@PLT
	mov	dword ptr [r14], 999
	call	scopedFn@PLT
	mov	esi, dword ptr [r14]
	mov	rdi, rbx
	xor	eax, eax
	call	printf@PLT
	call	sumArray@PLT
	mov	rdi, rbx
	mov	esi, eax
	xor	eax, eax
	call	printf@PLT
	mov	rcx, rsp
	lea	rax, [rcx - 32]
	mov	rsp, rax
	movabs	rdx, 30064771075
	mov	qword ptr [rcx - 32], rdx
	movabs	rdx, 38654705665
	mov	qword ptr [rcx - 24], rdx
	mov	dword ptr [rcx - 16], 4
	mov	rcx, rsp
	lea	rbx, [rcx - 16]
	mov	rsp, rbx
	mov	dword ptr [rcx - 16], 3
	mov	rdx, rsp
	lea	rcx, [rdx - 16]
	mov	rsp, rcx
	mov	dword ptr [rdx - 16], 1
	jmp	.LBB7_30
	.p2align	4, 0x90
.LBB7_33:                               # %L53
                                        #   in Loop: Header=BB7_30 Depth=1
	inc	dword ptr [rcx]
.LBB7_30:                               # %L48
                                        # =>This Inner Loop Header: Depth=1
	cmp	dword ptr [rcx], 4
	jg	.LBB7_34
# %bb.31:                               # %L50
                                        #   in Loop: Header=BB7_30 Depth=1
	movsxd	rdx, dword ptr [rcx]
	mov	edx, dword ptr [rax + 4*rdx]
	cmp	edx, dword ptr [rbx]
	jle	.LBB7_33
# %bb.32:                               # %L52
                                        #   in Loop: Header=BB7_30 Depth=1
	movsxd	rdx, dword ptr [rcx]
	mov	edx, dword ptr [rax + 4*rdx]
	mov	dword ptr [rbx], edx
	jmp	.LBB7_33
.LBB7_34:                               # %L51
	mov	esi, dword ptr [rbx]
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	xor	eax, eax
	call	printf@PLT
	mov	rax, rsp
	add	rax, -48
	mov	rsp, rax
	mov	rdx, rsp
	lea	rcx, [rdx - 16]
	mov	rsp, rcx
	mov	dword ptr [rdx - 16], 0
	jmp	.LBB7_35
	.p2align	4, 0x90
.LBB7_39:                               # %L61
                                        #   in Loop: Header=BB7_35 Depth=1
	inc	dword ptr [rcx]
.LBB7_35:                               # %L54
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB7_38 Depth 2
	cmp	dword ptr [rcx], 2
	jg	.LBB7_40
# %bb.36:                               # %L56
                                        #   in Loop: Header=BB7_35 Depth=1
	mov	rsi, rsp
	lea	rdx, [rsi - 16]
	mov	rsp, rdx
	mov	dword ptr [rsi - 16], 0
	cmp	dword ptr [rdx], 2
	jg	.LBB7_39
	.p2align	4, 0x90
.LBB7_38:                               # %L60
                                        #   Parent Loop BB7_35 Depth=1
                                        # =>  This Inner Loop Header: Depth=2
	movsxd	rsi, dword ptr [rcx]
	movsxd	rdi, dword ptr [rdx]
	lea	r8d, [rsi + 2*rsi]
	lea	r8d, [rdi + r8 + 1]
	lea	rsi, [rsi + 2*rsi]
	lea	rsi, [rax + 4*rsi]
	mov	dword ptr [rsi + 4*rdi], r8d
	inc	dword ptr [rdx]
	cmp	dword ptr [rdx], 2
	jle	.LBB7_38
	jmp	.LBB7_39
.LBB7_40:                               # %L57
	mov	rdx, rsp
	lea	rcx, [rdx - 16]
	mov	rsp, rcx
	mov	dword ptr [rdx - 16], 0
	mov	rsi, rsp
	lea	rdx, [rsi - 16]
	mov	rsp, rdx
	mov	dword ptr [rsi - 16], 0
	cmp	dword ptr [rdx], 2
	jg	.LBB7_43
	.p2align	4, 0x90
.LBB7_42:                               # %L64
                                        # =>This Inner Loop Header: Depth=1
	movsxd	rsi, dword ptr [rdx]
	lea	rdi, [rsi + 2*rsi]
	lea	rdi, [rax + 4*rdi]
	mov	esi, dword ptr [rdi + 4*rsi]
	add	dword ptr [rcx], esi
	inc	dword ptr [rdx]
	cmp	dword ptr [rdx], 2
	jle	.LBB7_42
.LBB7_43:                               # %L65
	mov	esi, dword ptr [rcx]
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	xor	eax, eax
	call	printf@PLT
	mov	rax, rsp
	add	rax, -32
	mov	rsp, rax
	mov	rdx, rsp
	lea	rcx, [rdx - 16]
	mov	rsp, rcx
	mov	dword ptr [rdx - 16], 0
	mov	rsi, rsp
	lea	rdx, [rsi - 16]
	mov	rsp, rdx
	mov	dword ptr [rsi - 16], 0
	jmp	.LBB7_44
	.p2align	4, 0x90
.LBB7_51:                               # %L73
                                        #   in Loop: Header=BB7_44 Depth=1
	inc	dword ptr [rdx]
.LBB7_44:                               # %L66
                                        # =>This Loop Header: Depth=1
                                        #     Child Loop BB7_46 Depth 2
                                        #       Child Loop BB7_49 Depth 3
	cmp	dword ptr [rdx], 1
	jg	.LBB7_52
# %bb.45:                               # %L68
                                        #   in Loop: Header=BB7_44 Depth=1
	mov	rdi, rsp
	lea	rsi, [rdi - 16]
	mov	rsp, rsi
	mov	dword ptr [rdi - 16], 0
	jmp	.LBB7_46
	.p2align	4, 0x90
.LBB7_50:                               # %L77
                                        #   in Loop: Header=BB7_46 Depth=2
	inc	dword ptr [rsi]
.LBB7_46:                               # %L70
                                        #   Parent Loop BB7_44 Depth=1
                                        # =>  This Loop Header: Depth=2
                                        #       Child Loop BB7_49 Depth 3
	cmp	dword ptr [rsi], 1
	jg	.LBB7_51
# %bb.47:                               # %L72
                                        #   in Loop: Header=BB7_46 Depth=2
	mov	r8, rsp
	lea	rdi, [r8 - 16]
	mov	rsp, rdi
	mov	dword ptr [r8 - 16], 0
	cmp	dword ptr [rdi], 1
	jg	.LBB7_50
	.p2align	4, 0x90
.LBB7_49:                               # %L76
                                        #   Parent Loop BB7_44 Depth=1
                                        #     Parent Loop BB7_46 Depth=2
                                        # =>    This Inner Loop Header: Depth=3
	movsxd	r8, dword ptr [rdx]
	movsxd	r9, dword ptr [rsi]
	movsxd	r10, dword ptr [rdi]
	lea	r11d, [r9 + r9]
	lea	r11d, [r11 + 4*r8]
	add	r11d, r10d
	shl	r8, 4
	add	r8, rax
	lea	r8, [r8 + 8*r9]
	mov	dword ptr [r8 + 4*r10], r11d
	movsxd	r8, dword ptr [rdx]
	movsxd	r9, dword ptr [rsi]
	movsxd	r10, dword ptr [rdi]
	shl	r8, 4
	add	r8, rax
	lea	r8, [r8 + 8*r9]
	mov	r8d, dword ptr [r8 + 4*r10]
	add	dword ptr [rcx], r8d
	inc	dword ptr [rdi]
	cmp	dword ptr [rdi], 1
	jle	.LBB7_49
	jmp	.LBB7_50
.LBB7_52:                               # %L69
	mov	esi, dword ptr [rcx]
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	xor	eax, eax
	call	printf@PLT
	call	isSorted@PLT
	mov	rdx, rsp
	lea	rcx, [rdx - 16]
	mov	rsp, rcx
	cmp	eax, 1
	mov	byte ptr [rdx - 16], 0
	jne	.LBB7_54
# %bb.53:                               # %L85
	cmp	dword ptr [rbx], 0
	setg	byte ptr [rcx]
.LBB7_54:                               # %L86
	cmp	byte ptr [rcx], 1
	jne	.LBB7_56
# %bb.55:                               # %L87
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	mov	esi, 1
	jmp	.LBB7_57
.LBB7_56:                               # %L89
	mov	rdi, qword ptr [rip + .str@GOTPCREL]
	xor	esi, esi
.LBB7_57:                               # %L88
	xor	eax, eax
	call	printf@PLT
	xor	eax, eax
	lea	rsp, [rbp - 24]
	pop	rbx
	pop	r14
	pop	r15
	pop	rbp
	.cfi_def_cfa rsp, 8
	ret
.Lfunc_end7:
	.size	main, .Lfunc_end7-main
	.cfi_endproc
                                        # -- End function
	.type	.str,@object                    # @.str
	.section	.rodata,"a",@progbits
	.globl	.str
.str:
	.asciz	"%d\n"
	.size	.str, 4

	.section	".note.GNU-stack","",@progbits
