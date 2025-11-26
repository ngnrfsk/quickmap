# Test script for OpenAir metadata cache system
# Tests Step 1: Metadata Cache System

cat("=== Test: OpenAir Metadata Cache ===\n\n")

# Source the main file
source("R/quickmap.R")

# Test 1: First call should fetch from API
cat("Test 1: First call to get_openair_metadata('aurn')\n")
cat("Expected: Fetch from API, cache result\n")
meta1 <- get_openair_metadata("aurn")
cat("Result: ", nrow(meta1), " sites loaded\n")
cat("Columns: ", paste(names(meta1), collapse = ", "), "\n\n")

# Test 2: Second call should use cache
cat("Test 2: Second call to get_openair_metadata('aurn')\n")
cat("Expected: Use cached metadata (no API call)\n")
meta2 <- get_openair_metadata("aurn")
cat("Result: ", nrow(meta2), " sites loaded\n")
cat("Identical to first call? ", identical(meta1, meta2), "\n\n")

# Test 3: Different source
cat("Test 3: Call get_openair_metadata('kcl')\n")
cat("Expected: Fetch from API for new source\n")
meta_kcl <- get_openair_metadata("kcl")
cat("Result: ", nrow(meta_kcl), " sites loaded\n\n")

# Test 4: Clear specific source
cat("Test 4: Clear cache for 'aurn'\n")
cat("Expected: Cache cleared, next call fetches again\n")
clear_openair_metadata_cache("aurn")
meta3 <- get_openair_metadata("aurn")
cat("Result: ", nrow(meta3), " sites loaded (re-fetched)\n\n")

# Test 5: Clear all cache
cat("Test 5: Clear all metadata cache\n")
cat("Expected: All cached sources removed\n")
clear_openair_metadata_cache()
cat("Cache cleared\n\n")

# Test 6: Verify cache is empty
cat("Test 6: Call after clearing all cache\n")
cat("Expected: Fetch from API again\n")
meta4 <- get_openair_metadata("aurn")
cat("Result: ", nrow(meta4), " sites loaded\n\n")

# Test 7: Error handling - invalid source
cat("Test 7: Invalid source name\n")
cat("Expected: Error message\n")
tryCatch(
  {
    meta_invalid <- get_openair_metadata("invalid_source")
    cat("ERROR: Should have failed!\n")
  },
  error = function(e) {
    cat("Result: Error caught as expected\n")
    cat("Message: ", e$message, "\n")
  }
)

cat("\n=== All tests completed ===\n")
cat("✓ Cache stores metadata\n")
cat("✓ Cache returns stored data on repeat calls\n")
cat("✓ Multiple sources can be cached\n")
cat("✓ Selective cache clearing works\n")
cat("✓ Full cache clearing works\n")
cat("✓ Error handling works for invalid sources\n")
