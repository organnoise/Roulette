// (launch with OSC_send.ck)
OscOut osc;
osc.dest("localhost", 54322);
// create our OSC receiver
OscIn oin;
// create our OSC message
OscMsg msg;
// use port 6449
54321 => oin.port;
// create an address in the receiver
oin.addAddress( "/play, i" );
oin.addAddress( "/save, i" );
oin.addAddress( "/timeOffset, f" );

int play;
int save;
float offset;

spork~ playTest();

// infinite event loop
while ( true )
{
    // wait for event to arrive
    oin => now;
    // grab the next message from the queue. 
    while ( oin.recv(msg) != 0 )
    { 
        if(msg.address == "/play") msg.getInt(0) => play;
        if(msg.address == "/save") msg.getInt(0) => save;
        if(msg.address == "/timeOffset") msg.getFloat(0) => offset;
    }
}

fun void oscOut(string addr, int val) {
    osc.start(addr);
    osc.add(val);
    osc.send();
}

fun void playTest(){
    while(true){
        if (play == 1) {
            for(int i; i < 16; i++){
                <<< i >>>;
                oscOut("/modNum", i + 1);
                500 :: ms => now;
                if (play == 0) break;
            }
        }
        else 10 :: ms => now;
    }    
}

