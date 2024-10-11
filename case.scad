// ==================================================
// Inky Impression 4" Lanyard Case with GPIO Cutout,
// Display Window, Button Cutouts, Lanyard Loop, and RFID Card Clips
// ==================================================
//
// Description:
// A 3D-printed case designed to house the Inky Impression 4" e-paper display.
// Features include a lanyard loop at the top, GPIO cutout for Raspberry Pi HAT connector,
// a transparent display window, button cutouts, and clips for holding an RFID ID card.
//
// Author: ChatGPT
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
wall_thickness = 1.5;    // Reduced thickness of the case walls
lip_height = 2;           // Height of the inner lip to hold the device
tolerance = 0.5;          // General tolerance for fit

// Lanyard loop dimensions
loop_width = 15;          // Width of the lanyard loop (increased for strength)
loop_height = 10;         // Height of the lanyard loop
loop_thickness = 5;       // Thickness of the lanyard loop (increased for strength)

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
button_count = 3; // Number of buttons to create cutouts for
button_positions = [ // Button positions (relative to the bottom-left corner)
    [10, 50],   // Button 1
    [40, 50],   // Button 2
    [70, 50]    // Button 3
];

button_radius = 3;    // Radius of the circular button cutouts
button_height = wall_thickness + 0.2; // Slightly taller than wall to ensure clearance

// RFID ID Card Clip Parameters
clip_height = 5;      // Height of the clip
clip_thickness = 1.5; // Thickness of the clip
clip_length = 15;     // Length of the clip (how far it extends)
card_thickness = 0.8; // Thickness of the RFID card (standard is around 0.76mm)

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
        
        // Display window slot
        translate([wall_thickness + window_margin, wall_thickness + window_margin, wall_thickness - 0.1])
            cube([device_width - 2 * window_margin, device_height - 2 * window_margin, wall_thickness + 0.2]);
    }
    
    // Inner lip to hold the device
    translate([wall_thickness, wall_thickness, wall_thickness])
        cube([device_width, device_height, lip_height]);
}

// Back Cover Module with GPIO Cutout, Lanyard Loop, and RFID Card Clips
module back_cover() {
    difference() {
        // Main back cover
        cube([device_width + 2 * wall_thickness, device_height + 2 * wall_thickness, device_thickness + wall_thickness], center=false);
        
        // GPIO cutout
        translate([gpio_cutout_x, gpio_cutout_y, wall_thickness + lip_height - 1]) // Slight offset in Z for clean cut
            cube([gpio_cutout_width, gpio_cutout_height, gpio_cutout_depth + 2], center=false);
        
        // Lanyard loop at the top
        translate([(device_width + 2 * wall_thickness - loop_width) / 2, device_height + wall_thickness, device_thickness])
            cube([loop_width, loop_thickness, loop_height], center=false);

        // RFID Card Clips (two clips)
        translate([(device_width + 2 * wall_thickness - clip_length) / 2, -clip_thickness, device_thickness + wall_thickness - card_thickness])
            cube([clip_length, clip_thickness, clip_height], center=false); // Clip 1
        translate([(device_width + 2 * wall_thickness - clip_length) / 2, (clip_thickness + 1), device_thickness + wall_thickness - card_thickness])
            cube([clip_length, clip_thickness, clip_height], center=false); // Clip 2
    }
}

// =======================
// Assembly Section
// =======================

module assemble_case() {
    // Front Frame with Display Window Slot and Button Cutouts
    front_frame();
    
    // Back Cover with GPIO Cutout, Lanyard Loop, and RFID Card Clips
    back_cover();
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
