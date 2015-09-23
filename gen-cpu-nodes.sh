#!/bin/sh
# Very dumb shell script to generate DTB nodes that changes the
# boot-method to PSCI.
#
# Copyright (C) 2014 ARM Limited. All rights reserved.
#
# Use of this source code is governed by a BSD-style license that can be
# found in the LICENSE.txt file.

CPU_IDS=$1;
CPU_IDS_NO_HEX=$(echo $CPU_IDS | sed s/0x//g);
CPU_IDS_NO_HEX=$(echo $CPU_IDS_NO_HEX | sed s/\,/\ /g);

echo '#address-cells = <0x1>;'
echo '#size-cells = <0>;'

for id in $CPU_IDS_NO_HEX;
do
	echo "cpu@$id {"
	echo '	device_type = \"cpu\";'
	echo '	enable-method = \"psci\";'
	echo "	reg = <0x$id>;"
	echo "};"
done
