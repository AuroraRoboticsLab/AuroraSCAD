/*
 Mechanical roller chain sprocket
 
 Derived from:  kresty December 06, 2013 Roller Chain Sprockets OpenSCAD Module
   CC BY-NC
   https://www.thingiverse.com/thing:197896/files
 
 Changed 2025-10 by Orion Lawlor to do a 2D extrude.
*/

// $fs=0.1; $fa=2; // smooth output (left to user)

// Adjust these if it's too tight/loose on your printer,
// These seem to be OK on my Replicator 1
FUDGE_BORE=0;	 // mm to fudge the edges of the bore
FUDGE_ROLLER=0.0; // mm to fudge the hole for the rollers
FUDGE_THICK=0.98; // fraction of nominal thickness to actually print
FUDGE_TEETH=0.0;  // Additional taper of the teeth
FUDGE_TEETH_TIP=0.0; // mm to trim back the tips of the teeth
  
FUDGE_ROUND=1.5; // mm of rounding on tooth tips
                
function inches2mm(inches) = inches * 25.4;
function mm2inches(mm) = mm / 25.4;

module sprocket(size=25, teeth=9, bore_radius_mm=inches2mm(5/16)/2)
{
	thickness=get_thickness_mm(size);
	
    linear_extrude(height=thickness,convexity=8)
    difference() {
        sprocket_plate2D(size, teeth);
        
        if (bore_radius_mm > 0)
        {
            circle(r=bore_radius_mm+FUDGE_BORE);
        }
        
        children(); // cut additional 2D drive key slots etc here
    }
}

// Look up the outside radius (mm) for this many teeth
function get_outside_radius_mm(size,teeth) = 
    inches2mm(get_pitch_inch(size)*(0.6+1/tan(180/teeth))) / 2;

// Look up the pitch radius (mm) for this many teeth
function get_pitch_radius_mm(size,teeth) =
    inches2mm(get_pitch_inch(size)/sin(180/teeth)) / 2;

// Make a 2D sprocket shape with this size (e.g., 40 for #40 roller chain) and tooth count.
//   Center is solid, use a difference to cut in the boreway
module sprocket_plate2D(size, teeth, verbose=0)
{
	angle = 360/teeth; // angular distance between rollers
	pitch=inches2mm(get_pitch_inch(size)); // distance between roller centers
	roller=inches2mm(get_roller_diameter_inch(size)/2); // radius of roller
	outside_radius = get_outside_radius_mm(size,teeth);
	pitch_radius = get_pitch_radius_mm(size,teeth); // distance from axle to roller centers

    if (verbose) {
        echo("Pitch=", mm2inches(pitch));
        echo("Pitch mm=", pitch);
        echo("Roller=", mm2inches(roller));
        echo("Roller mm=", roller);

        echo("Outside diameter=", mm2inches(outside_radius * 2));
        echo("Outside diameter mm=", outside_radius * 2);
        echo("Pitch Diameter=", mm2inches(pitch_radius * 2));
        echo("Pitch Diameter mm=", pitch_radius * 2);
    }
    
    // Radius to middle of teeth
	middle_radius = sqrt(pow(pitch_radius,2) - pow(pitch/2,2));

    offset(r=+FUDGE_ROUND) offset(r=-FUDGE_ROUND)
	difference()
	{
		union()
		{
			// Main plate (doesn't quite mate with the teeth, not done this way)
//			cylinder(r=pitch_radius-roller+.1, h=thickness);

			intersection()
			{
                // Trim outer tooth tips
				circle(r=pitch_radius-roller+pitch/2-FUDGE_TEETH_TIP);

				// Main section
				union()
				{
					// Build the teeth
					for (sprocket=[0:teeth-1])
					{
						// Rotate current sprocket by angle
						rotate([0,0,angle*sprocket])
						{
						    // The logic for tooth tips: the roller for the next segment needs to be free to swing over our tooth tip
						        intersection_for (side=[0,+1]) rotate([0,0,angle*side])
						            translate([0,pitch_radius])
						                circle(r=pitch-roller-FUDGE_ROLLER-FUDGE_TEETH);
						    
						}
					}

                    circle(r=middle_radius); //<- simpler (might leave tiny corners)
                
					// Fill the gap in the bottom
					if (0) for (sprocket=[0:teeth-1])
					{
						rotate([0,0,angle*sprocket-angle/2])
						translate([-pitch/2,-.01,0])
						square([pitch,middle_radius+.01]);
					}
				}
			}
		}

		// Remove holes for the rollers
		for (sprocket=[0:teeth-1])
		{
			rotate([0,0,angle*sprocket])
			translate([0,pitch_radius])
			circle(r=roller+FUDGE_ROLLER);
		}
	}

	// guide line for pitch radius
//	cylinder(h=.1,r=outside_radius);
//	cylinder(h=.2,r=pitch_radius);
}

// Return inch pitch
function get_pitch_inch(size) =
	// ANSI
	size == 25 ? 1/4 :
	size == 35 ? 3/8 :
	size == 40 ? 1/2 :
	size == 41 ? 1/2 :
	size == 50 ? 5/8 :
	size == 60 ? 3/4 :
	size == 80 ? 1 :
	// Bike
	size == 1 ? 1/2 :
	size == 2 ? 1/2 :
	// Motorcycle
	size == 420 ? 1/2 :
	size == 425 ? 1/2 :
	size == 428 ? 1/2 :
	size == 520 ? 5/8 :
	size == 525 ? 5/8 :
	size == 530 ? 5/8 :
	size == 630 ? 3/4 :
	// unknown
	0;

// Return inch roller diameter
function get_roller_diameter_inch(size) =
	// ANSI
	size == 25 ? .130 :
	size == 35 ? .200 :
	size == 40 ? 5/16 :
	size == 41 ? .306 :
	size == 50 ? .400 :
	size == 60 ? 15/32 :
	size == 80 ? 5/8 :
	// Bike
	size == 1 ? 5/16 :
	size == 2 ? 5/16 :
	// Motorcycle
	size == 420 ? 5/16 :
	size == 425 ? 5/16 :
	size == 428 ? .335 :
	size == 520 ? .400 :
	size == 525 ? .400 :
	size == 530 ? .400 :
	size == 630 ? 15/32 :
	// unknown
	0;

// Return mm thickness of plate, including slimming
function get_thickness_mm(size) = FUDGE_THICK * inches2mm(get_thickness_inch(size));

// I think there's a formula for this, but by the
// time I realized that I already had the table...
function get_thickness_inch(size) =
	// ANSI
	size == 25 ? .110 :
	size == 35 ? .168 :
	size == 40 ? .284 :
	size == 41 ? .227 :
	size == 50 ? .343 :
	size == 60 ? .459 :
	size == 80 ? .575 :
	// Bike
	size == 1 ? .110 :
	size == 2 ? .084 :
	// Motorcycle
	size == 420 ? .227 :
	size == 425 ? .284 :
	size == 428 ? .284 :
	size == 520 ? .227 :
	size == 525 ? .284 :
	size == 530 ? .343 :
	size == 630 ? .343 :
	// unknown
	0;

// Example:
//sprocket(40,17);

