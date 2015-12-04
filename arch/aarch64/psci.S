/*
 * arch/aarch64/psci.S - basic PSCI implementation
 *
 * Copyright (C) 2013 ARM Limited. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE.txt file.
 */
#include "common.S"

#define PSCI_CPU_OFF		0x84000002
#define PSCI_CPU_ON		0xc4000003

#define PSCI_RET_SUCCESS	0
#define PSCI_RET_NOT_IMPL	(-1)
#define PSCI_RET_INVALID	(-2)
#define PSCI_RET_DENIED		(-3)

#ifndef CPU_IDS
#error No CPU MPIDRs provided.
#endif

#define ADDR_INVALID		(-1)

	.macro	ventry	label
	.align	7
	b	\label
	.endm

	.section .vectors, "w"

	.align 11
vector:
	// current EL, SP_EL0
	ventry	err_exception	// synchronous
	ventry	err_exception	// IRQ
	ventry	err_exception	// FIQ
	ventry	err_exception	// SError

	// current EL, SP_ELx
	ventry	err_exception
	ventry	err_exception
	ventry	err_exception
	ventry	err_exception

	// lower EL, AArch64
	ventry	psci_call64
	ventry	err_exception
	ventry	err_exception
	ventry	err_exception

	// lower EL, AArch32
	ventry	psci_call32
	ventry	err_exception
	ventry	err_exception
	ventry	err_exception

	.data
branch_table:
	.rept (NR_CPUS)
	.quad ADDR_INVALID
	.endr

	.text

	.globl start_no_el3
	.globl start_el3

err_exception:
	b err_exception

psci_call32:
	mov	w0, PSCI_RET_NOT_IMPL
	eret

psci_call64:
	ldr	x7, =PSCI_CPU_OFF
	cmp	x0, x7
	b.eq	psci_cpu_off

	ldr	x7, =PSCI_CPU_ON
	cmp	x0, x7
	b.eq	psci_cpu_on

	mov	x0, PSCI_RET_NOT_IMPL
	eret

/*
 * x1 - optional power state parameter, ignored here
 */
psci_cpu_off:
	cpuid	x0, x1
	bl	find_logical_id
	adr	x1, branch_table
	mov	x2, #ADDR_INVALID
	str	x2, [x1, x0, lsl #3]

	b	spin

/*
 * x1 - target cpu
 * x2 - address
 */
psci_cpu_on:
	mov	x15, x30
	mov	x14, x2
	mov	x0, x1

	bl	find_logical_id
	cmp	x0, #-1
	b.eq	1f

	adr	x3, branch_table
	add	x3, x3, x0, lsl #3

	ldr	x4, =ADDR_INVALID

	ldxr	x5, [x3]
	cmp	x4, x5
	b.ne	1f

	stxr	w4, x14, [x3]
	cbnz	w4, 1f

	dsb	ishst
	sev

	mov	x0, #PSCI_RET_SUCCESS
	mov	x30, x15
	eret

1:	mov	x0, #PSCI_RET_DENIED
	mov	x30, x15
	eret


start_el3:
	ldr	x0, =vector
	bl	setup_vector
	bl	switch_to_idmap

	/* only boot the primary cpu (entry 0 in the table) */
	cpuid	x0, x1
	bl	find_logical_id
	cbnz	x0, spin

	adr	x2, branch_table
	adr	x1, start_cpu0
	str	x1, [x2]
	sevl
	b	spin

/*
 * Poll the release table, waiting for a valid address to appear.
 * When a valid address appears, branch to it.
 */
spin:
	cpuid	x0, x1
	bl	find_logical_id
	cmp	x0, #-1
	b.eq	spin_dead

	adr	x1, branch_table
	mov	x3, #ADDR_INVALID

	add	x1, x1, x0, lsl #3

1:	wfe
	ldr	x2, [x1]
	cmp	x2, x3
	b.eq	1b

	ldr	x0, =SCTLR_EL2_RESET
	msr	sctlr_el2, x0

	mov	x3, #SPSR_KERNEL
	adr	x4, el2_trampoline
	mov	x0, x2
	drop_el	x3, x4

/*
 * This PSCI implementation requires EL3. Without EL3 we'll only boot the
 * primary cpu, all others will be trapped in an infinite loop.
 */
start_no_el3:
	cpuid	x0, x1
	bl	find_logical_id
	cbz	x0, start_cpu0
spin_dead:
	wfe
	b	spin_dead


/*
 * Clean and invalidate the caches at EL2 to simplify EL3's cache usage.
 */
el2_trampoline:
	mov	x15, x0
	bl	flush_caches
	br	x15

start_cpu0:
	/*
	 * Kernel parameters
	 */
	mov	x0, xzr
	mov	x1, xzr
	mov	x2, xzr
	mov	x3, xzr

	bl	ns_init_system
	ldr	x0, =dtb
	b	kernel
