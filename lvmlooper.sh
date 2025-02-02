#!/usr/bin/bash
export PS4='+ ${BASH_SOURCE}:${LINENO}: '


#set -x
## This program creates filesystems on top of lvms using loop devices instead of block devices as the base/physical volumes. It is an interactive user friendly program written completely in bash
##


declare -i noofloop
#declare -i sizeofloop
declare -a arrloopfiles
declare -i selected_number

b=$(tput setaf 4)
r=$(tput setaf 1)
g=$(tput setaf 10)
y=$(tput setaf 3)
reset=$(tput sgr0)
c=$(tput setaf 14)
o=$(tput setaf 208) 

usage(){
	cat <<EOF
	${c}usage:${reset} ./${g}lvmlooper.sh${reset} [${y}-h${reset}|${y}-i${reset}|${y}-d${reset}|${y}-l${reset}|${y}-c${reset}|${y}-e${reset}|${y}-n${reset}|${y}-z${reset}] 
		${y}-i${reset} : ${g}Create${reset}${c} LVM & loop devices based mounted filesystems/Loopdrives ${reset}(/mnt/lvmloopfs/tmp*loopdrive) ${reset} 
		${y}-d${reset} : ${r}Delete${reset}${c} existing lvms created through lvmlooper${reset}
		${y}-l${reset} : ${b}List${reset}${c} existing files created through lvmlooper${reset}
		${y}-c${reset} : ${o}Connect${reset}${c} to existing containers deployed through podman${reset}
		${y}-e${reset} : Extend${c} existing mounted loopdrives On-line${reset}				       
		${y}-n${reset} : ${g}Create${reset}${c} NFS shares from exising loopdrives${reset}
		${y}-h${reset} : ${y}Help${reset}${c} section${reset}
		${y}-z${reset} : ${o}Enable${reset}${c} Zsh Auto-tab Completion on options for lvmlooper${reset} (zsh users only!)
	${o}(${y}-s${reset}${o} Snapshot Coming soon!) ${reset}
EOF

}
errormsg(){
	echo "${r}Error downloading the ${1} tool from the ${2} package${reset}"
	echo "${r}Need to install ${1} tool inorder for program to run properly.${reset}"
	exit 1
}	

dependencies(){
	#LVM dependency check
if [[ ! -n $( ls .lvmlooperDependency 2>/dev/null) ]]; then 
	echo "${r}Dependency file .lvmlooperDependency not found.${reset} ${g}Creating a new one.${reset}"
	echo -e "${y}Performing dependency check...${reset}" 

	if [[ -n $(which lvm) ]]; then
		echo "${g}lvm exists${reset}"
		lvm=1
	else
		echo "${y}Installing lvm from lvm2 package...${reset}"
		apt-get install lvm2
		if [[ $? -eq 1 ]]; then
			errormsg "lvm" "lvm2"
		fi

	fi
	
	#mkfs dependency check 
	
	if [[ -n $(which mkfs) ]]; then
		echo "${g}mkfs exists${reset}"
		mkfs=1
	else
		echo "${y}Installing mkfs from dosfstools package...${reset}"
		apt-get install dosfstools
		if [[ $? -eq 1 ]]; then
			errormsg "mkfs" "dosfstools"
		fi
	fi
       	if [[ $lvm -eq 1 ]] && [[ $mkfs -eq 1 ]];then 
		echo -e "${g}Dependencies checked Running program\n${reset}"
	fi
	if [[ $? -eq 0 ]]; then 
		touch .lvmlooperDependency
		echo "Contains Dependency" > .lvmlooperDependency
		
	fi

fi 

	
	
}

if [[ -n $1 ]]; then
	dependencies
fi

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
ascii(){

cat <<EOF
${g}██╗    ██╗   ██╗███╗   ███╗██╗      ██████╗  ██████╗ ██████╗ ███████╗██████╗ ${reset}
${g}██║    ██║   ██║████╗ ████║██║     ██╔═══██╗██╔═══██╗██╔══██╗██╔════╝██╔══██╗${reset}
${g}██║    ██║   ██║██╔████╔██║██║     ██║   ██║██║   ██║██████╔╝█████╗  ██████╔╝${reset}
${g}██║    ╚██╗ ██╔╝██║╚██╔╝██║██║     ██║   ██║██║   ██║██╔═══╝ ██╔══╝  ██╔══██╗${reset}
${g}███████╗╚████╔╝ ██║ ╚═╝ ██║███████╗╚██████╔╝╚██████╔╝██║     ███████╗██║  ██║${reset}
${g}╚══════╝ ╚═══╝  ╚═╝     ╚═╝╚══════╝ ╚═════╝  ╚═════╝ ╚═╝     ╚══════╝╚═╝  ╚═╝${reset}
                                                                             

EOF

}
interactive_mode(){
ascii

echo "${y}Interactive mode${reset}"


read -p "How many ${c}loop devices${reset} do you want to ${g}create${reset}: " noofloop


if [[ -n $noofloop ]] && [[ $noofloop -gt 0 ]]; then
	read -p "${y}Size${reset} of each ${c}loop device${reset} in ${g}Mb${reset}: " sizeofloop
	if [[ ! $sizeofloop =~ ^[0-9]+$ ]]; then
		echo "${r}Invalid size! ${reset}"
		exit 1
	fi
	if [[ $sizeofloop -gt 0 ]]; then
		totalsize=$[$noofloop*$sizeofloop]
		
		echo -e "\n${c}Creating a combined logical volume of size ${y}$totalsize ${o}Mb${reset}${reset}"
		for loopfile in $(seq 1 $noofloop); do
			arrloopfiles+=$(mktemp --suffix=_loopdev ; echo " ")	
		done
		for loopfile in ${arrloopfiles[@]}; do 
			fallocate -l $sizeofloop"M" $loopfile
			if [[ $? -eq 1 ]]; then
				echo "${r}No space on /tmp${reset}"
				echo "${r}Exiting!${reset}"	
				exit 1
			fi
				
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
		
		read -p "What ${y}type${reset} of ${c}lvm${reset} do you want to ${g}create${reset} : ${b}(${reset}${g}l${reset}${b})${reset}${y}inear${reset} ${b}(${reset}${g}s${reset}${b})${reset}${y}triped${reset}: " lvmtype
		if [[ ! $lvmtype =~ l|s ]] || [[ ! $lvmtype ]]; then 
			echo "${r}Not a valid lvm type${reset}"
			exit 1 
		fi 		
		case $lvmtype in
			l)
				lvcreate --type linear -l 100%FREE -n $(mktemp --dry-run --suffix=_linear_lv | sed -r 's/\/tmp\///') $vg | while read line; do
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
				lvcreate --type striped -l 100%FREE -n $(mktemp --dry-run --suffix=_striped_lv | sed -r 's/\/tmp\///') $vg | while read line; do
				echo "${g}${line}${reset}"
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
				echo "${r}Not a valid lvm type${reset}"
				exit 1
				;;
		esac
		
		read -p "Do you want to ${g}format${reset} with a ${c}filesystem${reset} (${g}y${reset} ${b}or${reset} ${r}n${reset}): " formatyorn
		
		case $formatyorn in
			y)
				read -p "Which ${c}filesystem${reset} to format with ${c}ext${reset}(${y}4${reset}) ${c}ext${reset}(${y}3${reset}) ${c}ext${reset}(${y}2${reset}): " filesystem
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
					if [[ ! $filesystem =~ ^[2-4]$ ]]; then
						echo "${r}Invalid filesystem${reset}"
						exit 1
					fi

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
				echo "${r}Created lvms have not been format with a filesystem on top so not mounting!${reset}"
				exit 0
				;;
			*)
				echo "${r}Invalid argument${reset}"
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
		read -p "${y}Are you sure you want to delete all loop-drives mounted? (${g}y${reset}${y})es or (${r}n${reset}${y})o :${reset}" loopquestion
		
		if [[ $loopquestion =~ "y" ]]; then
			echo "${y}Attempting to delete loopdrives created${reset}"
			umount -f /dev/mapper/tmp\-\-*lv 2>/dev/null
			umount -f /mnt/lvmloopfs/tmp\.*loopdrive 2>/dev/null
			deletepvs=($(losetup -l  | grep -Ei 'deleted' | cut -d ' ' -f 1 | tr '\n' ' ' ))
			for pv in ${deletepvs[@]} ; do
				echo 'y' | pvremove --force --force $pv
				if [[ $? -eq 1 ]]; then
					echo "error occured while removing pv"
					exit 1
				fi
			done
				
			       		
			echo yes | lvremove /dev/mapper/tmp\-\-*lv 2>/dev/null
				rm -rf /tmp/tmp\.*loopdev
				losetup -d $(losetup -l | grep -Ei 'loopdev \(deleted\)' | cut -d ' ' -f 1 ) 2>/dev/null
				if [[ ! -n $(lvs) ]]; then
					rm -rf /mnt/lvmloopfs/tmp\.*drive
					if [[ $? -eq 0 ]]; then
						umount /mnt/lvmloopfs
						rm -rf /mnt/lvmloopfs
					fi
				fi
				deletepvs=($(losetup -l  | grep -Ei 'deleted' | cut -d ' ' -f 1 | tr '\n' ' ' ))
			for pv in ${deletepvs[@]} ; do
				echo 'y' | pvremove --force --force $pv
				if [[ $? -eq 1 ]]; then
					echo "error occured while removing pv"
					exit 1
				fi
			done
rm -rf /mnt/lvmloopfs
		mount -f /mnt/lvmloopfs/tmp.*drive
		rm -rf /mnt/lvmloopfs
		if [[ $? -eq 1 ]]; then
			umount -l /mnt/lvmloopfs/tmp.*drive
			rm -rf /mnt/lvmloopfs	
		fi
		sed -ri 's/\/mnt\/lvmloopfs\/.*\*.*\)//g' /etc/exports
		echo "${g}Successfully done with deleting${reset}"
		elif [[ $loopquestion =~ "n" ]]; then
			echo "${g}Not deleting existing lvmdrives${reset}"
			exit 1
		else
			echo "${r}Invalid input entered. Please respond with '(y)es' or '(n)o'.${reset}"
			exit 1
		fi
			
	else
		echo "${y}lvmloopfs directory does not exist. ${r}Deleting${reset} any remains${reset}"
		umount -f /dev/mapper/tmp\-\-*lv 2>/dev/null
		umount -f /mnt/lvmloopfs/tmp\.*loopdrive 2>/dev/null
		echo yes | lvremove /dev/mapper/tmp\-\-*tmp*lv 2>/dev/null
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
} 

	

while getopts ':hdilecsnz' opts; do
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
			deleteloop
			exit 0
			;;
		l)
			if [[ -d "/mnt/lvmloopfs" ]]; then
				arr=($(df -h | grep -Eie'/mnt/lvmloopfs/tmp\..*drive' | gawk '{ print $2,$6 }' | sed -r 's/ //' | tr '\n' ' ' ))
				echo "${o}Total Size${reset}      ${o}LoopDrives${reset}"
				for mountDirWithSize in ${arr[@]}; do
					echo $mountDirWithSize | sed -r 's/([0-9]{1,3}(M|K|G))(.*)/\1 &/g' | sed -r 's/[0-9]{1,3}M|K|G//2' | xargs -n 1 -I {} echo "{}" 2>/dev/null | sed -re "s/[0-9]{1,4}(M|K|G)/${g}&${reset}/" | sed -r "s/\/mnt\/.*drive/${b}&${reset}/" 
				

					

				
				done 
				echo -e '\n'
				showmount -e localhost | while read -r line; do 
				if [[ $line =~ list ]]; then
				 echo ${y}$line${reset} 
				 
			 elif [[ $line =~ list ]]; then
				 echo $line | sed -r 's/Export.*list.*//'

				fi	 
				if [[ $line =~ /mnt/.*loopdrive.*\* ]]; then
						echo "${o}${line}${reset}"
					else
						echo "$line"
				fi
			done
			else
				echo "${r}Directory does not exist. Nothing to list. Exiting${reset}"
				echo -e '\n'
				showmount -e localhost | while read -r line; do 
				if [[ $line =~ list ]]; then
				 echo ${y}$line${reset} 
				 
			 elif [[ $line =~ list ]]; then
				 echo $line | sed -r 's/Export.*list.*//'

				fi	 
				if [[ $line =~ /mnt/.*loopdrive.*\* ]]; then
						echo "${o}${line}${reset}"
					else
						echo "$line"
				fi

				exit 1
			done
				fi | sed -r '/list/{ n ; d }'


			;;
			
		e)
			echo "${o}Choose which Filesystem to extend${reset}"
			echo "${b}Filesystems currently mounted${reset}"

			declare -A lv_mounts

			while read -r device mount_point; do
    				lv_mounts["$device"]="$mount_point"
			done < <(df -h | gawk '{ print $1,$6}' | grep -Ei '/dev/mapper/.*_lv\s')

			display_mount_points() {
   				 echo "${b}Available mount points:${reset}"
    				 local i=1
    				for mount_point in "${lv_mounts[@]}"; do
        				echo "${y}$i)${reset} ${o}$mount_point${reset}"
        				i=$((i + 1))
    				done
			}

			select_mount_point() {
   			local selected_number
    			declare -g selected_mount_point
    			local selected_device
    			while true; do
        			display_mount_points
        			read -p "Please enter the ${y}number${reset} corresponding to the ${y}mount point${reset} you want to ${o}extend${reset}: " selected_number
        			if [[ ! $selected_number =~ ^[0-9]+$ ]]; then 
					echo "${r}Invalid Selection${reset}"
					exit 1
				fi
				if [[ $selected_number =~ ^[0-9]+$ ]] && (( $selected_number > 0 && $selected_number <= ${#lv_mounts[@]} )); then
            			selected_mount_point=$(echo "${lv_mounts[@]}" | awk -v num=$selected_number '{print $num}')
           		 	for device in "${!lv_mounts[@]}"; do
                			if [[ "${lv_mounts[$device]}" == "$selected_mount_point" ]]; then
                    		selected_device=$device
                    		break
            			fi
				
			done
            		echo "${b}Selected:${reset} ${o}$selected_mount_point${reset}"
			fi
			
			read -p "Enter amount of ${y}size${reset} to extend and allocate in ${g}(Mb)${reset}: " extend
			if [[ ! $extend =~ ^[0-9]+$ ]]; then
				echo "${r}Invalid extend value${reset}"
				exit 1
			fi
			vg=$(echo "$selected_device" | grep -Eio 'tmp.*vg-tmp' | sed -r 's/--/-/' | sed -r 's/-tmp//')
			vfree=$(vgs | grep -Ei "$vg" | tr " " "\n" | sed -r '/^$/d' | tail -n 1 | sed -r 's/m//'| sed -r 's/\.00//')
	
			echo "${b}Vfree in Volume group${reset} ${o}$vg${reset} : $vfree Mb"
		if [[ $extend -le $vfree ]]; then
			lvextend -L '+'$extend"M" $vg 	
				if [[ $? -eq 0 ]]; then
					resize2fs $selected_device
				fi
			echo "${g}Done adding and extending by $extend Mb${reset}"
				
			echo "${b}Updated device information${reset}"
				fs_info=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 1 | sed -rn '1p') | sed -r "s/.*/${b}Fs_device:${reset} &/")
				fs_size=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 2 | sed -rn '2p') | sed -r "s/.*/${b}Fs_size:${reset} &/")
				fs_used=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 3 | sed -rn '3p') | sed -r "s/.*/${b}Fs_used:${reset} &/")
				fs_avail=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 4 | sed -rn '4p') | sed -r "s/.*/${b}Space Avail:${reset} &/")
				fs_use_perc=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 5 | sed -rn '5p') | sed -r "s/.*/${b}Used Percentage:${reset} &/")
				fs_mounted_on=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 6 | sed -rn '6p') | sed -r "s/.*/${b}Mounted On:${reset} &/")

				echo $fs_info | sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"
				echo $fs_size	| sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"

				echo $fs_used	| sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"

				echo $fs_avail	| sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"

				echo $fs_use_perc | sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"

				echo $fs_mounted_on | sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"



				exit 0

		else
		echo "${y}Not enough space available in vg creating loop device to add space${reset}"
		loopFilePath=$(mktemp --suffix=_loopdev)
		fallocate -l $extend"M" $loopFilePath
       			if [[ $? -eq 0 ]]; then
				losetup -f $loopFilePath
				losetupDevice=$(losetup -a | grep -Ei "$loopFilePath" | cut -d ':' -f 1)
				pvcreate $losetupDevice 
				vgextend $vg $losetupDevice
				errormsg=$(lvextend -L "+"$extend"M" $selected_device 2>&1 >/dev/null) 
					
				
					if [[ $? -eq 1 ]];then 
						echo "${r}Errors encountered${reset}"
						echo "${r}Exiting${reset}"
						exit 1	
					fi		
				if [[ -n $errormsg ]] && [[ $errormsg =~ [0-9]{0,5}[[:space:]]available ]]; then
					extent=$(echo "$errormsg" | grep -Eio "[0-9]{0,5}\savailable" | gawk '{ print $1 }')
					lvextend -l "+"$extent $selected_device
					echo "${y}Extending by $extent extents${reset}" 	
				fi
				resize2fs $selected_device | while read -r line; do
					if [[ $line =~ on-line ]]; then
					echo ${o}${line}${reset}
					else
						echo ${g}${line}${reset}
					fi
				done
				echo "${g}Done adding and extending by $extend Mb${reset}"
				echo "${b}Updated device information${reset}"
				fs_info=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 1 | sed -rn '1p') | sed -r "s/.*/Fs_device: &/")
				fs_size=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 2 | sed -rn '2p') | sed -r "s/.*/Fs_size: &/")
				fs_used=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 3 | sed -rn '3p') | sed -r "s/.*/Fs_used: &/")
				fs_avail=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 4 | sed -rn '4p') | sed -r "s/.*/Space Avail: &/")
				fs_use_perc=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 5 | sed -rn '5p') | sed -r "s/.*/Used Percentage: &/")
				fs_mounted_on=$(echo $(df -h | grep -Ei "$selected_device" | tr ' ' '\n' | sed -r '/^$/d' | head -n 6 | sed -rn '6p') | sed -r "s/.*/Mounted On: &/")
				
				echo $fs_info | sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"
				echo $fs_size	| sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"

				echo $fs_used	| sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"

				echo $fs_avail	| sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"

				echo $fs_use_perc | sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"

				echo $fs_mounted_on | sed -r "s/(.*)(:.*)/${o}\1${reset}${g}\2${reset}/"


				exit 0
			else
				echo "${r}No space on Partition /tmp${reset}"
				echo "${r}Exiting${reset}"
				exit 1
			fi	
		exit 1
	fi

	done
}
select_mount_point 

			;;
		c)
			echo "Choose which ${y}Filesystem${reset} to ${o}connect${reset} to ${o}container${reset}"
			echo "${b}Filesystems currently mounted${reset}"

			declare -A lv_mounts

			while read -r device mount_point; do
    			lv_mounts["$device"]="$mount_point"
			done < <(df -h | gawk '{ print $1,$6}' | grep -Ei '/dev/mapper/.*_lv\s')

		display_mount_points() {
    			echo "${b}Available mount points:${reset}"
    			local i=1
    			for mount_point in "${lv_mounts[@]}"; do
        		echo "${y}$i)${reset} ${o}$mount_point${reset}"
        		i=$((i + 1))
    			done
		}

		select_mount_point() {
   		local selected_number
    		declare -g selected_mount_point
    		local selected_device
    		while true; do
        		display_mount_points
        		read -p "Please enter the ${y}number${reset} corresponding to the ${y}mount point${reset} you want to select: " selected_number
        		if [[ $selected_number =~ ^[0-9]+$ ]] && (( selected_number > 0 && selected_number <= ${#lv_mounts[@]} )); then
            		selected_mount_point=$(echo "${lv_mounts[@]}" | awk -v num=$selected_number '{print $num}')
            		for device in "${!lv_mounts[@]}"; do
                		if [[ "${lv_mounts[$device]}" == "$selected_mount_point" ]]; then
                    			selected_device=$device
                    	break
                	fi
            	done
            	echo "${b}Selected:${reset} ${o}$selected_mount_point${reset}"
		list_containers() {
    			echo "${b}Available containers:${reset}"
    			podman ps -a --format "${o}{{.ID}}${reset} ${b}{{.Names}}${reset} ${y}{{.Status}}${reset}" | nl -v 1
		}

		select_container() {
    		local selected_number
    		local container_info
    		declare -g container_id
    		while true; do
        		list_containers
        		read -p "Please enter the ${y}number${reset} corresponding to the ${y}container${reset} you want to ${o}connect${reset}: " selected_number
        		container_info=$(podman ps -a --format "{{.ID}} {{.Names}} {{.Status}}" | nl -v 1 | awk -v num=$selected_number 'NR==num')
        		if [[ -n "$container_info" ]]; then
            			container_id=$(echo "$container_info" | awk '{print $2}')
            		break
        		else
            		echo "${r}Invalid selection. Please try again.${reset}"
        		fi
    		done
	}

		select_container
	
		echo "${y}Attempting to connect device to container${reset}"
       		podman start $container_id 
		if [[ $? -eq 0 ]]; then
			echo "${g}podman started container${reset} ${o}$container_id${reset}"
			mount --bind $selected_mount_point $(echo "$(podman mount $container_id)/mnt" | sed -r 's/ //g')
			if [[ $? -eq 0 ]]; then
				podman exec -it $container_id /bin/bash
			fi
		fi	
	    	break
        	else
            	echo "${r}Invalid selection. Please try again.${reset}"
        fi
    	done
	}

select_mount_point
	
			;;
			
		s)
			echo "snapshotting to be added soon"
			;;
		n)
			echo "Attempting to host mount point as nfs share"
			echo "Choose which ${y}Filesystem${reset} to ${o}connect${reset}"
			echo "${b}Filesystems currently mounted${reset}"

			declare -A lv_mounts

			while read -r device mount_point; do
    			lv_mounts["$device"]="$mount_point"
			done < <(df -h | gawk '{ print $1,$6}' | grep -Ei '/dev/mapper/.*_lv\s')

		display_mount_points() {
    			echo "${b}Available mount points:${reset}"
    			local i=1
    			for mount_point in "${lv_mounts[@]}"; do
        		echo "${y}$i)${reset} ${o}$mount_point${reset}"
        		i=$((i + 1))
    			done
		}

		select_mount_point() {
   		local selected_number
    		declare -g selected_mount_point
    		local selected_device
    		while true; do
        		display_mount_points
        		read -p "Please enter the ${y}number${reset} corresponding to the ${y}mount point${reset} you want to select: " selected_number
        		if [[ $selected_number =~ ^[0-9]+$ ]] && (( selected_number > 0 && selected_number <= ${#lv_mounts[@]} )); then
            		selected_mount_point=$(echo "${lv_mounts[@]}" | awk -v num=$selected_number '{print $num}')
            		for device in "${!lv_mounts[@]}"; do
                		if [[ "${lv_mounts[$device]}" == "$selected_mount_point" ]]; then
                    			selected_device=$device
                    	break
                	fi
            	done
            	echo "${b}Selected:${reset} ${o}$selected_mount_point${reset}"


	
	    	break
        	else
            	echo "${r}Invalid selection. Please try again.${reset}"
        fi
    	done
	}

select_mount_point

	if [[ -f /etc/exports ]] && [[ -n $(grep -Eio "$selected_mount_point" /etc/exports) ]]; then 
		echo "${y}Share already exists in /etc/exports. None Added.${reset}"
		echo -e "\n"
		showmount -e localhost | while read -r line ; do
			if [[ $line =~ Export ]]; then
				echo ${b}$line${reset}
			else
				echo ${o}${line}${reset}
			fi
		done
			if [[ $? -eq 1 ]]; then
				until [[ -n $(systemctl restart nfs-server.service 2>&1 | grep -Ei 'Failed to restart') ]]; do
					echo "Restarting Service..."	
					sleep 1
				done;
				showmount -e
			fi 
				       	
		
	else
		echo "${g}Adding lvmdrive as a share in /etc/exports file${reset}"
		echo "$selected_mount_point	*(rw,sync,no_root_squash)" >> /etc/exports
		if [[ $? -eq 0 ]]; then
			echo "${y}Listing shares on Localhost${reset}"
			exportfs -a 2>/dev/null
			exportfs -r 2>/dev/null
			echo -e '\n'
			showmount -e localhost | while read -r line; do 
				if [[ ${line} =~ Export ]]; then
					echo ${b}${line}${reset} 
				else
				echo ${o}${line}${reset}
				fi
			done
		fi	
	fi
		
	;;	
		z)
			current=$(readlink -f ${BASH_SOURCE[0]})
			scripname=$(basename $current)
			scriptname=$(echo ${scripname/\.sh/})
			
			scripath="/usr/bin"
			filename=lvmlooper_options.zsh
			shell=$SHELL

			if [[ ! $shell =~ zsh ]] && [[ ! -f /root/.zshrc ]]; then
				exit 1
			fi 

			if [[ ! -n $(find ${scripath} -type f -iname "${scriptname}") ]]; then
					ln -s $current ${scripath}/${scriptname} 2>/dev/null
						

		       	fi
	sourcer(){	
			
		if [[ -n $( grep -Ei "source.*options.zsh$" /root/.zshrc ) ]]; then
			sourceFilePath=$(cat /root/.zshrc | grep -Ei 'source' | grep -Ei 'options' |  cut -d ' ' -f 2)
					if [[ -n "$sourceFilePath" ]] || [[ ! -n "$sourceFilePath" ]]; then


					echo "${o}Modifying ${reset}${b}$sourceFilePath${reset}"	
					echo "${o}Listing${reset}${b} Contents of Source file $sourceFilePath${reset}" 
					cat <<EOF | tee $sourceFilePath 
#compdef your_script_name

_your_script_name() {
    local -a commands
    commands=(
        		'-i : Create LVM & loop devices based mounted filesystems/Loopdrives (/mnt/lvmloopfs/tmp*loopdrive) ' 
		'-d : Delete existing lvms created through lvmlooper'
		'-l : List existing files created through lvmlooper'
		'-c : Connect to existing containers deployed through podman'
		'-e : Extend existing mounted loopdrives On-line				       '
		'-n : Create NFS shares from exising loopdrives'
		'-h : Help section'
		'-z : Enable Zsh Auto-tab Completion on options for lvmlooper (zsh users only!)'
	
)
    _describe 'command' commands
}

compdef _your_script_name $scripath/${scriptname}
EOF
					source /root/.zshrc 2>/dev/null
					echo "${g}Custom options zsh auto-tab completion enabled!${reset}"
					echo "${y}Now try [ Tab ] while completing lvmlooper options!${reset}" 
					exit 0
					else
						echo "Only sourcing of existing zsh script.."
						source /root/.zshrc 2>/dev/null
						echo "Custom options zsh auto-tab completion enabled!"
						exit 0
					fi
				fi
	
}	
					
			sourcer
			source /root/.zshrc 2>/dev/null

			echo "source /root/${filename}" >> /root/.zshrc
				sourcer
				source /root/.zshrc 2>/dev/null				
				exit 0	
				
			;;

			
		
	
		\?)
			echo "${r}Invalid option${reset}"
			usage
			;;
		
		:)
			echo "${r}Requires argument${reset}"
			;;
	esac
done

if [[ ! -n $1 ]]; then
	usage
	exit 1 
fi 

shift $((OPTIND-1))

if [[ $# -ge 1 ]]; then
	echo "${r}Too many arguments${reset}"
	usage
	exit 1
fi

