/* Make colored boxes along X (red), Y (green), and Z (blue).
  Default length is 10mm, thickness 2mm
*/

module axes3D(len=10, thick=2) {
	axes=[[1,0,0],[0,1,0],[0,0,1]];
	for (a=axes) color(a*0.8+0.1*[1,1,1]) cube(a*len+thick*[1,1,1]);
}

