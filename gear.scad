/*
Simple involute gear generator code.

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

Notes on 3D printed gears:	https://engineerdog.com/2017/01/07/a-practical-guide-to-fdm-3d-printing-gears/

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
*/
function gear_create(geartype,nteeth) = [ geartype, nteeth ];
function gear_geartype(gear) = gear[0];
function gear_nteeth(gear) = gear[1];
function gear_height(gear) = geartype_height(gear_geartype(gear));

// Diameter of gear along pitch circle
function gear_D(gear) = geartype_Dpitch(gear[0])*gear[1];
function gear_ID(gear) = gear_D(gear)-2*geartype_sub(gear[0]);
function gear_OD(gear) = gear_D(gear)+2*geartype_add(gear[0]);

// Radius versions
function gear_R(gear) = gear_D(gear)/2;
function gear_IR(gear) = gear_ID(gear)/2;
function gear_OR(gear) = gear_OD(gear)/2;



// Draw one gear
module gear_2D(gear) {
	if (showteeth) {
		IR=gear_IR(gear);
		OR=gear_OR(gear);
		nT=gear_nteeth(gear);
		dT=360/nT; // angle per tooth (degrees)
		gt=gear_geartype(gear);
		Cpitch=geartype_Cpitch(gt);
		angle=geartype_pressure(gt);
		refR=IR;
		hO=OR-refR;
		hM=gear_R(gear)-refR;
		tilt = angle-0.5*dT;
		tI=Cpitch/4+geartype_sub(gt)*sin(tilt);
		tM=Cpitch/4;
		tO=Cpitch/4-geartype_add(gt)*(sin(tilt)+sin(dT));
		round=0.15*Cpitch;
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
			circle(r=OR);
		}
	}
	else
	{ // no teeth, just pressure circle (much faster)
		circle(d=gear_D(gear));
	}
}


/*
  Planetary gear support.
  One gearplane consists of:
    [0] geartype
    [1] (S) sun gear tooth count
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
function gearplane_Sgear(gearplane) = gear_create(gearplane[0],gearplane_Steeth(gearplane));
function gearplane_Sradius(gearplane) = gear_R(gearplane_Sgear(gearplane));

// Planet gear:
function gearplane_Pteeth(gearplane) = gearplane[2];
function gearplane_Pgear(gearplane) = gear_create(gearplane[0],gearplane_Pteeth(gearplane));
function gearplane_Pradius(gearplane) = gear_R(gearplane_Pgear(gearplane));

function gearplane_Pcount(gearplane) = gearplane[3];

// Ring gear:
function gearplane_Rteeth(gearplane) = gearplane_Steeth(gearplane)+2*gearplane_Pteeth(gearplane);
function gearplane_Rgear(gearplane) = gear_create(gearplane[0],gearplane_Rteeth(gearplane));
function gearplane_Rradius(gearplane) = gear_R(gearplane_Rgear(gearplane));

// Oradius: radius at which planets orbit the sun
function gearplane_Oradius(gearplane) = gearplane_Sradius(gearplane)+gear_R(gearplane_Pgear(gearplane));


// Gear reduction ratio if ring gear is fixed, planet carrier from sun gear.
function gearplane_ratio_Rfixed(gearplane) = (gearplane_Rteeth(gearplane) + gearplane_Steeth(gearplane)) / gearplane_Steeth(gearplane);


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


// Draw a full plane of gears
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
		gear_2D(Sgear);
	
	// Planets
	gearplane_planets(gearplane)
		gear_2D(Pgear);
	
	// Ring
	gearplane_ring_2D(gearplane);
}


// Make a 3D gear, with beveled teeth
module gear_3D(gear,enlarge=0,bevel=1,height=0,clearance=0) 
{
    e2=2*enlarge;
    translate([0,0,-enlarge])
    {
	    h=(height?height:gear_height(gear))+e2;
	    intersection() {
		    if (bevel) hull() {
			    cylinder(d1=gear_ID(gear)+e2,d2=gear_OD(gear)+e2,h=bevel);
			    translate([0,0,h]) scale([1,1,-1])
			    cylinder(d1=gear_ID(gear)+e2,d2=gear_OD(gear)+e2,h=bevel);
		    }
		    linear_extrude(height=h,convexity=8)
		        offset(r=-clearance+enlarge)
			    gear_2D(gear);
	    }
	}
}

// Cut ring gear hole in a cylinder (e.g., gear_OD+2*wall diameter)
module ring_gear_cut(ring,clearance=0.15)
{
    gear_3D(ring,
        bevel=0, //< straight ends (avoids overhangs)
        clearance=-clearance //< this is a cut, so needs to enlarge the opposite way
    );
}


// Print stepped planet gears as a single piece
module stepped_planets(gearplane_in,gearplane_out,
    overlap=3,axle_hole=6,clearance=0,enlarge=0,bevel=1)
{
    difference() {
        union() {
            // lower gearplane
            gearplane_planets(gearplane_in)
                gear_3D(gearplane_Pgear(gearplane_in),
                    clearance=clearance,enlarge=enlarge,bevel=bevel);
            
            // upper gearplane
            dz=gearplane_height(gearplane_in);
            translate([0,0,dz-overlap])
            gearplane_planets(gearplane_out)
                gear_3D(gearplane_Pgear(gearplane_out),
                    height=dz+overlap,
                    clearance=clearance,enlarge=enlarge,bevel=bevel);
        }
        
        // axle hole (or lighten)
        gearplane_planets(gearplane_in)
            cylinder(d=axle_hole-2*enlarge,h=2.1*(gearplane_height(gearplane_in)+gearplane_height(gearplane_out)),center=true);
    }
}



