#!/bin/bash
#
# Copyright (C) 2013  - Gert Hulselmans
#
# Purpose: Grep for multiple patterns at once in one or more files.



# Define the location of mawk and gawk:
#
# Those values can be overwritten from outside of this script with:
#      MAWK=/some/path/to/mawk ./multigrep.sh
# Or:
#      export MAWK=/some/path/to/mawk
#      ./multigrep.sh
trash="${MAWK:='mawk'}";
trash="${GAWK:='gawk'}";

# Try to use the following awk variants in the following order:
#   1. mawk
#   2. gawk
#   3. awk
if [ $(type "${MAWK}" > /dev/null 2>&1; echo $?) -eq 0 ] ; then
    AWK="${MAWK}";
elif  [ $(type "${GAWK}" > /dev/null 2>&1; echo $?) -eq 0 ] ; then
    AWK="${GAWK}";
else
    AWK='awk';
fi



# Filename which contains the patterns to grep for.
grep_patterns_file='';

# Create an array for storing all input filenames passed on the command line.
declare -a input_files;
# Index for the input_files array.
declare -i i=0;





# Function for printing the help text.
usage () {
    add_spaces="           ${0//?/ }";

    printf "\n%s\n\n%s\n%s\n\n%s\n%s\n\n" \
           "Usage:     ${0} -g grep_patterns_file [file(s)]" \
           "Arguments:" \
           "           -g grep_patterns_file    File with patterns to grep for." \
           "Purpose:" \
           "           Grep for multiple patterns at once in one or more files.";
}





# Retrieve passed arguments and filenames.
until ( [ -z "$1" ] ) ; do
    case "${1}" in
        -g)          if [ -z "${2}" ] ; then
                         printf "\nERROR: Parameter '-g' requires a file with grep patterns as argument.\n\n";
                         exit 1;
                     else
                         grep_patterns_file="${2}";
                         shift 2;
                     fi;;
        -h)          usage;
                     exit 0;;
        --help)      usage;
                     exit 0;;
        --usage)     usage;
                     exit 0;;
        -)           # Add stdin to array.
                     input_files[${i}]='-';
                     i=i+1;
                     shift 1;;
        *)           if [ ! -e "${1}" ] ; then
                         printf "\nERROR: Unknown parameter '$1'.\n\n";
                         usage;
                         exit 1;
                     fi
                     # Add input files to array.
                     input_files[${i}]="${1}";
                     i=i+1;
                     shift 1;;
    esac
done



if [ -z "${grep_patterns_file}" ] ; then
    printf "\nERROR: Specify a grep patterns file.\n\n";
    exit 1;
elif [ ! -f "${grep_patterns_file}" ] ; then
    printf "\nERROR: The grep patterns file '%s' could not be found.\n\n" "${grep_patterns_file}";
    exit 1;
fi



"${AWK}" \
    -v grep_patterns_file="${grep_patterns_file}" \
    '
    BEGIN {
            # Index for the grep_pattern_array.
            i = 0;
            
            # Read grep patterns in an array.
            while ( (getline < grep_patterns_file) > 0 ) {
                # Increase the index.
                i += 1;
                
                # Save pattern from grep pattern file to array.
                grep_pattern_array[i] = $0;
            }
    }
    {
            for (grep_pattern_index in grep_pattern_array) {
                if ( $0 ~ grep_pattern_array[grep_pattern_index] ) {
                    # Print the current input line if the pattern matches.
                    print $0;
                    
                    # Go out of the for loop and read next line, when a match
                    # was found. This prevents reporting the same line multiple
                    # times when multiple patterns match the current line.
                    break;
                }
            }
    }' "${input_files[@]}";



# Return the exit code returned by the awk command.
exit $?;

