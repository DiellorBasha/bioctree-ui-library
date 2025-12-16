classdef SignalFactoryUI < matlab.ui.componentcontainer.ComponentContainer

    properties (SetObservable)
        Model CompositeSignalModel
    end

    properties (Access = private, Transient, NonCopyable)
        Grid
        SignalList matlab.ui.control.ListBox
        AddButton matlab.ui.control.Button
        RemoveButton matlab.ui.control.Button

        TypeDropDown matlab.ui.control.DropDown
        WeightField matlab.ui.control.NumericEditField

        ParamGrid matlab.ui.container.GridLayout
    end

    % ==========================================================
    % Lifecycle
    % ==========================================================
    methods (Access = protected)

        function setup(comp)

            comp.Grid = uigridlayout(comp);
            comp.Grid.RowHeight = {'1x','fit'};
            comp.Grid.ColumnWidth = {'1x','1x'};

            % ---------------- Signal list ----------------
            comp.SignalList = uilistbox(comp.Grid);
            comp.SignalList.Layout.Row = 1;
            comp.SignalList.Layout.Column = 1;
            comp.SignalList.ValueChangedFcn = @(~,~)comp.updateEditor();

            % ---------------- Editor ----------------
            editor = uigridlayout(comp.Grid);
            editor.RowHeight = {'fit','fit','1x'};
            editor.ColumnWidth = {'1x','1x'};
            editor.Layout.Row = 1;
            editor.Layout.Column = 2;

            comp.TypeDropDown = uidropdown(editor);
            comp.TypeDropDown.Layout.Row = 1;
            comp.TypeDropDown.Layout.Column = [1 2];
            comp.TypeDropDown.ValueChangedFcn = @(~,~)comp.changeType();

            comp.WeightField = uieditfield(editor,'numeric');
            comp.WeightField.Layout.Row = 2;
            comp.WeightField.Layout.Column = [1 2];
            comp.WeightField.ValueChangedFcn = @(~,~)comp.updateWeight();

            comp.ParamGrid = uigridlayout(editor);
            comp.ParamGrid.Layout.Row = 3;
            comp.ParamGrid.Layout.Column = [1 2];

            % ---------------- Buttons ----------------
            btnGrid = uigridlayout(comp.Grid);
            btnGrid.RowHeight = {'fit'};
            btnGrid.ColumnWidth = {'1x','1x'};
            btnGrid.Layout.Row = 2;
            btnGrid.Layout.Column = [1 2];

            comp.AddButton = uibutton(btnGrid,'Text','Add');
            comp.AddButton.Layout.Column = 1;
            comp.AddButton.ButtonPushedFcn = @(~,~)comp.addSignal();

            comp.RemoveButton = uibutton(btnGrid,'Text','Remove');
            comp.RemoveButton.Layout.Column = 2;
            comp.RemoveButton.ButtonPushedFcn = @(~,~)comp.removeSignal();
        end

        function update(comp)

            if isempty(comp.Model)
                return;
            end

            signals = comp.Model.Signals;

            if isempty(signals)
                comp.SignalList.Items = {};
                comp.SignalList.Value = {};
                return;
            end

            names = cellfun(@(s) s.Type, signals, 'UniformOutput', false);
            comp.SignalList.Items = names;

            if isempty(comp.SignalList.Value) || ...
               ~ismember(comp.SignalList.Value, names)
                comp.SignalList.Value = names{1};
            end

            comp.updateEditor();
        end
    end

    % ==========================================================
    % Editor logic
    % ==========================================================
    methods (Access = private)

        function updateEditor(comp)

            idx = find(strcmp(comp.SignalList.Value, comp.SignalList.Items),1);
            if isempty(idx), return; end

            s = comp.Model.Signals{idx};   % ✅ FIX

            registry = SignalRegistry.getRegistry();
            reg = registry.(s.Type);

            comp.TypeDropDown.Items = fieldnames(registry);
            comp.TypeDropDown.Value = s.Type;

            comp.WeightField.Value = s.Weight;

            delete(comp.ParamGrid.Children);

            for i = 1:numel(reg.ParamNames)
                pname = reg.ParamNames{i};

                uilabel(comp.ParamGrid,'Text',pname);
                uieditfield(comp.ParamGrid,'numeric', ...
                    'Value', s.Parameters.(pname), ...
                    'ValueChangedFcn', @(src,~) ...
                        comp.setParam(idx,pname,src.Value));
            end
        end

        function addSignal(comp)
            reg = SignalRegistry.getRegistry();
            types = fieldnames(reg);
            s = reg.(types{1}).Constructor();
            comp.Model.addSignal(s);
            comp.update();
        end

        function removeSignal(comp)
            idx = find(strcmp(comp.SignalList.Value, comp.SignalList.Items),1);
            if isempty(idx), return; end
            comp.Model.removeSignal(idx);
            comp.update();
        end

        function setParam(comp, idx, pname, val)
            s = comp.Model.Signals{idx};     % ✅ FIX
            s.Parameters.(pname) = val;
        end

        function updateWeight(comp)
            idx = find(strcmp(comp.SignalList.Value, comp.SignalList.Items),1);
            if isempty(idx), return; end
            comp.Model.Signals{idx}.Weight = comp.WeightField.Value;  % ✅ FIX
        end

        function changeType(comp)

            idx = find(strcmp(comp.SignalList.Value, comp.SignalList.Items),1);
            if isempty(idx), return; end

            reg = SignalRegistry.getRegistry();
            newType = comp.TypeDropDown.Value;

            old = comp.Model.Signals{idx};           % ✅ FIX
            s = reg.(newType).Constructor();
            s.Weight = old.Weight;

            comp.Model.Signals{idx} = s;              % ✅ FIX
            comp.update();
        end
    end
end
