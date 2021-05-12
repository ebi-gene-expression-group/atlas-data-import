#!/usr/bin/env Rscript 

# Extract data from SCXA by experiment ID

suppressPackageStartupMessages(require(optparse))
suppressPackageStartupMessages(require(workflowscriptscommon))

option_list = list(
    make_option(
        c("-a", "--accession-code"),
        action = "store",
        default = NA,
        type = 'character',
        help = "Accession code of the data set to be extracted."
    ),
    make_option(
        c("-e", "--get-expression-data"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should expression data be downloaded? Default: False."
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
        c("-z", "--get-exp-design"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should experimental design file be downloaded? Default: FALSE"
    ),
    make_option(
        c("-r", "--get-marker-genes"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should marker gene file(s) be downloaded? Default: FALSE"
    ), 
    make_option(
        c("-g", "--markers-cell-grouping"),
        action = "store",
        default = "inferred_cell_type_-_ontology_labels",
        type = 'character',
        help = "What type of cell grouping is used for marker gene file? By default, markers 
                for inferred cell types are downloaded. If supplying an integer value, 
                an automatically-derived marker gene file for a corresponding number of clusters
                will be imported."
    ),
    make_option(
        c("-u", "--use-full-names"),
        action = "store_true",
        default = FALSE,
        type = 'logical',
        help = "Should non-expression data files be named with full file names? Default: FALSE"
    ), 
    make_option(
        c("--experiments-prefix"),
        action = "store",
        default = "http://ftp.ebi.ac.uk/pub/databases/microarray/data/atlas/sc_experiments",
        type = 'character',
        help = "URL prefix for scxa experiments."
    )
)

opt = wsc_parse_args(option_list, mandatory = c("accession_code", "matrix_type"))

suppressPackageStartupMessages(require(R.utils))
suppressPackageStartupMessages(require(RCurl))

acc = opt$accession_code
matrix_type = toupper(opt$matrix_type)

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

# generic url prefix
scxa_prefix = opt$experiments_prefix

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

# Wrap download.file for retries and error checking
download.file.with.retries <- function(link, dest, sleep_time=30, max_retries=5){
    stat <- 1
    retries <- 0

    print(paste("Downloading", link))
    while( stat != 0 && retries < max_retries){
        if (retries > 0){
            Sys.sleep(sleep_time)
        }    
        tryCatch({
            stat <- download.file(link, destfile=dest)
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

# download expression data
if(opt$decorated_rows){
    rows = "decorated.mtx_rows"
} else{
    rows = "mtx_rows.gz"
}

if(opt$get_expression_data){
    expr_data = c("mtx.gz", "mtx_cols.gz", rows)
    file_names = c("matrix.mtx", "barcodes.tsv", "genes.tsv")
    dir.create(paste(output_dir, opt$exp_data_dir, sep="/"), showWarnings = FALSE)
    for(idx in seq_along(expr_data)){
        url = paste(expr_prefix, expr_data[idx], sep=".")
        out_path = paste(output_dir, opt$exp_data_dir, basename(url), sep="/")
        download.file.with.retries(url, dest=out_path)
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
}

# download metadata & marker files, if specified
non_expr_files = c("sdrf"=opt$get_sdrf, "cond_sdrf"=opt$get_condensed_sdrf, 
                "idf"=opt$get_idf, "marker_genes"=opt$get_marker_genes, 
                "exp_design"=opt$get_exp_design)

# build file names array
markers = paste("marker_genes_", opt$markers_cell_grouping, ".tsv", sep="")
metadata_names = c("sdrf.txt", "condensed-sdrf.tsv", "idf.txt", markers, 
          paste("https://www.ebi.ac.uk/gxa/sc/experiment", acc, 
          "download?fileType=experiment-design&accessKey=",sep="/"))

for(idx in seq_along(non_expr_files)){
    get_curr_file = non_expr_files[idx]
    if(get_curr_file){
        if(names(non_expr_files[idx]) == "exp_design"){
            url = metadata_names[idx]
            download.file.with.retries(url, dest=paste(output_dir, "exp_design.tsv",sep="/"))
        }else{
            url = paste(url_prefix, metadata_names[idx], sep=".")
            dest_file = paste(output_dir, basename(url), sep="/")
            download.file.with.retries(url, dest=dest_file)
            if(!file.exists(dest_file)) stop(paste("File", dest_file, "does not exist"))
            # do not rename if use_full_names specified
            if(!opt$use_full_names){
                o = paste(output_dir, metadata_names[idx], sep="/")
                file.rename(dest_file, o)
            }
        }
    }
}
