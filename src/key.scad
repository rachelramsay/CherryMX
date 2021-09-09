// files
include <constants.scad>
include <functions.scad>
include <shapes.scad>
include <stems.scad>
include <stem_supports.scad>
include <dishes.scad>
include <supports.scad>
include <key_features.scad>

include <libraries/geodesic_sphere.scad>

// for skin hulls
use <libraries/scad-utils/transformations.scad>
use <libraries/scad-utils/lists.scad>
use <libraries/scad-utils/shapes.scad>
use <libraries/skin.scad>

// key shape including dish. used as the ouside and inside shape in hollow_key(). allows for itself to be shrunk in depth and width / height
module shape(thickness_difference, depth_difference=0){
  dished(depth_difference, $inverted_dish) {
    /* %shape_hull(thickness_difference, depth_difference, $inverted_dish ? 2 : 0); */
    color($primary_color) shape_hull(thickness_difference, depth_difference, $inverted_dish ? 2 : 0);
  }
}

// shape of the key but with soft, rounded edges. no longer includes dish
// randomly doesnt work sometimes
// the dish doesn't _quite_ reach as far as it should
module rounded_shape() {
  dished(-$minkowski_radius, $inverted_dish) {
    color($primary_color) minkowski(){
      // half minkowski in the z direction
      color($primary_color) shape_hull($minkowski_radius * 2, $minkowski_radius/2, $inverted_dish ? 2 : 0);
      /* cube($minkowski_radius); */
      sphere(r=$minkowski_radius, $fn=$minkowski_facets);
    }
  }
  /* %envelope(); */
}

// this function is more correct, but takes _forever_
// the main difference is minkowski happens after dishing, meaning the dish is
// also minkowski'd
/* module rounded_shape() {
  color($primary_color) minkowski(){
    // half minkowski in the z direction
    shape($minkowski_radius * 2, $minkowski_radius/2);
    difference(){
      sphere(r=$minkowski_radius, $fn=20);
      translate([0,0,-$minkowski_radius]){
        cube($minkowski_radius * 2, center=true);
      }
    }
  }
} */



// basic key shape, no dish, no inside
// which is only used for dishing to cut the dish off correctly
// $height_difference used for keytop thickness
// extra_slices is a hack to make inverted dishes still work
module shape_hull(thickness_difference, depth_difference, extra_slices = 0){
  render() {
    if ($skin_extrude_shape) {
      skin_extrude_shape_hull(thickness_difference, depth_difference, extra_slices);
    } else if ($linear_extrude_shape) {
      linear_extrude_shape_hull(thickness_difference, depth_difference, extra_slices);
    } else {
      hull_shape_hull(thickness_difference, depth_difference, extra_slices);
    }
  }
}

// use skin() instead of successive hulls. much more correct, and looks faster
// too, in most cases. successive hull relies on overlapping faces which are
// not good. But, skin works on vertex sets instead of shapes, which makes it
// a lot more difficult to use
module skin_extrude_shape_hull(thickness_difference, depth_difference, extra_slices = 0 ) {
  skin([
    for (index = [0:$height_slices + extra_slices])
      let(
        progress = (index / $height_slices),
        skew_this_slice = $top_skew * progress,
        x_skew_this_slice = $top_skew_x * progress,
        depth_this_slice = ($total_depth - depth_difference) * progress,
        tilt_this_slice = -$top_tilt / $key_height * progress,
        y_tilt_this_slice = $double_sculpted ? (-$top_tilt_y / $key_length * progress) : 0
      )
      skin_shape_slice(progress, thickness_difference, skew_this_slice, x_skew_this_slice, depth_this_slice, tilt_this_slice, y_tilt_this_slice)
  ]);
}

function skin_shape_slice(progress, thickness_difference, skew_this_slice, x_skew_this_slice, depth_this_slice, tilt_this_slice, y_tilt_this_slice) =
  transform(
    translation([x_skew_this_slice,skew_this_slice,depth_this_slice]),
    transform(
      rotation([tilt_this_slice,y_tilt_this_slice,0]),
        skin_key_shape([
          total_key_width(0),
          total_key_height(0),
          ],
          [$width_difference, $height_difference],
          progress,
          thickness_difference
        )
    )
  );

// corollary is hull_shape_hull
// extra_slices unused, only to match argument signatures
module linear_extrude_shape_hull(thickness_difference, depth_difference, extra_slices = 0){
  height = $total_depth - depth_difference;
  width_scale = top_total_key_width() / total_key_width();
  height_scale = top_total_key_height() / total_key_height();

  translate([0,$linear_extrude_height_adjustment,0]){
    linear_extrude(height = height, scale = [width_scale, height_scale]) {
        translate([0,-$linear_extrude_height_adjustment,0]){
        key_shape(
          [total_key_width(thickness_difference), total_key_height(thickness_difference)],
          [$width_difference, $height_difference]
        );
      }
    }
  }
}

module hull_shape_hull(thickness_difference, depth_difference, extra_slices = 0) {
  for (index = [0:$height_slices - 1 + extra_slices]) {
    hull() {
      shape_slice(index / $height_slices, thickness_difference, depth_difference);
      shape_slice((index + 1) / $height_slices, thickness_difference, depth_difference);
    }
  }
}

module shape_slice(progress, thickness_difference, depth_difference) {
  skew_this_slice = $top_skew * progress;
  x_skew_this_slice = $top_skew_x * progress;

  depth_this_slice = ($total_depth - depth_difference) * progress;

  tilt_this_slice = -$top_tilt / $key_height * progress;
  y_tilt_this_slice = $double_sculpted ? (-$top_tilt_y / $key_length * progress) : 0;

  translate([x_skew_this_slice, skew_this_slice, depth_this_slice]) {
    rotate([tilt_this_slice,y_tilt_this_slice,0]){
      linear_extrude(height = SMALLEST_POSSIBLE){
        key_shape(
          [
            total_key_width(thickness_difference),
            total_key_height(thickness_difference)
          ],
          [$width_difference, $height_difference],
          progress
        );
      }
    }
  }
}

// for when you want something to only exist inside the keycap.
// used for the support structure
module inside() {
  intersection() {
    shape($wall_thickness, $keytop_thickness);
    children();
  }
}

// for when you want something to only exist outside the keycap
module outside() {
  difference() {
    children();
    shape($wall_thickness, $keytop_thickness);
  }
}

// put something at the top of the key, with no adjustments for dishing
module top_placement(depth_difference=0) {
  top_tilt_by_height = -$top_tilt / $key_height;
  top_tilt_y_by_length = $double_sculpted ? (-$top_tilt_y / $key_length) : 0;

  minkowski_height = $rounded_key ? $minkowski_radius : 0;

  translate([$top_skew_x + $dish_skew_x, $top_skew + $dish_skew_y, $total_depth - depth_difference + minkowski_height/2]){
    rotate([top_tilt_by_height, top_tilt_y_by_length,0]){
      children();
    }
  }
}

module front_placement() {
  // all this math is to take top skew and tilt into account
  // we need to find the new effective height and depth of the top, front lip
  // of the keycap to find the angle so we can rotate things correctly into place
  total_depth_difference = sin(-$top_tilt) * (top_total_key_height()/2);
  total_height_difference = $top_skew + (1 - cos(-$top_tilt)) * (top_total_key_height()/2);

  angle = atan2(($total_depth - total_depth_difference), ($height_difference/2 + total_height_difference));
  hypotenuse = ($total_depth -total_depth_difference) / sin(angle);

  translate([0,-total_key_height()/2,0]) {
    rotate([-(90-angle), 0, 0]) {
      translate([0,0,hypotenuse/2]){
        children();
      }
    }
  }
}

// just to DRY up the code
module _dish() {
  translate([$dish_offset_x,0,0]) dish(top_total_key_width() + $dish_overdraw_width, top_total_key_height() + $dish_overdraw_height, $dish_depth, $inverted_dish);
}

module envelope(depth_difference=0) {
  s = 1.5;
  hull(){
    cube([total_key_width() * s, total_key_height() * s, $zero], center = true);
    top_placement(SMALLEST_POSSIBLE + depth_difference){
      cube([top_total_key_width() * s, top_total_key_height() * s, $zero], center = true);
    }
  }
}

// I think this is unused
module dished_for_show() {
  difference(){
    union() {
      envelope();
      if ($inverted_dish) top_placement(0) color($secondary_color) _dish();
    }
    if (!$inverted_dish) top_placement(0) color($secondary_color) _dish();
  }
}


// for when you want to take the dish out of things
// used for adding the dish to the key shape and making sure stems don't stick out the top
// creates a bounding box 1.5 times larger in width and height than the keycap.
module dished(depth_difference = 0, inverted = false) {
  intersection() {
    children();
    difference(){
      union() {
        envelope(depth_difference);
        if (inverted) top_placement(depth_difference) color($secondary_color) _dish();
      }
      if (!inverted) top_placement(depth_difference) color($secondary_color) _dish();
      /* %top_placement(depth_difference) _dish(); */
    }
  }
}

// puts it's children at the center of the dishing on the key, including dish height
// more user-friendly than top_placement
module top_of_key(){
  // if there is a dish, we need to account for how much it digs into the top
  dish_depth = ($dish_type == "disable") ? 0 : $dish_depth;
  // if the dish is inverted, we need to account for that too. in this case we do half, otherwise the children would be floating on top of the dish
  corrected_dish_depth = ($inverted_dish) ? -dish_depth / 2 : dish_depth;

  top_placement(corrected_dish_depth) {
    children();
  }
}

module keytext(text, position, font_size, depth) {
  woffset = (top_total_key_width()/3.5) * position[0];
  hoffset = (top_total_key_height()/3.5) * -position[1];
  translate([woffset, hoffset, -depth]){
    color($tertiary_color) linear_extrude(height=$dish_depth){
      text(text=text, font=$font, size=font_size, halign="center", valign="center");
    }
  }
}

module keystem_positions(positions) {
  for (connector_pos = positions) {
    translate(connector_pos) {
      rotate([0, 0, $stem_rotation]){
        children();
      }
    }
  }
}

module support_for(positions, stem_type) {
  keystem_positions(positions) {
    color($tertiary_color) supports($support_type, stem_type, $stem_throw, $total_depth - $stem_throw);
  }
}

module stems_for(positions, stem_type) {
  keystem_positions(positions) {
    color($tertiary_color) stem(stem_type, $total_depth, $stem_slop, $stem_throw);
    if ($stem_support_type != "disable") {
      color($quaternary_color) stem_support($stem_support_type, stem_type, $stem_support_height, $stem_slop);
    }
  }
}

// a fake cherry keyswitch, abstracted out to maybe replace with a better one later
module cherry_keyswitch() {
  union() {
    hull() {
      cube([15.6, 15.6, $zero], center=true);
      translate([0,1,5 - $zero]) cube([10.5,9.5, $zero], center=true);
    }
    hull() {
      cube([15.6, 15.6, $zero], center=true);
      translate([0,0,-5.5]) cube([13.5,13.5,$zero], center=true);
    }
  }
}

//approximate (fully depressed) cherry key to check clearances
module clearance_check() {
  if($stem_type == "cherry" || $stem_type == "cherry_rounded"){
    color($warning_color){
      translate([0,0,3.6 + $stem_inset - 5]) {
        cherry_keyswitch();
      }
    }
  }
}

module legends(depth=0) {
  if (len($front_legends) > 0) {
    front_placement() {
      if (len($front_legends) > 0) {
        for (i=[0:len($front_legends)-1]) {
          rotate([90,0,0]) keytext($front_legends[i][0], $front_legends[i][1], $front_legends[i][2], depth);
  		  }
	    }
    }
  }
  if (len($legends) > 0) {
    top_of_key() {
      // outset legend
      if (len($legends) > 0) {
        for (i=[0:len($legends)-1]) {
          keytext($legends[i][0], $legends[i][1], $legends[i][2], depth);
        }
      }
    }
  }
}

// legends / artisan support
module artisan(depth) {
  top_of_key() {
    // artisan objects / outset shape legends
    color($secondary_color) children();
  }
}

// key with hollowed inside but no stem
module hollow_key() {
  difference(){
    if ($rounded_key) {
      rounded_shape();
    } else {
      shape(0, 0);
    }
    // translation purely for aesthetic purposes, to get rid of that awful lattice
    translate([0,0,-SMALLEST_POSSIBLE]) {
      shape($wall_thickness, $keytop_thickness);
    }
  }
}


// The final, penultimate key generation function.
// takes all the bits and glues them together. requires configuration with special variables.
module key(inset = false) {
  difference() {
    union(){
      // the shape of the key, inside and out
      hollow_key();
      if($key_bump) top_of_key() keybump($key_bump_depth, $key_bump_edge);
      // additive objects at the top of the key
      // outside() makes them stay out of the inside. it's a bad name
      if(!inset && $children > 0) outside() artisan(0) children();
      if($outset_legends) legends(0);
      // render the clearance check if it's enabled, but don't have it intersect with anything
      if ($clearance_check) %clearance_check();
    }

    // subtractive objects at the top of the key
    // no outside() - I can't think of a use for it. will save render time
    if (inset && $children > 0) artisan($inset_legend_depth) children();
    if(!$outset_legends) legends($inset_legend_depth);
    // subtract the clearance check if it's enabled, letting the user see the
    // parts of the keycap that will hit the cherry switch
    if ($clearance_check) %clearance_check();
  }

  // both stem and support are optional
  if ($stem_type != "disable" || ($stabilizers != [] && $stabilizer_type != "disable")) {
    dished($keytop_thickness, $inverted_dish) {
      translate([0, 0, $stem_inset]) {
        if ($stabilizer_type != "disable") stems_for($stabilizers, $stabilizer_type);

        if ($stem_type != "disable") stems_for($stem_positions, $stem_type);
      }
    }
  }

  if ($support_type != "disable"){
    inside() {
      translate([0, 0, $stem_inset]) {
        if ($stabilizer_type != "disable") support_for($stabilizers, $stabilizer_type);

        // always render stem support even if there isn't a stem.
        // rendering flat support w/no stem is much more common than a hollow keycap
        // so if you want a hollow keycap you'll have to turn support off entirely
        support_for($stem_positions, $stem_type);
      }
    }
  }
}

// actual full key with space carved out and keystem/stabilizer connectors
// this is an example key with all the fixins from settings.scad
module example_key(){
  include <settings.scad>
  key();
}

if (!$using_customizer) {
  example_key();
}
