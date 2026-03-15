classdef SESideViewTacticalStatus < handle
    % SESideViewTacticalStatus
    %
    % Design Intent:
    %   X, Y = horizontal simulation plane
    %   Z    = vertical axis used for side view presentation
    %
    % Visual Intent:
    %   - Ships are rendered as a silhouette
    %   - Mines are spheres located at the waterline
    %
    % Camera ownership:
    %   - This class owns camera presets and view cycling.
    %   - GUI should call: nextView() and getViewName()
    %   - Default view is Side-Y.
    %
    % 3-05-26: Replaced blocky ship geometry side profiles
    %          silhouette (bow rake + sheer + transom + stepped superstructure)
    %          extruded across beam:
    %            - Single clean Y-Z outline and extruding it,
    %            - Superstructure proportional and forward.
    %
    % 3-06-26: Added sinking logic
    %
    % 3-12-26: Added dropdown-facing API so GUI can populate and select
    %          views directly from this class.

    properties
        Axes
        
        BoundaryBox (1,4) double = [0 0 6 9] % Simulation boundary box: [x0, y0, width, height]     
        MinefieldBox (1,4) double = [1.5 1.5 3 6] % Minefield rectangle: [x0, y0, width, height]
        WaterZ (1,1) double = 0 % Water surface elevation reference level

        % ---- Ship proportions ----
        % 3-05-26: Updated Comments
        ShipLength (1,1) double = 0.95
        ShipBeam   (1,1) double = 0.08
        ShipDraft  (1,1) double = 0.11
        ShipHullHeight (1,1) double = 0.14 % Hull vertical extent (keel/deck)
        ShipDeckHeight (1,1) double = 0.09 % Superstructure height above deck 

        % 3-06-26: Silhouette shaping 
        BowRakeFrac (1,1) double = 0.22        % fraction of length devoted to bow rake
        SternFrac (1,1) double = 0.12   % fraction devoted to stern shaping
        SuperstructureStartFrac (1,1) double = 0.18 % where superstructure begins 
        SuperstructureEndFrac   (1,1) double = 0.70 % where superstructure ends 
        SuperstructureStepFrac  (1,1) double = 0.12 % length of forward step 
        ExtrudeBeamFrac (1,1) double = 0.70    % extrusion thickness as fraction of beam

        MineRadius (1,1) double = 0.045 % Mine size
        FlashPause (1,1) double = 0.06 % Flash effect duration

        % Sinking controls
        OceanFloorZ (1,1) double = -0.32 
        SinkStep (1,1) double = 0.18
    end

    properties (Access=private)
        % Scene baseline 
        WaterSurf % Handle to the water object.
        BoundaryLine % Handle to the rectangle that outlines sim boundary.
        MinefieldLine % Handle to the rectangle that outlines sim minefield.

        % Graphic groups
        ShipGroups = gobjects(0)
        MineGroups = gobjects(0)

        ShipSinkProgress double = zeros(0,1) % Per-ship sink animation state index 

        % Cached counts from the previous update step.
        LastAliveCount double = NaN
        LastRemainingCount double = NaN

        BaseAxesColor (1,3) double = [0.94 0.97 1.0] % Default background color for the view.

        % ---- Camera presets ----
        % Each row is in degrees (view(az,el)).
        viewPresets double = [
            35  24;   % 1) Iso
            0    0;   % 2) Side-X
            90   0;   % 3) Side-Y 
            0   90;   % 4) Top
            180 15;   % 5) Front-Low
        ]
        viewNames cell = {'Iso','Side-X','Side-Y','Top','Front-Low'}
        viewIdx (1,1) double = 1 % Default view index 
    end

    methods
        function obj = SESideViewTacticalStatus(ax, boundaryBox, minefieldBox)
            % Constructor
            %
            % Inputs:
            %   ax          - axes handle supplied by the GUI
            %   boundaryBox - optional boundary box override
            %   minefieldBox- optional minefield box override
            %

            if nargin >= 1 && ~isempty(ax)
                obj.Axes = ax;
            end
            if nargin >= 2 && numel(boundaryBox) == 4
                obj.BoundaryBox = double(boundaryBox);
            end
            if nargin >= 3 && numel(minefieldBox) == 4
                obj.MinefieldBox = double(minefieldBox);
            end
            if ~isempty(obj.Axes) && isgraphics(obj.Axes)
                obj.initializeAxes();
            end
        end

        % ---------------- Camera controls ----------------
        % 3-05-26: Added functions to adjust view angle
        function nextView(obj)
            obj.viewIdx = obj.viewIdx + 1;
            if obj.viewIdx > size(obj.viewPresets,1)
                obj.viewIdx = 1;
            end
            obj.applyViewPreset();
        end

        function applyViewPreset(obj)
            if isempty(obj.Axes) || ~isgraphics(obj.Axes)
                return;
            end
            az = obj.viewPresets(obj.viewIdx,1);
            el = obj.viewPresets(obj.viewIdx,2);
            view(obj.Axes, az, el);
        end

        function name = getViewName(obj)
            if obj.viewIdx >= 1 && obj.viewIdx <= numel(obj.viewNames)
                name = obj.viewNames{obj.viewIdx};
            else
                name = obj.viewNames{1};
            end
        end

        function viewNames = getViewNames(obj)
            % 3-12-26: Added so GUI dropdown can populate directly from renderer.
            viewNames = obj.viewNames;
        end

        function idx = getViewIndex(obj)
            % 3-12-26: Added so GUI can query active view index if needed.
            idx = obj.viewIdx;
        end

        function setViewIndex(obj, idx)
            % 3-12-26: Added so GUI can select view by numeric index.
            if isempty(idx) || ~isscalar(idx) || ~isfinite(idx)
                return;
            end

            idx = round(double(idx));

            if idx < 1 || idx > numel(obj.viewNames)
                return;
            end

            obj.viewIdx = idx;
            obj.applyViewPreset();
        end

        function setViewByName(obj, viewName)
            % 3-12-26: Added so GUI dropdown can select a view by label.
            if isempty(viewName)
                return;
            end

            if isstring(viewName)
                viewName = char(viewName);
            end

            matchIdx = find(strcmpi(viewName, obj.viewNames), 1, 'first');
            if isempty(matchIdx)
                return;
            end

            obj.viewIdx = matchIdx;
            obj.applyViewPreset();
        end
        % ----------------------------------------------------------

        function initializeAxes(obj)
            % initializeAxes
            %
            % Clears and re-prepares the 3D scene.
            %
            % This method:
            %   - resets the axes
            %   - configures camera / aspect / labels
            %   - draws the water plane
            %   - draws the simulation boundary
            %   - draws the minefield rectangle
            %
            % This is called:
            %   - once at construction
            %   - after reset
            %   - if the water object was deleted and needs rebuilding

            ax = obj.Axes;

            cla(ax);
            hold(ax, 'on');
            grid(ax, 'on');
            axis(ax, 'equal');
            xlabel(ax, 'X (nm)');
            ylabel(ax, 'Y (nm)');
            zlabel(ax, 'Z');

            set(ax, ...
                'Color', obj.BaseAxesColor, ...
                'Box', 'on', ...
                'Projection', 'perspective');

            xlim(ax, [obj.BoundaryBox(1), obj.BoundaryBox(1)+obj.BoundaryBox(3)]);
            ylim(ax, [obj.BoundaryBox(2), obj.BoundaryBox(2)+obj.BoundaryBox(4)]);
            % zlim(ax, [-0.35, 0.35]); - 3-05-26: Did not like this.
            zlim(ax, [obj.OceanFloorZ - 0.10, 0.35]);
            daspect(ax, [1 1 0.18]);
            camlight(ax, 'headlight');
            material(ax, 'dull');

            % Camera 
            obj.applyViewPreset();

            % Water surface
            [X,Y] = meshgrid( ...
                [obj.BoundaryBox(1), obj.BoundaryBox(1)+obj.BoundaryBox(3)], ...
                [obj.BoundaryBox(2), obj.BoundaryBox(2)+obj.BoundaryBox(4)]);

            Z = zeros(size(X)) + obj.WaterZ;

            obj.WaterSurf = surf(ax, X, Y, Z, ...
                'FaceAlpha', 0.75, ...
                'EdgeAlpha', 0.10, ...
                'FaceColor', [0.55 0.82 0.95]);

            % Draw the outer operating area slightly above the waterline so
            % it remains visible and does not z-fight with the surface.
            obj.BoundaryLine = obj.drawRect3( ...
                obj.BoundaryBox, [0.15 0.3 0.45], 1.2, obj.WaterZ + 0.002);

            % Draw the minefield region in a more warning-like color.
            obj.MinefieldLine = obj.drawRect3( ...
                obj.MinefieldBox, [0.75 0.25 0.25], 1.4, obj.WaterZ + 0.003);
        end

        function reset(obj)
            % reset
            %
            % Clears all dynamic ship/mine graphics and reinitialize
            %
            % Best called between simulation runs so that stale
            % graphics handles do not remain.

            obj.deleteGroups(obj.ShipGroups);
            obj.deleteGroups(obj.MineGroups);
            obj.ShipGroups = gobjects(0);
            obj.MineGroups = gobjects(0);
            obj.ShipSinkProgress = zeros(0,1);

            % Reset event-tracking state.
            obj.LastAliveCount = NaN;
            obj.LastRemainingCount = NaN;

            if ~isempty(obj.Axes) && isgraphics(obj.Axes)
                obj.initializeAxes();
            end
        end

        function update(obj, simEngine)
            % update
            %
            % Main public render call.
            %
            % Input:
            %   simEngine - existing simulation engine object
            %g
            % What it does:
            %   - read ship state from simEngine.fleet.ships
            %   - read mine state from simEngine.minefield.mines
            %   - redraw ships and mines
            %   - detect changes in alive / remaining counts
            %   - flash red for destruction
            %   - flash green for successful exits

            if isempty(simEngine) || isempty(obj.Axes) || ~isgraphics(obj.Axes)
                return;
            end

            % If the scene base objects were deleted externally, rebuild.
            if isempty(obj.WaterSurf) || ~isgraphics(obj.WaterSurf)
                obj.initializeAxes();
            end

            % Pull current simulation entities.
            ships = simEngine.fleet.ships;
            mines = simEngine.minefield.mines;
            % Redraw dynamic content.
            obj.redrawShips(ships);
            obj.redrawMines(mines);

            drawnow limitrate nocallbacks;

            % Read summary counts from the engine. These are used to infer
            % visual events between frames.
            aliveCount = simEngine.getNumUnsunkShips();
            remainingCount = simEngine.getNumShipsRemaining();

            % Compare with previous step to detect losses or successful exits.
            if ~isnan(obj.LastAliveCount)
                if aliveCount < obj.LastAliveCount
                    % At least one ship was destroyed.
                    obj.flash([1.0 0.82 0.82]);
                elseif remainingCount < obj.LastRemainingCount && aliveCount == obj.LastAliveCount
                    % A ship left the operating area while still alive.
                    obj.flash([0.84 1.0 0.84]);
                end
            end

            % Cache counts for next update.
            obj.LastAliveCount = aliveCount;
            obj.LastRemainingCount = remainingCount;
        end
    end

    methods (Access=private)
        function h = drawRect3(obj, box, color, lw, z)
            % drawRect3
            %
            % Draws a rectangle outline at constant elevation z.
            %
            % Inputs:
            %   box   = [x y width height]
            %   color = line color
            %   lw    = line width
            %   z     = constant height for all corners
            %
            % Output:
            %   h     = line graphics handle

            x = box(1);
            y = box(2);
            w = box(3);
            hgt = box(4);

            x = box(1); y = box(2); w = box(3); hgt = box(4);
            xs = [x x+w x+w x x];
            ys = [y y y+hgt y+hgt y];
            zs = zeros(size(xs)) + z;

            % 3-05-26: Easier to use this over prior
            h = plot3(obj.Axes, xs, ys, zs, '-', 'LineWidth', lw, 'Color', color);
        end

        function redrawShips(obj, ships)
            % redrawShips
            %
            % Removes all previous ship graphics and redraws every ship from
            % the current simulation state.

            obj.deleteGroups(obj.ShipGroups);
            obj.ShipGroups = gobjects(numel(ships),1);

            if numel(obj.ShipSinkProgress) ~= numel(ships)
                obj.ShipSinkProgress = zeros(numel(ships),1);
            end

            for k = 1:numel(ships)
                ship = ships(k);

                % Skip invalid ship references.
                if isempty(ship) || ~isvalid(ship)
                    continue;
                end

                % Color scheme
                %   alive in bounds   -> gray 
                %   destroyed         -> red 
                %   alive and exited  -> green 
                if ship.alive
                    obj.ShipSinkProgress(k) = 0;
                    cHull = [0.42 0.44 0.48];
                    cDeck = [0.70 0.72 0.76];
                else
                    obj.ShipSinkProgress(k) = min(1, obj.ShipSinkProgress(k) + obj.SinkStep);
                    cHull = [0.78 0.18 0.18];
                    cDeck = [0.95 0.55 0.55];
                end

                % If the ship survives make green.
                inBounds = ship.pos_y <= (obj.BoundaryBox(2) + obj.BoundaryBox(4));
                if ~inBounds && ship.alive
                    cHull = [0.2 0.6 0.2];
                    cDeck = [0.45 0.82 0.45];
                end

                % Group ships so all parts can be
                % deleted together during the next refresh.
                g = hggroup('Parent', obj.Axes);
                obj.drawShipDestroyerSilhouette(g, ship, cHull, cDeck, obj.ShipSinkProgress(k));
                obj.ShipGroups(k) = g;
            end
        end

        function redrawMines(obj, mines)
            % redrawMines
            %
            % Removes all previous mine graphics and redraws all mines
            % according to the current simulation state.

            obj.deleteGroups(obj.MineGroups);
            obj.MineGroups = gobjects(numel(mines),1);

            for k = 1:numel(mines)
                mine = mines(k);

                % Skip invalid mine references.
                if isempty(mine) || ~isvalid(mine)
                    continue;
                end

                g = hggroup('Parent', obj.Axes);
                obj.drawMineGroup(g, mine);
                obj.MineGroups(k) = g;
            end
        end

        function drawShipDestroyerSilhouette(obj, parentGroup, ship, hullColor, deckColor, sinkProgress)
            % drawShipGroup
            %
            % Draws one ship as two blocks:
            %   1) main hull block
            %   2) upper superstructure block
            %
            % The ship is rotated based on heading_deg and then translated
            % to the ship's current simulation position to show direction.
            %
            % Visual interpretation:
            %   - hull = lower mass of the vessel
            %   - superstructure = upper body
            %   - bow line = simple heading

            if nargin < 6
                sinkProgress = 0;
            end
            L = obj.ShipLength;
            B = obj.ShipBeam;
            draft = obj.ShipDraft;
            hullH = obj.ShipHullHeight;
            deckH = obj.ShipDeckHeight;

            zKeel = -draft;
            zDeck = hullH - draft;

            % Side profile in coordinates (y,z polygon, closed)
            [yProf, zProf] = obj.makeDestroyerSideProfile(L, zKeel, zDeck, deckH);

            % Thickness 
            halfT = (obj.ExtrudeBeamFrac * B) / 2;

            % Hull solid
            Vloc = obj.extrudeProfileYZToVertices(yProf, zProf, halfT);
            Floc = obj.extrudeProfileYZToFaces(numel(yProf));
            V = obj.localPointsToWorld(Vloc, ship, sinkProgress);

            patch(obj.Axes, ...
                'Vertices', V, ...
                'Faces', Floc, ...
                'Parent', parentGroup, ...
                'FaceColor', hullColor, ...
                'EdgeColor', [0 0 0], ...
                'LineWidth', 0.6, ...
                'FaceAlpha', 0.96);

            % Superstructure slab
            [ySS, zSS] = obj.makeSuperstructureProfile(L, zDeck, deckH);
            VssLoc = obj.extrudeProfileYZToVertices(ySS, zSS, 0.55*halfT);
            FssLoc = obj.extrudeProfileYZToFaces(numel(ySS));
            Vss = obj.localPointsToWorld(VssLoc, ship, sinkProgress);

            patch(obj.Axes, ...
                'Vertices', Vss, ...
                'Faces', FssLoc, ...
                'Parent', parentGroup, ...
                'FaceColor', deckColor, ...
                'EdgeColor', 'none', ...
                'FaceAlpha', 0.96);

            % Bow cue
            bowCueLocal = [
                0,   0, zDeck + 0.01;
                0, L/2, zDeck + 0.01
            ];
            bowCueWorld = obj.localPointsToWorld(bowCueLocal, ship, sinkProgress);

            plot3(obj.Axes, ...
                bowCueWorld(:,1), bowCueWorld(:,2), bowCueWorld(:,3), ...
                'Parent', parentGroup, ...
                'Color', [0.08 0.08 0.08], 'LineWidth', 1.0);
        end

        function [y, z] = makeDestroyerSideProfile(obj, L, zKeel, zDeck, deckH)
            % 3-06-26: Silhouette outline (Y-Z polygon).
            %
            % Local convention:
            %   Y increases toward bow (+L/2)
            %   Y decreases toward stern (-L/2)

            yBow =  L/2;
            yStern = -L/2;

            % Bow rake region
            yBowRake = yBow - obj.BowRakeFrac * L;

            % Stern region
            ySternKink = yStern + obj.SternFrac * L;

            % Superstructure extents along deck
            ySS0 = yStern + obj.SuperstructureStartFrac * L;
            ySS1 = yStern + obj.SuperstructureEndFrac   * L;
            yStep = ySS1 - obj.SuperstructureStepFrac * L;

            zSS1 = zDeck + 0.65*deckH;   % main superstructure height
            zSS2 = zDeck + 1.05*deckH;   % forward bridge

            % Outline points
            % Start at bow tip 
            y = [
                yBow;                 % bow deck edge
                yBowRake;             % bow rake down start
                yBowRake;             % bow rake down end at keel
                ySternKink;           % keel toward stern
                yStern;               % transom bottom
                yStern;               % transom up
                ySS0;                 % deck to SS start
                ySS0;                 % SS up
                yStep;                % SS forward (main)
                yStep;                % step up
                ySS1;                 % upper forward
                ySS1;                 % step down to deck
                yBow;                 % deck back to bow
                yBow                  % close (repeat)
            ];

            z = [
                zDeck;                % bow deck
                zDeck;                % bow rake start (deck)
                zKeel;                % bow rake to keel
                zKeel;                % keel line
                zKeel;                % transom bottom
                zDeck*0.72;           % transom up (stern)
                zDeck;                % deck aft
                zSS1;                 % SS rise
                zSS1;                 % SS main top
                zSS2;                 % step up
                zSS2;                 % upper top
                zDeck;                % step down
                zDeck;                % deck to bow
                zDeck                 % close
            ];
        end

        function [y, z] = makeSuperstructureProfile(obj, L, zDeck, deckH)
            % 3-06-26: Secondary slab profile to add structure depth
            % without towers. Closed polygon.

            yStern = -L/2;
            y0 = yStern + (obj.SuperstructureStartFrac+0.06) * L;
            y1 = yStern + (obj.SuperstructureEndFrac-0.10)   * L;

            z0 = zDeck + 0.10*deckH;
            z1 = zDeck + 0.75*deckH;

            y = [y0; y0; y1; y1; y0];
            z = [z0; z1; z1; z0; z0];
        end

        function V = extrudeProfileYZToVertices(~, yProf, zProf, halfThickness)
            % Closed Y-Z profile into X-Y-Z vertices.
            % Creates two sheets at x=-halfThickness and x=+halfThickness.
            %
            % V rows:
            %   1..N   : left side  (x=-halfT)
            %   N+1..2N: right side (x=+halfT)

            N = numel(yProf);
            xL = -halfThickness * ones(N,1);
            xR =  halfThickness * ones(N,1);

            V = [
                xL, yProf(:), zProf(:);
                xR, yProf(:), zProf(:)
            ];
        end

        function F = extrudeProfileYZToFaces(~, N)
            % 3-05-26: Build faces for a closed polygon.
            %
            %
            % Vertex layout:
            %   1..N     : left sheet  (x = -halfT)
            %   N+1..2N  : right sheet (x = +halfT)
            %
            % Output:
            %   F is Mx3 triangle indices 
        
            if N < 4
                F = zeros(0,3);
                return;
            end
        
            nSeg = N - 1;  % because point N repeats point 1
        
            % ----- Side shell for two triangles per segment -----
            % quad: [Li, Li+1, Ri+1, Ri] -> triangles [Li Li+1 Ri+1] and [Li Ri+1 Ri]
            sideTri = zeros(2*nSeg, 3);
            t = 1;
            for i = 1:nSeg
                Li  = i;
                Li1 = i+1;
                Ri  = N + i;
                Ri1 = N + (i+1);
        
                sideTri(t,:)   = [Li,  Li1, Ri1]; t = t + 1;
                sideTri(t,:)   = [Li,  Ri1, Ri ]; t = t + 1;
            end
        
            % ----- Caps (fan triangulation) -----
            % Uses vertices 1..(N-1) as the polygon without duplicated last point.
            M = N - 1;
            capLeft  = zeros(max(0, M-2), 3);
            capRight = zeros(max(0, M-2), 3);
        
            % Left cap of [1 i i+1]
            tt = 1;
            for i = 2:(M-1)
                capLeft(tt,:) = [1, i, i+1];
                tt = tt + 1;
            end
        
            % Right cap: reverse winding so normals face outward
            % Right indices offset by N: (N+1) is the "same" as 1 on right side
            tt = 1;
            for i = 2:(M-1)
                capRight(tt,:) = [N+1, N+i+1, N+i];
                tt = tt + 1;
            end
        
            % All faces are triangles (Mx3), so vertcat is valid
            F = [sideTri; capLeft; capRight];
        end

        function Pworld = localPointsToWorld(obj, Plocal, ship, sinkProgress)
            if nargin < 4
                sinkProgress = 0;
            end

            Pship = obj.applySinkTransform(Plocal, sinkProgress);

            theta = deg2rad(ship.heading_deg - 90);
            Rxy = [cos(theta) -sin(theta); sin(theta) cos(theta)];

            XY = Pship(:,1:2) * Rxy';
            Pworld = [XY(:,1) + ship.pos_x, XY(:,2) + ship.pos_y, Pship(:,3)];
        end

        function P = applySinkTransform(obj, P, sinkProgress)
            sinkProgress = max(0, min(1, sinkProgress));
            if sinkProgress <= 0
                return;
            end

            % Roll the ship 180 deg about its longitudinal axis (local Y),
            % then translate it downward so it settles onto the ocean floor.
            phi = pi * sinkProgress;
            c = cos(phi);
            s = sin(phi);
            Rroll = [c 0 s; 0 1 0; -s 0 c];

            P = P * Rroll';

            targetBottomZ = obj.WaterZ + sinkProgress * (obj.OceanFloorZ - obj.WaterZ);
            currentBottomZ = min(P(:,3));
            P(:,3) = P(:,3) + (targetBottomZ - currentBottomZ);
        end

        function drawMineGroup(obj, parentGroup, mine)
            [sx, sy, sz] = sphere(10);
            r = obj.MineRadius;
            zCenter = obj.WaterZ;

            if mine.alive
                fc = [0.72 0.12 0.12];
                ec = [0.2 0.05 0.05];
                fa = 0.95;
            else
                fc = [1.0 0.72 0.2];
                ec = [0.7 0.35 0.1];
                fa = 0.45;
            end

            surf(obj.Axes, ...
                mine.pos_x + r*sx, ...
                mine.pos_y + r*sy, ...
                zCenter + 0.6*r*sz, ...
                'Parent', parentGroup, ...
                'FaceColor', fc, ...
                'EdgeColor', ec, ...
                'FaceAlpha', fa);
        end

        function flash(obj, color)
            if isempty(obj.Axes) || ~isgraphics(obj.Axes)
                return;
            end

            oldColor = get(obj.Axes, 'Color');
            set(obj.Axes, 'Color', color);
            drawnow limitrate nocallbacks;
            pause(obj.FlashPause);

            if isgraphics(obj.Axes)
                set(obj.Axes, 'Color', oldColor);
            end
        end

        function deleteGroups(~, groups)
            % deleteGroups
            %
            % Safely deletes all valid handles stored in array
            % before full redraws.

            if isempty(groups)
                return;
            end

            for i = 1:numel(groups)
                if isgraphics(groups(i))
                    delete(groups(i));
                end
            end
        end
    end
end