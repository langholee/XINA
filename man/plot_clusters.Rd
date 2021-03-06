% Generated by roxygen2: do not edit by hand
% Please edit documentation in R/clustering_plots.R
\name{plot_clusters}
\alias{plot_clusters}
\title{plot_clusters}
\usage{
plot_clusters(clustering_result, y_lim = NULL, xval = NULL,
  xtickmark = NULL, xylab = TRUE, ggplot_theme = NULL)
}
\arguments{
\item{clustering_result}{A list containing XINA clustering results.
See \link[XINA]{xina_clustering}}

\item{y_lim}{Y axis limit. If you set y_lim=c(0,1),
'plot_clusters' will plot line graphs scaled from 0 to 1 in y-axis
Default is NULL, which means unscaled line graphs.}

\item{xval}{XINA basically considers time points as a ordinary variable, like 1,2,3,4...n.
You can make the time points as a continuous variable using xval.}

\item{xtickmark}{Change X axis tick marks.
Default is data_column of the clustering result list.}

\item{xylab}{If it is FALSE, x and y labels will be blank.
If it is TRUE (defualt), x and y labels will be shown.}

\item{ggplot_theme}{This is ggplot theme to modify XINA clustering plot.}
}
\value{
Line graphs of all the clusters
}
\description{
Draw all the clustering results.
'plot_clusters' draws two plots, scaled and unscaled line graphs.
Scaled graphs have same y limits that are 0 to 1 by default,
but can be changed via 'y_lim' parameter.
}
\examples{
library(ggplot2)

# load XINA example data
data(xina_example)

# Draw clustering plots
plot_clusters(example_clusters)

# Apply theme to the clustering plot
theme1 <- theme(title=element_text(size=8, face='bold'),
axis.text.x = element_text(size=7),
axis.text.y = element_blank(),
axis.ticks.x = element_blank(),
axis.ticks.y = element_blank(),
axis.title.x = element_blank(),
axis.title.y = element_blank())
plot_clusters(example_clusters, ggplot_theme=theme1)

}
