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
