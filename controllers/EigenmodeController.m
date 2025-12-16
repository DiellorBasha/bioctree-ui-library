classdef EigenmodeController < matlab.ui.componentcontainer.ComponentContainer
    % EigenmodeController
    %
    % Composite component that visualizes Laplacian eigenmodes
    % and kernel-filtered operators on a ManifoldController.

    %% =========================
    %  Public API
    %  =========================

    properties
        Lambda = []     % eigenvalues [K x 1]
        Modes  = []     % eigenvectors [N x K]
    end

    properties (SetAccess = protected)
        Manifold ManifoldController
    end

    %% =========================
    %  Private UI state
    %  =========================

    properties (Access = private, Transient, NonCopyable)

        % Layout
        GridLayout
        ControlPanel
        ControlPanelGrid
        TabGroup

        % --- Eigenmodes tab
        ModeSlider
        ModeLabel

        % --- Kernel tab
        KernelModel_           % KernelModel instance
        KernelFactoryUI_       % KernelFactoryUI instance
        EigenmodeWeightViewer_ % EigenmodeWeightViewer instance
        
        % --- Signal tab
        SignalModel_           % CompositeSignalModel instance
        SignalFactoryUI_       % SignalFactoryUI instance
        
        % --- Colormap model
        ColormapModel_  % ColormapModel for manifold visualization

SeedListener   % listener handle
    end

    %% =========================
    %  Component lifecycle
    %  =========================

    methods (Access = protected)

        function setup(comp)

            % Root grid
            comp.GridLayout = uigridlayout(comp);
            comp.GridLayout.RowHeight    = {'1x'};
            comp.GridLayout.ColumnWidth = {'4x', '2x'};

            % --- Manifold viewer
            comp.Manifold = ManifoldController(comp.GridLayout);
            comp.Manifold.Layout.Row = 1;
            comp.Manifold.Layout.Column = 1;
            
            % Hide brush toolbar - EigenmodeController controls visualization
            comp.Manifold.setBrushToolbarVisible(false);
            
            % Set initial visualization mode
            comp.Manifold.VisualizationMode = 'Eigenmode';

            % --- Control panel
            comp.ControlPanel = uipanel(comp.GridLayout, ...
                'Title', 'Spectral Controls');
            comp.ControlPanel.Layout.Row = 1;
            comp.ControlPanel.Layout.Column = 2;

            % --- Grid layout inside control panel for responsive layout
            comp.ControlPanelGrid = uigridlayout(comp.ControlPanel);
            comp.ControlPanelGrid.RowHeight = {'1x', '2x'}; % TabGroup top, Viewer TabGroup bottom
            comp.ControlPanelGrid.ColumnWidth = {'1x'};

            % --- Tab group (top)
            comp.TabGroup = uitabgroup(comp.ControlPanelGrid);
            comp.TabGroup.Layout.Row = 1;
            comp.TabGroup.Layout.Column = 1;
            
            % Listen to tab changes to update visualization mode
            addlistener(comp.TabGroup, 'SelectionChanged', ...
                @(~,~)comp.onTabChanged());

            % --- Viewer TabGroup (bottom)
            viewerTabGroup = uitabgroup(comp.ControlPanelGrid);
            viewerTabGroup.Layout.Row = 2;
            viewerTabGroup.Layout.Column = 1;

            % --- EigenmodeWeightViewer tab
            tViewer = uitab(viewerTabGroup, 'Title', 'Eigenmode Weights');
            
            viewerGrid = uigridlayout(tViewer);
            viewerGrid.RowHeight = {'1x'};
            viewerGrid.ColumnWidth = {'1x'};
            
            comp.EigenmodeWeightViewer_ = EigenmodeWeightViewer(viewerGrid);
            comp.EigenmodeWeightViewer_.Layout.Row = 1;
            comp.EigenmodeWeightViewer_.Layout.Column = 1;

            % --- Signals tab
            tSignals = uitab(viewerTabGroup, 'Title', 'Signals');
            
            signalsGrid = uigridlayout(tSignals);
            signalsGrid.RowHeight = {'1x'};
            signalsGrid.ColumnWidth = {'1x'};
            
            % Initialize CompositeSignalModel with default Delta signal
            comp.SignalModel_ = CompositeSignalModel();
            deltaSig = DeltaSignal();
            deltaSig.Weight = 1.0;
            comp.SignalModel_.addSignal(deltaSig);
            
            % Create SignalFactoryUI in the Signals tab
            comp.SignalFactoryUI_ = SignalFactoryUI(signalsGrid);
            comp.SignalFactoryUI_.Layout.Row = 1;
            comp.SignalFactoryUI_.Layout.Column = 1;
            comp.SignalFactoryUI_.Model = comp.SignalModel_;
            
            % Add listener to update visualization when signals change
            addlistener(comp.SignalModel_, 'Signals', 'PostSet', ...
                @(~,~)comp.updateKernel());

            %% =========================
            %  Kernel tab
            %  =========================

            tKer = uitab(comp.TabGroup, 'Title', 'Kernel');

            kerGrid = uigridlayout(tKer);
            kerGrid.RowHeight    = {'1x'};
            kerGrid.ColumnWidth = {'1x'};

            % Initialize KernelModel with dummy axis (will be updated in setEigenmodes)
            comp.KernelModel_ = KernelModel(linspace(0, 1, 100));
            
            % Create KernelFactoryUI in the Kernel tab
            comp.KernelFactoryUI_ = KernelFactoryUI(kerGrid);
            comp.KernelFactoryUI_.Layout.Row = 1;
            comp.KernelFactoryUI_.Layout.Column = 1;
            
            % Link the model to the UI components
            comp.KernelFactoryUI_.Model = comp.KernelModel_;
            comp.EigenmodeWeightViewer_.Model = comp.KernelModel_;
            
            % Add listener to update visualization when kernel changes
            addlistener(comp.KernelModel_, 'KernelType', 'PostSet', ...
                @(~,~)comp.updateKernel());
            addlistener(comp.KernelModel_, 'Parameters', 'PostSet', ...
                @(~,~)comp.updateKernel());

            %% =========================
            %  Eigenmodes tab
            %  =========================

            tEig = uitab(comp.TabGroup, 'Title', 'Eigenmodes');

            eigGrid = uigridlayout(tEig);
            eigGrid.RowHeight    = {'1x','fit'};
            eigGrid.ColumnWidth = {'1x'};

            comp.ModeSlider = uislider(eigGrid, ...
                'Orientation', 'horizontal', ...
                'Limits', [1 2], ...
                'Value', 1, ...
                'MajorTicks', [], ...
                'Enable', 'off', ...
                'ValueChangedFcn', @(~,~)comp.updateEigenmode());

            comp.ModeSlider.Layout.Row = 1;

            comp.ModeLabel = uilabel(eigGrid, ...
                'Text', 'Mode: –', ...
                'FontWeight', 'bold', ...
                'HorizontalAlignment', 'center');

            comp.ModeLabel.Layout.Row = 2;

            %% =========================
            %  Colormap tab
            %  =========================

            tCmap = uitab(comp.TabGroup, 'Title', 'Colormap');

            cmapGrid = uigridlayout(tCmap);
            cmapGrid.RowHeight    = {'1x'};
            cmapGrid.ColumnWidth = {'1x'};
            
            % Initialize colormap model with defaults
            comp.ColormapModel_ = ColormapModel();
            comp.ColormapModel_.Name = 'redblue';
            comp.ColormapModel_.Symmetric = true;
            
            % Create colormap UI
            cmapUI = ColormapUI(cmapGrid);
            cmapUI.Layout.Row = 1;
            cmapUI.Layout.Column = 1;
            cmapUI.Model = comp.ColormapModel_;
            
            % Add listeners to update current visualization when colormap changes
            addlistener(comp.ColormapModel_, 'Name', 'PostSet', ...
                @(~,~)comp.reapplyColormap());
            addlistener(comp.ColormapModel_, 'Symmetric', 'PostSet', ...
                @(~,~)comp.reapplyColormap());

comp.SeedListener = addlistener( ...
    comp.Manifold, 'SeedChanged', ...
    @(~,~)comp.onSeedChanged());

        end

        function update(~)
            % No-op
        end
    end

    %% =========================
    %  Public methods
    %  =========================

    methods

        function initializeFromManifold(comp, manifold)
            % Initialize with a Manifold object
            % This is the recommended initialization method
            %
            % Usage:
            %   ec = EigenmodeController(parent);
            %   ec.initializeFromManifold(manifold);
            
            arguments
                comp
                manifold (1,1) bct.Manifold
            end
            
            comp.Manifold.initializeFromManifold(manifold);
        end

        function setMeshFromVerticesFaces(comp, V, F)
            % Set mesh from vertices and faces
            % Legacy method - consider using initializeFromManifold instead
            comp.Manifold.setMeshFromVerticesFaces(V, F);
        end

        function setEigenmodes(comp, Lambda, Modes)
            comp.Lambda = Lambda;
            comp.Modes  = Modes;

            K = size(Modes,2);

            if K < 2
                comp.ModeSlider.Limits = [1 2];
                comp.ModeSlider.Value = 1;
                comp.ModeSlider.Enable = 'off';
            else
                comp.ModeSlider.Limits = [1 K];
                comp.ModeSlider.Value = 1;
                comp.ModeSlider.MajorTicks = unique(round(linspace(1,K,min(6,K))));
                comp.ModeSlider.Enable = 'on';
            end

            % Update KernelModel with eigenvalue axis
            if ~isempty(Lambda)
                comp.KernelModel_.Axis = Lambda;
            end

            comp.updateEigenmode();
            comp.updateKernel();
        end
    end

    %% =========================
    %  Internal logic
    %  =========================

    methods (Access = private)

        function updateEigenmode(comp)

            if isempty(comp.Modes)
                return
            end

            k = round(comp.ModeSlider.Value);
            phi = comp.Modes(:,k);
            phi = phi / max(abs(phi));

            phiRGB = comp.ColormapModel_.apply(phi);

            comp.Manifold.setSurfaceColor(phiRGB);

            if ~isempty(comp.Lambda)
                comp.ModeLabel.Text = sprintf( ...
                    'Mode %d   λ = %.4g', k, comp.Lambda(k));
            end
        end
function onSeedChanged(comp)
    % React to annotation-driven seed changes

    % Only update kernel-based visualization
    if isempty(comp.Lambda) || isempty(comp.Modes)
        return
    end

    % Only act if Kernel tab is active
    if strcmp(comp.TabGroup.SelectedTab.Title, 'Kernel')
        comp.updateKernel();
    end
end

        function onTabChanged(comp)
            % Update visualization mode when tabs change
            if isempty(comp.TabGroup.SelectedTab)
                return
            end
            
            switch comp.TabGroup.SelectedTab.Title
                case 'Eigenmodes'
                    comp.Manifold.VisualizationMode = 'Eigenmode';
                    comp.updateEigenmode();
                case 'Kernel'
                    comp.Manifold.VisualizationMode = 'Signal';
                    comp.updateKernel();
                case {'Colormap'}
                    % Colormap tab doesn't change mode, just updates current viz
                    comp.reapplyColormap();
            end
        end

        function updateKernel(comp)

            if isempty(comp.Modes) || isempty(comp.Lambda)
                return
            end

            U = comp.Modes;
            N = size(U,1);

            % --------------------------------------------------
            % Build evaluation context
            % --------------------------------------------------
            context = struct();
            context.Seed = comp.Manifold.Seed;
            context.Manifold = comp.Manifold;

            % --------------------------------------------------
            % Evaluate composite signal
            % --------------------------------------------------
            s = comp.SignalModel_.evaluate(N, context);

            % --------------------------------------------------
            % Spectral filtering
            % --------------------------------------------------
            g = comp.KernelModel_.KernelFunction(comp.Lambda);

            coeffs = U' * s;
            u = U * (g .* coeffs);

            % --------------------------------------------------
            % Normalize + colormap
            % --------------------------------------------------
            u = u / max(abs(u));
            uRGB = comp.ColormapModel_.apply(u);

            comp.Manifold.setSurfaceColor(uRGB);
        end
        
        function reapplyColormap(comp)
            % Reapply colormap to current visualization
            % Determine which tab is active and update accordingly
            if isempty(comp.TabGroup.SelectedTab)
                return
            end
            
            switch comp.TabGroup.SelectedTab.Title
                case 'Eigenmodes'
                    comp.updateEigenmode();
                case 'Kernel'
                    comp.updateKernel();
            end
        end
    end
end
