// open cereal device
SerialIO cereal;

int bytes[];
string line;
string stringInts[3];
int data[3];
3 => int digits;
15 => int counter;

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
3 => int device;
if(me.args()) me.arg(0) => Std.atoi => device;

if(device >= list.cap())
{
    cherr <= "cereal device #" <= device <= "not available\n";
    me.exit(); 
}


if(!cereal.open(device, SerialIO.B9600, SerialIO.ASCII))
{
    chout <= "unable to open cereal device '" <= list[device] <= "'\n";
    me.exit();
}

// pause to let cereal device finish opening
2::second => now;


spork ~ cerealPoller();
spork ~ cerealSend(0,15,1);
spork ~ cerealSend(2,1,255);


// loop forever
while(true)
{
    counterTest();
}


fun void cerealSend(int a, int b, int c){
    while(true){
        [255, a, Std.rand2(0,b), Std.rand2(0,c)] @=> bytes;
        // write to cereal device
        cereal.writeBytes(bytes);
        500::ms => now;
    }
}


fun void counterTest(){
    
    counter % 16=> counter;
    [255, 1, counter, 1] @=> bytes;
    cereal.writeBytes(bytes);
    200::ms => now;
    [255, 1, counter, 0] @=> bytes;
    cereal.writeBytes(bytes);
    if(counter <= 0) 15 => counter;
    else counter--;
    //<<<counter>>>;  
    20::ms => now;       
}

fun void cerealPoller(){
    while( true )
    {
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
        
        <<< data[0], data[1], data[2]>>>;
        5::ms => now;
    } 
    
}