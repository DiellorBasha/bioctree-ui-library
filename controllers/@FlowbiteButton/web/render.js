/**
 * render.js - Pure rendering logic for FlowbiteButton
 * Uses Flowbite/Tailwind CSS classes, no inline styles
 */

function renderButton(data, htmlComponent) {
    var container = document.getElementById('button-container');
    
    if (!container) {
        console.error('[FlowbiteButton] Container #button-container not found');
        return;
    }
    
    // Clear previous button
    var existingButton = container.querySelector('button');
    if (existingButton) {
        existingButton.remove();
    }
    
    // Map variants to Flowbite Tailwind classes
    var variant = data.variant || 'primary';
    var variantClasses = {
        'primary': 'text-white bg-blue-700 hover:bg-blue-800 focus:ring-4 focus:ring-blue-300 dark:bg-blue-600 dark:hover:bg-blue-700 dark:focus:ring-blue-800',
        'success': 'text-white bg-green-700 hover:bg-green-800 focus:ring-4 focus:ring-green-300 dark:bg-green-600 dark:hover:bg-green-700 dark:focus:ring-green-800',
        'danger': 'text-white bg-red-700 hover:bg-red-800 focus:ring-4 focus:ring-red-300 dark:bg-red-600 dark:hover:bg-red-700 dark:focus:ring-red-800',
        'warning': 'text-white bg-yellow-400 hover:bg-yellow-500 focus:ring-4 focus:ring-yellow-300 dark:focus:ring-yellow-900',
        'secondary': 'text-gray-900 bg-white border border-gray-300 hover:bg-gray-100 focus:ring-4 focus:ring-gray-200 dark:bg-gray-800 dark:text-white dark:border-gray-600 dark:hover:bg-gray-700 dark:hover:border-gray-600 dark:focus:ring-gray-700'
    };
    
    // Create button with Flowbite classes
    var button = document.createElement('button');
    button.type = 'button';
    button.id = 'flowbite-button';
    
    // Apply Flowbite base classes + variant
    var baseClasses = 'font-medium rounded-lg text-sm px-5 py-2.5 text-center focus:outline-none';
    button.className = baseClasses + ' ' + (variantClasses[variant] || variantClasses['primary']);
    button.textContent = data.label || 'Click me';
    
    // Add click event listener with proper MATLAB event pattern
    button.addEventListener('click', function() {
        var clickCount = (data.clickCount || 0) + 1;
        
        // Create event data
        var eventData = {
            clickCount: clickCount,
            timestamp: new Date().toISOString(),
            variant: data.variant
        };
        
        console.log('[FlowbiteButton] Button clicked:', eventData);
        
        // Send to MATLAB using proper event pattern
        try {
            htmlComponent.sendEventToMATLAB('ButtonClicked:' + JSON.stringify(eventData));
        } catch (e) {
            console.error('[FlowbiteButton] Error sending event:', e.message);
        }
    });
    
    container.appendChild(button);
    console.log('[FlowbiteButton] Rendered with Tailwind classes:', button.className);
}
