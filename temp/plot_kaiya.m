clc, clearvars, close all;



%est vars
l = plot([4,-6,7]); %line
a=l.Parent; %axis
f=a.Parent; %figure


%creating graph
a.XLim=[0,10];
a.YLim=[-10,10];
l.LineWidth=5;
l.Marker='*';
l.MarkerSize=20;
f.Name = 'practice';
f.NumberTitle='off';
f.ToolBar='none';
f.MenuBar='none';
a.XGrid='on';
a.YGrid='on';
a.XTickLabel=[];
a.YTickLabel=[];
l.LineStyle='none';

%animation
dx=0.1; %direction
fps=30;
for k=1:1000
   if l.XData(3) > a.XLim(2)
       dx= -0.1;
   else
       if l.XData(1)<a.XLim(1)
           dx = +0.1;
       end
   end
   l.XData = l.XData + dx*1;
   %fprintf('%d\n':k');
   pause(1/fps);

end