classdef SEMine < handle
    properties
        pos_x
        pos_y
        detectRange = 10000 % The radius range around a mine that can detect enemy ships
        damageRange = 250 % The radius range that enemy ships can be engaged by friendly mines
        axes_h;
        graphic_h;
        face_color = [1 0.5 0.5];
    end

    properties (SetAccess = protected)
        armed = false % (T/F)
        alive = true % (T/F)
    end

    events
        Explosion
    end
    
    methods
        function obj = SEMine(position_x, position_y, axisHandle)
            if nargin > 0
                obj.setPosition(position_x, position_y); % setPosition does not exist in the code anywhere but here
                if nargin > 2
                    obj.initDisplay(axisHandle);
                end
            end
        end


        % Can  be used to assign an axes handle for the mine to be renderd
        % on.  If the mine handle does not exist, it will be created.
        function initDisplay(obj, axes_handle_in)
            if isempty(obj.graphic_h) || ~ishandle(obj.graphic_h)
                obj.graphic_h = line('parent',[], 'xdata', obj.pos_x, 'ydata', ...
                        obj.pos_y,'marker','*','markerfacecolor',obj.face_color,...
                        'markeredgecolor','k',...
                        'markersize',2);
                % You can do something like this too
                % this.item_handle = rectangle('Position',[obj.position_x obj.position_y  1 1],'Curvature',[1 1])
            end

            if nargin > 1
                obj.setAxesHandle(axes_handle_in);
            end
        end

        function setAxesHandle(obj, axes_handle_in)
            if nargin>1 && ishandle(axes_handle_in)
                obj.axes_h = axes_handle_in;
            end
            if ishandle(obj.graphic_h) && ishandle(obj.axes_h)
                set(obj.graphic_h,'parent',obj.axes_h);
            end
            obj.updateDisplay();
        end


        % TODO - create the marker handle and hide it somehow if it is not
        % alive
        %        - ask @hyatt if you don't understand how this can be done -
        %        there are a few ways that are all valid
        function updateDisplay(obj)
            if ishandle(obj.graphic_h)
                if obj.isAlive
                    visibility = 'on';
                else
                    visibility = 'off';
                end

                set(obj.graphic_h, 'xdata', obj.pos_x, 'ydata', ...
                    obj.pos_y,'marker','hexagram','markerfacecolor',obj.face_color, ...
                    'markersize',10, 'visible',visibility);
            end
        end

        % TODO - talk with @hyatt about possible misconception with setting
        % dx, dy and updating the position.
        function update(obj)
            % Update the mine's state, possibly checking for detection, etc.
            % obj.updateArmament();
            % obj.updatePosition(); --> see also setDxDy
            obj.updateDisplay();
        end 
        
        % TODO - talk with @hyatt about what is going on here
        function setDxDy(obj, dx, dy)
            % Passthrough from SEMinefield to set the mine's position change
            obj.pos_x = obj.pos_x + dx;
            obj.pos_y = obj.pos_y + dy;
        end
        
        function didSet = setPosition(obj, x, y)
            % Set the mine's position
            obj.pos_x = x;
            obj.pos_y = y;
            didSet = true;
        end

        
        function detected = hasDetected(obj, ship_x, ship_y)
            % Determine if a ship is within detection range
            distance = sqrt((obj.pos_x - ship_x)^2 + (obj.pos_y - ship_y)^2);
            detected = (distance <= obj.detectRange);
        end
        
        function detonation(obj)
            % Broadcast explosion event and kills mine
            obj.alive = false;
            % Add code to broadcast explosion event
        end
        
        function [inRange, distance] = isInDetectionRange(obj, xyPosToCheck)
            [inRange, distance] = obj.isInRange(xyPosToCheck, 'detectRange');
        end

        function [inRange, distance] = isInDamageRange(obj, xyPosToCheck)
            [inRange, distance] = obj.isInRange(xyPosToCheck, 'damageRange');
        end

        function [inRange, distance] = isInRange(obj, xyPosToCheck, rangeParameter)
            ship_x = xyPosToCheck(1);
            ship_y = xyPosToCheck(2);

            % Check if any of the ships are in range of the mine
            distance = sqrt((obj.pos_x - ship_x)^2 + (obj.pos_y - ship_y)^2);
            inRange = distance <= obj.(rangeParameter);
        end

        
        function aliveStatus = isAlive(obj)
            % Determine status of alive
            aliveStatus = obj.alive;
        end
        
        function armedStatus = isArmed(obj)
            % Determine status of armed
            armedStatus = obj.armed;
        end
        

        % TODO - discuss with @hyatt - this likely should not be a method or if it is, it should be three methods.        
        function armDisarm(obj, ship_x, ship_y)
            % Change status of armed to disarmed if friendly ship is within damage range
            if obj.isInRange(ship_x, ship_y)
                obj.armed = false;
            end
        end
    end
end




