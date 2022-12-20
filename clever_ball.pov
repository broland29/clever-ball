/* "Clever rolling ball"
 *  - to run animation, use clever_roll.ini
 *  - for further thoughts, check the end of the file
 */

#include "colors.inc"       // ex: for White
#include "textures.inc"     // ex: for PinkAlabaster
#include "skies.inc"        // for S_Cloud5        
#include "transforms.inc"   // for vtransform  
#include "math.inc"
        
        
// --- declaration of the ball; for convenience, center in origin --- //        
#declare SPHERE_CENTER = <0,0,0>;            
#declare SPHERE_RADIUS = 1;         
#declare HOLE_CENTER = <-0.5,0.5,-0.5>;      
#declare HOLE_RADIUS = 0.5;
  
#declare MySphere = difference {
    sphere {
        SPHERE_CENTER,
        SPHERE_RADIUS    
    }
    sphere {
        HOLE_CENTER,
        HOLE_RADIUS       
    }
    texture { 
        PinkAlabaster   // moon-like texture
    }
}


// --- declaration of the movement --- //
#declare TOTAL_DISTANCE = 2 * pi * SPHERE_RADIUS;               // recommended, nice value: 2 * pi * SPHERE_RADIUS for whole rotation
#declare CURRENT_DISTANCE = TOTAL_DISTANCE * clock;             // works since clock is a value in interval [0,1]
#declare MOVEMENT_DIRECTION = -z;                               // the direction in which the ball will roll, CONSTRAINED TO x, -x, z, -z by design 
#declare CURRENT_OFFSET = CURRENT_DISTANCE * MOVEMENT_DIRECTION;// movement direction of unit length

/* got total rotation from simple "rule of three"
 *     distance                     rotation
 *     2 * pi * R (circumference)   360 (full rotation)
 *     TOTAL_DISTANCE (given)       TOTAL_ROTATION (unknown) 
 */
#declare TOTAL_ROTATION_AMOUNT = 360 * TOTAL_DISTANCE / (2 * pi * SPHERE_RADIUS);   // from formula above
#declare CURRENT_ROTATION_AMOUNT = TOTAL_ROTATION_AMOUNT * clock;                   // works since clock is a value in interval [0,1]                        
#declare ROTATION_DIRECTION = vcross(y,MOVEMENT_DIRECTION);                         // works since MOVEMENT_DIRECTION is constrained to +-x, +-z; guaranteed unit length
#declare CURRENT_ROTATION = CURRENT_ROTATION_AMOUNT * ROTATION_DIRECTION;           // again, direction of unit length                                                               
                                                                                            
#declare RotateAndTranslate = transform {
    rotate CURRENT_ROTATION    // rotate (initially in origin) 
    translate CURRENT_OFFSET   // translate
}

#declare TranslateOnly = transform {
    translate CURRENT_OFFSET   // translate
}


// --- stopping logic --- //
// gravity vector: from center of sphere towards the ground
#declare gravity1 = SPHERE_CENTER;               
#declare gravity2 = SPHERE_CENTER - <0,2,0>; 
// hole vector: from center of sphere towards center of hole     
#declare hole1 = SPHERE_CENTER;   
#declare hole2 = HOLE_CENTER;  
  
#declare StoppingAngle = 40;    // if angle between gravity and hole vector is less than this, the ball stops rolling
#declare FOUND = false;         // flag to ensure only first time slot of stopping is saved
#declare LAST_CLOCK = 1;        // no guarantee of stopping- start by making the last clock tick the original last clock

#for (Count,0,100)              // with a 0.01 precision, search for stopping tick   
    
    // clock tick associated with current iteration
    #declare SEARCH_CLOCK = Count / 100.0;
    
    // movements based on this clock tick
    #declare SearchRotateAndTranslate = transform {
        rotate TOTAL_ROTATION_AMOUNT * SEARCH_CLOCK * ROTATION_DIRECTION
        translate TOTAL_DISTANCE * SEARCH_CLOCK * MOVEMENT_DIRECTION 
    }
    #declare SearchTranslateOnly = transform {
        translate TOTAL_DISTANCE * SEARCH_CLOCK * MOVEMENT_DIRECTION
    }
    
    // gravity and hole vectors in the given tick  
    #declare sGravity1 = vtransform(gravity1, TranslateOnly);
    #declare sGravity2 = vtransform(gravity2, TranslateOnly);                                       
    #declare sGravityVector = sGravity2 - sGravity1;      
    #declare sHole1 = vtransform(hole1, SearchRotateAndTranslate);
    #declare sHole2 = vtransform(hole2, SearchRotateAndTranslate);
    #declare sHoleVector = sHole2 - sHole1;
    
    // check condition
    #if (VAngleD(sHoleVector,sGravityVector) < StoppingAngle)
        #if (!FOUND)
            #declare LAST_CLOCK = SEARCH_CLOCK;
            #declare FOUND = true;
        #end
    #end
#end

// movements based on stopping tick 
#declare LastRotateAndTranslate = transform {
    rotate TOTAL_ROTATION_AMOUNT * LAST_CLOCK * ROTATION_DIRECTION
    translate TOTAL_DISTANCE * LAST_CLOCK * MOVEMENT_DIRECTION 
}
#declare LastTranslateOnly = transform {
    translate TOTAL_DISTANCE * LAST_CLOCK * MOVEMENT_DIRECTION
}
  
                                                     
// --- basic elements --- //                                                                                            
camera {
    location <0, 2, -15>
    look_at 0
    angle 0
}

light_source {
    <500, 500, -1000>
    White
}

plane {
    y,
    -SPHERE_RADIUS  // for convenience, so we do not need to offset the ball
    pigment {
        checker
        color rgb<0.2, 0.4, 0.8>
        White 
    }
}

sky_sphere {
    S_Cloud5    // nice, cloudy background 
}  



// --- movement selection --- //
#if (clock < LAST_CLOCK)
    #declare RT = RotateAndTranslate  
    #declare TO = TranslateOnly
#else
    #declare RT = LastRotateAndTranslate   
    #declare TO = LastTranslateOnly
#end



// --- object instantiation --- //
object {
    MySphere
    transform RT     
}


// --- tought process --- //
/*
    My initial approach was having the hole and gravity vectors move with the ball. This worked fine: i could
    detect when the stopping condition was fulfilled or when it wasn't. However, it was impossible to stop the
    ball. The only way I could stop the animation was by making an error by purpose- not elegant at all. Since
    POV-Ray has no idea of storing a variable from iterations, i had to abandon this idea.
    
    A perfectly fine solution would be to use an additional text file, so that we could signal finding the first
    stopping tick. The file would serve as a "memory". Unfortunately, we were not allowed to do this.
    
    So, after some thinking i came up with a very ugly idea: at each iteration, we re-calculate the stopping tick
    by iterating through all the clock ticks (with a given precision), and acting accordingly. It seems like the
    only way of stopping the ball without the notion of a real constant or variable is to know the stopping clock
    beforehand. There may be a nice mathematical solution for this problem, but i could not think of it. So, the
    lumberjack-method will do it this time.
*/
