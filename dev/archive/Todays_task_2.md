Context: Quickmap.R is a well-structured monolithic codebase that combines leaflet, JS, HTML and YAML technolgies, to ingests air pollution data or other time varying location based information and creates dynamic, time varying maps of it in HTML, with JPG export capability, styled using highly customisable themes. It is 100% functional but still in development at v0.9.1. 

Ahead of release as a full R library at version 1.0, the medium term goals by v0.9.5 are to:

- modularise the main function create_pollution_map
- create helper functions so functions from the R OpenAir library that download UK air pollution measurement networks in near real time, can be ingested using functions in the codebase, to enable workflows like:
  `importAURN() → timeAverage() → process_spatial_data() → quickmap()`.
- process OpenAir's time-oriented table/tibble, non-geographic data into time varying spatial features that can be used by the existing code, to they can be mapped using exist codebase. 
  By v0.9.5, create_pollution_map() becomes a thin wrapper around a new function quickmap() that takes data in a format X that is yet to be determine, and maps it using the existing plotting and styling code. 
- Decisions on the format X, whether it is openAir or another format such as SF, are critical determinants of the future architecture to be determine during this options analysis.

Existing code: Quickmap v0.9.1 has a well-structured monolithic architecture: `create_pollution_map()` orchestrates data loading (CSV/RData), spatial processing (BNG→WGS84), unified layer generation, and dual-output rendering (HTML+JPG). The 111-line main function delegates to helpers but remains the sole entry point. At present, OpenAir compatibility exists only at the level of one of the ingested datasets: Breathe London sensor RData files that follow OpenAir's date+pollutant convention, and some processing that allows these to be plotted using functions in the codebase,—but no functional integration exists for preprocessing or network access.

Your task:
Your is to assist me, the lead engineer, by drafting options for strategies for modularising the code between v0.9.1 and v0.9.5, 

- take account of the current codebase and the existing OpenAir library suites.
- carefully refine and define these goals so they are achievable plan the steps to get from 0.9.1 to 0.9.5
- with the long term goal in mind of a standalone R library that can be widely used to create dynamic maps of time verying point data.

You should plan to at least:

- review the exist main code loop in R/quickmap.R create_pollution_map() function
- review commentary and analysis of OpenAir vs Quickmap in the documents dev/dev/OA_vs_QM_style_guide.md and dev/OpenAir_Integration_Style_Guide.md
- ask me clarifying multiple choice questions
- develop an options analysis for how to refine the medium term goal into clear detailed steps that can be executed, while keeping the code operational, including an early test trying some OpenAir data
- Focus on key questions such as
  - How is quickmap likely to be used by others when it gets to version 1.0 and release it?
  - What are the best established data handling conventions for spatial data mapping, or should we focus on being an extension to OpenAir?
  - What else might we want to be compatible with in the future? 


Output:

- Options_analysis_091_095.md
- 4-6 paragraphs of up to 75 words each that presents
- introductory considerations
- 3-5 options for strategioes to design quickmap, helper functions for it, the types of data it shoudl handle, and which data handling conventions and best practices might be best followed. 
- recommended next step

Scope:

- no coding, only analysis and planning
- minimise verbosity, aim for clarity and realism
- do not exceed the scope stated here. 

Is that clear?