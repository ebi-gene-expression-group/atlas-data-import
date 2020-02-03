#!/usr/bin/env Rscript 

# Extract data from SCXA by experiment ID

suppressPackageStartupMessages(require(optparse))
suppressPackageStartupMessages(require(workflowscriptscommon))
suppressPackageStartupMessages(require(R.utils))


option_list = list(
    make_option(
        c("-a", "--accesssion-code"),
        action = "store",
        default = NA,
        type = 'character',
        help = "Accession code of the data set to be extracted"
    ),
    make_option(
        c("-d", "--expr-data-type"),
        action = "store",
        default = NA,
        type = 'character',
        help = "Type of expression data to download. Must be one of 'raw', 'filtered', 'normalised'"
    ),
    make_option(
        c("-n", "--normalisation-method"),
        action = "store_true",
        default = NA,
        type = 'character',
        help = "Normalisation method ('TPM' or 'CPM'). Needs to be specified if --expr-data-type is set to 'normalised'"
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
        c("-x", "--use-default-names"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should default (non 10x-type) file names be used? Default: TRUE"
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
    )
)

opt = wsc_parse_args(option_list, mandatory = c("accesssion_code", "expr_data_type"))
acc = opt$accesssion_code
data_type = toupper(opt$expr_data_type)
norm_method = toupper(opt$normalisation_method)

# check expression data type
if(!data_type %in% c("RAW", "FILTERED", "NORMALISED")){
    stop(paste("Incorrect argument provided for expr-data-type:", data_type))
}
# check normalisation method
if(data_type == "NORMALISED" & !norm_method %in% c("CPM", "TPM")){
    stop(paste("Empty or incorrect argument provided for normalisation-method:", norm_method))
}

# build output dir path
if(!is.na(opt$output_dir_name)){
    output_dir = opt$output_dir_name
} else {
    output_dir = paste(acc, data_type, sep="_")
    if(!is.na(norm_method)){
        output_dir = paste(output_dir, norm_method, sep="_")
    }
}
dir.create(output_dir)
# build generic url prefix
url_prefix = paste("ftp://ftp.ebi.ac.uk/pub/databases/microarray/data/atlas/sc_experiments", acc, acc, sep="/")
if(data_type == "RAW"){
    expr_prefix = paste(url_prefix, "aggregated_counts", sep=".")
} else if(data_type == "FILTERED"){
    expr_prefix = paste(url_prefix, "aggregated_filtered_counts", sep=".")
} else if(data_type == "NORMALISED"){
    if(norm_method == "CPM"){
        expr_prefix = paste(url_prefix, "aggregated_filtered_normalised_counts", sep=".")
    } else{
        expr_prefix = paste(url_prefix, "expression_tpm", sep=".")
    }
}

# download expression data
if(opt$decorated_rows){
    rows = "decorated.mtx_rows"
} else{
    rows = "mtx_rows.gz"
}
expr_data = c("mtx.gz", "mtx_cols.gz", rows)
file_names = c("matrix.mtx", "barcodes.tsv", "genes.tsv")
dir.create(paste(output_dir, opt$exp_data_dir, sep="/"))
for(idx in seq_along(expr_data)){
    url = paste(expr_prefix, expr_data[idx], sep=".")
    base_name = basename(url)
    out_path = paste(output_dir, opt$exp_data_dir, base_name, sep="/")
    download.file(url=url, destfile=out_path)
    if(!file.exists(out_path)){
        stop(paste0("Failed to download file:", url))
    }
    # decompress files 
    if(summary(file(out_path))$class == 'gzfile'){
        gunzip(out_path, overwrite = TRUE, remove = TRUE)
        out_path = sub(".gz", "", out_path)
    }
    # rename files if necessary
    if(!opt$use_default_names){
        base_name = file_names[idx]
        upd_out_path = sub(basename(out_path), base_name, out_path)
        file.rename(out_path, upd_out_path)
    }
}

# download metadata & marker files, if specified
non_expr_files = c(opt$get_sdrf, opt$get_idf, opt$get_marker_genes)
names = c("*sdrf.t*", "idf.txt", "marker_genes_*") 
for(idx in seq_along(non_expr_files)){
    if(non_expr_files[idx]){
        url = paste(url_prefix, names[idx], sep=".")
        system(paste("wget", url, "-P", output_dir))
    }
}
