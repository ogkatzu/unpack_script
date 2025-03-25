#!/bin/bash

# github repo can be found here:
# https://github.com/ogkatzu/unpack_script

# Initializing some global variables
verbose=0 # Flag for vebose
recursive=0 # Flag for recursive
filename=""
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

function check_dependencies() {
    # Fucntion to check wether the required packages are installed
    local missing=() # initilazing a list that will include the missing packages (if there are)
    for cmd in unzip gunzip bunzip2 uncompress; do
        # cmd is a list of the required packages - more can be added if needed
        if ! command -v "$cmd" &> /dev/null; then
            # the command 'command' (when passed with -v) will return a single word indicating the 
            # command or file name used to invoke command to be displayed
            # &> /dev/null will silence the output of the command (making ir run silently) - sending to "grabage bucket"
            # if the command is not found (hence using the NOT operator !) it will add the current command to the list of missing commands
            missing+=("$cmd")
        fi
    done

    if [[ ${#missing[@]} -gt 0 ]]; then
        # Check if the length of the missing array is larger then 0
        echo "Error: Missing required packages: ${missing[*]}"
        exit 1
    fi
}

function print_verbose()
{
    if [[ $verbose -eq 1 ]]; then
        echo "Unpacking $filename"
    fi
}

function process_file() {
    : '
    Main processing function 
    Gets file name and preform the matching uncompression command based on the output of the file command
    '
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
        unzip -q -o "$filename" -d "$file_dir" # -o overwrite files WITHOUT prompting & -q for quite mode
    else
        mkdir -p "$full_output_file" # -p makes parent directory(s)
        unzip -q -o "$filename" -d "$full_output_file"
    fi
}


function process_directory() {
    local dir="$1"
    # Process all items in this directory
    for item in "$dir"/*; do
        if [[ -f "$item" ]]; then
            process_file "$item"
        elif [[ -d "$item" ]]; then
            # Checking to see if -r is passed and the current file is directory. If so I run the function again.
            if [[ -d "$item" && "$recursive" -eq 1 ]]; then
                process_directory "$item"
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
    check_dependencies
    while [[ $# -gt 0 ]]; do
        filename="$1"
        shift

        if [[ -f "$filename" ]]; then
            process_file "$filename"
        elif [[ -d "$filename" ]]; then
            for item in "$filename"/*; do
                if [[ -f $item ]]; then
                    process_file "$item"
                elif [[ -d "$item" && "$recursive" -eq 1 ]]; then
                    process_directory "$item"
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