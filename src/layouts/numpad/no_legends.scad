include <../layout.scad>

/* The Plus and Enter keys will need to be added manually to the keys.scad file
Copy and paste the following two lines into keys.scad to add plus and enter, changing 'LAYOUT_ROW' to your chosen layout

translate_u(x=3.5, y=-1.5, z=0) LAYOUT_ROW(1) numpad_plus() key();
translate_u(x=3.5, y=-3.5, z=0) LAYOUT_ROW(3) numpad_enter() key();

Make sure you comment out/delete the 10u keys and their associated legends before exporting keys.
*/

numpad_no_legends_layout = [
  [1,1,1,1],
  [1,1,1,],
  [1,1,1],
  [1,1,1],
  [2,1],
  [],
  [10],
  [10]
];

numpad_legends = [
  [],
  [],
  [],
  [],
  [],
  [],
  ["CHECK NUMPAD_NO_LEGENDS LAYOUT FILE"],
  ["TO ADD NUMPAD PLUS AND ENTER"]
];
module numpad_no_legends(profile) {
  layout(numpad_default_layout, profile, numpad_legends) children();
}