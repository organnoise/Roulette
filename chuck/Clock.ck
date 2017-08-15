public class Clock {
    BPM bpm;
    OscOut osc;
    osc.dest("localhost", 12001);
    Event stepChange;
    int pStep; 
    int beat;
    
    0 => int launch;
    
    //Play
    fun void play(){
        while (true){
            //intercept determine settings
            for(0 => int i; i < 16; i++){
                stepper(i);
                i => pStep;
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
    
}