# Fleet < Handle

## Properties Constant
* possibleBehaviors - list of possible fleet behaviors. kamikaze is where all the ships line up across the field and send it. Straight follow is where a random path is chosen and all ships follow that path. Straight random is where a random path is chosen for every ship.

## Properties
* Graphics Handle - syncs graphics
* fleetBehavior - the method the fleet is using to navigate the minefield 
* numShips - number of ships starting in the fleet
* fieldSize - a value of the minefield dimensions


## Methods
* changeBehavior - change fleet behavior from initialized type
* updateGroupPosition - account for sunk ships
* updatePriority - updates priority of ships that are still alive
* getNumAlive - checks the numAlive to reflect how many ships are still alive
* validBehavior - checks if the chosen behavior is possible given number of ships and such



