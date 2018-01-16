1::second => dur x;



fun void timer(){
    <<<"start ", x/second>>>;
    x => now;
    <<<"done ", x/second>>>;
}

spork~ timer();

int i;
while(true){
    i++;
    
    //i :: second => x;
    <<< x /second >>>;
    .125::second => now;
    
    }