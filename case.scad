// ==================================================
// Inky Impression 4" Lanyard Case with GPIO Cutout,
// Display Window, and Button Cutouts
// ==================================================
//
// Description:
// A 3D-printed case designed to house the Inky Impression 4" e-paper display.
// Features include a lanyard loop, GPIO cutout for Raspberry Pi HAT connector,
// a transparent display window, and button cutouts.
//
// Author: ChatGPT / zitterbewegung
// Date: 2024-04-27
// ==================================================

// -------------------
// Parameters Section
// -------------------

// Device dimensions (in millimeters)
// Please verify and adjust these dimensions according to your specific device
device_width = 94;       // Width of the Inky Impression
device_height = 67;      // Height of the Inky Impression
device_thickness = 10;   // Thickness of the Inky Impression (including components)

// Case parameters
wall_thickness = 3;      // Thickness of the case walls
lip_height = 2;          // Height of the inner lip to hold the device
tolerance = 0.5;         // General tolerance for fit

// Lanyard loop dimensions
loop_width = 10;         // Width of the lanyard loop
loop_height = 5;         // Height of the lanyard loop
loop_thickness = 3;      // Thickness of the lanyard loop

// GPIO cutout dimensions
gpio_cutout_width = 54;      // Width of the GPIO cutout (slightly wider than the header)
gpio_cutout_height = 10;     // Height of the GPIO cutout
gpio_cutout_depth = device_thickness + wall_thickness; // Depth of the cutout

// GPIO cutout position (relative to the back cover)
gpio_cutout_x = (device_width + 2 * wall_thickness - gpio_cutout_width) / 2; // Centered horizontally
gpio_cutout_y = device_height + wall_thickness - gpio_cutout_height;       // Positioned near the top

// Display window parameters
window_margin = 1;              // Margin around the display opening for the window
window_thickness = 1.5;         // Thickness of the display window
window_material_overhang = 0.5; // Overhang for the window to snap or clip into place

// Button cutout parameters
// Define each button's position and size
// Adjust these based on your device's button layout
button_count = 3; // Number of buttons

// Example positions (relative to the front of the device)
// Modify these values to match your device's button layout
button_positions = [
    [20, 5],   // Button 1: [x, y] from the bottom-left corner
    [47, 5],   // Button 2
    [74, 5]    // Button 3
];

button_radius = 3;    // Radius of the circular button cutouts
button_height = wall_thickness + 0.2; // Slightly taller than wall to ensure clearance

// =======================
// Modules Definition
// =======================

// Front Frame Module with Display Window Slot and Button Cutouts
module front_frame() {
    difference() {
        // Outer frame
        cube([device_width + 2 * wall_thickness, device_height + 2 * wall_thickness, wall_thickness], center=false);
        
        // Inner cutout for the display
        translate([wall_thickness, wall_thickness, -1])
            cube([device_width, device_height, wall_thickness + 2]);
        
        // Button cutouts
        for (i = [0 : button_count - 1]) {
            translate([
                wall_thickness + button_positions[i][0] - button_radius,
                wall_thickness + button_positions[i][1] - button_radius,
                0
            ])
                cylinder(h = button_height, r = button_radius, $fn=100);
        }
    }
    
    // Inner lip to hold the device
    translate([wall_thickness, wall_thickness, wall_thickness])
        cube([device_width, device_height, lip_height]);
    
    // Display window slot
    translate([wall_thickness + window_margin, wall_thickness + window_margin, wall_thickness - 0.1])
        cube([device_width - 2 * window_margin, device_height - 2 * window_margin, wall_thickness + 0.2]);
}

// Back Cover Module with GPIO Cutout
module back_cover() {
    difference() {
        // Main back cover
        cube([device_width + 2 * wall_thickness, device_height + 2 * wall_thickness, device_thickness + wall_thickness], center=false);
        
        // Lanyard loop
        translate([(device_width + 2 * wall_thickness - loop_width) / 2, -loop_thickness, (device_thickness + wall_thickness) / 2 - loop_height / 2])
            cube([loop_width, loop_thickness, loop_height], center=false);
        
        // GPIO cutout
        translate([gpio_cutout_x, gpio_cutout_y, wall_thickness + lip_height - 1]) // Slight offset in Z for clean cut
            cube([gpio_cutout_width, gpio_cutout_height, gpio_cutout_depth + 2], center=false);
    }
}

// Display Window Module
module display_window() {
    // This module is for reference and should be printed separately or cut from a transparent sheet
    // If printing as part of the case, ensure the material is transparent
    // For best results, use a separate acrylic sheet inserted into the slot
    difference() {
        // Outer window piece
        cube([device_width - 2 * window_margin + 2 * window_material_overhang, 
              device_height - 2 * window_margin + 2 * window_material_overhang, 
              window_thickness], center=false);
        
        // Hole for window mounting (if using clips)
        // Customize based on your mounting method
    }
}

// =======================
// Assembly Section
// =======================

module assemble_case() {
    // Front Frame with Display Window Slot and Button Cutouts
    front_frame();
    
    // Back Cover with GPIO Cutout
    back_cover();
    
    // Uncomment the following line to include a hinged display window (requires additional design)
    // hinge_front_frame();
}

// Render the assembled case
assemble_case();

// =======================
// Optional: Customization
// =======================

// Uncomment the following lines to add text or logos to the case
/*
module add_text() {
    translate([wall_thickness, device_height + wall_thickness + 5, wall_thickness + lip_height + 1])
        linear_extrude(height=2)
            text("Inky Impression", size=10, valign="center", halign="center");
}

add_text();
*/

// =======================
// End of File
// =======================
