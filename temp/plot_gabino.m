close all
clear all

dx = 1

l = plot([10,5,20,30,-5])
l.Color = ['red']
l.LineStyle = 'none';
l.LineWidth = 5;
l.Marker = 'o';

a = l.Parent;
f = a.Parent;

f.Name = 'Gabino'
f.NumberTitle = 'off'

a.XLim = [1 60];
a.YLim = [-10 40];

a.Box = 'on'
l.XData = l.XData + .001
fps = 60
k=0

for k = 1:1000
    if l.XData(1) > a.XLim(2)
        dx = -dx
    else
        if l.XData(5) < a.XLim(1)
            dx = -dx
        end
    end
    l.XData = l.XData + dx;
    pause(1/fps);
end
