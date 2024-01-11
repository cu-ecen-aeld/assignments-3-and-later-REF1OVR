#!/bin/bash

# Assign arguments to variables
filesdir="$1"
searchstr="$2"

# Check if both arguments are provided
if [ -z "$filesdir" ] || [ -z "$searchstr" ]; then
    echo "Error: Both arguments must be provided."
    exit 1
fi

# Check if filesdir is valid directory
if [ ! -d "$filesdir" ]; then
    echo "Error: Provided path is not a directory."
    exit 1
fi

# Count the number of files and matching lines
file_count=$(find "$filesdir" -type f | wc -l)
matching_lines_count=$(grep -r "$searchstr" "$filesdir" | wc -l)

# Print the result
echo "The number of files are $file_count and the number of matching lines are $matching_lines_count"

exit 0
