# Defra diffusion-tube workbook -> quickmap CSV
#
# Reads the "Site Details" and "Data" sheets of an ASR-style workbook, outer-
# joins them on Site ID and writes a CSV that from_csv() accepts: Easting,
# Northing, Label, one column per year; the remaining site-detail columns are
# carried through as metadata. Candidate for a quickmap helper (roadmap item
# 11.1); readxl would then join Suggests.
#
# Workbook quirks handled, all seen in the Croydon 2020-2025 file:
#   - Site Details: header spread over two rows ("(m)", "(Y/N)" fragments on
#     the second), empty spacer columns, blank rows between sites
#   - Site Details suffixes a relocated tube (CY55a, CY97b); Data does not
#   - Data: blank corner cell, year headers stored as text or as 2022.00,
#     values carrying a letter flag ("42.77 c", "25.06c")
#   - sites present on one sheet only (CY114 has data, no details)

library(readxl)

# Regex on the lowercased, whitespace-collapsed header -> output name. First
# match wins; an unmatched header is snake_cased as found.
SITE_COLUMN_NAMES <- c(
  "^site id$"          = "site_id",
  "^site name$"        = "Label",
  "^x \\(m\\)$"        = "Easting",
  "^y \\(m\\)$"        = "Northing",
  "^site type$"        = "site_type",
  "^in aqma"           = "in_aqma",
  "relevant exposure"  = "distance_to_exposure_m",
  "kerb"               = "distance_to_kerb_m",
  "^inlet height"      = "inlet_height_m",
  "^pollutants"        = "pollutants",
  "co-located"         = "colocated"
)

snake <- function(x) {
  gsub("^_|_$", "", tolower(gsub("[^A-Za-z0-9]+", "_", x)))
}

rename_site_columns <- function(header) {
  key <- tolower(gsub("\\s+", " ", trimws(header)))
  vapply(key, function(k) {
    hit <- which(vapply(names(SITE_COLUMN_NAMES), grepl, logical(1), x = k))
    if (length(hit)) SITE_COLUMN_NAMES[[hit[1]]] else snake(k)
  }, character(1), USE.NAMES = FALSE)
}

# Relocation suffix dropped (CY55a -> CY55) so both sheets share a key
site_key <- function(id) {
  toupper(sub("(?<=\\d)[a-z]$", "", trimws(id), perl = TRUE))
}

# Header rows run from the "Site ID" cell to the row before the first site;
# their fragments are pasted per column. Rows with a blank ID are spacers.
read_site_details <- function(path, sheet = "Site Details") {
  raw <- read_excel(path, sheet, col_names = FALSE, col_types = "text",
                    .name_repair = "minimal")
  anchor <- which(tolower(trimws(as.matrix(raw))) == "site id", arr.ind = TRUE)
  stopifnot("no 'Site ID' cell on the sheet" = nrow(anchor) > 0)
  header_row <- anchor[1, "row"]
  ids <- raw[[anchor[1, "col"]]]
  body_row <- header_row + which(!is.na(ids[-seq_len(header_row)]))[1]
  header <- apply(raw[header_row:(body_row - 1), ], 2,
                  function(h) paste(h[!is.na(h)], collapse = " "))
  body <- raw[body_row:nrow(raw), nzchar(header)]
  names(body) <- rename_site_columns(header[nzchar(header)])
  body <- utils::type.convert(body[!is.na(body$site_id), ], as.is = TRUE)
  stopifnot(is.numeric(body$Easting), is.numeric(body$Northing))
  body
}

# One row per site, one column per year. The number is kept; any trailing
# text ("c") goes to attr(, "flags") as a long table of site_id, year, flag.
read_tube_data <- function(path, sheet = "Data") {
  raw <- read_excel(path, sheet, col_names = FALSE, col_types = "text",
                    .name_repair = "minimal")
  years <- suppressWarnings(as.integer(as.numeric(unlist(raw[1, -1]))))
  stopifnot("Data header must be years after a blank corner cell" =
              is.na(raw[[1, 1]]) && !anyNA(years))
  body <- raw[-1, ]
  names(body) <- c("site_id", years)
  body <- body[!is.na(body$site_id), ]
  body$site_id <- trimws(body$site_id)
  cells <- body[-1]
  flags <- tidyr::pivot_longer(
    cbind(body[1], lapply(cells, function(v) trimws(sub("^\\s*[0-9.]+", "", v)))),
    -site_id, names_to = "year", values_to = "flag"
  )
  attr(body, "flags") <- flags[!is.na(flags$flag) & nzchar(flags$flag), ]
  body[-1] <- lapply(cells, function(v) as.numeric(sub("^\\s*([0-9.]+).*$", "\\1", v)))
  body
}

join_tubes <- function(sites, data) {
  sites$site_key <- site_key(sites$site_id)
  data$site_key <- site_key(data$site_id)
  stopifnot(!anyDuplicated(sites$site_key), !anyDuplicated(data$site_key))
  only_sites <- setdiff(sites$site_key, data$site_key)
  only_data <- setdiff(data$site_key, sites$site_key)
  if (length(only_sites)) message("Site details without data: ", toString(only_sites))
  if (length(only_data)) message("Data without site details (from_csv() will drop these): ",
                                 toString(only_data))
  joined <- dplyr::full_join(sites, data, by = "site_key", suffix = c("", "_data"))
  joined$site_id <- dplyr::coalesce(joined$site_id, joined$site_id_data)
  years <- grep("^\\d{4}$", names(joined), value = TRUE)
  meta <- setdiff(names(sites), c("site_id", "Label", "Easting", "Northing", "site_key"))
  joined[c("site_id", "Label", "Easting", "Northing", meta, years)]
}

defra_tubes_to_csv <- function(xlsx, csv = sub("\\.xlsx?$", ".csv", xlsx),
                               site_sheet = "Site Details", data_sheet = "Data") {
  data <- read_tube_data(xlsx, data_sheet)
  joined <- join_tubes(read_site_details(xlsx, site_sheet), data)
  write.csv(joined, csv, row.names = FALSE, na = "")
  flags <- attr(data, "flags")
  if (nrow(flags)) write.csv(flags, sub("\\.csv$", "_flags.csv", csv), row.names = FALSE)
  invisible(joined)
}

# ---- run ------------------------------------------------------------------

folder <- "/Users/iarla/Coding/260911 Croydon LCA maps/fwlcaadditionsdiffusiontubedataandasrandaqap"
tubes <- defra_tubes_to_csv(
  file.path(folder, "Diffusion Tube Data Croydon 2020-2025.xlsx"),
  file.path(folder, "croydon_dt_2020_2025.csv")
)
print(tubes)
