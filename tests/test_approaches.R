# Test different approaches for adding divs above/below Leaflet map
# This file tests the complexity and feasibility of different methods

library(leaflet)
library(htmlwidgets)
library(htmltools)

# APPROACH 1: JavaScript DOM Manipulation via onRender
test_javascript_approach <- function() {
  map <- leaflet() %>%
    addTiles() %>%
    setView(lng = -0.1, lat = 51.5, zoom = 10)
  
  # Add JavaScript to manipulate DOM after rendering
  map <- map %>%
    htmlwidgets::onRender("
      function(el, x) {
        // Wait for map to be fully rendered
        setTimeout(function() {
          // Get the widget container
          var container = el.parentNode;
          
          // Create banner div
          var banner = document.createElement('div');
          banner.id = 'map-banner-js';
          banner.style.cssText = 'width: 100%; background: linear-gradient(90deg, #078141, #0a9d4a); color: white; text-align: center; padding: 15px; font-size: 18px; font-weight: bold;';
          banner.innerHTML = 'JavaScript Banner Above Map';
          
          // Create footer div
          var footer = document.createElement('div');
          footer.id = 'map-footer-js';
          footer.style.cssText = 'width: 100%; height: 100px; background-color: #f8f9fa; border-top: 1px solid #dee2e6; display: flex; align-items: center; justify-content: center; font-size: 14px; color: #6c757d;';
          footer.innerHTML = 'JavaScript Footer Below Map';
          
          // Insert banner before the map container
          container.parentNode.insertBefore(banner, container);
          
          // Insert footer after the map container
          container.parentNode.insertBefore(footer, container.nextSibling);
          
          // Adjust container styling for layout
          container.style.flex = '1';
          container.parentNode.style.display = 'flex';
          container.parentNode.style.flexDirection = 'column';
          container.parentNode.style.height = '100vh';
          
        }, 100);
      }
    ")
  
  return(map)
}

# APPROACH 2: htmltools wrapper (pre-render)
test_htmltools_approach <- function() {
  map <- leaflet() %>%
    addTiles() %>%
    setView(lng = -0.1, lat = 51.5, zoom = 10)
  
  # Try to wrap the map in htmltools structure
  banner <- tags$div(
    id = "map-banner-html",
    style = "width: 100%; background: linear-gradient(90deg, #078141, #0a9d4a); color: white; text-align: center; padding: 15px; font-size: 18px; font-weight: bold;",
    "htmltools Banner Above Map"
  )
  
  footer <- tags$div(
    id = "map-footer-html", 
    style = "width: 100%; height: 100px; background-color: #f8f9fa; border-top: 1px solid #dee2e6; display: flex; align-items: center; justify-content: center; font-size: 14px; color: #6c757d;",
    "htmltools Footer Below Map"
  )
  
  # Wrap in container
  wrapper <- tags$div(
    style = "display: flex; flex-direction: column; height: 100vh;",
    banner,
    tags$div(style = "flex: 1;", map),
    footer
  )
  
  return(wrapper)
}

# APPROACH 3: Custom HTML template with post-processing
test_template_approach <- function() {
  map <- leaflet() %>%
    addTiles() %>%
    setView(lng = -0.1, lat = 51.5, zoom = 10)
  
  # Store template info as attributes
  attr(map, "custom_template") <- list(
    banner_html = '<div id="map-banner-template" style="width: 100%; background: linear-gradient(90deg, #078141, #0a9d4a); color: white; text-align: center; padding: 15px; font-size: 18px; font-weight: bold;">Template Banner Above Map</div>',
    footer_html = '<div id="map-footer-template" style="width: 100%; height: 100px; background-color: #f8f9fa; border-top: 1px solid #dee2e6; display: flex; align-items: center; justify-content: center; font-size: 14px; color: #6c757d;">Template Footer Below Map</div>'
  )
  
  return(map)
}

# Function to apply template post-processing
apply_template_post_processing <- function(html_file, map_object) {
  template_info <- attr(map_object, "custom_template")
  if (is.null(template_info)) return()
  
  html_content <- readLines(html_file)
  
  # Add CSS for layout
  css <- '
  <style>
    body { margin: 0; padding: 0; height: 100vh; overflow: hidden; }
    .template-wrapper { height: 100vh; display: flex; flex-direction: column; }
    .template-map-container { flex: 1; display: flex; flex-direction: column; }
    #htmlwidget_container { flex: 1; }
    .leaflet-container { height: 100% !important; }
  </style>
  '
  
  # Insert CSS
  html_content <- gsub("</head>", paste0(css, "</head>"), html_content)
  
  # Find body and wrap content
  body_start <- grep("<body", html_content)
  body_end <- grep("</body>", html_content)
  
  if (length(body_start) > 0 && length(body_end) > 0) {
    body_content <- html_content[(body_start + 1):(body_end - 1)]
    
    new_body <- c(
      html_content[body_start],
      '<div class="template-wrapper">',
      template_info$banner_html,
      '<div class="template-map-container">',
      body_content,
      '</div>',
      template_info$footer_html,
      '</div>',
      html_content[body_end]
    )
    
    html_content <- c(
      html_content[1:(body_start - 1)],
      new_body,
      html_content[(body_end + 1):length(html_content)]
    )
  }
  
  writeLines(html_content, html_file)
}

# APPROACH 4: Using browsable() with htmltools
test_browsable_approach <- function() {
  map <- leaflet() %>%
    addTiles() %>%
    setView(lng = -0.1, lat = 51.5, zoom = 10)
  
  banner <- tags$div(
    style = "width: 100%; background: linear-gradient(90deg, #078141, #0a9d4a); color: white; text-align: center; padding: 15px; font-size: 18px; font-weight: bold;",
    "Browsable Banner Above Map"
  )
  
  footer <- tags$div(
    style = "width: 100%; height: 100px; background-color: #f8f9fa; border-top: 1px solid #dee2e6; display: flex; align-items: center; justify-content: center; font-size: 14px; color: #6c757d;",
    "Browsable Footer Below Map"
  )
  
  # Create browsable HTML
  page <- tags$div(
    style = "display: flex; flex-direction: column; height: 100vh;",
    banner,
    tags$div(style = "flex: 1;", map),
    footer
  )
  
  return(browsable(page))
}

# Test all approaches
cat("Testing different approaches for adding divs above/below Leaflet map...\n\n")

# Test JavaScript approach
cat("1. Testing JavaScript DOM manipulation approach...\n")
js_map <- test_javascript_approach()
saveWidget(js_map, "test_javascript.html", selfcontained = TRUE)
cat("   - Saved to test_javascript.html\n")
cat("   - Complexity: Medium (requires JavaScript knowledge)\n")
cat("   - Reliability: Good (works after DOM is ready)\n\n")

# Test htmltools approach
cat("2. Testing htmltools wrapper approach...\n")
tryCatch({
  html_map <- test_htmltools_approach()
  # This might fail due to widget dependency issues
  saveWidget(html_map, "test_htmltools.html", selfcontained = TRUE)
  cat("   - Saved to test_htmltools.html\n")
  cat("   - Complexity: High (widget dependency conflicts)\n")
  cat("   - Reliability: Poor (breaks widget rendering)\n")
}, error = function(e) {
  cat("   - FAILED:", e$message, "\n")
  cat("   - Complexity: High (widget dependency conflicts)\n")
  cat("   - Reliability: Poor (breaks widget rendering)\n")
})
cat("\n")

# Test template approach
cat("3. Testing template post-processing approach...\n")
template_map <- test_template_approach()
saveWidget(template_map, "test_template.html", selfcontained = TRUE)
apply_template_post_processing("test_template.html", template_map)
cat("   - Saved to test_template.html\n")
cat("   - Complexity: Medium-High (HTML parsing required)\n")
cat("   - Reliability: Medium (depends on HTML structure)\n\n")

# Test browsable approach
cat("4. Testing browsable() approach...\n")
tryCatch({
  browsable_page <- test_browsable_approach()
  # Save using htmltools
  html_file <- "test_browsable.html"
  save_html(browsable_page, html_file)
  cat("   - Saved to test_browsable.html\n")
  cat("   - Complexity: Low-Medium (uses htmltools)\n")
  cat("   - Reliability: Good (designed for this purpose)\n")
}, error = function(e) {
  cat("   - FAILED:", e$message, "\n")
  cat("   - May require different saving method\n")
})

cat("\nAll tests completed. Check the generated HTML files to see results.\n")

