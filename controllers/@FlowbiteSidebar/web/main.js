function setup(htmlComponent) {
    console.log('[FlowbiteSidebar] Setting up component');
    
    // Set default data if not provided
    if (!htmlComponent.Data) {
        htmlComponent.Data = {
            items: ['Dashboard', 'Users', 'Settings', 'Help'],
            collapsed: false,
            selectedItem: 'Dashboard',
            theme: 'light'
        };
    }
    
    try {
        // Initial render
        renderSidebar(htmlComponent.Data, htmlComponent);
        console.log('[FlowbiteSidebar] Initial render complete');
    } catch (e) {
        console.error('[FlowbiteSidebar] Error in initial render:', e.message);
    }
    
    // Listen for data changes from MATLAB
    htmlComponent.addEventListener('DataChanged', function(event) {
        console.log('[FlowbiteSidebar] DataChanged event received');
        try {
            renderSidebar(htmlComponent.Data, htmlComponent);
        } catch (e) {
            console.error('[FlowbiteSidebar] Error rendering on DataChanged:', e.message);
        }
    });
}
