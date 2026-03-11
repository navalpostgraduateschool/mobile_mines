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
            obj.pos_x = obj.pos_x + dt*(force(1)+obj.dx);
            obj.pos_y = obj.pos_y + dt*(force(2)+obj.dy);
            obj.pos_z = min(0,obj.pos_z + dt*(force(3)+obj.dz));

            update@SEMine(obj, dt, force, ships);
        end
    end
end
