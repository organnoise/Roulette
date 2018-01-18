Preset preset;

"kick" => preset.name;

string names[];

//<<< preset.getPresets().cap() >>>;

preset.getPresets() @=> names;

for(int i; i < names.size(); i++){
<<< names[i]>>>;
}