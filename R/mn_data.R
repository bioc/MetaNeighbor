#' @name mn_data
#' @title mn_data
#'
#' @description A SummarizedExperiment object containing: a gene matrix,
#' cell type labels, experiment labels, sets of genes, sample ID, study id and
#' cell types.
#'
#' @docType data
#'
#' @format
#' \describe{
#'   \item{Gene matrix}{A gene-by-sample expression matrix consisting of 3157
#'   rows (genes) and 1051 columns (cell types)}
#'   \item{cell_labels}{1051x1 binary matrix that indicates whether a cell
#'   belongs to the SstNos cell type (1=yes, 0 = no)}
#'   \item{sample_id}{A character vector of length 1051 that indicates the
#'   sample_id of each sample}
#'   \item{study_id}{A character vector of length 1051 that indicates the
#'   study_id of each sample ("GSE60361" = Zeisel et al, "GSE71585" = Tasic et 
#'   al)}
#'   \item{cell_type}{A character vector of length 1051 that indicates the
#'   cell-type of each sample}
#'   \item{genesets}{List containing gene symbols for 10 GO function (GO:0016853
#'   , GO:0005615, GO:0005768, GO:0007067, GO:0065003, GO:0042592, GO:0005929,
#'   GO:0008565, GO:0016829, GO:0022857) downloaded from the Gene Ontology
#'   Consortuum August 2015 \url{http://www.geneontology.org/}}
#' }
#'
#' @source Dataset:\url{https://github.com/mm-shah/MetaNeighbor/tree/master/data} 1. Zeisal et al. \url{http://science.sciencemag.org/content/347/6226/1138}
#' 2. Tasic et al. \url{http://www.nature.com/neuro/journal/v19/n2/full/nn.4216.html}
#' @rdname mn_data

"mn_data"