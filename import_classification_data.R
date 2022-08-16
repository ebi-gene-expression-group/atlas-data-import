#!/usr/bin/env Rscript 

# Import pre-trained classifiers for a provided list of datasets

suppressPackageStartupMessages(require(optparse))
suppressPackageStartupMessages(require(workflowscriptscommon))

option_list = list(
    make_option(
            c("-a", "--accession-code"),
            action = "store",
            default = NA,
            type = 'character',
            help = "One or more dataset accession codes of the data set for which 
                    to download the classifiers. By default, all classifiers are downloaded 
                    for a given dataset."
    ),
    make_option(
            c("-t", "--tool"),
            action = "store",
            default = NA,
            type = 'character',
            help = "Which tool's classifiers should be imported?"
        ),
    make_option(
            c("-e", "--species"),
            action = "store",
            default = NA,
            type = 'character',
            help = "Which species' classifiers should be imported?"
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
    ),
    make_option(
            c("-p", "--get-tool-perf-table"),
            action = "store_true",
            default = FALSE,
            type = 'logical',
            help = "Should the tool performance table be imported? Default: FALSE"
    ), 
    make_option(
            c("--tool-perf-table-url"),
            action = "store",
            default = "http://ftp.ebi.ac.uk/pub/databases/microarray/data/atlas/cell-types-project-test-data/data_1/tool_perf_pvals.tsv",
            type = 'character',
            help = "URL for import of tool performance table"
    ), 
    make_option(
            c("--classifiers-prefix"),
            action = "store",
            default = "http://ftp.ebi.ac.uk/pub/databases/microarray/data/atlas/sc_experiments_classifiers",
            type = 'character',
            help = "URL prefix for imported classifiers."
    ),
    make_option(
            c("--experiments-prefix"),
            action = "store",
            default = "http://ftp.ebi.ac.uk/pub/databases/microarray/data/atlas/sc_experiments",
            type = 'character',
            help = "URL prefix for imported experiment data."
    )
)

opt = wsc_parse_args(option_list, mandatory = c("tool", "species"))
suppressPackageStartupMessages(require(R.utils))
suppressPackageStartupMessages(require(RCurl))

tool_perf_table = opt$tool_perf_table_url
scxa_classifiers_prefix = sub("/$", "", opt$classifiers_prefix)
scxa_experiments_prefix = sub("/$", "", opt$experiments_prefix)

# subset by species
scxa_classifiers_prefix = paste(scxa_classifiers_prefix, opt$species, sep="/")

if(!is.na(opt$accession_code)){
    datasets = toupper(wsc_split_string(opt$accession_code))
} else {
    # by default, import all available classifiers
    scxa_classifiers_prefix_ftp = sub("http", "ftp", scxa_classifiers_prefix)
    datasets = system(paste("curl -l ", scxa_classifiers_prefix_ftp, "/", sep=""), intern=TRUE)
}

classifier_out_dir = opt$classifiers_output_dir
tool_file = tolower(paste(opt$tool, "rds", sep="."))

# create import directory
if(!dir.exists(classifier_out_dir)){
    dir.create(classifier_out_dir)
}

# Wrap download.file for retries and error checking
download.file.with.retries <- function(link, dest, sleep_time=10, max_retries=5){
    retries <- 0
    url_exists = FALSE
    # allow for possible network problems when checking url 
    while( !url_exists && retries < max_retries){
        if (retries > 0){
            Sys.sleep(sleep_time)
        } 
        url_exists = url.exists(link)
        retries <- retries + 1
    }
    if(!url_exists){
        print(paste("File ", link, " does not exist. Skipping to next file." ))
        return()
    }
    print(paste("Downloading", link))
    stat <- 1
    retries <- 0 
    while( stat != 0 && retries < max_retries){
        if (retries > 0){
            Sys.sleep(sleep_time)
        } 
        tryCatch({
            stat <- download.file(link, destfile=dest, timeout=3600)
            },
            error = function(cond){
                print(cond)
                print("Download attempt failed. Retrying...")
            }
            )   
        retries <- retries + 1
    }
    if (stat != 0){
        write(paste("Unable to download", link, 'after', max_retries, 'retries'), stderr())
        quit(status=1)
    }
    print("... success")
}

# download classifiers from specified datasets
for(dataset in datasets){
    print(paste("Downloading classifier for tool", opt$tool, "trained on dataset:", dataset))
    out_file = paste(dataset, tool_file, sep="_")
    link = paste(scxa_classifiers_prefix, dataset, out_file, sep="/")
    download.file.with.retries(link, dest=paste(classifier_out_dir, out_file, sep="/"))
}

# import SDRF files, if specified
if(opt$get_sdrf){
    # build a link for sdrf files
    if(opt$condensed_sdrf){
        sdrf_file = "condensed-sdrf.tsv"
    } else {
        sdrf_file = "sdrf.tsv"
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
        download.file.with.retries(download_path, dest = paste(sdrf_out_dir, file_name,sep="/"))
    }
}

# import tool performance table, if specified
if(opt$get_tool_perf_table){
    download.file.with.retries(tool_perf_table, dest=basename(opt$tool_perf_table))
}
