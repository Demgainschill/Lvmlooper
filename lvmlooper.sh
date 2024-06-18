#!/bin/bash

## This program creates lvms using loop devices instead of block devices. It is an interactive user friendly program written completely in bash
##

declare -i noofloop
declare -i sizeofloop
declare -a arrloopfiles

b=$(tput setaf 4)
r=$(tput setaf 1)
g=$(tput setaf 10)
y=$(tput setaf 3)
reset=$(tput sgr0)
c=$(tput setaf 14)
greensoo=$(tput setaf 48)

usage(){
	cat <<EOF
	${c}usage:${reset} ./lvmlooper.sh [-h|-i|d] 
		-h : Help section 
		-i : Interactive mode
		-d : delete existing lvms created through lvmlooper
		
EOF
}

fscreator(){
		echo -e "\n${y}Formatting lvm with ext$1 filesystem${reset}${reset}"
					mkfs.ext$1 /dev/mapper/$(ls -tr /dev/mapper | tail -n 1 ) | 
						while read line; do
							echo ${y}${line}${reset}
						done
					if [[ $? -eq 0 ]]; then
						echo "${g}Formatted ext$1 on lvm${reset} ${b}!!${reset}"
					fi
					fsdir=$(mktemp --dry-run --suffix=_lvmloopdrive | sed -r 's/\/tmp\///')
					mkdir -p /mnt/lvmloopfs/$fsdir
					mount /dev/mapper/$(ls -tr /dev/mapper | tail -n 1 ) /mnt/lvmloopfs/$fsdir
					echo "${g}Find mounted filesystem on /mnt/lvmloopfs/$fsdir ${reset}${b}!!${reset}"
}

interactive_mode(){


echo "${y}Interactive mode${reset}"


read -p "How many ${c}loop devices${reset} do you want to ${g}create${reset}:" noofloop


if [[ -n $noofloop ]] && [[ $noofloop -gt 0 ]]; then
	read -p "${y}Size${reset} of each ${c}loop device${reset} in ${g}Mb${reset}: " sizeofloop
	if [[ $sizeofloop -gt 0 ]]; then
		echo -e "\n${c}Creating a combined logical volume of size ${y}$[$noofloop*$sizeofloop]Mb${reset}${reset}"
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
			vgcreate $vg $loopdev  2>/dev/null
			vgextend $vg $loopdev  2>/dev/null 
		done | while read line ; do
			echo ${g}$line${reset}
		done
		
		read -p "What ${y}type${reset} of ${c}lvm${reset} do you want to ${g}create${reset} : ${b}(${reset}${g}l${reset}${b})${reset}${y}inear${reset} ${b}(${reset}${g}s${reset}${b})${reset}${y}triped${reset}:" lvmtype
		
		freespaceinvg=$(vgs | grep -Ei "$vg" | cut -d ' ' -f 15)

		case $lvmtype in
			l)
			lvcreate --type linear -L $freespaceinvg -n $(mktemp --dry-run --suffix=_linear_lv | sed -r 's/\/tmp\///') $vg | while read line; do
			echo -e "\n${g}$line${reset}"
		done
			echo -e "\n${y}Running lvs to display created logical volume${reset}"
			lvs | while read line; do
				if [[ $line =~ 'linear_lv' ]]; then
					echo ${g}${line}${reset}
				else
					echo $line
				fi
			done
				;;
			s)
				lvcreate --type striped -L $freespaceinvg -n $(mktemp --dry-run --suffix=_striped_lv | sed -r 's/\/tmp\///') $vg | while read line; do
				echo -e "\n${g}${line}${reset}"
			done
			echo "${y}Running lvs to display created logical volume${reset}"
			lvs | while read line; do
				if [[ $line =~ 'striped_lv' ]]; then
					echo ${g}$line${reset}
				else
					echo $line
				fi
			done
				;;
			*)
				echo "Not a valid lvm type"
				;;
		esac
		
		read -p "Do you want to ${g}format${reset} with a ${c}filesystem${reset} (${g}y${reset} ${b}or${reset} ${r}n${reset}): " formatyorn
		
		case $formatyorn in
			y)
				read -p "Which ${c}filesystem${reset} to format with ${c}ext${reset}(${y}4${reset}) ${c}ext${reset}(${y}3${reset}) ${c}ext${reset}(${y}2${reset}):" filesystem
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

					echo -e "\n${y}Formatting lvm with default ext4 filesystem${reset}\n"
					mkfs.ext4 /dev/mapper/$(ls -tr /dev/mapper | tail -n 1 )
					if [[ $? -eq 0 ]]; then
						echo "${y}Formatted ext4 on lvm !!${reset}"
					fi
					fsdir=$(mktemp --dry-run --suffix=_lvmloopdrive | sed -r 's/\/tmp\///')
					mkdir -p /mnt/lvmloopfs/$fsdir
					mount /dev/mapper/$(ls -tr /dev/mapper | tail -n 1 ) /mnt/lvmloopfs/$fsdir
					echo "${g}Find mounted filesystem on /mnt/lvmloopfs/$fsdir ${reset} !!"
					exit 0
					;;
				esac
				;;

			n)
				echo "${r}Created lvms did not format a filesystem on top so not mounted${reset}"
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
		umount /mnt/lvmloopfs/tmp\.*loopdrive 2>/dev/null
			echo yes | lvremove /dev/mapper/tmp\-\-*tmp*lv
				rm -rf /tmp/tmp\.*loopdev
				losetup -d $(losetup -l | grep -Ei 'loopdev \(deleted\)' | cut -d ' ' -f 1 ) 2>/dev/null
				if [[ ! -n $(lvs) ]]; then
					rm -rf /mnt/lvmloopfs/tmp\.*drive
					if [[ $? -eq 0 ]]; then
						rm -rf /mnt/lvmloopfs
					fi
				fi
		
		echo "${g}Successfully done with deleting${reset}"		
	else
		echo "${y}lvmloopfs directory does not exist. ${r}Deleting${reset} any remains${reset}"
		echo yes | lvremove /dev/mapper/tmp\-\-*tmp*lv
		rm -rf /tmp/tmp\.*loopdev
		losetup -d $(losetup -l | grep -Ei 'loopdev \(deleted\)' | cut -d ' ' -f 1 ) 2>/dev/null
		if [[ ! -n $(lvs) ]]; then
			rm -rf /mnt/lvmloopfs/tmp\.*drive
			if [[ $? -eq 0 ]]; then 
				rm -rf /mnt/lvmloopfs
			fi
		fi

		echo "${g}Successfully done with deleting${reset}"		
	fi
} 2>/dev/null

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
			echo "${y}Attempting to delete loopdrives created${reset}"
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
