#!/usr/bin/env Rscript
# Generates one YAML file per role from people.csv (runs as a Quarto pre-render step).
#
#   people.csv  (columns: name, institution, role)
#        |
#        v
#   people-data/01-<role>.yml, 02-<role>.yml, ...   (roles in order of first appearance,
#                                                    "Other" = people without a role, last)
#
# Each YAML file looks like:
#   role: PhD students
#   people:
#     - name: Mei Chen
#       institution: Example Research Institute
#       image: files/profiles/mei-chen.jpg        # only if the picture exists
#
# Pictures are looked up in files/profiles/<slug>.(jpg|jpeg|png|webp|gif|svg), where <slug> is
# the person's name in lowercase ASCII with hyphens, e.g. "Carlos Núñez" -> carlos-nunez.
# The page people.qmd reads these YAML files.

source("r/utils.R")

csv_file <- "data/people.csv"
exts     <- c("jpg", "jpeg", "png", "webp", "gif", "svg")
img_ext  <- c(exts, toupper(exts))

if (!file.exists(csv_file)) stop(csv_file, " not found")
people <- read.csv(csv_file, colClasses = "character", strip.white = TRUE,
                   fileEncoding = "UTF-8-BOM")
missing <- setdiff(c("name", "institution", "role"), names(people))
if (length(missing)) stop(csv_file, " is missing column(s): ", paste(missing, collapse = ", "))

people <- people[!is.na(people$name) & people$name != "", , drop = FALSE]
people$role[is.na(people$role) | people$role == ""] <- "Other"
people$institution[is.na(people$institution)] <- ""

roles <- unique(people$role)
roles <- c(setdiff(roles, "Other"), intersect(roles, "Other"))   # "Other" last

dir.create("people", showWarnings = FALSE)
unlink(list.files("people", pattern = "\\.ya?ml$", full.names = TRUE))   # remove stale files

n_img <- 0
for (k in seq_along(roles)) {
  p <- people[people$role == roles[k], , drop = FALSE]
  members <- lapply(seq_len(nrow(p)), function(i) {
    cand <- file.path("files/profiles/", paste0(slugify(p$name[i]), ".", img_ext))
    img  <- cand[file.exists(cand)][1]
    m <- list(name = p$name[i], institution = p$institution[i])
    if (!is.na(img)) { m$image <- img; n_img <<- n_img + 1 }
    m
  })
  file <- file.path("people", sprintf("%02d-%s.yml", k, slugify(roles[k])))
  yaml::write_yaml(list(role = roles[k], people = members), file, fileEncoding = "UTF-8")
}

message("generate_people: ", nrow(people), " people in ", length(roles), " role(s), ",
        n_img, " with a picture -> ", "people", "/")
