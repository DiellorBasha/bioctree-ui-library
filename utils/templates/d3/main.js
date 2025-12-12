/* {{COMPONENT_NAME}} Component Controller
 * Manages lifecycle, data flow, and MATLAB communication
 * 
 * D3.js Version: 5.9.2
 * Event Model: D3 v5 (uses d3.event global)
 */

// Component lifecycle - called by MATLAB
function setup(htmlComponent) {
    console.log('[{{COMPONENT_NAME}}] setup() called');
    console.log('[{{COMPONENT_NAME}}] htmlComponent:', htmlComponent);
    console.log('[{{COMPONENT_NAME}}] Initial Data:', htmlComponent.Data);
    
    try {
        // Get initial data from MATLAB
        var data = htmlComponent.Data;
        
        // Initial render
        console.log('[{{COMPONENT_NAME}}] Calling {{RENDER_FUNCTION}}...');
        {{RENDER_FUNCTION}}(data, htmlComponent);
        console.log('[{{COMPONENT_NAME}}] {{RENDER_FUNCTION}} initiated');
        
        // Listen for data changes from MATLAB (when properties are updated)
        htmlComponent.addEventListener("DataChanged", function(event) {
            console.log('[{{COMPONENT_NAME}}] DataChanged event received - redrawing');
            var newData = htmlComponent.Data;
            console.log('[{{COMPONENT_NAME}}] New Data:', newData);
            
            // Redraw with updated data
            {{RENDER_FUNCTION}}(newData, htmlComponent);
        });
        
        console.log('[{{COMPONENT_NAME}}] Setup complete, ready for interaction');
    } catch (error) {
        console.error('[{{COMPONENT_NAME}}] Error in setup():', error);
        console.error('[{{COMPONENT_NAME}}] Stack:', error.stack);
    }
}

console.log('[{{COMPONENT_NAME}}] Controller loaded, waiting for MATLAB to call setup()...');
