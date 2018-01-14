public class OSC {
    
    OscOut osc;
    osc.dest("localhost", 54322);
    // create our OSC receiver
    OscIn oin;
    OscMsg msg;
    54321 => oin.port;
    
    
    // osc sending function
    //overloaded funtions for sending different types of data
    fun void oscOut(string addr, int val) {
        osc.start(addr);
        osc.add(val);
        osc.send();
    }
    
    fun void oscOut(string addr, int val[]) {
        osc.start(addr);
        for(0 => int i; i < val.size(); i++){
            osc.add(val[i]);
        }
        osc.send();
    }
    
    fun void oscOut(string addr, string val) {
        osc.start(addr);
        osc.add(val);
        osc.send();
    }
    
    
}