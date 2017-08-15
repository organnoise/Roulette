public class SerialGrab {
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
    int settings[16];
    int encoder[2];
    
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
        spork~ cerealPoller();
        spork~ loop();
        
    }    
    fun void cerealSend(int a, int b, int c){
        [255, a, b, c] @=> bytes;
        // write to cereal device
        cereal.writeBytes(bytes);
    }
    
    
    fun void cerealPoller(){
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
            //else if(partType == 3) updateButton();
            //If 4, its the encoder
            else if(partType == 4) updateEncoder();   
            updateY();
            //debug(3);
        }
    }
    
    fun void updatePot(){
        Std.clamp(Std.scalef(value$float,0,127,13,0)$int,0,12) => seq[moduleNum][partType];
    }
    fun void updateButton(){
        if(moduleNum < 16){
            //Tell if button is being held or not for updateY
            value => seq[moduleNum][4];
            //Update settings for hit function of Drum Class
            if(value == 1) !settings[moduleNum] => settings[moduleNum];
        }
        if(moduleNum == 16); 
    }
    fun void updateX(){
        //If 2, its X of joystick for slugging
        Std.clamp(Std.scalef(value$float,21,105,0,11)$int,0,10) => seq[moduleNum][3];
    }
    
    fun void updateY(){
        // If button NOT being held and using Y, its the joystick, so set it for the HIGH vol 
        if(seq[moduleNum][4] == 0 && partType == 1) Std.clamp(Std.scalef(value$float,20,110,110,0)$int,0,100) => seq[moduleNum][partType];
        // If button IS being held and using Y, its the joystick, so set it for the LOW vol 
        else if(seq[moduleNum][4] == 1 && partType == 1) Std.clamp(Std.scalef(value$float,20,110,110,0)$int,0,100) => seq[moduleNum][2];    
    }
    
    fun void updateEncoder(){
        //If moduleNum == 0, assign it to represent the drum picker
        if(moduleNum == 0)Std.clamp(Std.scalef(value$float,0,255,0,numDrums)$int,0,numDrums - 1) => encoder[moduleNum];
        //If moduleNum == 1, assign it to Tempo
        if(moduleNum == 1)Std.clamp(Std.scalef(value$float,0,255,minTempo,maxTempo+2)$int,minTempo,maxTempo) => encoder[moduleNum];
        
    }
    
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
}


class Timer{
    
    time timerStart;
    time timerEnd;
    1::second => dur interval;
    0 => int startBool;
    
    fun void start(){
        if(startBool == 0){
            now => timerStart;
            timerStart + interval => timerEnd;
            1 => startBool;
        }
    }
    fun void setInterval(float a){
        a::ms => interval;
        timerStart + interval => timerEnd;
    }
    
    fun int done(){
        <<<timerEnd, " ", now>>>;
        if(timerEnd <= now)return 1;
        else return 0;
    }
    
    fun void reset(){
        0 => startBool;
    }
}

SerialGrab serial;

serial.setup(3);

while(true){
    serial.serialNotify => now;
    serial.debug(0);
 }

