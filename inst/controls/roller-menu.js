(function() {
  console.log('Roller menu script loaded');

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

      // Re-apply non-focusable to any newly added map elements
      setTimeout(function() {
        var elements = document.querySelectorAll(
          '.leaflet-marker-icon, .leaflet-interactive, ' +
          '.leaflet-control-zoom-in, .leaflet-control-zoom-out, ' +
          '.leaflet-control a, .leaflet-control button'
        );
        elements.forEach(function(el) {
          el.setAttribute('tabindex', '-1');
        });
      }, 100);

    } catch(e) {
      console.error("Year control error:", e);
    }
  }

  function initializeYearControl() {
    console.log('initializeYearControl called, checking for layer cache...');

    // Wait for layer cache to be available
    if (!window.quickmapLayerCache) {
      console.log('Layer cache not ready, polling again in 100ms...');
      setTimeout(initializeYearControl, 100);
      return;
    }

    console.log('Layer cache found!', window.quickmapLayerCache);

    // Make all map elements non-focusable for better keyboard navigation
    // This allows Tab to reach year controls first
    function removeMapFocus() {
      var elements = document.querySelectorAll(
        '.leaflet-marker-icon, .leaflet-interactive, ' +
        '.leaflet-control-zoom-in, .leaflet-control-zoom-out, ' +
        '.leaflet-control a, .leaflet-control button'
      );
      elements.forEach(function(el) {
        el.setAttribute('tabindex', '-1');
      });
    }

    // Apply immediately and re-apply after layer changes
    setTimeout(removeMapFocus, 100);
    setTimeout(removeMapFocus, 500); // Catch late-loading markers

    var yearControl = document.getElementById('yearControl');
    var yearButton = document.getElementById('yearButton');
    var yearList = document.getElementById('yearList');
    var selectedYearSpan = document.getElementById('selectedYear');
    var playPauseButton = document.getElementById('playPauseButton');

    // Play/pause state
    var isPlaying = false;
    var playInterval = null;
    var currentIndex = 0;

    // Keyboard navigation state
    var keyboardFocusIndex = -1; // Track which year item has keyboard focus

    // Read config from R (injected via window.quickmapConfig) or use defaults
    var config = window.quickmapConfig || {autoplay: false, playSpeed: 500};
    var playSpeed = config.playSpeed;

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

    // Handle single year UI - hide play button and arrow, disable expansion
    if (years.length <= 1) {
      if (playPauseButton) {
        playPauseButton.classList.add('hidden');
      }
      // Hide arrow and mark as single-year mode
      yearControl.classList.add('single-year');
      console.log('Single year mode - play button and arrow hidden, expansion disabled');
    } else {
      console.log('DEBUG: Multiple years - full controls enabled, years.length =', years.length);
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

    // Toggle menu on button click (disabled in single-year mode)
    yearButton.addEventListener('click', function(e) {
      e.stopPropagation();

      // Don't expand if single year
      if (yearControl.classList.contains('single-year')) {
        return;
      }

      yearControl.classList.toggle('expanded');
      yearList.classList.toggle('show');

      // Scroll to selected year when opening
      if (yearControl.classList.contains('expanded')) {
        var selectedItem = yearList.querySelector('.year-item.selected');
        if (selectedItem) {
          // Use setTimeout to ensure menu is rendered before scrolling
          setTimeout(function() {
            selectedItem.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
          }, 50);
        }
      }
    });

    // Year button keyboard handler (Space/Enter)
    yearButton.addEventListener('keydown', function(e) {
      if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault(); // Prevent page scroll on Space

        // Don't expand if single year
        if (yearControl.classList.contains('single-year')) {
          return;
        }

        // If Enter pressed during arrow navigation, let document handler deal with it
        if (e.key === 'Enter' && keyboardFocusIndex !== -1) {
          return; // Don't toggle, let the selection handler fire
        }

        e.stopPropagation();
        yearControl.classList.toggle('expanded');
        yearList.classList.toggle('show');

        // Scroll to selected year when opening
        if (yearControl.classList.contains('expanded')) {
          var selectedItem = yearList.querySelector('.year-item.selected');
          if (selectedItem) {
            // Use setTimeout to ensure menu is rendered before scrolling
            setTimeout(function() {
              selectedItem.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
            }, 50);
          }
        }
      }
    });

    // Close menu when clicking outside
    document.addEventListener('click', function(e) {
      if (!yearControl.contains(e.target)) {
        yearControl.classList.remove('expanded');
        yearList.classList.remove('show');
      }
    });

    // Close menu on Escape key
    document.addEventListener('keydown', function(e) {
      if (e.key === 'Escape' && yearControl.classList.contains('expanded')) {
        yearControl.classList.remove('expanded');
        yearList.classList.remove('show');
        keyboardFocusIndex = -1; // Reset keyboard focus
      }
    });

    // Arrow key navigation
    document.addEventListener('keydown', function(e) {
      // Skip if single year mode
      if (yearControl.classList.contains('single-year')) {
        return;
      }

      var allItems = yearList.querySelectorAll('.year-item');

      if (e.key === 'ArrowDown' || e.key === 'ArrowUp') {
        e.preventDefault(); // Prevent page scroll

        if (yearControl.classList.contains('expanded')) {
          // Dropdown is open - navigate through items
          if (keyboardFocusIndex === -1) {
            // Initialize to current selected item
            keyboardFocusIndex = currentIndex;
          }

          // Move focus
          if (e.key === 'ArrowDown') {
            keyboardFocusIndex = (keyboardFocusIndex + 1) % years.length;
          } else {
            keyboardFocusIndex = (keyboardFocusIndex - 1 + years.length) % years.length;
          }

          // Update visual highlight
          allItems.forEach(function(item, index) {
            if (index === keyboardFocusIndex) {
              item.classList.add('keyboard-focused');
              item.scrollIntoView({ block: 'nearest', behavior: 'smooth' });
            } else {
              item.classList.remove('keyboard-focused');
            }
          });

        } else {
          // Dropdown is closed - cycle years directly
          if (e.key === 'ArrowDown') {
            currentIndex = (currentIndex + 1) % years.length;
          } else {
            currentIndex = (currentIndex - 1 + years.length) % years.length;
          }

          var newYear = years[currentIndex];
          selectedYearSpan.textContent = newYear;

          // Update selected class
          allItems.forEach(function(item, index) {
            if (index === currentIndex) {
              item.classList.add('selected');
            } else {
              item.classList.remove('selected');
            }
          });

          // Switch map layers
          switchToYear(newYear, years);
        }
      }

      // Enter key when dropdown is open - apply selection
      if (e.key === 'Enter' && yearControl.classList.contains('expanded')) {
        e.preventDefault();

        if (keyboardFocusIndex !== -1) {
          var selectedYear = years[keyboardFocusIndex];
          currentIndex = keyboardFocusIndex;

          // Update display
          selectedYearSpan.textContent = selectedYear;

          // Update selected class
          allItems.forEach(function(item, index) {
            if (index === keyboardFocusIndex) {
              item.classList.add('selected');
              item.classList.remove('keyboard-focused');
            } else {
              item.classList.remove('selected');
              item.classList.remove('keyboard-focused');
            }
          });

          // Switch map layers
          switchToYear(selectedYear, years);

          // Close dropdown
          yearControl.classList.remove('expanded');
          yearList.classList.remove('show');
          keyboardFocusIndex = -1;
        }
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

    // Play/pause button keyboard handler (Space/Enter)
    playPauseButton.addEventListener('keydown', function(e) {
      if (e.key === ' ' || e.key === 'Enter') {
        e.preventDefault(); // Prevent page scroll on Space
        e.stopPropagation();
        togglePlayPause();
      }
    });

    // Cleanup interval on page unload to prevent memory leaks
    window.addEventListener('beforeunload', function() {
      if (playInterval) {
        clearInterval(playInterval);
        playInterval = null;
      }
    });

    // Pause animation when page becomes hidden (tab switch, minimize, etc.)
    // Resume when page becomes visible again
    // Cross-browser support with vendor prefixes
    var hidden, visibilityChange;
    if (typeof document.hidden !== "undefined") {
      hidden = "hidden";
      visibilityChange = "visibilitychange";
    } else if (typeof document.webkitHidden !== "undefined") {
      hidden = "webkitHidden";
      visibilityChange = "webkitvisibilitychange";
    } else if (typeof document.mozHidden !== "undefined") {
      hidden = "mozHidden";
      visibilityChange = "mozvisibilitychange";
    } else if (typeof document.msHidden !== "undefined") {
      hidden = "msHidden";
      visibilityChange = "msvisibilitychange";
    }

    if (typeof document[hidden] !== "undefined") {
      document.addEventListener(visibilityChange, function() {
        if (document[hidden]) {
          // Page hidden - pause if playing
          if (isPlaying && playInterval) {
            clearInterval(playInterval);
            playInterval = null;
            console.log('Animation paused - page hidden');
          }
        } else {
          // Page visible - resume if was playing
          if (isPlaying && !playInterval) {
            playInterval = setInterval(advanceToNextYear, playSpeed);
            console.log('Animation resumed - page visible');
          }
        }
      });
    }

    // Start animation automatically if autoplay is enabled (and multiple years exist)
    if (config.autoplay && years.length > 1 && !yearControl.classList.contains('single-year')) {
      console.log('Autoplay enabled - starting animation');
      togglePlayPause(); // This will start the animation
    }

    console.log('Year control initialized with years:', years);
  }

  // Start initialization when DOM is ready
  console.log('Setting up initialization, document.readyState =', document.readyState);
  if (document.readyState === 'loading') {
    console.log('Document still loading, adding DOMContentLoaded listener');
    document.addEventListener('DOMContentLoaded', initializeYearControl);
  } else {
    console.log('Document ready, initializing immediately');
    initializeYearControl();
  }
})();
