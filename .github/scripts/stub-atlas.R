# Give the rendered package a minimal but valid internal atlas so that
# R CMD check and the package's own tests have something real to run against.
#
# Usage: Rscript .github/scripts/stub-atlas.R <atlas_name> <package_dir>
#
# The geometry is a `brain_polygons` data.frame rather than an `sf` object,
# so the smoke test needs no GDAL/PROJ system libraries.

args <- commandArgs(trailingOnly = TRUE)
atlas_name <- args[1]
pkg_dir <- args[2]

square <- function(view, x0, y0) {
  data.frame(
    view = view,
    x = c(x0, x0 + 1, x0 + 1, x0, x0),
    y = c(y0, y0, y0 + 1, y0 + 1, y0),
    group = 1L,
    subgroup = 1L
  )
}

geometry <- list(
  rbind(square("lateral", 0, 0), square("medial", 2, 0)),
  rbind(square("lateral", 0, 2), square("medial", 2, 2))
)

polygons <- data.frame(
  label = c("lh_demo", "rh_demo"),
  hemi = c("lh", "rh"),
  region = "demo"
)
polygons$geometry <- geometry
class(polygons) <- c("brain_polygons", class(polygons))

atlas <- ggseg.formats::ggseg_atlas(
  atlas = atlas_name,
  type = "cortical",
  core = data.frame(
    hemi = c("lh", "rh"),
    region = "demo",
    label = c("lh_demo", "rh_demo")
  ),
  data = ggseg.formats::ggseg_data_cortical(
    geom = polygons,
    vertices = data.frame(
      label = c("lh_demo", "rh_demo"),
      vertices = I(list(0:10, 11:20))
    )
  ),
  palette = c(lh_demo = "#FF0000", rh_demo = "#0000FF")
)

env <- new.env()
assign(paste0(".", atlas_name), atlas, envir = env)

dir.create(file.path(pkg_dir, "R"), recursive = TRUE, showWarnings = FALSE)
save(
  list = paste0(".", atlas_name),
  file = file.path(pkg_dir, "R", "sysdata.rda"),
  envir = env,
  compress = "xz"
)

cat("Wrote stub .", atlas_name, " to R/sysdata.rda\n", sep = "")
