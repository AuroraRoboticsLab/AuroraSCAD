/*
 OpenSCAD library of bushings and bearings. 
 
 Data structures and accessors directly inspired by nophead's amazing mendel90 scad/vitamins.
 
 Some info on bearing part numbers at:
    http://www.engineerstudent.co.uk/bearing_numbers_explained.html
 
 Dr. Orion Lawlor, lawlor@alaska.edu, 2023-03 (Public Domain)
*/

bearing_clearance=0.1;
inch = 25.4; // file units are mm

/*
bearing={
    [0] inside diameter of bearing
    [1] outside diameter of bearing
    [2] thickness of bearing
*/
bearing_683 = [ 3, 7, 3 ]; // M3 micro bearing
bearing_623 = [ 3, 10, 4 ]; // M3 medium bearing
bearing_624 = [ 4, 13, 5 ]; // M4 medium bearing
bearing_606 = [ 6, 17, 5 ]; // M6 medium bearing
bearing_608 = [ 8, 22, 7 ]; // "skate bearing", also fits 5/16" shaft
bearing_3_8 = [ 3/8*inch, 7/8*inch, 9/32*inch ]; // "R6", 3/8" bore, similar to 608 outside

// Babbitt bushings
bushing_8_10 = [ 8,10,8];

// Ring bearings with a large thru hole
bearing_6807 = [ 35, 47, 7 ];
bearing_6808 = [ 40, 52, 7 ]; 
bearing_6813 = [ 65, 85, 10 ]; 
bearing_6013 = [ 65, 100, 18 ]; 

// Needle bearings, for large axial loads
bearing_5_16_needle = [ 5/16*inch, 1/2*inch, 5/16*inch ]; // 5/16" needle bearing
bearing_3_8_needle = [ 3/8*inch, 9/16*inch, 3/8*inch ]; // 3/8" needle bearing
bearing_5_8_needle = [ 5/8*inch, 13/16*inch, 3/4*inch ]; // 5/8" needle bearing


function bearingID(type) = type[0];
function bearingOD(type) = type[1];
function bearingZ(type) = type[2];
function bearingIR(type) = type[0]/2;
function bearingOR(type) = type[1]/2;


/* Make a 3D bearing model, shaft facing along +Z */
module bearing3D(type,clearance=bearing_clearance,hole=1,support=0,web=0,extraZ=0) 
{
    z=bearingZ(type) + extraZ;
    difference() {
        cylinder(d=bearingOD(type)+clearance,h=z);
        if (hole) { // thru hole
            translate([0,0,-0.1])
                cylinder(d=bearingID(type)-clearance,h=z+0.2-web);
        }
        if (support) { // support the central shaft with a ring
            translate([0,0,-0.1])
                cylinder(d=bearingID(type)+support,h=z+0.2-web);
        }
    }
}


