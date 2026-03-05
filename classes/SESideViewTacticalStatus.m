classdef SESideViewTacticalStatus < handle
    % SESideViewTacticalStatus
    %
    % Design Intent:
    %   X, Y = horizontal simulation plane
    %   Z    = vertical axis used for side view presentation
    %
    % Visual Intent:
    %   - Ships are represented as extruded boxes
    %   - Each ship has:
    %       * a hull section below / near the waterline
    %       * a superstructure above the hull
    %   - Mines are small spheres located at the waterline

    properties
        Axes

        % Simulation boundary box in the format:
        % [x0, y0, width, height]
        BoundaryBox (1,4) double = [0 0 6 9]

        % Minefield rectangle in the same format:
        % [x0, y0, width, height]
        %
        % This is shown separately from the outer boundary so the user can
        % see where the mine threat region is located.
        MinefieldBox (1,4) double = [1.5 1.5 3 6]  
		
        WaterZ (1,1) double = 0 % Water surface elevation reference level.
        ShipDraft (1,1) double = 0.12 % Draft is how far a hull extends below the waterline.
        ShipHullHeight (1,1) double = 0.12 % Height of the hull body.
        ShipDeckHeight (1,1) double = 0.10 % Height of the superstructure.
        ShipLength (1,1) double = 0.55 % Overall ship length.
        ShipBeam (1,1) double = 0.08  % Overall ship (width)
        ShipSuperLength (1,1) double = 0.18 % Length of the upper superstructure.
        ShipSuperBeam (1,1) double = 0.05 % Width of the upper superstructure.
        MineRadius (1,1) double = 0.045 % Radius of mine spheres.
        FlashPause (1,1) double = 0.06 % Flash effect duration.
    end

    properties (Access=private)
        WaterSurf % Handle to the water object.
        BoundaryLine % Handle to the rectangle that outlines sim boundary.
        MinefieldLine % Handle to the rectangle that outlines sim minefield.

        ShipGroups = gobjects(0) % Graphics groups for all ship drawings.
		MineGroups = gobjects(0) % Graphics groups for all mine drawings.

        % Cached counts from the previous update step.
        LastAliveCount double = NaN
        LastRemainingCount double = NaN

        % Default background color for the view.
        BaseAxesColor (1,3) double = [0.94 0.97 1.0]
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

            % If the GUI already gave us a valid axes, prepare it now.
            if ~isempty(obj.Axes) && isgraphics(obj.Axes)
                obj.initializeAxes();
            end
        end

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
            view(ax, 3);
            axis(ax, 'equal');

            xlabel(ax, 'X (nm)');
            ylabel(ax, 'Y (nm)');
            zlabel(ax, 'Z');

            set(ax, ...
                'Color', obj.BaseAxesColor, ...
                'Box', 'on', ...
                'Projection', 'perspective');

            % Set scene limits from the simulation boundary.
            xlim(ax, [obj.BoundaryBox(1), obj.BoundaryBox(1)+obj.BoundaryBox(3)]);
            ylim(ax, [obj.BoundaryBox(2), obj.BoundaryBox(2)+obj.BoundaryBox(4)]);

            % Vertical range is artificial, only for presentation.
            zlim(ax, [-0.35, 0.35]);

            % Compress vertical scale slightly so the scene does not look
            % too tall relative to X and Y.
            daspect(ax, [1 1 0.18]);

            % Add simple lighting to make 3D patches easier to read.
            camlight(ax, 'headlight');
            material(ax, 'dull');

            % Create a simple rectangular water surface using surf().
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

            xs = [x x+w x+w x x];
            ys = [y y y+hgt y+hgt y];
            zs = zeros(size(xs)) + z;

            h = plot3(obj.Axes, xs, ys, zs, '-', ...
                'LineWidth', lw, ...
                'Color', color);
        end

        function redrawShips(obj, ships)
            % redrawShips
            %
            % Removes all previous ship graphics and redraws every ship from
            % the current simulation state.

            obj.deleteGroups(obj.ShipGroups);
            obj.ShipGroups = gobjects(numel(ships),1);

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
                    cHull = [0.45 0.47 0.52];
                    cDeck = [0.68 0.70 0.76];
                else
                    cHull = [0.8 0.2 0.2];
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

                obj.drawShipGroup(g, ship, cHull, cDeck);
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

        function drawShipGroup(obj, parentGroup, ship, hullColor, deckColor)
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

            L = obj.ShipLength;
            B = obj.ShipBeam;
            draft = obj.ShipDraft;
            hullH = obj.ShipHullHeight;
            deckH = obj.ShipDeckHeight;
            SL = obj.ShipSuperLength;
            SB = obj.ShipSuperBeam;

            % Convert heading into a rotation angle for the XY plane.
            % Using a -90 offset to align the local ship model with the
            % simulation's direction.
            theta = deg2rad(ship.heading_deg - 90);

            % Rotation matrix applied to local ship coordinates.
            R = [cos(theta) -sin(theta); ...
                 sin(theta)  cos(theta)];

            % Coordinates for the hull block.
            % The local Y direction is treated as the ship's length axis.
            hullLocal = [ ...
                -B/2, -L/2;
                 B/2, -L/2;
                 B/2,  L/2;
                -B/2,  L/2];

            % Rotate hull into coordinates.
            hullXY = (R * hullLocal')';
            hullXY(:,1) = hullXY(:,1) + ship.pos_x;
            hullXY(:,2) = hullXY(:,2) + ship.pos_y;

            % Vertical placement:
            %   z0 = keel-ish lower point
            %   z1 = hull top
            z0 = -draft;
            z1 = hullH - draft;

            obj.drawExtrudedBox(parentGroup, hullXY, z0, z1, hullColor);

            % Superstructure footprint is narrower and shorter than hull.
            superLocal = [ ...
                -SB/2, -0.15*L;
                 SB/2, -0.15*L;
                 SB/2, -0.15*L+SL;
                -SB/2, -0.15*L+SL];

            superXY = (R * superLocal')';
            superXY(:,1) = superXY(:,1) + ship.pos_x;
            superXY(:,2) = superXY(:,2) + ship.pos_y;

            obj.drawExtrudedBox(parentGroup, superXY, z1, z1+deckH, deckColor);

            % Simple bow indicator:
            % draw a short line from center toward the front of the ship.
            bow = (R * [0; L/2])';
            bow = bow + [ship.pos_x, ship.pos_y];

            plot3(obj.Axes, ...
                [ship.pos_x bow(1)], ...
                [ship.pos_y bow(2)], ...
                [z1+0.01 z1+0.01], ...
                'Color', [0.1 0.1 0.1], ...
                'LineWidth', 1.0, ...
                'Parent', parentGroup);
        end

        function drawMineGroup(obj, parentGroup, mine)
            % drawMineGroup
            %
            % Draws a mine as a sphere centered at the waterline.
            %
            % Alive mine:
            %   red
            %
            % Inactive mine:
            %   yellow

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

        function drawExtrudedBox(obj, parentGroup, xy4, z0, z1, faceColor)
            % drawExtrudedBox
            %
            % Creates a shape for the mines/ships:
            %   - a 4-corner XY footprint
            %   - a lower Z plane
            %   - an upper Z plane
            %
            % Inputs:
            %   xy4       - 4x2 XY corners in order
            %   z0, z1    - lower and upper vertical bounds
            %   faceColor - patch face color
            %
			
            % Vertex ordering:
            %   first 4 rows  -> lower face
            %   next  4 rows  -> upper face
            verts = [xy4, repmat(z0,4,1); ...
                     xy4, repmat(z1,4,1)];

            % Face definitions for a rectangular prism. 
			% Think Cube
            faces = [ ...
                1 2 3 4;   % bottom
                5 6 7 8;   % top
                1 2 6 5;   % side 1
                2 3 7 6;   % side 2
                3 4 8 7;   % side 3
                4 1 5 8];  % side 4

            patch(obj.Axes, ...
                'Vertices', verts, ...
                'Faces', faces, ...
                'Parent', parentGroup, ...
                'FaceColor', faceColor, ...
                'EdgeColor', [0.18 0.18 0.2], ...
                'FaceAlpha', 0.96);
        end

        function flash(obj, color)
            % flash
            %
            % Briefly changes the axes background color to provide event
            % feedback, then restores the original color.
            %
            % Intended event mapping:
            %   red   -> ship destroyed
            %   green -> ship exited successfully

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