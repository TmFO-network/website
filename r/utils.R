# Shared helpers, used by scripts/generate_sites.R and map.qmd.
# Keeping slugify() in one place guarantees that the map links match the page names.

# "Éxample Site A (Guyane)" -> "example-site-a-guyane"
slugify <- function(x) {
  x <- stringi::stri_trans_general(x, "Any-Lower; NFD; [:Nonspacing Mark:] Remove")
  x <- gsub("[^a-z0-9]+", "-", x)
  x <- gsub("^-+|-+$", "", x)
  ifelse(x == "", "site", x)
}

required_cols <- c("lon", "lat", "site", "nb_control", "nb_logged", "plot_size")

read_sites <- function(path = "sites.csv") {
  if (!file.exists(path)) stop("sites.csv not found (expected at ", path, ")")
  sites <- read.csv(path, strip.white = TRUE, fileEncoding = "UTF-8-BOM")
  missing <- setdiff(required_cols, names(sites))
  if (length(missing)) stop("sites.csv is missing column(s): ", paste(missing, collapse = ", "))
  sites[sites$site != "", , drop = FALSE]
}

convert_coord <- function(val, is_lat) {
  if (is.na(val)) return(NA_character_)
  
  if (is_lat) {
    suffix <- ifelse(val >= 0, "N", "S")
  } else {
    suffix <- ifelse(val >= 0, "E", "W")
  }
  
  deg <- floor(abs(val))
  min_val <- (abs(val) - deg) * 60
  min <- floor(min_val)
  sec <- round((min_val - min) * 60)
  
  # Handle rounding overflow (e.g., 59.999 seconds becoming 60)
  if (sec >= 60) {
    sec <- 0
    min <- min + 1
  }
  if (min >= 60) {
    min <- 0
    deg <- deg + 1
  }
  
  # Format as a clean string
  return(sprintf("%d° %d' %.0f\" %s", deg, min, sec, suffix))
}
