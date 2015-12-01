/*
 * arch/aarch64/include/asm/psci.h
 *
 * Copyright (C) 2015 ARM Limited. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE.txt file.
 */
#ifndef __ASM_AARCH64_PSCI_H
#define __ASM_AARCH64_PSCI_H

#ifndef __ASSEMBLY__

static inline int psci_store_address(unsigned long address,
				     unsigned long *branch_entry)
{
	unsigned long ret;

	asm volatile (
	"1:\n"
	"ldxr	%0, [%2]\n"
	"subs	%0, %0, %3\n"
	"b.ne	2f\n"
	"stxr	%w0, %1, [%2]\n"
	"cbnz	%w0, 1b\n"
	"2:\n"
	: "=&r" (ret)
	: "r" (address), "r" (branch_entry), "J" (PSCI_ADDR_INVALID)
	: "cc");

	if (ret != 0)
		/* ret value comes from subs */
		return PSCI_RET_ALREADY_ON;

	return PSCI_RET_SUCCESS;
}

#endif /* !__ASSEMBLY__ */

#endif
