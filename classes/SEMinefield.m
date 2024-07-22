classdef SEMinefield < handle
    properties(Constant)
        LAYOUTS = {'uniform','rand','randn','se4003_delux','derez_distribution'}  % Possible layout
        DEFAULT_BOUNDARY_BOX = [0 0 2 5];
        MINE_TYPES = {'mobile','static'};

    end

    properties
        number_of_mines = 0 % Number of mines
        mines;   % mine or mobile mine objects (number_of_mines x 1)
        axes_h  % Color blob (could be a placeholder for visualization)
        layout = 'uniform' % How the mines are arrayed = only supporting random uniform distrubition right now

        % REMOVE after June 7, 2024
        % Note: these should be placed in the individual mine classes as
        % properties of the entire class or subclasses if we want to make
        % specific types of mines.
        % detect_Range  % The radius range around a mine that can detect enemy ships
        % damage_Range  % The range that enemy ships can be engaged by friendly mines
        % REMOVE END

        boundary_box
        boundary_x = 0 % Boundary x - lower left corner of the mine fields operating area
        boundary_y = 0 % Boundary y - lower left corner (y)
        boundary_width = 2 % Boundary width
        boundary_height = 5 % Boundary height

        

    end

    properties(SetAccess=protected)
        mineType = 'mobile';
    end
    
    methods
        function didSet = setMineType(obj, mineType)
            didSet = false;
            if any(strcmpi(mineType,obj.MINE_TYPES))
                obj.mineType = lower(mineType);
                obj.reset();
            end
        end

        function obj = SEMinefield(boundaryBox, numMines, mineLayout, axesHandle)

            narginchk(0,4);

            if nargin>0
                obj.setBoundaryBox(boundaryBox);

                if nargin>1
                    obj.setNumMines(numMines);

                    if nargin>2
                        obj.setLayout(mineLayout);

                        if nargin>3
                            obj.setAxesHandle(axesHandle);
                        end
                    end
                end
            end
        end

        function didSet = setAxesHandle(obj, axesHandle)
            didSet = false;
            if nargin>1 && ~isempty(axesHandle) && ishandle(axesHandle)
                obj.axes_h = axesHandle;
                for n=1:obj.number_of_mines
                    obj.mines(n).setAxesHandle(axesHandle);
                end
                didSet = true;
            end
        end

        function didSet = setBoundaryBox(obj, boundaryBox)
            didSet = false;
            if numel(boundaryBox) == 4
                obj.boundary_box = boundaryBox;
                obj.boundary_x  = boundaryBox(1);
                obj.boundary_y  = boundaryBox(2);
                obj.boundary_width  = boundaryBox(3);
                obj.boundary_height  = boundaryBox(4);
                didSet = true;
            end
        end

        function didSet = setNumMines(obj, num_mines)
            didSet = false;
            if nargin>=1 && ~isempty(num_mines) && num_mines>=0
                obj.number_of_mines = num_mines;
                obj.reset();
                didSet = true;
            end
        end

        function num = getNumUnexplodedMines(obj)
            num = 0;
            for m=1:obj.number_of_mines
                num = num + obj.mines(m).alive;
            end               
        end

        function resetLayout(obj)
            obj.setLayout();
        end

        % Leave blank to refresh the layout
        function didSet = setLayout(obj, minefieldLayout)
            didSet = false;
            if nargin < 2 || isempty(minefieldLayout)
                minefieldLayout = obj.layout;
            end

            if any(strcmpi(minefieldLayout, obj.LAYOUTS))
                obj.layout = minefieldLayout;
                didSet = true;

                switch lower(minefieldLayout)
                    case 'uniform'
                        xyCoords = SEMinefield.getUniformlyDistributedPositions(obj.number_of_mines, obj.boundary_box);
                    case 'rand'
                        % Create the positions for your mines and then set
                        % them
                        warning('Using uniform distribution');
                        xyCoords = SEMinefield.getUniformlyDistributedPositions(obj.number_of_mines, obj.boundary_box);
                        % xyCoords = SEMinefield.getRandomlyUniformDistributedPositions(obj.number_of_mines, obj.boundary_box);
                        
                    % FUTURE - implement other layouts
                    case 'randn'
                        SEMinefield.getRandomlyUniformDistributedPositions(obj.number_of_mines, obj.boundary_box);

                    otherwise
                        warning('%s is not currently implemented - using random uniform distribution', minefieldLayout)
                        xyCoords = SEMinefield.getRandomlyUniformDistributedPositions(obj.number_of_mines, obj.boundary_box);
                end

                for mineIndex=1:obj.number_of_mines
                    minePosition = xyCoords(mineIndex, :);
                    obj.setPosition(mineIndex, minePosition);
                end
                obj.refreshDisplay();
            end
        end
            
        % Reset the simulation for the current configuration
        function reset(obj)            
            switch lower(obj.mineType)
                case 'mobile'
                    mineClass = @SEMobileMine;
                case 'static'
                    mineClass = @SEMine; % CHANGE WHEN SABRINA IS DONE
                otherwise
                    warning('Unrecognized mine type ''%s'', mobile mines will be used', obj.mineType);
                    mineClass = @SEMobileMine;
            end
            obj.mines = repmat(mineClass(),obj.number_of_mines,1);
            
            for n = 1:obj.number_of_mines
               obj.mines(n) = mineClass(nan, nan,obj.axes_h);
            end

            % This will update the location of the mines according to the
            % current layout.
            obj.resetLayout();
        end
        
        function update(obj)
            % Update logic for mines can be added here
            for n=1:obj.number_of_mines
                % Calculate where the ships are perhaps and if something
                % should be exploded?
                obj.mines(n).update();
            end
        end
        
        function didSet = setPosition(obj, mineIndex, mineXY)
            didSet = false;
            % Like this: 
            if obj.isValidIndex(mineIndex)
                x = mineXY(1);
                y = mineXY(2);
                didSet = obj.mines(mineIndex).setPosition(x, y);
            end
        end
        
        function isIt = isValidIndex(obj, mineIndex)
            isIt = nargin>1 && ~isempty(mineIndex) && mineIndex > 0 && mineIndex <= obj.number_of_mines;
        end

        function didSet = setDxDy(obj, mineIndex, dx, dy)
            didSet = false;
            if obj.isValidIndex(mineIndex)
                didSet = obj.mines(mineIndex).setDxDy(dx, dy);
            end
        end
        
        function [detected, distance] = hasDetected(obj, mineIndex, shipPosition)
            detected = false;
            distance = inf;
            if isValidIndex(mineIndex)
                [detected, distance]  = obj.mines(mineIndex).inDetectionRange(shipPosition);
            end
        end
        
        function refreshDisplay(obj)
            for n=1:obj.number_of_mines
                obj.mines(n).updateDisplay();
            end
        end

        function mineExplosion(obj, mineIndex)
            if obj.isValidIndex(mineIndex)
                warning('Not implemented yet');
            end
            % obj.armed(mineIndex) = false;
            % obj.alive(mineIndex) = false;
            % Event broadcast logic can be added here
        end
        
        function [inRange, distance] = isInDamageRange(obj, mineIndex, pos_x, pos_y)
            inRange = false;
            if obj.isValidIndex(mineIndex)
                [inRange, distance] = obj.mines(mineIndex).isInDamageRage(pos_x, pos_y);

                % TODO - push this logic down to your base mine class -
                % create a isInDamageRange method that will return these
                % values for the mine.
                % distance = sqrt((obj.position_x(mineIndex) - pos_x)^2 + (obj.position_y(mineIndex) - pos_y)^2);
                % inRange = distance <= obj.damage_Range(mineIndex);
            end
        end
        
        function inDetectRange = isInDetectRange(obj, mineIndex, ship_x, ship_y)
            inDetectRange = obj.hasDetected(mineIndex, ship_x, ship_y);
        end
        
        function inBoundary = isInBoundary(obj, x, y)
            inBoundary = x >= obj.boundary_x && x <= (obj.boundary_x + obj.boundary_width) && y >= obj.boundary_y && y <= (obj.boundary_y + obj.boundary_height);
        end
        
        % TODO - fix this to use obj.mines(mineIndex) with some checking
        % for mineIndex >= 1 and <= obj.number_of_mines
        function alive = isAlive(obj, mineIndex)
            alive = false;
            if obj.isValidIndex(mineIndex)
                alive = obj.mines(mineIndex).alive;
            end               
        end
        
        function inRange = isInRange(obj, ship_x, ship_y)
            inRange = false;
            for i = 1:obj.number_of_mines
                if obj.isInDetectRange(i, ship_x, ship_y)
                    inRange = true;
                    break;
                end
            end
        end
    end

    methods(Static)
        function getDistributedPostions(numItems, boundarBox, distributionTag)
            switch lower(distributionTag)


            end
        end

        % QUERY - there may be a logic error or corner case where not every item
        % is guaranteed to be assigned a position. 
        % TODO - submit a ticket and place on the backlog to investigate
        % later.
        function xyCoords = getUniformlyDistributedPositions(numItems, boundaryBox)
            boundary_x = boundaryBox(1);
            boundary_y = boundaryBox(2);
            width = boundaryBox(3);
            height = boundaryBox(4);
            % distributeObjectsUniformly distributes objects uniformly within a specified boundary
            %
            % Inputs:
            %   numItems - Number of objects to distribute
            %   boundary_x - X-coordinate of the boundary's top-left corner
            %   boundary_y - Y-coordinate of the boundary's top-left corner
            %   width - Width of the boundary
            %   height - Height of the boundary
            %
            % Outputs:
            %   xyCoords - numItems x 2 matrix of x, y coordinates for each
            %   item randomly distributed across the boundary box
            
            
            % Calculate the number of rows and columns for a roughly square grid
            numRows = ceil(sqrt(numItems));
            numCols = ceil(numItems / numRows);

            % Calculate the spacing between objects
            if numRows > 1
                rowSpacing = height / (numRows - 1);
            else
                rowSpacing = height;
            end
            
            if numCols > 1
                colSpacing = width / (numCols - 1);
            else
                colSpacing = width;
            end

            % Initialize coordinates vectors
            xyCoords = nan(numItems, 2);
            
            % Generate the coordinates
            index = 1;
            for row = 0:numRows-1
                for col = 0:numCols-1
                    if index > numItems
                        break;
                    end
                    x = boundary_x + col * colSpacing;
                    y = boundary_y + row * rowSpacing;
                    xyCoords(index,:) = [x, y];
                    index = index + 1;
                end
            end
        end

        function xyCoords = getRandomlyGaussianDistributedPositions(numItems, boundaryBox)
            boundary_x = boundaryBox(1);
            boundary_y = boundaryBox(2);
            width = boundaryBox(3);
            height = boundaryBox(4);
            % Distributes objects within a specified boundary according to
            % a gaussian/normal distribution
            %
            % Inputs:
            %   numItems - Number of objects to distribute
            %   boundary_x - X-coordinate of the boundary's top-left corner
            %   boundary_y - Y-coordinate of the boundary's top-left corner
            %   width - Width of the boundary
            %   height - Height of the boundary
            %
            % Outputs:
            %   xyCoords - numItems x 2 matrix of x, y coordinates for each
            %   item randomly distributed across the boundary box
            
            
            % Calculate the number of rows and columns for a roughly square grid
            numRows = ceil(sqrt(numItems));
            numCols = ceil(numItems / numRows);

            % Calculate the spacing between objects
            if numRows > 1
                rowSpacing = height / (numRows - 1);
            else
                rowSpacing = height;
            end
            
            if numCols > 1
                colSpacing = width / (numCols - 1);
            else
                colSpacing = width;
            end

            % Initialize coordinates vectors
            xyCoords = nan(numItems, 2);
            
            % Generate the coordinates
            index = 1;
            for row = 0:numRows-1
                for col = 0:numCols-1
                    if index > numItems
                        break;
                    end
                    x = boundary_x + col * colSpacing;
                    y = boundary_y + row * rowSpacing;
                    xyCoords(index,:) = [x, y];
                    index = index + 1;
                end
            end
        end        
    end
end



