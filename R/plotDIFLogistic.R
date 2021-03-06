#' Function for characteristic curve of 2PL logistic DIF model
#'
#' @aliases plotDIFLogistic
#'
#' @description Plots characteristic curve of 2PL logistic DIF model
#'
#' @param data numeric: the data matrix. See Details.
#' @param group numeric: the vector of group membership. See Details.
#' @param type character: a character string specifying which DIF effects must be tested.
#' Possible values are "both" (default), "udif" and "nudif". See Details.
#' @param item numeric: number of item to be plotted
#' @param item.name character: the name of item.
#' @param IRT logical: if IRT parameterization (\code{TRUE}, default) or classic logistic
#' parameterization (\code{FALSE}) may be applied.
#' @param p.adjust.method character:  the acronym of the method for p-value adjustment for
#' multiple comparisons. See Details.
#' @param purify logical: if item purification may be applied.
#'
#' @usage plotDIFLogistic(data, group, type = "both", item, item.name,
#' IRT = F, p.adjust.method = "none", purify = F)
#'
#' @details
#' This function plots characteristic curve of 2PL logistic DIF model.
#'
#'
#' @author
#' Adela Drabinova \cr
#' Institute of Computer Science, The Czech Academy of Sciences \cr
#' Faculty of Mathematics and Physics, Charles University \cr
#' drabinova@cs.cas.cz \cr
#'
#' Patricia Martinkova \cr
#' Institute of Computer Science, The Czech Academy of Sciences \cr
#' martinkova@cs.cas.cz \cr
#'
#' @examples
#' \dontrun{
#' # loading libraries
#' library(difNLR, difR)
#'
#'  # loading data based on GMAT
#' data(GMAT, package = "difNLR")
#' data  <- GMAT[, colnames(GMAT) != "group"]
#' group <- GMAT[, "group"]
#'
#' # Characteristic curve by logistic regression model
#' plotDIFLogistic(data, group, item = 1)
#'
#' # Characteristic curve by logistic regression model using scaled score
#' plotDIFLogistic(data, group, item = 1, IRT = T)
#' }
#'
#'
#' @export
#' @importFrom ggplot2 guides guide_legend



plotDIFLogistic <- function(data, group, type = "both", item, item.name,
                            IRT = F, p.adjust.method = "none", purify = F){
  if (IRT){
    match <- c(scale(apply(data, 1, sum)))
  } else {
    match <- "score"
  }
  fit <- difR::difLogistic(Data = data, group = group, focal.name = 1, type = type,
                           match = match, p.adjust.method = p.adjust.method,
                           purify = purify)

  LR_plot <- function(x, group, beta0, beta1, beta2, beta3){
    return(1/(1 + exp(-(beta0 + beta1*x + beta2*group + beta3*x*group))))
  }

  ### data
  if (IRT){
    score_R <- scale(apply(data[group == 0, ], 1, sum))
    score_F <- scale(apply(data[group == 1, ], 1, sum))
  } else {
    score_R <- apply(data[group == 0, ], 1, sum)
    score_F <- apply(data[group == 1, ], 1, sum)
  }


  max_score <- max(score_R, score_F)
  min_score <- min(score_R, score_F)

  col   <- c("dodgerblue2", "goldenrod2")
  alpha <- .5
  shape <-  21
  size  <- .8
  linetype <- c(2, 1)
  if (IRT){
    xlab <- "Standardized total score (Z-score)"
  } else {
    xlab <- "Total score"
  }

  if (missing(item.name)){
    item.name <- paste("Item", item)
  }

  hv_R <- data.frame(X1 = as.numeric(levels(as.factor(score_R))),
                     X2 = tapply(data[group == 0, item], as.factor(score_R), mean))
  hv_F <- data.frame(X1 = as.numeric(levels(as.factor(score_F))),
                     X2 = tapply(data[group == 1, item], as.factor(score_F), mean))
  hv   <- data.frame(rbind(cbind(hv_R, Group = "Reference"), cbind(hv_F, Group = "Focal")))
  rownames(hv) <- 1:dim(hv)[1]
  hv$size <- c(table(score_R), table(score_F))

  coef <- fit$logitPar[item, ]

  plot_CC <- ggplot(hv, aes_string("X1", "X2")) +
    ### points
    geom_point(aes_string(colour = "Group", fill = "Group",
                          size = "size"),
               alpha = alpha, shape = shape) +
    ### lines
    stat_function(aes(colour = "Reference", linetype = "Reference"),
                  fun = LR_plot,
                  args = list(group = 0,
                              beta0 = coef[1],
                              beta1 = coef[2],
                              beta2 = coef[3],
                              beta3 = coef[4]),
                  size = size, geom = "line") +
    stat_function(aes(colour = "Focal", linetype = "Focal"),
                  fun = LR_plot,
                  args = list(group = 1,
                              beta0 = coef[1],
                              beta1 = coef[2],
                              beta2 = coef[3],
                              beta3 = coef[4]),
                  size = size, geom = "line")  +
    ### style
    scale_size_continuous(name = "Counts")  +
    scale_colour_manual(name = "Group",
                        breaks = hv$Group,
                        values = col) +
    scale_fill_manual(values = col) +
    scale_linetype_manual(name = "Group",
                          breaks = hv$Group,
                          values = linetype) +
    guides(colour = guide_legend(title = "Group", order = 1)) +
    guides(fill = guide_legend(title = "Group", order = 1)) +
    guides(linetype = guide_legend(title = "Group", order = 1)) +
    guides(size = guide_legend(title = "Counts", order = 2)) +
    ### theme
    xlab(xlab) +
    ylab("Probability of correct answer") +
    scale_y_continuous(limits = c(0, 1)) +
    theme_app() +
    theme(legend.box.just = "top",
          legend.position = c(0.01, 0.98),
          legend.justification = c(0, 1),
          legend.key.width = unit(1, "cm"),
          legend.box = "horizontal") +
    ggtitle(item.name)

  plot_CC

}


