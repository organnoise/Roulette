int seq[16][4];

[[12,20,50,4],[0,70,80,4],[3,70,90,4],[2,70,100,6],
[0,40,60,2],[0,70,80,4],[0,70,90,5],[0,70,100,5],
[12,60,70,5],[0,70,80,4],[0,70,90,5],[0,70,100,6],
[0,40,60,7],[0,70,80,4],[1,70,90,4],[4,70,100,6]] @=> seq;

string presetStatus;

"[\n" => presetStatus;

for(int i; i < seq.size(); i++){
    "[" +=> presetStatus;
    for(int j; j < seq[0].size(); j++){
        Std.itoa(seq[i][j]) +=> presetStatus;
        if(j < seq[0].size() - 1) "," +=> presetStatus;
    }
    "]" +=> presetStatus;
    
    if (i < seq.size() - 1) {
        "," +=> presetStatus;
        if (i % 4 == 3 && i != 0) "\n" +=> presetStatus;
    }
}
"\n]" +=> presetStatus;

<<<presetStatus>>>;