$fn = 64;
part = "base"; // base, lid, tray_pi, tray_radxa, blank_long, blank_short

// --- Main envelope parameters (millimeters) ---
wall_thickness = 2.4;
floor_thickness = 2.6;
inner_length = 96;   // X direction, sized to swallow Pi 4B with room for cable strain relief
inner_width  = 64;   // Y direction
inner_height = 27;   // Z clearance from floor to underside of lid

// Lid and screw interface
lid_thickness = 3;
screw_hole_diameter = 2.7; // clearance for M2.5
screw_head_diameter = 5.3; // pan head recess
screw_post_offset = 9;     // distance of corner posts from interior walls

// Tray and adapter settings
tray_clearance = 0.6;   // overall play between tray and interior walls
tray_thickness = 2.6;
standoff_outer_diameter = 7;
standoff_height = 6;
radxa_edge_rails = 4;   // height of Radxa Zero edge clamps

// Port window geometry
slot_bottom = 6;        // from outside floor to bottom of window
slot_height = 18;
long_slot_length = 78;
short_slot_length = 42;

// Convenience derived numbers
outer_length = inner_length + 2 * wall_thickness;
outer_width  = inner_width  + 2 * wall_thickness;
outer_height = inner_height + floor_thickness;

tray_length = inner_length - tray_clearance;
tray_width  = inner_width  - tray_clearance;
tab_reach   = tray_clearance; // amount tabs extend to touch south/west walls

// --- Public modules --------------------------------------------------------

/*
 * dual_case_base():
 *   Bottom half of the enclosure. Includes generous side windows so either
 *   board's IO can reach the outside, and four corner screw posts for a
 *   captive lid.
 */
module dual_case_base() {
    difference() {
        cube([outer_length, outer_width, outer_height], false);
        translate([wall_thickness, wall_thickness, floor_thickness])
            cube([inner_length, inner_width, inner_height + 0.1], false);
        carve_side_windows();
    }

    // Add floor pads for the feet
    for (pad = base_feet()) {
        translate([pad[0], pad[1], 0])
            cylinder(h = 1.2, r = 7/2);
    }

    // Corner screw posts
    for (p = screw_post_positions()) {
        translate(p)
            screw_post(outer_height, standoff_outer_diameter, screw_hole_diameter);
    }
}

/*
 * dual_case_lid():
 *   Flat lid that keys off the four posts in the base. The screw heads sit
 *   inside shallow counterbores to keep the exterior flush.
 */
module dual_case_lid() {
    difference() {
        cube([outer_length, outer_width, lid_thickness], false);
        translate([wall_thickness + 1.5, wall_thickness + 1.5, 0.6])
            cube([inner_length - 3, inner_width - 3, lid_thickness], false);
        for (p = screw_post_positions()) {
            translate([p[0], p[1], -0.1])
                cylinder(h = lid_thickness + 0.2, r = screw_hole_diameter / 2);
            translate([p[0], p[1], 0])
                cylinder(h = 1.5, r = screw_head_diameter / 2);
        }
    }
}

/*
 * board_tray(board_type = "pi"):
 *   Removable insert that carries the mounting pattern and keeps each board
 *   registered relative to the case windows. Print one for Raspberry Pi 4B
 *   and one for Radxa Zero.
 */
module board_tray(board_type = "pi") {
    difference() {
        tray_blank();
        // relieve the interior to save material
        translate([2, 2, 0])
            cube([tray_length - 4, tray_width - 4, tray_thickness], false);

        // clearance pockets for the four base posts
        for (p = tray_post_pockets()) {
            translate([p[0], p[1], -0.1])
                cylinder(h = tray_thickness + 0.2, r = standoff_outer_diameter);
        }
    }

    // L-shaped location tabs (south/west) to precisely seat against the base walls
    translate([-tab_reach, 0, 0])
        cube([tab_reach, 14, tray_thickness], false);
    translate([0, -tab_reach, 0])
        cube([14, tab_reach, tray_thickness], false);

    // Add board-specific standoffs and keep-outs
    board_mounts = board_mount_pattern(board_type);
    board_size = board_outline(board_type);
    offset = board_offsets(board_type);

    for (pt = board_mounts) {
        translate([offset[0] + pt[0], offset[1] + pt[1], tray_thickness])
            standoff(standoff_height, screw_hole_diameter);
    }

    if (board_type == "pi") {
        // Cable pocket for the 40-pin header ribbon and display connector
        translate([offset[0] + board_size[0] - 10, offset[1] + board_size[1]/2 - 8, 0])
            cube([12, 16, tray_thickness], false);
    } else if (board_type == "radxa") {
        // Edge rails gently clamp the skinny Radxa Zero so it cannot drift
        translate([offset[0] - 1, offset[1], tray_thickness])
            cube([1.2, board_size[1], radxa_edge_rails], false);
        translate([offset[0] + board_size[0] - 0.2, offset[1], tray_thickness])
            cube([1.2, board_size[1], radxa_edge_rails], false);

        // Relief for the Wi-Fi antenna end
        translate([offset[0] + board_size[0] - 6, offset[1] - 1.5, 0])
            cube([6, board_size[1] + 3, tray_thickness], false);
    }
}

/*
 * port_blank(side = "long"):
 *   Optional snap-in blank for any unused IO window. Print side-specific
 *   blanks to close off airflow when a board does not expose connectors
 *   there.
 */
module port_blank(side = "long") {
    if (side == "long") {
        cube([long_slot_length, wall_thickness, slot_height], false);
    } else {
        cube([short_slot_length, wall_thickness, slot_height], false);
    }
}

// --- Helper geometry -------------------------------------------------------

module screw_post(height, outer_d, hole_d) {
    difference() {
        cylinder(h = height, r = outer_d / 2);
        translate([0, 0, -0.2])
            cylinder(h = height + 0.4, r = hole_d / 2);
    }
}

module standoff(height, hole_d) {
    difference() {
        cylinder(h = height, r = standoff_outer_diameter / 2);
        translate([0, 0, -0.2])
            cylinder(h = height + 0.4, r = hole_d / 2);
    }
}

module tray_blank() {
    cube([tray_length, tray_width, tray_thickness], false);
}

function board_outline(board_type) =
    board_type == "pi" ? [85, 56, 18] :
    board_type == "radxa" ? [66, 30, 9] :
    [0, 0, 0];

function board_mount_pattern(board_type) =
    board_type == "pi" ? [
        [3.5, 3.5], [3.5, 52.5], [61.5, 3.5], [61.5, 52.5]
    ] :
    board_type == "radxa" ? [
        [3.5, 3.5], [3.5, 26.5], [62.5, 3.5], [62.5, 26.5]
    ] : [];

function board_offsets(board_type) =
    board_type == "pi" ? [
        (tray_length - board_outline("pi")[0]) / 2,
        (tray_width  - board_outline("pi")[1]) / 2
    ] :
    board_type == "radxa" ? [
        (tray_length - board_outline("radxa")[0]) / 2,
        (tray_width  - board_outline("radxa")[1]) / 2
    ] : [0, 0];

function screw_post_positions() = [
    [wall_thickness + screw_post_offset, wall_thickness + screw_post_offset, 0],
    [wall_thickness + inner_length - screw_post_offset, wall_thickness + screw_post_offset, 0],
    [wall_thickness + screw_post_offset, wall_thickness + inner_width - screw_post_offset, 0],
    [wall_thickness + inner_length - screw_post_offset, wall_thickness + inner_width - screw_post_offset, 0]
];

function tray_post_pockets() = [
    [screw_post_offset, screw_post_offset],
    [tray_length - screw_post_offset, screw_post_offset],
    [screw_post_offset, tray_width - screw_post_offset],
    [tray_length - screw_post_offset, tray_width - screw_post_offset]
];

function base_feet() = [
    [16, 16],
    [outer_length - 16, 16],
    [16, outer_width - 16],
    [outer_length - 16, outer_width - 16]
];

module carve_side_windows() {
    window_z = floor_thickness + slot_bottom;

    // north (+Y) long slot
    translate([(outer_length - long_slot_length)/2, outer_width - wall_thickness - 0.2, window_z])
        cube([long_slot_length, wall_thickness + 0.4, slot_height], false);
    // south (-Y) long slot
    translate([(outer_length - long_slot_length)/2, -0.2, window_z])
        cube([long_slot_length, wall_thickness + 0.4, slot_height], false);
    // east (+X) short slot
    translate([outer_length - wall_thickness - 0.2, (outer_width - short_slot_length)/2, window_z])
        cube([wall_thickness + 0.4, short_slot_length, slot_height], false);
    // west (-X) short slot
    translate([-0.2, (outer_width - short_slot_length)/2, window_z])
        cube([wall_thickness + 0.4, short_slot_length, slot_height], false);
}

if (part == "base") {
    dual_case_base();
} else if (part == "lid") {
    dual_case_lid();
} else if (part == "tray_pi") {
    board_tray("pi");
} else if (part == "tray_radxa") {
    board_tray("radxa");
} else if (part == "blank_long") {
    port_blank("long");
} else if (part == "blank_short") {
    port_blank("short");
}
