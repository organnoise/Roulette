80 => int Tempo;

dur whl, hlf, qtr, eth, sth, tsnd, sfth;
//Dotted and triplet
1.5 => float dot; 
1.0/3.0 => float trip;

measure(Tempo);

SndBuf click => dac;
SndBuf inst => dac;

int seq[][];
int settings[][];
float instGain;

load(click, "hihat_01.wav");
load(inst,"kick_01.wav");

click.gain(0.2);
click.rate(1.5); 

0 => int launch;
[[12,40,70,4],[0,70,80,4],[0,70,90,4],[3,70,100,7],
 [0,40,60,3],[0,70,80,4],[12,70,90,5],[0,70,100,5],
 [11,60,70,6],[0,70,80,4],[4,70,90,5],[0,70,100,6],
 [0,40,60,3],[0,70,80,4],[8,70,90,5],[6,70,100,6]] @=> seq;

spork~ metro();

while(true){
    
    play(0.6);
    
}


//Metro
fun void metro(){
    while(true){
        0 => click.pos;
        eth => now;
    }
}

//Play is the modular version of a for-loop sequencer 
fun void play(float _instGain){
    
    _instGain => instGain;
    //determine();
    while (true){
        
        for(0 => int i; i < seq.size(); i++){
            <<<inst.gain()>>>;
            stepper(i);
        }
        
    }
    
}


//Stepper
fun void stepper(int prob){
    //On launch start sequence from middle
    if(launch == 0){
        1 => launch;
        step(prob, 4);
    }
    //Otherwise start as a typical for loop would start    
    else step(prob, 0);
    
    
}

//Step

//*essentially this is micro sequencing
//*that allows the "Slugging" timing effect
fun void step(int prob, int launchPoint){
    
    seq[prob][3] => float hitPoint;
    
    //"launch point" is used as a strange solution to allow the 
    // time displacement effect
    for(launchPoint => int i; i < 10; i ++){
        //If a hit occurs...
        if(hitPoint == i){
            check(prob);
        }
        sth/10 => now;
    }
}


//Check
//Porting the check function into the class!
fun void check(int _prob){
    //<<<"check", " 1 ", _prob>>>;
    seq[_prob][0] => int prob;
    seq[_prob][1]$float*0.01 => float low;
    seq[_prob][2]$float*0.01=> float high;
    
    if(prob == 12){
        //Set the instrument gain to its typical value
        instGain => inst.gain;
        //Play sample
        0 => inst.pos;
    }
    else if (prob > 0 && prob < 12) {
        Std.rand2(1, 12) => int test;
        if(test <= prob){   
            
            //Choose a random number between the low and high points specified
            Std.rand2f(low, high) => float adjust;
            //Multiply the set gain of the instrument with the random number
            adjust * instGain => float gain;
            gain => inst.gain;
            
            //<<<instrument, adjust, gain>>>;
            0 => inst.pos;
            
        }
    }              
    
}

//Load Buffer
fun string load ( SndBuf inst, string filename )

{
    me.dir() + "/audio/" + filename => inst.read;
    inst.samples() => inst.pos;
    return <<< "Loaded ", filename  >>>; 
}

//Measure
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