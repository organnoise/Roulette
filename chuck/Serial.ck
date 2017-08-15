public class SerialGrab {
    // open cereal device
    SerialIO cereal;
    
    int bytes[];
    string line;
    string stringInts[3];
    int data[3];
    3 => int digits;
    
    Event serialNotify; 
    
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
int data[3];
int partType;
int moduleNum;
int value;
int seq[16][5];

Event button;
Timer buttonTimer[16];

int blinkBool;
Shred s;

serial.setup(3);
spork~ serial.cerealPoller();

while(true){
    
    //Wait for a serial notify event
    serial.serialNotify => now;
    //Grab all the data and put it in local array
    serial.dataBang() @=> data;
    
    //Organize data so it is easier to understand it's parts
    data[0] => partType;
    data[1] => moduleNum;
    data[2] => value;
    
    // If 0, it is a pot for probability
    if(partType == 0) Std.clamp(Std.scalef(value$float,0,127,13,0)$int,0,12) => seq[moduleNum][partType];
    // If 2, its X of joystick for slugging
    else if(partType == 2) Std.clamp(Std.scalef(value$float,21,105,0,11)$int,0,10) => seq[moduleNum][3];
    else if(partType == 3)
    { 
        value => seq[moduleNum][4];
        button.broadcast();
    }
    
    // If button NOT being held and using Y, its the joystick, so set it for the HIGH vol 
    if(seq[moduleNum][4] == 0 && partType == 1) Std.clamp(Std.scalef(value$float,20,110,110,0)$int,0,100) => seq[moduleNum][partType];
    // If button IS being held and using Y, its the joystick, so set it for the LOW vol 
    else if(seq[moduleNum][4] == 1 && partType == 1) Std.clamp(Std.scalef(value$float,20,110,110,0)$int,0,100) => seq[moduleNum][2]; 
    
    if(seq[moduleNum][4] == 0){
        0 => blinkBool;
        buttonTimer[moduleNum].reset();
        Machine.remove( s.id() );
    }
    
    else if (seq[moduleNum][4] == 1){
        buttonTimer[moduleNum].start();
    }
    
    if(blinkBool == 0 && buttonTimer[moduleNum].done() == 1){
        1 => blinkBool;
        spork~ blink(moduleNum) @=> s;
    }  
    
    for(0 => int i; i < 16; i++){
        //<<<"Seq ",i, ":", seq[i][0], seq[i][1], seq[i][2], seq[i][3]>>>;
    }
}

fun void blink(int a){
    while(true){
        serial.cerealSend(0,a,1);
        100::ms => now;
        serial.cerealSend(0,a,0);
        100::ms => now;
    }
}

