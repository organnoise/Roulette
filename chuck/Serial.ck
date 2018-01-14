public class RouletteSerial {
    // open cereal device
    SerialIO cereal;
    
    int bytes[];
    string line;
    string stringInts[3];
    int data[3];
    3 => int digits;
    
    Event serialNotify;
    
    int partType;
    int moduleNum;
    int value;
    
    int seq[16][5];
    int buttonMomentaryState[16];
    int settings[16];
    Event buttonPressed;
    
    int encoder[2];
    100 => int encoderTempo;
    int encoderSelect;
    1 => int encoderSelectP;
    Event drumChange;
    int encoderState;
    int encoderStateP;
    [[255,0],[0,255],[10,255],[55,200]] @=> int encoderColor[][];
    Event tempoChange;
    
    3 => int numDrums;
    40 => int minTempo;
    200 => int maxTempo;
    
    
    
    fun void setup(int dev){
        // list cereal devices
        SerialIO.list() @=> string list[];
        
        // no cereal devices available
        if(list.cap() == 0)
        {
            cherr <= "no cereal devices available\n";
            me.exit(); 
        }
        
        // print list of cereal devices
        chout <= "Available devices\n";
        for(int i; i < list.cap(); i++)
        {
            chout <= i <= ": " <= list[i] <= IO.newline();
        }
        
        // parse first argument as device number
        dev => int device;
        if(me.args()) me.arg(0) => Std.atoi => device;
        
        if(device >= list.cap())
        {
            cherr <= "cereal device #" <= device <= "not available\n";
            me.exit(); 
        }
        
        
        if(!cereal.open(device, SerialIO.B115200, SerialIO.ASCII))
        {
            chout <= "unable to open cereal device '" <= list[device] <= "'\n";
            me.exit();
        }
        // pause to let cereal device finish opening
        2::second => now;
        spork~ poller();
        spork~ tempoMonitorBlink();
        spork~ encoderPing();
        colorUpdate();
        0 => encoderSelectP;
    } 
    
    fun void send(int a, int b, int c){
        [255, a, b, c] @=> bytes;
        // write to cereal device
        cereal.writeBytes(bytes);
    }
    
    
    fun void poller(){
        while(true){
            // Grab Serial data
            cereal.onLine()=>now;
            cereal.getLine()=>line;
            
            if( line$Object == null ) continue;
            if( line == "\n" ) continue;
            
            0 => stringInts.size;
            
            // Line Parser
            string pattern;
            "\\[" => pattern;
            for(int i;i<digits;i++){
                "([0-9]+)" +=> pattern;
                if(i<digits-1){
                    "," +=> pattern;
                }
            }
            "\\]" +=> pattern;
            if (RegEx.match(pattern, line , stringInts))
            {
                for(1 =>int i; i<stringInts.cap(); i++)  
                {
                    // Convert string to Integer
                    Std.atoi(stringInts[i])=>data[i-1];
                }
            }
            
            serialNotify.signal();
            //<<< data[0], data[1], data[2]>>>;
            5::ms => now;
        } 
    }
    
    fun int[] dataBang(){
        return data;
    }
    
    //Main loop to be sporked by parent
    fun void loop(){
        while(true){
            //Wait for a serial notify event
            serialNotify => now;
            //Grab all the data and put it in local array
            dataBang() @=> data;
            
            sort();
            // If 0, it is a pot for probability
            if(partType == 0) updatePot();
            // If 2, its X
            else if(partType == 2) updateX();
            //If 3, its a button
            else if(partType == 3) updateButton();
            //If 4, its the encoder
            else if(partType == 4) updateEncoder();   
            else updateY();
            
        }
    }
    
    //Overloaded for debug options
    fun void loop(int a){
        while(true){
            //Wait for a serial notify event
            serialNotify => now;
            //Grab all the data and put it in local array
            dataBang() @=> data;
            
            sort();
            // If 0, it is a pot for probability
            if(partType == 0) updatePot();
            // If 2, its X
            else if(partType == 2) updateX();
            //If 3, its a button
            else if(partType == 3) updateButton();
            //If 4, its the encoder
            else if(partType == 4) updateEncoder();   
            else updateY();
            debug(a);
        }
    }
    
    //Scales pot values to run clockwise and be a number between 0 and 12
    fun void updatePot(){
        Std.clamp(Std.scalef(value$float,0,127,13,0)$int,0,12) => seq[moduleNum][partType];
    }
    fun void updateButton(){
        if(moduleNum < 16){
            //Tell if button is being held or not for updateY
            value => buttonMomentaryState[moduleNum];
            //Update settings for hit function of Drum Class
            if(value == 1){
                !settings[moduleNum] => settings[moduleNum];
                buttonPressed.signal();
            }
        }
        if(moduleNum == 16 && value == 1){
            //<<<"yo ", encoderState >>>;
            !encoderState => encoderState;
        }
    }
    fun void updateX(){
        //If 2, its X of joystick for slugging
        Std.clamp(Std.scalef(value$float,21,105,0,10)$int,0,9) => seq[moduleNum][3];
    }
    
    fun void updateY(){
        //Make sure the button is not the encoder button before moving on
        if(moduleNum < 16){
            // If button NOT being held and using Y, its the joystick, so set it for the HIGH vol 
            if(buttonMomentaryState[moduleNum] == 0 && partType == 1) Std.clamp(Std.scalef(value$float,20,110,100,20)$int,25,90) => seq[moduleNum][partType];
            // If button IS being held and using Y, its the joystick, so set it for the LOW vol 
            else if(buttonMomentaryState[moduleNum] == 1 && partType == 1) Std.clamp(Std.scalef(value$float,20,100,110,20)$int,25,90) => seq[moduleNum][2];    
        }
    }
    
    int encoderDrum;
    int encoderCount;
    int encoderVal[2];
    int encTimerOn;
    //Sporked to monitor changes in encoder between 2 and 0
    fun void encoderPing(){
        while (true){
            serialNotify => now;
            
            if(partType == 4) {
                if (moduleNum == 0){
                    if (encTimerOn == 0) spork~ encoderTimer(1);
                    
                    value => encoderVal[0];
                    
                    if (value == 2){ 
                        if (encoderVal[0] != encoderVal[1]) 0 => encoderCount;
                        encoderCount++;
                    }
                    if (value == 1) {
                        if (encoderVal[0] != encoderVal[1]) 0 => encoderCount;
                        encoderCount--;
                    }
                    value => encoderVal[1];
                }
                else if (moduleNum == 1) {
                    //If moduleNum == 1, assign it to Tempo
                    Std.clamp(Std.scalef(value$float,0,255,minTempo,maxTempo+2)$int,minTempo,maxTempo) => encoderTempo => encoder[1];
                    tempoChange.signal();
                }
            }
            //<<<"Encoder Counter: ", Std.abs(encoderCount)>>>;
        }
    }
    
    fun void encoderTimer(int timer) {
        1 => encTimerOn;
        timer::second => now;
        <<<"Encoder timer reset">>>;
        0 => encoderCount;
        0 => encTimerOn;
    }
    
    5 => int turnCount;
    fun void updateEncoder(){
        //If moduleNum == 0, assign it to represent the drum picker
        if(moduleNum == 0){
            //If encoder turned enough, change drum
            if (Std.abs(encoderCount) % turnCount == turnCount - 1) {
                
                if (value == 2) encoderDrum++;
                else if (value == 1) encoderDrum--;
                
                //Wrap if number is going backwards
                if(encoderDrum < 0) numDrums - 1 => encoderDrum;
                
                encoderDrum % numDrums => encoderDrum;
                Std.abs(encoderDrum) => encoderSelect => encoder[0];
                <<<"Drum Change: ", encoderDrum >>>;
            }
            colorUpdate();
            encoder[0] => encoderSelectP;
        }
        
        moduleNum => encoderState;
    }
    
    //Debug tool to know if data is being collected properly
    fun void debug(int a){
        if(a == 0)  <<< partType, moduleNum, value>>>;
        
        if(a == 1 || a == 2){
            for(0 => int i; i < 16; i++){
                if(a == 1)<<<"Seq ",i, ":", seq[i][0], seq[i][1], seq[i][2], seq[i][3]>>>;
                //Button Status
                else if(a == 2)<<<"Settings ",i, ":", settings[i]>>>;
                else break;
            }
        }
        if(a == 3)for(0 => int i; i < 2; i++)<<<"Encoder ",i, ":", encoder[i]>>>;
        
    }
    
    fun void sort(){
        //Organize data so it is easier to understand it's parts
        data[0] => partType;
        data[1] => moduleNum;
        //Most of the circuits are rigged backwards
        //So you will see a lot of scaling to flip the data around
        //Right here I am flipping so that the moduleNum rotates clockwise
        if(moduleNum < 16 && partType != 4) Std.scalef(moduleNum$float,0,15,15,0)$int => moduleNum;
        data[2] => value;
    }
    
    
    fun void colorUpdate(){
        if(encoderSelect != encoderSelectP){
            send(2,0,encoderColor[encoderSelect][0]);
            send(2,1,encoderColor[encoderSelect][1]);
            drumChange.signal();
        }
    }
    
    fun void tempoMonitorBlink(){
        float beat;
        while(true){  
            //Quick bpm math
            60000/encoderTempo => beat;
            
            //If the encoder is in tempo mode make it blink
            if(encoderState == 1){
                //Send R/G 0
                send(2,0,0);
                send(2,1,0);
                //Blink at a rate related to the tempo
                beat*.7::ms => now;
                //Send R/G values according to drum setting
                send(2,0,encoderColor[encoderSelect][0]);
                send(2,1,encoderColor[encoderSelect][1]);
            }
            //On transition from blinking to not blinking, reset the color 
            //this ensures the encoder is always on
            if(encoderState != encoderStateP){
                send(2,0,encoderColor[encoderSelect][0]);
                send(2,1,encoderColor[encoderSelect][1]);
            }
            encoderState => encoderStateP; 
            beat*.3::ms => now;
        }
    }
}

//RouletteSerial serial;
//serial.setup(3);

//spork~ serial.loop(3);

//while(true)1::second=>now;
