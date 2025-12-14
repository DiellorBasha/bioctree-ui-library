/**
 * main.js - Bootstrap and lifecycle controller for FlowbiteButton
 * Handles setup, MATLAB communication, and data synchronization
 */

function setup(htmlComponent) {
    console.log('[FlowbiteButton] Initializing component');
    
    try {
        // Initialize with default data if none provided
        var data = htmlComponent.Data || {
            label: 'Click me',
            variant: 'primary',
            clickCount: 0
        };
        
        console.log('[FlowbiteButton] Initial data:', data);
        
        // Initial render
        renderButton(data, htmlComponent);
        
        // Listen for data changes from MATLAB (set via HTMLComponent.Data)
        htmlComponent.addEventListener('DataChanged', function(event) {
            console.log('[FlowbiteButton] DataChanged event received');
            console.log('[FlowbiteButton] New data:', htmlComponent.Data);
            renderButton(htmlComponent.Data, htmlComponent);
        });
        
        console.log('[FlowbiteButton] Setup complete - ready for user interaction');
        
    } catch (e) {
        console.error('[FlowbiteButton] Setup error:', e.message);
        console.error(e.stack);
    }
}

// Make setup available globally for MATLAB to call
window.setup = setup;
console.log('[FlowbiteButton] Script loaded, setup function registered');
