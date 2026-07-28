# Render this template into a real package, the way setup_atlas_repo() does.
#
# Usage: Rscript .github/scripts/render-template.R <atlas_name> <output_dir>
#
# Kept deliberately dependency-free so the smoke test can run before any
# package is installed. Mirrors ggseg.extra::template_replace().

args <- commandArgs(trailingOnly = TRUE)
atlas_name <- args[1]
out_dir <- args[2]
repo_name <- paste0("ggseg", tools::toTitleCase(atlas_name))

skip <- "^\\.git/|^\\.github/|\\.(png|jpg|jpeg|gif|ico|rda|RData|rds)$"
files <- list.files(".", recursive = TRUE, all.files = TRUE, no.. = TRUE)
files <- files[!grepl(skip, files)]

tokens <- c(
  ATLASNAME = atlas_name,
  PKGNAME = repo_name,
  YEARNUM = format(Sys.Date(), "%Y")
)

for (f in files) {
  dest <- file.path(out_dir, f)
  dir.create(dirname(dest), recursive = TRUE, showWarnings = FALSE)

  content <- readLines(f, warn = FALSE)
  for (token in names(tokens)) {
    content <- gsub(token, tokens[[token]], content, fixed = TRUE)
  }
  writeLines(content, dest)
}

pkg_doc <- file.path(out_dir, "R", "PKGNAME-package.R")
if (file.exists(pkg_doc)) {
  invisible(file.rename(
    pkg_doc,
    file.path(out_dir, "R", paste0(repo_name, "-package.R"))
  ))
}

leftover <- Filter(
  function(f) {
    any(grepl(paste(names(tokens), collapse = "|"), readLines(f, warn = FALSE)))
  },
  list.files(out_dir, recursive = TRUE, full.names = TRUE)
)
if (length(leftover) > 0) {
  stop(
    "Unsubstituted placeholders remain in: ",
    paste(leftover, collapse = ", ")
  )
}

for (f in list.files(
  out_dir,
  pattern = "\\.R$",
  recursive = TRUE,
  full.names = TRUE
)) {
  tryCatch(
    parse(f),
    error = function(e) {
      stop("Generated file does not parse: ", f, "\n", conditionMessage(e))
    }
  )
}

cat("Rendered", repo_name, "into", out_dir, "\n")
