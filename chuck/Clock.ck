public class Clock {
    BPM bpm;
    OSC osc;
    //OSC tools
    "clock" => string name;
    
    Event stepChange;
    Event pause;
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
                    if (playState == 0) {
                        pause.signal();
                        osc.oscOut("/play", 0);
                        break;
                    }
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
            osc.oscOut("/play", 1);
            step(stepNumber, 4);
        }
        //Otherwise start as a typical for loop would start    
        else step(stepNumber, 0);
    }
    
    //Step
    fun void step(int stepNumber, int launchPoint){
        for(launchPoint => int i; i < 10; i ++){
            if(i == 3){
                osc.oscOut("/clockOn", stepNumber);
                //write info to bytes array for interface
                if(stepNumber != pStep){
                    stepNumber => beat;
                    stepChange.signal();
                }
            }
            bpm.sth/10 => now;
        }
    }
    
    fun int getBeat(){
        return Std.scalef(beat, 0, 15, 15, 0)$int;
    }
    
    fun void appIn(){
        // infinite event loop
        // create an address in the receiver
        osc.oin.addAddress( "/play, i" );
        while ( true )
        {
            // wait for event to arrive
            osc.oin => now;
            
            // grab the next message from the queue. 
            while ( osc.oin.recv(osc.msg) != 0 )
            { 
                //Play/Pause
                if(osc.msg.address == "/play"){
                    <<< name, " play: ", osc.msg.getInt(0) >>>;
                    //set playstate
                    osc.msg.getInt(0) => playState;
                    //reset launch value for microstepping
                    if (playState == 0) 0 => launch;
                }
            }
        }
    }
    
}