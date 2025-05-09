close all
clear all;
y = (rand(1,4)-0.5)*10;

x = (rand(1,4)-0.5)*10;

dir_x = sign(x);
dir_y = sign(y);
speed = 0.1;

markerType = 'o';
markerColor = [0.8, 0.5, 0.5];
markerEdgeColor = 'black';

l = plot(x,y);    % line handle
a = get(l,'parent');    % axes handle
f = a.Parent;   % figure handle

% configure figure, axis, line
f.NumberTitle = 'off';
f.Name = 'Demo';
f.ToolBar = 'none';
f.MenuBar = 'none';


% Create a boundary to fix things to do
limits = [-10, 10];
a.XLim = limits;
a.YLim = limits;
a.Box = "on";
a.XGrid = "on";
a.YGrid = "on";
a.XTickLabel = '';
a.YTickLabel = [];  % this works too

l.LineStyle = 'none';       % no lines
l.Marker = markerType;
l.MarkerEdgeColor = markerEdgeColor;
l.MarkerFaceColor = markerColor;
l.MarkerSize = 15;


update_position = @(x,y)(x.XData + x.XData + 1);

fps = 20;       % frame rate
dur_sec = 10;
num_frames = fps*dur_sec;
for frame = 1:num_frames

    % boundary checks - this uses vectorization as a shortcut to if/else
    % statements, but the logic is the same.
    tooFarRight = l.XData > limits(end);
    tooFarLeft = l.XData < limits(1);
    tooLow = l.YData < limits(1);
    tooHigh = l.YData > limits(end);

    title_str = sprintf('Demo (% 3d)', frame);
    f.Name = title_str;
    dir_x(tooFarLeft) = 1;
    dir_x(tooFarRight) = -1;
    dir_y(tooLow) = 1;
    dir_y(tooHigh) = -1;

    % update position
    l.XData = l.XData + dir_x*speed;
    l.YData = l.YData + dir_y*speed;
    pause(1/fps);
end