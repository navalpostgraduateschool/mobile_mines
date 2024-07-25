classdef SEMobileMine < SEMine
    properties
        dx = 0.5;
        dy = 0.5;
        fps = 10
    end
    
    methods
        function obj = SEMobileMine(varargin)
            % pass everything to the base class
            obj@SEMine(varargin{:});
            obj.marker = 'pentagram';
        end

        function updatePosition(obj)
            % Update the position of the mobile mine based on ship position
            %if true || obj.isAlive() && obj.isArmed() && obj.hasDetected(ship_x, ship_y)
                % Implement your logic to update position here
                % Example: Move towards the ship
                %obj.pos_x = obj.pos_x + obj.dx;
                %obj.pos_y = obj.pos_y + obj.dy;
            if rand(1) <= 0.1
                obj.pos_x = obj.pos_x + (rand(1) - 0.5)*obj.dx;
                obj.pos_y = obj.pos_y + (rand(1) - 0.5)*obj.dy;
            end
            
        end

        function update(obj)
            if obj.isAlive()
                obj.updatePosition();
                obj.updateDisplay();
            end
        end
    end
end

%minePosition = minePosition + (rand(1, 2) - 0.5)