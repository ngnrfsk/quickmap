# QuickMap

Air quality maps from the data you already have — a diffusion tube
spreadsheet, a sensor-network export, or a live OpenAir data pull. Every
map is a single self-contained file you can email or put on a website,
and animations stay small enough to send.

## Start here

### [Get started](articles/quickmap.html)

**A fast intro to QuickMap, to get you making maps in minutes.** Two
builds, a line at a time: a report map grown from a single argument, then
an animated pollution episode. Every map on the page is real output you
can click, drag and play with.

Install · your first map from one argument · a borough boundary · the
vignette · `DATA_PATH` · export a JPG · title and file name · labels ·
several networks at once · a 108-step animation · live wind over it.

## The chapters

### [Your data](articles/your-data.html)
What QuickMap accepts and how it recognises it. Diffusion tube CSVs ·
context CSVs for schools and other places · sensor exports in RData ·
data frames you built yourself · fetching with the OpenAir tools · how
recognition works.

### [Layers](articles/layers.html)
Putting more than one source on a map, and controlling each separately.
The `layers` list · naming with `from_csv()` · per-layer pollutants with
`from_rdata()` · live data with `from_openair()` · your own data frame
with `qm_layer()` · per-layer symbols.

### [Labels](articles/labels.html)
The number, or the name, beside each symbol. The five modes ·
always-visible values · site names instead of values · how content is
chosen per layer · size and the plate behind them · why reference layers
get a banner key instead.

### [Boundaries](articles/boundaries.html)
The area the map is about. One borough, several, or all · writing names
on the map · the vignette that dims the outside · leaving the boundary
off altogether.

### [Styling and themes](articles/styling.html)
What the colours mean, and how everything else looks. The bundled colour
scales · writing your own · **the mean and maximum figures on the
legend** · themes as one reusable file · which setting wins · background
tiles.

### [Time and animation](articles/time.html)
Any layer with more than one time step gets the slider. Choosing which
steps to show · autoplay and how the pace is decided · the speed button ·
how big an animation can get before QuickMap changes tactics.

### [Wind](articles/wind.html)
A particle flow over the map, advancing with the slider. Where the data
comes from · bringing your own · styling the particles · limits worth
knowing.

### [Sharing and export](articles/sharing.html)
The file *is* the product. Email it · put it on a website · export a JPG
for a report · **sizing labels for the printed page**.

### [Recipes](articles/recipes.html)
Whole worked jobs, start to finish. The annual borough report map · the
pollution-episode animation · proposed sites over existing ones ·
fetch-to-map straight from the internet.

### [For R users: the layer contract](articles/r-users.html)
The internals, for anyone extending QuickMap. Canonical columns ·
construction and inspection · the time grammar · how inference decides ·
the compatibility wrapper.

## If you are looking for something specific

| You want to… | Go to |
|---|---|
| Make a map in the next five minutes | [Get started](articles/quickmap.html) |
| Know whether your spreadsheet will work | [Your data](articles/your-data.html) |
| Put schools, or a second network, on the map | [Layers](articles/layers.html) |
| Show the numbers on the map | [Labels](articles/labels.html) |
| Change the colours or the branding | [Styling and themes](articles/styling.html) |
| Animate several years, or an episode | [Time and animation](articles/time.html) |
| Get a picture into a report | [Sharing and export](articles/sharing.html) |
| Copy a complete worked example | [Recipes](articles/recipes.html) |
| Look up a function | [Reference](reference/index.html) |
