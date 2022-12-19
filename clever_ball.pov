//enable to see the "progress" i got trying to get the extra points
#declare DEBUG_MODE = true;



#include "colors.inc"
#include "textures.inc"
#include "skies.inc"       
#include "transforms.inc" //for vtransform  
#include "math.inc"


// ---  properties of objects --- //

//properties of the whole sphere (at "creation")
#declare SPHERE_CENTER_CREATION = <0,0,0>;
#declare SPHERE_RADIUS = 1;

//properties of the hole (at "creation")
#declare HOLE_CENTER_CREATION = <-0.5,0.5,-0.5>;       //todo:verify
#declare HOLE_RADIUS = 0.5;



// --- properties of movement --- //
#declare TOTAL_DISTANCE = 2 * pi * SPHERE_RADIUS;       //recommended, nice value: 2 * pi * SPHERE_RADIUS for whole rotation
#declare CURRENT_DISTANCE = TOTAL_DISTANCE * clock;     //works since clock is a value in interval [0,1]

#declare MOVEMENT_DIRECTION = <0,0,-1>;                         //the direction in which the ball will roll
#declare MOVEMENT_DIRECTION = vnormalize(MOVEMENT_DIRECTION);   //make sure it is normalized

#declare INITIAL_OFFSET = <0,1,0>;                      //calculated from SPHERE_CENTER_CREATION                   
#declare CURRENT_OFFSET = INITIAL_OFFSET + CURRENT_DISTANCE * MOVEMENT_DIRECTION;


//properties of rotation

//ex: y is constant; comes one the z axis -> rotates around x axis
//sign is weird, got by testing, i guess it is because of handedness
//#declare ROTATION_DIRECTION = <MOVEMENT_DIRECTION.z,0,-MOVEMENT_DIRECTION.x>;

#declare ROTATION_DIRECTION = vcross(y,MOVEMENT_DIRECTION);     //only seems to work in x and z direction ??
#declare ROTATION_DIRECTION = vnormalize(ROTATION_DIRECTION);


//got total rotation from simple "rule of three"
//      distance                    rotation
//      2 * pi * R (circumference)  360 (full rotation)
//      TOTAL_DISTANCE (given)      TOTAL_ROTATION (the unknown)
#declare TOTAL_ROTATION = 360 * TOTAL_DISTANCE / (2 * pi * SPHERE_RADIUS);
#declare CURRENT_ROTATION = TOTAL_ROTATION * clock;             //works since clock is a value in interval [0,1]



// --- basic elements --- //

camera{ location <0, 2, -15> look_at 0 angle 0}
light_source { <500, 500, -1000> White }
#if (!DEBUG_MODE)
plane {y, 0 pigment { checker color rgb<0.2, 0.4, 0.8> White } }
#end 
sky_sphere { S_Cloud5 } //for nice background  



// --- components --- //
#declare wholeSphere = sphere {
    SPHERE_CENTER_CREATION, SPHERE_RADIUS    
}

#declare hole = sphere {
    HOLE_CENTER_CREATION, HOLE_RADIUS       
}

#declare mySphere = difference {
    object { wholeSphere }
    object { hole }
    texture { PinkAlabaster }
}



// --- transformations --- //
#declare RotateAndTranslate = transform {
    //translate CURRENT_OFFSET                      //movement - cancels out (v)
    
    //translate -CURRENT_OFFSET                     //translate back to origin - cancels out (^)
    rotate CURRENT_ROTATION * ROTATION_DIRECTION    //rotate 
    translate CURRENT_OFFSET                        //translate back to current position
}

#declare TranslateOnly = transform { 
    translate CURRENT_OFFSET            //used by the gravity vector and cylinder (see later)
}
                    
                    



// --- instantiation of object --- //
object {
    mySphere
    transform RotateAndTranslate      
} 


// --- stopping logic --- //                                                                                                  
#declare gravity1 = SPHERE_CENTER_CREATION;               //from center of sphere
#declare gravity2 = SPHERE_CENTER_CREATION - <0,2,0>;     //towards the ground
#declare hole1 = SPHERE_CENTER_CREATION;   
#declare hole2 = HOLE_CENTER_CREATION;           
                                         

// gravity vector and cylinder - disable plane to see //
#declare gravity1 = vtransform(gravity1, TranslateOnly);
#declare gravity2 = vtransform(gravity2, TranslateOnly);                                       
#declare GravityVector = gravity2 - gravity1; 

#declare GravityDebug = cylinder {  
    gravity1,    
    gravity2,     
    .1
    pigment { color Brown }     
}

#if(DEBUG_MODE)
GravityDebug  
#end
                                                      
                                                                                       
// hole vector and cylinder //
#declare hole1 = vtransform(hole1, RotateAndTranslate);
#declare hole2 = vtransform(hole2, RotateAndTranslate);
#declare HoleVector = hole2 - hole1;

#declare HoleDebug = cylinder {  
    hole1,         
    hole2,         
    .1
    pigment { color Cyan }     
}

#if(DEBUG_MODE) 
HoleDebug
#end 
                                                  
                                                      
// the logic itself // 
#declare StoppingAngle = 60;
#if(DEBUG_MODE) 
    #if (VAngleD(HoleVector,GravityVector) < StoppingAngle)
        sky_sphere { pigment { Red } }
    #else
        sky_sphere { pigment { Green } }
    #end
#end 