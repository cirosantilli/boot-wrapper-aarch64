/*
 * psci.c - basic PSCI implementation
 *
 * Copyright (C) 2015 ARM Limited. All rights reserved.
 *
 * Use of this source code is governed by a BSD-style license that can be
 * found in the LICENSE.txt file.
 */

#include <stdint.h>

#include <cpu.h>
#include <psci.h>
#include <spin.h>

#ifndef CPU_IDS
#error "No MPIDRs provided"
#endif

static unsigned long branch_table[NR_CPUS];

int psci_cpu_on(unsigned long target_mpidr, unsigned long address)
{
	int ret;
	unsigned int cpu = find_logical_id(target_mpidr);

	if (cpu == MPIDR_INVALID)
		return PSCI_RET_INVALID_PARAMETERS;

	ret = psci_store_address(address, branch_table + cpu);

	dsb(ishst);
	sev();

	return ret;
}

int psci_cpu_off(void)
{
	unsigned long mpidr = read_mpidr();
	unsigned int cpu = find_logical_id(mpidr);

	if (cpu == MPIDR_INVALID)
		return PSCI_RET_DENIED;

	branch_table[cpu] = PSCI_ADDR_INVALID;

	spin(branch_table + cpu, PSCI_ADDR_INVALID, 0);

	unreachable();
}

void __noreturn psci_first_spin(unsigned int cpu)
{
	if (cpu == MPIDR_INVALID)
		while (1);

	first_spin(cpu, branch_table + cpu, PSCI_ADDR_INVALID);

	unreachable();
}
