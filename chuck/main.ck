BPM bpm;
Clock clock;
OSC osc;



RouletteSerial serial;

Drum kick;
Drum snare; 
Drum hihat;   

[kick, snare, hihat] @=> Drum drum[];
int currentDrum;

80 => bpm.tempo => serial.encoderTempo;
bpm.measure();


serial.setup(2);
spork~ serial.loop(0);

kick.inst => dac;
snare.inst => dac;
hihat.inst => dac;

kick.load("kick","/HipHop/HIP_kick_9.wav");
snare.load("snare","/HipHop/HIP_Snare_8.wav");
hihat.load("hihat","/HipHop/HIP_Hat_4.wav");

//[[12,20,50,4],[0,70,80,4],[3,70,90,4],[2,70,100,6],
//[0,40,60,2],[0,70,80,4],[0,70,90,5],[0,70,100,5],
//[12,60,70,5],[0,70,80,4],[0,70,90,5],[0,70,100,6],
//[0,40,60,7],[0,70,80,4],[1,70,90,4],[4,70,100,6]] @=> kick.seq;

//kick.seq @=> serial.seq;

//[[0,20,50,4],[4,70,80,4],[3,70,90,4],[1,50,70,6],
//[12,40,60,2],[0,70,80,4],[0,70,90,5],[0,70,100,5],
//[0,60,70,5],[0,70,80,4],[2,70,90,5],[0,70,100,6],
//[12,40,60,7],[0,70,80,4],[0,70,90,5],[0,70,100,6]] @=> snare.seq;

//[[12,20,50,4],[0,70,80,4],[3,70,90,4],[1,70,100,6],
//[12,40,60,4],[0,70,80,4],[3,70,90,4],[0,70,100,4],
//[12,60,70,4],[0,70,80,4],[1,70,90,5],[0,70,100,6],
//[12,40,60,4],[0,70,80,4],[4,70,90,4],[1,70,100,5]] @=> hihat.seq;



spork~ setButtonStateInit();



spork~ clockCheck();
spork~ pauseCheck();
spork~ setButtonState();
spork~ getButtonState();
spork~ drumChange();
spork~ tempoChange();

spork~ clock.play();
spork~ kick.play(0.5);
spork~ snare.play(0.8);
spork~ hihat.play(0.08);

spork~ appIn();


while(true){
    bpm.measure();
    drum[currentDrum].seq @=> serial.seq;
    10::ms => now;
}


fun void clockCheck(){
    while(true){
        clock.stepChange => now;
        
        clock.getBeat() => int beat;
        serial.send(1,beat,1);
        if(beat + 1 <= 15)serial.send(1,beat +1, 0);
        else serial.send(1,0,0);
        
        //<<<"change ", clock.beat, " , ", beat >>>;
    }
}

fun void pauseCheck(){
    while(true){
        clock.pause => now;
        serial.send(1,clock.getBeat(),0);
        //<<<"off lights at ", clock.getBeat()>>>;
    }
    
}

fun void setButtonStateInit(){
    drum[currentDrum].determiner => now;
    <<<"determine">>>;
    for(0 => int i; i < 16; i++){
        serial.send(0,i,drum[currentDrum].settings[i][1]$int);
    }
}

fun void setButtonState(){
    while(true){
        drum[currentDrum].determiner => now;
        //scale the beat info to flip the values
        Std.scalef(clock.beat, 0, 15, 15, 0)$int => int beat;
        //Note that both beat and clock.beat are being sent
        //I think it could be switched. This is done due to the
        //reversal of data when sending to the interface
        serial.send(0,beat,drum[currentDrum].settings[clock.beat][1]$int);
        //<<<beat, ",",kick.settings[beat][1] >>>;
    }
}

fun void getButtonState(){
    while(true){
        serial.buttonPressed => now;
        
        serial.moduleNum => int moduleNum;
        drum[currentDrum].settings[moduleNum][1]$int=> int flip;
        !flip => drum[currentDrum].settings[moduleNum][1];
        //<<<"button pressed", serial.moduleNum, kick.settings[moduleNum][1]$int, flip>>>;    
    }    
}

fun void drumChange(){
    while(true){
        serial.drumChange => now;
        
        serial.encoderSelect => currentDrum;
        <<<drum[currentDrum].name>>>;
        osc.oscOut("/drum", drum[currentDrum].name);
        for(0 => int i; i < 16; i++){
            serial.send(0,i,drum[currentDrum].settings[i][1]$int);
        }    
    }
}

fun void tempoChange(){
    while(true){
        serial.tempoChange => now;
        serial.encoderTempo => bpm.tempo;
    }
}

fun void appIn(){
    // infinite event loop
    // create an address in the receiver
    osc.oin.addAddress( "/tempo, i" );
    while ( true )
    {
        // wait for event to arrive
        osc.oin => now;
        
        // grab the next message from the queue. 
        while ( osc.oin.recv(osc.msg) != 0 )
        { 
            //Play/Pause
            if(osc.msg.address == "/tempo"){
                <<< "OSC tempo: ", osc.msg.getInt(0) >>>;
                Std.clamp(osc.msg.getInt(0), 1, 200) => bpm.tempo => serial.encoderTempo;
                bpm.measure();
            }
        }
    }
}