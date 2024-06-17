#!/bin/bash

## This program creates lvms using loop devices instead of block devices. It is an interactive user friendly program written completely in bash
##

declare -i noofloop
declare -i sizeofloop
declare -a arrloopfiles

usage(){
	cat <<EOF
	usage: ./lvmlooper.sh [-h|-i|d]
		-h : Help section 
		-i : Interactive mode
		-d : delete existing lvms created through lvmlooper
		
EOF
}

fscreator(){
		echo "Formatting lvm with ext$1 filesystem"
					mkfs.ext$1 /dev/mapper/$(ls -tr /dev/mapper | tail -n 1 )
					if [[ $? -eq 0 ]]; then
						echo "Formatted ext$1 on lvm !!"
					fi
					fsdir=$(mktemp --dry-run --suffix=_lvmloopdrive | sed -r 's/\/tmp\///')
					mkdir -p /mnt/lvmloopfs/$fsdir
					mount /dev/mapper/$(ls -tr /dev/mapper | tail -n 1 ) /mnt/lvmloopfs/$fsdir
					echo "Find mounted filesystem on /mnt/lvmloopfs/$fsdir !!"
}

interactive_mode(){

echo "Interactive mode"

read -p "How many loop devices do you want to create: " noofloop

if [[ -n $noofloop ]] && [[ $noofloop -gt 0 ]]; then
	read -p "Size of each loop device in Mb: " sizeofloop
	if [[ $sizeofloop -gt 0 ]]; then
		for loopfile in $(seq 1 $noofloop); do
			arrloopfiles+=$(mktemp --suffix=_loopdev ; echo " ")	
		done
		for loopfile in ${arrloopfiles[@]}; do 
			fallocate -l $sizeofloop"M" $loopfile
		done
		for loopfile in ${arrloopfiles[@]}; do
			losetup -f $loopfile
		done
		
		loopdevicearr+=$(losetup -l | grep -Ei 'loopdev' | cut -d " " -f 1)
		
		vg=$(mktemp --dry-run --suffix=_vg | sed -r 's/\./-/' | sed -r 's/\/tmp\///')
			
		
		for loopdev in ${loopdevicearr[@]}; do
			vgcreate $vg $loopdev
			vgextend $vg $loopdev
		done
		
		read -p "What type of lvm do you want to create : (l)inear (s)triped:" lvmtype
		
		freespaceinvg=$(vgs | grep -Ei "$vg" | cut -d ' ' -f 15)

		case $lvmtype in
			l)
			lvcreate --type linear -L $freespaceinvg -n $(mktemp --dry-run --suffix=_linear_lv | sed -r 's/\/tmp\///') $vg
			echo "Running lvs to display created logical volume"
			lvs
				;;
			s)
				lvcreate --type striped -L $freespaceinvg -n $(mktemp --dry-run --suffix=_linear_lv | sed -r 's/\/tmp\///') $vg
			echo "Running lvs to display created logical volume"
				;;
		esac
		
		read -p "Do you want to format with a filesystem (y or n): " formatyorn
		
		case $formatyorn in
			y)
				read -p "Which filesystem to format with ext(4) ext(3) ext(2):" filesystem
			       	case $filesystem in
			
				4)
					fscreator 4
					exit 0
					;;
				3)
					fscreator 3
					exit 0
					;;
				2)
					fscreator 2
					exit 0
					;;
				1)
					fscreator 1
					exit 0
					;;
				*)

					echo "Formatting lvm with default ext4 filesystem"
					mkfs.ext4 /dev/mapper/$(ls -tr /dev/mapper | tail -n 1 )
					if [[ $? -eq 0 ]]; then
						echo "Formatted ext4 on lvm !!"
					fi
					fsdir=$(mktemp --dry-run --suffix=_lvmloopdrive | sed -r 's/\/tmp\///')
					mkdir -p /mnt/lvmloopfs/$fsdir
					mount /dev/mapper/$(ls -tr /dev/mapper | tail -n 1 ) /mnt/lvmloopfs/$fsdir
					echo "Find mounted filesystem on /mnt/lvmloopfs/$fsdir !!"
					exit 0
					;;
				esac
				;;

			n)
				echo "Created lvms did not format a filesystem on top so not mounted"
				exit 0
				;;
			*)
				echo "Invalid argument"
				usage
				exit 1
				;;
				
			esac
	fi

else
	usage
	exit 1
fi 
}

deleteloop(){
	if [[ -d "/mnt/lvmloopfs" ]]; then
		umount /mnt/lvmloopfs/tmp\.*loopdrive
			echo y | lvremove /dev/mapper/tmp\-\-*tmp*lv
				rm -rf /tmp/tmp\.*loopdev
				losetup -d $(losetup -l | grep -Ei 'loopdev \(deleted\)' | cut -d ' ' -f 1 )
				if [[ ! -n $(lvs) ]]; then
					rm -rf /mnt/lvmloopfs/tmp\.*drive
					if [[ $? -eq 0 ]]; then
						rm -rf /mnt/lvmloopfs
					fi
				fi		
		
	else
		echo "lvmloopfs directory does not exist. Deleting the rest"
		echo y | lvremove /dev/mapper/tmp\-\-*tmp*lv
		rm -rf /tmp/tmp\.*loopdev
		losetup -d $(losetup -l | grep -Ei 'loopdev \(deleted\)' | cut -d ' ' -f 1 )
		if [[ ! -n $(lvs) ]]; then
			rm -rf /mnt/lvmloopfs/tmp\.*drive
			if [[ $? -eq 0 ]]; then 
				rm -rf /mnt/lvmloopfs
			fi
		fi
	fi
}

while getopts ':hdi' opts; do
	case $opts in
		h)
			usage
			exit 1
			;;
		i)
			interactive_mode
			exit 1
			;;
		d)
			echo "Attempting to delete loopdrives created"
			deleteloop
			exit 0
			;;
		\?)
			echo "Invalid option"
			;;
		:)
			echo "Required argument"
			;;
	esac
done

if [[ ! -n $1 ]]; then
	usage
	exit 1 
fi 

shift $((OPTIND-1))

if [[ $# -ge 1 ]]; then
	echo "Too many arguments"
	usage
	exit 1
fi 
