/**
 * Main controller for ManifoldBrushToolbar
 * Called by MATLAB when component is initialized
 */
function setup(htmlComponent) {
    // console.log('[ManifoldBrushToolbar] Setup started');
    
    // Initial render
    if (htmlComponent.Data) {
        renderToolbar(htmlComponent.Data, htmlComponent);
    }
    
    // Listen for data changes from MATLAB
    htmlComponent.addEventListener("DataChanged", function(event) {
        // console.log('[ManifoldBrushToolbar] Data changed');
        renderToolbar(htmlComponent.Data, htmlComponent);
    });
    
    // console.log('[ManifoldBrushToolbar] Setup complete');
}
