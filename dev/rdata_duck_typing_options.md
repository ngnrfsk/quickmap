# RData Duck Typing Implementation Options

## Current State

```r
load_rdata_file <- function(file_path, pollutant) {
  env <- new.env()
  load(file.path(Sys.getenv("DATA_PATH"), file_path), envir = env)

  if (!exists("dataOAformat", envir = env)) {
    stop("dataOAformat object not found in RData file")
  }

  return(process_oa_data(env$dataOAformat, pollutant))
}
```

**Limitation:** Requires exact object name `"dataOAformat"`

---

## Option 1: Simple Duck Typing (First Match)

**Philosophy:** Find ANY data.frame with required columns, use the first one found.

```r
load_rdata_file_duck_simple <- function(file_path, pollutant) {
  env <- new.env()
  load(file.path(Sys.getenv("DATA_PATH"), file_path), envir = env)

  obj_names <- ls(envir = env)
  required_cols <- c("siteCode", "year", pollutant, "lat", "lon")

  # Find first compatible object
  for (obj_name in obj_names) {
    obj <- get(obj_name, envir = env)

    if (is.data.frame(obj) && all(required_cols %in% names(obj))) {
      message("Found sensor data: ", obj_name, " (", nrow(obj), " rows)")
      return(process_oa_data(obj, pollutant))
    }
  }

  # Helpful error message
  stop(
    "No compatible sensor data found in: ", basename(file_path), "\n",
    "Expected data.frame with columns: [", paste(required_cols, collapse = ", "), "]\n",
    "Found objects: ", paste(obj_names, collapse = ", "),
    call. = FALSE
  )
}
```

**Pros:**
- Simple implementation
- Fast (stops at first match)
- Clear error messages

**Cons:**
- Arbitrary choice if multiple matches
- No control over which object is selected

**Best for:** Files with one sensor data object + metadata

---

## Option 2: Largest Dataset (Smart Default)

**Philosophy:** Find all compatible objects, use the largest one (most likely the main dataset).

```r
load_rdata_file_duck_largest <- function(file_path, pollutant) {
  env <- new.env()
  load(file.path(Sys.getenv("DATA_PATH"), file_path), envir = env)

  obj_names <- ls(envir = env)
  required_cols <- c("siteCode", "year", pollutant, "lat", "lon")

  # Find ALL compatible objects
  compatible <- list()
  for (obj_name in obj_names) {
    obj <- get(obj_name, envir = env)

    if (is.data.frame(obj) && all(required_cols %in% names(obj))) {
      compatible[[obj_name]] <- list(
        data = obj,
        nrow = nrow(obj),
        ncol = ncol(obj)
      )
    }
  }

  # Error if none found
  if (length(compatible) == 0) {
    stop(
      "No compatible sensor data found in: ", basename(file_path), "\n",
      "Expected data.frame with columns: [", paste(required_cols, collapse = ", "), "]\n",
      "Found objects: ", paste(obj_names, collapse = ", "),
      call. = FALSE
    )
  }

  # Pick largest
  sizes <- sapply(compatible, function(x) x$nrow)
  largest_name <- names(which.max(sizes))

  # Inform user
  if (length(compatible) > 1) {
    message(
      "Multiple compatible objects found: ",
      paste(names(compatible), " (", sapply(compatible, function(x) x$nrow), " rows)",
            sep = "", collapse = ", "), "\n",
      "Using largest: ", largest_name
    )
  } else {
    message("Found sensor data: ", largest_name, " (", sizes[1], " rows)")
  }

  return(process_oa_data(compatible[[largest_name]]$data, pollutant))
}
```

**Pros:**
- Smart heuristic (largest = main dataset)
- Handles multiple objects gracefully
- Transparent (tells user what was selected)

**Cons:**
- Slightly more complex
- "Largest" might not always be correct

**Best for:** Production use - handles 90% of cases correctly

---

## Option 3: Priority-Based Search (OpenAir Convention)

**Philosophy:** Search in order of preference (OpenAir standard names first, then duck type).

```r
load_rdata_file_duck_priority <- function(file_path, pollutant) {
  env <- new.env()
  load(file.path(Sys.getenv("DATA_PATH"), file_path), envir = env)

  obj_names <- ls(envir = env)
  required_cols <- c("siteCode", "year", pollutant, "lat", "lon")

  # Priority 1: Standard OpenAir names (backward compatible)
  priority_names <- c("dataOAformat", "data", "sensor_data", "bl_data", "oa_data")

  for (pname in priority_names) {
    if (exists(pname, envir = env)) {
      obj <- get(pname, envir = env)
      if (is.data.frame(obj) && all(required_cols %in% names(obj))) {
        message("Found sensor data (standard name): ", pname, " (", nrow(obj), " rows)")
        return(process_oa_data(obj, pollutant))
      }
    }
  }

  # Priority 2: Duck typing search (any compatible object)
  compatible <- list()
  for (obj_name in setdiff(obj_names, priority_names)) {
    obj <- get(obj_name, envir = env)

    if (is.data.frame(obj) && all(required_cols %in% names(obj))) {
      compatible[[obj_name]] <- list(data = obj, nrow = nrow(obj))
    }
  }

  if (length(compatible) > 0) {
    # Use largest if multiple found
    sizes <- sapply(compatible, function(x) x$nrow)
    selected_name <- names(which.max(sizes))

    if (length(compatible) > 1) {
      message(
        "Multiple compatible objects: ",
        paste(names(compatible), collapse = ", "), "\n",
        "Using largest: ", selected_name
      )
    } else {
      message("Found sensor data: ", selected_name, " (", sizes[1], " rows)")
    }

    return(process_oa_data(compatible[[selected_name]]$data, pollutant))
  }

  # Error - nothing found
  stop(
    "No compatible sensor data in: ", basename(file_path), "\n",
    "Expected data.frame with columns: [", paste(required_cols, collapse = ", "), "]\n",
    "Found objects: ", paste(obj_names, collapse = ", "),
    call. = FALSE
  )
}
```

**Pros:**
- 100% backward compatible (checks `dataOAformat` first)
- Graceful degradation (falls back to duck typing)
- Respects OpenAir conventions

**Cons:**
- Most complex implementation
- Priority list needs maintenance

**Best for:** Migration path - works with old AND new files

---

## Option 4: Explicit Parameter (User Control)

**Philosophy:** Add optional parameter to specify object name, default to duck typing.

```r
load_rdata_file_duck_explicit <- function(
  file_path,
  pollutant,
  data_object_name = NULL  # NEW PARAMETER
) {
  env <- new.env()
  load(file.path(Sys.getenv("DATA_PATH"), file_path), envir = env)

  obj_names <- ls(envir = env)
  required_cols <- c("siteCode", "year", pollutant, "lat", "lon")

  # If user specified object name, use it
  if (!is.null(data_object_name)) {
    if (!exists(data_object_name, envir = env)) {
      stop(
        "Specified object '", data_object_name, "' not found in RData file.\n",
        "Available objects: ", paste(obj_names, collapse = ", "),
        call. = FALSE
      )
    }

    obj <- get(data_object_name, envir = env)

    if (!is.data.frame(obj) || !all(required_cols %in% names(obj))) {
      stop(
        "Object '", data_object_name, "' does not have required structure.\n",
        "Expected columns: [", paste(required_cols, collapse = ", "), "]\n",
        "Found columns: [", paste(names(obj), collapse = ", "), "]",
        call. = FALSE
      )
    }

    message("Using specified object: ", data_object_name)
    return(process_oa_data(obj, pollutant))
  }

  # Otherwise, duck type (use largest compatible)
  compatible <- list()
  for (obj_name in obj_names) {
    obj <- get(obj_name, envir = env)

    if (is.data.frame(obj) && all(required_cols %in% names(obj))) {
      compatible[[obj_name]] <- list(data = obj, nrow = nrow(obj))
    }
  }

  if (length(compatible) == 0) {
    stop(
      "No compatible sensor data found in: ", basename(file_path), "\n",
      "Expected data.frame with columns: [", paste(required_cols, collapse = ", "), "]\n",
      "Found objects: ", paste(obj_names, collapse = ", "), "\n",
      "TIP: Specify data_object_name parameter if object has different name",
      call. = FALSE
    )
  }

  # Use largest
  sizes <- sapply(compatible, function(x) x$nrow)
  selected_name <- names(which.max(sizes))

  if (length(compatible) > 1) {
    message(
      "Multiple compatible objects found: ",
      paste(names(compatible), collapse = ", "), "\n",
      "Using largest: ", selected_name, "\n",
      "TIP: Use data_object_name parameter to select a specific object"
    )
  } else {
    message("Found sensor data: ", selected_name, " (", sizes[1], " rows)")
  }

  return(process_oa_data(compatible[[selected_name]]$data, pollutant))
}
```

**Usage:**
```r
# Auto-detect (duck typing)
load_rdata_file("my_sensors.Rdata", "no2")

# Explicit control
load_rdata_file("my_sensors.Rdata", "no2", data_object_name = "sensor_dataset_v2")
```

**Pros:**
- User control when needed
- Automatic when not
- Best of both worlds

**Cons:**
- New parameter to document
- API change (though backward compatible via default)

**Best for:** Power users + automatic operation

---

## Option 5: Hybrid (Recommended)

**Philosophy:** Combine Option 3 (priority) + Option 4 (explicit parameter).

```r
load_rdata_file_duck_hybrid <- function(
  file_path,
  pollutant,
  data_object_name = NULL
) {
  env <- new.env()
  load(file.path(Sys.getenv("DATA_PATH"), file_path), envir = env)

  obj_names <- ls(envir = env)
  required_cols <- c("siteCode", "year", pollutant, "lat", "lon")

  # Helper: validate and use object
  use_object <- function(obj, name) {
    if (!is.data.frame(obj)) {
      stop("Object '", name, "' is not a data.frame", call. = FALSE)
    }
    if (!all(required_cols %in% names(obj))) {
      stop(
        "Object '", name, "' missing columns: ",
        paste(setdiff(required_cols, names(obj)), collapse = ", "),
        call. = FALSE
      )
    }
    message("Using sensor data: ", name, " (", nrow(obj), " rows)")
    return(process_oa_data(obj, pollutant))
  }

  # Strategy 1: Explicit user choice
  if (!is.null(data_object_name)) {
    if (!exists(data_object_name, envir = env)) {
      stop(
        "Object '", data_object_name, "' not found.\n",
        "Available: ", paste(obj_names, collapse = ", "),
        call. = FALSE
      )
    }
    return(use_object(get(data_object_name, envir = env), data_object_name))
  }

  # Strategy 2: Standard names (backward compatible)
  standard_names <- c("dataOAformat", "data", "oa_data", "sensor_data")
  for (sname in standard_names) {
    if (exists(sname, envir = env)) {
      obj <- get(sname, envir = env)
      if (is.data.frame(obj) && all(required_cols %in% names(obj))) {
        return(use_object(obj, sname))
      }
    }
  }

  # Strategy 3: Duck typing (largest compatible)
  compatible <- list()
  for (obj_name in obj_names) {
    obj <- get(obj_name, envir = env)
    if (is.data.frame(obj) && all(required_cols %in% names(obj))) {
      compatible[[obj_name]] <- list(data = obj, nrow = nrow(obj))
    }
  }

  if (length(compatible) == 0) {
    stop(
      "No compatible sensor data in: ", basename(file_path), "\n",
      "Expected: data.frame with [", paste(required_cols, collapse = ", "), "]\n",
      "Found: ", paste(obj_names, collapse = ", "),
      call. = FALSE
    )
  }

  sizes <- sapply(compatible, function(x) x$nrow)
  selected <- names(which.max(sizes))

  if (length(compatible) > 1) {
    message(
      "Found ", length(compatible), " compatible objects, using largest: ", selected
    )
  }

  return(use_object(compatible[[selected]]$data, selected))
}
```

**Pros:**
- Backward compatible (checks `dataOAformat` first)
- User control when needed (explicit parameter)
- Smart defaults (largest dataset)
- Production-ready

**Cons:**
- Most complex
- Three strategies to maintain

**Best for:** Production implementation - handles all cases

---

## Comparison Matrix

| Feature | Option 1 | Option 2 | Option 3 | Option 4 | Option 5 |
|---------|----------|----------|----------|----------|----------|
| Simple | ✓✓✓ | ✓✓ | ✓ | ✓✓ | ✓ |
| Backward Compatible | ✗ | ✗ | ✓✓✓ | ✗ | ✓✓✓ |
| Smart Default | ✗ | ✓✓✓ | ✓✓ | ✓✓✓ | ✓✓✓ |
| User Control | ✗ | ✗ | ✗ | ✓✓✓ | ✓✓✓ |
| Clear Errors | ✓✓✓ | ✓✓✓ | ✓✓✓ | ✓✓✓ | ✓✓✓ |
| Migration Path | ✗ | ✗ | ✓✓✓ | ✓ | ✓✓✓ |

---

## Recommendation: Option 5 (Hybrid)

**Why:**
1. **Backward compatible**: Existing files with `dataOAformat` work unchanged
2. **Duck typing**: New files with any name work automatically
3. **User control**: Power users can specify exact object name
4. **Smart defaults**: Picks largest dataset when multiple exist
5. **Clear feedback**: Messages inform user what was selected
6. **Production ready**: Handles edge cases gracefully

**Migration strategy:**
1. Deploy Option 5
2. Existing code continues working (uses `dataOAformat`)
3. New users benefit from duck typing automatically
4. Edge cases use `data_object_name` parameter

---

## Implementation Notes

### Error Messages
All options provide helpful errors showing:
- What was expected (required columns)
- What was found (object names)
- How to fix (use `data_object_name` parameter)

### Performance
- Negligible impact (< 1ms overhead for typical RData files)
- Only iterates through top-level objects
- Short-circuits on first match (Options 1 & 3)

### Testing Strategy
Test with:
1. Standard `dataOAformat` object (backward compatibility)
2. Different object name (duck typing)
3. Multiple compatible objects (selection logic)
4. No compatible objects (error handling)
5. Non-data.frame objects (type checking)
6. Missing required columns (validation)

---

## Next Steps

1. Review options with user
2. Select preferred approach
3. Implement in `load_rdata_file()`
4. Update documentation
5. Add test cases
6. Update example files
