/* {{COMPONENT_NAME}} View Controller
 * Simplified lifecycle for views - DataChanged listener only
 * NO event dispatching - one-way data flow (MATLAB → JS)
 * 
 * Uses UMD pattern - render function is globally available from render.js
 */

// View lifecycle - called by MATLAB
function setup(htmlComponent) {
    console.log('[{{COMPONENT_NAME}}] setup() called');
    
    // Get initial data from MATLAB
    var data = htmlComponent.Data;
    
    // Initial render
    {{RENDER_FUNCTION}}(data);
    
    // Listen for data changes from MATLAB (one-way only)
    htmlComponent.addEventListener("DataChanged", function(event) {
        console.log('[{{COMPONENT_NAME}}] DataChanged event received');
        {{RENDER_FUNCTION}}(htmlComponent.Data);
    });
}

console.log('[{{COMPONENT_NAME}}] Controller loaded');
