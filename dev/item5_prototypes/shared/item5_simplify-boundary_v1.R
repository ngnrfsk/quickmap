# Simplify the boundary polygon for prototype embedding (rendering research only)
library(sf)
shared <- "/Users/iarla/Coding/quickmap/dev/item5_prototypes/shared"
b <- st_read(file.path(shared, "boundary.json"), quiet = TRUE)
bs <- st_simplify(st_transform(b, 27700), dTolerance = 20)
bs <- st_transform(bs, 4326)
st_write(st_geometry(bs), file.path(shared, "boundary_simplified.json"),
         driver = "GeoJSON", delete_dsn = TRUE, quiet = TRUE)
cat("simplified boundary:", file.size(file.path(shared, "boundary_simplified.json")), "bytes\n")
