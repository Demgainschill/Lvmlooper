#!/bin/bash

# Declare an associative array
declare -A lv_mounts

# Populate the associative array with device and mount point pairs
while read -r device mount_point; do
    lv_mounts["$device"]="$mount_point"
done < <(df -h | gawk '{ print $1,$6}' | grep -Ei '/dev/mapper/.*_lv\s')

# Function to display available mount points with numbers
display_mount_points() {
    echo "Available mount points:"
    local i=1
    for mount_point in "${lv_mounts[@]}"; do
        echo "$i) $mount_point"
        i=$((i + 1))
    done
}

# Prompt the user to select a mount point by number
select_mount_point() {
    local selected_number
    local selected_mount_point
    while true; do
        display_mount_points
        read -p "Please enter the number corresponding to the mount point you want to select: " selected_number
        # Check if the selected number is valid
        if [[ $selected_number =~ ^[0-9]+$ ]] && (( selected_number > 0 && selected_number <= ${#lv_mounts[@]} )); then
            selected_mount_point=$(echo "${lv_mounts[@]}" | awk -v num=$selected_number '{print $num}')
            echo "You selected: $selected_mount_point"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# Call the function to prompt the user
select_mount_point

