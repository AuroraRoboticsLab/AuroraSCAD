/*
 Builds a series of gear stages, for example to reduce a motor input to an output shaft.

 Gearbox data structures are indexed by the stage number, for example:
    [0]: Output stage
    [1]: Reducer stage
    [2]: Motor input stage

 geartypes: Each stage shares the gear pitch (geartype) between the big and little gears, so they mesh.  The height defines the vertical step between each stage too.

 toothcounts: Number of teeth per gear, stored as an array in each stage with big [0] (possibly negative, indicating a ring gear) then lil [1]. 

 angles: degrees of Z rotation to shift the next geartrain stage away from the X axis.
 
 Example gearbox:
 gearbox = gearbox_create(
    // Geartypes for each stage
    [ geartype_create(1.75), geartype_create(1.25), geartype_create(0.8) ],

    // Tooth counts for big and little gears at each stage
    [ [ 40, 12 ], [ 52, 10 ],  [64, 14] ],
    
    // Angles between each stage
    [ 90, 45, 90 ],
    
    // axleODs: thru-gear axle diameters for the big gear of each stage
    [ 5.0, 4.0, 3.0 ],
    
    // Thru-frame hole diameters at each stage (here, for tapped threads)
    [ 4.5, 3.5, 2.7 ],
    
    // Clearances: between gears radial (clearanceR), between stages vertical (clearanceZ), vertical Z shift direction (shiftZ)
    [ 0.1, 1, -1 ]
 );

*/
include <gear.scad>; // https://github.com/AuroraRoboticsLab/AuroraSCAD

// Create a gearbox with these arrays, each indexed by the stage. 
function gearbox_create(geartypes, toothcounts, angles, axleODs, frameODs=axleODs, clearances=[0,1])
    = [ geartypes, toothcounts, angles, axleODs, frameODs, clearances ];

// Return how many stages this gearbox has:  stage=[0:gearbox_stages(gearbox)-1]
function gearbox_stages(gearbox) = len(gearbox[0]);

// Look up this gearbox's geartype for this stage number
function gearbox_geartype(gearbox,stage) = gearbox[0][stage];

// Look up this gearbox's big (0) or little (1) tooth count
function gearbox_toothcount(gearbox,stage,islittle) = abs(gearbox[1][stage][islittle]);

// Return 1 if this gearbox stage has a ring gear (inside teeth) instead of a spur
function gearbox_isring(gearbox,stage) = gearbox[1][stage][0]<0 ? 1 : 0;

// Make this gearbox's big (0) or little (1) gear structure
function gearbox_gear(gearbox,stage,islittle) = gear_create(
    gearbox_geartype(gearbox,stage),
    gearbox_toothcount(gearbox,stage,islittle),
    islittle ? 0 : gearbox_isring(gearbox,stage)
);

// Make the big gear for this gearbox stage
function gearbox_biggear(gearbox,stage) = gearbox_gear(gearbox,stage,0);
// Make the little gear for this gearbox stage
function gearbox_lilgear(gearbox,stage) = gearbox_gear(gearbox,stage,1);

// Return the idealized distance between this gearbox stage and the next stage
function gearbox_stageR(gearbox,stage,clearanceR=0) = (
    gear_R(gearbox_biggear(gearbox,stage)) + 
    (gearbox_isring(gearbox,stage)?-1:+1)*(
        clearanceR + gear_R(gearbox_lilgear(gearbox,stage))
    )
);

// Return the angle beween this gearbox stage and the next stage
function gearbox_stageangle(gearbox,stage) = gearbox[2][stage];

// Return the thru-gear axle hole size of this gearbox stage's big gear
function gearbox_axleOD(gearbox,stage) = cap_lookup(gearbox[3],stage);
// Return the thru-frame axle hole size of this gearbox stage
function gearbox_frameOD(gearbox,stage) = cap_lookup(gearbox[4],stage);

function cap_lookup(array,index) = (index>=len(array))?array[len(array)-1]:array[index];

// Return the clearance between gears (pitch radius)
function gearbox_clearanceR(gearbox) = gearbox[5][0];
// Return the vertical clearance between gear stages (Z)
function gearbox_clearanceZ(gearbox) = gearbox[5][1];
// Return the direction (+1 for +Z, -1 for -Z) each axle is shifted
function gearbox_shiftZ(gearbox) = gearbox[5][2];

// Return the Z height difference down to this stage
function gearbox_stepZ(gearbox,stage) = (
    (stage>=gearbox_stages(gearbox))?0:
        gearbox_shiftZ(gearbox)*(
            gearbox_clearanceZ(gearbox)+
              geartype_height(gearbox_geartype(gearbox,stage))
        )
    );


// Return the cumulative gear ratio
function gearbox_ratio(gearbox) = gearbox_ratio_stages(gearbox,0);
function gearbox_ratio_stage(gearbox,stage) = gear_R(gearbox_biggear(gearbox,stage))/gear_R(gearbox_lilgear(gearbox,stage));
function gearbox_ratio_stages(gearbox,stage) = gearbox_ratio_stage(gearbox,stage)*(
    stage+1>=gearbox_stages(gearbox)?1:gearbox_ratio_stages(gearbox,stage+1)
);


// Make the reduction gear for this stage (not stage 0)
module gearbox_reduction3D(gearbox,stage) 
{
    lilG=gearbox_lilgear(gearbox,stage-1);
    bigG=gearbox_biggear(gearbox,stage);
    reduction_gear3D(bigG,lilG,gearbox_axleOD(gearbox,stage));
}

// Rotate and translate to the center of this stage's axis
module gearbox_transform(gearbox,stage,shiftZ=-1)
{
    cR=gearbox_clearanceR(gearbox);
    cZ=gearbox_clearanceZ(gearbox);
    if (stage<=0) children(); // base case
    else {
        gearbox_transform(gearbox,stage-1) //<- recursive case
            rotate([0,0,gearbox_stageangle(gearbox,stage-1)])
                translate([gearbox_stageR(gearbox,stage-1,cR),0,0])
                    translate([0,0,gearbox_stepZ(gearbox,stage)])
                        children(); 
    }
}

// Move to the gearbox motor center
module gearbox_motor_transform(gearbox) 
{
    gearbox_transform(gearbox,gearbox_stages(gearbox),0)
        children();
}

// Spaces for gearbox frame shafts
module gearbox_frame_shafts(gearbox,len=110,start_stage=0)
{
    // Reduction gear stages
    stages=gearbox_stages(gearbox);
    for (stage=[start_stage:stages-1]) 
        gearbox_transform(gearbox,stage)
            cylinder(d=gearbox_frameOD(gearbox,stage),h=len,center=true);
}

// Space for this gear to spin freely
module gear_clearance(gearbig,gearlil,axleOD,spaceR=1,spaceZ=1,undergearZ=1,axleWall=2) 
{
    r = gear_OR(gearbig)+spaceR;
    z = gear_height(gearbig)+spaceZ+gear_height(gearlil);

    difference() {
        translate([0,0,-undergearZ])
            cylinder(r=r,h=undergearZ + z + undergearZ);
        translate([0,0,-undergearZ-0.01]) // don't clear space around axle
            cylinder(d=axleOD+2*axleWall,h=undergearZ + z + undergearZ+0.02);
    }
}

// Clearance for each of these gears to spin freely
module gearbox_clearance(gearbox,spaceR=1,spaceZ=1)
{
    for (stage=[0:gearbox_stages(gearbox)-1]) 
    {
        gearbox_transform(gearbox,stage) 
            gear_clearance(gearbox_biggear(gearbox,stage),
                gearbox_lilgear(gearbox,stage),
                gearbox_axleOD(gearbox,stage),spaceR,spaceZ);
    }
}

// Frame holds each stage's axle.  
//   The bottoms run long here, trim everything off at your preferred Z.
module gearbox_frame_solid(gearbox,wall=2,wallplate=1,len=50)
{
    for (stage=[0:gearbox_stages(gearbox)-1]) 
    {
        // Stage axles
        gearbox_transform(gearbox,stage) 
            scale([1,1,-1]) 
                cylinder(d=2*wall + gearbox_frameOD(gearbox,stage),h=len);
        
        // Plates between stage axles
        translate([0,0,-1])
        hull() {
            gearbox_transform(gearbox,stage) translate([0,0,gearbox_stepZ(gearbox,stage+1)])
                scale([1,1,-1]) 
                    cylinder(d=2*wallplate + gearbox_frameOD(gearbox,stage),h=len);
            gearbox_transform(gearbox,stage+1) 
                scale([1,1,-1]) 
                    cylinder(d=2*wallplate + gearbox_frameOD(gearbox,stage+1),h=len);
        }
    }
}

module gearbox_frame(gearbox)
{
    difference() {
        gearbox_frame_solid(gearbox);
        gearbox_clearance(gearbox);
        gearbox_frame_shafts(gearbox);
    }
}

// Illustrate entire gearbox
module gearbox_draw_all(gearbox,draw_frame=1)
{
    if (draw_frame) gearbox_frame(gearbox);
    
    // Final output gear
    outG=gearbox_biggear(gearbox,0);
    if (gear_ring(outG)) {
        difference() {
            translate([0,0,0.01]) cylinder(r=2+gear_OR(outG),h=gear_height(outG)-0.02);
            ring_gear_cut(outG);
        }
    }
    else { // normal spur gear
        gear_3D(outG);
    }
        
    // Reduction gear stages
    stages=gearbox_stages(gearbox);
    for (stage=[1:stages-1]) 
        gearbox_transform(gearbox,stage)
            gearbox_reduction3D(gearbox,stage);
    
    // Motor input gear on last stage
    gearbox_motor_transform(gearbox)
        gear_3D(gearbox_lilgear(gearbox,stages-1));
    
}






