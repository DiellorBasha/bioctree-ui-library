classdef ColormapUI < matlab.ui.componentcontainer.ComponentContainer

    properties (SetObservable)
        Model ColormapModel
    end

    properties (Access = private, Transient, NonCopyable)
        Grid
        MapDropDown
        SymmetricCheck
        AutoCheck
        LoField
        HiField
        PreviewAxes
    end

    methods (Access = protected)

        function setup(comp)

            comp.Grid = uigridlayout(comp);
            comp.Grid.RowHeight = {'fit','fit','fit','1x'};
            comp.Grid.ColumnWidth = {'1x','1x'};

            comp.MapDropDown = uidropdown(comp.Grid, ...
                'Items', {'parula','turbo','hot','jet','redblue'}, ...
                'ValueChangedFcn', @(~,~)comp.syncModel());
            comp.MapDropDown.Layout.Row = 1;
            comp.MapDropDown.Layout.Column = [1 2];

            comp.SymmetricCheck = uicheckbox(comp.Grid, ...
                'Text','symmetric', ...
                'ValueChangedFcn', @(~,~)comp.syncModel());
            comp.SymmetricCheck.Layout.Row = 2;
            comp.SymmetricCheck.Layout.Column = 1;

            comp.AutoCheck = uicheckbox(comp.Grid, ...
                'Text','auto limits', ...
                'Value', true, ...
                'ValueChangedFcn', @(~,~)comp.syncModel());
            comp.AutoCheck.Layout.Row = 2;
            comp.AutoCheck.Layout.Column = 2;

            comp.LoField = uieditfield(comp.Grid,'numeric');
            comp.LoField.Layout.Row = 3;
            comp.LoField.Layout.Column = 1;

            comp.HiField = uieditfield(comp.Grid,'numeric');
            comp.HiField.Layout.Row = 3;
            comp.HiField.Layout.Column = 2;

            comp.PreviewAxes = uiaxes(comp.Grid);
            comp.PreviewAxes.Layout.Row = 4;
            comp.PreviewAxes.Layout.Column = [1 2];
            axis(comp.PreviewAxes,'off');
        end

        function update(comp)
            if isempty(comp.Model), return; end

            comp.MapDropDown.Value = comp.Model.Name;
            comp.SymmetricCheck.Value = comp.Model.Symmetric;
            comp.AutoCheck.Value = comp.Model.AutoLimits;

            comp.LoField.Enable = ~comp.Model.AutoLimits;
            comp.HiField.Enable = ~comp.Model.AutoLimits;

            comp.drawPreview();
        end
    end

    methods (Access = private)

        function syncModel(comp)
            m = comp.Model;
            if isempty(m), return; end

            m.Name = comp.MapDropDown.Value;
            m.Symmetric = comp.SymmetricCheck.Value;
            m.AutoLimits = comp.AutoCheck.Value;

            if ~m.AutoLimits
                m.Lo = comp.LoField.Value;
                m.Hi = comp.HiField.Value;
            end

            comp.update();
        end

        function drawPreview(comp)
            C = comp.Model.colormap();
            imagesc(comp.PreviewAxes, permute(C,[1 3 2]));
            axis(comp.PreviewAxes,'tight');
            axis(comp.PreviewAxes,'off');
        end
    end
end
