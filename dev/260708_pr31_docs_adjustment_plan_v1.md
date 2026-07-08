# Plan: adjust the PR #31 manual pages for the shape change (PR #32)

**Date:** 2026-07-08 · **Status:** awaiting user approval
**Problem:** the manual pages awaiting review in PR #31 were written before
the shape fix in PR #32, so they describe behaviour that PR #32 changes.
If both merge as-is, the brand-new manual is wrong on day one.

## What is now wrong in PR #31

1. **Layers page, example comment** — says sensors draw as *squares*;
   after PR #32 they draw as *diamonds*.
2. **Layers page, screenshot** (`vignettes/figures/layers-multilayer.png`)
   — shows squares and plus signs; after PR #32 the same map shows
   diamonds and ✖ crosses.
3. **Layers page, "Full detail" shape bullet** — says
   "`qm_layer(shape = )` is recorded but not yet consumed"; after PR #32
   that is false, and the shape choice is now the *recommended* way,
   with the full symbol vocabulary (square, star, plus, triangle,
   stadium…) not just three names.
4. **Get started page** — unaffected (single circle layer, unchanged
   look); its screenshot needs no change. Verify only.
5. **Reference vignette** (`quickmap_reference.md`, merged on main) —
   its `data_symbols` row should mention that layer shapes are now the
   primary mechanism. One-line edit.

## The fix (one small follow-up, ~30 minutes)

Order of operations matters because the two open PRs are separate:

1. **You merge PR #32 first** (the shape change — sets the behaviour).
2. **I update the PR #31 branch** with:
   - corrected comment + shape bullet on the Layers page (now describing:
     shape on the layer is the norm; full vocabulary with friendly names;
     `data_symbols` as the map-level override);
   - one new rising example on the Layers page: choosing a shape
     (`qm_layer(my_data, shape = "star")`) — it slots naturally between
     the existing examples and shows off the new capability;
   - regenerated `layers-multilayer.png` screenshot (diamonds + crosses);
   - chunk harness + site rebuild rerun as verification.
3. **You review the small added diff on PR #31** (it will be a few dozen
   lines plus one image) and merge it once.

This way you review each thing exactly once and nothing merges stale.

## Alternative (rejected)

Updating PR #31 *before* PR #32 is merged would make the manual describe
code that is not yet on main — if PR #32 were then amended or rejected,
the manual would be wrong in the other direction.

## Approval

Say "approve docs plan" (optionally with amendments) and step 2 executes
as soon as PR #32 is merged.
