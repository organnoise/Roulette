RouletteSerial serial;

serial.setup(2);

spork~ serial.loop();

while(true){
    1:: second => now;
    }