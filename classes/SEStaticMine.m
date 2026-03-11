classdef SEStaticMine < SEMine
    properties
        dx = 0;
        dy = 0;
        dz = 0;
    end
    
    methods
        function obj = SEStaticMine(varargin)
            % pass everything to the base class
            obj@SEMine(varargin{:});
            obj.marker = 'o';
        end

        function update(obj, dt, force, ships)

            % SMCC TODO: update position based on force and time step.            
            update@SEMine(obj, dt, force, ships);
        end
    end
end
