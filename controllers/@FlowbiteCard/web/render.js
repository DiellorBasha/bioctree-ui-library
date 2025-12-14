/**
 * render.js - Pure rendering logic for FlowbiteCard
 * No lifecycle management, only visualization
 */

function renderCard(data, htmlComponent) {
    var container = document.getElementById('card-container');
    
    if (!container) {
        console.error('[FlowbiteCard] Container #card-container not found');
        return;
    }
    
    // Clear previous card
    var existingCard = container.querySelector('[data-card]');
    if (existingCard) {
        existingCard.remove();
    }
    
    // Define badge colors
    var badgeColors = {
        'primary': 'background-color: #3b82f6; color: white;',
        'success': 'background-color: #10b981; color: white;',
        'danger': 'background-color: #ef4444; color: white;',
        'warning': 'background-color: #f59e0b; color: white;'
    };
    
    // Create card with inline styles
    var card = document.createElement('div');
    card.setAttribute('data-card', 'true');
    card.style.cssText = `
        background-color: white;
        border: 1px solid #e5e7eb;
        border-radius: 8px;
        display: flex;
        flex-direction: column;
        height: 100%;
        box-shadow: 0 1px 3px rgba(0, 0, 0, 0.1);
        overflow: hidden;
        transition: all 0.2s;
    `;
    
    if (data.interactive) {
        card.style.cursor = 'pointer';
        card.addEventListener('mouseenter', function() {
            card.style.boxShadow = '0 4px 6px rgba(0, 0, 0, 0.1)';
            card.style.transform = 'translateY(-2px)';
        });
        card.addEventListener('mouseleave', function() {
            card.style.boxShadow = '0 1px 3px rgba(0, 0, 0, 0.1)';
            card.style.transform = 'translateY(0)';
        });
    }
    
    // Create header
    var header = document.createElement('div');\n    header.style.cssText = `\n        padding: 16px;\n        border-bottom: 1px solid #e5e7eb;\n        display: flex;\n        justify-content: space-between;\n        align-items: flex-start;\n        flex-shrink: 0;\n    `;\n    
    var titleDiv = document.createElement('div');\n    titleDiv.style.flex = '1';\n    var title = document.createElement('h2');\n    title.textContent = data.title || 'Card Title';\n    title.style.cssText = 'margin: 0; font-size: 18px; font-weight: 600; color: #111827;';\n    \n    var subtitle = document.createElement('p');\n    subtitle.textContent = data.subtitle || '';\n    subtitle.style.cssText = 'margin: 4px 0 0 0; font-size: 14px; color: #6b7280;';\n    \n    titleDiv.appendChild(title);\n    if (data.subtitle) {\n        titleDiv.appendChild(subtitle);\n    }\n    header.appendChild(titleDiv);\n    \n    // Add badge if status provided\n    if (data.status) {\n        var badge = document.createElement('span');\n        var badgeStyle = badgeColors[data.statusVariant] || badgeColors['primary'];\n        badge.style.cssText = `\n            ${badgeStyle}\n            padding: 4px 12px;\n            border-radius: 12px;\n            font-size: 12px;\n            font-weight: 500;\n            white-space: nowrap;\n            margin-left: 12px;\n        `;\n        badge.textContent = data.status;\n        header.appendChild(badge);\n    }\n    \n    card.appendChild(header);\n    \n    // Create body\n    var body = document.createElement('div');\n    body.style.cssText = `\n        padding: 16px;\n        flex: 1;\n        overflow-y: auto;\n        font-size: 14px;\n        color: #374151;\n        line-height: 1.6;\n    `;\n    body.innerHTML = data.content || '<p>No content provided</p>';\n    card.appendChild(body);\n    \n    // Create footer if footerText provided\n    if (data.footerText) {\n        var footer = document.createElement('div');\n        footer.style.cssText = `\n            padding: 12px 16px;\n            background-color: #f9fafb;\n            border-top: 1px solid #e5e7eb;\n            font-size: 13px;\n            color: #6b7280;\n            flex-shrink: 0;\n        `;\n        footer.innerHTML = data.footerText;\n        card.appendChild(footer);\n    }\n    \n    // Add click event listener if card is interactive\n    if (data.interactive) {\n        card.addEventListener('click', function() {\n            var eventData = {\n                title: data.title,\n                timestamp: new Date().toISOString(),\n                clickCount: (data.clickCount || 0) + 1\n            };\n            \n            console.log('[FlowbiteCard] Card clicked:', eventData);\n            \n            try {\n                htmlComponent.dispatchEvent(new CustomEvent('CardClicked', {\n                    detail: JSON.stringify(eventData)\n                }));\n            } catch (e) {\n                console.error('[FlowbiteCard] Error dispatching click event:', e.message);\n            }\n        });\n    }\n    \n    container.appendChild(card);\n    \n    console.log('[FlowbiteCard] Card rendered:', data.title);\n}
