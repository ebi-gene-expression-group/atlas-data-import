#!/usr/bin/env bats

@test "download data" {
    if [ "$use_existing_outputs" = 'true' ]; then
        skip "use_existing_outputs is set to 'true'"
    fi

    run rm -rf $output_dir_name'/*' && get_experiment_data.R\
                                        --accession-code $study_accession_1\
                                        --get-expression-data\
                                        --matrix-type $matrix_type\
                                        --output-dir-name $output_dir_name\
                                        --get-sdrf\
                                        --get-condensed-sdrf\
                                        --get-idf\
                                        --get-exp-design\
                                        --get-marker-genes
     echo "status = ${status}"
     echo "output = ${output}"
     [ "$status" -eq 0 ]
}

@test "import classification data" {
    if [ "$use_existing_outputs" = 'true' ]; then
        skip "use_existing_outputs is set to 'true'"
    fi

    run rm -rf $classifiers_output_dir && import_classification_data.R\
                                            --accession-code "$study_accession_1,$study_accession_2"\
                                            --tool $tool\
                                            --classifiers-output-dir $classifiers_output_dir\
                                            --get-sdrf\
                                            --condensed-sdrf\
                                            --get-tool-perf-table\
                                            --sdrf-output-dir $sdrf_output_dir 

    echo "status = ${status}"
    echo "output = ${output}"
    [ "$status" -eq 0 ]
}
