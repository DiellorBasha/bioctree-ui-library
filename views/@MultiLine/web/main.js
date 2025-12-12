/* MultiLine View Controller
 * Simplified lifecycle for views - DataChanged listener only
 * NO event dispatching - one-way data flow (MATLAB → JS)
 * 
 * Uses UMD pattern - render function is globally available from render.js
 */

// View lifecycle - called by MATLAB
function setup(htmlComponent) {
    console.log('[MultiLine] setup() called');
    
    // Get initial data from MATLAB
    var data = htmlComponent.Data;
    
    // Initial render
    renderMultiLine(data);
    
    // Listen for data changes from MATLAB (one-way only)
    htmlComponent.addEventListener("DataChanged", function(event) {
        console.log('[MultiLine] DataChanged event received');
        renderMultiLine(htmlComponent.Data);
    });
}

console.log('[MultiLine] Controller loaded');
