public class Clock {
    BPM bpm;
    //OSC tools
    string name;
    // send object
    OscOut osc;
    osc.dest("localhost", 54322);
    // create our OSC receiver
    OscIn oin;
    OscMsg msg;
    54321 => oin.port;
    Event stepChange;
    int pStep; 
    int beat;
    
    0 => int launch;
    1 => int playState;
    
    spork~ appIn();
    //Play
    fun void play(){
        while (true){
            if (playState == 1){
                //intercept determine settings
                for(0 => int i; i < 16; i++){
                    stepper(i);
                    i => pStep;
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
    fun void step(int stepNumber, int launchPoint){
        for(launchPoint => int i; i < 10; i ++){
            if(i == 3){
                oscOut("/clockOn", stepNumber);
                //write info to bytes array for interface
                if(stepNumber != pStep){
                    stepNumber => beat;
                    stepChange.signal();
                }
            }
            bpm.sth/10 => now;
        }
    }
    fun void oscOut(string addr, int val) {
        osc.start(addr);
        osc.add(val);
        osc.send();
    }
    
    fun void appIn(){
        // infinite event loop
        // create an address in the receiver
        oin.addAddress( "/play, i" );
        while ( true )
        {
            // wait for event to arrive
            oin => now;
            
            // grab the next message from the queue. 
            while ( oin.recv(msg) != 0 )
            { 
                //Play/Pause
                if(msg.address == "/play"){
                    <<< "play: ", msg.getInt(0) >>>;
                    //set playstate
                    msg.getInt(0) => playState;
                    //reset launch value for microstepping
                    if (playState == 0) 0 => launch;
                }
            }
        }
    }
    
}