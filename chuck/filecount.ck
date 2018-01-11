// instantiate
FileIO fio;
//Store number of presets already made
int presetCount;
//dir name for saving preset, default name is "other"
"other" => string name;

int seq[16][4];

save(seq);
load(1);

fun void load(int presetNum){
    
    cherr <= "Loading preset_" <= presetNum <= " ...\n";
    cherr <= "Current:\n";
    
    cherr <= printStatus() <= "\n";
    
    // default file
    me.sourceDir() + "/presets" + name +"/preset_" + Std.itoa(presetNum) + ".txt"=> string filename;
    
    // open a file
    fio.open( filename, FileIO.READ );
    
    // ensure it's ok
    if( !fio.good() )
    {
        cherr <= "can't open file: " <= filename <= " for reading..."
        <= IO.newline();
        me.exit();
    }
    
    int val;
    int vals[0];
    // loop until end
    while( fio => val )
    {
        val<= Std.atoi( IO.newline());
        //push val to vals[]
        vals << val;
    }
    
    //push vals[] into seq
    int j;
    
    for(int i; i < vals.size(); i++){
        vals[i] => seq[j][i % 4];
        //increment j after every 4 vals  
        if(i % 4 == 3 && i != vals.size()) j++;
    }
    
    cherr <= "Loaded: preset_" <= Std.itoa(presetNum) <= ".txt";
    cherr <= printStatus() <= "\n";
}

//load by specific filename
fun void load(string presetName){
    
    cherr <= "Loading preset_" <= presetNum <= " ...\n";
    cherr <= "Current:\n";
    
    cherr <= printStatus() <= "\n";
    
    // default file
    me.sourceDir() + "/presets" + name +"/" + presetName + ".txt"=> string filename;
    
    // open a file
    fio.open( filename, FileIO.READ );
    
    // ensure it's ok
    if( !fio.good() )
    {
        cherr <= "can't open file: " <= filename <= " for reading..."
        <= IO.newline();
        me.exit();
    }
    
    int val;
    int vals[0];
    // loop until end
    while( fio => val )
    {
        val<= Std.atoi( IO.newline());
        //push val to vals[]
        vals << val;
    }
    
    //push vals[] into seq
    int j;
    
    for(int i; i < vals.size(); i++){
        vals[i] => seq[j][i % 4];
        //increment j after every 4 vals  
        if(i % 4 == 3 && i != vals.size()) j++;
    }
    
    cherr <= "Loaded:" <= presetName <= ".txt\n";
    cherr <= printStatus() <= "\n";
}

//save a preset by passing a two-dimensional array to it
fun void save(int seq[][]){
    countPresets() => presetCount;
    
    // open for write
    fio.open( me.sourceDir() + "presets/" + name + "/preset_"+ Std.itoa(presetCount + 1) + ".txt", FileIO.WRITE );
    
    // test
    if( !fio.good() )
    {
        cherr <= "can't open file for writing..." <= IO.newline();
        me.exit();
    }
    
    // write some stuff
    for (int i; i < seq.size(); i++){
        for (int j; j < seq[0].size(); j++){
            fio.write( seq[i][j]);
            fio.write("\n");
        }
    }
    
    cherr <= "Saved as 'preset_" <= Std.itoa(presetCount + 1) <= ".txt" ;
    // close the thing
    fio.close();
}

fun int countPresets(){
    //Temp file for storing the number of presets
    // using . format to hide file from finder
    ".count.txt" => string file;
    
    // default file
    me.sourceDir() + file => string filename;
    
    Std.system("ls -l ./presets/preset_*.txt | wc -l | tr -d [:space:] >" + file + "&& echo -e '\n' >> " + file);
    // open a file
    fio.open( filename, FileIO.READ );
    
    // ensure it's ok
    if( !fio.good() )
    {
        cherr <= "can't open file: " <= filename <= " for reading..."
        <= IO.newline();
        me.exit();
    }
    
    int val;
    
    // loop until end
    while( fio => val )
    {
        cherr <= val <= IO.newline();
        val => presetCount;
        Std.system("rm " + file);   
    }
    return presetCount;
}

fun string printStatus(){
    
    string presetStatus;
    
    "[\n" => presetStatus;
    
    for(int i; i < seq.size(); i++){
        "[" +=> presetStatus;
        for(int j; j < seq[0].size(); j++){
            Std.itoa(seq[i][j]) +=> presetStatus;
            if(j < seq[0].size() - 1) "," +=> presetStatus;
        }
        "]" +=> presetStatus;
        
        if (i < seq.size() - 1) {
            "," +=> presetStatus;
            if (i % 4 == 3 && i != 0) "\n" +=> presetStatus;
        }
    }
    "\n]" +=> presetStatus;
    
    return presetStatus;
    
}
//set the name of the directory to save presets
//base use-case is to set it to the name of the drum
fun void setFolder(string folder){
    folder => name;
    }