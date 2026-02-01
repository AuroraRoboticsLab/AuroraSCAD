/*
Beveled primitives, designed as drop-in replacements for builtins.

 Dr. Orion Lawlor, lawlor@alaska.edu, 2023-01-18 (Public Domain)

*/


// Beveled cube
module bevelcube(size,bevel,center=false,bz=1)
{
    translate(center?[0,0,0]:size/2)
    hull() {
        cube(size-[2*bevel,2*bevel,0],center=true);
        cube(size-[2*bevel,0,bz*2*bevel],center=true);
        cube(size-[0,2*bevel,bz*2*bevel],center=true);
    }
}

// Beveled 2D square
module bevelsquare(size,bevel,center=false)
{
    translate(center?[0,0,0]:size/2)
    hull() {
        square(size-[2*bevel,0],center=true);
        square(size-[0,2*bevel],center=true);
    }
}


// Beveled cylinder
module bevelcylinder(d,h,bevel,center=false,$fn=0)
{
    translate(center?[0,0,0]:[0,0,h/2])
    hull() {
        cylinder(d=d-2*bevel,h=h,center=true,$fn=$fn);
        cylinder(d=d,h=h-2*bevel,center=true,$fn=$fn);
    }
}

// Bevel linear extrude convex 2D children into 3D (uses hull, so only convex works)
module bevel_extrude_convex(height=100,bevel=1,center=false,convexity=2)
{
    del=0.01; // thickness of slices
    
    translate([0,0,center?-height/2:0])
    hull()
    for (step=[
        /* z, r */
        [0,bevel],
        [bevel,0],
        [height-bevel-del,0],
        [height-del,bevel]
    ]
    )
    {
        translate([0,0,step[0]])
        linear_extrude(height=del,convexity=convexity)
            offset(r=-step[1])
                children();
    }
}

// Bevel linear extrude non-convex 2D children into 3D (only bevels outside corners though)
module bevel_extrude_outside(height=100,bevel=1,center=false,convexity=2)
{
    intersection() {
        bevel_extrude_convex(height,bevel,center,convexity) children();
        linear_extrude(height,center=center,convexity=convexity) children();
    }
}


