classdef TestGUI < handle
    % DEBUG - NOT FOR SUBMISSION

    properties
        Figure
        MapAxes
        View3DAxes
        ControlPanel
        StartButton
        ResetButton
        StatusText
        NumRunsEdit
        TimeLimitEdit
        NumShipsEdit
        NumMinesEdit
        DamageRangeEdit
        DetectRangeEdit
        FleetBehaviorPopup
        LayoutPopup
        MineTypePopup
        AnimateCheckbox
        HeadingCheckbox

        simEngine
        renderer3D
    end

    properties (Access = private)
        boundary_box (1,4) double = [0, 0.1, 6, 8.9]
        minefield_box (1,4) double = [1.5, 1.5, 3.0, 6.0]
        localMaxSteps (1,1) double = 50
        isRunning (1,1) logical = false
        currentRun (1,1) double = 0
    end

    methods
        function app = TestGUI()
            app.createComponents();
            app.startup();
        end

        function delete(app)
            app.isRunning = false;
            try
                if ~isempty(app.simEngine) && isvalid(app.simEngine)
                    delete(app.simEngine);
                end
            catch
            end
            try
                if ~isempty(app.renderer3D) && isvalid(app.renderer3D)
                    delete(app.renderer3D);
                end
            catch
            end
            try
                if ~isempty(app.Figure) && isgraphics(app.Figure)
                    delete(app.Figure);
                end
            catch
            end
        end
    end

    methods (Access = private)
        function startup(app)
            tmpEngine = SESimulatorEngine();

            set(app.FleetBehaviorPopup, 'String', tmpEngine.getValidFleetBehaviors());
            set(app.LayoutPopup, 'String', tmpEngine.getValidMinefieldLayouts());
            set(app.MineTypePopup, 'String', {'mobile','static'});

            % Update renderer
            app.renderer3D = SESideViewTacticalStatus(app.View3DAxes, app.boundary_box, app.minefield_box);

            app.rebuildSimulation();

            try
                delete(tmpEngine);
            catch
            end

            app.setStatus('Ready');
        end

        function createComponents(app)
            app.Figure = figure( ...
                'Name','Sea Shield 3D Mine Simulator', ...
                'NumberTitle','off', ...
                'MenuBar','none', ...
                'ToolBar','none', ...
                'Color',[0.94 0.94 0.94], ...
                'Position',[80 60 1280 800], ...
                'CloseRequestFcn',@(src,evt)app.onClose());

            app.MapAxes = axes('Parent', app.Figure, 'Units','normalized', ...
                'Position',[0.05 0.67 0.62 0.24]);
            title(app.MapAxes, '2D Overhead Map');

            app.View3DAxes = axes('Parent', app.Figure, 'Units','normalized', ...
                'Position',[0.05 0.08 0.62 0.54]);
            title(app.View3DAxes, '3D Tactical View');

            app.ControlPanel = uipanel('Parent', app.Figure, 'Units','normalized', ...
                'Position',[0.71 0.05 0.26 0.9], 'Title','Controls');

            y = 0.93;
            dy = 0.055;
            labelW = 0.46;
            fieldX = 0.52;
            fieldW = 0.40;

            app.StartButton = uicontrol(app.ControlPanel, 'Style','pushbutton', 'String','Start', ...
                'Units','normalized','Position',[0.08 y 0.36 0.045], ...
                'Callback',@(s,e)app.StartButtonPushed());

            app.ResetButton = uicontrol(app.ControlPanel, 'Style','pushbutton', 'String','Reset', ...
                'Units','normalized','Position',[0.56 y 0.36 0.045], ...
                'Callback',@(s,e)app.ResetButtonPushed());
            y = y - dy;

            app.StatusText = uicontrol(app.ControlPanel, 'Style','text', 'String','Ready', ...
                'Units','normalized', 'HorizontalAlignment','left', ...
                'Position',[0.08 y 0.84 0.05], ...
                'BackgroundColor',get(app.ControlPanel,'BackgroundColor'));
            y = y - dy;

            app.addLabel('Runs', y, labelW);           app.NumRunsEdit = app.addEdit('1', fieldX, y, fieldW); y = y - dy;
            app.addLabel('Time Limit', y, labelW);     app.TimeLimitEdit = app.addEdit('50', fieldX, y, fieldW); y = y - dy;
            app.addLabel('Ships', y, labelW);          app.NumShipsEdit = app.addEdit('5', fieldX, y, fieldW); y = y - dy;
            app.addLabel('Mines', y, labelW);          app.NumMinesEdit = app.addEdit('9', fieldX, y, fieldW); y = y - dy;
            app.addLabel('Damage Radius', y, labelW);  app.DamageRangeEdit = app.addEdit('0.25', fieldX, y, fieldW); y = y - dy;
            app.addLabel('Detect Range', y, labelW);   app.DetectRangeEdit = app.addEdit('2', fieldX, y, fieldW); y = y - dy;

            app.addLabel('Fleet Behavior', y, labelW); app.FleetBehaviorPopup = app.addPopup(fieldX, y, fieldW); y = y - dy;
            app.addLabel('Mine Layout', y, labelW);    app.LayoutPopup = app.addPopup(fieldX, y, fieldW); y = y - dy;
            app.addLabel('Mine Type', y, labelW);      app.MineTypePopup = app.addPopup(fieldX, y, fieldW); y = y - dy;

            app.AnimateCheckbox = uicontrol(app.ControlPanel, 'Style','checkbox', ...
                'String','Animate', 'Value',1, ...
                'Units','normalized','Position',[0.08 y 0.84 0.04]);
            y = y - dy;

            app.HeadingCheckbox = uicontrol(app.ControlPanel, 'Style','checkbox', ...
                'String','Display Ship Headings', 'Value',1, ...
                'Units','normalized','Position',[0.08 y 0.84 0.04]);
        end

        function h = addLabel(app, txt, y, w)
            h = uicontrol(app.ControlPanel, 'Style','text', 'String',txt, ...
                'Units','normalized', ...
                'HorizontalAlignment','left', ...
                'Position',[0.08 y w 0.04], ...
                'BackgroundColor',get(app.ControlPanel,'BackgroundColor'));
        end

        function h = addEdit(app, txt, x, y, w)
            h = uicontrol(app.ControlPanel, 'Style','edit', 'String',txt, ...
                'Units','normalized', ...
                'Position',[x y w 0.045]);
        end

        function h = addPopup(app, x, y, w)
            h = uicontrol(app.ControlPanel, 'Style','popupmenu', 'String',{'-'}, ...
                'Units','normalized', ...
                'Position',[x y w 0.045]);
        end

        function rebuildSimulation(app)
            app.localMaxSteps = max(1, floor(app.getNumeric(app.TimeLimitEdit, 50)));

            if ~isempty(app.simEngine)
                try
                    if isvalid(app.simEngine)
                        delete(app.simEngine);
                    end
                catch
                end
            end

            if isgraphics(app.MapAxes)
                cla(app.MapAxes, 'reset');
            end

            app.simEngine = SESimulatorEngine();
            app.simEngine.setBoundaryBox(app.boundary_box);
            app.simEngine.setMinefieldBox(app.minefield_box);
            app.simEngine.setAnimate(logical(get(app.AnimateCheckbox,'Value')));
            app.simEngine.setNumRuns(app.getNumeric(app.NumRunsEdit,1));
            app.simEngine.setFleetBehavior(app.getPopupValue(app.FleetBehaviorPopup));
            app.simEngine.setMinefieldLayout(app.getPopupValue(app.LayoutPopup));
            app.simEngine.setMineType(app.getPopupValue(app.MineTypePopup));
            app.simEngine.setAxesHandle(app.MapAxes);
            app.simEngine.setNumShips(app.getNumeric(app.NumShipsEdit,5));
            app.simEngine.setNumMines(app.getNumeric(app.NumMinesEdit,9));
            app.simEngine.displayShipHeadings(logical(get(app.HeadingCheckbox,'Value')));

            app.applyMineRanges();
            app.resetDisplays();
        end

        function applyMineRanges(app)
            mines = app.simEngine.minefield.mines;
            damageRange = app.getNumeric(app.DamageRangeEdit, 0.25);
            detectRange = app.getNumeric(app.DetectRangeEdit, 2);

            for k = 1:numel(mines)
                try
                    mines(k).damageRange = damageRange;
                    mines(k).detectRange = detectRange;
                    mines(k).updateDisplay();
                catch
                end
            end
        end

        function resetDisplays(app)
            axes(app.MapAxes); %#ok<LAXES>
            hold(app.MapAxes, 'on');
            axis(app.MapAxes, 'equal');
            xlim(app.MapAxes, [0 6]);
            ylim(app.MapAxes, [0 9]);
            set(app.MapAxes, 'Color', [0.6745 0.9686 0.9882], ...
                'Box', 'on', 'XGrid', 'on', 'YGrid', 'on');
            title(app.MapAxes, '2D Overhead Map');

            app.simEngine.refreshDisplay();

            app.renderer3D.reset();
            app.renderer3D.update(app.simEngine);

            app.updateStatusCounts();
        end

        function runSimulation(app)
            app.isRunning = true;
            app.setControlsEnabled(false);
            set(app.AnimateCheckbox, 'Enable', 'on');
            drawnow;

            numRuns = max(1, floor(app.getNumeric(app.NumRunsEdit,1)));

            for runIdx = 1:numRuns
                if ~ishandle(app.Figure) || ~app.isRunning
                    break;
                end

                app.currentRun = runIdx;
                app.rebuildSimulation();
                app.setStatus(sprintf('Run %d started', runIdx));
                drawnow;

                while ~app.simulationDoneLocal()
                    app.simEngine.update();
                    app.simEngine.refreshDisplay();
                    app.renderer3D.update(app.simEngine);
                    app.updateStatusCounts();
                    drawnow;

                    if ~ishandle(app.Figure) || ~app.isRunning
                        break;
                    end
                end
            end

            app.isRunning = false;

            if ishandle(app.Figure)
                app.setStatus('Ready');
                app.setControlsEnabled(true);
            end
        end

        function tf = simulationDoneLocal(app)
            localMaxFrames = app.localMaxSteps * app.simEngine.fps * app.simEngine.time_multiplier;

            tf = app.simEngine.getNumShipsRemaining() == 0 || ...
                 app.simEngine.getNumUnexplodedMines() == 0 || ...
                 app.simEngine.curSimulationStep >= localMaxFrames;
        end

        function StartButtonPushed(app)
            if app.isRunning
                return;
            end

            app.rebuildSimulation();
            app.runSimulation();
        end

        function ResetButtonPushed(app)
            app.isRunning = false;
            app.rebuildSimulation();
            app.setStatus('Reset complete');
        end

        function setStatus(app, txt)
            if ishandle(app.StatusText)
                set(app.StatusText, 'String', txt);
            end
        end

        function updateStatusCounts(app)
            msg = sprintf('Run %d | Step %d | Ships alive %d | Ships remaining %d | Mines live %d', ...
                app.currentRun, app.simEngine.curSimulationStep, ...
                app.simEngine.getNumUnsunkShips(), app.simEngine.getNumShipsRemaining(), ...
                app.simEngine.getNumUnexplodedMines());

            app.setStatus(msg);
        end

        function setControlsEnabled(app, enabled)
            if enabled
                state = 'on';
            else
                state = 'off';
            end

            ctrls = { ...
                app.StartButton, ...
                app.ResetButton, ...
                app.NumRunsEdit, ...
                app.TimeLimitEdit, ...
                app.NumShipsEdit, ...
                app.NumMinesEdit, ...
                app.DamageRangeEdit, ...
                app.DetectRangeEdit, ...
                app.FleetBehaviorPopup, ...
                app.LayoutPopup, ...
                app.MineTypePopup, ...
                app.HeadingCheckbox};

            for k = 1:numel(ctrls)
                if ishandle(ctrls{k})
                    set(ctrls{k}, 'Enable', state);
                end
            end
        end

        function val = getNumeric(~, h, defaultVal)
            try
                val = str2double(get(h,'String'));
                if isnan(val) || ~isfinite(val)
                    val = defaultVal;
                end
            catch
                val = defaultVal;
            end
        end

        function val = getPopupValue(~, h)
            strs = get(h, 'String');
            idx = get(h, 'Value');

            if iscell(strs)
                val = strs{idx};
            else
                val = strs(idx,:);
                val = strtrim(val);
            end
        end

        function onClose(app)
            app.isRunning = false;
            delete(app);
        end
    end
end