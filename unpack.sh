#!/bin/bash

#intilazing some global variables
verbose=0
recursive=0
filename=""
is_dir=0
is_file=0
success_counter=0
fail_counter=0

function main() {
    # This function checks the file type using the file command - returns the compprassion type (if it is compresses)
    file_dir=$(dirname "$filename")      # Get directory if the given file is strctured like this path/to/file.gz
    file_base=$(basename "$filename")   # Getting the file name with the path to the file



    comp_type=$(file --mime-type -b "$filename")
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
        application/gzip)
            # Here I use the -c to write the stdout
            gunzip -c "$filename" > "$full_output_file"
            ;;
        application/x-bzip2)
            bunzip2 -c "$filename" > "$full_output_file"
            ;;
        application/zip)
            # unzip command unzips the comppressed file to a folder
            mkdir -p "$full_output_file"
            unzip -o "$filename" -d "$full_output_file"
            ;;
        application/x-compress)
            uncompress -c "$filename" > "$full_output_file"
            ;;
        # more options for compressed file can be added:
        # for example:
        # tar)
        *)
            echo "File is not supported"
            ((fail_counter++))
            return 1
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
if [[ $# -lt 1 ]]; then
    echo "Error: Missing filename(s)."
    usage
fi

# Function to process a single file
process_file() {
    local filename="$1"

    # Check if it's a file or directory
    if [[ -f "$filename" ]]; then
        is_file=1
    elif [[ -d "$filename" ]]; then
        is_dir=1
    else
        echo "$filename does not exist"
        return
    fi

    if [[ $verbose -eq 1 ]]; then
        echo "Processing file: $filename"
    fi

    # Call the decompression function
    file_type=$(main "$filename")

    if [[ $? -ne 0 ]]; then
        echo "Error processing $filename"
        ((fail_counter++))
        return 1  # Return failure if the main function failed
    fi

    echo "Successfully processed: $filename"
    ((success_counter++))
    return 0  # 0 = Success
    echo "${file_type}"
}

# Process all provided files
succes=0
for file in "$@"; do
    process_file "$file" || success=1
done
echo "Total files unpacked: $success_counter"
exit $success
