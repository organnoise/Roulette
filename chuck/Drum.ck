public class Drum {
    BPM bpm;
    
    80 => bpm.tempo;
    bpm.measure();
    
    //OSC tools
    string name;
    // send object
    OscOut osc;
    osc.dest("localhost", 12001);
    // create our OSC receiver
    OscIn oin;
    OscMsg msg;
    12000 => oin.port;
    
    Event determiner;
    SndBuf inst;
    
    int seq[16][4];
    //[][0] = volume, [][1] = hit boolean
    float settings[16][2];
    float instGain;
    0 => int launch;
    
    spork~ trackClick();
    
    //Play 
    //calculates with determine, then launches  
    //the hits in sequence
    fun void play(float _instGain){
        
        _instGain => instGain;
        determineInit();
        while (true){
            
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
            //For visual purposes make the clock light
            //slightly early
            if(i == 3){
                oscOut("/clockOn", stepNumber);
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
        }
        //Send a comma separated string as OSC message
        for(0 => int i; i < seq.size(); i++){
            Std.itoa(settings[i][1]$int) +=> value;
            if(i < seq.size()-1) "," +=> value;
        }
        oscOut("/"+ name + "/hit", value);
        determiner.signal();
        
    }
    
    //I use this determine msg a couple times
    fun void determine(){
        
        string value;
        oscOut("/"+ name + "/determine", 1);
        
        //Send a comma separated string as OSC message
        for(0 => int i; i < seq.size(); i++){
            Std.itoa(settings[i][1]$int) +=> value;
            if(i < seq.size()-1) "," +=> value;
        }
        oscOut("/"+ name + "/hit", value);
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
            0 => inst.pos;
        }
        // <<<"CHECK AGAIN ", stepNumber>>>;
        check(stepNumber);
        int value[2];
        stepNumber => value[0];
        settings[stepNumber][1]$int => value[1];
        //Send the value of the step hitting
        oscOut("/"+ name + "/soloHit", value);
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
        return <<< "Loaded ", filename  >>>; 
    }
    
    // osc sending function
    //overloaded funtions for sending different types of data
    fun void oscOut(string addr, int val) {
        osc.start(addr);
        osc.add(val);
        osc.send();
    }
    
    fun void oscOut(string addr, int val[]) {
        osc.start(addr);
        for(0 => int i; i < val.size(); i++){
            osc.add(val[i]);
        }
        osc.send();
    }
    
    fun void oscOut(string addr, string val) {
        osc.start(addr);
        osc.add(val);
        osc.send();
    }
    
    
    //Listens to Processing for changes in the settings[][] array
    // It basically recieves OSC msgs if there is a change in data
    //that was sent from ChucK
    
    //ie. Flip the type of hit event for a certain step
    fun void trackClick(){
        // infinite event loop
        // create an address in the receiver
        oin.addAddress( "/"+ name + "/change, i i" );
        while ( true )
        {
            // wait for event to arrive
            oin => now;
            
            // grab the next message from the queue. 
            while ( oin.recv(msg) != 0 )
            { 
                // getFloat fetches the expected float (as indicated by "f")
                msg.getInt(1) => settings[msg.getInt(0)][1];
                // print
                //Chuck needs to be launched second for it to receive...
                //<<<msg.getInt(1)>>>;
                
            }
        }
    }
}