#!/bin/bash

# Assign arguments to variables
writefile="$1"
writestr="$2"

# Check if both arguments are provided
if [ -z "$writefile" ] || [ -z "$writestr" ]; then
    echo "Error: Both arguments must be provided."
    exit 1
fi

# Create the directory structure if it doesn't exist
mkdir -p "$(dirname "$writefile")"

# Write the string to the file, creating or overwriting the file
echo "$writestr" > "$writefile"

# Check if the file was created
if [ $? -ne 0 ]; then
    echo "Error: Could not create file."
    exit 1
fi

exit 0
