(function() {
  var cachedMap = null;

  function getMapInstance() {
    if (cachedMap) return cachedMap;

    var mapDiv = document.querySelector(".leaflet-container");
    var widgetContainer = mapDiv.closest("[id^=htmlwidget-]");
    var widget = HTMLWidgets.find("#" + widgetContainer.id);

    cachedMap = widget;
    if (widget.getMap) cachedMap = widget.getMap();
    else if (widget.map) cachedMap = widget.map;
    else if (widget._map) cachedMap = widget._map;

    return cachedMap;
  }

  function switchToYear(selectedYear, years) {
    try {
      if (!window.quickmapLayerCache) {
        console.error("window.quickmapLayerCache not found");
        return;
      }

      var map = getMapInstance();
      var layerCache = window.quickmapLayerCache;

      var added = 0, removed = 0;
      years.forEach(function(yr) {
        if (!layerCache[yr]) return;

        layerCache[yr].forEach(function(layer) {
          if (yr === selectedYear) {
            if (!map.hasLayer(layer)) {
              map.addLayer(layer);
              added++;
            }
          } else {
            if (map.hasLayer(layer)) {
              map.removeLayer(layer);
              removed++;
            }
          }
        });
      });
      console.log("Year switched to", selectedYear, "- Added:", added, "Removed:", removed);

    } catch(e) {
      console.error("Year control error:", e);
    }
  }

  function initializeYearControl() {
    // Wait for layer cache to be available
    if (!window.quickmapLayerCache) {
      setTimeout(initializeYearControl, 100);
      return;
    }

    var yearControl = document.getElementById('yearControl');
    var yearButton = document.getElementById('yearButton');
    var yearList = document.getElementById('yearList');
    var selectedYearSpan = document.getElementById('selectedYear');

    // Extract years from layer cache and sort
    var years = Object.keys(window.quickmapLayerCache).sort(function(a, b) {
      return parseInt(a) - parseInt(b);
    });

    if (years.length === 0) {
      console.warn('No years found in layer cache');
      return;
    }

    // Find latest year (last in sorted array)
    var latestYear = years[years.length - 1];

    // Populate year list
    years.forEach(function(year) {
      var yearItem = document.createElement('div');
      yearItem.className = 'year-item';
      yearItem.setAttribute('data-year', year);
      yearItem.textContent = year;

      // Add click handler for layer switching
      yearItem.addEventListener('click', function() {
        var clickedYear = this.getAttribute('data-year');

        // Update selected year display
        selectedYearSpan.textContent = clickedYear;

        // Switch map layers
        switchToYear(clickedYear, years);

        // Close menu
        yearControl.classList.remove('expanded');
        yearList.classList.remove('show');
      });

      yearList.appendChild(yearItem);
    });

    // Set initial selected year to latest
    selectedYearSpan.textContent = latestYear;

    // Toggle menu on button click
    yearButton.addEventListener('click', function(e) {
      e.stopPropagation();
      yearControl.classList.toggle('expanded');
      yearList.classList.toggle('show');
    });

    // Close menu when clicking outside
    document.addEventListener('click', function(e) {
      if (!yearControl.contains(e.target)) {
        yearControl.classList.remove('expanded');
        yearList.classList.remove('show');
      }
    });

    console.log('Year control initialized with years:', years);
  }

  // Start initialization when DOM is ready
  if (document.readyState === 'loading') {
    document.addEventListener('DOMContentLoaded', initializeYearControl);
  } else {
    initializeYearControl();
  }
})();
