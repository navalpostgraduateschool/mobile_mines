classdef SESimulatorEngine < SEBase
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

        % Group 7 (explosions) addition
        activeEmitters = []; % Array to track active particle emitters
        currentArrow_h; % <-- NEW: Handle for the visual arrow
        currentText_h;  % <-- NEW: Handle for the text label
		environment; % <-- NEW: Track the environment class

        time_multiplier = 10; % Speed up the simulation by this factor
        animate = true;
        debugMode = false;

        curSimulation = 0;  % the current simulation being run.  Each simulation consists of a number of steps where the fleet goes through the minefiles
        numSimulations = 1;  % The number of simulations to run

        curSimulationStep = 0;
        maxSimulationSteps = 50;

        isRunning = false;
    end

    properties (Dependent)
        dt
    end
    
    methods

        function obj = SESimulatorEngine(boundary_box, axes_handle)
            narginchk(0, 2);

            % Create fleet
            obj.fleet = SEFleet();            
            % Create minefield
            obj.minefield = SEMinefield();
			% Create Dummy Environment with a defensive fallback
            try
                obj.environment = SEEnvironment(); 
            catch
                % If the environment team's class is missing or broken, 
                % leave this empty so the engine uses its built-in fallback.
                obj.environment = []; 
            end

            % initialize as applicable based on the number of input arguments
            if nargin>0
                obj.setBoundaryBox(boundary_box);
                obj.setMinefieldBox(minefield_box);

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

            % Group 7 addition: Clear any active emitters from previous runs
            for e = 1:length(obj.activeEmitters)
                delete(obj.activeEmitters(e));
            end
            obj.activeEmitters = [];
            % end Group 7 (explosion) addition

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

        function value = get.dt(obj)
            value = 1/obj.fps;
        end

        function stop(obj)
            obj.isRunning = false;
        end

        function run(obj, numSimulationsToRun)
            if nargin<2 || isempty(numSimulationsToRun) || numSimulationsToRun < 0
                numSimulationsToRun = obj.numSimulations;
            end

            % make sure we aren't dealing with rational/decimal numbers
            obj.numSimulations = floor(numSimulationsToRun);

            obj.isRunning = true;

            for simulationNum = 1:obj.numSimulations
                obj.curSimulation = simulationNum;
                obj.reset();
                while ~obj.simulationDone() && obj.isRunning
                    obj.update();
                    obj.notify('SimUpdated');
                end
                obj.notify('SimCompleted');
            end
            obj.notify('MonteCarloFinished');

            obj.isRunning = false;
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
            % Next line is New code for Team 7
            obj.axes_h = axes_h; % <-- NEW: Save the handle for the engine to use!
            obj.fleet.setAxesHandle(axes_h);
            obj.minefield.setAxesHandle(axes_h);

            % NEW: Draw the ocean current indicator in the bottom right corner
            if isempty(obj.currentArrow_h) || ~ishandle(obj.currentArrow_h)
                % Get the current limits of the axes to place the arrow dynamically
                xlims = get(axes_h, 'XLim');
                ylims = get(axes_h, 'YLim');
                
                % Position at 85% of X width, and 10% of Y height (Bottom Right)
                x_pos = xlims(1) + 0.85 * (xlims(2) - xlims(1));
                y_pos = ylims(1) + 0.10 * (ylims(2) - ylims(1));
                
                % Query the environment force (at a dummy position like [0,0,0])
                envForce = obj.getEnvironmentForce([0, 0, 0]);
                
                % Scale the arrow purely for visual rendering
                visualScale = 0.5; % Adjust this if the arrow is too big/small!
                u = envForce(1) * visualScale;
                v = envForce(2) * visualScale;
                
                % Use quiver to draw a directional arrow without wiping the canvas
                hold(axes_h, 'on'); 
                obj.currentArrow_h = quiver(axes_h, x_pos, y_pos, u, v, 0, ...
                    'Color', '#0072BD', 'LineWidth', 2, 'MaxHeadSize', 2);
                
                % Add a label nearby
                obj.currentText_h = text(axes_h, x_pos, y_pos - (0.05 * (ylims(2) - ylims(1))), 'Current', ...
                    'Color', '#0072BD', 'FontSize', 12, 'HorizontalAlignment', 'center', 'FontWeight', 'bold');
            end
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

        function setAnimate(obj, shouldAnimate)
            obj.animate = shouldAnimate;
        end


        % TODO - talk with @hyatt about the updateFleetPosition method and
        % detection of detonations ...
        function update(obj)
            % Update fleet position

            obj.fleet.update(obj.dt);
            

            ships = obj.fleet.getActiveShipPositions();

            % Update minefield
            obj.minefield.update(obj.dt, ships)
            
            % Check for mine detonations
            obj.detectMineDetonations();

            % Group 7 (explosions) addition: Update active particle emitters
            for e = length(obj.activeEmitters):-1:1
                
                if obj.activeEmitters(e).is_active
                    obj.activeEmitters(e).update(obj.dt); % <-- ADDED obj.dt
                else
                    % Clean up finished emitters to free memory
                    delete(obj.activeEmitters(e));
                    obj.activeEmitters(e) = [];
                end
            end

            if obj.animate
                pause(obj.dt);
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

    % Entire function updated by Team 7 (explosions) 

    function detectMineDetonations(obj)
            minesExploded = false(obj.getNumMines,1);
            
            % NEW: Track the velocity of the ship that hit the mine
            hitVelocities = zeros(obj.getNumMines, 3); 

            for shipIdx = 1:obj.getNumShips()
                [ship, isValid] = obj.fleet.getShip(shipIdx);
                if isValid
                    [inMinesDamageRange, ~, ~] = obj.minefield.getMineRanges(ship);

                    if any(inMinesDamageRange)
                        % NEW: Calculate ship's velocity vector to direct the explosion
                        headingRad = ship.heading_deg * pi / 180;
                        % Multiply by a constant to give the explosion velocity scale
                        shipVelX = cos(headingRad);
                        shipVelY = sin(headingRad);

                        % Assign this velocity to the mines that were hit (Now 3D: x, y, z)
                        hitIdx = find(inMinesDamageRange);
                        for k = 1:length(hitIdx)
                            hitVelocities(hitIdx(k), :) = [shipVelX, shipVelY, 0];
                        end

                        minesExploded(inMinesDamageRange) = true;
                        ship.sink();
                    end
                end
            end

            if any(minesExploded)
                mineIdx = find(minesExploded);
                for n=1:numel(mineIdx)
                    mIdx = mineIdx(n);
                    mineObj = obj.minefield.mines(mIdx);
                    mineObj.explode();
                    
                    % NEW: Instantiate and trigger a particle emitter at the mine's location
                    if ~isempty(obj.axes_h) && ishandle(obj.axes_h)
                        newEmitter = SEParticleEmitter(obj.axes_h, 40);
                        
                        % <-- NEW: Pass the environment object down!
                        newEmitter.environment = obj.environment; 
                        
                        % Format the mine's location as a 1x3 vector [x, y, z]
                        mineLocation = [mineObj.pos_x, mineObj.pos_y, 0];
                        newEmitter.trigger(mineLocation, hitVelocities(mIdx, :));
                        
                        % Add to our tracking array
                        obj.activeEmitters = [obj.activeEmitters, newEmitter];
                    end
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

        function setDebugMode(obj, setOn)
            if nargin <1 || isempty(setOn)
                setOn = false;
            end
            obj.debugMode = logical(setOn);
        end
		
		function forceAtPos = getEnvironmentForce(obj, position)
            if ~isempty(obj.environment)
                forceAtPos = obj.environment.getForceAtPosition(position);
            else
                forceAtPos = [1, 1, 0];
            end
        end
        
    end
end