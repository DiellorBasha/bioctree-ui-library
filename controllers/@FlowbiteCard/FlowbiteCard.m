classdef FlowbiteCard < FlowbiteComponentBase
    % FlowbiteCard - Flexible card component using Flowbite + Tailwind CSS
    %
    % Display rich content in a styled card with optional headers, footers, and status badges.
    %
    % Example:
    %   fig = uifigure('Position', [100 100 600 400]);
    %   card = FlowbiteCard(fig, 'Position', [50 50 500 300]);
    %   card.Title = 'Welcome';
    %   card.Subtitle = 'This is a card component';
    %   card.Content = '<p>Your HTML content here</p>';
    %   card.Status = 'Active';
    %   card.StatusVariant = 'success';
    
    properties
        % Title - Main heading of the card
        Title = "Card Title";
        
        % Subtitle - Optional subtitle below the title
        Subtitle = "";
        
        % Content - HTML content to display in card body
        Content = "<p>Your content goes here</p>";
        
        % FooterText - Optional footer content
        FooterText = "";
        
        % Status - Status badge text (empty = no badge)
        Status = "";
        
        % StatusVariant - Status badge color: 'primary', 'success', 'danger', 'warning'
        StatusVariant = "primary";
        
        % Interactive - If true, card is clickable and fires CardClicked event
        Interactive logical = false;
    end
    
    properties
        % CardClickedFcn - Callback when card is clicked (if Interactive is true)
        CardClickedFcn = []
    end
    
    events
        % CardClicked - Event fired when card is clicked (if Interactive is true)
        CardClicked
    end
    
    properties (Access = private)
        % ClickCount - Internal counter for card clicks
        ClickCount = 0;
    end
    
    methods (Access = protected)
        function data = getJSData(comp)
            % getJSData - Provide component state for JavaScript
            
            data = struct();
            data.title = char(comp.Title);
            data.subtitle = char(comp.Subtitle);
            data.content = char(comp.Content);
            data.footerText = char(comp.FooterText);
            data.status = char(comp.Status);
            data.statusVariant = char(comp.StatusVariant);
            data.interactive = comp.Interactive;
            data.clickCount = comp.ClickCount;
        end
        
        function handleEvent(comp, name, payload)
            % handleEvent - Process events from JavaScript
            
            switch name
                case "CardClicked"
                    % Update internal state
                    comp.ClickCount = payload.clickCount;
                    
                    % Fire MATLAB event
                    notify(comp, 'CardClicked');
                    
                    % Execute callback if defined
                    if ~isempty(comp.CardClickedFcn)
                        comp.CardClickedFcn(comp, payload);
                    end
                    
                    % Log click
                    fprintf('[FlowbiteCard] Card clicked: %s (count: %d)\n', payload.title, comp.ClickCount);
            end
        end
    end
end
