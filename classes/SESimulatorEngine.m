classdef SESimulatorEngine < handle
    events
        SimUpdated;% StepEnded;  % each simulation has a number of steps/updates (iterations)
        SimCompleted; % monte carlo simulations consist of a number of simulations;
        MonteCarloFinished% 
    end

    properties(SetAccess=protected)
        fleet % SEFleet object
        minefield % SEMinefield object
        boundary_box % Boundary box:  [x-coordinate, y-coordinate, width, height]
        minfield_box % Minefield box: [x-coordinate, y-coordinate, width, height]
        axes_h % Graphics Handle for axes things will be drawn to
        fps = 10; % desired frames per second
        mineDamageRange % Mine damage radius
        minedetectRange % mine detection range

        time_multiplier = 10; % Speed up the simulation by this factor
        animate = true;

        curSimulation = 0;  % the current simulation being run.  Each simulation consists of a number of steps where the fleet goes through the minefiles
        numSimulations = 1;  % The number of simulations to run

        curSimulationStep = 0;
        maxSimulationSteps = 50;
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

        % Reset the simulation for the current configuration
        function reset(obj)
            %rng(obj.curSimulation); % seed randomizer for repeatability
            obj.fleet.reset();
            obj.minefield.reset();
            obj.curSimulationStep = 0;
        end

        function displayShipHeadings(obj, shouldDisplay)
            obj.fleet.displayShipHeadings(shouldDisplay);
        end

        function num = getNumShips(obj)
            num = obj.fleet.numShips;
        end

        function num = getNumMines(obj)
            num = obj.minefield.number_of_mines;
        end

        function num = getNumUnexplodedMines(obj)
            num = obj.minefield.getNumUnexplodedMines();
        end

        % Available ships include those that have not been sunk
        % and that have yet to transit through the minefield
        function num = getNumShipsAvailable(obj)
            num = obj.fleet.getNumShipsRemaining();
        end

        function num = getNumUnsunkShips(obj)
            num = obj.fleet.getNumAlive();
        end

        function run(obj, numSimulationsToRun)
            if nargin<2 || isempty(numSimulationsToRun) || numSimulationsToRun < 0
                numSimulationsToRun = 1;
            end

            % make sure we aren't dealing with rational/decimal numbers
            obj.numSimulations = floor(numSimulationsToRun);

            for simulationNum = 1:obj.numSimulations
                obj.curSimulation = simulationNum;
                obj.reset();
                while ~obj.simulationDone()
                    obj.update();
                    obj.notify('SimUpdated');
                end
                obj.notify('SimCompleted');
            end
            obj.notify('MonteCarloFinished');
        end

        function isDone = simulationDone(obj)
            maxSteps = obj.maxSimulationSteps*obj.fps*obj.time_multiplier;
            numShipsLeft = obj.getNumShipsRemaining();
            numMinesLeft = obj.getNumUnexplodedMines();
            isDone = 0 == numShipsLeft || ...
                0 == numMinesLeft || ...
                obj.curSimulationStep >= maxSteps;
        end

        function num = getNumShipsRemaining(obj)
            num = obj.fleet.getNumShipsRemaining();
        end

        function setBoundaryBox(obj, boundary_box)
            obj.fleet.setBoundaryBox(boundary_box);
        end

        function didSet = setMinefieldBox(obj, minefield_box)
            didSet = obj.minefield.setBoundaryBox(minefield_box);
        end



        function didSet = setNumRuns(obj,numRuns)
            didSet = false;
            if numRuns >= 0
                obj.numSimulations = numRuns; 
                didSet = true;
            end 
        end


        function setAxesHandle(obj, axes_h)
            obj.fleet.setAxesHandle(axes_h);
            obj.minefield.setAxesHandle(axes_h);
        end

        function behaviors = getValidFleetBehaviors(obj)
            behaviors = obj.fleet.BEHAVIORS;
        end

        function layouts = getValidMinefieldLayouts(obj)
            layouts = obj.minefield.LAYOUTS;
        end

        function didSet = setFleetBehavior(obj, behavior)
            didSet = obj.fleet.setBehavior(behavior);
        end

        function didSet = setMinefieldLayout(obj, layout)
            didSet = obj.minefield.setLayout(layout);
        end

        function didSet = setNumMines(obj, numMines)
            didSet = false;
            if nargin>1 && ~isempty(numMines) && numMines>= 0
                didSet = obj.minefield.setNumMines(numMines);
                if didSet
                    obj.minefield.resetLayout();
                end
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

        function setMineType(obj, mineType)
            obj.minefield.setMineType(mineType);
        end

        function didSet = setNumShips(obj, numShips)
            didSet = false;
            if nargin>1 && ~isempty(numShips) && numShips>= 0
                didSet = obj.fleet.setNumShips(numShips);
            end
        end
     

        % TODO - talk with @hyatt about the updateFleetPosition method and
        % detection of detonations ...
        function update(obj)
            % Update fleet position
            obj.fleet.update();
            
            % Update minefield
            obj.minefield.update();
            
            % Check for mine detonations
            obj.detectMineDetonations();

            if obj.animate
                pause(1/obj.fps);
            end
            obj.curSimulationStep = obj.curSimulationStep + 1;
        end
        
        function refreshDisplay(obj)
            obj.minefield.refreshDisplay();
            obj.fleet.refreshDisplay();
        end

        function updateFleetPosition(obj)
            obj.fleet.updatePosition();
        end
        
        function detectMineDetonations(obj)
            minesExploded = false(obj.getNumMines,1);
            for shipIdx = 1:obj.getNumShips()
                [ship, isValid] = obj.fleet.getShip(shipIdx);
                if isValid
                    [inMinesDamageRange, inMinesDetectionRange, distances] = obj.minefield.getMineRanges(ship);

                    if any(inMinesDamageRange)
                        minesExploded(inMinesDamageRange) = true;
                        ship.sink();
                    end
                end
            end

            if any(minesExploded)
                mineIdx = find(minesExploded);
                for n=1:numel(mineIdx)
                    obj.minefield.mines( mineIdx(n)).explode();
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
            stats.numShips = obj.getNumShips();
            stats.proportionShipsRemaining = stats.shipsRemaining / stats.numShips;  %transitSuccessRate = # of ships alive at end / # of ships at start
            % transitSuccessRate - but only if you have completed the loop
            
            
            %% 7.2 **Ships Killed**:            
            stats.shipsSunk = stats.numShips - stats.shipsRemaining;

            %% 7.4 **Mine Statistics**:
            stats.minesRemaining = obj.getNumUnexplodedMines();            
            stats.numMines = obj.getNumMines();
            stats.minesDetonated = stats.numMines - stats.minesRemaining;
            stats.proportionMinesRemaining = stats.minesRemaining / stats.numMines;
            

            %% TO DO AFTER GETTING ONE TRIAL TO RUN CORRECTLY
            % Average Number of ships alive at end of q route for all trials
            % meanSurvivalRate = sum(numShipsALive) / numTrials;
        end
    end
end