#!/bin/bash

# Initializing some global variables
verbose=0 # Flag for vebose
recursive=0 # Flag for recursive
filename=""
is_dir=0 
is_file=0
success_counter=0
fail_counter=0

# function to display the usage of the script
function usage() {
        echo "Usage: $0 [-v] [-r] <filename/directory>"
        echo "  -h       : [Optional] Display this message"
        echo "  -v       : [Optional] Enable verbose mode"
        echo "  -r       : [Optional] Enable recursive mode"
        echo "  filename/folder path : [Required] The file/folder to upack - Must be gzip,bzip2,zip or compressd "
        exit 0
}


function main() {
    # main processing function
    file_dir=$(dirname "$filename")      # Get directory if the given file is structured like this: path/to/file.gz
    file_base=$(basename "$filename")   # Get the file name without the path

    comp_type=$(file --mime-type -b "$filename")
    
    if [[ "$is_dir" -eq 1 ]]; then
        return 0
    fi

    # This is a check to see if the file has an extension. 
    # Compressed files don’t necessarily have an extension like .gz/.zip/etc.
    # In order to keep the original compressed file as is, 
    # if it doesn’t have an extension, I'll add "_uncompressed" to the uncompressed file.
    
    if [[ "$file_base" == *.* ]]; then
        output_file="${file_base%.*}"
    else
        output_file="${file_base}_uncompressed"
    fi

    full_output_file="$file_dir/$output_file"

    case "$comp_type" in
        application/gzip)
            gunzip -c "$filename" > "$full_output_file"
            ;;
        application/x-bzip2)
            bunzip2 -c "$filename" > "$full_output_file"
            ;;
        application/zip)
            file_count=$(unzip -l "$filename" | tail -n +4 | head -n -2 | wc -l)
            
            if [[ "$file_count" -eq 1 ]]; then
                unzip -o "$filename" -d "$file_dir"
            else
                mkdir -p "$full_output_file"
                unzip -q -o "$filename" -d "$full_output_file"
            fi
            ;;
        application/x-compress)
            uncompress -c "$filename" > "$full_output_file"
            ;;
        *)
            echo "Ignoring: $filename"
            ((fail_counter++))  # Increment failure counter
            return 1
            ;;
    esac

    if [[ $? -ne 0 ]]; then
        echo "Failed to unpack: $filename"
        ((fail_counter++))  # Increment failure counter
    else
        ((success_counter++))  # Increment success counter
    fi

    return 0
}

# Process CLI arguments
while [[ $# -gt 0 ]]; do
    case "$1" in
        -v) verbose=1; shift ;;
        -r) recursive=1; shift ;;
        -h) usage ;;
        -) shift; break ;;
        -*) echo "Unknown option: $1"; usage ;;
        *) break ;;
    esac
done

# Checking if a file name is given. If not, display the help message and exit the script
if [[ -z "$1" ]]; then
    echo "Error: Missing filename or directory."
    usage
fi

# Processing each file
while [[ $# -gt 0 ]]; do
    filename="$1"
    shift  # Move to the next argument

    if [[ -f "$filename" ]]; then
        is_file=1
        main "$filename"
    elif [[ -d "$filename" ]]; then
        is_dir=1
    else
        echo "$filename does not exist"
        ((fail_counter++))
        continue
    fi

    if [[ $verbose -eq 1 ]]; then
        echo "Unpacking: $filename"
    fi

done

# Print summary
echo "Decompressed: $success_counter archive(s), $fail_counter failed."

# Exit with the number of failed files as the exit code
exit "$fail_counter"