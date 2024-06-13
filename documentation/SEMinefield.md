# SEMinefield < handle

This handles the mines and mobile mines within the playable area of the simulation.

## Events

## Properties

* posistion_x (Random position within boundary between 0-10)
* position_y (Random position within boundary between 0-10)
* detect_Range -(The radius range around a mine that can detect enemy ships; exceeds the damage range) --- when detection is=< the ____ blow up 
* damage_Range -(The range that enemy ships can be engaged by friendly mines. The radius of circle; impact range is less than the detect range)  
* graphic_handle  [color blob]
* Current layout - How the mines are arrayed
* Possible layout
* Number of mines
* boundary_x (10)
* boundary_y (10)
* setMineDxDy(obj, mineIdx, dx,dy)
* obj.mine(mineIdx).setDxDy(dx,dy)
  
*Protected* 
* armed -(T/F) 
* alive -(T/F)   

## Methods
* update()
* setPosition()
* SetDxDy(mineIndex)
* hasDetected 
* mineExplosion - (event_broadcast explosion, kills mine)
* isIndDamageRange(mineIndex, Ship)
* isInDetectRange
* isInBoundary (boundary x,y or h,w)
* isAlive(mineIndex)  
* isInRange - (game controller asks minefield controller if any of the ships
            - are in range of any of the mines) (T/F)  
            - If True: Tell that mine to change status (alive =F) and report to game controller ship 







