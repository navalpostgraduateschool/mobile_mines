classdef SESimulatorEngine < handle
    properties(SetAccess=protected)
        fleet % SEFleet object
        minefield % SEMinefield object
        numShips % Number of ships in the fleet
        numMines % Number of mines in the minefield
        boundary_box % Boundary box:  [x-coordinate, y-coordinate, width, height]
        minfield_box % Minefield box: [x-coordinate, y-coordinate, width, height]
        axes_h % Graphics Handle for axes things will be drawn to
        fps = 20; % desired frames per second
        mineDamageRange % Mine damage radius
        minedetectRange % mine detection range

        curIteration = 0;
        numIterations = 1;

    end
    
    methods
        function obj = SESimulatorEngine(boundary_box, axes_handle)
            narginchk(0, 2);

            % Create fleet
            obj.fleet = SEFleet();            
            % Create minefield
            obj.minefield = SEMinefield();

            % initialize as applicable based on the number of input arguments
            if nargin>0
                obj.setBoundaryBox(boundary_box);
                obk.setMinefieldBox(minefield_box);

                if nargin>1

                    obj.setAxesHandle(axes_handle);
                end
            end            
        end

        function num = getNumUnexplodedMines(obj)
            num = obj.minefield.getNumUnexplodedMines();
        end

        function num = getNumUnsunkShips(obj)
            num = obj.fleet.getNumAlive();
        end

        function run(obj, numIterations)


        end

        function setBoundaryBox(obj, boundary_box)
            obj.fleet.setBoundaryBox(boundary_box);
        end

        function setMinefieldBox(obj, minefield_box)
            obj.minefield.setBoundaryBox(minefield_box);
        end

        function setAxesHandle(obj, axes_h)
            obj.fleet.setAxesHandle(axes_h);
            obj.minefield.setAxesHandle(axes_h);
        end

        function behaviors = getValidFleetBehaviors(obj)
            behaviors = obj.fleet.BEHAVIORS;
        end

        function layouts = getValidMinefieldLayouts(obj)
            layouts = obj.minefield.POSSIBLE_LAYOUTS;
        end

        function setFleetBehavior(obj, behavior)
            obj.fleet.setBehavior(behavior);
        end

        function setMinefieldLayout(obj, layout)
            obj.minefield.setLayout(layout);
        end

        function didSet = setNumMines(obj, numMines)
            didSet = false;
            if nargin>1 && ~isempty(numMines) && numMines>= 0
                obj.numMines = floor(numMines);
                obj.minefield.setNumMines(obj.numMines);
                didSet = true;
            end
        end

        function didSet = setDamageRadius(obj, damageRadius)
            didSet = false;
            if nargin>1 && ~isempty(damageRadius) && damageRadius>= 0
                obj.mineDamageRange = floor(damageRadius);
                obj.minefield.setDamageRadius(obj.mineDamageRange);
                didSet = true;
            end
        end        

        function didSet = setdetectRange(obj, detectRange)
            didSet = false;
            if nargin>1 && ~isempty(detectRange) && detectRange>= 0
                obj.minedetectRange = floor(detectRange);
                obj.minefield.setdetectRange(obj.minedetectRange);
                didSet = true;
            end
        end        
        
        function didSet = setNumShips(obj, numShips)
            didSet = false;
            if nargin>1 && ~isempty(numShips) && numShips>= 0
                obj.numShips = floor(numShips);
                obj.fleet.setNumShips(obj.numShips);
                didSet = true;
            end
        end

     

        % TODO - talk with @hyatt about the updateFleetPosition method and
        % detection of detonations ...
        function update(obj)
            % Update fleet position
            obj.updateFleetPosition();
            
            % Update minefield
            obj.minefield.update();
            
            % Check for mine detonations
            obj.detectMineDetonations();
        end
        
        function refreshDisplay(obj)
            obj.minefield.refreshDisplay();
            obj.fleet.refreshDisplay();

        end

        function updateFleetPosition(obj)
            obj.fleet.updatePosition();
        end
        

        function detectMineDetonations(obj)
            for i = 1:obj.numShips
                ship = obj.fleet.graphicsHandle.Ships(i);
                if obj.minefield.isInDamageRange(ship.PositionX, ship.PositionY)
                    obj.minefield.mineExplosion(i);
                end
            end
        end        

        function changeFleetBehavior(obj, newBehavior)
            obj.fleet.changeBehavior(newBehavior);
        end


        % 7.1 **Transit Success Rate**:
        %   - Percentage of ships that successfully transit through the minefield.
        % 7.2 **Ships Destoryed**:
        %   - Number of ships destroyed by mines.
        % 7.3 **Ships Survived**:
        %   - Number of ships that survived the transit.
        % 7.4 **Mine Statistics**:
        %   a- Percentage of mines remaining after each run.
        %   b- Number of mines destroyed.
        %   c- Number of mines that survived each run.
        function stats = getStatistics(obj)

            stats = struct();
            
            %% 7.3 **Ships Survived**:
            stats.shipsRemaining = obj.getNumUnsunkShips();

            %% 7.1 **Transit Success Rate**:            
            stats.numShips = obj.numShips;
            stats.proportionShipsRemaining = stats.shipsRemaining / obj.numShips;  %transitSuccessRate = # of ships alive at end / # of ships at start
            % transitSuccessRate - but only if you have completed the loop
            
            
            %% 7.2 **Ships Killed**:            
            stats.shipsSunk = stats.numShips - stats.shipsRemaining;

            %% 7.4 **Mine Statistics**:
            stats.minesRemaining = obj.getNumUnexplodedMines();            
            stats.numMines = obj.numMines;            
            stats.minesDetonated = stats.numMines - stats.minesRemaining;
            stats.proportionMinesRemaining = stats.minesRemaining / stats.numMines;
            

            %% TO DO AFTER GETTING ONE TRIAL TO RUN CORRECTLY
            % Average Number of ships alive at end of q route for all trials
            % meanSurvivalRate = sum(numShipsALive) / numTrials;
        end
    end
end