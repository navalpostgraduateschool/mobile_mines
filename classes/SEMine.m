classdef SEMine < handle
    events
        Armed
        Disarmed
        Exploded
    end

    properties
        pos_x;
        pos_y;
        detectRange = 2 % The radius range around a mine that can detect enemy ships
        damageRange = 0.25 % The radius range that enemy ships can be engaged by friendly mines
        axes_h;
        graphic_h;
        detonation_h;
        face_color = [1 0.5 0.5];
        marker = 'hexagram';
   
        detRangeGraphic;
        explosion = 'o';
        explosionSize = 30;
        explosionColor = 'none';

    end


    properties (SetAccess = protected)
        armed = false % (T/F)
        alive = true % (T/F)
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

        function delete(obj)
            % deleteHandles is a custom function.
            deleteHandles(obj.graphic_h);
            deleteHandles(obj.detonation_h);
            deleteHandles(obj.detRangeGraphic);
            deleteHandles(obj.detRangeGraphic);

            % This is the superclass method for delete the object, which we
            % need to specifiy explicitly since we have overloaded the
            % method.
            delete@handle(obj);
        end

        % Can  be used to assign an axes handle for the mine to be renderd
        % on.  If the mine handle does not exist, it will be created.
        function initDisplay(obj, axes_handle_in)
            if isempty(obj.graphic_h) || ~ishandle(obj.graphic_h)
                obj.graphic_h = line('parent',[], 'xdata', obj.pos_x, 'ydata', ...
                        obj.pos_y,'marker',obj.marker,'markerfacecolor',obj.face_color,...
                        'markeredgecolor','k',...
                        'markersize',2);
                 obj.detonation_h = line('parent',[], 'xdata', obj.pos_x, 'ydata', ...
                        obj.pos_y,'marker','o',...
                        'markeredgecolor','blue',...
                        'markersize',obj.damageRange);
                obj.detRangeGraphic = line('parent',[], 'xdata', obj.pos_x, 'ydata', ...
                        obj.pos_y,'marker',obj.explosion,'markerfacecolor',obj.explosionColor,...
                        'markeredgecolor','k',...
                        'markersize', obj.detectRange);
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
                
                %NEW
                set(obj.detRangeGraphic,'parent',obj.axes_h);                
                set(obj.graphic_h,'parent',obj.axes_h);
                set(obj.detonation_h,'parent',obj.axes_h);
            end
            obj.updateDisplay();
        end


        function updateDisplay(obj)
            if ishandle(obj.graphic_h)
               
                
                if obj.isAlive
                    visibility = 'on';
                else
                    visibility = 'off';
                    obj.marker = 'x';
                    obj.face_color = [1 0 0];
                    %obj.detRangeGraphic.markersize = 0;
                end

                set(obj.graphic_h, 'xdata', obj.pos_x, 'ydata', ...
                    obj.pos_y,'marker',obj.marker,'markerfacecolor',obj.face_color, ...
                    'markersize',10, 'visible','on');

                set(obj.detonation_h, 'xdata', obj.pos_x, 'ydata', ...
                    obj.pos_y,'visible',visibility);
                     
                set(obj.detRangeGraphic, 'xdata', obj.pos_x, 'ydata', ...
                    obj.pos_y,'marker',obj.explosion,'markerfacecolor',obj.explosionColor, ...
                    'markersize',obj.explosionSize, 'visible',visibility);

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
        
        function didSet = setDxDy(obj, dx, dy)
            didSet = false;
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
        
        function explode(obj)
            % Broadcast explosion event and kills mine
            obj.notify('Exploded');
            obj.alive = false;
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

        function [inDamageRange, inDetectionRange, rangeToShip] = getRangesToShip(obj, shipPosition)
            ship_x = shipPosition(1);
            ship_y = shipPosition(2);
            rangeToShip = sqrt((obj.pos_x - ship_x)^2 + (obj.pos_y - ship_y)^2);
            inDamageRange = rangeToShip <= obj.damageRange;
            inDetectionRange = rangeToShip <= obj.detectRange;
        end

        function aliveStatus = isAlive(obj)
            % Determine status of alive
            aliveStatus = obj.alive;
        end
        
        function armedStatus = isArmed(obj)
            armedStatus = obj.armed;
        end

    end
end