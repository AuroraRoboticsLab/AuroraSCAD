/*
 Example of how to use the AuroraSCAD/motor library.

 Dr. Orion Lawlor, lawlor@alaska.edu, 2022-03-06 (Public Domain)
*/
include <../AuroraSCAD/motor.scad>;
$fs=0.1; $fa=2;

all_motors=[motortype_750,motortype_550,motortype_3674,motortype_2845];
n_all_motors=4;

plate=5;

module show_motor(type) 
{
    cap=screw_head_height(motor_screw(type));
    faceZ=3;
    boltZ=faceZ+2;
    overallZ=boltZ+cap;
        
    //motor_face_2D(type);
    difference() {
        cylinder(d=motor_diameter(type)+4,h=overallZ);
        
        translate([0,0,faceZ]) motor_3D(type,spin=1);
        
        translate([0,0,boltZ]) motor_bolts(type);
    }  
    // webbing. to eliminate bridges when printed this way up
    //translate([0,0,faceZ]) cylinder(d=motor_diameter(type)+1,h=0.3);
}

module show_all_motors(i=0)
{
    if (i<n_all_motors) {
        m=all_motors[i];
        translate([motor_diameter(m)/2+3,0,0])
        {
            show_motor(m);
            translate([motor_diameter(m)/2+3,0,0])
                show_all_motors(i+1);
        }
    }
}

show_all_motors(0);

