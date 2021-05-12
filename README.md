# atlas-data-import
Scripts for extracting expression- and metadata from SCXA in a programmatic way. 

### Installation 
Package is installed via conda. To avoid dependency conflicts, it is recommended to install into fresh environment:

```
conda create -n <env_name>
conda activate <env_name>
conda install -c bioconda atlas-data-import
```

### Obtain study data from Single Cell Expression Atlas 
```
get_experiment_data.R\
            --accession-code <accession code of the dataset to be extracted>\
            --get-expression-data <should expression data be imported?>\
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
            --use-full-names <should non-expression data files be named with full file names? Default: FALSE>\
            --experiments-prefix <URL prefix for scxa experiments>

```

### Import pre-trained classifiers and SDRF files for a range of studies
User can provide a yaml-formatted config file (see [example](example_user_config.yaml)) with specific datasets for which to import classifiers. Otherwise, all available classifiers of a given type are imported. 
```
import_classification_data.R\
            --accession-code <comma-separated string of datasets for which to extract the classifiers>\
            --tool <which tool's classifiers should be imported>\
            --classifiers-output-dir <output directory for downloaded classifiers>\
            --get-sdrf <should SDRF file(s) be downloaded?>\
            --condensed-sdrf <if --get-sdrf is set to TRUE, import condensed SDRF? by default, a normal version is imported>\
            --sdrf-output-dir <output path for imported SDRF files directory>\
            --get-tool-perf-table <should tool performance table be imported?>\
            --tool-perf-table-output-path <output path for tool performance table>
```
