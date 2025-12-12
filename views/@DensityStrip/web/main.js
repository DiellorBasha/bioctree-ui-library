/* DensityStrip View Controller
 * Simplified lifecycle for views - DataChanged listener only
 * NO event dispatching - one-way data flow (MATLAB → JS)
 * 
 * Uses UMD pattern - renderDensity is globally available from render.js
 */

// View lifecycle - called by MATLAB
function setup(htmlComponent) {
    console.log('[DensityStrip] setup() called');
    
    // Get initial data from MATLAB
    var data = htmlComponent.Data;
    
    // Initial render
    renderDensity(data);
    
    // Listen for data changes from MATLAB (one-way only)
    htmlComponent.addEventListener("DataChanged", function(event) {
        console.log('[DensityStrip] DataChanged event received');
        renderDensity(htmlComponent.Data);
    });
}

console.log('[DensityStrip] Controller loaded');
