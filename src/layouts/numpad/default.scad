include <../layout.scad>

/* The Plus and Enter keys will need to be added manually to the keys.scad file
Copy and paste the following two lines into keys.scad to add plus and enter, changing 'LAYOUT_ROW' to your chosen layout

translate_u(x=3.5, y=-1.5, z=0) LAYOUT_ROW(1) legend("+", size=6) numpad_plus() key();
translate_u(x=3.5, y=-3.5, z=0) LAYOUT_ROW(3) legend("⏎", size=6) numpad_enter() key();

Make sure you comment out/delete the 10u keys and their associated legends before exporting keys.
*/

numpad_default_layout = [
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
  ["№", "/", "*", "-"],
  ["7", "8", "9"],
  ["4", "5", "6"],
  ["1", "2", "3"],
  ["0", "."],
  [],
  ["CHECK NUMPAD_DEFAULT LAYOUT FILE"],
  ["TO ADD NUMPAD PLUS AND ENTER"]
];
module numpad_default(profile) {
  layout(numpad_default_layout, profile, numpad_legends) children();
}