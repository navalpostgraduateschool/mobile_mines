# SEMine < handle

This class handles the basic mine behavior in the 
mobile mine simulator.  It can be used to subclass the SEMobileMine class.

## Events

## Properties
* posistion_x 
* position_y
* detectRange -(The radius range around a mine that can detect enemy ships; exceeds the damage range) --- when detection is=< the ____ blow up 
* damageRange -(The range that enemy ships can be engaged by friendly mines. The radius of circle; impact range is less than the detect range)  
* graphicHandle  

  
*Protected* 
* armed -(T/F) 
* alive -(T/F)  

## Methods
* update()
* setDx,Dy [passthrough from SEMinefield]
* setPosition()
* render() -Updates the mine's graphical representation on the screen, reflecting its current state.
* hasDetected -determines if ships is within detection range (distance between mine to any ship is less than detection range)
* detonation -event_broadcast explosion, kills mine)  
* isInRange -(game controller asks minefield controller if any of the ships
            -are in range of any of the mines) (T/F)  
            -If True: Tell that mine to change status (alive =F) and report to game controller ship 
* isAlive() -determines status of Alive 
* isArmed -Determine status of Armed
* armDisarm -changes status of Armed to disarmed if friendly ship is within Damage range




