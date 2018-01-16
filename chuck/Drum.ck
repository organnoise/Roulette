public class Drum {
    Preset preset;
    BPM bpm;
    OSC osc;
    
    80 => bpm.tempo;
    bpm.measure();
    
    //OSC tools
    string name;
    
    Event determiner;
    SndBuf inst;
    
    int seq[16][4];
    
    float offsetPercent;
    
    //seq: [probability, vol low, vol high, time offset]
    
    [[0,100,100,4],[0,70,80,4],[0,70,80,4],[0,70,80,4],
    [0,70,80,4],[0,70,80,4],[0,70,80,4],[0,70,80,4],
    [0,70,80,4],[0,70,80,4],[0,70,80,4],[0,70,80,4],
    [0,70,80,4],[0,70,80,4],[0,70,80,4],[0,70,80,4]] @=> seq;
    
    //[][0] = volume, [][1] = hit boolean
    float settings[16][2];
    float instGain;
    0 => int launch;
    
    spork~ appIn();
    1 => int playState;
    int saveState;
    float offset;
    
    //Play 
    //calculates with determine, then launches  
    //the hits in sequence
    fun void play(float _instGain){
        
        _instGain => instGain;
        determineInit();
        while (true){
            
            if (playState == 1){
                //intercept determine settings
                for(0 => int i; i < seq.size(); i++){
                    stepper(i);
                    if (playState == 0) break;
                }
            }
            //If not playing pass arbitrary time to avoid crashing
            else 10 :: ms => now;
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
        
        bpm.sth/2 * offset => now;
        
        //"launch point" is used as a strange solution to allow the 
        // time displacement effect
        for(launchPoint => int i; i < 10; i ++){
            //If a hit occurs...
            if(hitPoint == i){
                hit(stepNumber);
            }
            //For visual purposes make the clock light
            //slightly early
            if(i == 3){
                //osc.oscOut("/clockOn", stepNumber);
            }
            bpm.sth/10 => now;
        }
    }
    
    //Determine
    //run check() on each step on the inital launch
    fun void determineInit(){
        //<<<"Determine">>>;
        determine();
        string value;
        for(0 => int i; i < seq.size(); i++){
            check(i);
            instGain => settings[i][0];
        }
        //Send a comma separated string as OSC message
        for(0 => int i; i < seq.size(); i++){
            Std.itoa(settings[i][1]$int) +=> value;
            if(i < seq.size()-1) "," +=> value;
        }
        osc.oscOut("/"+ name + "/hit", value);
        determiner.signal();
        
    }
    
    //I use this determine msg a couple times
    fun void determine(){
        
        string value;
        osc.oscOut("/"+ name + "/determine", 1);
        
        //Send a comma separated string as OSC message
        for(0 => int i; i < seq.size(); i++){
            Std.itoa(settings[i][1]$int) +=> value;
            if(i < seq.size()-1) "," +=> value;
        }
        osc.oscOut("/"+ name + "/hit", value);
        determiner.signal();
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
        }
        // <<<"CHECK AGAIN ", stepNumber>>>;
        check(stepNumber);
        int value[2];
        stepNumber => value[0];
        settings[stepNumber][1]$int => value[1];
        //Send the value of the step hitting
        osc.oscOut("/"+ name + "/soloHit", value);
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
        osc.oin.addAddress( "/play, i" );
        osc.oin.addAddress( "/save, i" );
        osc.oin.addAddress( "/timeOffset, f" );
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
                if(osc.msg.address == "/save"){
                    //trigger save state
                    if(osc.msg.getInt(0) == 1) {
                        preset.save(seq);
                        <<<"Preset saved to: ", name >>>;
                    }
                }
                //Offset Percentage
                if(osc.msg.address == "/timeOffset") osc.msg.getFloat(0) => offset;
            }
        }
    }
}