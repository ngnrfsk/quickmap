[r-spatial.org]([r-spatial.org](https://www.r-spatial.org/)) outline summary

The core r-spatial components are **sf**, **stars**, **terra**, **sp** (legacy) plus key extensions like mapview, gstat and spdep.[^1][^2][^3]

## sf

- Simple features (OGC) implementation for vector data (points, lines, polygons, multiparts, all XYZ/XYM variants) stored as geometries in a data frame list-column.[^4][^1]
- Interfaces to GDAL for I/O, GEOS and s2 for geometry operations, and PROJ for CRS transformations, with strong integration into dplyr, tidyr and ggplot2 workflows.[^1][^4]
- Extended by packages such as lwgeom (PostGIS/liblwgeom functions), stars (raster and data cubes), sfnetworks (network data), and connects to spatial databases like PostGIS via DBI.[^3][^4][^1]


## stars

- Designed for raster and spatio‑temporal “data cubes”, representing multi-band, multi-time rasters and vector time series, scalable beyond local disk where needed.[^1]
- Handles regular, rotated, sheared, rectilinear and curvilinear grids, leveraging GDAL for raster operations and providing tight integration with sf for vector overlays and conversion.[^1]
- Offers modeling helpers such as predict methods on stars objects, supporting typical raster modelling workflows while keeping data in the stars abstraction.[^1]


## terra

- General spatial data analysis for both raster (SpatRaster) and vector (SpatVector) data, written mostly in C++/S4 for performance and large data handling.[^5][^6][^7]
- Provides core GIS functionality: reading/writing many formats, raster algebra, reprojection, resampling, proximity, zonal statistics, and model prediction/interpolation methods.[^6][^7]
- Successor to raster, and interoperates with sf for vector I/O and conversions, giving users a performant alternative raster engine within the r-spatial universe.[^8][^5][^6][^3]


## sp (legacy core)

- Original S4 spatial classes (SpatialPoints, SpatialLines, SpatialPolygons, SpatialGrid, etc.) underpinning earlier R spatial workflows and many older CRAN packages.[^2][^9][^3]
- Now superseded for new work by sf and terra, but still widely used; conversion helpers exist (st_as_sf, as(x,"Spatial"), terra::vect) to move objects between sp, sf and terra classes.[^9][^2][^8]
- Historically worked together with rgdal and rgeos (now retired) for I/O and geometry operations, and still forms the data backbone for numerous domain‑specific spatial packages.[^2][^9]


## Key extension packages

- mapview: Interactive map visualisation for sf, stars, sp and terra objects, easing exploratory data analysis and sharing of spatial results.[^3]
- gstat: Geostatistics (kriging, variograms) operating on sf and sp objects, bridging core spatial classes with advanced interpolation and simulation tools.[^2][^3]
- spdep (and successors like spatialreg): Spatial dependence, weights, and regression for lattice and areal data, historically on sp, with growing sf support.[^3][^2]


## Interactions and co‑development

- sf and stars were co‑designed and share data and function conventions, which simplifies combining vector and raster data in a single workflow.[^4][^1]
- terra interoperates via converters with sf and sp, letting users mix fast raster operations in terra with sf’s tidyverse‑friendly vector handling and legacy sp‑based packages.[^5][^9][^8]
- Shared reliance on the OSGeo stack (GDAL, GEOS, PROJ) and CRAN Task View coordination encourages aligned APIs, cross‑package extensions (mapview, gstat, spdep) and community co‑maintenance, reinforcing mutual development.[^4][^2][^3]
<span style="display:none">[^10][^11][^12][^13][^14][^15]</span>

<div align="center">⁂</div>

[^1]: https://r-spatial.org/book/07-Introsf.html

[^2]: https://cran.r-project.org/view=Spatial

[^3]: https://www.osgeo.org/projects/r-spatial/

[^4]: https://r-spatial.github.io/sf/

[^5]: https://github.com/r-spatial/stars/issues/633

[^6]: https://rspatial.r-universe.dev/terra/terra.pdf

[^7]: https://cran.r-project.org/web/packages/terra/terra.pdf

[^8]: https://geo200cn.github.io/introspatial.html

[^9]: https://www.r-bloggers.com/2021/06/conversions-between-different-spatial-classes-in-r/

[^10]: https://www.paulamoraga.com/book-spatial/spatial-data-in-r.html

[^11]: https://github.com/helixcn/sdm_r_packages

[^12]: https://cran.r-project.org/web/packages/available_packages_by_name.html

[^13]: https://rpubs.com/Wyclife/sdm_sf_stars_terra

[^14]: https://mappinggis.com/2022/09/los-paquetes-de-r-para-gis-mas-utilizados/

[^15]: https://consensus.app/search/what-are-the-most-commonly-used-r-packages-for-eco/TGTWwwqpR5qKny_p5ZGZqQ/

