(function() {
  document.addEventListener('DOMContentLoaded', function() {
    var years = ['2017', '2018', '2019', '2020', '2021', '2022', '2023', '2024'];

    document.getElementById("testBtn").addEventListener("click", function() {
      try {
        var mapDiv = document.querySelector(".leaflet-container");
        if (!mapDiv) {
          document.getElementById("testResult").innerHTML = "❌ FAIL: No .leaflet-container found";
          return;
        }

        var widgetContainer = mapDiv.closest("[id^=htmlwidget-]");
        if (!widgetContainer) {
          document.getElementById("testResult").innerHTML = "❌ FAIL: No HTMLWidget container found";
          return;
        }

        var widget = HTMLWidgets.find("#" + widgetContainer.id);
        if (!widget) {
          document.getElementById("testResult").innerHTML = "❌ FAIL: HTMLWidgets.find() returned null";
          return;
        }

        var map = widget;
        if (widget.getMap) map = widget.getMap();
        else if (widget.map) map = widget.map;
        else if (widget._map) map = widget._map;

        if (!map.eachLayer) {
          document.getElementById("testResult").innerHTML = "❌ FAIL: Cannot find Leaflet map object";
          return;
        }

        var groups = {};
        var totalLayers = 0;
        map.eachLayer(function(layer) {
          totalLayers++;
          if (layer.options && layer.options.group) {
            var g = layer.options.group;
            groups[g] = (groups[g] || 0) + 1;
          }
        });

        var groupInfo = JSON.stringify(groups, null, 2);
        document.getElementById("testResult").innerHTML =
          "✅ SUCCESS: Map accessible<br>" +
          "Total layers: " + totalLayers + "<br>" +
          "Groups: <pre style='margin:5px 0;'>" + groupInfo + "</pre>";

        console.log("Groups found:", groups);
      } catch(e) {
        document.getElementById("testResult").innerHTML = "❌ ERROR: " + e.message;
        console.error(e);
      }
    });

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

    document.getElementById("testSlider").addEventListener("input", function() {
      var index = parseInt(this.value);
      var selectedYear = years[index];
      document.getElementById("testYear").textContent = selectedYear;

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
        console.error("Slider control error:", e);
      }
    });
  });
})();
