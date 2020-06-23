#!/usr/bin/env Rscript 

# Import pre-trained classifiers for a provided list of datasets

suppressPackageStartupMessages(require(optparse))
suppressPackageStartupMessages(require(workflowscriptscommon))

option_list = list(
    make_option(
            c("-f", "--config-file"),
            action = "store",
            default = NA,
            type = 'character',
            help = "Config file in .yaml format"
        ),
    make_option(
            c("-t", "--tool"),
            action = "store",
            default = NA,
            type = 'character',
            help = "Which tool's classifiers should be imported?"
        ),
    make_option(
            c("-c", "--classifiers-output-dir"),
            action = "store_true",
            default = "imported_classifiers",
            type = 'character',
            help = "Path for directory storing imported classifiers"
    ),
    make_option(
            c("-s", "--get-sdrf"),
            action = "store_true",
            default = FALSE,
            type = 'logical',
            help = "Should SDRF file(s) be downloaded? Default: FALSE"
    ),
    make_option(
            c("-k", "--condensed-sdrf"),
            action = "store_true",
            default = FALSE,
            type = 'logical',
            help = "If --get-sdrf is set to TRUE, import condensed SDRF? By default, a normal version is imported. Default: FALSE"
    ),
    make_option(
            c("-d", "--sdrf-output-dir"),
            action = "store",
            default = "imported_SDRFs",
            type = 'character',
            help = "Output path for imported SDRF files directory"
    )
)

opt = wsc_parse_args(option_list, mandatory = c("tool"))
# import dependencies
suppressPackageStartupMessages(require(R.utils))
suppressPackageStartupMessages(require(RCurl))
suppressPackageStartupMessages(require(yaml))

classifier_out_dir = opt$classifiers_output_dir
tool = tolower(paste(opt$tool, "rds", sep="."))

# source default config file
script_dir = dirname(strsplit(commandArgs()[grep('--file=', commandArgs())], '=')[[1]][2])
default_config = yaml.load_file(paste(script_dir, "config.yaml", sep="/"))

# parse config file or use default values
if(!is.na(opt$config_file)){
    config = yaml.load_file(opt$config_file)
    datasets = toupper(config$datasets)
    scxa_classifiers_prefix = sub("/$", "", config$scxa_classifiers_prefix)
    scxa_experiments_prefix = sub("/$", "", config$scxa_experiments_prefix)
} else {
    scxa_classifiers_prefix = default_config$scxa_classifiers_prefix
    scxa_experiments_prefix = default_config$scxa_experiments_prefix
    datasets = system(paste("curl -l ", scxa_classifiers_prefix, "/", sep=""), intern=TRUE)
}

# create import directory
if(!dir.exists(classifier_out_dir)){
    dir.create(classifier_out_dir)
}

# download classifiers from specified datasets
for(dataset in datasets){
    out_file = paste(dataset, tool, sep="_")
    link = paste(scxa_classifiers_prefix, dataset, out_file, sep="/")
    download.file(link, destfile=paste(classifier_out_dir, out_file, sep="/"))
}

# import SDRF files, if specified
if(opt$get_sdrf){
    # build a link for sdrf files
    if(opt$condensed_sdrf){
        sdrf_file = default_config$condensed_sdrf
    } else {
        sdrf_file = default_config$sdrf
    }
    # create import directory
    sdrf_out_dir = opt$sdrf_output_dir
    if(!dir.exists(sdrf_out_dir)){
        dir.create(sdrf_out_dir)
    }
    # for each dataset, retrieve corresponding sdrf file
    for(dataset in datasets){
        file_name = paste(dataset, sdrf_file, sep=".")
        prefix = paste(scxa_experiments_prefix, dataset, sep="/")
        download_path = paste(prefix, file_name, sep="/")
        download.file(download_path, destfile = paste(sdrf_out_dir, file_name,sep="/"))
    }
}

