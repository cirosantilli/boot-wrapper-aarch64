/*
 * boot.S - simple register setup code for stand-alone Linux booting
 *
 * Copyright (C) 2012 ARM Limited. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE.txt file.
 */

#include "common.S"

	.text

	.globl	_start
_start:
	/*
	 * EL3 initialisation
	 */
	mrs	x0, CurrentEL
	cmp	x0, #CURRENTEL_EL3
	b.ne	start_ns			// skip EL3 initialisation

	mov	x0, #0x30			// RES1
	orr	x0, x0, #(1 << 0)		// Non-secure EL1
	orr	x0, x0, #(1 << 8)		// HVC enable
	orr	x0, x0, #(1 << 10)		// 64-bit EL2
	msr	scr_el3, x0

	msr	cptr_el3, xzr			// Disable copro. traps to EL3

	ldr	x0, =CNTFRQ
	msr	cntfrq_el0, x0

	/*
	 * Check for the primary CPU to avoid a race on the distributor
	 * registers.
	 */
	mrs	x0, mpidr_el1
	ldr	x1, =MPIDR_ID_BITS
	tst	x0, x1
	b.ne	1f				// secondary CPU

	ldr	x1, =GIC_DIST_BASE		// GICD_CTLR
	mov	w0, #3				// EnableGrp0 | EnableGrp1
	str	w0, [x1]

1:	ldr	x1, =GIC_DIST_BASE + 0x80	// GICD_IGROUPR
	mov	w0, #~0				// Grp1 interrupts
	str	w0, [x1]
	b.ne	2f				// Only local interrupts for secondary CPUs
	str	w0, [x1, #4]
	str	w0, [x1, #8]

2:	ldr	x1, =GIC_CPU_BASE		// GICC_CTLR
	mov	w0, #3				// EnableGrp0 | EnableGrp1
	str	w0, [x1]

	mov	w0, #1 << 7			// allow NS access to GICC_PMR
	str	w0, [x1, #4]			// GICC_PMR

	msr	sctlr_el2, xzr

	/*
	 * Prepare the switch to the EL2_SP1 mode from EL3
	 */
	ldr	x0, =start_ns			// Return after mode switch
	mov	x1, #SPSR_KERNEL
	drop_el	x1, x0

start_ns:
	/*
	 * Kernel parameters
	 */
	mov	x0, xzr
	mov	x1, xzr
	mov	x2, xzr
	mov	x3, xzr

	mrs	x4, mpidr_el1
	ldr	x5, =MPIDR_ID_BITS
	tst	x4, x5
	b.eq	2f

	/*
	 * Secondary CPUs
	 */
1:	wfe
	ldr	x4, mbox
	cbz	x4, 1b
	br	x4				// branch to the given address

2:

	/*
	 * Primary CPU
	 */
	bl	ns_init_system
	ldr	x0, =dtb			// device tree blob
	b	kernel

	.ltorg

	.org	0x200
