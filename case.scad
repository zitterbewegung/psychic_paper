// Device dimensions (adjust as necessary)
device_width = 94;
device_height = 67;
device_thickness = 10;

// Case parameters
wall_thickness = 3;
lip_height = 2;
tolerance = 0.5;

// Lanyard loop dimensions
loop_width = 10;
loop_height = 5;
loop_thickness = 3;

// GPIO cutout dimensions
gpio_cutout_width = 54;     // Slightly wider than the header for clearance
gpio_cutout_height = 10;    // Enough to accommodate the header height
gpio_cutout_depth = device_thickness + wall_thickness; // Cut through the back cover

// GPIO cutout position (relative to the back cover)
gpio_cutout_x = (device_width + 2*wall_thickness - gpio_cutout_width) / 2; // Centered horizontally
gpio_cutout_y = device_height + wall_thickness - gpio_cutout_height;       // Positioned at the top


module front_frame() {
    difference() {
        // Outer frame
        cube([device_width + 2*wall_thickness, device_height + 2*wall_thickness, wall_thickness]);
        // Inner cutout for screen
        translate([wall_thickness, wall_thickness, -1])
            cube([device_width, device_height, wall_thickness + 2]);
    }
    // Inner lip to hold the device
    translate([wall_thickness, wall_thickness, wall_thickness])
        cube([device_width, device_height, lip_height]);
}
module back_cover() {
    // Main cover
    translate([0, 0, wall_thickness + lip_height])
        cube([device_width + 2*wall_thickness, device_height + 2*wall_thickness, device_thickness + wall_thickness]);

    // Lanyard loop
    translate([(device_width + 2*wall_thickness - loop_width)/2, -loop_thickness, wall_thickness + lip_height + (device_thickness + wall_thickness)/2 - loop_height/2])
        cube([loop_width, loop_thickness, loop_height]);
}

module back_cover() {
    // Main cover
    translate([0, 0, wall_thickness + lip_height])
        cube([device_width + 2*wall_thickness, device_height + 2*wall_thickness, device_thickness + wall_thickness]);

    // Lanyard loop
    translate([(device_width + 2*wall_thickness - loop_width)/2, -loop_thickness, wall_thickness + lip_height + (device_thickness + wall_thickness)/2 - loop_height/2])
        cube([loop_width, loop_thickness, loop_height]);

    // GPIO cutout
    difference() {
        // Existing back cover
        translate([0, 0, wall_thickness + lip_height])
            cube([device_width + 2*wall_thickness, device_height + 2*wall_thickness, device_thickness + wall_thickness]);
        // Cutout for GPIO header
        translate([gpio_cutout_x, gpio_cutout_y, wall_thickness + lip_height - 1])  // Slightly offset in Z to ensure a clean cut
            cube([gpio_cutout_width, gpio_cutout_height, gpio_cutout_depth + 2]);
    }
}

front_frame();
back_cover();

