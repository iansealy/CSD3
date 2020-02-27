suppressPackageStartupMessages(library(tidyverse))
suppressPackageStartupMessages(library(jsonlite))
suppressPackageStartupMessages(library(DESeq2))

options(readr.show_progress=FALSE)

# Get samples
num_columns <- count_fields("samples.tsv", tokenizer_tsv(), n_max=1)
if (num_columns == 2) {
  samples <- read_tsv(
    "samples.tsv",
    col_names=c("sample", "condition"),
    col_types=cols(
      sample=col_character(),
      condition=col_factor()
    )
  )
  stop_for_problems(samples)
} else if (num_columns == 3) {
  samples <- read_tsv(
    "samples.tsv",
    col_names=c("sample", "condition", "group"),
    col_types=cols(
      sample=col_character(),
      condition=col_factor(),
      group=col_factor()
    )
  )
  stop_for_problems(samples)
} else {
  stop("samples.tsv must have two or three columns")
}

# Get comparison
comparison <- fromJSON("comparison.json")
samples_deseq2 <- samples
samples_deseq2$condition <- fct_collapse(
  samples_deseq2$condition,
  exp=comparison$experimental_conditions,
  con=comparison$control_conditions
)
samples_deseq2$condition <- fct_relabel(
  samples_deseq2$condition,
  ~ str_replace_all(.x, "-", "_")
)
if (num_columns == 3) {
  samples_deseq2$group <- fct_relabel(
    samples_deseq2$group,
    ~ str_replace_all(.x, "-", "_")
  )
}

# Get annotation
annotation <- read_tsv(
  "../annotation/annotation.txt",
  col_names=c(
    "Gene", "Chr", "Start", "End", "Strand",
    "Biotype", "Name", "Description"
  ),
  col_types=cols(
    Gene=col_character(),
    Chr=col_factor(),
    Start=col_integer(),
    End=col_integer(),
    Strand=col_integer(),
    Biotype=col_factor(),
    Name=col_character(),
    Description=col_character()
  )
)

# Get counts
counts <-tibble(
  gene=character(),
  sample=factor(samples$sample, levels=unique(samples$sample))[0],
  stranded2=integer(),
  .rows=0
)
for (sample in samples$sample) {
  tmp_counts <- read_tsv(
    str_c("../star2/", sample, "/ReadsPerGene.out.tab"),
    skip=4,
    col_names=c("gene", "unstranded", "stranded1", "stranded2"),
    col_types=cols(
      gene=col_character(),
      unstranded=col_skip(),
      stranded1=col_skip(),
      stranded2=col_integer()
    )
  )
  stop_for_problems(tmp_counts)
  tmp_counts <- add_column(
    tmp_counts,
    sample=factor(sample, levels=levels(counts$sample)),
    .before="stranded2"
  )
  counts <- bind_rows(counts, tmp_counts)
}
rm(tmp_counts)

# Aggregate counts
counts <- pivot_wider(counts, names_from=sample, values_from=stranded2)

# DESeq2
if (num_columns == 2) {
  design <- formula(~ condition)
} else if (num_columns == 3) {
  design <- formula(~ group + condition + group:condition)
}
dds <- DESeqDataSetFromMatrix(
  column_to_rownames(counts, var="gene"),
  column_to_rownames(samples_deseq2, var="sample"),
  design=design
)
rm(counts)
dds <- DESeq(dds)
res <- results(dds, contrast=c("condition", "exp", "con"), alpha=0.05, tidy=TRUE)

# Output
write_tsv(
  enframe(dds$sizeFactor),
  "size-factors.tsv",
  col_names=FALSE
)
res <- inner_join(
  select(res, Gene=row, pval=pvalue, adjp=padj, log2fc=log2FoldChange),
  annotation,
  by="Gene"
)
res <- inner_join(
  res,
  rownames_to_column(
    rename_all(
      as.data.frame(counts(dds)),
      paste0,
      " count"
    ),
    var="Gene"
  ),
  by="Gene"
)
res <- inner_join(
  res,
  rownames_to_column(
    rename_all(
      as.data.frame(counts(dds, normalized=TRUE)),
      paste0,
      " normalised count"
    ),
    var="Gene"
  ),
  by="Gene"
)
res <- arrange(res, adjp, pval, Gene)
write_tsv(res, "all.tsv")
write_tsv(filter(res, adjp < 0.05), "sig.tsv")

# QC
rld <- rlog(dds, blind=TRUE)
colData(rld)$condition <- samples$condition
pdf("qc.pdf")
if (num_columns == 2) {
  plotPCA(rld, intgroup="condition")
} else if (num_columns == 3) {
  plotPCA(rld, intgroup=c("condition", "group"))
}
plotMA(dds)
plotMA(lfcShrink(dds, contrast=c("condition", "exp", "con"), quiet=TRUE))
plotDispEsts(dds)
dev.off()
