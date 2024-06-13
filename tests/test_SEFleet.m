close all;
num_ships = 5;

% fleetObj = SEFleet(gca);
% fleetObj.setNumShips(num_ships);

fleetObj = SEFleet(gca, num_ships);

% TODO - kill one of your ships and make sure it disappears

shipID = 1;
fleetObj.sinkShip(shipID);
