#' Plots symmetric AUROC heatmap, clustering cell types by similarity.
#'
#' @param aurocs A square AUROC matrix as returned by MetaNeighborUS.
#' @param cex Size factor for row and column labels.
#' @param margins Size of margins (for row and column labels).
#' @param ... Additional graphical parameters that are passed on to
#'  gplots::heatmap.2 (allows customization of the heatmap).
#'
#' @examples
#' data(mn_data)
#' var_genes = variableGenes(dat = mn_data, exp_labels = mn_data$study_id)
#' celltype_NV = MetaNeighborUS(var_genes = var_genes,
#'                              dat = mn_data,
#'                              study_id = mn_data$study_id,
#'                              cell_type = mn_data$cell_type)
#' plotHeatmap(celltype_NV)
#'
#' @seealso \code{\link{ggPlotHeatmap}}
#' @export
#'
plotHeatmap <- function(aurocs, cex = 1, margins = c(8, 8), ...) {
    auroc_cols <- rev(grDevices::colorRampPalette(RColorBrewer::brewer.pal(11,"RdYlBu"))(100))
    breaks <- seq(0, 1, length=101)
    ordering <- stats::as.dendrogram(orderCellTypes(aurocs))
    
    arg_list <- list(
        x = aurocs, margins = margins,
        key = TRUE, keysize = 1, key.xlab="AUROC", key.title="NULL",
        offsetRow=0.1, offsetCol=0.1,
        trace = "none", density.info = "none",
        Rowv = ordering, Colv = ordering, 
        col = auroc_cols, breaks = breaks, na.color = grDevices::gray(0.95),
        cexRow = cex, cexCol = cex
    )
    additional_args <- list(...)
    arg_list[names(additional_args)] <- additional_args
    do.call(gplots::heatmap.2, arg_list)
}

#' Plots symmetric AUROC heatmap, clustering cell types by similarity.
#'
#' This function is a ggplot alternative to plotHeatmap (without the cell type
#' dendrogram).
#'
#' @param aurocs A square AUROC matrix as returned by MetaNeighborUS.
#' @param label_size Font size of cell type labels along the heatmap
#'  (default is 10).
#' @return A ggplot object.
#'
#' @seealso \code{\link{plotHeatmap}}
#' @export
#'
ggPlotHeatmap <- function(aurocs, label_size = 10) {
    ct_order <- labels(stats::as.dendrogram(orderCellTypes(aurocs)))
    `%>%` <- dplyr::`%>%`
    tidy_aurocs <- tibble::as_tibble(aurocs, rownames = "target_ct") %>%
        tidyr::pivot_longer(-target_ct,
                            names_to = "ref_ct",
                            values_to = "auroc") %>%
        dplyr::mutate(ref_ct = factor(ref_ct, ct_order)) %>%
        dplyr::mutate(target_ct = factor(target_ct, ct_order))
    result <- tidy_aurocs %>%
        ggplot2::ggplot(ggplot2::aes(x = ref_ct, y = target_ct, fill = auroc)) +
        ggplot2::geom_tile() +
        ggplot2::coord_fixed() +
        ggplot2::scale_fill_distiller(palette = "RdYlBu", limits=c(0,1), na.value = grDevices::gray(0.95)) +
        ggplot2::labs(x = NULL, y = NULL, fill = "AUROC") +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle = 90, hjust=1, vjust=0.5, size=label_size),
                       axis.text.y = ggplot2::element_text(size=label_size))
    return(result)
}

#' Order cell types based on AUROC similarity matrix.
#'
#' @param M A square AUROC matrix as returned by MetaNeighborUS.
#' @param na_value Replace NA values with this value (default is 0).
#' @return A hierarchical clustering object as returned by stats::hclust.
#'
#' @export
#'
orderCellTypes <- function(M, na_value = 0) {
    M <- (M + t(M))/2
    M[is.na(M)] <- na_value
    result <- stats::hclust(stats::as.dist(1-M), method = "average")
    return(result)
}

#' Plots rectangular AUROC heatmap, clustering train cell types (columns)
#' by similarity, and ordering test cell types (rows) according to similarity
#' to train cell types..
#'
#' @param aurocs A rectangular AUROC matrix as returned by MetaNeighborUS,
#  typically run with the trained_model option.
#' @param alpha_col Parameter controling column clustering: a higher value of
#' alpha_col gives more weight to extreme AUROC values (close to 1).
#' @param alpha_row Parameter controling row ordering: a higher value of
#' alpha_row gives more weight to extreme AUROC values (close to 1).
#' @param cex Size factor for row and column labels.
#' @param margins Size of margins (for row and column labels).
#'
#' @examples
#' data(mn_data)
#' var_genes = variableGenes(dat = mn_data, exp_labels = mn_data$study_id)
#' celltype_NV = MetaNeighborUS(var_genes = var_genes,
#'                              dat = mn_data,
#'                              study_id = mn_data$study_id,
#'                              cell_type = mn_data$cell_type,
#'                              symmetric_output = FALSE)
#' keep_col = getStudyId(colnames(celltype_NV)) == "GSE71585"
#' keep_row = getStudyId(rownames(celltype_NV)) != "GSE71585"
#' plotHeatmapPretrained(celltype_NV[keep_row, keep_col])
#'
#' @export
#'
plotHeatmapPretrained <- function(aurocs, alpha_col = 1, alpha_row = 10,
                                  cex = 1, margins = c(8,8)) {
    auroc_cols <- rev(grDevices::colorRampPalette(RColorBrewer::brewer.pal(11,"RdYlBu"))(100))
    breaks <- seq(0, 1, length=101)
    auroc_no_na <- aurocs
    auroc_no_na[is.na(aurocs)] <- 0
    col_order <- stats::as.dendrogram(
        stats::hclust(stats::dist(t(auroc_no_na)**alpha_col), method = "average")
    )
    row_order <- order_rows_according_to_cols(auroc_no_na[, labels(col_order)], alpha_row)
    aurocs <- aurocs[row_order,]

    gplots::heatmap.2(
        x = aurocs, margins = margins,
        key = TRUE, keysize = 1, key.xlab="AUROC", key.title="NULL",
        offsetRow=0.1, offsetCol=0.1,
        trace = "none", density.info = "none", dendrogram = "col",
        col = auroc_cols, breaks = breaks, na.color = grDevices::gray(0.95),
        Rowv = FALSE, Colv = col_order, 
        cexRow = cex, cexCol = cex
    )
}

order_rows_according_to_cols = function(M, alpha = 1) {
    M <- M**alpha
    row_score <- colSums(t(M)*seq_len(ncol(M)), na.rm=TRUE)/rowSums(M, na.rm=TRUE)
    return(order(row_score))
}

#' Plot Bean Plot, showing how replicability of cell types depends on gene sets.
#'
#' @param nv_mat A rectangular AUROC matrix as returned by MetaNeighbor,
#' where each row is a gene set and each column is a cell type.
#' @param hvg_score Named vector with AUROCs obtained from a set of Highly
#' Variable Genes (HVGs). The names must correspond to cell types from nv_mat.
#' If specified, the HVG score is  highlighted in red.
#' @param cex Size factor for row and column labels.
#'
#' @examples
#' data("mn_data")
#' data("GOmouse")
#' library(SummarizedExperiment)
#' AUROC_scores = MetaNeighbor(dat = mn_data,
#'                             experiment_labels = as.numeric(factor(mn_data$study_id)),
#'                             celltype_labels = metadata(colData(mn_data))[["cell_labels"]],
#'                             genesets = GOmouse,
#'                             bplot = FALSE)
#' plotBPlot(AUROC_scores)
#'
#' @export
#'
plotBPlot <- function(nv_mat, hvg_score=NULL, cex=1) {
  # remove cell types with 0 variance
  has_zero_var <- matrixStats::colVars(nv_mat, na.rm = TRUE) < 1e-10
  if (sum(has_zero_var) > 0) {
    warning("Removing cell types with identical scores across all gene sets ",
            "(cell types not present in data?): ",
            paste(colnames(nv_mat)[has_zero_var], collapse = ", "), ".")
    nv_mat <- nv_mat[, !has_zero_var]
  }

  Celltype <- rep(colnames(nv_mat),each=dim(nv_mat)[1])
  ROCValues <- unlist(lapply(seq_len(dim(nv_mat)[2]), function(i) {nv_mat[,i]}))
  beanplot::beanplot(
    ROCValues ~ Celltype, border="NA", col="gray", ylab="AUROC", log = "",
    what=c(0,1,1,1), frame.plot = FALSE, las = 2, cex.axis = cex
  )
  if (!is.null(hvg_score)) {
    graphics::points(hvg_score ~ factor(names(hvg_score)), pch=17, col="red")
  }
}

#' Plot Upset plot showing how replicability depends on input dataset.
#'
#' @param metaclusters Metaclusters extracted from MetaNeighborUS analysis.
#' @param min_recurrence Only show replicability structure for metaclusters
#' that are replicable across at least min_recurrence datasets.
#' @param outlier_name In metaclusters, name assigned to outliers (clusters that
#' did not match with any other cluster)
#'
#' @examples
#' data(mn_data)
#' var_genes = variableGenes(dat = mn_data, exp_labels = mn_data$study_id)
#' celltype_NV = MetaNeighborUS(var_genes = var_genes,
#'                              dat = mn_data,
#'                              study_id = mn_data$study_id,
#'                              cell_type = mn_data$cell_type,
#'                              fast_version = TRUE, one_vs_best = TRUE)
#' mclusters = extractMetaClusters(celltype_NV)
#' plotUpset(mclusters)
#'
#' @export
#'
plotUpset = function(metaclusters, min_recurrence = 2,
                     outlier_name = "outliers") {
    if (!requireNamespace("UpSetR", quietly = TRUE)) {
        stop(paste("Package \"UpSetR\" needed for this function to work.",
                   "Please install it (install.packages(\"UpSetR\"))."),
             call. = FALSE)
    }
    
    metaclusters <- c(metaclusters[names(metaclusters)!=outlier_name],
                      as.list(metaclusters[[outlier_name]]))
    all_studies <- lapply(metaclusters, function(c) { getStudyId(c) })
    unique_studies <- unique(unlist(all_studies))
    study_matrix <- sapply(all_studies, function(c) { unique_studies %in% c })
    rownames(study_matrix) <- unique_studies

    # text.scale: vector containing individual scales in the following format:
    # c(intersection size title, intersection size tick labels, set size title,
    #   set size tick labels, set names, numbers above bars)
    UpSetR::upset(as.data.frame(t(study_matrix[, colSums(study_matrix) >= min_recurrence])*1),
                  order.by = "degree", nsets = nrow(study_matrix),
                  mainbar.y.label = "Number of meta-clusters", main.bar.color = "gray23",
                  sets.x.label = "", line.size = 1.5, point.size = 2.5,
                  show.numbers = TRUE, text.scale = c(2, 2, 1, 2, 1.5, 0.75))
}

#' Plot dot plot showing expression of a gene set across cell types.
#'
#' The size of each dot reflects the number of cell that express a gene,
#' the color reflects the average expression.
#' Expression of genes is first average and scaled in each dataset
#' independently. The final value is obtained by averaging across datasets.
#'
#' @param dat A SummarizedExperiment object containing gene-by-sample
#' expression matrix.
#' @param experiment_labels A vector that indicates the source/dataset
#' of each sample.
#' @param celltype_labels A character vector that indicates the cell type of
#' each sample.
#' @param gene_set Gene set of interest provided as a vector of genes.
#' @param i Default value 1; non-zero index value of assay containing the matrix
#' data.
#' @param normalize_library_size Whether to apply library size normalization
#' before computing average expression (set this value to FALSE if data are
#' already normalized).
#' @param alpha_row Parameter controling row ordering: a higher value of
#' alpha_row gives more weight to extreme AUROC values (close to 1).
#' @param average_expressing_only Whether average expression should be computed
#' based only on expressing cells (Seurat default) or taking into account zeros.
#' @return a ggplot object.
#'
#' @export
plotDotPlot = function(dat, experiment_labels, celltype_labels, gene_set, i = 1,
                       normalize_library_size = TRUE, alpha_row = 10,
                       average_expressing_only = FALSE) {
    if (length(experiment_labels)!=ncol(dat)) {
        stop('experiment_labels length does not match number of samples.')
    }
    if (length(celltype_labels)!=ncol(dat)) {
        stop('celltype_labels length does not match number of samples.')
    }
    gene_set <- gene_set[gene_set %in% rownames(dat)]
    if (length(gene_set)==0) {
        warning('None of the genes are included in the dataset.')
        return()
    }

    expr_cols <- rev(grDevices::colorRampPalette(RColorBrewer::brewer.pal(11,"RdYlBu"))(100))
    expr <- SummarizedExperiment::assay(dat, i = i)
    if (normalize_library_size) {
        normalization_factor <- Matrix::colSums(expr) / 1000000
    } else {
        normalization_factor <- 1
    }
    expr <- scale(expr[gene_set,,drop=FALSE], center = FALSE,
                  scale = normalization_factor)
    
    label_matrix <- design_matrix(makeClusterName(experiment_labels, celltype_labels))
    label_matrix <- scale(label_matrix, center = FALSE, scale = colSums(label_matrix))
    
    centroids <- t(expr %*% label_matrix)
    average_nnz <- t((expr>0) %*% label_matrix)
    # convert to average expression of *expressing* cells and scale
    if (average_expressing_only) {
        centroids <- centroids / average_nnz
    }
    centroids <- scale(centroids)
    
    # convert to tidy format
    `%>%` <- dplyr::`%>%`
    centroids <- centroids %>%
        dplyr::as_tibble(rownames = "cluster") %>%
        tidyr::pivot_longer(cols = -cluster, names_to = "gene",
                            values_to = "average_expression")
    average_nnz <- average_nnz %>%
        tidyr::as_tibble(rownames = "cluster") %>%
        tidyr::pivot_longer(cols = -cluster, names_to = "gene",
                            values_to = "percent_expressing")
    summary <- dplyr::inner_join(centroids, average_nnz,
                                 by = c("cluster", "gene")) %>%
        dplyr::mutate(study = getStudyId(cluster),
                      cell_type = getCellType(cluster)) %>%
        dplyr::group_by(gene, cell_type) %>%
        dplyr::summarize(average_expression = mean(average_expression, na.rm=TRUE),
                         percent_expressing = mean(percent_expressing, na.rm=TRUE))
    summary_matrix <- summary %>%
        dplyr::select(gene, cell_type, average_expression) %>%
        tidyr::pivot_wider(id_cols = dplyr::everything(),
                           names_from = "cell_type",
                           values_from = "average_expression") %>%
        tibble::column_to_rownames("gene") %>%
        as.matrix()
    row_order <- rownames(summary_matrix)[
        order_rows_according_to_cols(summary_matrix, alpha = alpha_row)
    ]
    
    summary %>%
        dplyr::mutate(gene = factor(gene, levels = rev(row_order))) %>%
        ggplot2::ggplot(ggplot2::aes(x = cell_type, y = gene,
                                     size = percent_expressing,
                                     col = average_expression)) +
        ggplot2::geom_point() + 
        ggplot2::scale_radius(limits = c(0,1.001)) +
        ggplot2::theme_bw() +
        ggplot2::theme(axis.title.x = ggplot2::element_blank(),
                       axis.title.y = ggplot2::element_blank()) +
        ggplot2::scale_color_distiller(palette = "RdYlBu") +
        ggplot2::labs(col = "Average expression", size = "Percent expressing") +
        ggplot2::theme(axis.text.x = ggplot2::element_text(angle=45, hjust=1))
}
