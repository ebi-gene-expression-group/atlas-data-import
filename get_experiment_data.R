#!/usr/bin/env Rscript 

# Extract data from SCXA by experiment ID

suppressPackageStartupMessages(require(optparse))
suppressPackageStartupMessages(require(workflowscriptscommon))
suppressPackageStartupMessages(require(R.utils))
suppressPackageStartupMessages(require(yaml))
suppressPackageStartupMessages(require(RCurl))


option_list = list(
    make_option(
        c("-a", "--accesssion-code"),
        action = "store",
        default = NA,
        type = 'character',
        help = "Accession code of the data set to be extracted"
    ),
    make_option(
        c("-f", "--config-file"),
        action = "store",
        default = NA,
        type = 'character',
        help = "Config file in .yaml format"
    ),
    make_option(
        c("-d", "--matrix-type"),
        action = "store",
        default = NA,
        type = 'character',
        help = "Type of expression data to download. Must be one of 'raw', 'filtered', 'TPM' or 'CPM'"
    ),
    make_option(
        c("-c", "--decorated-rows"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should the decorated version of row names be downloaded? Deafult: FALSE"
    ),
    make_option(
        c("-o", "--output-dir-name"),
        action = "store",
        default = NA,
        type = 'character',
        help = "Name of the output directory containing study data. Default directory name is the provided accession code"
    ),
    make_option(
        c("-x", "--use-default-expr-names"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should default (non 10x-type) file names be used for expression data? Default: FALSE"
    ),
    make_option(
        c("-t", "--exp-data-dir"),
        action = "store",
        default = '10x_data',
        type = 'character',
        help = "Output name for expression data directory"
    ),
    make_option(
        c("-m", "--get-sdrf"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should SDRF file(s) be downloaded? Default: FALSE"
    ),
    make_option(
        c("-k", "--get-condensed-sdrf"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should condensed SDRF file(s) be downloaded? Default: FALSE"
    ),
    make_option(
        c("-i", "--get-idf"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should IDF file(s) be downloaded? Default: FALSE"
    ),
    make_option(
        c("-r", "--get-marker-genes"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should marker gene file(s) be downloaded? Default: FALSE"
    ), 
    make_option(
        c("-g", "--number-of-clusters"),
        action = "store",
        default = NA,
        type = 'integer',
        help = "Number of clusters for marker gene file"
    ),
    make_option(
        c("-u", "--use-full-names"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should non-expression data files be named with full file names? Default: FALSE"
    )
)

opt = wsc_parse_args(option_list, mandatory = c("accesssion_code", "matrix_type"))
acc = opt$accesssion_code
matrix_type = toupper(opt$matrix_type)

# source default config file
script_dir = dirname(strsplit(commandArgs()[grep('--file=', commandArgs())], '=')[[1]][2])
default_config = yaml.load_file(paste(script_dir, "config.yaml", sep="/"))

# check expression data type
if(!matrix_type %in% c("RAW", "FILTERED", "CPM", "TPM")){
    stop(paste("Incorrect argument provided for expr-data-type:", matrix_type))
}

# build output dir path
if(!is.na(opt$output_dir_name)){
    output_dir = opt$output_dir_name
} else {
    output_dir = paste(acc, matrix_type, sep="_")
}
dir.create(output_dir, showWarnings = FALSE)

# build generic url prefix
if(!is.na(opt$config_file)){
    config = yaml.load_file(opt$config_file)
    scxa_prefix = config$scxa_prefix
    if(!url.exists(scxa_prefix)){
        stop("Incorrect 'scxa_prefix' parameter provided in config file. Page does not exist")
    }
} else {
    scxa_prefix = default_config$scxa_experiments_prefix
}

# construct download link depending on matrix type 
url_prefix = paste(scxa_prefix, acc, acc, sep="/")
if(matrix_type == "RAW"){
    expr_prefix = paste(url_prefix, "aggregated_counts", sep=".")
} else if(matrix_type == "FILTERED"){
    expr_prefix = paste(url_prefix, "aggregated_filtered_counts", sep=".")
} else if(matrix_type == "CPM"){
    expr_prefix = paste(url_prefix, "aggregated_filtered_normalised_counts", sep=".")
} else if(matrix_type == "TPM"){
    expr_prefix = paste(url_prefix, "expression_tpm", sep=".")
}


# download expression data
if(opt$decorated_rows){
    rows = "decorated.mtx_rows"
} else{
    rows = "mtx_rows.gz"
}
expr_data = c("mtx.gz", "mtx_cols.gz", rows)
file_names = c("matrix.mtx", "barcodes.tsv", "genes.tsv")
dir.create(paste(output_dir, opt$exp_data_dir, sep="/"), showWarnings = FALSE)
for(idx in seq_along(expr_data)){
    url = paste(expr_prefix, expr_data[idx], sep=".")
    out_path = paste(output_dir, opt$exp_data_dir, basename(url), sep="/")
    download.file(url=url, destfile=out_path)
    if(!file.exists(out_path)) stop(paste("File", out_path, "failed to be downloaded"))
    # decompress files 
    if(summary(file(out_path))$class == 'gzfile'){
        gunzip(out_path, overwrite = TRUE, remove = TRUE)
        out_path = sub(".gz", "", out_path)
    }
    # rename files if necessary
    if(!opt$use_default_expr_names){
        base_name = file_names[idx]
        upd_out_path = sub(basename(out_path), base_name, out_path)
        file.rename(out_path, upd_out_path)
    }
}

# download metadata & marker files, if specified
non_expr_files = c(opt$get_sdrf, opt$get_condensed_sdrf, opt$get_idf, opt$get_marker_genes)

# build file names 
if(opt$get_marker_genes & !is.na(opt$number_of_clusters)){
    markers = paste("marker_genes_", opt$number_of_clusters, ".tsv", sep="")
    multiple_markers = FALSE
} else {
    markers = "marker_genes_*"
    multiple_markers = TRUE
}

names = c("sdrf.txt", "condensed-sdrf.tsv", "idf.txt", markers) 
for(idx in seq_along(non_expr_files)){
    if(non_expr_files[idx]){
        url = paste(url_prefix, names[idx], sep=".")
        i = paste(output_dir, basename(url), sep="/")
        system(paste("wget", url, "-P", output_dir))
        if(!file.exists(i)) stop(paste("File", i, "does not exist"))
        # do not rename if multiple marker files downloaded
        if(!opt$use_full_names & !(idx==4 & multiple_markers)){
            o = paste(output_dir, names[idx], sep="/")
            file.rename(i, o)
        }
    }
}
