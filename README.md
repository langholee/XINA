# XINA
XINA: a workflow for the integration of multiplexed proteomics kinetics data with network analysis
Lang Ho Lee, Arda Halu, Stephanie Morgan, Hiroshi Iwata, Masanori Aikawa, and Sasha A. Singh
Journal of Proteome Research DOI: 10.1021/acs.jproteome.8b00615

https://pubs.acs.org/doi/10.1021/acs.jproteome.8b00615

### 1. Introduction
Quantitative proteomics experiments, using for instance isobaric tandem mass tagging approaches, are conducive to measuring changes in protein abundance over multiple time points in response to one or more conditions or stimulations. The aim of XINA is to determine which proteins exhibit similar patterns within and across experimental conditions, since proteins with co-abundance patterns may have common molecular functions. XINA imports multiple datasets, tags dataset in silico, and combines the data for subsequent subgrouping into multiple clusters. The result is a single output depicting the variation across all conditions. XINA, not only extracts co-abundance profiles within and across experiments, but also incorporates protein-protein interaction databases and integrative resources such as KEGG to infer interactors and molecular functions, respectively, and produces intuitive graphical outputs. 

Main contribution: an easy-to-use software for non-expert users of clustering and network analyses.

Data inputs: any type of quantitative proteomics data, label or label-free

### 2. XINA references
https://cics.bwh.harvard.edu/software
http://bioconductor.org/packages/XINA/

### 3. XINA installation
```{r installation}
# Install from Bioconductor
if (!requireNamespace("BiocManager", quietly = TRUE))
    install.packages("BiocManager")
BiocManager::install("XINA")

## Install from Github
install.packages("devtools")
library(devtools)
install_github("cics-bwh/XINA")
```

To follow this tutorial, you need these libraries. If you don't have the packages below, please install them.
``` {r import libraries}
library(XINA)
library(igraph)
library(ggplot2)
library(STRINGdb)
```

### 4. Example theoretical dataset
We generated an example dataset to show how XINA can be used for your research.  To demonstrate XINA functions and allow users to perform similar exercises, we included a module that can generate multiplexed time-series datasets using theoretical data.  This data consists of three treatment conditions, 'Control', 'Stimulus1' and 'Stimulus2'.  Each condition has time series data from 0 hour to 72 hours.  As an example, we chose the mTOR pathway to be differentially regulated across the three conditions.
``` {r example random dataset}
# Generate random multiplexed time-series data
random_data_info <- make_random_xina_data()

# The number of proteins
random_data_info$size

# Time points
random_data_info$time_points

# Three conditions
random_data_info$conditions
```

Read and check the randomly generated data
```{r check randomly generated data files}
Control <- read.csv("Control.csv", check.names=FALSE, stringsAsFactors = FALSE)
Stimulus1 <- read.csv("Stimulus1.csv", check.names=FALSE, stringsAsFactors = FALSE)
Stimulus2 <- read.csv("Stimulus2.csv", check.names=FALSE, stringsAsFactors = FALSE)

head(Control)
head(Stimulus1)
head(Stimulus2)
```

Since XINA needs to know which columns have the kinetics data matrix, the user should give a vector containing column names of the kinetics data matrix.  These column names have to be the same in all input datasets (Control input, Stimulus1 input and Stimulus2 input).
```{r data matrix}
head(Control[random_data_info$time_points])
```

### 5. Package features
XINA is an R package and can examine, but is not limited to, time-series omics data from multiple experiment conditions. It has three modules: 1. Model-based clustering analysis, 2. coregulation analysis, and 3. Protein-protein interaction network analysis (we used STRING DB for this practice).

#### 5.1 Model-based clustering analysis
XINA implements model-based clustering to classify features (genes or proteins) depending on their expression profiles.  The model-based clustering optimizes the number of clusters at minimum Bayesian information criteria (BIC). Model-based clustering is fulfilled by the 'mclust' R package [https://www.ncbi.nlm.nih.gov/pmc/articles/PMC5096736/], which was used by our previously developed tool mIMT-visHTS [https://www.ncbi.nlm.nih.gov/pubmed/26232111]. By default, XINA performs sum-normalization for each gene/protein time-series profile [https://www.ncbi.nlm.nih.gov/pubmed/19861354]. This step is done to standardize all datasets. Most importantly, XINA assigns an electronic tag to each dataset's proteins (similar to TMT) in order to combine the multiple datasets (Super dataset) for subsequent clustering. 

XINA uses the 'mclust' package for the model-based clustering. 'mclust' requires the fixed random seed to get reproducible clustering results. 
```{r fix random seed}
set.seed(0)
```

'nClusters' is the number of desired clusters. 'mclust' will choose the most optimized number of clusters by considering the Bayesian information criteria (BIC). BIC of 'mclust' is the negative of normal BIC, thus the higher BIC, the more optimized clustering scheme in 'mclust', while lowest BIC is better in statistics.
```{r set up for the clustering}
# Data files
data_files <- paste(random_data_info$conditions, ".csv", sep='')
data_files

# time points of the data matrix
data_column <- random_data_info$time_points
data_column
```

Run the model-based clustering
```{r XINA clustering}
# Run the model-based clusteirng
clustering_result <- xina_clustering(data_files, data_column=data_column, nClusters=30)
```

If you think the clustering cannot be optimized by the automatically selected covariance model (scored highest BIC), you can adjust the clustering results by appointing specific parameterisations of the within-condition covariance matrix.
```{r XINA clustering with VVI covariance matrix}
# Model-based clustering using VVI covariance model
clustering_result_vvi <- xina_clustering(data_files, data_column=data_column, nClusters=30, chosen_model='VVI')
```

XINA also supports k-means clustering as well as the model-based clustering
```{r XINA with k-means clustering}
clustering_result_km <- xina_clustering(data_files, data_column=data_column, nClusters=30, chosen_model='kmeans')
```

The clustering results are stored in your working directory.  XINA clustering generates the mclust BIC plot containing the BIC of each covariance matrix ifor each number of clusters. 'xina_clusters.csv' has a long list of XINA cluster results. 'xina_clusters_aligned.csv' has clustering results arranged by gene name. If you want to recall previous clustering results, you can use 'load_previous_results'
```{r load previous data}
clustering_result_reloaded <- load_previous_results()
head(clustering_result_reloaded$aligned)
```

Load previously generated dataset for upcoming XINA analyses.
``` {r load xina_example}
data(xina_example)
```

For visualizing clustering results, XINA draws line graphs of the clustering results using 'plot_clusters'.
```{r XINA clustering plot}
plot_clusters(example_clusters)
```

Clustering plot without x label.
```{r clustering plot2, eval=TRUE, warning=FALSE}
plot_clusters(example_clusters, xylab=FALSE)
```

X axis information is considered as a ordinal variable in XINA's plot_clusters, but you can change it to be continuous variable.
```{r clustering plot3, eval=TRUE, warning=FALSE}
# Convert the time points from the ordinary to the continuous variables
plot_clusters(example_clusters, xval=c(0,2,6,12,24,48,72))

# You can change x axis tick marks
plot_clusters(example_clusters, xval=c(0,2,6,12,24,48,72), xtickmark = c(0,2,6,12,24,48,72))

# You can change Y axis limits to be ranged from 0 to 0.35
plot_clusters(example_clusters, y_lim=c(0,0.35), xval=c(0,2,6,12,24,48,72), xtickmark = c(0,2,6,12,24,48,72))
```

If you need, you can modify the clustering plot by creating your own ggplot theme.
This theme is for small font size of X axis ticks and the plot titles
```{r clustering plot4}
theme1 <- theme(title=element_text(size=8, face='bold'),
                axis.text.x = element_text(size=7),
                axis.text.y = element_blank(),
                axis.ticks.x = element_blank(),
                axis.ticks.y = element_blank(),
                axis.title.x = element_blank(),
                axis.title.y = element_blank())
plot_clusters(example_clusters, ggplot_theme=theme1)
```

Tiny font size and white background
``` {r tmp}
theme2 <- theme(plot.title=element_text(hjust=0, vjust=-1.5, size=5, face='bold'),
                axis.text.x = element_text(size=3.5),
                axis.text.y = element_blank(),
                axis.ticks.x = element_blank(),
                axis.ticks.y = element_blank(),
                axis.title.x = element_blank(),
                axis.title.y = element_blank(),
                panel.background = element_blank(),
                plot.margin = unit(c(0,0,0,0),"cm"))
plot_clusters(example_clusters, ggplot_theme=theme2)
```

XINA calculates sample condition composition, for example the sample composition in the cluster 28 is higher than 95% for Stimulus2. 'plot_condition_composition' plots these compositions as pie-charts. Sample composition information is insightful because we can find which specific patterns are closely related with each stimulus. 
```{r XINA condition composition}
condition_composition <- plot_condition_compositions(example_clusters)
tail(condition_composition)
```

Like XINA clustering plot, you can modify the condition composition charts using ggplot2 theme
This is for small font size and small legend key size
```{r XINA condition composition2}
theme3 <- theme(legend.key.size = unit(0.3, "cm"),
                legend.text=element_text(size=5),
                title=element_text(size=7, face='bold'))
condition_composition <- plot_condition_compositions(example_clusters, ggplot_theme=theme3)
```

This is to draw the charts without the legend
```{r XINA condition composition2}
theme4 <- theme(legend.position="none", title=element_text(size=7, face='bold'))
condition_composition <- plot_condition_compositions(example_clusters, ggplot_theme=theme4)
```

The large piechart without the legend
```{r XINA condition composition3}
theme5 <- theme(legend.position="none",
                plot.title=element_text(hjust=0, vjust=-1.5, size=3, face='bold'),
                panel.grid.major = element_blank(),
                panel.grid.minor = element_blank(),
                panel.background = element_blank(),
                axis.text.x=element_blank(),
                plot.margin = unit(c(-.1,-.1,-.1,-.1),"cm"))
condition_composition <- plot_condition_compositions(example_clusters, ggplot_theme = theme5)
```

You can change colors for the conditions
```{r XINA condition composition4}
# Make a new color code for conditions
condition_colors <- c("tomato","steelblue1","gold")
names(condition_colors) <- example_clusters$condition
example_clusters$color_for_condition <- condition_colors

# Draw condition composition pie-chart with the new color code
condition_composition <- plot_condition_compositions(example_clusters, ggplot_theme=theme2)
```

You can draw the bullseye plot.
```{r bullseye}
# XINA also can draw bull's-eye plots instead of pie-charts.
condition_composition <- plot_condition_compositions(example_clusters, ggplot_theme=theme2, bullseye = TRUE)
```

Based on the condition composition pie-charts, we can see some of clusters are mostly coming from specific stimuli or conditions. Default threshold is 50%.
```{r clustering plot with condition colors}
# New colors for the clustering plot based on condition composition
example_clusters$color_for_clusters <- mutate_colors(condition_composition, example_clusters$color_for_condition)
example_clusters$color_for_clusters
```

```{r drawing clustering plot with the mutated colors}
plot_clusters(example_clusters, xval=c(0,2,6,12,24,48,72), xylab=FALSE)
```

You can lower down the percentage threshold, such as 40%.
```{r clustering plot with lowered threshold}
example_clusters$color_for_clusters <- mutate_colors(condition_composition, example_clusters$color_for_condition, threshold_percent=40)
plot_clusters(example_clusters, xval=c(0,2,6,12,24,48,72), xylab=FALSE)
```

#### 5.2 coregulation analysis
XINA supposes that proteins that comigrate between clusters in response to a given condition are more likely to be coregulated at the biological level than other proteins within the same clusters.  For this module, at least two datasets to be compared are needed. XINA supposes features assigned to the same cluster in an experiment condition as a coregulated group.  XINA traces the comigrated proteins in different experiment conditions and finds signficant trends by 1) the number of member features (proteins) and 2) the enrichment test using the Fishers exact test.  The comigrations are displayed via an alluvial plot. In XINA the comigration is defined as a condition of proteins that show the same expression pattern, classified and evaluated by XINA clustering, in at least two dataset conditions.  If there are proteins that are assigned to the same cluster in more than two datasets, XINA considers those proteins to be comigrated. XINA's 'alluvial_enriched' is designed to find these comigrations and draws alluvial plots for visualizing the found comigrations.
```{r XINA comigration search}
classes <- as.vector(example_clusters$condition)
classes

all_cor <- alluvial_enriched(example_clusters, classes)
head(all_cor)
```

By changing order of sample conditions, you can change colors of streams.
```{r XINA comigration search with different order}
all_cor_Stimulus1_start <- alluvial_enriched(example_clusters, c(classes[2],classes[1],classes[3]))
head(all_cor_Stimulus1_start)
```

You can narrow down comigrations by using the size (the number of comigrated proteins) filter. 
```{r XINA comigration search with comigration size filter}
cor_bigger_than_10 <- alluvial_enriched(example_clusters, classes, comigration_size=10)
head(cor_bigger_than_10)
```

From the size flitered comigrations, XINA provides one more filtering using the condition composition pie-charts. It is the limitation to condition-biased clusters. This enables to find coregulations related with the condition-specific patterns.  XINA assumes that one expression pattern is majorly found in one speficif experimental condition, that patterns is condition-biased.
``` {r finding the condition-biased clusters}
condition_biased_comigrations <- get_condition_biased_comigrations(clustering_result=example_clusters,
count_table=cor_bigger_than_10, selected_conditions=classes, condition_composition=condition_composition, threshold_percent=50, color_for_null='gray', color_for_highly_matched='yellow', cex = 1)
```

In the alluvial plot displaying corregulations between three conditions, Control, Stimulus1 and Stimulus2, one large comigration protein condition is evident (tan color).  XINA can extract the proteins from this comigrated condition.
```{r protein list of specific comigrations}
condition_biased_clusters <- condition_composition[condition_composition$Percent_ratio>=50,]
control_biased_clusters <- condition_biased_clusters[condition_biased_clusters$Condition=="Control",]$Cluster
Stimulus1_biased_clusters <- condition_biased_clusters[condition_biased_clusters$Condition=="Stimulus1",]$Cluster
Stimulus2_biased_clusters <- condition_biased_clusters[condition_biased_clusters$Condition=="Stimulus2",]$Cluster

# Get the proteins showing condition-specific expression patterns in three conditions
proteins_found_in_condition_biased_clusters <- subset(example_clusters$aligned, Control==control_biased_clusters[1] & Stimulus1==Stimulus1_biased_clusters[1] & Stimulus2==Stimulus2_biased_clusters[1])
nrow(proteins_found_in_condition_biased_clusters)
head(proteins_found_in_condition_biased_clusters)
```

If you compare only two conditions, you can apply Fishers exact test to measure how significantly any given comigration condition is with respect to all in the comparison. The following 2x2 table was used to calculate the p-value from the Fisher's exact test.
To evaluate significance of comigrated proteins from cluster #1 in control to cluster #2 in a test condition,

                           | cluster 1 in control   |    other clusters in control
    -----------------------|------------------------|------------------------------
    cluster 2 in test      | 65 (TP)                |    175 (FP)
    other clusters in test | 35 (FN)                |    1079 (TN)

```{r comigrations with comigration size and significance filters}
Control_Stimulus1_significant <- alluvial_enriched(example_clusters, c("Control","Stimulus1"), comigration_size=5, pval_threshold=0.05)
head(Control_Stimulus1_significant)
```

#### 5.3 Network analysis
XINA conducts protein-protein interaction (PPI) network analysis through implementing 'igraph' and 'STRINGdb' R packages.  XINA constructs PPI networks for comigrated protein groups as well as individual clusters of a specific experiment (dataset) condition.  In the constructed networks, XINA finds influential players by calculating various network centrality calculations including betweenness, closeness and eigenvector scores.  For the selected comigrated groups, XINA can calculate an enrichment test based on gene ontology and KEGG pathway terms to help understanding comigrated groups.

XINA's example dataset is from human gene names, so download human PPI database from STRING DB
```{r STRING DB set up}
string_db <- STRINGdb$new( version="10", species=9606, score_threshold=0, input_directory="" )
string_db
```

STRING DB provides PPI confidence score so that users can adjust to get more convincing or more comprehensive PPI networks. 
```{r select PPI confidence level of STRING DB}
get.edge.attribute(string_db$graph)$combined_score

# Medium confidence PPIs only
string_db_med_confidence <- string_db
string_db_med_confidence$graph <- subgraph.edges(string_db$graph, which(E(string_db$graph)$combined_score>=400), delete.vertices = TRUE)

# High confidence PPIs only
string_db_high_confidence <- string_db
string_db_high_confidence$graph <- subgraph.edges(string_db$graph, which(E(string_db$graph)$combined_score>=700), delete.vertices = TRUE)
```

When you run XINA network analysis, you need XINA clustering results and STRING db object. 
```{r XINA analysis with STRING DB}
xina_result <- xina_analysis(example_clusters, string_db)
```

If you want to use another PPI information instead of STRING DB, you can use a data frame containing PPI information.  For example, XINA provides PPI information of HPRD DB datase.
```{r HPRD PPI network}
# Construct HPRD PPI network
data(HPRD)
ppi_db_hprd <- simplify(graph_from_data_frame(d=hprd_ppi, directed=FALSE), remove.multiple = FALSE, remove.loops = TRUE)
head(hprd_ppi)
```

```{r XINA analysis with HPRD}
# Run XINA with HPRD protein-protein interaction database
xina_result_hprd <- xina_analysis(example_clusters, ppi_db_hprd, is_stringdb=FALSE)
```

You can draw PPI networks of all the XINA clusters using 'xina_plots' function easily.  PPI network plots will be stored in the working directory
```{r plotting PPI networks of all the clusters}
# XINA network plots labeled gene names
xina_plot_all(xina_result, example_clusters)
```

If node labels are excessive and the nodes cannot be visualized, labels can be removed.
```{r xina_plots without labels}
# XINA network plots without labels
xina_plot_all(xina_result, example_clusters, vertex_label_flag=FALSE)
```

The PPI network layout can be changed. XINA's available layout options are c('sphere','star','gem','tree','circle','random','nicely'). If you need more information about igraph layouts, see http://igraph.org/r/doc/layout_.html
```{r xina_plots with tree layout}
# Plot PPI networks with tree layout
xina_plot_all(xina_result, example_clusters, vertex_label_flag=FALSE, layout_specified='tree')
```

If you want to draw protein-protein interaction networks for a cluster, use 'xina_plot_bycluster'.
``` {r xina_plot_bycluster}
xina_plot_bycluster(xina_result, example_clusters, cl=1)
```

Also, you can print the network only for one condition
``` {r xina_plot_bycluster2}
xina_plot_bycluster(xina_result, example_clusters, cl=1, condition="Control")
```

Print the protein-protein interaction entworks for every cluster
``` {r xina_plot_all}
img_size <- c(3000,3000)
xina_plot_all(xina_result, example_clusters, img_size=img_size)
```

You can divide protein-protein interaction networks by experimental conditions.
``` {r xina_plot_all2}
xina_plot_all(xina_result, example_clusters, condition="Control", img_size=img_size)
xina_plot_all(xina_result, example_clusters, condition="Stimulus1", img_size=img_size)
xina_plot_all(xina_result, example_clusters, condition="Stimulus2", img_size=img_size)
```

XINA can calculate network centrality of the protein-protein interaction networks within experimental conditions.
``` {r xina_plot_all_eigen}
xina_plot_all(xina_result, example_clusters, centrality_type="Eigenvector", 
              edge.color = 'gray', img_size=img_size)
xina_plot_all(xina_result, example_clusters, condition="Control", centrality_type="Eigenvector", 
              edge.color = 'gray', img_size=img_size)
xina_plot_all(xina_result, example_clusters, condition="Stimulus1", centrality_type="Eigenvector", 
              edge.color = 'gray', img_size=img_size)
xina_plot_all(xina_result, example_clusters, condition="Stimulus2", centrality_type="Eigenvector", 
              edge.color = 'gray', img_size=img_size)
```

Using 'alluvial_enriched' XINA will input the comigrated alluvial plot results and apply the network analysis tools and evaluate them by their network centrality using several network centrality scores, such as degree, eigenvector and hub. XINA ranks proteins by centrality score.
```{r network analysis of comigrated proteins}
protein_list <- proteins_found_in_condition_biased_clusters$`Gene name`
protein_list

plot_title_ppi <- "PPI network of the proteins found in the condition-biased clusters"

# Draw PPI networks and compute eigenvector centrality score.
comigrations_condition_biased_clusters <- xina_plot_single(xina_result, protein_list, centrality_type="Eigenvector",
                                                           vertex.label.cex=0.5, vertex.size=8, vertex.label.dist=1,
                                                           main=plot_title_ppi)
```

You can adjust the number of ranks
``` {r three breaks, results="hide"}
# Draw with less breaks
comigrations_condition_biased_clusters <- xina_plot_single(xina_result, protein_list, centrality_type="Eigenvector",
                                                           vertex.label.cex=0.5, vertex.size=8, vertex.label.dist=1,
                                                           num_breaks=3, main=plot_title_ppi)

```

Without vertex labels, you may see the graph structure better
``` {r test of xina network plotting}
# Draw without labels
comigrations_condition_biased_clusters <- xina_plot_single(xina_result, protein_list, centrality_type="Eigenvector", 
                                                           vertex.size=10, vertex_label_flag=FALSE)
```

You can try different graph layouts
``` {r layout test}
# Sphere layout
comigrations_condition_biased_clusters <- xina_plot_single(xina_result, protein_list, centrality_type="Eigenvector",
                                                           vertex.label.cex=0.5, vertex.size=8, vertex.label.dist=1,
                                                           main=plot_title_ppi, layout_specified = "sphere")
# Star layout
comigrations_condition_biased_clusters <- xina_plot_single(xina_result, protein_list, centrality_type="Eigenvector",
                                                           vertex.label.cex=0.5, vertex.size=8, vertex.label.dist=1,
                                                           main=plot_title_ppi, layout_specified = "star")

# Gem layout
comigrations_condition_biased_clusters <- xina_plot_single(xina_result, protein_list, centrality_type="Eigenvector",
                                                           vertex.label.cex=0.5, vertex.size=8, vertex.label.dist=1,
                                                           main=plot_title_ppi, layout_specified = "gem")

# Tree layout
comigrations_condition_biased_clusters <- xina_plot_single(xina_result, protein_list, centrality_type="Eigenvector",
                                                           vertex.label.cex=0.5, vertex.size=8, vertex.label.dist=1,
                                                           main=plot_title_ppi, layout_specified = "tree")

# Circle layout
comigrations_condition_biased_clusters <- xina_plot_single(xina_result, protein_list, centrality_type="Eigenvector",
                                                           vertex.label.cex=0.5, vertex.size=8, vertex.label.dist=1,
                                                           main=plot_title_ppi, layout_specified = "circle")

# Random layout
comigrations_condition_biased_clusters <- xina_plot_single(xina_result, protein_list, centrality_type="Eigenvector",
                                                           vertex.label.cex=0.5, vertex.size=8, vertex.label.dist=1,
                                                           main=plot_title_ppi, layout_specified = "random")

# Nicely layout
comigrations_condition_biased_clusters <- xina_plot_single(xina_result, protein_list, centrality_type="Eigenvector",
                                                           vertex.label.cex=0.5, vertex.size=8, vertex.label.dist=1,
                                                           main=plot_title_ppi, layout_specified = "nicely")

```

XINA provides functional enrichment tests using KEGG pathways and GO terms via STRINGdb.
```{r enrichment test of the comigrated proteins}
# Enrichment test using KEGG pathway terms
kegg_enriched <- xina_enrichment(string_db, protein_list, enrichment_type = "KEGG", pval_threshold=0.1)
head(kegg_enriched$KEGG)
# plot enrichment test results
plot_enrichment_results(kegg_enriched$KEGG, num_terms=20)
```

GO enrichment results using STRING DB
```{r enrichment test of the comigrated proteins2}
# Enrichment test using GO pathway terms
go_enriched <- xina_enrichment(string_db, protein_list, enrichment_type = "GO", pval_threshold=0.1)
head(go_enriched$Process)
head(go_enriched$Function)
head(go_enriched$Component)
```

You can draw the GO enrichment results
```{r draw GO enrichment results}
plot_enrichment_results(go_enriched$Process, num_terms=20)
plot_enrichment_results(go_enriched$Function, num_terms=20)
plot_enrichment_results(go_enriched$Component, num_terms=20)
```

### 6. Authors
Lee, Lang Ho, Ph.D.   <lhlee@bwh.harvard.edu>
Singh, Sasha A.,Ph.D. <sasingh@bwh.harvard.edu>
Aikawa, Masanori, M.D. Ph.D. <maikawa@bwh.harvard.edu>

### 7. Maintainers
Lee, Lang Ho, Ph.D.   <lhlee@bwh.harvard.edu>
Singh, Sasha A.,Ph.D. <sasingh@bwh.harvard.edu>


### 8. Copyright and license
Copyright (C) <2019>  Lang Ho Lee, Sasha A. Singh and Masanori Aikawa
This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as published by
the Free Software Foundation, either version 3 of the License any 
later version.
This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.
You should have received a copy of the GNU General Public License
along with this program.  If not, see <https://www.gnu.org/licenses/>.
