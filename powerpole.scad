/*
 Space for an Anderson Power Pole(tm) electrical connector,
 an awesome ambidexterous DC connector widely used in robotics and remote control. 

 Origin is at the base of the connector, with the connector
 standing up along +Z (like a cylinder).

 Dr. Orion Lawlor, lawlor@alaska.edu, 2022-08 (Public Domain)
*/

/*
 powerpole (pp) structure order:
    OD of box, length of box overall, mate depth, keydepth, keywidth, keylength, pinOD, pinheight, wireOD
*/
powerpole_45A=[7.9,24.9, 8.3, 0.5,3.5,12.3, 2.25,14.6, 5.1 ];
powerpole_75A=[16.1,48, 14.7, 1.0,6.0,26.0, 5.0,29.4, 11.6 ];

/* Return the box outside dimension / pitch of coupler stack (less keying) */
function powerpole_OD(pp)=pp[0];

/* Return the box overall length (including coupler, less wire) */
function powerpole_length(pp)=pp[1];

/* Return the mating depth (overlap with mating connector) */
function powerpole_mate(pp)=pp[2];

/* Return the key depth (distance key sticks above box) */
function powerpole_keydepth(pp)=pp[3];
/* Return the key width (length of key the short way on box) */
function powerpole_keywidth(pp)=pp[4];
/* Return the key length (length of key the long way on box) */
function powerpole_keylength(pp)=pp[5];

/* Return the retaining pin OD */
function powerpole_pinOD(pp)=pp[6];
/* Return the pin height (up from base of box) */
function powerpole_pinheight(pp)=pp[7];

/* Return the wire space OD */
function powerpole_wireOD(pp)=pp[8];


/* Basic 2D XY section of box, less keying */
module powerpole_box2D(pp) {
    OD=powerpole_OD(pp);
    square([OD,OD],center=true);
}

/* Keying on back side of box */
module powerpole_key2D(pp) {
    OR=powerpole_OD(pp)/2;
    keydepth=powerpole_keydepth(pp);
    keywidth=powerpole_keywidth(pp);
    
    for (angle=[0,90]) rotate([0,0,angle]) //< keying on two sides
        translate([OR-keydepth,-keywidth/2,0]) 
            square([2*keydepth,keywidth]);
}

/* Basic 2D space for wiring pins */
module powerpole_wire2D(pp) {
    OD=powerpole_wireOD(pp);
    square([OD,OD],center=true);
}

/* 2D cross section through powerpole retention pin holes.
    Needs to be extruded and rotated up 90 degrees along X axis. 
*/
module powerpole_pin2D(pp,nhole=2) {
    OD=powerpole_OD(pp);
    pinOD=powerpole_pinOD(pp);
    for (hole=[0:nhole-1])
        translate([(hole-0.5)*OD,powerpole_pinheight(pp),0])
            circle(d=pinOD);
}

// 3D grid of holes for retaining pins
module powerpole_pins3D(pp,pins,height)
{
    rotate([90,0,0])
    linear_extrude(height=height,center=true,convexity=2*pins)
        powerpole_pin2D(pp,pins);
}

/* 2D front section of insets for electrical mating plug */
module powerpole_mate2D(pp) {
    OD=powerpole_OD(pp);
    wall=0.8;
    
    box=[OD+0.3,OD+0.3];
    hole=[OD-2*wall,OD-2*wall];
    
    // Large center gap
    intersection() {
        square(box,center=true);
        square(hole,center=true);
        translate([0,100,0]) square([200,200],center=true);
    }
    
    // Inset area for other side's wall
    difference() {
        square(box,center=true);
        square(hole,center=true);
        translate([0,100,0]) square([200,200],center=true);
    }    
}

/* 3D model of basic connector, without pins or electrical mating surfaces */
module powerpole_base3D(pp,wiggle=0.1,extrakey=0)
{
    linear_extrude(height=powerpole_length(pp)+wiggle) 
        offset(r=wiggle) powerpole_box2D(pp);
    linear_extrude(height=powerpole_keylength(pp)+wiggle+extrakey) 
        offset(r=wiggle) powerpole_key2D(pp);
}


/* 3D model of a powerpole connector. */
module powerpole_3D(pp,wiggle=0.1, pins=2, matinghole=1)
{
    OD=powerpole_OD(pp);
    difference() {
        powerpole_base3D(pp,wiggle);
        
        if (pins)
            powerpole_pins3D(pp,pins,OD+2*wiggle+0.1);
        
        if (matinghole)
        translate([0,0,powerpole_length(pp)+wiggle+0.01])
            scale([1,1,-1])
                linear_extrude(height=powerpole_mate(pp)+wiggle,convexity=4)
                    powerpole_mate2D(pp);
    }
}

/* Make an array of children at this powerpole's spacing.
   Element [0][0] is at the origin.
*/
module powerpole_array(pp,nx,ny) {
    OD=powerpole_OD(pp);
    for (dx=[0:nx-1]) for (dy=[0:ny-1])
        translate([OD*dx,OD*dy,0])
            children();
}


// Demo parts
module powerpole_demo()
{
    $fs=0.1;
    
    pp=powerpole_45A;
    powerpole_array(pp,2,1) 
        powerpole_3D(pp,matinghole=1);
    
    translate([0,15,0])
    {
        pp=powerpole_75A;
        powerpole_array(pp,3,2) 
            powerpole_3D(pp,wiggle=0,matinghole=1);
    }
    
}

// powerpole_demo();

