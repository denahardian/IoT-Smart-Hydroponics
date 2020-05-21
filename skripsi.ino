#include <OneWire.h>

#define StartConvert 0
#define ReadTemperature 1
#define Offset 0.00            //deviation compensate
#define samplingInterval 20
#define ArrayLenth  40        //times of collection
#define samplingInterval 20
//#define printInterval 800

#define pinPH A0            //pH meter Analog output to Arduino Analog Input 0
#define pinEC A1
#define pinSuhu 2

int pHArray[ArrayLenth];      //Store the average value of the sensor feedback
int pHArrayIndex = 0;
const byte numReadings = 20;   //the number of sample times
unsigned int AnalogSampleInterval = 25, printInterval = 700, tempSampleInterval = 850; //analog sample interval;serial print interval;temperature sample interval
unsigned int readings[numReadings];      // the readings from the analog input
byte index = 0;                          // the index of the current reading
unsigned long AnalogValueTotal = 0;                  // the running total
unsigned int AnalogAverage = 0, averageVoltage = 0;             // the average
unsigned long AnalogSampleTime, printTime, tempSampleTime;
float temperature, ECcurrent, ppm, pHValue, voltage = 0;
String JSON;

//Temperature chip i/o
OneWire ds(pinSuhu);      // on digital pin 2

void setup() {
  // EC Meter:
  Serial.begin(115200);
  for (byte thisReading = 0; thisReading < numReadings; thisReading++) {
    readings[thisReading] = 0;
  }
  TempProcess(StartConvert);   //let the DS18B20 start the convert
  AnalogSampleTime = millis();
  printTime = millis();
  tempSampleTime = millis();
}

void loop() {
  // put your main code here, to run repeatedly:
  // Bagian EC meter
  if (millis() - AnalogSampleTime >= AnalogSampleInterval)
  {
    AnalogSampleTime = millis();
    AnalogValueTotal = AnalogValueTotal - readings[index];
    readings[index] = analogRead(pinEC);
    AnalogValueTotal = AnalogValueTotal + readings[index];
    index = index + 1;
    if (index >= numReadings) {
      index = 0;
    }
    AnalogAverage = AnalogValueTotal / numReadings;
  }

  //Bagian suhu
  if (millis() - tempSampleTime >= tempSampleInterval)
  {
    tempSampleTime = millis();
    temperature = TempProcess(ReadTemperature);  // read the current temperature from the  DS18B20
    TempProcess(StartConvert);                   //after the reading,start the convert for next reading
  }
  /*
    Every once in a while,print the information on the serial monitor.
  */
  if (millis() - printTime >= printInterval)
  {
    printTime = millis();
    averageVoltage = AnalogAverage * (float)5000 / 1024;

    float TempCoefficient = 1.0 + 0.0185 * (temperature - 25.0); //temperature compensation formula: fFinalResult(25^C) = fFinalResult(current)/(1.0+0.0185*(fTP-25.0));
    float CoefficientVolatge = (float)averageVoltage / TempCoefficient;


    pHArray[pHArrayIndex++] = analogRead(pinPH);
    if (pHArrayIndex == ArrayLenth)pHArrayIndex = 0;
    voltage = avergearray(pHArray, ArrayLenth) * 5.0 / 1024;
    pHValue = 3.5 * voltage + Offset;



    if (CoefficientVolatge < 150) {
//      Serial.println("No solution!"); //25^C 1413us/cm<-->about 216mv  if the voltage(compensate)<150,that is <1ms/cm,out of the range
      ECcurrent = 0;
      ppm = 0;
    }
    else if (CoefficientVolatge > 3300) {
      ECcurrent = 0;
      ppm = 0;
//      Serial.println("Out of the range!"); //>20ms/cm,out of the range
    }
    else
    {
      if (CoefficientVolatge <= 448){
        ECcurrent = 6.84 * CoefficientVolatge - 64.32; //1ms/cm<EC<=3ms/cm
      }
      else if (CoefficientVolatge <= 1457){
        ECcurrent = 6.98 * CoefficientVolatge - 127; //3ms/cm<EC<=10ms/cm
      }
      else {
        ECcurrent = 5.3 * CoefficientVolatge + 2278; //10ms/cm<EC<20ms/cm
      }
      ECcurrent /= 1000;  //convert us/cm to ms/cm
      ppm = ECcurrent / 0.00156;
    }
    
    JSON = "{\"data\": {";
    JSON += "\"temp\":";
    JSON += temperature;
    JSON += ",\"EC\":";
    JSON += ECcurrent;
    JSON += ",\"ppm\":";
    JSON += ppm;
    JSON += ",\"ph\":";
    JSON += pHValue;
    JSON += "}}";
    Serial.println(JSON);

  }
  //  static unsigned long samplingTime = millis();
  //  static unsigned long printTime = millis();
  //  static float pHValue, voltage;
  //  if (millis() - samplingTime > samplingInterval)
  //  {
  //    pHArray[pHArrayIndex++] = analogRead(pinPH);
  //    if (pHArrayIndex == ArrayLenth)pHArrayIndex = 0;
  //    voltage = avergearray(pHArray, ArrayLenth) * 5.0 / 1024;
  //    pHValue = 3.5 * voltage + Offset;
  //    samplingTime = millis();
  //  }
  //  if (millis() - printTime > printInterval)  //Every 800 milliseconds, print a numerical, convert the state of the LED indicator
  //  {
  //    Serial.print("pH : ");
  //    Serial.println(pHValue, 2);
  //    printTime = millis();
  //  }
}


float TempProcess(bool ch)
{
  //returns the temperature from one DS18B20 in DEG Celsius
  static byte data[12];
  static byte addr[8];
  static float TemperatureSum;
  if (!ch) {
    if ( !ds.search(addr)) {
      Serial.println("no more sensors on chain, reset search!");
      ds.reset_search();
      return 0;
    }
    if ( OneWire::crc8( addr, 7) != addr[7]) {
      Serial.println("CRC is not valid!");
      return 0;
    }
    if ( addr[0] != 0x10 && addr[0] != 0x28) {
      Serial.print("Device is not recognized!");
      return 0;
    }
    ds.reset();
    ds.select(addr);
    ds.write(0x44, 1); // start conversion, with parasite power on at the end
  }
  else {
    byte present = ds.reset();
    ds.select(addr);
    ds.write(0xBE); // Read Scratchpad
    for (int i = 0; i < 9; i++) { // we need 9 bytes
      data[i] = ds.read();
    }
    ds.reset_search();
    byte MSB = data[1];
    byte LSB = data[0];
    float tempRead = ((MSB << 8) | LSB); //using two's compliment
    TemperatureSum = tempRead / 16;
  }
  return TemperatureSum;
}


double avergearray(int* arr, int number) {
  int i;
  int max, min;
  double avg;
  long amount = 0;
  if (number <= 0) {
    Serial.println("Error number for the array to avraging!/n");
    return 0;
  }
  if (number < 5) { //less than 5, calculated directly statistics
    for (i = 0; i < number; i++) {
      amount += arr[i];
    }
    avg = amount / number;
    return avg;
  } else {
    if (arr[0] < arr[1]) {
      min = arr[0]; max = arr[1];
    }
    else {
      min = arr[1]; max = arr[0];
    }
    for (i = 2; i < number; i++) {
      if (arr[i] < min) {

        amount += min;      //arr<min
        min = arr[i];
      } else {
        if (arr[i] > max) {
          amount += max;  //arr>max
          max = arr[i];
        } else {
          amount += arr[i]; //min<=arr<=max
        }
      }//if
    }//for
    avg = (double)amount / (number - 2);
  }//if
  return avg;
}
