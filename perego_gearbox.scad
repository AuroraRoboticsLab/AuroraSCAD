/*
 Fits the big cross-shaped projection on 
 the Peg Perego electric motor gearbox output shaft.
 
 In addition to our robots, these gearboxes are used by PowerWheels, 
 like the Barbie Jeep (hence the alternate name!). 
 
 Dr. Orion Lawlor, lawlor@alaska.edu, 2017-2022 (Public Domain)
*/
bearing_outer_diam = 7/8*25.4; // 22.225; // 7/8 inch
bearing_width = 9/32*25.4; // 7.14375; // 9/32 inch

barbie_gearbox_height=16.5; // Z size of motor drive cross
wiggle=0.1; // distance to add around holes so parts fit (keep tight, for bearings)

// Bearing that fits on axle
module axle_bearing(fatten=0.0) {
	cylinder(d=bearing_outer_diam+2*wiggle+fatten, h=bearing_width+fatten+wiggle+1);
}

// 3D holes to fit all the projections associated with a Barbie jeep gearbox.
//  Z=0 is the plane at the front of the projections.
module barbie_gearbox(overall_height,fatten=0.0)
{
    radius=16;
    cube_width=13;
    cube_diameter=50;
    round=1.5;
    
    // Main body
	translate([0,0,-barbie_gearbox_height-fatten])
		linear_extrude(height=barbie_gearbox_height+fatten,convexity=4)
			
			offset(r=round) offset(r=-round) // rounds outside corners
      offset(r=-round) offset(r=round) // rounds inside corners

			offset(r=2*wiggle+fatten)
			{
				circle(r=radius);
				square([cube_width,cube_diameter],center=true);
				square([cube_diameter,cube_width],center=true);
			}

	// Inside bearing hole
	translate([0, 0, -barbie_gearbox_height-bearing_width-fatten]){
		axle_bearing(fatten);
	}
	// Outside bearing hole
	translate([0, 0, -overall_height-fatten]){
		axle_bearing(fatten);
	}

	// Thru axle hole
	translate([0, 0, -overall_height]){
		cylinder(d=11+2*(wiggle+fatten), h=overall_height);
	}
}


