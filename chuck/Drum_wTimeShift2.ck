60 => int Tempo;

dur whl, hlf, qtr, eth, sth, tsnd, sfth;
//Dotted and triplet
1.5 => float dot; 
1.0/3.0 => float trip;

measure(Tempo);

// send object
OscOut osc;
osc.dest("localhost", 12000);

SndBuf click => dac;
SndBuf inst => dac;

string name;
int seq[16][4];
float settings[16][2];
float instGain;

load(click, "hihat_01.wav");
load(inst,"kick_01.wav");

click.gain(0.2);
click.rate(1.5); 

0 => int launch;
[[12,20,50,4],[0,70,80,4],[0,70,90,4],[0,70,100,7],
[0,40,60,3],[0,70,80,4],[0,70,90,5],[0,70,100,5],
[0,60,70,6],[0,70,80,4],[0,70,90,5],[0,70,100,6],
[0,40,60,3],[0,70,80,4],[0,70,90,5],[0,70,100,6]] @=> seq;

spork~ metro();

while(true){
    
    play(0.7);
    
}


//Metro
fun void metro(){
    while(true){
        0 => click.pos;
        eth => now;
    }
}

//Play 
//calculates with determine, then launches  
//the hits in sequence
fun void play(float _instGain){
    
    _instGain => instGain;
    
    while (true){
        determine();
        //intercept determine settings
        for(0 => int i; i < seq.size(); i++){
            stepper(i);
        }
    }
    
}


//Stepper
fun void stepper(int stepNumber){
    //On launch start sequence from middle
    if(launch == 0){
        1 => launch;
        step(stepNumber, 4);
    }
    //Otherwise start as a typical for loop would start    
    else step(stepNumber, 0);
    
    
}

//Step

//essentially this is micro sequencing
//that allows the "Slugging" timing effect
fun void step(int stepNumber, int launchPoint){
    
    seq[stepNumber][3] => float hitPoint;
    
    //"launch point" is used as a strange solution to allow the 
    // time displacement effect
    for(launchPoint => int i; i < 10; i ++){
        //If a hit occurs...
        if(hitPoint == i){
            hit(stepNumber);
        }
        sth/10 => now;
    }
}

//Determine
//run check() on each step 
fun void determine(){
    //<<<"Determine">>>;
    for(0 => int i; i < seq.size(); i++){
        check(i);
    }
    oscOut("/"+ name + "/hit/" + i,settings[i][1]);
}

//Hit
//uses the data from settings[][] trigger a sample
fun void hit(int stepNumber){
    /*<<<stepNumber,"Gain:", 
    settings[stepNumber][0], 
    inst.gain(),"Pos:", 
    settings[stepNumber][1]>>>;
    */
    
    if(settings[stepNumber][1] == 1){ 
        settings[stepNumber][0] => inst.gain;
        0 => inst.pos;
    }
}
//Check
//uses the values from seq[][] to determine hit data
//sends values to the settings[][] array
fun void check(int step){
    seq[step][0] => int prob;
    seq[step][1]$float*0.01 => float low;
    seq[step][2]$float*0.01=> float high;
    
    if(prob == 12){
        //<<<"Definite" , step>>>;
        //Set the instrument gain to its typical value
        instGain => settings[step][0];
        //Play sample (set .pos to 0)
        1 => settings[step][1];
        
    }
    else if (prob > 0 && prob < 12) {
        Std.rand2(1, 12) => int test;
        <<<"Calculating" , step>>>;
        if(test <= prob){   
            <<<"True", step>>>;
            //Choose a random number between the low and high points specified
            Std.rand2f(low, high) => float adjust;
            //Multiply the set gain of the instrument with the random number
            adjust * instGain => float gain;
            gain => settings[step][0];
            //Set .pos to 0
            1 => settings[step][1];   
        }
        //Failed test
        else{
            //Set .pos to 1 (boolean for not playing)
            <<<"Failed Test", step>>>;
            0 => settings[step][1];
        }
    } 
    else {
        //<<<"Nothing", step>>>;
        instGain => settings[step][0];
        //Set .pos to 1 (boolean for not playing)
        0 => settings[step][1];
    }             
}

//Load Buffer
fun string load ( SndBuf inst, string _name, string filename )

{
    me.dir() + "/audio/" + filename => inst.read;
    inst.samples() => inst.pos;
    _name => name;
    return <<< "Loaded ", filename  >>>; 
}

// osc sending function
fun void oscOut(string addr, int val) {
    osc.start(addr);
    osc.add(val);
    osc.send();
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