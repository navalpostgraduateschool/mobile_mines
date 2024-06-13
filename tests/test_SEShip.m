close all;
clear all;
clc;
pos_x = rand*10;
pos_y = rand*10;
axes_h = gca;

set(axes_h, 'xlim',[0 10], 'ylim', [0 10]);
ship = SEShip(pos_x, pos_y, axes_h);

% TODO - update SEShip to not the heading by default
%      - sink your ship and see if it disappears from the display

ship.sink();

