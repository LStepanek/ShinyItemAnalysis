#' Wright Map using ggplot
#'
#' @aliases ggWrightMap
#'
#' @description This function allows to generate Wright Map (also called item-person map)
#' using ggplot() function from package ggplot2. Wright Map is used to display histogram
#' of factor scores and the item difficulty parameters estimated by the Rasch IRT model.
#'
#' @param theta numeric: vector of ability estimates
#' @param b numeric: vector of difficulty estimates
#' @param binwidth numeric: the width of the bins of histogram
#' @param color character: color of histogram
#' @param size text size in pts
#'
#' @usage ggWrightMap(theta, b, binwidth = 0.5, color = "blue", size = 15)
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
#' @references
#' Wright, B. D., & Stone, M. H. (1979). Best test design.
#'
#' @seealso
#' \code{\link[WrightMap]{wrightMap}}
#'
#' @examples
#' \dontrun{
#' library(ShinyItemAnalysis)
#' library(mirt)
#'
#' data(dataMedical)
#' data <- dataMedical[, 1:100]
#'
#' # Model
#' fit <- mirt(data, model = 1, itemtype = "Rasch")
#' # factor scores
#' theta <- as.vector(fscores(fit))
#' # difficulty estimates
#' b <- coef(fit, simplify = T)$items[, "d"]
#'
#' ggWrightMap(theta, b)
#' }
#' @export


ggWrightMap <- function(theta, b, binwidth = 0.5, color = "blue", size = 15){
  if (missing(theta)){
    stop("'theta' needs to be specified", call. = FALSE)
  }
  if (missing(b)){
    stop("'theta' needs to be specified", call. = FALSE)
  }

  df.theta <- data.frame(theta = theta)

  theta.cut.points <- seq(min(c(theta, b)) - binwidth/2, max(c(theta, b)) + binwidth/2, binwidth/2)
  b.cut.points <- cut(b, theta.cut.points, include.lowest = T)
  levels(b.cut.points) <- theta.cut.points[-length(theta.cut.points)] + diff(theta.cut.points)/2
  b.cut.points <- as.numeric(paste(b.cut.points))

  df.b <- data.frame(item = 1:length(b), b = b, y = b.cut.points)
  df.b$x <- 0
  for (i in unique(df.b$y)){
    n <- nrow(df.b[df.b$y == i, ])
    df.b[df.b$y == i, "x"] <- 1:n
  }

  maxn <- max(nchar(df.b$item))

  while(any(nchar(df.b$item) < maxn)){
    df.b$item <- ifelse(nchar(df.b$item) < maxn, paste0("0", df.b$item), df.b$item)
  }

  if(any(df.b$x > 1)){
    for (k in which(df.b$x > 1)){
      df.b[nrow(df.b) + 1, ] <- df.b[k, ]
      df.b[nrow(df.b), "item"] <- "|"
      df.b[nrow(df.b), "x"] <- df.b[nrow(df.b), "x"] - 0.5
    }
  }

  lim.x.min <- min(c(theta, b)) - binwidth
  lim.x.max <- max(c(theta, b)) + binwidth

  g1 <- ggplot(df.theta, aes_string(x = "theta")) +
    geom_histogram(binwidth = binwidth, fill = color, col = "black", na.rm = TRUE) +
    xlim(lim.x.min, lim.x.max) +
    coord_flip() +
    scale_y_reverse() +
    xlab("Student ability") +
    theme_app(base_size = size) +
    theme(axis.title.x = element_blank(),
          axis.text.x = element_blank(),
          axis.ticks.x = element_blank())

  g2 <- ggplot(df.b, aes_string(x = "x", y = "y", label = "item")) +
    geom_text(hjust = 0.5, vjust = 0.5, na.rm = TRUE) +
    scale_y_continuous(position = "right", limits = c(lim.x.min, lim.x.max)) +
    scale_x_continuous(limits = c(min(df.b$x) - 0.5, max(df.b$x) + 0.5)) +
    ylab("Item difficulty") +
    theme_app(base_size = size) +
    theme(axis.title.x = element_blank(),
          axis.text.x = element_blank(),
          axis.ticks.x = element_blank())

  plot_grid(g1, g2)
}
