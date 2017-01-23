#!/bin/bash
#
# Copyright (C) 2013-2016 - Gert Hulselmans
#
# Purpose: Grep for multiple patterns at once in one or more columns.



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

# Pattern to search for.
search_pattern='';

# Pattern separator.
pattern_separator='';


# Create an array for storing all input filenames passed on the command line.
declare -a input_files;
# Index for the input_files array.
declare -i input_files_idx=0;


# By default, search the whole line for the pattern.
field_numbers=0;
# Set the default field separator to TAB.
field_separator='\t';

# By default, use the whole line of the grep pattern file as a pattern.
grep_patterns_file_field_number=0;


# Append grep patterns file content. (= 1) or not (= 0).
append_grep_patterns_file_content=0;


# Interpret patterns as regular expressions (= 1) or not (= 0).
regex=0;


# Match whole field (= 1) or not (= 0).
match_whole_field=0;

# Invert match (= 1) or not (= 0).
invert_match=0;



# Function for printing the help text.
usage () {
    add_spaces="  ${0//?/ }";

    printf '\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n%s\n\n%s\n\n%s\n\n' \
           'Usage:' \
           "  ${0} [-g grep_patterns_file]" \
           "${add_spaces} [-G grep_patterns_file_field_number]" \
           "${add_spaces} [-p search_pattern] [-P pattern_separator]" \
           "${add_spaces} [-f field_numbers]  [-s field_separator]" \
           "${add_spaces} [-a] [-r] [-w] [-v]" \
           "${add_spaces} [file(s)]" \
           'Options:' \
           '  -f field_numbers       Comma separated list of field numbers.   (default: 0)' \
           '                         If specified, pattern matching will only be performed' \
           '                         on the specified fields instead of on the whole line.' \
           '  -g grep_patterns_file  File with patterns to grep for.   (required if no -p)' \
           '  -G grep_patterns_file_field_number' \
           '                         Use only specified field from grep patterns file and' \
           '                         and append content of grep pattern file to lines' \
           '                         matching the specified field.' \
           '  -p search_pattern      Pattern(s) to search for.         (required if no -g)' \
           "  -P pattern_separator   Pattern separator.                      (default: '')" \
           '                         Make separate patterns by splitting search_pattern' \
           '                         string of -p option at each pattern_separator.' \
           '  -a                     Append grep patterns file content.' \
           '  -r                     Interpret patterns as regular expressions.' \
           "  -s field_separator     Field separator.                      (default: '\t')" \
           '  -w                     Pattern(s) need to match the whole line or field.' \
           '                         Pattern matching will be very fast with this option.' \
           '  -v                     Invert the sense of matching, to select non-matching' \
           '                         fields/lines.' \
           'Purpose:' \
           '  Grep for multiple patterns at once in one or more columns.';
}





# Create an array for storing all arguments passed on the command line.
declare -a args_array;
# Define arg_idx as an integer.
declare -i arg_idx=0;
# Define next_arg_idx as an integer.
declare -i next_arg_idx=0;
# Get number of arguments.
declare -i nbr_args="${#@}";


for arg in "${@}" ; do
    # Store all passed arguments in args_array.
    args_array[${arg_idx}]="${arg}";

    # Increase args_array index.
    arg_idx=arg_idx+1;
done


if [ ${nbr_args} -eq 0 ] ; then
    # Print help message if no parameters are passed and exit.
    usage;
    exit 0;
fi



for arg_idx in "${!args_array[@]}" ; do
    if [ ${arg_idx} -ne ${next_arg_idx} ] ; then
        # Don't process the argument arg_idx points to when the previous
        # argument was an option ("-f", "-g", "-G", "-p", "-P" or "-s")
        # which requires an argument.
        continue;
    fi

    case "${args_array[${arg_idx}]}" in
        -f)          if [ $((arg_idx+1)) -eq ${nbr_args} ] ; then
                         # "-f" was the last argument, so no field numbers were given.
                         printf "\nERROR: Parameter '-f' requires comma separated list of fields as argument.\n\n" > /dev/stderr;
                         exit 1;
                     else
                         # Increase the next argument index with 1,
                         # so the field numbers argument will be
                         # skipped in the next for loop iteration.
                         next_arg_idx=next_arg_idx+1;

                         # Get the field numbers.
                         field_numbers="${args_array[${next_arg_idx}]}";

                         # Remove "-f" and field numbers from the list of arguments.
                         unset args_array[${arg_idx}];
                         unset args_array[${next_arg_idx}];
                     fi;;
        -g)          if [ $((arg_idx+1)) -eq ${nbr_args} ] ; then
                         # "-g" was the last argument, so no grep patterns filename was given.
                         printf "\nERROR: Parameter '-g' requires a file with grep patterns as argument.\n\n" > /dev/stderr;
                         exit 1;
                     else
                         # Increase the next argument index with 1,
                         # so the grep patterns filename argument will
                         # be skipped in the next for loop iteration.
                         next_arg_idx=next_arg_idx+1;

                         # Get the grep patterns filename.
                         grep_patterns_file="${args_array[${next_arg_idx}]}";

                         # Remove "-g" and filename from the list of arguments.
                         unset args_array[${arg_idx}];
                         unset args_array[${next_arg_idx}];
                     fi;;
        -G)          if [ $((arg_idx+1)) -eq ${nbr_args} ] ; then
                         # Remove "-g" and grep patterns filename from the list of arguments.
                         printf "\nERROR: Parameter '-G' requires a field number of the grep pattern file argument.\n\n" > /dev/stderr;
                         exit 1;
                     else
                         # Increase the next argument index with 1,
                         # so the search pattern argument will be
                         # skipped in the next for loop iteration.
                         next_arg_idx=next_arg_idx+1;

                         # Get the field number for grep pattern file.
                         grep_patterns_file_field_number="${args_array[${next_arg_idx}]}";

                         # Remove "-g" and grep patterns filename from the list of arguments.
                         unset args_array[${arg_idx}];
                         unset args_array[${next_arg_idx}];
                     fi;;
        -p)          if [ $((arg_idx+1)) -eq ${nbr_args} ] ; then
                         # "-p" was the last argument, so no search pattern was given.
                         printf "\nERROR: Parameter '-p' requires a search pattern as argument.\n\n" > /dev/stderr;
                         exit 1;
                     else
                         # Increase the next argument index with 1,
                         # so the search pattern argument will be
                         # skipped in the next for loop iteration.
                         next_arg_idx=next_arg_idx+1;

                         # Get the search pattern.
                         search_pattern="${args_array[${next_arg_idx}]}";

                         # Remove "-p" and search pattern from the list of arguments.
                         unset args_array[${arg_idx}];
                         unset args_array[${next_arg_idx}];
                     fi;;
         -P)          if [ $((arg_idx+1)) -eq ${nbr_args} ] ; then
                         # "-P" was the last argument, so no pattern separator was given.
                         printf "\nERROR: Parameter '-P' requires a pattern separator as argument.\n\n" > /dev/stderr;
                         exit 1;
                     else
                         # Increase the next argument index with 1,
                         # so the pattern separator argument will be
                         # skipped in the next for loop iteration.
                         next_arg_idx=next_arg_idx+1;

                         # Get the search pattern separator.
                         pattern_separator="${args_array[${next_arg_idx}]}";

                         # Remove "-P" and search pattern separator from the list of arguments.
                         unset args_array[${arg_idx}];
                         unset args_array[${next_arg_idx}];
                     fi;;
        -a)          # Append grep patterns file content.
                     append_grep_patterns_file_content=1;;
        -r)          # Interpret patterns as regular expressions.
                     regex=1;;
        -s)          if [ $((arg_idx+1)) -eq ${nbr_args} ] ; then
                         # "-s" was the last argument, so no field separator was given.
                         printf "\nERROR: Parameter '-s' requires a field separator pattern as argument.\n\n" > /dev/stderr;
                         exit 1;
                     else
                         # Increase the next argument index with 1,
                         # so the field separator argument will be
                         # skipped in the next for loop iteration.
                         next_arg_idx=next_arg_idx+1;

                         # Get the field separator.
                         field_separator="${args_array[${next_arg_idx}]}";

                         # Remove "-s" and field separator from the list of arguments.
                         unset args_array[${arg_idx}];
                         unset args_array[${next_arg_idx}];
                     fi;;
        -w)          # A pattern need to match exactly with the whole line or selected fields.
                     match_whole_field=1;;
        -v)          # Invert the sense of matching, to select non-matching fields/lines.
                     invert_match=1;;
        -h)          usage;
                     exit 0;;
        --help)      usage;
                     exit 0;;
        --usage)     usage;
                     exit 0;;
        -)           # Add stdin to array.
                     input_files[${input_files_idx}]='-';
                     input_files_idx=input_files_idx+1;;
        *)           if [ ! -e "${args_array[${arg_idx}]}" ] ; then
                         printf "\nERROR: Unknown parameter '%s'.\n\n" "${args_array[${arg_idx}]}" > /dev/stderr;
                         usage;
                         exit 1;
                     fi
                     if [ -d "${args_array[${arg_idx}]}" ] ; then
                         printf "\nERROR: '%s' is not a file but a directory.\n\n" "${args_array[${arg_idx}]}" > /dev/stderr;
                         exit 1;
                     fi
                     # Add input files to array.
                     input_files[${input_files_idx}]="${args_array[${arg_idx}]}";
                     input_files_idx=input_files_idx+1;;
    esac

    # Increase the next argument index with 1.
    next_arg_idx=next_arg_idx+1;
done


if ( [ ${regex} -eq 1 ] && [ ${match_whole_field} -eq 1 ] ) ; then
    printf "\nERROR: Options -r and -w are mutually exclusive.\n\n" > /dev/stderr;
    exit 1;
fi


if ( [ -z "${grep_patterns_file}" ] && [ -z "${search_pattern}" ] ) ; then
    printf "\nERROR: Specify a grep patterns file (-g) or a search pattern (-p).\n\n" > /dev/stderr;
    exit 1;
elif [ ! -z "${grep_patterns_file}" ] ; then
    if [ "${grep_patterns_file}" != '-' ] ; then
        if [ ! -e "${grep_patterns_file}" ] ; then
            printf "\nERROR: The grep patterns file '%s' could not be found.\n\n" "${grep_patterns_file}" > /dev/stderr;
            exit 1;
        fi
        if [ -d "${grep_patterns_file}" ] ; then
            printf "\nERROR: The grep patterns file '%s' is not a file but a directory.\n\n" "${grep_patterns_file}" > /dev/stderr;
            exit 1;
        fi
    fi
fi



"${AWK}" \
    -v grep_patterns_file="${grep_patterns_file}" \
    -v search_pattern="${search_pattern}" \
    -v pattern_separator="${pattern_separator}" \
    -v field_numbers="${field_numbers}" \
    -v grep_patterns_file_field_number="${grep_patterns_file_field_number}" \
    -v append_grep_patterns_file_content="${append_grep_patterns_file_content}" \
    -v match_whole_field="${match_whole_field}" \
    -v regex="${regex}" \
    -v invert_match="${invert_match}" \
    -F "${field_separator}" \
    '
    BEGIN {
            # Check if a grep patterns file was specified.
            if ( grep_patterns_file != "" ) {
                # Read grep patterns in the grep_pattern_array array.
                while ( (getline < grep_patterns_file) > 0 ) {
                    # Save pattern (whole line or certain column, depending on value of grep_patterns_file_field_number)
                    # from grep pattern file to array.
                    grep_pattern_array[$grep_patterns_file_field_number] = $grep_patterns_file_field_number;

                    if ( append_grep_patterns_file_content == 1 ) {
                        # Save whole line from grep pattern file to array when the "-a" is set.
                        grep_pattern_full_line_array[$grep_patterns_file_field_number] = $0;
                    }
                }
            }

            # Check if a search_pattern was provided.
            if ( search_pattern != "" ) {
                if ( pattern_separator != "" ) {
                    split( search_pattern, search_pattern_array, pattern_separator );

                    for ( search_pattern_idx in search_pattern_array ) {
                        # Add each search_pattern_element to the grep_pattern_array array.
                        grep_pattern_array[search_pattern_array[search_pattern_idx]] = search_pattern_array[search_pattern_idx];
                    }
                } else {
                    # Add search_pattern to the grep_pattern_array array.
                    grep_pattern_array[search_pattern] = search_pattern;
                }
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

                    # If it is not a number it will be converted to 0 by awk.
                    if ( field_numbers_array[field_number_idx] == 0 ) {
                        # If we need to match the whole line it does not make sense
                        # to check individual fields, so delete the array and recreate
                        # it again with only one element set to 0 (= whole line).
                        delete field_numbers_array;
                        field_numbers_array[1] = 0;
                        break;
                    }
                }
            }

            # Set last printed line number to a non-existent line number.
            last_printed_linenumber = 0;
    }

    # Process input files line by line.
    {
            # Set current_line_has_match back to zero as a new input line is processed.
            current_line_has_match = 0;

            # Reset grep_pattern_string.
            grep_pattern_string = "";

            # Loop over all selected fields to look for the patterns.
            for ( field_number_idx in field_numbers_array ) {
                # Go out of the field_numbers_array for loop and read next line,
                # when we already printed the current line (no need to check for
                # another match in the current line or in another field).
                if ( last_printed_linenumber == NR ) {
                    break;
                }

                # Go to the next field number if the current selected field number
                # is higher than the number of fields of the current line.
                if ( field_numbers_array[field_number_idx] > NF ) {
                    continue;
                }

                # Set content variable to the right field number (= 1 or higher)
                # or the whole line (= 0).
                content = $field_numbers_array[field_number_idx];

                if ( regex == 0 ) {
                    # match_whole_field = 1
                    # ---------------------
                    #
                    # If the patterns need to be interpreted as normal text and if
                    # the patterns needs to match the whole field/line, a direct
                    # key lookup (very fast) in the grep_pattern_array is possible
                    # to find an exact match by checking all patterns at once.
                    #
                    # match_whole_field = 0:
                    # ----------------------
                    #
                    # If the patterns need to be interpreted as normal text but do
                    # not need to match the whole field/line, there is still a
                    # chance that the patterns matches the whole field/line. Because
                    # a direct key lookup is very fast, it is better to check for
                    # this special condition first, before looking inside the current
                    # selected field for those patterns by looping over each pattern
                    # separately in a for loop.
                    if ( content in grep_pattern_array ) {
                        current_line_has_match = 1;

                        grep_pattern_string = content;
                    } else if ( match_whole_field == 0 ) {
                        # Patterns did not match whole field/line so search now in the
                        # selected field for a match with a pattern for each pattern
                        # separately.
                        for ( grep_pattern_key in grep_pattern_array ) {
                            # Pattern is interpreted as normal text and needs to be in
                            # the current field/line.
                            if ( index(content, grep_pattern_key) != 0 ) {
                                current_line_has_match = 1;

                                grep_pattern_string = grep_pattern_key;

                                # Go out of the grep_pattern_array for loop, so no
                                # useless iterations are done.
                                break;
                            }
                        }
                    }
                } else {
                    # regex = 1:
                    # ----------
                    #
                    # If the patterns needs to be interpreted as a regular expression,
                    # loop over each pattern separately in a for loop.
                    for ( grep_pattern_key in grep_pattern_array ) {
                        # Threat pattern as as a regular expression.
                        if ( match(content, grep_pattern_key) != 0 ) {
                            current_line_has_match = 1;

                            grep_pattern_string = grep_pattern_key;

                            # Go out of the grep_pattern_array for loop, so no useless
                            # iterations are done.
                            break;
                        }
                    }
                }

                # Print the current line:
                #   - if "-v" option was not used and if a match was found:
                #       * invert_match = 0
                #       * current_line_has_match = 1
                #   - if "-v" option was used and if no match was found:
                #       * invert_match = 1
                #       * current_line_has_match = 0
                if ( ( invert_match == 0 && current_line_has_match == 1 ) \
                     || ( invert_match == 1 && current_line_has_match == 0 ) ) {

                    if ( append_grep_patterns_file_content == 1 ) {
                        # Print the current input line and the full grep pattern line when "-a" is set.
                        print $0 FS grep_pattern_full_line_array[grep_pattern_string];
                    } else {
                        # Print the current input line.
                        print $0;
                    }

                    # Save the last printed line number, to prevent printing the same
                    # line more than once.
                    last_printed_linenumber = NR;

                    # Go out of the field_numbers_array for loop and read the next line,
                    # when we already printed the current line as there is no need to
                    # check if there is another match in another field.
                    break;
                }
            }
    }' "${input_files[@]}";



# Return the exit code returned by the awk command.
exit $?;

