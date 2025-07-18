/*
Simple approximately involute gear generator code.
Actually only does a low, middle, and high gear tip.

Applications: robot arms, wheels, legs, etc.

Built by Dr. Orion Lawlor (lawlor@alaska.edu) starting from many
sources and much trial and error, 2019-2021.  (Public Domain)

See also:
John Kerr's planetary reduction gears:
	https://www.thingiverse.com/LoboCNC/designs

General gear design:
	https://www.engineersedge.com/gear_formula.htm

Observations and constraints on planetary gearsets:
	https://woodgears.ca/gear/planetary.html

Notes on 3D printed gears:	
    https://engineerdog.com/2017/01/07/a-practical-guide-to-fdm-3d-printing-gears/

Much fancier (helical, bevel, true involute) library:
    https://github.com/dpellegr/PolyGear/

*/
$fs=0.1;
$fa=3;

// Distance between gear teeth
tooth_clearance=0.05;

// showteeth=true: show actual gear teeth.  False: show only pitch circle.
showteeth=true;

/*
  One geartype is a tooth profile for a family of gears with different numbers of teeth.
  
  geartype = [
    [0] Diametral gear pitch, in mm diameter per gear tooth.
    [1] Z height of teeth after extrusion
    [2] Pressure angle of teeth, in degrees (often 20)
    [3] Addendum: radial distance top of tooth sticks up from pitch circle
    [4] Dedendum: radial distance down from pitch circle to bottom of root
*/

// Geartype for an RS-550 type motor, 0.8P = approx 32 pitch.
geartype_550 = [ 0.8, 10.0, 20, 0.32, 0.4 ]; 

// Create a typical geartype
function geartype_create(moduleD, height=10.0, pressure=20.0, addn=0.32, dedn=0.40)
    = [ moduleD, height, pressure, addn, dedn ];

/// Circular gear pitch = distance between teeth along arc of pitch circle
function geartype_Cpitch(geartype) = geartype[0]*PI;

/// Diametral gear pitch = amount of diameter per gear tooth
function geartype_Dpitch(geartype) = geartype[0];

/// Height of each tooth along Z (after extrusion)
function geartype_height(geartype) = geartype[1];

/// Pressure angle (degrees)
function geartype_pressure(geartype) = geartype[2];

/// Addendum = radial distance top of tooth sticks up from pitch circle
function geartype_add(geartype) = geartype[3]*geartype_Cpitch(geartype);

/// Dedendum = radial distance down from pitch circle to bottom of root
function geartype_sub(geartype) = geartype[4]*geartype_Cpitch(geartype);

/* A gear consists of a type and a tooth count.
   This gear has a defined size.
   ring=0 if this is a normal spur gear (outside teeth)
   ring=1 if this is a ring gear (inside teeth)
*/
function gear_create(geartype,nteeth,ring=0) = [ geartype, nteeth, ring ];
function gear_geartype(gear) = gear[0];
function gear_nteeth(gear) = gear[1];
function gear_height(gear) = geartype_height(gear_geartype(gear));
function gear_ring(gear) = gear[2];

// Diameter of gear along pitch circle
function gear_D(gear) = geartype_Dpitch(gear[0])*gear[1];
function gear_ID(gear) = gear_D(gear)-2*(gear[2]?geartype_add(gear[0]):geartype_sub(gear[0]));
function gear_OD(gear) = gear_D(gear)+2*(gear[2]?geartype_sub(gear[0]):geartype_add(gear[0]));

// Radius versions
function gear_R(gear) = gear_D(gear)/2;
function gear_IR(gear) = gear_ID(gear)/2;
function gear_OR(gear) = gear_OD(gear)/2;



// Draw one gear, in 2D, with zero clearance.
//  Children cut holes, like for axle space.
module gear_2D(gear) {
	if (showteeth) {
		gt=gear_geartype(gear);
		IR=gear_IR(gear);
		OR=gear_OR(gear);
		nT=gear_nteeth(gear);
		dT=360/nT; // angle per tooth (degrees)
		Cpitch=geartype_Cpitch(gt); // circular pitch (one tooth along pressure circle arc)
		angle=geartype_pressure(gt); // pressure angle (degrees)
		refR=IR;
		hO=OR-refR;
		hM=gear_R(gear)-refR;
		tilt = angle-0.5*dT;
		tI=Cpitch/4+geartype_sub(gt)*sin(tilt);
		tM=Cpitch/4;
		tO=Cpitch/4-geartype_add(gt)*(sin(tilt)+sin(dT));
		round=0.1*Cpitch;
		if (nT>0)
		offset(r=-tooth_clearance/2)
		offset(r=+round) offset(r=-round) // round off inside corners
		offset(r=-round) offset(r=+round) // round outside corners
		intersection() {
			union() {
				circle(r=IR);
				// Loop over the gear's teeth 
				for (T=[0:nT-0.5])
					rotate([0,0,dT*T]) 
						translate([refR,0,0])
						polygon([
							[0,tI],
							[hM,tM],
							[hO,tO],
							[hO,-tO],
							[hM,-tM],
							[0,-tI]
						]);
			}
			difference() {
			    circle(r=OR);
			    children();
			}
		}
	}
	else
	difference() { // no teeth, just pressure circle (much faster)
		circle(d=gear_D(gear));
	    children();
	}
}


/*
  Planetary gear support.
  One gearplane consists of:
    [0] geartype
    [1] (S) sun gear tooth count (may be negative)
    [2] (P) planet gear tooth count
        (R) ring gear tooth count = S + 2*P
    [3] planet count (number of planet gears, such as 2 or 3 or 10)
*/

// Accessors for geartype and common parameters
function gearplane_geartype(gearplane) = gearplane[0];
function gearplane_height(gearplane) = geartype_height(gearplane[0]);
function gearplane_Cpitch(gearplane) = geartype_Cpitch(gearplane[0]);
function gearplane_Dpitch(gearplane) = geartype_Dpitch(gearplane[0]);

// Sun gear:
function gearplane_Steeth(gearplane) = gearplane[1];
function gearplane_Sgear(gearplane) = gear_create(gearplane[0],gearplane_Steeth(gearplane),ring=0);
function gearplane_Sradius(gearplane) = gear_R(gearplane_Sgear(gearplane));

// Planet gear:
function gearplane_Pteeth(gearplane) = gearplane[2];
function gearplane_Pgear(gearplane) = gear_create(gearplane[0],gearplane_Pteeth(gearplane),ring=0);
function gearplane_Pradius(gearplane) = gear_R(gearplane_Pgear(gearplane));

function gearplane_Pcount(gearplane) = gearplane[3];

// Ring gear:
function gearplane_Rteeth(gearplane) = gearplane_Steeth(gearplane)+2*gearplane_Pteeth(gearplane);
function gearplane_Rgear(gearplane) = gear_create(gearplane[0],gearplane_Rteeth(gearplane),ring=1);
function gearplane_Rradius(gearplane) = gear_R(gearplane_Rgear(gearplane));

// Oradius: radius at which planets orbit the sun
function gearplane_Oradius(gearplane) = gearplane_Sradius(gearplane)+gear_R(gearplane_Pgear(gearplane));


// Gear reduction ratio if ring gear is fixed, planet carrier from sun gear.
function gearplane_ratio_Rfixed(gearplane) = (gearplane_Rteeth(gearplane) + gearplane_Steeth(gearplane)) / gearplane_Steeth(gearplane);

// Print the basic counts of this gearplane:
module gearplane_print(gearplane,desc="") {
    echo("Gearplane: ",desc,
        "  Dpitch ",gearplane_Dpitch(gearplane),
        "  Sun",gearplane_Steeth(gearplane),
        "  Planet",gearplane_Pteeth(gearplane),
        "  Ring",gearplane_Rteeth(gearplane));
}


/*
 Stepped planetary gear support: a stepped planetary geartrain
 is two planetary geartrains where the orbit radii match, so 
 you can couple the planets together directly.  Power enters
 via the input sun gear, which spins the planets relative to the 
 fixed input ring gear.  Power leaves via the output ring gear. 
*/

// Gear ratio between two stepped planetary geartrains:
//   turns of input sun gear per turn of output ring gear.
function gearplane_stepped_ratio(gearplane_in,gearplane_out) = 
    gearplane_ratio_Rfixed(gearplane_in) * 
    gearplane_Rteeth(gearplane_out) / 
    (gearplane_Rteeth(gearplane_out)-gearplane_Rteeth(gearplane_in));


/*
 Return the diametral pitch required for the orbit radii of these gearplanes to match,
 assuming the planets have the same number of teeth, and the sun adds n teeth per planet.
 
 Rationale:
    gearplane_Oradius(gp) = gearplane_Oradius(gearplane_out);
    
    A = gearplane_Oradius(gp)
    B = gp[1]+n*gp[3]; // new sun gear tooth count
    C = gp[2]; // new planet gear tooth count
    p = new diametral pitch
    
    A = (B*p/2 + C*p/2);
    A*2/(B+C) = p
    
    gearplane_out = [ [p, ..], B, C, gp[3] ]
*/
function gearplane_stepped_Dpitch(gp,n=1) = (
    gearplane_Oradius(gp)*2/
    (gp[1]+n*gp[3]   +   gp[2])
);

/* Return a stepped planetary gearplane to match this one's
   planet count and planet gear teeth, but adjusting the 
   sun teeth by n per planet. */
function gearplane_stepped(gp,n=1) = [
    [ gearplane_stepped_Dpitch(gp,n), 
        gp[0][1], gp[0][2], gp[0][3], gp[0][4] ],
    gp[1]+n*gp[3],
    gp[2],
    gp[3]
];



// Return x rounded to the nearest multiple of step
function find_nearest_multiple(x,step) = step*round(x/step);

// Rotate to align the sun gear
module gearplane_sun(gearplane) {
	P=gearplane_Pteeth(gearplane);
	timing=(P%2)?0.0:0.5;
	rotate([0,0,360/gearplane_Steeth(gearplane)*timing])
		children();
}

// Translate (and rotate) to the positions of each planet gear
module gearplane_planets(gearplane) {	
	S=gearplane_Steeth(gearplane);
	P=gearplane_Pteeth(gearplane);
	nP=gearplane_Pcount(gearplane);
	Oradius=gearplane_Oradius(gearplane);
	
	// Planet gear positions must be a multiple of this to match ring
	Pconstraint=360/(gearplane_Rteeth(gearplane)+gearplane_Steeth(gearplane));
	
	for (P=[0:nP-0.5])
	{
		target=360/nP*P;
		ring=find_nearest_multiple(target,Pconstraint);
		timing = ring/360*S;
		rotate([0,0,ring])
			translate([Oradius,0,0])
				rotate([0,0,360/gearplane_Pteeth(gearplane)*timing])
					children();
	}
}

module gearplane_ring_2D_inside(gearplane) {
	offset(+tooth_clearance)
	gear_2D(gearplane_Rgear(gearplane));
}
module gearplane_ring_2D(gearplane,rim_thick=4) {
	difference() {
		circle(d=rim_thick+gear_OD(gearplane_Rgear(gearplane)));
		gearplane_ring_2D_inside(gearplane);
	}
}
module gearplane_hex_2D(gearplane,rim_thick=4) {
	difference() {
		circle(d=(rim_thick+gear_OD(gearplane_Rgear(gearplane)))/cos(30),$fn=6);
		gearplane_ring_2D_inside(gearplane);
	}
}


// Draw a full plane of gears.  Children are cut into the sun gear.
module gearplane_2D(gearplane) {
	Sgear=gearplane_Sgear(gearplane);
	Pgear=gearplane_Pgear(gearplane);
	Rgear=gearplane_Rgear(gearplane);
	
	// Gear timing:
	//   Ring gear defines alignment, right side always has tooth hole
	//   First planet gear fits into tooth hole
	//   Sun gear needs to match first planet
	//   Other planets need to match sun
	
	// Sun
	gearplane_sun(gearplane)
		gear_2D(Sgear)
		    children();
	
	// Planets
	gearplane_planets(gearplane)
		gear_2D(Pgear);
	
	// Ring
	gearplane_ring_2D(gearplane);
}


// Make a 3D gear, with beveled teeth:
//    enlarge makes the entire gear bigger on all sides
//    bevel flattens the vertical tips of the teeth
//    height overrides the gear's vertical height
//    clearance enlarges (normal gear) or shrinks (ring gear) the teeth in 2D
// children() get subtracted from gear, like for shafts or keyways or lightening
module gear_3D(gear,enlarge=0,bevel=1,height=0,clearance=0) 
{
    e2=2*enlarge;
    clear=gear_ring(gear)?-clearance:+clearance;
    translate([0,0,-enlarge])
    {
	    h=(height?height:gear_height(gear))+e2;
	    intersection() {
		    if (bevel) hull() {
			    cylinder(d1=gear_ID(gear)+e2,d2=gear_OD(gear)+e2,h=bevel);
			    translate([0,0,h]) scale([1,1,-1])
			    cylinder(d1=gear_ID(gear)+e2,d2=gear_OD(gear)+e2,h=bevel);
		    }
		    difference() {
		        linear_extrude(height=h,convexity=8)
		            offset(r=-clear+enlarge)
			        gear_2D(gear);
			    children();
			}
	    }
	}
}

// Cut ring gear hole in a cylinder
module ring_gear_cut(ring,clearance=0.15)
{
    gear_3D(ring,
        bevel=0, //< straight ends (avoids overhangs)
        clearance=clearance
    );
}


/// Make shape to lighten the gear G, leaving space for this axle
module gear_lighten2D(G,axleOD,wall=2,rib=1,anglestep=60)
{
    round=1.5; // round off the rib/circle intersections this much
    offset(r=+round) offset(r=-round)
    difference() {
        // outside circle against teeth
        circle(d=gear_ID(G)-2*wall);
        
        // inside circle leaves space for axle
        circle(d=axleOD + 2*wall);
        
        // Ribs connect axle to outer wall
        for (side=[-1,+1])
        for (angle=[anglestep/2:anglestep:360-1]) rotate([0,0,angle+5*side])
            translate([0,(axleOD+wall)/2,0]) scale([side,1,1])
                square([gear_OD(G),rib]);
    }
}

/// Make a stacked reduction gear with big (bottom) and lil (top)
module reduction_gear3D(bigG, lilG, axleOD, wall=2, floor=1)
{
    bZ=gear_height(bigG);
    lZ=gear_height(lilG);

    difference() {
        union() {
            // big bottom gear, lightened
            gear_3D(bigG, height=bZ, bevel=1);

            // little top gear sticks above it
            gear_3D(lilG, height=bZ+lZ, bevel=0);
            
            // Leave material above interface to top gear
            translate([0,0,bZ])
                cylinder(d1=gear_OD(lilG),d2=gear_ID(lilG),h=1);
        }
        
        // Lighten the big bottom gear
        difference() {
            translate([0,0,floor+0.01])
            linear_extrude(height=bZ-floor,convexity=4)
                gear_lighten2D(bigG,axleOD,wall);
            
            // Leave material below interface to top gear
            cylinder(d1=axleOD+2,d2=gear_OD(lilG),h=bZ);
        }
        
        // Axle runs through gear center
        cylinder(d=axleOD,h=100,center=true);
    }
}

// Print stepped planet gears as a single piece
module stepped_planets(gearplane_in,gearplane_out,
    raise_lower=3,lower_upper=1,axle_hole=6,clearance=0,enlarge=0,bevel=1)
{
    difference() {
        union() {
            // lower gearplane
            gearplane_planets(gearplane_in)
                gear_3D(gearplane_Pgear(gearplane_in),
                    height=gearplane_height(gearplane_in)+raise_lower,
                    clearance=clearance,enlarge=enlarge,bevel=bevel);
            
            // upper gearplane
            dz=gearplane_height(gearplane_in);
            translate([0,0,dz-lower_upper])
            gearplane_planets(gearplane_out)
                gear_3D(gearplane_Pgear(gearplane_out),
                    height=dz+lower_upper,
                    clearance=clearance,enlarge=enlarge,bevel=bevel);
        }
        
        // axle hole (or lighten)
        gearplane_planets(gearplane_in)
            cylinder(d=axle_hole-2*enlarge,h=2.1*(gearplane_height(gearplane_in)+gearplane_height(gearplane_out)),center=true);
    }
}



