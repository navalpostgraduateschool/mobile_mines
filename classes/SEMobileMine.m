classdef SEMobileMine < SEMine
    properties
        dx = 0;
        dy = 0;
    end
    
    methods
        function obj = SEMobileMine(varargin)
            % pass everything to the base class
            obj@SEMine(varargin{:});
            obj.marker = 'pentagram';
        end
        
        function updatePosSmart(obj, ship_x, ship_y)
            % Update the position of the mobile mine based on ship position
            if obj.isAlive() && obj.isArmed() && obj.hasDetected(ship_x, ship_y)
                % Implement your logic to update position here
                % Example: Move towards the ship
                obj.position_x = obj.position_x + obj.dx;
                obj.position_y = obj.position_y + obj.dy;
            end
        end
    end
end
