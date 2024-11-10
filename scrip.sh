#!/bin/bash

# Declare an associative array
declare -A lv_mounts

# Populate the associative array with device and mount point pairs
while read -r device mount_point; do
    lv_mounts["$device"]="$mount_point"
done < <(df -h | gawk '{ print $1,$6}' | grep -Ei '/dev/mapper/.*_lv\s')

# Function to display available mount points
display_mount_points() {
    echo "Available mount points:"
    for mount_point in "${lv_mounts[@]}"; do
        echo "$mount_point"
    done
}

# Prompt the user to select a mount point
select_mount_point() {
    local selected_mount_point
    while true; do
        display_mount_points
        read -p "Please enter the mount point you want to select: " selected_mount_point
        # Check if the selected mount point is valid
        if [[ " ${lv_mounts[@]} " =~ " ${selected_mount_point} " ]]; then
            echo "You selected: $selected_mount_point"
            break
        else
            echo "Invalid mount point. Please try again."
        fi
    done
}

# Call the function to prompt the user
select_mount_point

