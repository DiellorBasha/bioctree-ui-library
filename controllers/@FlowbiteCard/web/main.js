/**
 * main.js - Bootstrap and lifecycle controller for FlowbiteCard
 * Handles setup, MATLAB communication, and data synchronization
 */

function setup(htmlComponent) {
    console.log('[FlowbiteCard] Initializing component');
    
    try {
        // Initialize with default data if none provided
        var data = htmlComponent.Data || {
            title: 'Card Title',
            subtitle: '',
            content: '<p>Your content goes here</p>',
            footerText: '',
            status: '',
            statusVariant: 'primary',
            interactive: false,
            clickCount: 0
        };
        
        console.log('[FlowbiteCard] Initial data:', data);
        
        // Initial render
        renderCard(data, htmlComponent);
        
        // Listen for data changes from MATLAB (set via HTMLComponent.Data)
        htmlComponent.addEventListener('DataChanged', function(event) {
            console.log('[FlowbiteCard] DataChanged event received');
            console.log('[FlowbiteCard] New data:', htmlComponent.Data);
            renderCard(htmlComponent.Data, htmlComponent);
        });
        
        console.log('[FlowbiteCard] Setup complete - ready for user interaction');
        
    } catch (e) {
        console.error('[FlowbiteCard] Setup error:', e.message);
        console.error(e.stack);
    }
}

// Make setup available globally for MATLAB to call
window.setup = setup;
console.log('[FlowbiteCard] Script loaded, setup function registered');
