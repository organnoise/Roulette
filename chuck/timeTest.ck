1::second => dur x;



fun void timer(){
    while (true){
        1.0/3.0 => float x;
        x::second => now;
        <<<x>>>;
    }
}

spork~ timer();

int i;
while(true){
    1::second => now;
    <<< "1 second" >>>;
    
}