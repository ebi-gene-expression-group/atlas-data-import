#!/usr/bin/env bash 

script_name=$0
# Initialise directories
test_dir=`pwd`/post_install_tests
mkdir -p $test_dir

# update path variable
export PATH=`pwd`:$PATH

function usage {
    echo "usage: garnett_cli_post_install_tests.sh [action] [use_existing_outputs]"
    echo "  - action: what action to take, 'test' or 'clean'"
    echo "  - use_existing_outputs, 'true' or 'false'"
    exit 1
}

action=${1:-'test'}
use_existing_outputs=${2:-'false'}

if [ "$action" != 'test' ] && [ "$action" != 'clean' ]; then
    echo "Invalid action"
    usage
fi

if [ "$use_existing_outputs" != 'true' ] &&\
   [ "$use_existing_outputs" != 'false' ]; then
    echo "Invalid value ($use_existing_outputs) for 'use_existing_outputs'"
    usage
fi

# Clean up if specified
if [ "$action" = 'clean' ]; then
    echo "Cleaning up $output_dir ..."
    rm -rf $output_dir

    exit 0
fi 

################################################################################
# List tool outputs/ inputs
################################################################################
export study_accession_1="E-MTAB-6912"
export study_accession_2="E-MTAB-6925"
export species="mus_musculus"
export matrix_type="cpm"
export output_dir_name=$test_dir/$study_accession_num
export classifiers_output_dir=$test_dir/"imported_classifiers"
export tool="scpred"
export sdrf_output_dir=$test_dir/"sdrf_files"
export tool_perf_table_output_path=$test_dir/"tool_perf_pvals.tsv"

################################################################################
# Test individual scripts
################################################################################

export use_existing_outputs
tests_file="${script_name%.*}".bats
# Execute tests
$tests_file
