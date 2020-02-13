#!/usr/bin/env bats

@test "download data" {
    if [ "$use_existing_outputs" = 'true' ]; then
        skip "use_existing_outputs is set to 'true'"
    fi

    run rm -rf output_dir_name'/*' && get_experiment_data.R\
                                        --accesssion-code $study_accession_num\
                                        --expr-data-type $expr_data_type\
                                        --normalisation-method $normalisation_method\
                                        --output-dir-name $output_dir_name\
                                        --get-sdrf\
                                        --get-condensed-sdrf\
                                        --get-idf\
                                        --get-marker-genes\
                                        --number-of-clusters $num_clusters
     echo "status = ${status}"
     echo "output = ${output}"
     [ "$status" -eq 0 ]
}