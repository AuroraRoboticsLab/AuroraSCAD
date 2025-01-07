/*
 Gearbox that holds a NEMA 17 stepper motor, and bolts to a robot ring gear.
*/
include <gearbox.scad>; // https://github.com/AuroraRoboticsLab/AuroraSCAD
include <motor.scad>;

gearbox = gearbox_create(
    // Geartypes for each stage (tooth module slowly decreasing)
    [ geartype_create(1.75,12), geartype_create(1.25,10), geartype_create(0.8,8) ],

    // Tooth counts for big and little gears at each stage (negative = ring)
    [ [ -42, 9 ], [ 35, 10 ],  [58, 14] ],
    
    // Angles between each stage
    [ 0, 90, 90 ],
    
    // axleODs: thru-gear axle diameters for the big gear of each stage
    [ 8, 3.0, 3.0 ],
    
    // Thru-frame hole diameters at each stage (here, for tapped threads)
    [ 8, 2.6, 2.6 ],
    
    // Clearances
    [ 0.1, 1, -1 ]
 );


motortype = motortype_NEMA17;
motorZ=[0,0,-12];
motorplate=3;

module gearbox_illustrate() {
    echo("Gear ratio: ",gearbox_ratio(gearbox));
    
    // Show the gears
    gearbox_draw_all(gearbox,0);

    // Build the frame that holds the gears
    difference() {
        gearbox_frame(gearbox);
        gearbox_motor_transform(gearbox) translate(motorZ) {
            // Clear area around motor pinion
            cylinder(d=motor_boss_diameter(motortype),h=100);
            // Cut off bottom flat
            translate([0,0,-500]) cube([1000,1000,1000],center=true);
        }
    }
    
    // Draw the motor and shafts
    gearbox_motor_transform(gearbox) translate(motorZ) {
        linear_extrude(height=motorplate,convexity=6)
            motor_face_2D(motortype);
        #motor_3D(motortype);
        #translate([0,0,motorplate]) motor_bolts(motortype);
    }
    #gearbox_frame_shafts(gearbox);
}

gearbox_illustrate();

//gearbox_reduction3D(gearbox,1);
//gearbox_reduction3D(gearbox,2);
