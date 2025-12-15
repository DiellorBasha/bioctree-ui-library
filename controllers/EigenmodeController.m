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
        TabGroup

        % --- Eigenmodes tab
        ModeSlider
        ModeLabel

        % --- Kernel tab
        KernelDropDown
        KernelAxes
        TauField          % Heat kernel parameter
        ScaleField        % Mexican hat parameter

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
            comp.GridLayout.ColumnWidth = {'4x', '1x'};

            % --- Manifold viewer
            comp.Manifold = ManifoldController(comp.GridLayout);
            comp.Manifold.Layout.Row = 1;
            comp.Manifold.Layout.Column = 1;

            % --- Control panel
            comp.ControlPanel = uipanel(comp.GridLayout, ...
                'Title', 'Spectral Controls');
            comp.ControlPanel.Layout.Row = 1;
            comp.ControlPanel.Layout.Column = 2;

            % --- Tab group
            comp.TabGroup = uitabgroup(comp.ControlPanel);

            %% =========================
            %  Eigenmodes tab
            %  =========================

            tEig = uitab(comp.TabGroup, 'Title', 'Eigenmodes');

            eigGrid = uigridlayout(tEig);
            eigGrid.RowHeight    = {'1x','fit'};
            eigGrid.ColumnWidth = {'1x'};

            comp.ModeSlider = uislider(eigGrid, ...
                'Orientation', 'vertical', ...
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
            %  Kernel tab
            %  =========================

            tKer = uitab(comp.TabGroup, 'Title', 'Kernel');

            kerGrid = uigridlayout(tKer);
            kerGrid.RowHeight    = {'fit','fit','1x'};
            kerGrid.ColumnWidth = {'1x','1x'};

            % Kernel selector
            comp.KernelDropDown = uidropdown(kerGrid, ...
                'Items', {'Heat','Mexican Hat'}, ...
                'ValueChangedFcn', @(~,~)comp.updateKernel());

            comp.KernelDropDown.Layout.Row = 1;
            comp.KernelDropDown.Layout.Column = [1 2];

            % Heat kernel parameter
            comp.TauField = uieditfield(kerGrid, 'numeric', ...
                'Value', 0.01, ...
                'Limits', [0 Inf], ...
                'ValueChangedFcn', @(~,~)comp.updateKernel());

            comp.TauField.Layout.Row = 2;
            comp.TauField.Layout.Column = 1;

            % Mexican hat parameter
            comp.ScaleField = uieditfield(kerGrid, 'numeric', ...
                'Value', 1.0, ...
                'Limits', [eps Inf], ...
                'ValueChangedFcn', @(~,~)comp.updateKernel());

            comp.ScaleField.Layout.Row = 2;
            comp.ScaleField.Layout.Column = 2;

            % Kernel visualization
            comp.KernelAxes = uiaxes(kerGrid);
            comp.KernelAxes.Layout.Row = 3;
            comp.KernelAxes.Layout.Column = [1 2];
            comp.KernelAxes.Box = 'on';

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

        function setMeshFromVerticesFaces(comp, V, F)
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

            phiRGB = bct.show.x2rgb(phi, ...
                'symmetric', true, ...
                'colormap', 'redblue');

            comp.Manifold.Viewer.CurrentObject.Color = phiRGB;

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

        function updateKernel(comp)

            if isempty(comp.Modes) || isempty(comp.Lambda)
                return
            end

            lambda = comp.Lambda;
            U      = comp.Modes;

            % --- Build kernel
            switch comp.KernelDropDown.Value
                case 'Heat'
                    tau = comp.TauField.Value;
                    g = exp(-tau * lambda);

                    cla(comp.KernelAxes)
                    fplot(comp.KernelAxes, ...
                        @(x)exp(-tau*x), ...
                        [0 max(lambda)]);
                    title(comp.KernelAxes,'Heat kernel')

                case 'Mexican Hat'
                    s = comp.ScaleField.Value;
                    g = (lambda .* exp(-s*lambda));

                    cla(comp.KernelAxes)
                    fplot(comp.KernelAxes, ...
                        @(x)x.*exp(-s*x), ...
                        [0 max(lambda)]);
                    title(comp.KernelAxes,'Mexican hat kernel')
            end

            % --- Kronecker delta from seed
            N = size(U,1);
            delta = zeros(N,1);
            delta(comp.Manifold.Seed) = 1;

            % --- Spectral projection + filtering
            coeffs = U' * delta;
            u = U * (g .* coeffs);

            u = u / max(abs(u));

            uRGB = bct.show.x2rgb(u, ...
                'symmetric', true, ...
                'colormap', 'hot');

            comp.Manifold.Viewer.CurrentObject.Color = uRGB;
        end
    end
end
