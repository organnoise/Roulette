public class Drum {
    Preset preset;
    BPM bpm;
    OSC osc;
    MidiOut mout;
    
    int port;
    int noteNum;
    mout.open(port);
    
    80 => bpm.tempo;
    bpm.measure();
    0.5 => float swing;
    
    //OSC tools
    string name;
    
    Event determiner;
    SndBuf inst;
    
    int seq[16][4];
    
    //seq: [probability, vol low, vol high, time offset]
    
    [[0,100,100,4],[0,70,80,4],[0,70,80,4],[0,70,80,4],
    [0,70,80,4],[0,70,80,4],[0,70,80,4],[0,70,80,4],
    [0,70,80,4],[0,70,80,4],[0,70,80,4],[0,70,80,4],
    [0,70,80,4],[0,70,80,4],[0,70,80,4],[0,70,80,4]] @=> seq;
    
    //[][0] = volume, [][1] = hit boolean
    float settings[16][2];
    float instGain;
    0 => int launch;
    
    
    1 => int playState;
    int saveState;
    .1 => float offset;
    
    
    osc.oin.addAddress( "/play, i" );
    osc.oin.addAddress( "/save, i" );
    //osc.oin.addAddress( "/clear, i" );
    osc.oin.addAddress( "/load, i" );
    osc.oin.addAddress( "/timeOffset, f" );
    
    //Play 
    //calculates with determine, then launches  
    //the hits in sequence
    fun void play(float _instGain){
        
        _instGain => instGain;
        determineInit();
        
        
        
        spork~ appIn();
        while (true){
            
            if (playState == 1){
                //intercept determine settings
                for(0 => int i; i < seq.size(); i++){
                    stepper(i);
                    if (playState == 0) break;
                }
            }
            //If not playing pass the shortest amount of time
            else 1 :: samp => now;
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
    0.99 => swing;
    dur stepTime;
    //essentially this is micro sequencing
    //that allows the "Slugging" timing effect
    fun void step(int stepNumber, int launchPoint){
        
        seq[stepNumber][3] => float hitPoint;
        
        //Swing multiplier to normal sth note
        bpm.sth => stepTime;
        
        if(offset == 0) 0.01 => offset;
        //(stepTime * (1 - offset)) / 2 => dur offsetTime;
        (stepTime * (1 - offset)) => dur offsetTime;
        
        offsetTime * calcSwing(stepNumber) => now;
        //"launch point" is used as a strange solution to allow the 
        // time displacement effect
        for(launchPoint => int i; i < 9; i ++){
            //If a hit occurs...
            if(hitPoint == i){
                hit(stepNumber);
            }
            (stepTime * offset)/9 => now;
            
        }
        offsetTime * (1 - calcSwing(stepNumber)) => now;
    }
    
    //Calculate the swing based on the stepNumber
    fun float calcSwing(int stepNumber){
        float swingPercent;
        
        if (swing == 0.0) 0.01 => swing;
        
        if (stepNumber % 2 == 0) {
            .5 => swingPercent;
        }
        if (stepNumber % 2 == 1) {
            swing => swingPercent;
        }
        //<<<"Calc Swing", name, swingPercent, stepNumber >>>;
        return swingPercent;
    }
    
    //Determine
    //run check() on each step on the inital launch
    fun void determineInit(){
        //<<<"Determine">>>;
        determine();
        for(0 => int i; i < seq.size(); i++){
            check(i);
            instGain => settings[i][0];
        }
        determiner.signal();
    }
    
    //I use this determine msg a couple times
    fun void determine(){     
        determiner.signal();
    }
    
    //Midi Set
    fun void setMidi(int _port, int _noteNum){
        _port => port;
        mout.open(port);
        _noteNum => noteNum;
    }
    
    //Midi send
    fun void noteOn(int control, int note, int vel){
        MidiMsg msg;
        
        if (control == 1) 0x90 => msg.data1;
        else 0x80 => msg.data1;
        note => msg.data2;
        vel => msg.data3;
        mout.send(msg);  
    }
    
    //Hit
    //uses the data from settings[][] trigger a sample
    //The logic of this function relaunches the check function
    //for each step after a hit is launched
    //This allows users to see the next occuring hit before it happens
    fun void hit(int stepNumber){
        
        if(settings[stepNumber][1] == 1){ 
            //<<<"HIT">>>;
            settings[stepNumber][0] => inst.gain;
            //<<<name, " ", stepNumber, " ", inst.gain() >>>;
            0 => inst.pos;
            noteOn(1, noteNum, (inst.gain() * 127)$int);
            noteOn(0, noteNum, (inst.gain() * 127)$int);
        }
        // <<<"CHECK AGAIN ", stepNumber>>>;
        check(stepNumber);
        int value[2];
        stepNumber => value[0];
        settings[stepNumber][1]$int => value[1];
        //Send the value of the step hitting
        //osc.oscOut("/"+ name + "/soloHit", value);
        //Allow processing to create a new table of comparison
        //see the KickPing[] array in hitUpdate()
        //oscOut("/"+ name + "/determine", 1);
        determine();
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
            //<<<"Calculating" , step>>>;
            if(test <= prob){   
                // <<<"True", step>>>;
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
                // <<<"Failed Test", step>>>;
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
    
    //Clear
    fun void clear(){
        [[0,100,100,4],[0,70,80,4],[0,70,80,4],[0,70,80,4],
        [0,70,80,4],[0,70,80,4],[0,70,80,4],[0,70,80,4],
        [0,70,80,4],[0,70,80,4],[0,70,80,4],[0,70,80,4],
        [0,70,80,4],[0,70,80,4],[0,70,80,4],[0,70,80,4]] @=> seq;  
        <<< name, "cleared">>>;
    }
    
    //Load Buffer
    fun string load ( string _name, string filename ){
        me.dir() + "/audio/" + filename => inst.read;
        inst.samples() => inst.pos;
        _name => name;
        name => preset.name;
        return <<< "Loaded ", filename  >>>; 
    }
    
    
    //Listens to Processing for changes in the settings[][] array
    // It basically recieves OSC msgs if there is a change in data
    //that was sent from ChucK
    
    //ie. Flip the type of hit event for a certain step
    fun void appIn(){
        // infinite event loop
        // create an address in the receiver
        while ( true )
        {
            // wait for event to arrive
            osc.oin => now;
            
            // grab the next message from the queue. 
            while ( osc.oin.recv(osc.msg) != 0 )
            { 
                //Play/Pause
                if(osc.msg.address == "/play"){
                    <<< name," play: ", osc.msg.getInt(0) >>>;
                    //set playstate
                    osc.msg.getInt(0) => playState;
                    //reset launch value for microstepping
                    if (playState == 0) 0 => launch;
                }
                //Preset Saving
                else if(osc.msg.address == "/save"){
                    //trigger save state
                    if(osc.msg.getInt(0) == 1) {
                        preset.save(seq);
                        <<<"Preset saved to: ", name >>>;
                    }
                }
                //Loading
                else if(osc.msg.address == "/load"){
                    preset.load(osc.msg.getInt(0)) @=> seq;
                    determineInit();
                    <<< name, "loaded">>>; 
                }
                //Set offset
                else if(osc.msg.address == "/timeOffset"){
                    osc.msg.getFloat(0) => offset;
                    //<<<name, osc.msg.getFloat(0)>>>;  
                }
            }
        }
    }
}