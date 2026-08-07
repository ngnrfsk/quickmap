# dev/archive — headings digest

Generated 2026-08-07. 42 unreferenced documents. Title and opening lines only, so a keep/cut decision can be made without opening them.

### 20251126_0924_CODE_REVIEW_v092.md  _(23 KB)_

**QuickMap v0.9.2 Layer Generalization - Code Review Report**

> **Date:** 2025-11-26 09:24 **Reviewer:** Automated Code Review Agent **Scope:** Logic review of v0.9.2 implementation
> ------------------------------------------------------------------------

### 251116_PLAN_TEMPLATE_CLOUD.md  _(6 KB)_

**Template for Drafting Step-by-Step Coding Plan**

> - Ideally in one succinct line. Example: A proof of concept HTML control for layer visibility in a leaflet map has been created. This correctly controls layer v
> - Clear statment of final objective. Example: "Adapt proof of concept code into a flexible, mobile/touch friendly, expanding/collapsing menu control with stylin

### 251123_CHANGE_NOTE__legend_redesign.md  _(7 KB)_

**Legend Refactor Implementation Summary - v0.9.0.3**

> **Date**: 2025-11-18
> **Version**: 0.9.0.3

### 251123_CHANGE_NOTE_streamline.md  _(8 KB)_

**Streamline Branch Summary**

> Streamlining of `quickmap.R` to improve maintainability, reduce complexity, and follow R package best practices. Removal of junk comments, inline CSS, HTML, JS,
> **Code Reduction:**

### 251123_OA_vs_QM_style_guide.md  _(28 KB)_

**---**

> editor_options:
>   markdown:

### 251123_OpenAir_Integration_Style_Guide.md  _(24 KB)_

**OpenAir Integration Style Guide**

> **Version:** 1.0  
> **Target:** Developers extending OpenAir functionality  

### 251123_PLAN_modern_r_practices.md  _(4 KB)_

**Task 4B: Modern R Practices Implementation**

> Modernize the QuickMap codebase by implementing contemporary R development practices including tidyverse consistency, comprehensive error handling, structured l
> - Implement tidyverse-consistent coding patterns and data manipulation

### 251123_PLAN_modular_architecture.md  _(3 KB)_

**Task 3A: Modular Architecture Enhancement**

> Split the monolithic quickmap.R file into focused, maintainable modules that separate concerns and improve code organization. This refactoring maintains all exi
> Transform the single 1800+ line file into a modular system with clear separation of responsibilities:

### 251125_Plan_v091_to_v095.md  _(22 KB)_

**QuickMap v0.9.1 → v0.9.5: Implementation Plan**

> **Date:** 2025-11-24 **Status:** Problem-oriented implementation roadmap **Timeline:** 8 weeks (2 weeks per version)
> ------------------------------------------------------------------------

### 251127_code_minimalism_rules.md  _(0 KB)_

**Code Minimalism Rules**

> **Avoid:**
> - cat() in user scripts

### 251129_DEPENDENCY_GRAPH.md  _(6 KB)_

**QuickMap Function Dependency Graph**

> ```
> create_pollution_map()

### 251129_PARAMETER_REFERENCE.md  _(13 KB)_

**create_pollution_map() Parameter Reference**

> -   **Type:** String
> -   **Default:** `"none"`

### 260113_rdata_duck_typing_options.md  _(13 KB)_

**RData Duck Typing Implementation Options**

> ```r
> load_rdata_file <- function(file_path, pollutant) {

### 260705_permissions_pretest_original.md  _(2 KB)_

**Permissions pre-Test approach**

> \## This is a PERMISSIONS TEST, not real work. Execute the numbered steps below in
> order, in the QuickMap repo. Before EACH step, output the step number and name

### ANALYSIS_config_system_issues.md  _(6 KB)_

**Analysis: YAML Config System Issues**

> **Date:** 2025-11-25 **Context:** Step 6 testing revealed two design issues in the YAML config system
> YAML configs only allow reference to ONE pollutant via `pollutant_col` field:

### ANALYSIS_create_pollution_map_refactor.md  _(7 KB)_

**Analysis: create_pollution_map() Refactoring Opportunities**

> **Current State:** 185 lines (1706-1890), single monolithic function
> **Goal:** Simplify, clarify, shorten, make tidyverse-compliant, extract reusable functions

### ANALYSIS_function_naming_review.md  _(10 KB)_

**Function Naming Review - Single-Use Helper Functions**

> **Date:** 2025-11-26
> **Version:** QuickMap v0.9.2

### ANALYSIS_local_data_caching.md  _(2 KB)_

**Local Data Caching Feasibility Analysis (v0.9.3)**

> **Current approach (session metadata cache) is optimal for v0.9.3.**
> Disk caching deferred to v0.9.4+ if needed. Full database NOT recommended.

### ANALYSIS_openair_essentials.md  _(3 KB)_

**OpenAir Converter Essentials**

> **For:** v0.9.3 converter implementation
> -   **openair** v2.18.2: Core air quality data import and analysis

### ANALYSIS_openair_structure.md  _(21 KB)_

**OpenAir Data Structure Analysis for v0.9.3 Converter**

> **Date:** 2025-11-26 **Purpose:** Document OpenAir API, data structures, and integration requirements for spatial converter
> -   **openair** v2.18.2: Core air quality data import and analysis

### ANALYSIS_single_use_functions.md  _(10 KB)_

**Single-Use Function Abstraction Review**

> **Date:** 2025-11-26
> **Version:** QuickMap v0.9.2

### CRITICAL_hardcoded_variables_issue.md  _(7 KB)_

**CRITICAL: Hardcoded Variable Names Break Config System**

> **Date:** 2025-11-25
> **Context:** User identified fundamental architectural flaw in v0.9.2 refactoring

### function_renames_v092.md  _(1 KB)_

**Function Renames - v0.9.2**

> **Date:** 2025-11-26
> Renamed 5 internal functions for clarity:

### Implementation_v092_Layer_Generalization.md  _(15 KB)_

**v0.9.2 Layer Generalization: Step-by-Step Implementation Plan**

> QuickMap v0.9.1 has three hardcoded layer types (dt_sites, bl_nodes, schools) with coupled parameters throughout R/quickmap.R lines 1249-1634. Adding new monito
> Refactor layer system to data-driven configuration where adding a new data source requires only a YAML config file, not code modification. System must support u

### ISSUE_bl_nodes_config.md  _(2 KB)_

**Issue: BL Nodes Config Mismatch**

> `bl_nodes.yaml` has `openair_import_function: null` but load logic treats null as "CSV with year columns", not "local RData".
> **bl_nodes.yaml line 13:** `openair_import_function: null`

### ISSUE_M2_static_pollutants_redundancy.md  _(2 KB)_

**M2: Redundant `static` Field - User Identified Issue**

> **Date:** 2025-11-26
> **Source:** User feedback during code review

### NOTE_m2_showGroup_behavior.md  _(2 KB)_

**m2: showGroup() Behavior Analysis - CORRECTED**

> **Date:** 2025-11-26
> **Location:** R/quickmap.R line 1790

### Option3_Analysis_Concise.md  _(10 KB)_

**Option 3: Hybrid Pipeline - Detailed Exploration**

> **Date:** 2025-11-23
> **Focus:** OpenAir ingestion, layer extensibility, informed by ecosystem research

### Option3_Detailed_Analysis.md  _(66 KB)_

**Option 3: Hybrid Pipeline with Early OpenAir Testing**

> **Document Version:** 1.0
> **Date:** 2025-11-23

### Options_analysis_091_095.md  _(6 KB)_

**Options Analysis: QuickMap v0.9.1 → v0.9.5**

> QuickMap v0.9.1 is a functional, well-structured monolithic codebase generating dynamic HTML+JPG maps from air quality data. Current architecture: `create_pollu
> Create `convertOpenAirToSpatial()` helper that transforms OpenAir format (date-indexed data.frame with site/pollutant columns) to sf objects matching quickmap's

### OPTIONS_MODERN_R_REMAINING.md  _(8 KB)_

**Modern R & Tidyverse Best Practices Analysis**

> **Current (lines 608, 1384, 1387, 1498):**
> ```r

### OPTIONS_streamline2.md  _(25 KB)_

**Streamline Phase 2: Options Analysis**

> **Date:** 2025-01-22
> **Current State:** R/quickmap_clean.R (2,295 lines, 59 functions)

### PLAN_configuration_system_251014.md  _(3 KB)_

**Task 2ABC: Comprehensive Configuration System Enhancement**

> Create a robust, multi-layered configuration system that addresses hardcoded values, implements comprehensive settings management, and provides excellent parame
> This task combines three complementary approaches:

### PLAN_modernization_outline_level_251122.md  _(33 KB)_

**QuickMap Modernization Outline Plan**

> **Date**: 2025-11-18
> **Current Version**: 0.9.0.2

### PLAN_remove_yaml_configs.md  _(2 KB)_

**Remove YAML Data Source Configs - Implementation Plan**

> - ✓ `inst/config/data_sources/*.yaml` (5 files)
> - `load_data_source_config()` (lines 729-758)

### restart_note.md  _(1 KB)_

**Restart Note - v0.9.3 OpenAir Converter**

> **Review Plan:** `dev/Implementation_v093_OpenAir_Converter.md`
> **Review for context:** `dev/ANALYSIS_openair_essentials.md`

### RETROSPECTIVE_v092_methods.md  _(15 KB)_

**v0.9.2 Collaboration Methods Review**

> **Date:** 2025-11-26
> **Duration:** Multiple sessions across 2 days

### roadmap091_095.md  _(10 KB)_

**Quickmap v0.9.1 → v0.9.5 Roadmap**

> **Date:** 2025-11-23
> **Status:** Planning Phase

### Todays_task_2.md  _(4 KB)_

**Context: Quickmap.R is a well-structured monolithic codebase that combines leaflet, JS, HTML and YAML technolgies, to ingests air pollution data or other time varying location based information and creates dynamic, time varying maps of it in HTML, with JPG export capability, styled using highly customisable themes. It is 100% functional but still in development at v0.9.1. **

> Ahead of release as a full R library at version 1.0, the medium term goals by v0.9.5 are to:
> - modularise the main function create_pollution_map

### Todays_task.md  _(4 KB)_

**Context: Quickmap.R is a well-structured monolithic codebase that combines leaflet, JS, HTML and YAML technolgies, to ingests air pollution data or other time varying location based information and creates dynamic, time varying maps of it in HTML, with JPG export capability, styled using highly customisable themes. It is 100% functional but still in development at v0.9.1. **

> Ahead of release as a full R library at version 1.0, the medium term goals by v0.9.5 are to:
> - modularise the main function create_pollution_map

### TRYCATCH_ANALYSIS.md  _(7 KB)_

**tryCatch Usage Analysis**

> 7 tryCatch blocks found. 3 are useful, 4 are redundant wrapper patterns.
> ```r

### v0.9.0_parameter_changes.md  _(5 KB)_

**QuickMap v0.9.0 Parameter Changes**

> **Date:** 2025-10-28
> **Version:** 0.8.11 → 0.9.0

