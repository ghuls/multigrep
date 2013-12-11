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


# By default, search the whole line for the pattern.
field_numbers=0;
# Set the default field separator to TAB.
field_separator='\t';



# Function for printing the help text.
usage () {
    add_spaces="           ${0//?/ }";

    printf "\n%s\n%s\n%s\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n%s\n\n" \
           "Usage:     ${0} -g grep_patterns_file" \
           "${add_spaces} [-f field_numbers]" \
           "${add_spaces} [-s field_separator]" \
           "${add_spaces} [file(s)]" \
           "Arguments:" \
           "           -f field_numbers         Comma separated list of field numbers." \
           "                                    If specified, the pattern natching will" \
           "                                    only occur in those fields instead of" \
           "                                    in the whole line ( = field_number=0)." \
           "           -g grep_patterns_file    File with patterns to grep for (required)." \
           "           -s field_separator       Field separator (default: '\t')." \
           "Purpose:" \
           "           Grep for multiple patterns at once in one or more files.";
}






# Retrieve passed arguments and filenames.
until ( [ -z "$1" ] ) ; do
    case "${1}" in
        -f)          if [ -z "${2}" ] ; then
                         printf "\nERROR: Parameter '-f' requires comma separated list of fields as argument.\n\n" > /dev/stderr;
                         exit 1;
                     else
                         field_numbers="${2}";
                         shift 2;
                     fi;;
        -g)          if [ -z "${2}" ] ; then
                         printf "\nERROR: Parameter '-g' requires a file with grep patterns as argument.\n\n" > /dev/stderr;
                         exit 1;
                     else
                         grep_patterns_file="${2}";
                         shift 2;
                     fi;;
        -s)          if [ -z "${2}" ] ; then
                         printf "\nERROR: Parameter '-s' requires a field separator pattern as argument.\n\n" > /dev/stderr;
                         exit 1;
                     else
                         field_separator="${2}";
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
                         printf "\nERROR: Unknown parameter '$1'.\n\n" > /dev/stderr;
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
    printf "\nERROR: Specify a grep patterns file.\n\n" > /dev/stderr;
    exit 1;
elif [ ! -f "${grep_patterns_file}" ] ; then
    printf "\nERROR: The grep patterns file '%s' could not be found.\n\n" "${grep_patterns_file}" > /dev/stderr;
    exit 1;
fi



"${AWK}" \
    -v grep_patterns_file="${grep_patterns_file}" \
    -v field_numbers="${field_numbers}" \
    -F "${field_separator}" \
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

            # Split field_numbers on comma.
            nbr_of_fields = split(field_numbers, field_numbers_array, ",");

            if ( nbr_of_fields == 0 ) {
                # If no field_number is passed, set it to 0 (= whole line).
                field_numbers_array[1] = 0;
            } else {
                for ( field_number_idx in field_numbers_array ) {
                    # Make an integer of each field number.
                    field_numbers_array[field_number_idx] = int(field_numbers_array[field_number_idx]);

                    # If it is not an number it will be converted to 0 by awk.
                    if ( field_numbers_array[field_number_idx] == 0 ) {
                        # If we need to match the whole line it does not make sense to check individual fields,
                        # so delete the array and recreate it with only one element set to 0 (= whole line).
                        delete field_numbers_array;
                        field_numbers_array[1] = 0;
                        break;
                    }
                }
            }
    }
    {
            # Loop over all selected fields to look for the patterns.
            for ( field_number_idx in field_numbers_array ) {
                # Go to the next field number if the current selected field number
                # is higher than the number of fields of the current line.
                if ( field_numbers_array[field_number_idx] > NF ) {
                    continue;
                }

                # Set content variable to the right field number (= 1 or higher) or the whole line (= 0).
                content = $field_numbers_array[field_number_idx];

                # Check for each pattern if it matches the selected field.
                for ( grep_pattern_idx in grep_pattern_array ) {
                    # Check for the current pattern if it matches the selected field.
                    if ( content ~ grep_pattern_array[grep_pattern_idx] ) {
                        # Print the current input line if the pattern matches.
                        print $0;

                        # Save the last printed line number, to prevent printing the same line more than once.
                        last_printed_linenumber = NR;

                        # Go out of the grep_pattern_array for loop, so no useless iterations are done.
                        break;
                    }
                }

                # Go out of the field_numbers_array for loop and read next line, when we already printed the
                # current line (no need to check of another match in the current line in another field).
                if ( last_printed_linenumber == NR ) {
                    break;
                }
            }
    }' "${input_files[@]}";



# Return the exit code returned by the awk command.
exit $?;

