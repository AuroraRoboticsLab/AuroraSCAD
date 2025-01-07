/*
 AuroraSCAD/gear.scad interface to PolyGear (which has true involute gear shapes).
*/

use <gear.scad>;
use <PolyGear/PolyGear.scad>;


module gear3D_via_PolyGear(gear,height,bevel=0,clearance=0,$fn=16)
{
    n=gear_nteeth(gear); 
    gt=gear_geartype(gear);
    m=geartype_Dpitch(gt);
    
    /* Translate addendum / dedendum:
        Polygear: 
            add_dist = m*(1 + add);
            add_dist / m - 1 = add
            
            ded_dist = m*(1.167)*(1 + ded);
            ded_dist/(m*1.167) - 1 = ded;
    */
    add=geartype_add(gt)/m - 1;
    ded=geartype_sub(gt)/(m*1.167) - 1; 
    backlash=clearance/m;
    type=+1; // gear_ring(gear)?-1:+1;
    
    translate([0,0,height/2]) //<- centered for some reason
        spur_gear(
            n=n,m=m,
            z=height,
            pressure_angle=geartype_pressure(gt),
            backlash=backlash,
            add=add, ded=ded, 
            type=type, $fn=$fn,
            chamfer=bevel // degrees
        );
}


