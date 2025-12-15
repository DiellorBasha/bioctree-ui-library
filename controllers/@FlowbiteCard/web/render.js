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
    var header = document.createElement('div');
    header.style.cssText = `
        padding: 16px;
        border-bottom: 1px solid #e5e7eb;
        display: flex;
        justify-content: space-between;
        align-items: flex-start;
        flex-shrink: 0;
    `;
    
    var titleDiv = document.createElement('div');
    titleDiv.style.flex = '1';
    var title = document.createElement('h2');
    title.textContent = data.title || 'Card Title';
    title.style.cssText = 'margin: 0; font-size: 18px; font-weight: 600; color: #111827;';
    
    var subtitle = document.createElement('p');
    subtitle.textContent = data.subtitle || '';
    subtitle.style.cssText = 'margin: 4px 0 0 0; font-size: 14px; color: #6b7280;';
    
    titleDiv.appendChild(title);
    if (data.subtitle) {
        titleDiv.appendChild(subtitle);
    }
    header.appendChild(titleDiv);
    
    // Add badge if status provided
    if (data.status) {
        var badge = document.createElement('span');
        var badgeStyle = badgeColors[data.statusVariant] || badgeColors['primary'];
        badge.style.cssText = `
            ${badgeStyle}
            padding: 4px 12px;
            border-radius: 12px;
            font-size: 12px;
            font-weight: 500;
            white-space: nowrap;
            margin-left: 12px;
        `;
        badge.textContent = data.status;
        header.appendChild(badge);
    }
    
    card.appendChild(header);
    
    // Create body
    var body = document.createElement('div');
    body.style.cssText = `
        padding: 16px;
        flex: 1;
        overflow-y: auto;
        font-size: 14px;
        color: #374151;
        line-height: 1.6;
    `;
    body.innerHTML = data.content || '<p>No content provided</p>';
    card.appendChild(body);
    
    // Create footer if footerText provided
    if (data.footerText) {
        var footer = document.createElement('div');
        footer.style.cssText = `
            padding: 12px 16px;
            background-color: #f9fafb;
            border-top: 1px solid #e5e7eb;
            font-size: 13px;
            color: #6b7280;
            flex-shrink: 0;
        `;
        footer.innerHTML = data.footerText;
        card.appendChild(footer);
    }
    
    // Add click event listener if card is interactive
    if (data.interactive) {
        card.addEventListener('click', function() {
            var eventData = {
                title: data.title,
                timestamp: new Date().toISOString(),
                clickCount: (data.clickCount || 0) + 1
            };
            
            console.log('[FlowbiteCard] Card clicked:', eventData);
            
            try {
                htmlComponent.dispatchEvent(new CustomEvent('CardClicked', {
                    detail: JSON.stringify(eventData)
                }));
            } catch (e) {
                console.error('[FlowbiteCard] Error dispatching click event:', e.message);
            }
        });
    }
    
    container.appendChild(card);
    
    console.log('[FlowbiteCard] Card rendered:', data.title);
}
