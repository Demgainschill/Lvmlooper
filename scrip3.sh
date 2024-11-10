#!/bin/bash

# Function to list all containers and assign numbers
list_containers() {
    echo "Available containers:"
    podman ps -a --format "{{.ID}} {{.Names}} {{.Status}}" | nl -v 1
}

# Function to prompt the user to select a container by number
select_container() {
    local selected_number
    local container_info
    local container_id
    while true; do
        list_containers
        read -p "Please enter the number corresponding to the container you want to select: " selected_number
        # Check if the selected number is valid
        container_info=$(podman ps -a --format "{{.ID}} {{.Names}} {{.Status}}" | nl -v 1 | awk -v num=$selected_number 'NR==num')
        if [[ -n "$container_info" ]]; then
            container_id=$(echo "$container_info" | awk '{print $2}')
            echo "You selected container ID: $container_id"
            break
        else
            echo "Invalid selection. Please try again."
        fi
    done
}

# Call the function to prompt the user
select_container

