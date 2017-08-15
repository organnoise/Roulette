// classTester.ck

// Composition Files

interfaceTemplate myInstrument;

// initialize instrument
myInstrument.initSerial();
2::second => now;
myInstrument.initOsc();
myInstrument.initSignalCondition();


// MOVE THIS -- This will be the Art part
while (true)
{
    <<< myInstrument.data[0], "\t",  myInstrument.data[1], "\t", myInstrument.data[2], "\t", myInstrument.sensorClean[1], "\t", myInstrument.data[4], "\t", myInstrument.sensorClean[2] >>>;
    
    myInstrument.midiSensor(2, myInstrument.data[2]);
    myInstrument.midiToggle(0, myInstrument.data[0]);
    
    .05::second => now;
}
