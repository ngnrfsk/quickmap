# dev/archive — proposed cut list

Date: 2026-08-07. For veto: say which rows to move the other way.

The 13 throwaway test scripts were already deleted. This covers the 42
unreferenced documents. Git keeps everything deleted, so nothing here is lost —
the question is only what stays visible in the working tree.

**Proposal: keep 5, cut 37.**

The test applied: does the document describe something that is still true, or
does it describe a codebase that no longer exists? Almost all of these were
written between November 2025 and January 2026, when `quickmap.R` was a
monolith, `create_pollution_map()` was the main entry point and there were YAML
data-source configs. All three are gone.

## Keep (5)

| File | KB | Why |
|---|---|---|
| `251123_OA_vs_QM_style_guide.md` | 28 | OpenAir's conventions against QuickMap's. Still live: the stated v2 direction is QuickMap as OpenAir's spatial companion |
| `251123_OpenAir_Integration_Style_Guide.md` | 24 | The same ground for developers extending OpenAir. Feeds the post-1.0 ecosystem integrations |
| `ANALYSIS_openair_structure.md` | 21 | OpenAir's API and data structures, documented. `from_openair()` still depends on this being right, and the post-1.0 saqgetr/OpenAQ wrappers will |
| `ANALYSIS_openair_essentials.md` | 3 | The short version of the above |
| `260113_rdata_duck_typing_options.md` | 13 | Why RData duck typing works the way it does. The behaviour is live and documented in CLAUDE.md, but not the reasoning |

## Cut (37)

**Plans for work that was done, abandoned or superseded (13)**
`251116_PLAN_TEMPLATE_CLOUD.md`, `251123_PLAN_modern_r_practices.md`,
`251123_PLAN_modular_architecture.md`, `251125_Plan_v091_to_v095.md`,
`PLAN_configuration_system_251014.md`,
`PLAN_modernization_outline_level_251122.md`, `PLAN_remove_yaml_configs.md`,
`roadmap091_095.md`, `Todays_task.md`, `Todays_task_2.md`,
`Implementation_v092_Layer_Generalization.md`, `restart_note.md`,
`260705_permissions_pretest_original.md`

**Options papers for decisions long since taken (6)**
`Option3_Analysis_Concise.md`, `Option3_Detailed_Analysis.md` (66 KB, the
single largest), `Options_analysis_091_095.md`, `OPTIONS_MODERN_R_REMAINING.md`,
`OPTIONS_streamline2.md`, `ANALYSIS_local_data_caching.md`

**Analyses of code that has since been rewritten (9)**
`ANALYSIS_config_system_issues.md`,
`ANALYSIS_create_pollution_map_refactor.md`,
`ANALYSIS_function_naming_review.md`, `ANALYSIS_single_use_functions.md`,
`TRYCATCH_ANALYSIS.md`, `CRITICAL_hardcoded_variables_issue.md`,
`ISSUE_bl_nodes_config.md`, `ISSUE_M2_static_pollutants_redundancy.md`,
`NOTE_m2_showGroup_behavior.md`

**Change notes and reviews of released versions (6)**
`20251126_0924_CODE_REVIEW_v092.md`, `251123_CHANGE_NOTE__legend_redesign.md`,
`251123_CHANGE_NOTE_streamline.md`, `function_renames_v092.md`,
`RETROSPECTIVE_v092_methods.md`, `v0.9.0_parameter_changes.md`

**Superseded by something current (3)**
| File | Superseded by |
|---|---|
| `251127_code_minimalism_rules.md` | The "Code Minimalism" section of `CLAUDE.md`, which is the same content |
| `251129_PARAMETER_REFERENCE.md` | The roxygen documentation and `man/`, which are generated and cannot drift |
| `251129_DEPENDENCY_GRAPH.md` | Describes `create_pollution_map()` as the entry point; it is now a compatibility wrapper around `quickmap()` |

## The ten referenced files, not covered here

Left alone for now. Only two have a live referrer: `symbols_sampler.html` is the
output of `scripts/demos/symbols_chart.R`, and four are cited by
`dev/PROJECT_STATUS.md`. The rest are cited only by other historical documents,
so they can be reconsidered once the 37 are gone.
