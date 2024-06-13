classdef SEFleet < handle
    properties (Constant)
        %Possible fleet pathing behaviors
        BEHAVIORS={'Will Kamikaze','Kamikaze','Random_Start_Point','Random_End_Point','Rand_Start_Rand_End'}; 
    end

    properties
        ships;     % Vector of SEShip objects (numShips x 1)
        behavior = 'Kamikaze'; % Current behavior of the fleet
        numShips = 0; % Number of ships in the fleet - default to 0 to help with initialization
        axesHandle % Handle for graphical representation        
        operatingBoundary = [0 0 6 9];  % lower left point (x,y) and size (width, height)
        startPos;
        endPos;
       
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

        function num = getNumUnsunkShips(obj)


        end
        
        %sets bounds
        function didSet = setBoundaryBox(obj, bounds)
            didSet = false;
            if numel(bounds) == 4
                obj.operatingBoundary = bounds;
                obj.refreshBehavior();
            end
        end

        function refreshBehavior(obj)
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
            end
        end

        function didSink = sinkShip(obj, shipIndex)
            didSink = false;
            if shipIndex >=1 && shipIndex<=obj.numShips
                obj.ships(shipIndex).sink();
                didSink = true;  % may have a semantic error - if the ship was already sunk, did you really sink it here?
            end
        end

        function update(obj)
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
                obj.refreshBehavior();
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
        %function updatePosition(obj)
            % Assuming each ship has a method to update its position
         %   for i = 1:obj.numShips
                % TODO - discuss misconception here
          %      obj.ships(i).updatePosition();
                % /obj.axesHandle.Ships(i).updatePosition(newPosition);
           % end
            
            % TODO - are these below comments a todo for yourself?  Let's discuss if it is a
            % remaining todo or just left over and can be removed
            %pull heading and speed from ship info, use that to update
            %position every xx frames
        %end

        % Method to update the priority of the fleet
        %function updatePriority(obj, newPriority)
            % Assuming each ship has a priority attribute
            %for i = 1:obj.numShips
                %obj.graphicsHandle.Ships(i).Priority = newPriority;
            %end
            %if ship dies, update
        %end

        % Method to get the number of ships that are still operational
        function numAlive = getNumAlive(obj)
            numAlive = 0;
            for n = 1:obj.numShips                
                numAlive = numAlive + obj.ships(n).isAlive();                
            end
        end
    end
end
