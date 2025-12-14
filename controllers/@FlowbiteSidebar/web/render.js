function renderSidebar(data, htmlComponent) {
    const container = document.getElementById('sidebar-container');
    if (!container) {
        console.error('[FlowbiteSidebar] Container not found');
        return;
    }
    
    // Clear previous content
    container.innerHTML = '';
    
    // Validate data
    if (!data || !data.items || !Array.isArray(data.items)) {
        console.warn('[FlowbiteSidebar] Invalid data structure');
        data = {
            items: ['Dashboard', 'Users', 'Settings'],
            collapsed: false,
            selectedItem: 'Dashboard',
            theme: 'light'
        };
    }
    
    // Define colors
    const isDark = data.theme === 'dark';
    const colors = {
        bg: isDark ? '#1f2937' : '#ffffff',
        border: isDark ? '#374151' : '#e5e7eb',
        text: isDark ? '#d1d5db' : '#374151',
        textHover: isDark ? '#f3f4f6' : '#1f2937',
        hoverBg: isDark ? '#374151' : '#f3f4f6',
        selectedBg: '#2563eb',
        selectedText: '#ffffff'
    };
    
    const sidebarWidth = data.collapsed ? '64px' : '256px';
    
    // Create sidebar wrapper
    const sidebar = document.createElement('aside');
    sidebar.id = 'flowbite-sidebar';
    sidebar.style.cssText = `
        width: ${sidebarWidth};
        height: 100%;
        background-color: ${colors.bg};
        border-right: 1px solid ${colors.border};
        overflow-y: auto;
        overflow-x: hidden;
        transition: width 0.3s ease;
        box-sizing: border-box;
        flex-shrink: 0;
    `;
    
    // Create nav wrapper
    const nav = document.createElement('nav');
    nav.style.cssText = `
        display: flex;
        flex-direction: column;
        height: 100%;
        padding: 12px;
        gap: 8px;
        box-sizing: border-box;
    `;
    
    // Add menu items
    data.items.forEach((item, index) => {
        const isSelected = item === data.selectedItem;
        
        // Create link
        const link = document.createElement('a');
        link.href = '#';
        link.style.cssText = `
            display: flex;
            align-items: center;
            gap: 12px;
            padding: 12px;
            border-radius: 8px;
            cursor: pointer;
            text-decoration: none;
            white-space: nowrap;
            transition: all 0.2s;
            background-color: ${isSelected ? colors.selectedBg : 'transparent'};
            color: ${isSelected ? colors.selectedText : colors.text};
            font-weight: ${isSelected ? '600' : '400'};
            overflow: hidden;
        `;
        
        // Add hover effect
        link.addEventListener('mouseenter', () => {
            if (!isSelected) {
                link.style.backgroundColor = colors.hoverBg;
            }
        });
        link.addEventListener('mouseleave', () => {
            if (!isSelected) {
                link.style.backgroundColor = 'transparent';
            }
        });
        
        // Add icon (SVG home icon)
        const iconSVG = document.createElement('svg');
        iconSVG.setAttribute('viewBox', '0 0 24 24');
        iconSVG.setAttribute('fill', 'currentColor');
        iconSVG.style.cssText = `width: 24px; height: 24px; flex-shrink: 0;`;
        iconSVG.innerHTML = `<path d="M10 20v-6h4v6h5v-8h3L12 3 2 12h3v8z"/>`;
        link.appendChild(iconSVG);
        
        // Add label
        const label = document.createElement('span');
        label.textContent = item;
        label.style.cssText = `
            display: ${data.collapsed ? 'none' : 'inline'};
            font-size: 14px;
            overflow: hidden;
            text-overflow: ellipsis;
        `;
        link.appendChild(label);
        
        // Add tooltip when collapsed
        if (data.collapsed) {
            link.title = item;
        }
        
        // Click handler
        link.addEventListener('click', (e) => {
            e.preventDefault();
            console.log('[FlowbiteSidebar] Item clicked:', item);
            htmlComponent.dispatchEvent(new CustomEvent('ItemClicked', {
                detail: JSON.stringify({ item: item, index: index })
            }));
        });
        
        nav.appendChild(link);
    });
    
    sidebar.appendChild(nav);
    container.appendChild(sidebar);
    
    console.log('[FlowbiteSidebar] Rendered', data.items.length, 'items, collapsed:', data.collapsed);
}
