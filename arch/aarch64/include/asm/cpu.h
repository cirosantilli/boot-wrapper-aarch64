/*
 * arch/aarch64/include/asm/cpu.h
 *
 * Copyright (C) 2015 ARM Limited. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE.txt file.
 */
#ifndef __ASM_AARCH64_CPU_H
#define __ASM_AARCH64_CPU_H

#define MPIDR_ID_BITS		0xff00ffffff

#define CURRENTEL_EL3		(3 << 2)

/*
 * RES1 bits,  little-endian, caches and MMU off, no alignment checking,
 * no WXN.
 */
#define SCTLR_EL2_RESET		(3 << 28 | 3 << 22 | 1 << 18 | 1 << 16 | 1 << 11 | 3 << 4)

#define SPSR_A			(1 << 8)	/* System Error masked */
#define SPSR_D			(1 << 9)	/* Debug masked */
#define SPSR_I			(1 << 7)	/* IRQ masked */
#define SPSR_F			(1 << 6)	/* FIQ masked */
#define SPSR_T			(1 << 5)	/* Thumb */
#define SPSR_EL2H		(9 << 0)	/* EL2 Handler mode */

#define SPSR_KERNEL		(SPSR_A | SPSR_D | SPSR_I | SPSR_F | SPSR_EL2H)

#ifndef __ASSEMBLY__

#define sevl()		asm volatile ("sevl\n" : : : "memory")

static inline unsigned long read_mpidr(void)
{
	unsigned long mpidr;

	asm volatile ("mrs	%0, mpidr_el1\n" : "=r" (mpidr));
	return mpidr & MPIDR_ID_BITS;
}


#endif /* !__ASSEMBLY__ */

#endif
