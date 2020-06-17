# atlas-data-import
Scripts for extracting expression- and metadata from SCXA in a programmatic way. 

### Installation 
Package is installed via conda. To avoid dependency conflicts, it is recommended to install into fresh environment:

```
conda create -n <env_name>
conda activate <env_name>
conda install -c ebi-gene-expression-group atlas-data-import
```

### Obtain study data from Single Cell Expression Atlas 
```
get_experiment_data.R\
            --accesssion-code <accession code of the data set to be extracted>\
            --config-file <path to config file in .yaml format>\
            --matrix-type <type of expression data to download>\
            --decorated-rows <boolean; use decorated row names?>\
            --output-dir-name <name of the output directory>\
            --use-default-names <should default names be used?>\
            --exp-data-dir <name for expression data directory>\
            --get-sdrf <boolean; should SDRF files be imported?>\
            --get-condensed-sdrf <boolean; should condensed SDRF be imported?>\
            --get-idf <boolean; should IDF files be imported?>\
            --get-marker-genes <boolean; should marker genes be imported?>\
            --number-of-clusters <number of clusters for marker gene file>\
            --use-full-names <should non-expression data files be named with full file names? Default: FALSE>

```

### Import pre-trained classifiers for a range of studies
User can provide a yaml-formatted config file (see [example](example_user_config.yaml)) with specific datasets for which to import classifiers. Otherwise, all available classifiers of a given type are imported. 

import_classifiers.R\
            --config-file <path to user-provided config file>\
            --tool <for which tool should the classifiers be imported>/
            --classifiers-output-dir <output directory for downloaded classifiers>

### Import SDRF files for a range of studies
import_sdrf_files.R\
            --config-file <path to user-provided config file>\
            --get-condensed-sdrf <should condensed sdrf files be imported?>\
            --sdrf-output-dir <path to the output directory>





