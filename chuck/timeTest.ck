60 => int Tempo;

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

spork~ metro();
spork~ kick(14);


while(true){
    10::ms => now;
}

fun void metro(){
    while(true){
        0 => click.pos;
        qtr => now;
    }
}

fun void kick(int displace){
    while(true){
        displace*(tsnd/32) => now;
        0 => inst.pos;
        qtr - displace*(tsnd/32) => now;
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