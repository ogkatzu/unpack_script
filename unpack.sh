#!/bin/bash

verbose=0
recursive=0
filename=""
is_dir=0
is_file=0

function main() {
    # This function checks the file type using the file command - returns the compprassion type (if it is compresses)
    # If it is not a compresses file, exit the script
    file_dir=$(dirname "$filename")      # Get directory (e.g., ./path/to)
    file_base=$(basename "$filename")



    comp_type=$(file $filename | awk '{print $2}')
    if [[ "$is_dir" -eq 1 ]]; then
        return 0
    fi
    # This is a check to see if the file has an extension. 
    # Compresses files doesn't necessarily have an extension like .gz/.zip/etc.
    # In order to keep the original compressed as is, 
    # in the case it doesn't have an extension, I'll add "_uncompressed" to the uncompressed file

    if [[ "$file_base" == *.* ]]; then
        output_file="${file_base%.*}"
    else
        output_file="${file_base}_uncompressed"
    fi

    full_output_file="$file_dir/$output_file"

    case "$comp_type" in
        gzip)
            echo $comp_type
            # Here I use the -c to write the stdout
            gunzip -c "$filename" > "$full_output_file"
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
#Fucntion to display the usage and flags of the function
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
        # this checks if any other option beside the ones abvoe was entered
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

file_type=$(main)
echo "${file_type}"
