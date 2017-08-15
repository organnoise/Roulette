
public class interfaceTemplate
{
    
    // Number of Buttons
    2 => int numberButtons;
    3 => int numberSensors; 
    
    // Member Global Variables
    int buttonState[numberButtons];
    Event buttonEvent[numberButtons];
    int sensor[numberSensors]; // raw
    int button[numberButtons]; // raw
    
    
    int sensorClean[numberSensors]; // signal conditioning on IR sensor
    Event irBang;  // threshold for IR sensor
    
    
    // MIDI Out setup
    MidiOut mout;
    MidiMsg msg;
    
    
    // MIDI Port (Window > Device Manager > Output )
    1 => int port; 
    
    if ( !mout.open(port) )
    {
        <<< "Error : MIDI port did not open on port: ", port >>>;
        me.exit();
    }
    
    
    // OSC Initialization
    OscSend xmit;
    "localhost" => string hostname;
    12001 => int portOSC;
    xmit.setHost(hostname, portOSC);
    
    
    
    
    // Serial Handling 
    SerialIO serial;
    string line;
    string stringInts[5];
    int data[5];
    
    fun void initSerial()
    {
        
        SerialIO.list() @=> string list[];
        for( int i; i < list.cap(); i++ )
        {
            chout <= i <= ": " <= list[i] <= IO.newline();
        }
        serial.open(2, SerialIO.B9600, SerialIO.ASCII);
        
        1::second => now;
        
        spork ~ serialPoller();
    }
    
    // ***********************************************************
    //
    // SERIAL
    // 
    // ***********************************************************
    
    
    fun void serialPoller(){
        while( true )
        {
            // Grab Serial data
            serial.onLine()=>now;
            serial.getLine()=>line;
            
            if( line$Object == null ) continue;
            
            0 => stringInts.size;
            
            // Line Parser
            if (RegEx.match("\\[([0-9]+),([0-9]+),([0-9]+),([0-9]+),([0-9]+)\\]", line , stringInts))
            {      
                for( 1=>int i; i<stringInts.cap(); i++)  
                {
                    // Convert string to Integer
                    Std.atoi(stringInts[i])=>data[i-1];
                }
            }
            
            
            // Organize Sensor Data in Array sensor[]
            // sensors are in data 2, 3 & 4 
            for( 2 => int i; i <= 4; i++)
            {
                data[i] => sensor[i-2];
            }   
            
            // Organize Button Data in Array button[]
            // button are in data 0 1
            for( 0 => int i; i <= 1; i++ )
            {
                data[i] => button[i];
            }
        }
    }
    
    
    
    // ***********************************************************
    //
    // SIGNAL CONDITIONING
    // 
    // ***********************************************************
    fun void lowPass(int sensorIndex, dur sampleTime)
    {
        sensor[sensorIndex] => int lastSensor;
        while( true ) 
        {
            sampleTime => now;
            (sensor[sensorIndex] + lastSensor) / 2 => sensorClean[sensorIndex];   
            sensor[sensorIndex] => lastSensor;
        }
    }
    
    
    
    fun void irBanger(int sensorIndex, dur sampleTime, int Threshold)
    {
        sensorClean[sensorIndex] => int lastSensor;
        while( true ) 
        {
            sampleTime => now;
            sensorClean[sensorIndex] - lastSensor => int Derivative;
            
            if( Derivative > Threshold )
            {
                irBang.broadcast();
                <<<" Bang... IR " >>>;
                500::ms => now;  //allow one bang every 500 ms. 
            } 
            
        }
    }
    
    fun void initSignalCondition()
    {
        // deal with this
        spork ~ irBanger(2,10::ms, 700);      
        spork ~ lowPass(2, 10::ms);
        spork ~ lowPass(1, 10::ms);
    }
    
    
    
    // ***********************************************************
    //
    // MIDI
    // 
    // ***********************************************************
    fun void midiToggle(int whichButton, int rawValue)
    {
        
        if (rawValue != buttonState[whichButton])
        { 
            // Broadcast Event
            buttonEvent[whichButton].broadcast();
            
            if ( rawValue == 1 )
            {
                144 => msg.data1; // Note On
                whichButton => msg.data2; 
                127 => msg.data3;
            }
            else 
            {
                144 => msg.data1; // Note Off
                whichButton => msg.data2;     
                0 => msg.data3;
            }
            mout.send(msg);
            rawValue => buttonState[whichButton];
            
            <<< " bang: ", rawValue >>>;
        }
        
    }
    
    fun int midiSensor(int whichSensor, int rawValue)
    {
        // scale raw value to MIDI
        // bit shift -  rawValue >> 3
        rawValue / 8 => int midiValue;  
        
        176 => msg.data1; // Control Change Channel 1
        whichSensor => msg.data2;
        midiValue => msg.data3;
        mout.send(msg);
        
        return midiValue;
    }
    
    
    // ***********************************************************
    //
    // OSC
    // 
    // ***********************************************************
    fun void oscSensor(dur samplerate)
    {
        
        // Create typetag based on number sensors
        string typetag;
        for( 0 => int i; i < sensor.cap(); i++)
        {
            "i" +=> typetag;
        }
        
        while( true )
        {
            // create OSC message
            xmit.startMsg("/interface",typetag);
            for( 0 => int i; i < sensor.cap(); i++)
            {
                sensor[i] => xmit.addInt;
            } 
            
            samplerate => now;
        }
    }
    
    fun void oscButton(int whichButton)
    {
        xmit.startMsg("/button","ii");
        
        while( true )
        {
            buttonEvent[whichButton] => now;
            whichButton => xmit.addInt;
            button[whichButton] => xmit.addInt;   
        }
    }
    
    
    fun void initOsc()
    {
        spork ~ oscSensor(100::ms);
        
        for (0 => int i; i < button.cap(); i++)
        {
            spork ~ oscButton(i);
        } 
    }
    
}





