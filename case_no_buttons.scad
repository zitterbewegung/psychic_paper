// -------------------
// Parameters
// -------------------
original_width = 97;          // Original width in mm
extension_width = 20;         // Extension width in mm
total_width = original_width + extension_width; // Total width after extension: 117 mm
case_height = 70;             // Height in mm
case_depth = 5;              // Depth in mm
wall_thickness = 2;           // Wall thickness in mm

// Screen Opening Parameters
screen_width = original_width - 2 * wall_thickness; // 93 mm
screen_height = 65;           // Screen height in mm
screen_thickness = 1;         // Screen opening depth in mm

// Badge Mount Hole Parameters
badge_mount_diameter = 6;     // Diameter of the badge mount hole in mm

// Lanyard Hole Parameters
lanyard_hole_diameter = 5;    // Diameter of the lanyard hole in mm
lanyard_hole_offset = total_width / 2;       // Offset from the top edge in mm

// -------------------
// Main Case Design
// -------------------
module plastic_case() {
    difference() {
        // Outer Shell: Main Case + Extension
        cube([total_width, case_height, case_depth], center=false);
        
        // Inner Cavity: Hollow out the main case (excluding extension)
        translate([wall_thickness, wall_thickness, wall_thickness])
            cube([original_width, case_height - 2 * wall_thickness, case_depth - 2 * wall_thickness]);
        
        // Screen Opening on the Front Face
        translate([wall_thickness, wall_thickness, 0])
            cube([screen_width, screen_height, screen_thickness]);
        
        // Badge Mount Hole on the Extension Side (Front Extension)
        translate([original_width + (extension_width / 2), case_height / 2, case_depth / 2])
            rotate([90, 0, 0]) // Rotate to align the hole with the front face
            cylinder(h = case_depth + 1, d = badge_mount_diameter, center=true);

    }
}

// -------------------
// Render the Case
// -------------------
plastic_case();
