#!/bin/bash 

rm -rf /tmp/tmp\.*loopdev
vgs
losetup -d $(losetup -l | grep -Ei 'loopdev \(deleted\)' | cut -d ' ' -f 1 )

