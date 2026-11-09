# Shared helpers, used by scripts/generate_sites.R and map.qmd.
# Keeping slugify() in one place guarantees that the map links match the page names.

# "Éxample Site A (Guyane)" -> "example-site-a-guyane"
slugify <- function(x) {
  x <- stringi::stri_trans_general(x, "Any-Lower; NFD; [:Nonspacing Mark:] Remove")
  x <- gsub("[^a-z0-9]+", "-", x)
  x <- gsub("^-+|-+$", "", x)
  ifelse(x == "", "site", x)
}

required_cols <- c("lon", "lat", "site", "years", "nb_control", "nb_logged", "plot_size")

read_sites <- function(path = "sites.csv") {
  if (!file.exists(path)) stop("sites.csv not found (expected at ", path, ")")
  sites <- read.csv(path, colClasses = "character", strip.white = TRUE,
                    fileEncoding = "UTF-8-BOM")
  missing <- setdiff(required_cols, names(sites))
  if (length(missing)) stop("sites.csv is missing column(s): ", paste(missing, collapse = ", "))
  sites[sites$site != "", , drop = FALSE]
}
