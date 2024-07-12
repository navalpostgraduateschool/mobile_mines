classdef SEShip<handle
 
    properties
        pos_x;
        pos_y;
        ship_type = 'General'; % Placeholder for now
        speed = 0; % speed in knots (0-30) (nm/hour)
        %shipPriority = 1; % scales based off total number of ships
        heading = 0; % 0-359 degrees
        start_x; % set start x position on 2D Grid
        start_y; % set start y position on 2D Grid
        end_x; % set end x position on 2D Grid
        end_y; % set end y position on 2D Grid
        time_step; % arbitrary time unit; dt
        face_color = [0.5, 0.5, 0.5];
    end

    properties(SetAccess=protected)
        showHeading = true;
        alive = true;
        health = 4;
        armor = 4;
        axes_h;
        graphic_h; % ship graphic handle       
        heading_h;  % holds a line showing where the ship is going to go
    end

    methods
        function obj = SEShip(pos_x,pos_y, axes_handle)
            if nargin>=2
                obj.setStartEndPositions([pos_x, pos_y], [pos_x, pos_y]);
                if nargin>2
                    obj.initDisplay(axes_handle);
                end
            end
        end

        function delete(obj)
            if ~isempty(obj.graphic_h) && isvalid(obj.graphic_h)
                delete(obj.graphic_h);
            end
            delete@handle(obj);
        end

        function setStartEndPositions(obj, startPos, endPos)
            obj.setStartPosition(startPos);
            obj.setEndPosition(endPos);
            obj.setPosition(startPos);
        end

        function setPosition(obj, pos_x,pos_y)
            narginchk(2,3);  % if just 2 arguments, then the second is a two element vector with x, y
            if nargin==2
                pos_y = pos_x(2);
                pos_x = pos_x(1);
            end                
            obj.pos_x = pos_x;
            obj.pos_y = pos_y;
        end

        function setStartPosition(obj, pos_x,pos_y)
            narginchk(2,3);  % if just 2 arguments, then the second is a two element vector with x, y
            if nargin==2
                pos_y = pos_x(2);
                pos_x = pos_x(1);
            end                
            obj.start_x = pos_x;
            obj.start_y = pos_y;
        end

        function setEndPosition(obj, pos_x,pos_y)
            narginchk(2,3);  % if just 2 arguments, then the second is a two element vector with x, y
            if nargin==2
                pos_y = pos_x(2);
                pos_x = pos_x(1);
            end            
            obj.end_x = pos_x;
            obj.end_y = pos_y;
        end

        function cur_heading = updateHeading(obj)
            cur_heading = atand((obj.end_x-obj.pos_x)/(obj.end_y-obj.pos_y));
            obj.heading = cur_heading;
        end

        function isIt = isAlive(obj)
            isIt = obj.alive;
        end

        function makeAlive(obj)
            obj.alive = true;
        end

        % QUERY - Should we call update display after sinking a ship?
        function sink(obj)
            obj.alive = false;
        end

        function update(obj)
            obj.updateHeading();
            obj.updatePosition();
            obj.updateDisplay();
        end

        function updatePosition(obj)
            updateHeading(obj);
            obj.pos_x = obj.pos_x + obj.time_step*obj.speed*sind(obj.heading);
            obj.pos_y = obj.pos_y + obj.time_step*obj.speed*cosd(obj.heading);      
        end

        function showPath(obj, shouldShow)
            obj.showHeading = shouldShow;
            obj.updateDisplay;
        end

        function initDisplay(obj, axes_handle_in)
            if isempty(obj.heading_h) || ~ishandle(obj.heading_h)
                obj.heading_h = line('parent',[],'linestyle','-.','color','w');
            end
            if isempty(obj.graphic_h) || ~ishandle(obj.graphic_h)
                obj.graphic_h = line('parent',[],'xdata',nan,'ydata',nan,'marker','d','markersize',16,...
                    'markerfacecolor',obj.face_color,'markeredgecolor','k');
            end
            if nargin > 1
                obj.setAxesHandle(axes_handle_in);
            end
        end

        function setAxesHandle(obj, axes_handle_in)
            if ishandle(axes_handle_in)
                obj.axes_h = axes_handle_in;
                obj.graphic_h.Parent = axes_handle_in;
                obj.heading_h.Parent = axes_handle_in;
                obj.updateDisplay();
            else
                disp('Something is wrong in the setAxesHandle function')
            end
        end

        function updateDisplay(obj)
            if obj.alive
                visibility = 'on';
            else
                visibility = 'off';
            end

            if ishandle(obj.graphic_h)
                set(obj.graphic_h,'markerfacecolor',obj.face_color,'xdata',obj.pos_x,'ydata',obj.pos_y, ...
                    'visible',visibility);
            end
            if ishandle(obj.heading_h)
                xVec = [obj.pos_x, obj.end_x];
                yVec = [obj.pos_y, obj.end_y];

                if ~obj.showHeading
                    visibility = 'off';
                end
                set(obj.heading_h,'XData',xVec,'YData',yVec, 'visible',visibility, ...
                    'linestyle','-.','color','k');
            end
        end
    end
end
