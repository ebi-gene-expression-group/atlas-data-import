#!/usr/bin/env Rscript 

### Import SDRF files for the downloaded classifiers
### By default, SDRF files for all available datasets that have trained classifiers are obtained
### Alternatively, necessary datasets can be provided through a config file

option_list = list(
    make_option(
            c("-f", "--config-file"),
            action = "store",
            default = NA,
            type = 'character',
            help = "Config file in .yaml format"
    ),
    make_option(
            c("-k", "--get-condensed-sdrf"),
            action = "store_true",
            default = FALSE,
            type = 'logical',
            help = "Should condensed SDRF file(s) be downloaded? Default: FALSE"
    ),
    make_option(
            c("-s", "--sdrf-output-dir"),
            action = "store_true",
            default = NA,
            type = 'character',
            help = "Output path for imported SDRF files directory"
    )
)
opt = wsc_parse_args(option_list, mandatory = c("tool", "classifiers_output_dir"))
# import dependencies 
suppressPackageStartupMessages(require(optparse))
suppressPackageStartupMessages(require(workflowscriptscommon))
suppressPackageStartupMessages(require(R.utils))
suppressPackageStartupMessages(require(yaml))
suppressPackageStartupMessages(require(RCurl))

# parse config file or use default values
if(!is.na(opt$config_file)){
    config = yaml.load_file(opt$config_file)
    datasets = toupper(config$datasets)
    scxa_experiments_prefix = config$scxa_experiments_prefix
    if(!endsWith(scxa_experiments_prefix, "/")) scxa_experiments_prefix = paste(scxa_experiments_prefix, "/", sep="")
} else {
    scxa_experiments_prefix = "ftp://ftp.ebi.ac.uk/pub/databases/microarray/data/atlas/sc_experiments/"
    scxa_classifiers_prefix = "ftp://ftp.ebi.ac.uk/pub/databases/microarray/data/atlas/classifiers/"
    datasets = system(paste("curl -l", scxa_classifiers_prefix), intern=TRUE)
}

# build a link for sdrf files
if(opt$get_condensed_sdrf){
    sdrf_file = "condensed-sdrf.tsv"
} else {
    sdrf_file = "sdrf.txt"
}

# create import directory
out_dir = opt$sdrf_output_dir
if(!dir.exists(out_dir)){
    dir.create(out_dir)
}

# for each dataset, retrieve corresponding sdrf file
for(dataset in datasets){
    file_name = paste(dataset, sdrf_file, sep=".")
    prefix = paste(scxa_experiments_prefix, dataset, sep="")
    download_path = paste(prefix, file_name, sep="/")
    download.file(download_path, destfile = paste(out_dir, file_name))
}
