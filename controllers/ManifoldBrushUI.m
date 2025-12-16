classdef ManifoldBrushUI < matlab.ui.componentcontainer.ComponentContainer
    % ManifoldBrushUI
    %
    % Inspector-style UI for selecting and configuring manifold brushes.
    %
    % Layout:
    %   [ Selector List | Brush Parameters ]
    %
    % Responsibilities:
    %   - Choose manifold brush type
    %   - Instantiate selector object
    %   - Mount selector-specific parameter UI
    %   - Synchronize selector seed with ManifoldController
    %
    % Does NOT:
    %   - Implement selector parameter logic
    %   - Perform spatial selection itself

    %% =========================
    % Public API
    % =========================

    properties (SetObservable)
        Model ManifoldBrushModel
        ManifoldController
    end

    %% =========================
    % Private state
    % =========================

    properties (Access = private)
        SeedListener event.listener
        IsInitialized logical = false
    end

    properties (Access = private, Transient, NonCopyable)
        Grid matlab.ui.container.GridLayout

        % Left panel
        SelectorList matlab.ui.control.ListBox

        % Right panel
        ParamsPanel matlab.ui.container.Panel
        ParamsGrid matlab.ui.container.GridLayout
        ActiveParamsUI
    end

    %% =========================
    % Lifecycle
    % =========================

    methods (Access = protected)

        function setup(comp)

            % Root grid: 25% / 75%
            comp.Grid = uigridlayout(comp);
            comp.Grid.RowHeight    = {'1x'};
            comp.Grid.ColumnWidth = {'1x','3x'};

            %% Selector list (left)
            comp.SelectorList = uilistbox(comp.Grid);
            comp.SelectorList.Layout.Row = 1;
            comp.SelectorList.Layout.Column = 1;

            comp.SelectorList.Items = {'Delta','Graph','Spectral'};
            comp.SelectorList.Value = 'Delta';

            comp.SelectorList.ValueChangedFcn = ...
                @(~,~)comp.updateSelector();

            %% Parameters panel (right)
            comp.ParamsPanel = uipanel(comp.Grid, ...
                'Title','Brush Parameters');
            comp.ParamsPanel.Layout.Row = 1;
            comp.ParamsPanel.Layout.Column = 2;

            % Grid INSIDE panel (critical for resizing)
            comp.ParamsGrid = uigridlayout(comp.ParamsPanel);
            comp.ParamsGrid.RowHeight    = {'1x'};
            comp.ParamsGrid.ColumnWidth = {'1x'};

            % React to controller assignment
            addlistener(comp, 'ManifoldController', 'PostSet', ...
                @(~,~)comp.update());
        end

        function update(comp)
            % Update available selectors and seed listener

            if isempty(comp.ManifoldController)
                return;
            end

            % Enable / disable Spectral based on dual availability
            hasSpectral = ~isempty(comp.ManifoldController.Manifold) && ...
                          ~isempty(comp.ManifoldController.Manifold.dual);

            if hasSpectral
                comp.SelectorList.Items = {'Delta','Graph','Spectral'};
            else
                comp.SelectorList.Items = {'Delta','Graph'};
                if strcmp(comp.SelectorList.Value,'Spectral')
                    comp.SelectorList.Value = 'Delta';
                end
            end

            % Seed listener (guarded)
            if ~isempty(comp.SeedListener) && isvalid(comp.SeedListener)
                delete(comp.SeedListener);
            end

            if isobject(comp.ManifoldController) && ...
               isvalid(comp.ManifoldController) && ...
               any(strcmp(events(comp.ManifoldController),'SeedChanged'))

                comp.SeedListener = addlistener( ...
                    comp.ManifoldController, ...
                    'SeedChanged', ...
                    @(~,~)comp.onSeedChanged());
            end
        end
    end

    %% =========================
    % Public methods
    % =========================

    methods
        function initialize(comp)
            % Call once after Model + ManifoldController are set
            comp.IsInitialized = true;
            comp.updateSelector();
        end
    end

    %% =========================
    % Internal logic
    % =========================

    methods (Access = private)

        function updateSelector(comp)

            % Guard against early callbacks
            if ~comp.IsInitialized || ...
               isempty(comp.Model) || ...
               isempty(comp.ManifoldController) || ...
               isempty(comp.ManifoldController.Manifold)
                return;
            end

            % Remove previous parameter UI
            if ~isempty(comp.ActiveParamsUI) && isvalid(comp.ActiveParamsUI)
                delete(comp.ActiveParamsUI);
            end
            comp.ActiveParamsUI = [];

            manifold = comp.ManifoldController.Manifold;
            seed     = comp.ManifoldController.Seed;

            switch comp.SelectorList.Value

                case 'Delta'
                    s = DeltaBrush(manifold);
                    s.Seed = seed;

                case 'Graph'
                    s = GraphBrush(manifold);
                    s.Seed = seed;

                    ui = GraphSelectorParamsUI(comp.ParamsGrid);
                    ui.Layout.Row = 1;
                    ui.Layout.Column = 1;
                    ui.Selector = s;
                    comp.ActiveParamsUI = ui;

                case 'Spectral'
                    if isempty(manifold.dual)
                        warning('SpatialSelectorUI:NoSpectralBasis', ...
                            'Spectral selector requires a spectral basis.');
                        comp.SelectorList.Value = 'Delta';
                        return;
                    end

                    s = SpectralBrush(manifold);
                    s.SeedBrush.Seed = seed;

                    ui = KernelFactoryUI(comp.ParamsGrid);
                    ui.Layout.Row = 1;
                    ui.Layout.Column = 1;
                    ui.Model = s.KernelModel;
                    comp.ActiveParamsUI = ui;
            end

            comp.Model.Brush = s;
        end

        function onSeedChanged(comp)
            if isempty(comp.Model) || isempty(comp.Model.Brush)
                return;
            end

            seed = comp.ManifoldController.Seed;
            s = comp.Model.Brush;

            if isprop(s,'Seed')
                s.Seed = seed;
            elseif isprop(s,'SeedBrush')
                s.SeedBrush.Seed = seed;
            end
        end
    end
end
