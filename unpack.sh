#!/bin/bash

verbose=0
recursive=0
filename=""
is_dir=0
is_file=0

function check_compression_type() {
    # This function checks the file type using the file command - returns the compprassion type (if it is compresses)
    # If it is not a compresses file, exit the script
    comp_type=$(file $filename | awk '{print $2}')
    if [[ "$is_dir" -eq 1 ]]; then
        return 0
    fi
    case "$comp_type" in
        gzip)
            echo $comp_type
            ;;
        bzip2)
            echo $comp_type
            ;;
        zip)
            echo $comp_type
            ;;
        *compress*)
            echo $comp_type
            ;;
        # more options for compressed file can be added:
        # for example:
        # tar)
        *)
            echo "File is not supported"
            usage
            ;;
    esac
}

function usage() {
        echo "Usage: $0 [-v] [-r] <filename/directory>"
        echo "  -h       : [Optional] Display this message"
        echo "  -v       : [Optional] Enable verbose mode"
        echo "  -r       : [Optional] Enable recursive mode"
        echo "  filename/folder path : [Required] The file/folder to upack - Must be gzip,bzip2,zip or compressd "
        exit 0
}


while [[ $# -gt 0 ]]; do
    case "$1" in
        -v) verbose=1; shift ;;
        -r) recursive=1; shift ;;
        -h) usage;;
        -) shift; break ;; 
        -*) echo "Unknown option: $1"; usage ;;
        *) break ;;
    esac
done

# Chceking if file name is given. If not, display the help messege and exit the script
if [[ -z "$1" ]]; then
    echo "Error: Missing filename or directory."
    usage
fi

# $1 = first argument = filename
filename="$1"
# checking if the filename given is file or a folder
if [[ -f "$filename" ]]; then
    is_file=1
elif [[ -d "$filename" ]]; then
    is_dir=1
else
    echo "$filename does not exist"
    exit 1
fi

if [[ $verbose -eq 1 ]]; then
    echo "Processing file: $filename"
fi

# if [[ $recursive -eq 1 ]]; then
#     echo "Recursive mode enabled"
# fi

file_type=$(check_compression_type)
echo "${file_type}"
