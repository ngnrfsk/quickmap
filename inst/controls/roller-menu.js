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
    var playPauseButton = document.getElementById('playPauseButton');

    // Play/pause state
    var isPlaying = false;
    var playInterval = null;
    var currentIndex = 0;
    var playSpeed = 500; // milliseconds per year

    // Extract years from layer cache and sort
    var years = Object.keys(window.quickmapLayerCache).sort(function(a, b) {
      return parseInt(a) - parseInt(b);
    });

    console.log('DEBUG: Years found in layer cache:', years);
    console.log('DEBUG: Years count:', years.length);
    console.log('DEBUG: Play button element exists:', !!playPauseButton);

    if (years.length === 0) {
      console.warn('No years found in layer cache');
      return;
    }

    // Hide play button if only one year (nothing to animate)
    if (years.length <= 1 && playPauseButton) {
      playPauseButton.classList.add('hidden');
      console.log('Play button hidden - only', years.length, 'year(s) available');
    } else {
      console.log('DEBUG: Not hiding play button - years.length =', years.length);
    }

    // Find latest year (last in sorted array)
    var latestYear = years[years.length - 1];

    // Populate year list
    years.forEach(function(year) {
      var yearItem = document.createElement('div');
      yearItem.className = 'year-item';
      yearItem.setAttribute('data-year', year);
      yearItem.textContent = year;

      // Mark latest year as selected initially
      if (year === latestYear) {
        yearItem.classList.add('selected');
      }

      // Add click handler for layer switching
      yearItem.addEventListener('click', function() {
        var clickedYear = this.getAttribute('data-year');

        // Pause animation if playing
        if (isPlaying) {
          isPlaying = false;
          playPauseButton.textContent = '▶';
          if (playInterval) {
            clearInterval(playInterval);
            playInterval = null;
          }
        }

        // Update current index to match clicked year
        currentIndex = years.indexOf(clickedYear);

        // Remove selected class from all items
        var allItems = yearList.querySelectorAll('.year-item');
        allItems.forEach(function(item) {
          item.classList.remove('selected');
        });

        // Add selected class to clicked item
        this.classList.add('selected');

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
    currentIndex = years.indexOf(latestYear);

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

    // Advance to next year in sequence
    function advanceToNextYear() {
      // Increment index with loop wrapping
      currentIndex = (currentIndex + 1) % years.length;
      var nextYear = years[currentIndex];

      // Update selected year display
      selectedYearSpan.textContent = nextYear;

      // Update dropdown selection highlight
      var allItems = yearList.querySelectorAll('.year-item');
      allItems.forEach(function(item) {
        if (item.getAttribute('data-year') === nextYear) {
          item.classList.add('selected');
        } else {
          item.classList.remove('selected');
        }
      });

      // Switch map layers
      switchToYear(nextYear, years);
    }

    // Toggle play/pause
    function togglePlayPause() {
      isPlaying = !isPlaying;
      playPauseButton.textContent = isPlaying ? '⏸' : '▶';

      if (isPlaying) {
        // Start animation
        playInterval = setInterval(advanceToNextYear, playSpeed);
      } else {
        // Stop animation
        if (playInterval) {
          clearInterval(playInterval);
          playInterval = null;
        }
      }
    }

    // Play/pause button click handler
    playPauseButton.addEventListener('click', function(e) {
      e.stopPropagation();
      togglePlayPause();
    });

    // Cleanup interval on page unload to prevent memory leaks
    window.addEventListener('beforeunload', function() {
      if (playInterval) {
        clearInterval(playInterval);
        playInterval = null;
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
