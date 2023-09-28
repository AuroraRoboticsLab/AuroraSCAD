/*
 OpenSCAD library of common small DC motors, both brushed and brushless. 
 
 Data structures and accessors directly inspired by nophead's amazing mendel90 scad/vitamins.
 
 Dr. Orion Lawlor, lawlor@alaska.edu, 2022-03-06 (Public Domain)
*/

include <../AuroraSCAD/screw.scad>;

motor_clearance=0.1;

/*
motormotor={ 
    [0] outside diameter of motor face
    [1] front-to-back length of motor (incl minimal space for terminals)
    [2] shaft length above face
    [3] shaft diameter
    [4] shaft flat diameter
    [5] boss height above face
    [6] boss diameter
    [7] bolthole spacing, center-to-center
    [8] bolthole count
    [9] vent radius delta from bolthole radius (0 for no vents)
    [10] bolt type (symbolic from above)
    [11] bolt start angle
    [12] diameter of square box of motor (or 0 for round motor)
};
*/
function motor_diameter(type) = type[0];
function motor_length(type) = type[1];
function motor_shaft_length(type) = type[2];
function motor_shaft_diameter(type) = type[3];
function motor_shaft_flat(type) = type[4];
function motor_boss_length(type) = type[5];
function motor_boss_diameter(type) = type[6];
function motor_bolthole_radius(type) = type[7]/2;
function motor_bolthole_count(type) = type[8];
function motor_vent_delta(type) = type[9];
function motor_screw(type) = type[10];
function motor_bolthole_angle(type) = type[11];
function motor_square(type) = type[12];

// NEMA17 stepper with 5mm shaft
motortype_NEMA17=[56, 40,
    25,5.0,4.5, 
    2.2, 22.3,
    2*21.9, 4, 
    0,
    M3_cap_screw, 45, 42.5];

// 750/775 style heavy brushed with 5mm shaft
motortype_750=[44.4, 77,
    21.1,5.0,5.0, 
    4.61, 17.6,
    29, 2, 
    0.5,
    M4_cap_screw,0,0];

// RS-550 style brushed
motortype_550=[38.2,74,
    21.2, 3.12, 3.12,
    4.5, 13.0,
    25.0,2, 
    -2,
    M3_cap_screw,0,0];

// Turnigy XK3674 heavy brushless
motortype_3674=[36,74.3,
    19,5,4.5,
    0,0,
    25,6,
    0,
    M3_cap_screw,0,0];

// Turnigy XK2845 light brushless
motortype_2845=[28,46.8,
    14.4,3.12,2.9,
    0,0,
    19,2,
    0,
    M3_cap_screw,0,0];


// Call children at the center of each motor bolt
module motor_bolt_locations(type,countscale=1) 
{
    count=countscale*motor_bolthole_count(type);
    for (angle=[motor_bolthole_angle(type):360/count:360-1])
        rotate([0,0,angle])
            translate([motor_bolthole_radius(type),0,0])
                children();
}

// Create mounting bolts facing down into this motor.  
//   +Z is along the motor shaft, origin is at the base of the bolts.
//   The caps extend by extra_head in Z
module motor_bolts(type,web=-0.01,clearance=motor_clearance,extra_head=10)
{
    motor_bolt_locations(type) 
        screw_3D(motor_screw(type),thru=10,length=10,clearance=clearance,web=web,extra_head=extra_head);
}


// Make 2D slots where the motor intakes air
module motor_vents_2D(type)
{
    delta=motor_vent_delta(type);
    if (delta!=0) {
        screw=motor_screw(type);
        vent_halfwidth=0.7*screw_diameter(screw); // half the width of the vent slots
        vent_r=motor_bolthole_radius(type)+delta; // centerline of vents
        r=0.9*vent_halfwidth;
        offset(r=+r) offset(r=-r) //<- round the vent slots
        difference() {
            circle(r=vent_r+vent_halfwidth);
            circle(r=vent_r-vent_halfwidth);
            
            // Leave meat around the bolts:
            motor_bolt_locations(type,2)
                circle(d=1.5*screw_head_diameter(screw));
        }
    }
}

// Make 2D version of motor face, with holes for boss, vents, and screws
module motor_face_2D(type,with_boss=1,with_screws=1,with_vents=1)
{
    difference() {
        intersection() {
            circle(d=motor_diameter(type));
            s=motor_square(type);
            if (s>0) square([s,s],center=true);
        }
        
        if (with_boss) circle(d=motor_boss_diameter(type));
        if (with_screws) motor_bolt_locations(type) circle(d=screw_diameter(motor_screw(type)));
        if (with_vents) motor_vents_2D(type);
    }
}


// Solid version of motor shaft (e.g., for gears)
//  If spin is nonzero, it's a clearance around a spinning shaft.
module motor_3D_shaft(type,spin=0,web=-0.01,shaft_clearance=0.05,extra_OD=0,extra_Z=0)
{
    intersection() {
        start=motor_boss_length(type)+web;
        len=motor_shaft_length(type)+extra_Z-start;
        d=motor_shaft_diameter(type);
        translate([0,0,start])
        cylinder(d=d+2*shaft_clearance+spin+extra_OD,h=len);
        if (spin==0) // include flat on shaft
            translate([d/2-motor_shaft_flat(type)-shaft_clearance+100,0,0])
                cube([200,200,200],center=true);
    }
}


// Make solid version of motor, not including terminals or bolts.
//  Works like cylinder: shaft sticks up along +Z direction.
//  Origin is at base of shaft on face plane.
module motor_3D(type,spin=0,web=-0.01,
    clearance=motor_clearance,
    shaft_clearance=0.05,
    extra_OD=0,extra_Z=0,with_shaft=1,with_boss=1,with_vents=1,vent_ht=10)
{
    // motor body (below the face in -Z)
    translate([0,0,0.005])
    scale([1,1,-1]) 
    intersection() {
        z=motor_length(type)+extra_Z;
        cylinder(d=motor_diameter(type)+clearance+extra_OD,  h=z);
        s=motor_square(type);
        if (s>0) {
            s=s+clearance+extra_OD;
            translate([0,0,z/2])
                cube([s,s,z],center=true);
        }
    }
    
    // boss
    if (with_boss)
        cylinder(d=motor_boss_diameter(type)+clearance+extra_OD, h=motor_boss_length(type)+extra_Z);
    
    // shaft
    if (with_shaft)
        motor_3D_shaft(type,spin=spin,web=web,shaft_clearance=shaft_clearance,
        extra_OD=extra_OD,extra_Z=extra_Z);
    
    // vents
    if (with_vents)
        linear_extrude(height=vent_ht,convexity=4) motor_vents_2D(type);
}









