(function() {
  document.addEventListener('DOMContentLoaded', function() {
    var yearControl = document.getElementById('yearControl');
    var yearButton = document.getElementById('yearButton');
    var yearList = document.getElementById('yearList');

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
  });
})();
