# to do list for code 251015

## urgent bug fixing tasks avoid manual work
- check why the paths don't work correctly for CSV files, e.gg. when CSV files are given, an error is thrown unless the whole path is given eg "~/Coding/R projects/Library/data/wandsworth_2017_2024_no_labels.csv", whereas when OH filenames are given the data path is used correctly from the environment
- merge with code fragment from missing_data_stats.R so that sites where there is less then 80% data in a given year are not displayed

## important tasks before website goes live
- fix zoom level so that on open the map is zoomed in such that markers fill the screen and there are no wide or tall empty borders
- extend the vignette shape so that very wide or very tall do not result in gaps between the vignette overlay and the map edge
- Double check that the addControl legend is removed unless it can be used to show the year on static images
- harmonise approach to ward and marker labelling between the static and interactive/dynamic maps
- show ward labels on the overlay only if parameter set with auto-hide
- Use label value in data as as tooltips for markers if parameter set with auto-hide
- Make radio buttons collapse and move to bottom left corner
- If it will make other tasks simpoler, revise the code approach so choice is dynamic XOR static map generation early on, otherwie leave to later stage tasks


## pre-release
- Select start layer
- Split data import and map creation
- Automate label location, clustering and spread
- prepare the code for packaging as an R library