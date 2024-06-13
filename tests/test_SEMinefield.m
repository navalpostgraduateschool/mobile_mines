% Clear the workspace and command window
clear;
clc;

% Initialize number of mines
numMines = 5;
boundary_box = [0 0 5 2];
axes_h = gca;
set(axes_h, 'xlim',[0 10],'ylim',[0 10])
% Create an instance of SEMinefield with specified number of mines
minefield = SEMinefield();
fprintf('Test empty constructor - pass\n');
minefield.setBoundaryBox(boundary_box);
fprintf('Test setBoundaryBox - pass\n');
minefield.setAxesHandle(axes_h);
fprintf('Test setAxesHandle - pass\n');
% Fix this so it works
minefield.setNumMines(numMines);

fprintf('Test setNumMines - pass\n');