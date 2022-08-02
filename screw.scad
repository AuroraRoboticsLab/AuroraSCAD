/*
 OpenSCAD library of machine screw fasteners. 
 
 Data structures and accessors directly inspired by nophead's amazing mendel90 scad/vitamins.
 
 Dr. Orion Lawlor, lawlor@alaska.edu, 2022-05 (Public Domain)
*/

screw_clearance=0.1;
motor_clearance=0.1;

/*
machine screw={
    [0] outside diameter of threads
    [1] tap diameter of threads
    [2] outside diameter of head
    [3] total height of head
*/
M3_cap_screw=[3.0,2.5, 5.8,2.7];
M4_cap_screw=[4.0,3.3, 7.2,3.2];
US10_24_pan_screw=[5.0,3.8, 9.5,2]; /* US #10-24 machine screw, pan head */
QI_cap_screw=[6.4,5.2, 9.6,6.6]; /* US quarter inch 1/4" cap screw */
US_5_16_hex=[8.0,6.3, 14.2,6]; /* US 5/16" hex bolt */

function screw_diameter(type) = type[0];
function screw_radius(type) = type[0]/2;
function screw_tap_diameter(type) = type[1];
function screw_head_diameter(type) = type[2];
function screw_head_height(type) = type[3];

/* Make a 3D screw model.  The origin is at the base of the head.
   The screw shaft faces down -Z, the cap faces up +Z (like a cylinder).
   "thru" is the length of the unthreaded portion.
   "length" is the overall length including thru and tapped portion.
   "web" is space between head and shaft along Z, a webbing plate used for cleaner bridging
*/
module screw_3D(type,clearance=screw_clearance,web=-0.01,thru=0,length=25,extra_head=0) {
    scale([1,1,-1]) {
        cylinder(d=screw_tap_diameter(type)+clearance,h=length);
        cylinder(d=screw_diameter(type)+clearance,h=thru);
    }
    translate([0,0,web])
        cylinder(d=screw_head_diameter(type)+clearance,h=screw_head_height(type)+extra_head);
}


