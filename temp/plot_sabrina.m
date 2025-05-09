close all
clear all

l = plot([3,-15,9,20]);
l.Marker = 'pentagram';
l.MarkerSize=20;
l.MarkerFaceColor = 'magenta';
l.MarkerEdgeColor = 'cyan'; 
l.LineStyle = "none";
a = l.Parent;
f = a.Parent;
f.Name = 'Sabrina';
a.Box = 'on';
a.XTickLabel = '';
a.YTickLabel = '';
a.XLim = [0 20];
a.YLim = [-15 20];
l.XData = l.XData - .01;
fps=60;
dx = 1;
for k=  1:1000
    if l.XData(1) > a.XLim(2)
        dx = -1;
    else
        if l.XData(2) < a.XLim(1)
            dx = +1;
        end
    end
    l.XData = l.XData + dx;
    pause(1/fps);
end
