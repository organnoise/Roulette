//Example code
//for using 2 buttons, 2 pots, and ir sensor

// setting up pins
const int button[] = {5,6};
const int pots[] = {0,1};
const int irSensor = 4;

// Size variables
const int numButtons = 2;
const int numPots = 2;

// State Variables
int btnState[numButtons]; 
int potState[numPots];
int irState;

void setup() {
  for (int i = 0; i < numButtons; i++)
  {
    pinMode(button[i], INPUT); // set btns to input
    btnState[i] = 0; // initialize
  }
  Serial.begin(9600); 
 
}

void loop() {
  // Get Data
  buttons();
  rotary();
  sensor();
// Serial Printing
  serialPrint();
}


void buttons()
{
  for (int i = 0; i < numButtons; i++)
  {
     btnState[i] = digitalRead(button[i]);
  }
}

void rotary()
{
 for (int i = 0; i < numPots; i++)
  {
     potState[i] = analogRead(pots[i]);
  }
}


void sensor() 
{
  // Sensor Data Reading

  // ir
  irState = analogRead(irSensor);
  irState = map(irState, 40,550, 0,1023);
  irState = constrain(irState, 0, 1023);
 // deal with signal here in future
}

void serialPrint()
{
  // pot1, pot2, btn1, btn2, ir 
  
  Serial.print("[");
  for (int i = 0; i < numPots; i++)
  {
    Serial.print(potState[0]);
    Serial.print(",");
  }
  for (int i = 0; i < numPots; i++)
  {
   Serial.print(btnState[0]);
    Serial.print(",");
  }
  Serial.print(irState);
  Serial.print("]");
  Serial.print("\n");
  
}
  

