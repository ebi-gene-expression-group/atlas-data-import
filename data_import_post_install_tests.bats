#!/usr/bin/env bats

@test "download data" {
    if [ "$use_existing_outputs" = 'true' ]; then
        skip "use_existing_outputs is set to 'true'"
    fi

    run rm -rf $output_dir_name'/*' && get_experiment_data.R\
                                        --accesssion-code $study_accession_num\
                                        --matrix-type $matrix_type\
                                        --config-file $user_config_file\
                                        --output-dir-name $output_dir_name\
                                        --get-sdrf\
                                        --get-condensed-sdrf\
                                        --get-idf\
                                        --get-exp-design\
                                        --get-marker-genes\
                                        --number-of-clusters $num_clusters
     echo "status = ${status}"
     echo "output = ${output}"
     [ "$status" -eq 0 ]
}

@test "import classification data" {
    if [ "$use_existing_outputs" = 'true' ]; then
        skip "use_existing_outputs is set to 'true'"
    fi

    run rm -rf $classifiers_output_dir && import_classification_data.R\
                                            --config-file $user_config_file\
                                            --tool $tool\
                                            --classifiers-output-dir $classifiers_output_dir\
                                            --get-sdrf\
                                            --condensed-sdrf\
                                            --get-tool-perf-table\
                                            --tool-perf-table-output-path $tool_perf_table_output_path\
                                            --sdrf-output-dir $sdrf_output_dir 

    echo "status = ${status}"
    echo "output = ${output}"
    [ "$status" -eq 0 ]
}
