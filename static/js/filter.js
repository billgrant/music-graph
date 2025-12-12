/**
 * Genre Filter - Filters multi-select dropdowns as user types
 *
 * Usage: Add a text input with class="genre-filter" and data-target="selectId"
 * where selectId matches the id of the <select> element to filter.
 */
document.addEventListener('DOMContentLoaded', function() {
    // Find all filter inputs on the page
    const filterInputs = document.querySelectorAll('.genre-filter');

    // Set up filtering for each one
    filterInputs.forEach(function(input) {
        // Get the id of the select box this filter controls
        const selectId = input.dataset.target;
        const select = document.getElementById(selectId);

        // Skip if select not found (misconfigured data-target)
        if (!select) {
            console.warn('Filter target not found:', selectId);
            return;
        }

        // Listen for typing in the filter input
        input.addEventListener('input', function() {
            // Get filter text, lowercase for case-insensitive matching
            const filterText = input.value.toLowerCase();

            // Loop through all options in the select
            const options = select.querySelectorAll('option');
            options.forEach(function(option) {
                // Get option text, lowercase for comparison
                const text = option.textContent.toLowerCase();

                // Show if matches, hide if not
                if (text.includes(filterText)) {
                    option.style.display = '';  // Reset to default (visible)
                } else {
                    option.style.display = 'none';  // Hide
                }
            });
        });
    });
});
