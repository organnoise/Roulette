40 => int Tempo;

dur whl, hlf, qtr, eth, sth, tsnd, sfth;
//Dotted and triplet
1.5 => float dot; 
1.0/3.0 => float trip;

measure(Tempo);

SndBuf click => dac;
SndBuf inst => dac;

load(click, "hihat_01.wav");
load(inst,"kick_01.wav");

click.gain(0.2);
click.rate(1.5); 

0 => int launch;
[4,4,3,7] @=> int array[];
spork~ metro();

while(true){
    
    for(0 => int i; i < array.size(); i++){
        stepper(array[i]);
    }
}



//Metro
fun void metro(){
    while(true){
        0 => click.pos;
        sth => now;
    }
}
//Seq
fun void seq(){
    while(true){
        for(0 => int i; i < array.size(); i++){
            stepper(array[i]);
        }
        
    }
}

//Stepper
fun void stepper(int hitPoint){
    //On launch start sequence from middle
    if(launch == 0){
        1 => launch;
        step(hitPoint, 4);
        }
    //Otherwise start as a typical for loop would start    
    else step(hitPoint, 0);
    
    
}

//Step

//*essentially this is micro sequencing
//*that allows the "Slugging" timing effect
fun void step(int hit, int launchPoint){
    //"launch point" is used as a strange solution to allow the 
    // time displacement effect
    for(launchPoint => int i; i < 10; i ++){
        //If a hit occurs...
        if(hit == i){
            0 => inst.pos;
        }
        sth/10 => now;
    }
}


fun string load ( SndBuf inst, string filename )

{
    me.dir() + "/audio/" + filename => inst.read;
    inst.samples() => inst.pos;
    return <<< "Loaded ", filename  >>>; 
}

fun void measure(float bpm){
    //Note division math
    60000/bpm => float SPB;
    SPB::ms => qtr;
    qtr*2 =>  hlf;
    hlf*2 =>  whl;
    qtr*0.5 =>  eth;
    eth*0.5 =>  sth;
    sth*0.5 =>  tsnd;
    tsnd*0.5 =>  sfth;   
}