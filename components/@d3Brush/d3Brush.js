/* d3Brush Component Controller
 * Manages lifecycle, data flow, and MATLAB communication
 * 
 * D3.js Version: 5.9.2
 * Event Model: D3 v5 (uses d3.event global)
 */

// Component lifecycle - called by MATLAB
function setup(htmlComponent) {
    console.log('[d3Brush] setup() called');
    console.log('[d3Brush] htmlComponent:', htmlComponent);
    console.log('[d3Brush] Initial Data:', htmlComponent.Data);
    
    try {
        // Get initial data from MATLAB
        var data = htmlComponent.Data;
        
        // Draw the brush with initial data
        console.log('[d3Brush] Calling renderBrush...');
        renderBrush(data, htmlComponent);
        console.log('[d3Brush] renderBrush completed');
        
        // Listen for data changes from MATLAB (when properties are updated)
        htmlComponent.addEventListener("DataChanged", function(event) {
            console.log('[d3Brush] DataChanged event received - redrawing brush');
            var newData = htmlComponent.Data;
            console.log('[d3Brush] New Data:', newData);
            
            // Redraw the brush with updated data
            renderBrush(newData, htmlComponent);
        });
        
        console.log('[d3Brush] Setup complete, ready for interaction');
    } catch (error) {
        console.error('[d3Brush] Error in setup():', error);
        console.error('[d3Brush] Stack:', error.stack);
    }
}

console.log('[d3Brush] Controller loaded, waiting for MATLAB to call setup()...');
