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
        echo "Usage: $0 [-v] [-r] <filenames/directory> "
        echo "  -h       : [Optional] Display this message"
        echo "  -v       : [Optional] Enable verbose mode"
        echo "  -r       : [Optional] Enable recursive mode"
        echo "  filename/folder path : [Required] The files/folder to upack - Must be gzip,bzip2,zip or compressd "
        exit 0
}

function process_file() {
    local filename="$1"
    file_dir=$(dirname "$filename")      # Get directory if the given file is structured like this: path/to/file.gz
    file_base=$(basename "$filename")   # Get the file name without the path

    local comp_type=$(file --mime-type -b "$filename")

    # This is a check to see if the file has an extension. 
    # Compressed files don’t necessarily have an extension like .gz/.zip/etc.
    # In order to keep the original compressed file as is, 
    # if it doesn’t have an extension, I'll add "_uncompressed" to the uncompressed file.

    if [[ "$file_base" == *.* ]]; then
        output_file="${file_base%.*}"
    else
        output_file="${file_base}_uncompressed"
    fi

    local full_output_file="$file_dir/$output_file"

    if [[ $verbose -eq 1 ]]; then
        echo "Unpacking $filename"
    fi

    case "$comp_type" in
        application/gzip)
            gunzip -c "$filename" > "$full_output_file"
            ;;
        application/x-bzip2)
            bunzip2 -c "$filename" > "$full_output_file"
            ;;
        application/zip)
            handle_zip "$filename" "$full_output_file" "$file_dir"
            ;;
        application/x-compress)
            uncompress -c "$filename" > "$full_output_file"
            ;;
        *)
            if [[ $verbose -eq 1 ]]; then
                echo "File type not supported: $filename"
            fi
            ((fail_counter++))
            return 1
            ;;
    esac

    if [[ $? -ne 0 ]]; then
        echo "Failed to unpack: $filename"
        ((fail_counter++))
    else
        ((success_counter++))
    fi

    return 0
}

function handle_zip() {
    local filename="$1"
    local full_output_file="$2"
    local file_dir="$3"

    local file_count=$(unzip -l "$filename" | tail -n +4 | head -n -2 | wc -l)
    
    if [[ "$file_count" -eq 1 ]]; then
        unzip -q -o "$filename" -d "$file_dir"
    else
        mkdir -p "$full_output_file"
        unzip -q -o "$filename" -d "$full_output_file"
    fi
}

# Processing the given CLI arguments
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

if [[ -z "$1" ]]; then
    echo "Error: Missing filename or directory."
    usage
fi

function process_directory() {
    local dir="$1"
    local cur_dir="$2"
    # Process all items in this directory
    for item in "$dir"/*; do
        if [[ -f "$item" ]]; then
            process_file "$item"
        elif [[ -d "$item" ]]; then
            # Checking to see if -r is passed and the current file is directory. If so I run the function again.
            if [[ -d "$item" && "$recursive" -eq 1 ]]; then
                process_directory "$item" $((current_depth + 1))
            fi
        fi
    done
}

function main() {

    while [[ $# -gt 0 ]]; do
        filename="$1"
        shift

        if [[ -f "$filename" ]]; then
            is_file=1
            process_file "$filename"
        elif [[ -d "$filename" ]]; then
            is_dir=1
            for item in "$filename"/*; do
                if [[ -f $item ]]; then
                    process_file "$item"
                elif [[ -d "$item" && "$recursive" -eq 1 ]]; then
                    process_directory $item 1
                fi
            done
        else
            echo "$filename does not exist"
            ((fail_counter++))
            continue
        fi


    done

    echo "Decompressed: $success_counter archive(s), $fail_counter failed."
    exit "$fail_counter"
}

main "$@" # run the main fucntion with all the given CLI arguments passed ($@)