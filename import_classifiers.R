#!/usr/bin/env Rscript 

# Import pre-trained classifiers for a provided list of datasets

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
            default = NA,
            type = 'character',
            help = "Path for directory storing imported classifiers"
    )
)

opt = wsc_parse_args(option_list, mandatory = c("tool", "classifiers_output_dir"))
# import dependencies
suppressPackageStartupMessages(require(optparse))
suppressPackageStartupMessages(require(workflowscriptscommon))
suppressPackageStartupMessages(require(R.utils))
suppressPackageStartupMessages(require(yaml))
suppressPackageStartupMessages(require(RCurl))

out_dir = opt$classifiers_output_dir
tool = paste(opt$tool, "classifier.rds", sep="_")

# parse config file or use default values
if(!is.na(opt$config_file)){
    config = yaml.load_file(opt$config_file)
    datasets = toupper(config$datasets)
    scxa_classifiers_prefix = config$scxa_classifiers_prefix
    if(!endsWith(scxa_classifiers_prefix, "/")) scxa_classifiers_prefix = paste(scxa_classifiers_prefix, "/", sep="")
} else {
    scxa_classifiers_prefix = "ftp://ftp.ebi.ac.uk/pub/databases/microarray/data/atlas/classifiers/"
    datasets = system(paste("curl -l", scxa_classifiers_prefix), intern=TRUE)
}

# create import directory
if(!dir.exists(out_dir)){
    dir.create(out_dir)
}

# download classifiers from specified datasets
for(dataset in datasets){
    out_file = paste(dataset, tool, sep="_")
    link = paste(scxa_classifiers_prefix, dataset, out_file, sep="/")
    download.file(link, destfile=paste(out_dir, out_file, sep="/"))
}
