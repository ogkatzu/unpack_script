#!/bin/bash

# github repo can be found here:
# https://github.com/ogkatzu/unpack_script

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
function print_verbose()
{
    if [[ $verbose -eq 1 ]]; then
        echo "Unpacking $filename"
    fi
}
function process_file() {
    local filename="$1"
    local file_dir=$(dirname "$filename")      # Get directory if the given file is structured like this: path/to/file.gz
    local file_base=$(basename "$filename")   # Get the file name without the path

    local comp_type=$(file --mime-type -b "$filename")
    : '
    This is a check to see if the file has an extension. 
    Compressed files dont necessarily have an extension like .gz/.zip/etc.
    In order to keep the original compressed file as is, 
    if it doesnt have an extension, Ill add "_uncompressed" to the uncompressed file.
    '
    if [[ "$file_base" == *.* ]]; then
        output_file="${file_base%.*}"
    else
        output_file="${file_base}_uncompressed"
    fi

    local full_output_file="$file_dir/$output_file"

    # if [[ $verbose -eq 1 ]]; then
    #     echo "Unpacking $filename"
    # fi

    case "$comp_type" in
        application/gzip)
            print_verbose $filename
            gunzip -c "$filename" > "$full_output_file"
            ;;
        application/x-bzip2)
            print_verbose $filename
            bunzip2 -c "$filename" > "$full_output_file"
            ;;
        application/zip)
            print_verbose $filename
            handle_zip "$filename" "$full_output_file" "$file_dir"
            ;;
        application/x-compress)
            print_verbose $filename
            uncompress -c "$filename" > "$full_output_file"
            ;;
        *)
            if [[ $verbose -eq 1 ]]; then
                echo "Ignoring: $filename"
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
    : '
    Zip is special because unlike the other compression formats, 
    it can compress a few file into one archive, unlike bzip2 or gzip.
    This fucntion comes to solve this issue by checking if the zip contains more the one file
    '
    local filename="$1"
    local full_output_file="$2"
    local file_dir="$3"
    : '
    here I check how many files are in the zip using the -l flag in the zip command.
    tail -n +4 will discard the 4 first lines
    head -n -2 will discard the 2 last lines
    wc -l will count the number of lines in the processed unzip -l command
    > 1 means that there are more then 1 file in the zip archive
    '
    local file_count=$(unzip -l "$filename" | tail -n +4 | head -n -2 | wc -l)
    
    if [[ "$file_count" -eq 1 ]]; then
        unzip -q -o "$filename" -d "$file_dir"
    else
        mkdir -p "$full_output_file"
        unzip -q -o "$filename" -d "$full_output_file"
    fi
}



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

function main() {
    # running a loop over all the file arguments. The code above "shift" the arguments (like -r or -v) 
    # and what is left is only the file/directory names.
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

    echo "Decompressed $success_counter archive(s)"
    exit "$fail_counter" # exiting with the number of faild files as an exit code (default = 0)
}
main "$@" # run the main fucntion with all the given CLI arguments passed ($@)