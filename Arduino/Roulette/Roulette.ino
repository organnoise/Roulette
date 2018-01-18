#include <Mux.h>
#include <Wire.h>
#include <Adafruit_PWMServoDriver.h>


Adafruit_PWMServoDriver orgLED = Adafruit_PWMServoDriver(0x40);
Adafruit_PWMServoDriver bluLED = Adafruit_PWMServoDriver(0x41);

//Mux mux[4] <--NEEDS TO BE THIS, ONCE YOU HAVE PROPERLY CONNECTTED EVERYTHING
/*
  Index of Mux inputs:
  0 - POT
  1 - X
  2 - Y
  3 - BUTTON
*/

//enum muxType {
//  pot,
//  x,
//  y,
//  butt
//  };

Mux mux[4]; // ...or construct now, and call setup later

#define NUM_MODULES 16
#define NUM_BUTTONS 17
#define NUM_LED 16
#define NUM_SLIDERS 3

//Incoming Serial Bytes
char bytes[3];
// constants won't change. They're used here to
// set pin numbers:
//const int buttonPin[] = {7, 6, 5, 4, 3, 2, 15, 14}; // the number of the pushbutton pin

//BUTTONS::
// Variables that will change:
int encButton = 17;
int encLED[] = {26, 25};
int buttonState[NUM_BUTTONS];             // the current reading from the input pin
int ledState[2][NUM_BUTTONS];
int lastButtonState[NUM_BUTTONS];   // the previous reading from the input pin
int reading[NUM_BUTTONS];
unsigned long lastDebounceTime[NUM_BUTTONS];  // the last time the output pin was toggled
unsigned long debounceDelay = 50;    // the debounce time; increase if the output flickers

//PWM FADE
float fadeVal[2][NUM_BUTTONS];
const int pwmInterval = 25;
int pwmIntervals[2][NUM_BUTTONS];
float R;

//POTS::
// for helping with smoothing pot data
const int numReadings = 8;
int potValues[numReadings];


//Mux reading arrays to be populated
int sliders[3][NUM_MODULES];
unsigned long pMillis_Sliders[3][NUM_MODULES];
int currentPotVal[3][NUM_MODULES];
int prevPotVal[3][NUM_MODULES];
int thresh[3][NUM_MODULES];
/*
  [0][16] = pots
  [1][16] = joyX
  [2][16] = joyY
*/
unsigned long interval = 50;

//these pins can not be changed 2/3 are special pins
int encoderPin1 = 36;
int encoderPin2 = 37;
volatile int lastEncoded = 0;
volatile long encoderValue[2];
bool encoderChange[2] = {false, false};


void setup() {

  // Calculate the R variable (only needs to be done once at setup)
  R = (pwmInterval * log10(2)) / (log10(1023));

  pinMode(encoderPin1, INPUT);
  pinMode(encoderPin2, INPUT);
  //digitalWrite(buttonPin[0], HIGH); //turn pullup resistor on
  digitalWrite(encoderPin1, HIGH); //turn pullup resistor on
  digitalWrite(encoderPin2, HIGH); //turn pullup resistor on
  //call updateEncoder() when any high/low changed seen
  //on interrupt 0 (pin 2), or interrupt 1 (pin 3)
  attachInterrupt(4, updateEncoder, CHANGE);
  attachInterrupt(5, updateEncoder, CHANGE);
  pinMode(encButton, INPUT_PULLUP);

  Serial.begin(115200);
  mux[0].setup(7, 6, 5, 4, A1);
  mux[1].setup(11, 10, 9, 8, A2);
  mux[2].setup(15, 14, 13, 12, A3);
  mux[3].setup(23, 22, 21, 20, A4);

  bluLED.begin();
  orgLED.begin();
  bluLED.setPWMFreq(490);  // Analog servos run at ~60 Hz updates
  orgLED.setPWMFreq(490);

  for (int i = 0; i < NUM_BUTTONS; i++) {
    // pinMode(buttonPin[i], INPUT);
    lastButtonState[i] = LOW;
    lastDebounceTime[i] = 0;
    reading[i] = 0;
    bluLED.setPWM(i, 0, uint16_t(0));
    orgLED.setPWM(i, 0, uint16_t(0));
  }

  yield();
}

void loop() {
  serialRead();
  updateButton();
  updatePot();
  updateLED();
  updateEncLED();
  change();
}

//UPDATE::
void updateButton() {
  for (int i = 0; i < NUM_BUTTONS; i++) {
    // read the state of the switch into a local variable:
    if (i == 16) {
      reading[i] = digitalRead(encButton);
    }
    else {
      reading[i] = (mux[3].read(i)) >> 9;
    }
    // check to see if you just pressed the button
    // (i.e. the input went from LOW to HIGH),  and you've waited
    // long enough since the last press to ignore any noise:

    // If the switch changed, due to noise or pressing:
    if (reading[i] != lastButtonState[i]) {
      // reset the debouncing timer
      lastDebounceTime[i] = millis();
    }

    if ((millis() - lastDebounceTime[i]) > debounceDelay) {
      // whatever the reading is at, it's been there for longer
      // than the debounce delay, so take it as the actual current state:

      // if the button state has changed:
      if (reading[i] != buttonState[i]) {
        buttonState[i] = reading[i];
        if (i == 16) serialPrint(3, i, !buttonState[i]);
        else serialPrint(3, i, buttonState[i]);
        if (buttonState[i] == HIGH) {
          ledState[0][i] = !ledState[0][i];
        }
      }
    }
    //PWM FADE
    if (i != 16) fade(0, i, bluLED);

    // save the reading.  Next time through the loop,
    // it'll be the lastButtonState:
    lastButtonState[i] = reading[i];
  }
}

void updateLED() {
  for (int i = 0; i < NUM_BUTTONS; i++) {
    fade(1, i, orgLED);
  }
  //analogWrite(encLED[0], encoderValue[0]);
  //analogWrite(encLED[1], encoderValue[1]);
}
void updateEncLED() {

  if (bytes[0] == 2) {
    analogWrite(encLED[int(bytes[1])], int(bytes[2]));
  }
}
void fade(int which, int i, Adafruit_PWMServoDriver ledDriver) {
  //This way of fading the LEDs should cause less blocking than a "for loop"
  if (ledState[which][i] == HIGH && fadeVal[which][i] < 1023) pwmIntervals[which][i] += 5;
  else if (ledState[which][i] == LOW && fadeVal[which][i] > 0) pwmIntervals[which][i] -= 5;

  //logarithmic scaling
  fadeVal[which][i] = pow (2, (pwmIntervals[which][i] / R)) - 1;

  ledDriver.setPWM(i, 0, uint16_t(fadeVal[which][i]));
  //pwm1.setPWM(i, 0, uint16_t(fadeVal[i]));

}

void updatePot() {
  // compare value (lowpassed pot reading) to current tempo
  // if value is +- 2 from current tempo then update tempo
  int potVal;
  //Slider array
  for (int i = 0; i < NUM_SLIDERS; i++) {
    for (int j = 0; j < NUM_MODULES; j++) {

      //Read pot, and bitshift it to be in the range of 0 - 127
      //this currently helps with all the noise
      currentPotVal[i][j] = mux[i].read(j) >> 3;
      thresh[i][j] = abs(currentPotVal[i][j] - prevPotVal[i][j]);

      //If timer has past its interval length continue
      if (millis() - pMillis_Sliders[i][j] > interval) {
        pMillis_Sliders[i][j] = millis();

        //If the delta value is large enough print the value
        //this should help decrease noise
        if (thresh[i][j] > 1) {
          //update prevPotVal
          prevPotVal[i][j] = currentPotVal[i][j];
          potVal = prevPotVal[i][j];
          //Store pot value in array
          sliders[i][j] = potVal;
          //Only serial print if data has changed
          serialPrint(i, j, potVal);
        }

      }
    }
  }
}

//SERIAL::
void serialPrint(int section, int member, int data) {
  Serial.print("[");
  Serial.print(section);
  Serial.print(",");
  Serial.print(member);
  Serial.print(",");
  Serial.print(data);
  Serial.println("]");
}


void updateEncoder() {
  int MSB = digitalRead(encoderPin1); //MSB = most significant bit
  int LSB = digitalRead(encoderPin2); //LSB = least significant bit

  int encoded = (MSB << 1) | LSB; //converting the 2 pin value to single number
  int sum  = (lastEncoded << 2) | encoded; //adding it to the previous encoded value

  if (ledState[0][16] == HIGH) {
    if (sum == 0b1101 || sum == 0b0100 || sum == 0b0010 || sum == 0b1011) {
      // 2 means up
      encoderValue[0] = 2;
    }
    if (sum == 0b1110 || sum == 0b0111 || sum == 0b0001 || sum == 0b1000) {
      // 1 means down (1 an 0 were causing serial print issues)
      encoderValue[0] = 1;
    }
    //Signal change()
    encoderChange[0] = true;
    //serialPrint(4, 0, encoderValue[0]);
  }
  else {
    if (sum == 0b1101 || sum == 0b0100 || sum == 0b0010 || sum == 0b1011) {
      encoderValue[1] ++;
    }
    if (sum == 0b1110 || sum == 0b0111 || sum == 0b0001 || sum == 0b1000) {
      encoderValue[1] --;
    }
    //Signal change()
    encoderChange[1] = true;
    //serialPrint(4, 1, encoderValue[1]);
  }
  encoderValue[0] = constrain(encoderValue[0], 0, 255);
  encoderValue[1] = constrain(encoderValue[1], 0, 255);

  lastEncoded = encoded; //store this value for next time
}

//serial print encoder info in the main loop
void change() {
  if (encoderChange[0]) {
    serialPrint(4, 0, encoderValue[0]);
    encoderChange[0] = false;
  }
  else if(encoderChange[1]){
    serialPrint(4, 1, encoderValue[1]);
    encoderChange[1] = false;
    }

}

void serialRead() {
  if (Serial.available() ) {
    if (Serial.read() == 0xff) {
      Serial.readBytes(bytes, 3);
      if (bytes[0] < 2) {
        if (ledState[int(bytes[0])][int(bytes[1])] != int(bytes[2])) {
          ledState[int(bytes[0])][int(bytes[1])] = int(bytes[2]);
        }
      }
    }
  }
}
