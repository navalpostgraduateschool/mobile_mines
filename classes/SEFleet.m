classdef SEFleet < handle
    properties (Constant)
        %Possible fleet pathing behaviors
        BEHAVIORS={'Will Kamikaze','Kamikaze','Random_Start_Point','Random_End_Point','Rand_Start_Rand_End'}; 
    end

    properties
        ships;     % Vector of SEShip objects (numShips x 1)
        behavior = 'Will Kamikaze'; % Current behavior of the fleet
        numShips = 0; % Number of ships in the fleet - default to 0 to help with initialization
        axesHandle % Handle for graphical representation        
        operatingBoundary = [0 0 6 9];  % lower left point (x,y) and size (width, height)
        startPos;
        endPos;
        activeShipIndex; % keeps track of which speed
    end    
    
    methods
        % Constructor to initialize the fleet
        function obj = SEFleet(boundaryBox, numShips, fleetBehavior, axesHandle)
            narginchk(0,4);
            if nargin>0
                obj.setBoundaryBox(boundaryBox);
                if nargin>1
                    obj.setNumShips(numShips);
                    if nargin>2
                        obj.setBehavior(fleetBehavior);
                        if nargin>3
                            obj.setAxesHandle(axesHandle);
                        end
                    end
                end
            end
        end

        % Reset the fleet for the current configuration
        function reset(obj)
            obj.setNumShips(obj.numShips); %  this invokes obj.resetBehavior()
            % obj.activeShipIndex = 1;
            % if obj.numShips==0
            %     obj.activeShipIndex = [];
            % end
        end

        

        %axes sync
        function didSet = setAxesHandle(obj, axesHandle)
            didSet = false;
            if nargin>1 && ~isempty(axesHandle) && ishandle(axesHandle)
                obj.axesHandle = axesHandle;
                for n=1:obj.numShips
                    obj.ships(n).setAxesHandle(axesHandle);
                end
            end
        end
        
        %refreshes the display
        function refreshDisplay(obj)
            for shipIdx = 1:obj.numShips
                obj.ships(shipIdx).updateDisplay();
            end
        end
        
        %sets bounds
        function didSet = setBoundaryBox(obj, bounds)
            didSet = false;
            if numel(bounds) == 4
                obj.operatingBoundary = bounds;
                obj.resetBehavior();
            end
        end

        function resetBehavior(obj)
            obj.setBehavior(obj.behavior);
        end

        % Method to change the behavior of the fleet
        function didSet=setBehavior(obj, newBehavior)
            didSet=false;
            if any(strcmp(newBehavior,obj.BEHAVIORS))

                obj.behavior = newBehavior;

                [start_positions, end_positions] = obj.getStartEndPositions();
                %start_positions = rand(obj.numShips, 2)*10;

                for k=1:obj.numShips
                    % start_x = start_positions(k,1);
                    % start_y = start_positions(k,2);
                    obj.ships(k).setStartEndPositions(start_positions(k,:), ...
                        end_positions(k,:));
                end
                didSet=true;  
                obj.refreshDisplay();
            end
        end

        function didSink = sinkShip(obj, shipIndex)
            didSink = false;
            if shipIndex >=1 && shipIndex<=obj.numShips
                obj.ships(shipIndex).sink();
                didSink = true;  % may have a semantic error - if the ship was already sunk, did you really sink it here?
            end
        end

        function updateActiveShip(obj)
            % obj.activeShipIndex;
        end

        function update(obj)
            % do we have any active ships
            obj.updateActiveShip();
            for n = 1:obj.numShips
                obj.ships(n).update();
            end
        end

        function didSet = setNumShips(obj, numShips)
            didSet = false;
            if numShips>= 0
                obj.numShips = floor(numShips);
                tmpShip = SEShip();
                obj.ships = repmat(tmpShip, obj.numShips, 1);

                for k=1:obj.numShips
                    obj.ships(k) = SEShip(0, 0, obj.axesHandle);
                end

                % This causes a refresh for the ships initial and end
                % points
                obj.resetBehavior();
                didSet = true;
            end
        end

        % TODO - Update with logic and boundary property
        function [startPos, endPos]=getStartEndPositions(obj)
            startPos = nan(obj.numShips, 2);
            endPos = nan(obj.numShips, 2);

            opX = obj.operatingBoundary(1);
            opY = obj.operatingBoundary(2);
            opWidth = obj.operatingBoundary(3);
            opHeight = obj.operatingBoundary(4);
            
            xCenters = repmat(opX+opWidth/2, obj.numShips, 1);

            yStarts = repmat(opY, obj.numShips,1);
            yEnds = obj.operatingBoundary(4)+ yStarts;
            xRandStarts = opX+rand(obj.numShips,1)*opWidth;
            xRandEnds = opX+rand(obj.numShips,1)*opWidth;
            
            if obj.numShips>0
                switch lower(obj.behavior)
                    case 'kamikaze'
                        startPos = [xCenters, yStarts];
                        endPos = [xCenters, yEnds];
                    case 'random_start_point'
                        startPos = [xRandStarts, yStarts];
                        endPos = [xCenters, yEnds];
                    case 'random_end_point'
                        startPos = [xCenters, yStarts];
                        endPos =   [xRandEnds, yEnds];
                    case 'rand_start_rand_end'
                        startPos = [xRandStarts, yStarts];
                        endPos =   [xRandEnds, yEnds];                        
                    case 'will kamikaze'
                        xStarts = linspace(opX, opX+opWidth, obj.numShips);
                        xEnds = xStarts;
                        startPos = [xStarts(:), yStarts];
                        endPos = [xEnds(:), yEnds];                    
                end

            end
        end

        % TODO - talk with @hyatt about this method and where to utilize it
        % in the class
        % Method to update the position of the fleet
        function updatePositions(obj)
            % Assuming each ship has a method to update its position
            for i = 1:obj.numShips
                % TODO - discuss misconception here
                obj.ships(i).updatePosition();
                obj.axesHandle.Ships(i).updatePosition(newPosition);
            end

            % TODO - are these below comments a todo for yourself?  Let's discuss if it is a
            % remaining todo or just left over and can be removed
            % pull heading and speed from ship info, use that to update
            % position every xx frames
        end

        % Method to update the priority of the fleet
        %function updatePriority(obj, newPriority)
            % Assuming each ship has a priority attribute
            %for i = 1:obj.numShips
                %obj.graphicsHandle.Ships(i).Priority = newPriority;
            %end
            %if ship dies, update
        %end

        function status = getStatus(obj)
            status = struct('numAlive',0,...
                'numSuccess', 0, ...
                'numSunk', 0,...
                'numRemaining', 0, ...
                'numTransiting', 0);
            for n = 1:obj.numShips
                stillAlive = obj.ships(n).isAlive();
                inBounds = obj.ships(n).pos_y <= (obj.operatingBoundary(2)+obj.operatingBoundary(4));
                status.numRemaining = status.numRemaining+ (stillAlive && inBounds);
                status.numAlive = status.numAlive + stillAlive;
                status.numSunk = status.numAlive + ~obj.ships(n).isAlive();
            end
            status.numSunk = obj.numShips - status.numAlive;
        end

        % num is the number of ships that have not been sunk
        % and have not yet transited out of the minefield
        function num = getNumShipsRemaining(obj)
            status = obj.getStatus();
            num = status.numRemaining;
        end

        function num = getNumUnsunkShips(obj)
            num = obj.getNumAlive();
        end

        % Method to get the number of ships that are still operational
        function numAlive = getNumAlive(obj)
            numAlive = 0;
            for n = 1:obj.numShips                
                numAlive = numAlive + obj.ships(n).isAlive();                
            end
        end        

        function num = getNumShipsLeftToTransit(obj)
            status = obj.getStatus();
            num = status.numRemaining;            
        end

    end
end
