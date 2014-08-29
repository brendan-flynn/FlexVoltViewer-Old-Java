import processing.core.*; 
import processing.data.*; 
import processing.event.*; 
import processing.opengl.*; 

import processing.serial.*; 
import java.awt.AWTException; 
import java.awt.Robot; 

import java.util.HashMap; 
import java.util.ArrayList; 
import java.io.File; 
import java.io.BufferedReader; 
import java.io.PrintWriter; 
import java.io.InputStream; 
import java.io.OutputStream; 
import java.io.IOException; 

public class FlexVoltViewer extends PApplet {

//  Author:  Brendan Flynn - FlexVolt
//  Date Modified:    14 Aug 2014
/*  FlexVolt Viewer v1.2.1-bugfix
 
 Recent Changes:
 Add Linux communication
 Fix data save
 
 
 Description:
 Processing sketch for visualization of data measured using a FlexVolt sensor
 
 Uses the USB-serial (or Bluetooth-serial) port emulator to receive data and adjust settings on the FlexVolt
 
 Exportable to stand-alone executable program file for Windows and Mac using Processing 2.1.2
 
 To Run this Sketch:
 
 1.  Download Processing - www.processing.org
 Processing is free (donations optional)
 2.  Expand the compressed folder when finished downloading.
 3.  Place the folder where you like
 4.  Download FlexVoltViewer_release_v1_x.pde (this file) from www.flexvoltbiosensor.com
 5.  Open the sketch in Processing.  Click play (ctrl-r).
 6.  Connect your FlexVolt, click Reset (under "Connection")
 
 For FAQ and troubleshooting, go to www.flexvoltbiosensor.com/software
 
 */

// imports




// interface to wrap all page objects
public interface pagesClass {
  public void switchToPage(); // anything that should be done during switch to this page
  public void drawPage(); // 
  public boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev);
  public void useSerialEvent(); // may not need this one
  public void drawHelp(); //
  public String getPageName(); // return title
  public void initializeButtons();
}

// To add a page:
//
///************************* BEGIN Example Page ***********************/
//public class ExamplePage implements pagesClass{
//  // variables
//  
//  // constructor
//  ExamplePage(){
//    // set input variables
//    
//  }
//  
//  void switchToPage(){
//    
//  }
//
//  void drawPage(){
//    // draw subfunctions
//  }
//
//  String getPageName(){
//    return pageName;
//  }
//  
//  boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev){
//  if (inputDev == mouseInput){
//    handle mouse inputs using x,y
//  } else if (inputDev == keyInput){
//    handle key inputs using key and keyCode
//  }
//  }
//  
//  void useSerialEvent(){
//    if (dataflag) {
//    byte[] inBuffer = new byte[serialBufferN];
//    while (myPort.available () > serialBufferN) {
//      int inChar = myPort.readChar(); // get ASCII
//      if (inChar != -1) {
//        serialReceivedFlag = true;
//        if (inChar == 'C' || inChar == 'D' || inChar == 'E' || inChar == 'F') {
//          myPort.readBytes(inBuffer);
//          // do stuff
//        }
//      }
//    }
//  }
//  
//  void drawHelp(){
//    // help text
//  }
//}
///************************* END EXAMPLE PAGE ***********************/


// Constants
String viewerVersion = "v1.2";
String homePath = System.getProperty("user.home"); // default path to save settings files
String folder = "";
Serial myPort;
//String RENDERMODE = "P2D";
int currentWidth;
int currentHeight;
int fullPlotWidth = 500;
int plotwidth = fullPlotWidth;
int halfPlotWidth = fullPlotWidth/2;
int plotheight = 300;
int plot2offset = 5;
int xx, yy;
int xStep = 60;
int yStep = 40;
int yTitle = 70;
int barWidth = 100;

int serialBufferN = 5;
int serialBurstN = 2;
int serialPortSpeed = 230400;
int serialwritedelay = 50;

// font sizes
int axisnumbersize = 16;
int labelsize = 20;
int labelsizes = 16;
int labelsizexs = 14;
int titlesize = 26;
int buttontextsize = 16;

// Robot is used to move the computer mouse pointer
Robot robot;

// GUi Class Objects //
// Buttons
GuiButton[] buttonsCommon;
int buttonNumberCommon = 0;
int
bcsettings = buttonNumberCommon++, 
bchelp = buttonNumberCommon++, 
bcrecordnextdata = buttonNumberCommon++, 
bcplotdomain = buttonNumberCommon++, 
bctraindomain = buttonNumberCommon++, 
bcmousedomain = buttonNumberCommon++, 
bcsnakedomain = buttonNumberCommon++, 
bcmusicdomain = buttonNumberCommon++, 
bcserialreset = buttonNumberCommon++, 
bcsave = buttonNumberCommon++;


int bheight = 25; // button height
int bheights = 20; // button height

float fps = 30;
int scaleVoltage = 1;
float maxVoltage = 10/scaleVoltage;
float minVoltage = -10/scaleVoltage;
float signalAmplifierGain = 1845; // 495 from Instrumentation Amp, 3.73 from second stage.  1845 total.
float signalDynamicRange = 1.355f;//mV.  5V max, split around 2.5.  2.5V/1845 = 1.355mV.
float signalResolution = signalDynamicRange/1024;// mV, 1.355mV/1024 = 1.3uV.  NOTE - resolution is likely worse than this - most ADCs' botton 2-3 bits are just noise.  10uV is a more reasonable estimate
int maxSignalVal = 512;//1024 / 2 (-512 : +512);
int halfSignalVal = 512; // same
int nXTicks = 5;
int nYTicks = 4;
int nYTicksHalf = 2;
int maxSignalLength = 1000;
int signalLengthFFT = 1024;
int pointThickness = 3;
int ytmp;
int nMedianFilt = 3;

// Register variables and constants
int[] userFreqArray = {  
  1, 10, 50, 100, 200, 300, 400, 500, 1000, 1500, 2000
};
int userFreqIndexTraining = 7;
int userFreqIndexMouse = 7;
int userFreqIndexFFT = 8;
int userFreqIndexDefault = 7;
int userFreqIndex = userFreqIndexDefault;
int userFrequency = userFreqArray[userFreqIndex];//40;//1000;
int userFreqCustom = 0;
int userFreqCustomMax = 4000;
int userFreqCustomMin = 0;
int smoothFilterVal = 8;
int smoothFilterValDefault = 8;
int smoothFilterValMin = 0, smoothFilterValMax = 50;
int timer0PartialCount = 0;
Boolean bitDepth10 = true;
int timer0AdjustVal = 2;
int timer0AdjustValMin = -5;
int timer0AdjustValMax = 248;
int prescalerPic = 2;
int prescalerPicMin = 0;
int prescalerPicMax = 2;
int downSampleCount = 1;
int downSampleCountMax = 100;
int downSampleCountMin = 0;
int downSampleCountTraining = 5;
int downSampleCountMouse = 5;

// Colors
int colorBOutline = color(0);
int colorBIdle = color(160);
int colorbOn = color(100);
int colorBPressed = color(70);
int colorSig1 = color(255, 0, 0);//red
int colorSig2 = color(0, 255, 0);//green
int colorSig3 = color(0, 0, 255);//blue
int colorSig4 = color(255, 128, 0);//orange
int colorSig5 = color(0, 255, 255);//cyan
int colorSig6 = color(255, 255, 0);//yellow
int colorSig7 = color(255, 0, 255);//fushcia
int colorSig8 = color(255, 255, 255);//white
int colorSigM[] = {  
  colorSig1, colorSig2, colorSig3, colorSig4, colorSig5, colorSig6, colorSig7, colorSig8
};
int colorFFT = color(255, 255, 0);
int colorLabel = color(0);
int colorPlotBackground = color(100);
int colorPlotOutline = color(0);
int colorBackground = color(200);

// FFT variables
FFTutils fft;
FIRFilter filter1, filter2;
float[] filtered;
float[][] fft_result;//1, fft_result2, fft_result3, fft_result4;
float[][] SignalInFFT; // longer for FFT calculation


//int xPos = 0;
float[][] signalIn;//1, signalIn2, signalIn3, signalIn4;
int[] oldPlotSignal;



float maxPlotTime = PApplet.parseFloat(fullPlotWidth)/PApplet.parseFloat(userFrequency);
int datacounter = 0;
int signalindex = 0;
int currentSignalNumber = 4;
int maxcurrentSignalNumber = 8;
long[] timeStamp;
long buttonColorTimer = 0;
long buttonColorDelay = 100;

int checkSerialNSamples = 2;
int checkSerialMinTime = 500;
long checkSerialDelay = (long)max( checkSerialMinTime, 1000.0f/((float)userFrequency/checkSerialNSamples) );//2000;//userFrequency/10; // millis. check at 10Hz
int calibrateN = 50;
int calibrateCounter = calibrateN;
int calibration[] = {  
  0, 0, 0, 0, 0, 0, 0, 0
};

// GUI variables
int currentbuttonCommon = -1;
int currentbutton = -1;
int currentpage;
int dummypage = -1;
int oldpage;
int imagesavecounter = 1;

// data recording
int[][] recordData;
int recordDataCols = 9;
int recordDataTime = 5; // seconds
int recordDataLength = recordDataTime*userFrequency;
int recordDataIndex = 0;
int recordDataedCounter = 0;
int recordDatamaxPlotTime = 50;
int recordDataTimeMin = 1;

/*********** Page Variables ************/
// any page variables that require access for saving and loading should go here

// MouseVariables
int thresh2chxLow = 0, thresh2chxHigh = 1, thresh2chyLow = 2, thresh2chyHigh = 3,
    thresh2chaux1Low = 4, thresh2chaux1High = 5, thresh2chaux2Low = 6, thresh2chaux2High = 7,
    thresh2chaux3Low = 8, thresh2chaux3High = 9, thresh2chaux4Low = 10, thresh2chaux4High = 11,
    thresh2chaux5Low = 12, thresh2chaux5High = 13, thresh2chaux6Low = 14, thresh2chaux6High = 15;
int thresh4chLeft = 0, thresh4chRight = 1, thresh4chDown = 2, thresh4chUp = 3, thresh4chaux1 = 4, thresh4chaux2 = 5, thresh4chaux3 = 6, thresh4chaux4 = 7;
int tmpL = maxSignalVal*5/4, tmpH = maxSignalVal * 6/4;
int mouseThresh2Ch[] = {    
  tmpL, tmpH, tmpL, tmpH, tmpL, tmpH, tmpL, tmpH, tmpL, tmpH, tmpL, tmpH, tmpL, tmpH, tmpL, tmpH
};// xlow, xhigh, ylow, yhigh, aux1low, aux1high, aux2low, aux2high, aux3low, aux3high, aux4low, aux4high, aux5low, aux5high, aux6low, aux6high
int mouseThresh4Ch[] = {    
  tmpH, tmpH, tmpH, tmpH, tmpH, tmpH, tmpH, tmpH
};// left, right, up, down, aux1, aux2, aux3, aux4
int[] mouseChan = {    
  0, 1, 2, 3, 4, 5, 6, 7
};

// Frequency variables
int maxPlotFrequency = 200;
/*********** End Page Variables ************/

// Flags
boolean initializeFlag = true;
boolean dataflag = false;
boolean pauseFlag = false;
boolean offsetFlag = false;
boolean smoothFilterFlag = false;
boolean buttonPressedFlag = false;
boolean bOnOff = false;
boolean bMomentary = true;
boolean channelsOn[]= {  
  true, true, true, true, false, false, false, false
};
boolean recordDataFlag = false;
boolean medianFilter = false;
boolean plugTestFlag = false;
boolean helpFlag = false;
boolean dataRegWriteFlag = false;
boolean snakeGameFlag = false;
boolean commentflag = true;
boolean communicationsflag = false;
boolean hideButton = true;
boolean showButton = false;

int plugTestDelay = 0;
int testcounter = 0;

long startTime = System.nanoTime();
// ... the code being measured ...
long estimatedTime = System.nanoTime() - startTime;
long endTime;

int initializeCounter = 0;
int xMIN;
int xMAX;
int yMIN;
int yMAX;

//String[] usbPORTs = new String[0];
//String[] bluetoothPORTs = new String[0];

PImage img;

int nVersionBuffer = 4;
int VERSION;
int SERIALNUMBER;
int MODELNUMBER;

SerialPortObj FVserial;

ArrayList<pagesClass> FVpages;
int settingspage, timedomainpage, frequencydomainpage, workoutpage, targetpracticepage, snakegamepage, musclemusicpage;
int keyInput = 1;
int mouseInput = 2;

public void setup () {
  println("Homepath = "+homePath);
  FVpages = new ArrayList<pagesClass>();
  int tmpindex = 0;
  FVpages.add(new SettingsPage(this));       
  settingspage = tmpindex++;
  FVpages.add(new TimeDomainPlotPage()); 
  timedomainpage = tmpindex++;
  FVpages.add(new workoutPage());        
  workoutpage = tmpindex++;
  FVpages.add(new TargetPracticePage()); 
  targetpracticepage = tmpindex++;
  FVpages.add(new SnakeGamePage(this));  
  snakegamepage = tmpindex++;
  FVpages.add(new MuscleMusicPage());    
  musclemusicpage = tmpindex++;
  currentpage = timedomainpage;

  initializeEverything();

  frame.setResizable(true);
  frame.setTitle("FlexVolt Viewer v1.2");

  //  registerMethod("pre", this);
  //  frame.addComponentListener(new ComponentAdapter() {
  //    public void componentResized(ComponentEvent e) {
  //      if(e.getSource()==frame) {
  //        println("resized");
  //        updateGUISizes();
  //      }
  //    }
  //  });

  frameRate(fps);



  // Setup mouse control robot
  try {
    robot = new Robot();
  }
  catch (AWTException e) {
    e.printStackTrace();
  }

  importSettings();

  img = loadImage("FlexVolt_Image1.png");

  // fft setup
  fft=new FFTutils(signalLengthFFT);
  fft.useEqualizer(false);
  fft.useEnvelope(true, 1);
  fft_result = new float[maxcurrentSignalNumber][signalLengthFFT];
  signalIn = new float[maxcurrentSignalNumber][maxSignalLength];
  SignalInFFT = new float[maxcurrentSignalNumber][signalLengthFFT];
  oldPlotSignal = new int[maxcurrentSignalNumber];

  filter1=new FIRFilter(FIRFilter.LOW_PASS, 2000f, 0, 1000, 60, 3400);
  filter2=new FIRFilter(FIRFilter.HIGH_PASS, 2000f, 20, 10, 60, 3400);

  timeStamp = new long[5000];

  FVserial = new SerialPortObj(this);
}

public void stop() {  // doesn't actually get called on closed, but it should, and hopefully will in future versions!
  if (myPort != null) {
    myPort.write('X');
    myPort.clear();
  }
}

public void initializeEverything() {

  halfPlotWidth = fullPlotWidth/2;
  // set the window size TODO get window size, modify
//  size(fullPlotWidth+barWidth+xStep, plotheight+yStep+yTitle, P2D);
  size(fullPlotWidth+barWidth+xStep, plotheight+yStep+yTitle);
  currentWidth = width;
  currentHeight = height;
  ytmp = height - yStep;
  println("w = "+currentWidth+", h = "+currentHeight+", ytmp = "+ytmp);

  xMIN = xStep+pointThickness;
  xMAX = xStep+fullPlotWidth-pointThickness;
  yMIN = yTitle+pointThickness;
  yMAX = yTitle+plotheight-pointThickness;

  bheight = 25; // button height
  bheights = 20; // button height

  initializeButtons();

  for (int i = 0; i < FVpages.size(); i++) {
    FVpages.get(i).initializeButtons();
  }
}

public void checkResize() {
  if (currentWidth != width || currentHeight != height) {
    boolean backon = false;
    if (dataflag) {
      println("data was on");
      StopData();
      backon = true;
    }
    currentWidth = width;
    currentHeight = height;
    xStep = 60;
    yStep = 40;
    yTitle = 70;
    barWidth = 100;
    fullPlotWidth = width - xStep - barWidth;
    plotheight = height - yTitle - yStep;
    plotwidth = fullPlotWidth;
    halfPlotWidth = fullPlotWidth/2;
    xMIN = xStep+pointThickness;
    xMAX = xStep+fullPlotWidth-pointThickness;
    yMIN = yTitle+pointThickness;
    yMAX = yTitle+plotheight-pointThickness;

    bheight = 25; // button height
    bheights = 20; // button height

    ytmp = height - yStep;
    println("height now = "+plotheight);
    initializeButtons();

    for (int i = 0; i < FVpages.size(); i++) {
      FVpages.get(i).initializeButtons();
    }

    println("labeling GUI, currentpage ="+currentpage);
    labelGUI();
    FVpages.get(currentpage).switchToPage();

    if (backon) {
      establishDataLink();
    }
  }
}

public void initializeButtons() {
  buttonsCommon = new GuiButton[buttonNumberCommon];
  buttonsCommon[bcsettings]       = new GuiButton("Settings", 's', settingspage, xStep+plotwidth+55, yTitle+plotheight+yStep/2, 70, bheight, color(colorBIdle), color(0), "Settings", bMomentary, false, showButton);
  buttonsCommon[bchelp]           = new GuiButton("Help", 'h', dummypage, xStep+plotwidth-35, 30, 25, 25, color(colorBIdle), color(0), "?", bMomentary, false, showButton);
  buttonsCommon[bcsave]           = new GuiButton("Store", 'i', dummypage, xStep+50, 12, 100, 20, color(colorBIdle), color(0), "Save Image", bMomentary, false, showButton);
  buttonsCommon[bcrecordnextdata] = new GuiButton("SaveRecord", 'd', dummypage, xStep+50, 36, 100, 20, color(colorBIdle), color(0), "Record "+recordDataTime+"s", bMomentary, false, showButton);
  buttonsCommon[bcplotdomain]     = new GuiButton("TimePage", 't', timedomainpage, xStep+fullPlotWidth/2-73, yTitle-10, 60, 20, color(colorBIdle), color(0), "Plot Signals", bOnOff, true, showButton);
  buttonsCommon[bctraindomain]    = new GuiButton("workoutPage", 'w', workoutpage, xStep+fullPlotWidth/2+19, yTitle-10, 75, 20, color(colorBIdle), color(0), "workout", bOnOff, false, showButton);
  buttonsCommon[bcmousedomain]    = new GuiButton("MousePage", 'm', targetpracticepage, xStep+fullPlotWidth/2+115, yTitle-10, 110, 20, color(colorBIdle), color(0), "Mouse Games", bOnOff, false, showButton);
  buttonsCommon[bcsnakedomain]    = new GuiButton("SnakeGame", 'n', snakegamepage, xStep+fullPlotWidth/2+115, yTitle-10, 110, 20, color(colorBIdle), color(0), "Snake Game", bOnOff, false, showButton);
  buttonsCommon[bcmusicdomain]    = new GuiButton("MuscleMusic", 'u', musclemusicpage, xStep+fullPlotWidth/2+155, yTitle-10, 110, 20, color(colorBIdle), color(0), "Muscle Music", bOnOff, false, showButton);
  buttonsCommon[bcserialreset]    = new GuiButton("SerialReset", 'r', dummypage, xStep+fullPlotWidth+55, yTitle/2, 60, 20, color(colorBIdle), color(0), "Reset", bMomentary, false, showButton);
  println(fullPlotWidth);
  textSize(buttontextsize);
  int tabpad = 6;
  int tabspace = 5;
  int lengthtotal = 0;
  for (int i = bcplotdomain; i<=bcmusicdomain; i++){
    int tmplength = PApplet.parseInt(textWidth(buttonsCommon[i].label));
    buttonsCommon[i].xsize = tmplength + tabpad;
    println("bsize = "+buttonsCommon[i].xsize);
    lengthtotal += tmplength+tabpad+tabspace;
  }
  lengthtotal -= tabspace;
  lengthtotal /= 2;
  int tmpxpos = xStep + fullPlotWidth/2 - lengthtotal;
  int oldxsize = 0;
  for (int i = bcplotdomain; i<=bcmusicdomain; i++){
    int tmplength = PApplet.parseInt(textWidth(buttonsCommon[i].label));
    tmplength = (tmplength+tabpad)/2;
    tmpxpos +=  tmplength + oldxsize;
    oldxsize = tmplength + tabspace;
    buttonsCommon[i].xpos = tmpxpos;
  }
}


public void draw () {
  if (initializeFlag) {
    initializeCounter ++;
    if (initializeCounter == 1) {
      frame.setLocation(0, 0);//1441
      xx = frame.getX()+2;
      if (platform == MACOSX) {
        yy = frame.getY()+42; // add ace for the mac top bar + the app top bar
      } 
      else if (platform == WINDOWS) {
        yy = frame.getY()+22; // add ace for teh app top bar
      }

      background(colorBackground);

      for (int i = 0; i < buttonsCommon.length; i++) {
        buttonsCommon[i].drawButton();
      }
      FVpages.get(currentpage).switchToPage();
      FVpages.get(currentpage).drawPage();

      labelGUI();

      display_error("Searching for FlexVolt Devices");
    }
    if (initializeCounter >= 2) {
      startTime = System.nanoTime();
      // frame.setLocation(1481, 0);//1441

      initializeFlag = false;
      FVserial.connectserial();// the function will poll devices, set connecting flag, and set current try port index to 0
    }
  }

  checkResize();

  if (buttonPressedFlag) {
    if (millis() > buttonColorTimer) {
      buttonPressedFlag = false;
      println("Current Button = " + currentbutton);
      if (buttonsCommon[currentbuttonCommon] != null && currentbuttonCommon < buttonsCommon.length) {
        buttonsCommon[currentbuttonCommon].changeColorUnpressed();
        labelGUI();
      }
    }
  }

  dataflag = FVserial.manageConnection(dataflag);

  drawRecordIndicator(recordDataFlag);
  
  
  
  if (!helpFlag) {
    FVpages.get(currentpage).drawPage();
  }
}

public void drawRecordIndicator(boolean isrecording){
  fill(150);
  strokeWeight(2);
  stroke(0);
  ellipse(xStep+112, yTitle*1/2, 18, 18);
  fill(color(50, 50, 50));
  if (isrecording) {
    fill(color(255, 0, 0));
  }
  stroke(0);
  ellipse(xStep+112, yTitle*1/2, 10, 10);
}

public void serialEvent (Serial myPort) {
  int tmpfillColor = g.fillColor;
  int tmpstrokeColor = g.strokeColor;
  float tmpstrokeWeight = g.strokeWeight;

  //  println(myPort.available()+"dataflag = "+dataflag+", communicationflag = "+communicationsflag);
  if (!communicationsflag && !dataflag) {
    int inChar = myPort.readChar(); // get ASCII
    if (inChar != -1) {
      FVserial.serialReceivedFlag = true;
      println("handshaking, "+inChar+", count = "+testcounter);
      testcounter++;
      if (inChar == 'x') {
        FVserial.flexvoltfound = true; // this flag tells the SerialPortObj that a flexvolt port has been found. Searching stops, and that port is now connnected
        FVserial.connectingflag = false;
        FVserial.connectionindicator = FVserial.indicator_connecting;
        println("Received the x");
      }
      if (inChar == 'a') {
        FVserial.connectionindicator = FVserial.indicator_connecting;
        myPort.clear();
        myPort.write('1');
        println("1st");
      }
      else if (inChar == 'b') {
        myPort.clear();
        // ConnectingFlag = true;
        FVserial.flexvoltconnected = true;
        FVserial.connectionindicator = FVserial.indicator_connecting;
        updateSettings(); //establishDataLink is rolled in
        println("updated settings");
        communicationsflag = true;
      }
    }
  } 
  else if (communicationsflag && !dataflag) {
    int inChar = myPort.readChar(); // get ASCII
    if (inChar != -1) {
      FVserial.serialReceivedFlag = true;
      println("handshaking, "+inChar+", count = "+testcounter);
      if (inChar == 'g') {
        myPort.clear();
        println("dataflag = true g");
        blankPlot();
        dataflag = true;
        FVserial.connectionindicator = FVserial.indicator_connected;
        myPort.buffer((serialBufferN+1)*serialBurstN);
      }
      else if (inChar == 'y') {
        println("Received 'Y'");
      }
      else if (inChar == 'v') {
        byte[] inBuffer = new byte[nVersionBuffer];
        myPort.readBytes(inBuffer);
        VERSION = inBuffer[0];
        SERIALNUMBER = ((int)inBuffer[1]<<8)+(int)inBuffer[2];
        MODELNUMBER = inBuffer[3];
        println("Version = "+VERSION+". SerailNumber = "+SERIALNUMBER+". MODEL = "+MODELNUMBER);
      }
    }
  }
  else if (dataflag) {
    // Actual Data Acquisition
    byte[] inBuffer = new byte[serialBufferN];
    //    println("avail = "+myPort.available());
    while (myPort.available () > serialBufferN) {
      // println((System.nanoTime()-startTime)/1000);

      //      println(myPort.available());
      int inChar = myPort.readChar(); // get ASCII
      // print("data, ");println(inChar);
      if (inChar != -1) {
        FVserial.serialReceivedFlag = true;

        if (inChar == 'C' || inChar == 'D' || inChar == 'E' || inChar == 'F') {
          myPort.readBytes(inBuffer);
          //          println("Received8bit - "+inChar+", buffer = "+serialBufferN);
          // println(inBuffer);
          for (int i = 0; i < currentSignalNumber; i++) {
            int tmp = inBuffer[i]; // last 2 bits of each signal discarded
            tmp = tmp&0xFF; // account for translation from unsigned to signed
            tmp = tmp << 2; // shift to proper position
            float rawVal = PApplet.parseFloat(tmp);

            if (currentpage == frequencydomainpage) {
              arrayCopy(SignalInFFT[i], 1, SignalInFFT[i], 0, signalLengthFFT-1);
              SignalInFFT[i][signalLengthFFT-1]=rawVal;
            }
            else {
              signalIn[i][signalindex]=rawVal;
            }
            if (recordDataFlag && recordDataIndex < recordDataLength) {
              recordData[i][recordDataIndex]=PApplet.parseInt(rawVal);
            }
          }
          if (recordDataFlag) {
            recordDataIndex++;
            if ((recordDataIndex % 100) == 0) {
              println("Saving " + recordDataIndex + "/" + recordDataLength + "data point");
            }
            if (recordDataIndex >= recordDataLength) {
              recordDataedCounter = saveRecordedData(recordDataedCounter);
              recordDataFlag = false;
            }
          }
          signalindex ++;//= downSampleCount;
          if (signalindex >= maxSignalLength)signalindex = 0;
          datacounter++;
          if (datacounter >= maxSignalLength)datacounter = maxSignalLength;
        }
        else if (inChar == 'H' || inChar == 'I' || inChar == 'J' || inChar == 'K') {
          myPort.readBytes(inBuffer);
          for (int i = 0; i < currentSignalNumber; i++) {
            int tmplow = inBuffer[serialBufferN-1]; // last 2 bits of each signal stored here
            tmplow = tmplow&0xFF; // account for translation from unsigned to signed
            tmplow = tmplow >> (2*(3-i)); // shift to proper position
            tmplow = tmplow & (3); //3 (0b00000011) is a mask.
            int tmphigh = inBuffer[i];
            tmphigh = tmphigh & 0xFF; // account for translation from unsigned to signed
            tmphigh = tmphigh << 2; // shift to proper position
            float rawVal = PApplet.parseFloat(tmphigh+tmplow);
            if (currentpage == frequencydomainpage) {
              arrayCopy(SignalInFFT[i], 1, SignalInFFT[i], 0, signalLengthFFT-1);
              SignalInFFT[i][signalLengthFFT-1]=rawVal;
            }
            else {
              signalIn[i][signalindex]=rawVal;
            }
            if (recordDataFlag && (recordDataIndex < recordDataLength)) {
              // println("Saving Point: "+recordDataIndex);
              recordData[i][recordDataIndex]=PApplet.parseInt(rawVal);
            }
          }
          if (recordDataFlag) {
            recordDataIndex++;
            if ((recordDataIndex % 100) == 0) {
              println("Saving " + recordDataIndex + "/" + recordDataLength + "data point");
            }
            if (recordDataIndex >= recordDataLength) {
              recordDataedCounter = saveRecordedData(recordDataedCounter);
              recordDataFlag = false;
            }
          }
          signalindex ++;//= downSampleCount;
          if (signalindex >= maxSignalLength)signalindex = 0;
          datacounter++;
          if (datacounter >= maxSignalLength)datacounter = maxSignalLength;
        }
        else if (inChar == 'p') {
          inBuffer = new byte[1];
          myPort.readBytes(inBuffer);
          int jacks = inBuffer[0] & 0xFF;
          println("Ports = "+jacks);
          UpdatePorts(jacks);
        }
        else {
          print("data = ");
          println(inChar);
        }
      }
    }
  }
  // endTime = System.nanoTime();
  // long tmp = System.nanoTime() -startTime;
  // println("elapsed = "+tmp);
  // Restore fill and stroke settings
  fill(tmpfillColor);
  stroke(tmpstrokeColor);
  strokeWeight(tmpstrokeWeight);
}

public void useKeyPressedOrMousePressed(int inputDev) {
  // Store current fill and stroke settings
  int tmpfillColor = g.fillColor;
  int tmpstrokeColor = g.strokeColor;
  float tmpstrokeWeight = g.strokeWeight;

  boolean mpressed = mousePressed;
  int x = mouseX, y = mouseY;
  char tkey = key;
  int tkeyCode = keyCode;

  // priority 1 - if in the help menu, any click or key exis the help menu
  if (helpFlag) {
    helpFlag = false;
    buttonsCommon[bchelp].bOn = false;
    background(colorBackground);
    FVpages.get(currentpage).switchToPage();
    labelGUI();
    // Restore fill and stroke settings
    fill(tmpfillColor);
    stroke(tmpstrokeColor);
    strokeWeight(tmpstrokeWeight);
    return;
  }

  // priority 2 - page actions (ex: rename signal, up/down thresh)
  currentbutton = -1;
  if (FVpages.get(currentpage).useKeyPressedOrMousePressed(x, y, tkey, tkeyCode, inputDev)) {
    // Restore fill and stroke settings
    fill(tmpfillColor);
    stroke(tmpstrokeColor);
    strokeWeight(tmpstrokeWeight);
    return;
  }

  // priority 3 - GUI controls (click and hotkey tied together and to a page in the button.pageRef and button.hotKey)
  currentbuttonCommon = -1;
  for (int i = 0; i < buttonsCommon.length; i++) {
    if (buttonsCommon[i] != null) {
      if ( (inputDev == mouseInput && buttonsCommon[i].IsMouseOver(x, y)) || (inputDev == keyInput && tkey == buttonsCommon[i].hotKey) ) {
        println("current button about to be " + i);
        buttonsCommon[i].bOn = true;
        buttonsCommon[i].changeColorPressed();
        currentbuttonCommon = i;
        if (buttonsCommon[i].pageRef >= 0 && buttonsCommon[i].pageRef < FVpages.size()) {
          changePage(buttonsCommon[i].pageRef); // calls labelGUI
          println("Going to page"+buttonsCommon[i].pageRef);
        } 
        else {
          buttonColorTimer = millis()+buttonColorDelay;
          buttonPressedFlag = true;

          if (buttonsCommon[currentbuttonCommon].hotKey == 'h') {
            println("swap to help?");
            FVpages.get(currentpage).drawHelp();
            helpFlag = true;
          }
          if (buttonsCommon[currentbuttonCommon].hotKey == 'r') {
            ResetSerialConnection();
          }
          if (buttonsCommon[currentbuttonCommon].hotKey == 'i') {
            imagesavecounter = saveImage(imagesavecounter);
          }
          if (buttonsCommon[currentbuttonCommon].hotKey == 'd') {
            saveData();
          }
          labelGUI();
        }
        // Restore fill and stroke settings
        fill(tmpfillColor);
        stroke(tmpstrokeColor);
        strokeWeight(tmpstrokeWeight);
        return;
      }
    }
  }
}

// keyboard button handling section
public void keyPressed() {
  if (keyCode == ESC||key == ESC) {
    key = 0;
    keyCode = 0;
  }
  useKeyPressedOrMousePressed(keyInput);
}

// Mouse Button Handling Section
public void mousePressed() {
  useKeyPressedOrMousePressed(mouseInput);
}


public void drawMyLine(int x1, int y1, int x2, int y2, int c, int w) {
  int dif = (y2+y1)/2;
  if (y2 >= y1) {
    for (int i = y1-w; i < dif; i++) {
      setPixel(x1, i, c);
    }
    for (int i = dif; i <= y2+w; i++) {
      setPixel(x2, i, c);
    }
  }
  else if (y1 > y2) {
    for (int i = y1+w; i > dif; i--) {
      setPixel(x1, i, c);
    }
    for (int i = dif; i >= y2-w; i--) {
      setPixel(x2, i, c);
    }
  }
}

public void setPixel(int x, int y, int c) {
  x = constrain(x, xMIN, xMAX);
  y = constrain(y, yMIN, yMAX);
  // if (x < xMIN || x >= xMAX) return;
  // if (y < yMIN || y >= yMAX) return;
  // int N = 4;
  // for (int j = y-N; j<=y+N;j++){
  // pixels[x + j * width] = c;
  // }
  //  println("x = "+x+", y = "+y+", width = "+width);
  pixels[x + y * width] = c;
}


public void drawHelp() {
  
}


public void clearYAxis() {
  fill(colorBackground);
  stroke(colorBackground);
  rectMode(CENTER);
  // stroke(0);
  rect(xStep/2, yTitle+plotheight/2, xStep, plotheight);
}

public void clearRightBar(){
  fill(colorBackground);
  stroke(colorBackground);
  strokeWeight(0);
  rectMode(CENTER);
  rect(xStep+plotwidth+barWidth/2,yTitle+plotheight/2,barWidth-6,plotheight);
}


public void blankPlot() {
  fill(colorPlotBackground);
  stroke(colorPlotOutline);
  strokeWeight(2);
  rectMode(CENTER);
  if (currentpage == workoutpage) {
    rect(xStep+plotwidth/2, yTitle+(plotheight/2)/2, plotwidth, plotheight/2);
    rect(xStep+plotwidth/2, yTitle+plotheight/2+5+(plotheight/2)/2, plotwidth, plotheight/2);
  } 
  else {
    rect(xStep+plotwidth/2, yTitle+plotheight/2, plotwidth, plotheight);
  }
  rectMode(CENTER);
}

public void labelGUI() {

  // Logo
  if (img != null) {
    image(img, 2, 2, xStep-4, yTitle-26);
  }
  else if (img == null) {
    textSize(labelsizexs);
    fill(20, 150, 20);
    textAlign(CENTER, CENTER);
    text("FlexVolt\nViewer\n"+viewerVersion, xStep/2, yTitle/2-2);
  }

  fill(colorLabel);
  textSize(labelsizes);
  text("Connection", xStep+fullPlotWidth+45, yTitle*3/16);

  FVserial.drawConnectionIndicator();

  for (int i = 0; i < buttonsCommon.length; i++) {
    buttonsCommon[i].drawButton();
  }
}
// End of plotting section

public void UpdatePorts(int ports) {
}

public void saveData() {
  recordDataFlag = true;
  println("UserFreq = "+userFrequency+", recordDataTime = "+recordDataTime);
  recordDataLength = recordDataTime*userFrequency;
  recordData = new int[recordDataCols][recordDataLength];
  recordDataIndex = 0;
}

public int saveRecordedData(int datasavecounter) {
  String[] lines = new String[recordDataLength];
  for (int i=0; i<recordDataLength;i++) {
    lines[i] = nf(i, 6)+", ";
    for (int j=0; j<currentSignalNumber;j++) {
      lines[i] += str(recordData[j][i]) +", ";
    }
  }
  String[] saveheader = {
    "FlexVolt Saved Data", "Frequency = "+userFrequency, "Signal Amplification Factor = "+signalAmplifierGain, "Index , Ch1, Ch2, Ch3, Ch4, Ch5, Ch6, Ch7, Ch8"
  };
  String[] savearray = concat(saveheader, lines);
  if (folder.length() == 0){
    folder = sketchPath("");
  }
  if (platform == MACOSX) {
    saveStrings(folder+"/FlexVoltData_"+year()+"-"+nf(month(), 2)+"-"+nf(day(), 2)+"_"+ nf(hour(), 2) +"h-"+ nf(minute(), 2) +"m-"+ nf(second(), 2)+"s_"+nf(datasavecounter, 3)+".txt", savearray);
  }
  else if (platform == WINDOWS) {
    saveStrings(folder+"\\FlexVoltData_"+year()+"-"+nf(month(), 2)+"-"+nf(day(), 2)+"_"+ nf(hour(), 2) +"h-"+ nf(minute(), 2) +"m-"+ nf(second(), 2)+"s_"+nf(datasavecounter, 3)+".txt", savearray);
  }
  datasavecounter ++;
  return datasavecounter;
}

public int saveImage(int imagesavecounter) {
  String a0 = "";
  if (folder.length() == 0){
    folder = sketchPath("");
  }
  if (platform == MACOSX) {
    a0=folder+"/FlexVoltPlot";
  }
  else if (platform == WINDOWS) {
    a0=folder+"\\FlexVoltPlot";
  }
  a0 += "_"+year()+"-"+nf(month(), 2)+"-"+nf(day(), 2)+"_"+ nf(hour(), 2) +"h-"+ nf(minute(), 2) +"m-"+ nf(second(), 2)+"s_";
  if (currentpage == timedomainpage) {
    a0 += "Voltage_";
  }  
  else if (currentpage == frequencydomainpage) {
    a0 += "Frequency_";
  }  
  else if (currentpage == workoutpage) {
    a0 += "Training_";
  }  
  else if (currentpage == targetpracticepage) {
    a0 += "TargetPractice_";
  }
  a0 += nf(imagesavecounter, 3);

  a0 += ".jpg";
  save(a0);
  println("Image Saved");
  println(a0);
  imagesavecounter++;
  return imagesavecounter;
}

public void display_error(String msg) {
  strokeWeight(4);
  stroke(0);
  fill(180);
  textAlign(CENTER, CENTER);
  rectMode(CENTER);
  rect(width/2, height/2, width/4, height/4, 15);
  fill(0);
  text(msg, width/2, height/2, width/5, height/5);
  strokeWeight(2);
}

public void delay(int delay)
{
  int time = millis();
  while (millis () - time <= delay);
}

public void ResetSerialConnection() {
  StopData();
  communicationsflag = false;
  println("stopped data in resetserial");
  display_error("Disconnecting USB Device!");
  if (myPort!=null) {
    myPort.clear();
    myPort.stop();
    myPort.clear();
    myPort = null;
  }
  FVserial.connectserial();
  FVserial.drawConnectionIndicator();
}


public void establishDataLink() {
  if (myPort == null) {
    println("no port to connect to");
    return;
  }
  myPort.write('G'); // tells Arduino to start sending data
  if (commentflag)println("sent G at establishdatalink");

  serialBufferN = currentSignalNumber;
  if (commentflag)println("Signum = "+currentSignalNumber);
  if (bitDepth10) {
    serialBufferN += 1;
    if (currentSignalNumber > 4) {
      serialBufferN += 1;
    }
  }
  if (commentflag)println("SignalBuffer = "+serialBufferN);

  myPort.buffer((serialBufferN+1)*serialBurstN);
}


public void StopData() {
  if (myPort == null) {
    println("no port to stop");
    return;
  }
  try {
    myPort.write('Q');
  }
  catch (RuntimeException e) {
    if (e.getMessage().contains("Port busy")) {
      println("Error = "+e.getMessage());
    } 
    else { 
      println("Unknown Error = "+e.getMessage());
    }
  }
  dataflag = false;
  println("Stopped Data");
  FVserial.connectionindicator = FVserial.indicator_noconnection;
  // ConnectingFlag = false;
}

public void importSettings() {
  String loadedsettings[] = loadStrings(homePath+"/FlexVoltViewerSettings.txt");
  if (loadedsettings == null) {
    //handle error
    println("no settings saved!");
    return;
    //loadDefaults();
  }
  else {
    // import settings
    println("ready to load settings");

    // println(loadedsettings);

    String[] m;
    // folder
    m = match(loadedsettings[1], "null");
    if (m == null) {
      folder = loadedsettings[1];
    } 
    else {
      folder = "";
    }
    println("folder = " + folder);

    // frequency index
    m = match(loadedsettings[2], "null");
    if (m == null) {
      userFreqIndex = PApplet.parseInt(loadedsettings[2]);
      userFrequency = userFreqArray[userFreqIndex];
    } 
    else {
      userFreqIndex = userFreqIndexDefault;
      userFrequency = userFreqArray[userFreqIndex];
    }
    checkSerialDelay = (long)max( checkSerialMinTime, 1000.0f/((float)userFrequency/checkSerialNSamples) );
    maxPlotTime = PApplet.parseFloat(fullPlotWidth)/PApplet.parseFloat(userFrequency);
    println("UserFrequencyIndex = " + userFreqIndex);
    println("userFrequency = " + userFrequency);

    // smoothing filter factor
    m = match(loadedsettings[3], "null");
    if (m == null) {
      smoothFilterVal = PApplet.parseInt(loadedsettings[3]);
    } 
    else {
      smoothFilterVal = smoothFilterValDefault;
    }
    println("smoothFilterVal = " + smoothFilterVal);

    // mouse calibration values
    m = match(loadedsettings[4], "null");
    if (m == null) {      mouseThresh2Ch[thresh2chxLow] = PApplet.parseInt(loadedsettings[4]);    }
    m = match(loadedsettings[5], "null");
    if (m == null) {      mouseThresh2Ch[thresh2chxHigh] = PApplet.parseInt(loadedsettings[5]);    }
    m = match(loadedsettings[6], "null");
    if (m == null) {      mouseThresh2Ch[thresh2chyLow] = PApplet.parseInt(loadedsettings[6]);    }
    m = match(loadedsettings[7], "null");
    if (m == null) {      mouseThresh2Ch[thresh2chyHigh] = PApplet.parseInt(loadedsettings[7]);    }
    println(mouseThresh2Ch);

    if (loadedsettings.length <= 8)return;
    m = match(loadedsettings[8], "null");
    if (m == null) {      mouseThresh4Ch[thresh4chLeft] = PApplet.parseInt(loadedsettings[4]);    }
    m = match(loadedsettings[9], "null");
    if (m == null) {      mouseThresh4Ch[thresh4chRight] = PApplet.parseInt(loadedsettings[5]);    }
    m = match(loadedsettings[10], "null");
    if (m == null) {      mouseThresh4Ch[thresh4chDown] = PApplet.parseInt(loadedsettings[6]);    }
    m = match(loadedsettings[11], "null");
    if (m == null) {      mouseThresh4Ch[thresh4chUp] = PApplet.parseInt(loadedsettings[7]);    }
    println(mouseThresh4Ch);
  }
}

public void PollVersion() {
  if (myPort == null) {
    println("no port to poll");
    return;
  }
  StopData(); // turn data off
  // handle changes to the Serial buffer coming out of settings
  delay(serialwritedelay);
  myPort.clear();
  println("sent Q version");
  myPort.buffer(nVersionBuffer+1);
  myPort.clear();

  myPort.write('V'); // Poll version and SN
  delay(serialwritedelay);

  establishDataLink();
}

public void updateSettings() {
  /*
* Control Words
   *
   * REG0 = main/basic user settings
   * REG0<7:6> = Channels, 11=8, 10=4, 01=2, 00=1
   * REG0<5:2> = FreqIndex
   * REG0<1> = DataMode (1 = filtered, 0 = raw)
   * REG0<0> = Data bit depth. 1=10bits, 0 = 8bits
   *
   * REG1 = Filter Shift Val + Prescalar Settings
   * REG1<4:0> = filter shift val, 0:31, 5-bits
   * REG1<7:5> = PS setting.
   * 000 = 2
   * 001 = 4
   * 010 = 8
   * 011 = 16 // not likely to be used
   * 100 = 32 // not likely to be used
   * 101 = 64 // not likely to be used
   * 111 = off (just use 48MHz/4)
   *
   * REG2 = Manual Frequency, low byte (16 bits total)
   * REG3 = Manual Frequency, high byte (16 bits total)
   *
   * REG4 = Time adjust val (8bits, -6:249)
   *
   * REG5 & REG6 Timer Adjustment
   * (add Time Adjust to x out of N total counts to 250)
   * REG5<7:0> = partial counter val, low byte, 16 bits total
   * REG6<7:0> = partial counter val, high byte, 16 bits total
   *
   * REG7<7:0> = down sampling value (mainly for smoothed data)
   *
   * REG8<7:0> = Plug Test Frequency
   */

  if (myPort == null) {
    println("no port to updatesettings on");
    return;
  }
  if (FVserial.flexvoltconnected) {
    StopData(); // turn data off
    // handle changes to the Serial buffer coming out of settings


    dataRegWriteFlag = true;
    delay(serialwritedelay);
    myPort.clear();
    println("sent Q update settings");
    myPort.buffer(1);
    myPort.clear();

    myPort.write('V'); // Poll version and SN
    delay(serialwritedelay);

    myPort.write('S'); // Enter settings menu
    delay(serialwritedelay);

    int REGtmp = 0;
    int tmp = 0;
    //Register 1
    if (currentSignalNumber == 8)tmp = 3;
    if (currentSignalNumber == 4)tmp = 2;
    if (currentSignalNumber == 2)tmp = 1;
    if (currentSignalNumber == 1)tmp = 0;
    println(binary(tmp));
    REGtmp = tmp << 6;
    REGtmp += userFreqIndex << 2;
    tmp = 0;
    if (smoothFilterFlag) {
      tmp = 1;
    }
    REGtmp += tmp << 1;
    tmp = 0;
    if (bitDepth10) {
      tmp = 1;
    }
    REGtmp += tmp;
    myPort.write(REGtmp);//10100001
    delay(serialwritedelay);

    REGtmp = 0;
    REGtmp += prescalerPic << 5;
    REGtmp += smoothFilterVal;
    myPort.write(REGtmp);
    delay(serialwritedelay);//01000101

    REGtmp = userFreqCustom;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = userFreqCustom>>8;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = timer0AdjustVal+6;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = timer0PartialCount;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = timer0PartialCount>>8;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = downSampleCount;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = plugTestDelay;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    myPort.write('Y');
    delay(serialwritedelay);

    establishDataLink();
  }
}

public int getIntFromString(String savedname, int defaultval) {
  boolean intflag = false;
  boolean completeintflag = true;
  int test = defaultval;
  for (int j = 0; j < savedname.length(); j++) {
    intflag = false;
    for (int i = 0; i<10; i++) {
      String tmp = str(i);
      if (tmp.equals(savedname.substring(j, j+1))) {
        intflag = true;
      }
    }
    if (!intflag) {
      completeintflag = false;
    }
  }
  println("input string will be"+savedname);
  if (savedname.length()>0) {
    if (completeintflag)test = Integer.parseInt(savedname);
  }
  return test;
}

public void changePage(int newPage) {
  oldpage = currentpage;
  currentpage = newPage;
  println("oldpage = "+oldpage+", newpage = "+currentpage);

  if (newPage != settingspage) {
    background(colorBackground);
  }

//  buttonsCommon[bcsettings].changeColorUnpressed();
//  buttonsCommon[bchelp].changeColorUnpressed();
//  buttonsCommon[bcplotdomain].bOn = false;
//  buttonsCommon[bctraindomain].bOn = false;
//  buttonsCommon[bcmousedomain].bOn = false;
//  buttonsCommon[bcsnakedomain].bOn = false;
//  buttonsCommon[bcmusicdomain].bOn = false;
  
  for (int i = 0; i < buttonsCommon.length; i++){
    if (buttonsCommon[i].pageRef == currentpage){
      buttonsCommon[i].bOn = true;
    } else {
      buttonsCommon[i].bOn = false;
      buttonsCommon[i].changeColorUnpressed();
    }
  }
  
//  if (currentbuttonCommon >= 0 && currentbuttonCommon < buttonsCommon.length){
//    buttonsCommon[currentbuttonCommon].bOn = true;
//  }

  FVpages.get(currentpage).switchToPage();
  labelGUI();

  loadPixels();
}

public void drawGenericHelp(){
  blankPlot();
  stroke(0);
  strokeWeight(4);
  fill(200);
  rectMode(CENTER);
  textAlign(CENTER, CENTER);
  rect(xStep+fullPlotWidth/2, yTitle+plotheight/2, fullPlotWidth, plotheight, 12);

  fill(0);
  textSize(labelsizes);
  int tmptextw = PApplet.parseInt(textWidth("Help Page"))/2; 
  text("Help Page ", xStep+fullPlotWidth/2, yTitle+12);

  String helpdoc = "";
  helpdoc = helpdoc + " Troubleshooting:  1. Try resetting the connection using 'Reset'.\n";
  helpdoc = helpdoc + "       2. Unplug USB cable from computer, plug back in, 'Reset'.\n";
  helpdoc = helpdoc + "\n";
  helpdoc = helpdoc + "Use Tabs or Hotkeys to switch Pages:\n";
  helpdoc = helpdoc + " Time (hotkey 't') - home page, plot signals vs. time\n";
  helpdoc = helpdoc + " Frequency (hotkey 'f') - plot signal frequencies (using FFT).\n";
  helpdoc = helpdoc + " Train (workout) (hotey 'w') - monitor reps, work towards a goal\n";
  helpdoc = helpdoc + " Mouse (hotkey 'm') - control your computer mouse\n";
  helpdoc = helpdoc + "\n";
  helpdoc = helpdoc + "Hot Keys: 'h' = help 's' = settings 'r' = reset connection 'c' = clear\n";
  helpdoc = helpdoc + " 'p' = pause/unpause 'i' = save image 'd' = save data\n";
  helpdoc = helpdoc + " 'o' = offset plot lines 'j ' = smoothing filter\n";
  helpdoc = helpdoc + "\n";
  helpdoc = helpdoc + "For addtional help, go to www.flexvoltbiosensor.com\n";
  fill(0);
  textSize(labelsizexs);
  textAlign(LEFT, CENTER);
  text(helpdoc, xStep+fullPlotWidth/2, yTitle+plotheight/2+10, fullPlotWidth-10, plotheight-20);
  textAlign(CENTER, CENTER);
  textSize(labelsizexs);
  text("For addtional help: www.flexvoltbiosensor.com", xStep+fullPlotWidth/2, yTitle+plotheight - 15);
}


/************************* BEGIN SETTINGS Page ***********************/
public class SettingsPage implements pagesClass {
  // variables
  PApplet parent;

  GuiButton[] buttons;
  int buttonNumber = 0;
  int
    bfolder = buttonNumber++, 
  bfiltup = buttonNumber++, 
  bfiltdown = buttonNumber++, 
  bfrequp = buttonNumber++, 
  bfreqdown = buttonNumber++, 
  brecordtimeup = buttonNumber++, 
  brecordtimedown = buttonNumber++, 
  b1chan = buttonNumber++, 
  b2chan = buttonNumber++, 
  b4chan = buttonNumber++, 
  b8chan = buttonNumber++, 
  bcancel = buttonNumber++, 
  bsave = buttonNumber++, 
  bdefaults = buttonNumber++, 
  bdownsampleup = buttonNumber++, 
  bdownsampledown = buttonNumber++, 
  btimeradjustup = buttonNumber++, 
  btimeradjustdown = buttonNumber++, 
  //bbitdepth8 = buttonNumber++,
  //bbitdepth10 = buttonNumber++,
  bprescalerup = buttonNumber++, 
  bprescalerdown = buttonNumber++;
  // Settings Page Buttons

  String pageName = "Settings";
  String folderTmp = "";
  String tmpfolder = "";
  int currentbutton = 0;
  int userFrequencyTmp;
  int userFreqIndexTmp;
  int smoothFilterValTmp;
  int downSampleCountTmp;
  int timer0AdjustValTmp;
  int prescalerPicTmp;
  int recordDataTimeTmp;
  int currentSignalNumberTmp;
  boolean buttonPressedFlag = false;

  // constructor
  SettingsPage(PApplet parent) {
    this.parent = parent;
    // set input variables
    initializeButtons();

    folderTmp = folder;
    userFreqIndexTmp = userFreqIndex;
    userFrequencyTmp = userFreqArray[userFreqIndexTmp];
    smoothFilterValTmp = smoothFilterVal;
    downSampleCountTmp = downSampleCount;
    timer0AdjustValTmp = timer0AdjustVal;
    prescalerPicTmp = prescalerPic;
    recordDataTimeTmp = recordDataTime;
    currentSignalNumberTmp = currentSignalNumber;
  }

  public void initializeButtons() {
    buttons = new GuiButton[buttonNumber];
    println("width here = "+width);
    buttons[bfolder]         = new GuiButton("Folder", ' ', dummypage, width/2-200, height/2-110, 80, bheights, color(colorBIdle), color(0), "change", bMomentary, false, showButton);
    buttons[bfiltup]         = new GuiButton("FilterUp", ' ', dummypage, width/2+115, height/2+10, 20, bheights, color(colorBIdle), color(0), "+", bMomentary, false, showButton);
    buttons[bfiltdown]       = new GuiButton("FilterDn", ' ', dummypage, width/2+65, height/2+10, 20, bheights, color(colorBIdle), color(0), "-", bMomentary, false, showButton);
    buttons[bfrequp]         = new GuiButton("FreqUp", ' ', dummypage, width/2-160, height/2+10, 20, bheights, color(colorBIdle), color(0), "+", bMomentary, false, showButton);
    buttons[bfreqdown]       = new GuiButton("FreqDn", ' ', dummypage, width/2-230, height/2+10, 20, bheights, color(colorBIdle), color(0), "-", bMomentary, false, showButton);
    buttons[brecordtimeup]   = new GuiButton("RecordTimeUp", ' ', dummypage, width/2+200, height/2-70, 20, bheights, color(colorBIdle), color(0), "+", bMomentary, false, showButton);
    buttons[brecordtimedown] = new GuiButton("RecordTimeDn", ' ', dummypage, width/2+130, height/2-70, 20, bheights, color(colorBIdle), color(0), "-", bMomentary, false, showButton);
    buttons[b1chan]          = new GuiButton("1chanmodel", ' ', dummypage, width/2-105, height/2+10, 30, bheights, color(colorBIdle), color(0), "1", bOnOff, false, showButton);
    buttons[b2chan]          = new GuiButton("2chanmodel", ' ', dummypage, width/2-70, height/2+10, 30, bheights, color(colorBIdle), color(0), "2", bOnOff, false, showButton);
    buttons[b4chan]          = new GuiButton("4chanmodel", ' ', dummypage, width/2-35, height/2+10, 30, bheights, color(colorBIdle), color(0), "4", bOnOff, true, showButton);
    buttons[b8chan]          = new GuiButton("8chanmodel", ' ', dummypage, width/2+0, height/2+10, 30, bheights, color(colorBIdle), color(0), "8", bOnOff, false, showButton);
    buttons[bdownsampleup]   = new GuiButton("downSampleUp", ' ', dummypage, width/2+220, height/2+10, 20, bheights, color(colorBIdle), color(0), "+", bMomentary, false, showButton);
    buttons[bdownsampledown] = new GuiButton("downSampleDn", ' ', dummypage, width/2+170, height/2+10, 20, bheights, color(colorBIdle), color(0), "-", bMomentary, false, showButton);
    buttons[btimeradjustup]  = new GuiButton("TimerAdjustUp", ' ', dummypage, width/2-70, height/2+80, 20, bheights, color(colorBIdle), color(0), "+", bMomentary, false, showButton);
    buttons[btimeradjustdown]= new GuiButton("TimerAdjustDn", ' ', dummypage, width/2-130, height/2+80, 20, bheights, color(colorBIdle), color(0), "-", bMomentary, false, showButton);
    buttons[bprescalerup]    = new GuiButton("prescalerPicUp", ' ', dummypage, width/2+60, height/2+80, 20, bheights, color(colorBIdle), color(0), "+", bMomentary, false, showButton);
    buttons[bprescalerdown]  = new GuiButton("prescalerPicDn", ' ', dummypage, width/2+0, height/2+80, 20, bheights, color(colorBIdle), color(0), "-", bMomentary, false, showButton);
    buttons[bsave]           = new GuiButton("Save", 's', dummypage, width/2-160, height/2+130, 140, 30, color(colorBIdle), color(0), "Save & Exit (s)", bOnOff, false, showButton);
    buttons[bdefaults]       = new GuiButton("Defaults", 'd', dummypage, width/2+160, height/2+130, 140, 30, color(colorBIdle), color(0), "Restore Defaults", bOnOff, false, showButton);
    buttons[bcancel]         = new GuiButton("Exit", 'c', dummypage, width/2, height/2+130, 120, 30, color(colorBIdle), color(0), "Cancel (c)", bOnOff, false, showButton);
  }

  public void switchToPage() {
    folderTmp = folder;
    userFreqIndexTmp = userFreqIndex;
    userFrequencyTmp = userFrequency;
    smoothFilterValTmp = smoothFilterVal;
    downSampleCountTmp = downSampleCount;
    timer0AdjustValTmp = timer0AdjustVal;
    prescalerPicTmp = prescalerPic;
    recordDataTimeTmp = recordDataTime;
    currentSignalNumberTmp = currentSignalNumber;

    StopData(); // turn data off
    delay(serialwritedelay);
    if (myPort != null) {
      myPort.clear();
    }
    println("width = "+width+", height = "+height+". but parent.width = "+parent.width);
  }

  public void drawPage() {
    // draw subfunctions
    if (buttonPressedFlag) {
      if (millis() > buttonColorTimer) {
        buttonPressedFlag = false;
        println("Current Button = " + currentbutton);
        if (buttons[currentbutton] != null && currentbutton < buttons.length) {
          buttons[currentbutton].changeColorUnpressed();
        }
      }
    }

    drawSettings();
  }

  public String getPageName() {
    return pageName;
  }

  public void saveSettings() {
    // save all tmp vals from the settings menu in the actual variables
    folder = folderTmp;
    userFreqIndex = userFreqIndexTmp;
    smoothFilterVal = smoothFilterValTmp;
    downSampleCount = downSampleCountTmp;
    timer0AdjustVal = timer0AdjustValTmp;
    prescalerPic = prescalerPicTmp;
    recordDataTime = recordDataTimeTmp;
    currentSignalNumber = currentSignalNumberTmp;

    userFrequency = userFreqArray[userFreqIndex];
    maxPlotTime = PApplet.parseFloat(fullPlotWidth)/PApplet.parseFloat(userFrequency);
    userFreqCustom = 0;
    checkSerialDelay = (long)max( checkSerialMinTime, 1000.0f/((float)userFrequency/checkSerialNSamples) );
    recordDataLength = recordDataTime*userFrequency;
    buttonsCommon[bcrecordnextdata].label = "Record "+recordDataTime+"s";
    for (int i = 0; i<maxcurrentSignalNumber;i++) {
      if (i < currentSignalNumber) {
        channelsOn[i]=true;
      } 
      else if (i >= currentSignalNumber) {
        channelsOn[i]=false;
      }
    }
    maxPlotTime = PApplet.parseFloat(fullPlotWidth)/PApplet.parseFloat(userFrequency);

    // build and save a txt file of settings
    String[] settingString = new String[12];
    settingString[0] = "FlexVoltViewer User Settings";
    settingString[1] = folder;
    settingString[2] = str(userFreqIndex);
    settingString[3] = str(smoothFilterVal);
    settingString[4] = str(mouseThresh2Ch[thresh2chxLow]);
    settingString[5] = str(mouseThresh2Ch[thresh2chxHigh]);
    settingString[6] = str(mouseThresh2Ch[thresh2chyLow]);
    settingString[7] = str(mouseThresh2Ch[thresh2chyHigh]);
    settingString[8]  = str(mouseThresh4Ch[thresh4chLeft]);
    settingString[9]  = str(mouseThresh4Ch[thresh4chRight]);
    settingString[10] = str(mouseThresh4Ch[thresh4chDown]);
    settingString[11] = str(mouseThresh4Ch[thresh4chUp]);

    saveStrings(homePath+"/FlexVoltViewerSettings.txt", settingString);
    updateSettings();
  }

  public boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
    boolean outflag = false;
    currentbutton = -1;
    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        if ( (inputDev == mouseInput && buttons[i].IsMouseOver(x, y)) || (inputDev == keyInput && tkey == buttons[i].hotKey) ) {
          outflag = true;
          buttons[i].bOn = !buttons[i].bOn;
          buttons[i].changeColorPressed();
          buttonColorTimer = millis()+buttonColorDelay;
          buttonPressedFlag = true;
          currentbutton = i;

          if (currentbutton == bfolder) {
            println("getting folder");
            waitForFolder();
            println(folder);
          }
          if (currentbutton == bfrequp) {
            userFreqIndexTmp++;
            if (userFreqIndexTmp >= userFreqArray.length)userFreqIndexTmp=userFreqArray.length-1;
            println(userFreqIndexTmp);
            userFrequencyTmp = userFreqArray[userFreqIndexTmp];
          }
          if (currentbutton == bfreqdown) {
            userFreqIndexTmp--;
            if (userFreqIndexTmp < 0)userFreqIndexTmp=0;
            println(userFreqIndexTmp);
            userFrequencyTmp = userFreqArray[userFreqIndexTmp];
          }
          if (currentbutton == bfiltup) {
            smoothFilterValTmp++;  
            smoothFilterVal = constrain(smoothFilterValTmp, smoothFilterValMin, smoothFilterValMax);
          }
          if (currentbutton == bfiltdown) {
            smoothFilterValTmp--;  
            smoothFilterVal = constrain(smoothFilterValTmp, smoothFilterValMin, smoothFilterValMax);
          }
          if (currentbutton == bdownsampleup) {
            downSampleCountTmp++;  
            downSampleCountTmp = constrain(downSampleCountTmp, downSampleCountMin, downSampleCountMax);
          }
          if (currentbutton == bdownsampledown) {
            downSampleCountTmp--;  
            downSampleCountTmp = constrain(downSampleCountTmp, downSampleCountMin, downSampleCountMax);
          }
          if (currentbutton == btimeradjustup) {
            timer0AdjustValTmp++;  
            timer0AdjustValTmp = constrain(timer0AdjustValTmp, timer0AdjustValMin, timer0AdjustValMax);
          }
          if (currentbutton == btimeradjustdown) {
            timer0AdjustValTmp--;  
            timer0AdjustValTmp = constrain(timer0AdjustValTmp, timer0AdjustValMin, timer0AdjustValMax);
          }
          if (currentbutton == bprescalerup) {
            prescalerPicTmp++;
            if (prescalerPicTmp > prescalerPicMax) prescalerPicTmp = prescalerPicMax;
          }
          if (currentbutton == bprescalerdown) {
            prescalerPicTmp--;
            if (prescalerPicTmp < prescalerPicMin) prescalerPicTmp = prescalerPicMin;
          }
          if (currentbutton == brecordtimeup) {
            recordDataTimeTmp++;
            if (recordDataTimeTmp > recordDatamaxPlotTime) recordDataTimeTmp = recordDatamaxPlotTime;
          }
          if (currentbutton == brecordtimedown) {
            recordDataTimeTmp--;
            if (recordDataTimeTmp < recordDataTimeMin) recordDataTimeTmp = recordDataTimeMin;
          }
          if (currentbutton == b1chan) {
            currentSignalNumberTmp = 1;
            buttons[b1chan].bOn = false;
            buttons[b2chan].bOn = false;
            buttons[b4chan].bOn = false;
            buttons[b8chan].bOn = false;
            buttons[currentbutton].bOn = true;
          }
          if (currentbutton == b2chan) {
            currentSignalNumberTmp = 2;
            buttons[b1chan].bOn = false;
            buttons[b2chan].bOn = false;
            buttons[b4chan].bOn = false;
            buttons[b8chan].bOn = false;
            buttons[currentbutton].bOn = true;
          }
          if (currentbutton == b4chan) {
            currentSignalNumberTmp = 4;
            buttons[b1chan].bOn = false;
            buttons[b2chan].bOn = false;
            buttons[b4chan].bOn = false;
            buttons[b8chan].bOn = false;
            buttons[currentbutton].bOn = true;
          }
          if (currentbutton == b8chan) {
            currentSignalNumberTmp = 8;
            buttons[b1chan].bOn = false;
            buttons[b2chan].bOn = false;
            buttons[b4chan].bOn = false;
            buttons[b8chan].bOn = false;
            buttons[currentbutton].bOn = true;
          }
          if (currentbutton == bsave) {
            println("Got the save 's'");
            saveSettings();
            changePage(oldpage);
            buttons[currentbutton].bOn = false;
            return outflag;
          }
          if (currentbutton == bcancel) {
            changePage(oldpage);
            establishDataLink();
            buttons[currentbutton].bOn = false;
            return outflag;
          }
          if (currentbutton == bdefaults) {
            restoreDefaults();
          }
          drawSettings();
        }
      }
    }
    return outflag;
  }

  public void useSerialEvent() {
  }

  public void drawHelp() {
    drawGenericHelp();
  }

  public void restoreDefaults() {
  }

  public void waitForFolder() {
    tmpfolder = null;
    selectFolder("Select a folder to process:", "folderSelected");
    while (tmpfolder == null) delay(200);

    // labelAxes();
    // for (String csv: filenames = folder.list(csvFilter)) println(csv);
  }

  public void folderSelected(File selection) {
    if (selection == null) {
      println("Window was closed or the user hit cancel.");
      tmpfolder = "";
    } 
    else {
      println("User selected " + selection.getAbsolutePath());
      folderTmp = selection.getAbsolutePath();
      tmpfolder = folderTmp;
    }
  }

  public void drawSettings() {
    textAlign(CENTER, CENTER);
    blankPlot();
    stroke(colorLabel);
    strokeWeight(4);
    fill(colorBackground);
    rectMode(CENTER);
    rect(width/2, height/2, fullPlotWidth+20, plotheight+40, 12);

    strokeWeight(2);
    textSize(labelsizexs);
    textAlign(CENTER, CENTER);

    stroke(colorLabel);
    fill(colorBackground);
    rect(width/2-90, height/2-90, 300, bheights);
    if (PApplet.parseInt(textWidth(folderTmp)) < 300) {
      fill(colorLabel);
      text(folderTmp, width/2-90, height/2-90);
    }
    else if (textWidth(folderTmp) >= 450) {
      rect(width/2-90, height/2-70, 300, bheights);
      fill(colorLabel);
      text(folderTmp, width/2-90, height/2-80, 300, bheights*2);
    }

    textSize(titlesize);
    text("FlexVolt Settings Menu", width/2, height/2-plotheight/2);

    textSize(labelsizes);
    text("Saving Data & Images", width/2, height/2-115);
    textSize(labelsizexs);
    text("Save Directory", width/2-200, height/2-130);

    text("Data Recording Time (s)", width/2+170, height/2-95);
    text(str(recordDataTimeTmp), width/2+170, height/2-70);

    textSize(labelsizes);
    text("Data Sampling Settings", width/2, height/2-40);
    textSize(labelsizexs);
    text("Frequency, Hz", width/2-195, height/2-15);
    text(str(userFrequencyTmp), width/2-195, height/2+10);

    text("Number of Channels", width/2-50, height/2-15); // reserved for future use

    text("Smooth Filter", width/2+90, height/2-15);
    text(str(smoothFilterValTmp), width/2+90, height/2+10);

    text("Downsample", width/2+200, height/2-15);
    text(str(downSampleCountTmp), width/2+200, height/2+10);

    textSize(labelsizes);
    text("Timing Settings (Advanced)", width/2, height/2+40);
    textSize(labelsizexs);
    text("Timer Adjust", width/2-100, height/2+60);
    text(str(timer0AdjustValTmp), width/2-100, height/2+80);

    text("prescalerPic", width/2+30, height/2+60);
    text(str(prescalerPicTmp), width/2+30, height/2+80);


    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        buttons[i].drawButton();
      }
    }
  }
}
/************************* END SETTINGS PAGE ***********************/


/************************* BEGIN TimeDomainPlot Page ***********************/
public class TimeDomainPlotPage implements pagesClass {
  // variables
  GuiButton[] buttons;
  int buttonNumber = 0;
  int
    boffset = buttonNumber++, 
  bpause = buttonNumber++, 
  bsmooth = buttonNumber++, 
  bclear = buttonNumber++, 
  bchan1 = buttonNumber++, 
  bchan2 = buttonNumber++, 
  bchan3 = buttonNumber++, 
  bchan4 = buttonNumber++, 
  bchan5 = buttonNumber++, 
  bchan6 = buttonNumber++, 
  bchan7 = buttonNumber++, 
  bchan8 = buttonNumber++,
  bdomain = buttonNumber++;

  String pageName = "Muscle Voltage";
  int xPos = 0;
  int[] offSet2 = {    
    +plotheight*3/4, +plotheight*1/4
  };
  int[] offSet8 = {    
    +plotheight*7/8, +plotheight*5/8, +plotheight*3/8, +plotheight*1/8, +plotheight*7/8, +plotheight*5/8, +plotheight*3/8, +plotheight*1/8
  };
  int[] offSet4 = {    
    +plotheight*7/8, +plotheight*5/8, +plotheight*3/8, +plotheight*1/8
  };
  
  float minFreqAmp = 0;
  float maxFreqAmp = 1;
  int scaleFFT = 80; // multiplying fft amplitude
  int yStepFFT = 2;
  float frequencyFactor = (float)plotwidth/maxPlotFrequency;

  boolean buttonPressedFlag = false;
  boolean flagTimeDomain = true;
  boolean flagFreqDomain = false;
  
  String domainStr;

  // constructor
  TimeDomainPlotPage() {
    // set input variables
    domainStr = "Switch to Frequency";
    initializeButtons();
  }

  public void initializeButtons() {
    buttons = new GuiButton[buttonNumber];
    int buttony = yTitle+195;
    int controlsy = yTitle+30;

    buttons[boffset] =new GuiButton("OffSet", 'o', dummypage, xStep+plotwidth+45, controlsy+70, 60, bheight, color(colorBIdle), color(0), "OffSet", bOnOff, false, showButton);
    buttons[bpause] = new GuiButton("Pause",  'p', dummypage, xStep+plotwidth+45, controlsy+10, 60, bheight, color(colorBIdle), color(0), "Pause", bOnOff, false, showButton);
    buttons[bsmooth] =new GuiButton("Smooth", 'f', dummypage, xStep+plotwidth+45, controlsy+100, 60, bheight, color(colorBIdle), color(0), "Filter", bOnOff, false, showButton);
    buttons[bclear] = new GuiButton("Clear",  'c', dummypage, xStep+plotwidth+45, controlsy+40, 60, bheight, color(colorBIdle), color(0), "Clear", bMomentary, false, showButton);
    buttons[bchan1] = new GuiButton("Chan1",  '1', dummypage, xStep+plotwidth+25, buttony, 30, bheight, color(colorBIdle), colorSig1, "1", bOnOff, true, showButton);
    buttons[bchan2] = new GuiButton("Chan2",  '2', dummypage, xStep+plotwidth+25, buttony+30, 30, bheight, color(colorBIdle), colorSig2, "2", bOnOff, true, showButton);
    buttons[bchan3] = new GuiButton("Chan3",  '3', dummypage, xStep+plotwidth+25, buttony+60, 30, bheight, color(colorBIdle), colorSig3, "3", bOnOff, true, showButton);
    buttons[bchan4] = new GuiButton("Chan4",  '4', dummypage, xStep+plotwidth+25, buttony+90, 30, bheight, color(colorBIdle), colorSig4, "4", bOnOff, true, showButton);
    buttons[bchan5] = new GuiButton("Chan5",  '5', dummypage, xStep+plotwidth+65, buttony, 30, bheight, color(colorBIdle), colorSig5, "5", bOnOff, false, showButton);
    buttons[bchan6] = new GuiButton("Chan6",  '6', dummypage, xStep+plotwidth+65, buttony+30, 30, bheight, color(colorBIdle), colorSig6, "6", bOnOff, false, showButton);
    buttons[bchan7] = new GuiButton("Chan7",  '7', dummypage, xStep+plotwidth+65, buttony+60, 30, bheight, color(colorBIdle), colorSig7, "7", bOnOff, false, showButton);
    buttons[bchan8] = new GuiButton("Chan8",  '8', dummypage, xStep+plotwidth+65, buttony+90, 30, bheight, color(colorBIdle), colorSig8, "8", bOnOff, false, showButton);
    buttons[bdomain]= new GuiButton("Domain", 't', dummypage, xStep+80, yTitle+plotheight+30, 160, 18, color(colorBIdle), color(0), domainStr, bMomentary, false, showButton);

    if (flagTimeDomain){
      offSet2[0] = plotheight*3/4;
      offSet2[1] = plotheight*1/4;
  
      offSet4[0] = plotheight*7/8;
      offSet4[1] = plotheight*5/8;
      offSet4[2] = plotheight*3/8;
      offSet4[3] = plotheight*1/8;
  
      offSet8[0] = plotheight*7/8;
      offSet8[1] = plotheight*5/8;
      offSet8[2] = plotheight*3/8;
      offSet8[3] = plotheight*1/8;
      offSet8[4] = plotheight*7/8;
      offSet8[5] = plotheight*5/8;
      offSet8[6] = plotheight*3/8;
      offSet8[7] = plotheight*1/8;
    } else if(flagFreqDomain){
      offSet2[0] = 0;
      offSet2[1] = plotheight/2;
  
      offSet4[0] = 0;
      offSet4[1] = plotheight/4;
      offSet4[2] = plotheight/2;
      offSet4[3] = plotheight*3/4;
  
      offSet8[0] = 0;
      offSet8[1] = plotheight/8;
      offSet8[2] = plotheight/4;
      offSet8[3] = plotheight*3/8;
      offSet8[4] = plotheight/2;
      offSet8[5] = plotheight*5/8;
      offSet8[6] = plotheight*3/4;
      offSet8[7] = plotheight*7/8;
      
      frequencyFactor = (float)plotwidth/maxPlotFrequency;
    }
  }

  public void switchToPage() {
    //    smoothFilterFlag = false; //todo make this stay as it was for this page
    //    offsetFlag = false;
    //pauseFlag = false;
    for (int i = 0; i < maxcurrentSignalNumber; i++) {
      buttons[bchan1+i].bOn = channelsOn[i];
    }
    buttons[boffset].bOn = offsetFlag;
    buttons[bsmooth].bOn = smoothFilterFlag;
    buttons[bpause].bOn = pauseFlag;

    datacounter = 0;
    plotwidth = fullPlotWidth;
    xPos = 0;
    //    background(colorBackground);
    labelAxes();
    blankPlot();
    println("TimeDomain");
  }

  public void drawPage() {
    // draw subfunctions
    if (buttonPressedFlag) {
      if (millis() > buttonColorTimer) {
        buttonPressedFlag = false;
        println("Current Button = " + currentbutton);
        if (buttons[currentbutton] != null && currentbutton < buttons.length) {
          buttons[currentbutton].changeColorUnpressed();
        }
      }
    }

    if (!(xPos == plotwidth && pauseFlag)) {
      // startTime = System.nanoTime()/1000;
      if(flagTimeDomain){
        drawTrace();
      }
      else if(flagFreqDomain){
        drawFFT();
      }
      // endTime = System.nanoTime()/1000;
      // println("drawTrace takes "+(endTime-startTime));
    }
  }

  public String getPageName() {
    return pageName;
  }
  
  public void labelAxes(){
    if(flagTimeDomain){
      labelAxesTime();
    }
    else if(flagFreqDomain){
      labelAxesFFT();
    }
  }

  public void labelAxesTime() {
    fill(colorLabel);
    stroke(colorLabel);
    strokeWeight(2);
    textAlign(CENTER, CENTER);

    // title
    textSize(titlesize);
    text("Muscle Voltage", xStep+fullPlotWidth/2+20, yTitle-45);

    textSize(axisnumbersize);
    // x-axis
    float val = 0;
    for (int i = 0; i < nXTicks+1; i++) {
      text(nf(val, 1, 0), xStep+PApplet.parseInt(map(val, 0, maxPlotTime, 0, plotwidth-10)), height-yStep+10);
      val += maxPlotTime/nXTicks;
    }

    // y-axis
    if (!offsetFlag) {
      val = minVoltage;
      for (int i = 0; i < nYTicks+1; i++) {
        if (val > 0) {
          text(("+"+nf(val, 1, 0)), xStep-22, ytmp -6 - PApplet.parseInt(map(val, minVoltage, maxVoltage, 0, plotheight-12)));
        } 
        else {
          text(nf(val, 1, 0), xStep-22, ytmp -6 - PApplet.parseInt(map(val, minVoltage, maxVoltage, 0, plotheight-12)));
        }
        val += (maxVoltage-minVoltage)/nYTicks;
      }
    }
    else if (offsetFlag) {
      val = minVoltage/2;
      // val = minVoltage;
      int xtmp = 0;
      for (int i = 0; i < nYTicksHalf+1; i++) {
        xtmp = xStep-20;
        if (val > 0) {
          text(("+"+nf(val, 1, 0)), xtmp, ytmp - PApplet.parseInt(map(val, minVoltage, maxVoltage, 0, plotheight/4)));
          text(("+"+nf(val, 1, 0)), xtmp, ytmp - PApplet.parseInt(map(val, minVoltage, maxVoltage, plotheight/4, plotheight/2)));
          text(("+"+nf(val, 1, 0)), xtmp, ytmp - PApplet.parseInt(map(val, minVoltage, maxVoltage, plotheight/2, plotheight*3/4)));
          text(("+"+nf(val, 1, 0)), xtmp, ytmp - PApplet.parseInt(map(val, minVoltage, maxVoltage, plotheight*3/4, plotheight)));
        } 
        else {
          text(nf(val, 1, 0), xtmp, ytmp - PApplet.parseInt(map(val, minVoltage, maxVoltage, 0, plotheight/4)));
          text(nf(val, 1, 0), xtmp, ytmp - PApplet.parseInt(map(val, minVoltage, maxVoltage, plotheight/4, plotheight/2)));
          text(nf(val, 1, 0), xtmp, ytmp - PApplet.parseInt(map(val, minVoltage, maxVoltage, plotheight/2, plotheight*3/4)));
          text(nf(val, 1, 0), xtmp, ytmp - PApplet.parseInt(map(val, minVoltage, maxVoltage, plotheight*3/4, plotheight)));
        }
        val += ((maxVoltage/2)-(minVoltage/2))/nYTicksHalf;
        // val += ((maxVoltage)-(minVoltage))/nYTicks;
      }
    }

    // axis labels
    textSize(labelsizes);
    translate(12, height/2);
    rotate(-PI/2);
    text("Electrical Potential, millivolts", 0, 0);
    rotate(PI/2);
    translate(-12, -height/2);
    text("Time, seconds", xStep + plotwidth/2, height-15);

    textSize(labelsize);
    text("Channel", xStep+fullPlotWidth+45, yTitle+165);
    text("Plotting", xStep+fullPlotWidth+45, yTitle+10);

    for (int i = 0; i < buttons.length; i++) {
      buttons[i].drawButton();
    }
  }
  
  public void labelAxesFFT() {
    fill(colorLabel);
    stroke(colorLabel);
    strokeWeight(2);
    textAlign(CENTER, CENTER);

    // title
    textSize(titlesize);
    text("Signal Frequency", xStep+fullPlotWidth/2+20, yTitle-45);

    // x-axis
    textSize(axisnumbersize);
    float val = 0;
    for (int i = 0; i < nXTicks+1; i++) {
      text(nf(val, 1, 0), xStep+PApplet.parseInt(map(val, 0, maxPlotFrequency, 0, plotwidth)), height-yStep+10);
      val += maxPlotFrequency/nXTicks;
    }

    // axis labels
    textSize(labelsizes);
    translate(40, height/2);
    rotate(-PI/2);
    text("Intensity, a.u.", 0, 0);
    rotate(PI/2);
    translate(-40, -height/2);
    text("Frequency, Hz", xStep + plotwidth/2, height-15);

    textSize(labelsize);
    text("Channel", xStep+fullPlotWidth+45, yTitle+165);
    text("Plotting", xStep+fullPlotWidth+45, yTitle+10);
    textSize(labelsizes);

    for (int i = 0; i < buttons.length; i++) {
      buttons[i].drawButton();
    }
  }

  public boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
    boolean outflag = false;
    currentbutton = -1;
    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        if ( (inputDev == mouseInput && buttons[i].IsMouseOver(x, y)) || (inputDev == keyInput && tkey == buttons[i].hotKey) ) {
          outflag = true;
          buttons[i].bOn = !buttons[i].bOn;
          buttons[i].changeColorPressed();
          buttonColorTimer = millis()+buttonColorDelay;
          buttonPressedFlag = true;
          currentbutton = i;

          if (currentbutton == bdomain){
            if (flagTimeDomain){
              flagTimeDomain = false;
              flagFreqDomain = true;
              domainStr = "Switch to Time";
              buttons[i].label = "Switch to Time";
              buttons[i].changeColorUnpressed();
              buttonPressedFlag = false;
              background(colorBackground);
              labelGUI();
              initializeButtons();
              switchToPage();
              return outflag;
            }
            else if (flagFreqDomain){
              flagTimeDomain = true;
              flagFreqDomain = false;
              domainStr = "Switch to Frequency";
              buttons[i].label = "Switch to Frequency";
              buttons[i].changeColorUnpressed();
              buttonPressedFlag = false;
              background(colorBackground);
              labelGUI();
              initializeButtons();
              switchToPage();
              return outflag;
            }
          }
          if (currentbutton == boffset) {
            offsetFlag = !offsetFlag;
            clearYAxis();
          }
          if (currentbutton == bsmooth) {
            smoothFilterFlag = !smoothFilterFlag;
            if (smoothFilterFlag) {
              downSampleCount = 10;
              bitDepth10 = false;
            }
            else {
              downSampleCount = 1;
              bitDepth10 = true;
            }
            updateSettings();
          }
          if (currentbutton == bclear) {
            datacounter = 0;
            xPos = 0;
            blankPlot();
          }
          if (currentbutton == bpause) {
            pauseFlag = !pauseFlag;
            if (!pauseFlag) {
              buttons[currentbutton].label = "Pause";
              datacounter = 0;
              xPos = 0;
            }
            else if (pauseFlag) {
              buttons[currentbutton].label = "Play";
            }
          }
          if (currentbutton == bchan1) {
            channelsOn[0] = !channelsOn[0];
          }
          if (currentbutton == bchan2) {
            channelsOn[1] = !channelsOn[1];
          }
          if (currentbutton == bchan3) {
            channelsOn[2] = !channelsOn[2];
          }
          if (currentbutton == bchan4) {
            channelsOn[3] = !channelsOn[3];
          }
          if (currentbutton == bchan5) {
            channelsOn[4] = !channelsOn[4];
          }
          if (currentbutton == bchan6) {
            channelsOn[5] = !channelsOn[5];
          }
          if (currentbutton == bchan7) {
            channelsOn[6] = !channelsOn[6];
          }
          if (currentbutton == bchan8) {
            channelsOn[7] = !channelsOn[7];
          }

          labelAxes();
        }
      }
    }
    return outflag;
  }

  public void useSerialEvent() {
  }

  public void drawHelp() {
    drawGenericHelp();
  }

  public void drawTrace() {
    int sigtmp = 0;
    loadPixels();
    while (datacounter > 1) {
      xPos++;//=downSampleCount;
      if (xPos >= plotwidth && !pauseFlag) {
        xPos = -1;
        updatePixels();
        return;
      }
      else if (xPos >= plotwidth && pauseFlag) {
        xPos = plotwidth-1;
        updatePixels();
        return;
      }
      else if (xPos == 0) {
        updatePixels();
        blankPlot();
        return;
      }

      for (int j = 0; j < currentSignalNumber;j++) {
        if (channelsOn[j]) {
          int tmpind = signalindex-datacounter;//*downSampleCount;
          while (tmpind < 0) {
            tmpind+=maxSignalLength;
          }
          if (!offsetFlag) {
            sigtmp = PApplet.parseInt(map((signalIn[j][tmpind]+calibration[j]-halfSignalVal)*scaleVoltage, -maxSignalVal, +maxSignalVal, 0, plotheight));
          }
          else {
            if (channelsOn[4] || channelsOn[5] || channelsOn[6] || channelsOn[7]) {
              sigtmp = offSet8[j]+PApplet.parseInt(map((signalIn[j][tmpind]+calibration[j]-halfSignalVal)*scaleVoltage, -maxSignalVal, +maxSignalVal, -plotheight/(2*currentSignalNumber), plotheight/(2*currentSignalNumber)));
            } 
            else if (channelsOn[3] || channelsOn[2]) {
              sigtmp = offSet4[j]+PApplet.parseInt(map((signalIn[j][tmpind]+calibration[j]-halfSignalVal)*scaleVoltage, -maxSignalVal, +maxSignalVal, -plotheight/(2*currentSignalNumber), plotheight/(2*currentSignalNumber)));
            } 
            else if (channelsOn[1]) {
              sigtmp = offSet2[j]+PApplet.parseInt(map((signalIn[j][tmpind]+calibration[j]-halfSignalVal)*scaleVoltage, -maxSignalVal, +maxSignalVal, -plotheight/(2*currentSignalNumber), plotheight/(2*currentSignalNumber)));
            }
          }
          sigtmp = constrain( sigtmp, pointThickness, plotheight - pointThickness);
          drawMyLine(xPos+xStep-1, ytmp - oldPlotSignal[j], xPos+xStep, ytmp - sigtmp, colorSigM[j], pointThickness);
          oldPlotSignal[j] = sigtmp;
        }
      }
      datacounter --;
    }
    updatePixels();
  }
  
  public void drawFFT() {
    blankPlot();
    stroke(colorFFT);
    // filtered=filter1.apply(signalIn);
    // filtered = signalIn1;

    for (int j = 0; j < currentSignalNumber; j++) {
      System.arraycopy(fft.computeFFT(SignalInFFT[j]), 0, fft_result[j], 0, signalLengthFFT/2);
    }

    for (int i = 2; i<min(fft.WS2,maxPlotFrequency); i++) {
      int xtmp = xStep+PApplet.parseInt(frequencyFactor*PApplet.parseFloat(i-1));
      for (int j = 0; j < currentSignalNumber;j++) {
        if (channelsOn[j]) {
          stroke(colorSigM[j]);
          if (offsetFlag) {
            if (channelsOn[4] || channelsOn[5] || channelsOn[6] || channelsOn[7]) {
              for (int k = 0; k < frequencyFactor; k++) {
                line(xtmp+k, ytmp - yStepFFT - offSet8[j], xtmp+k, min(ytmp-yStepFFT-offSet8[j], max(yTitle+2+offSet8[7-j], ytmp - offSet8[j] - PApplet.parseInt(scaleFFT*fft_result[j][i])/8)) );
              }
            }
            else if (channelsOn[3] || channelsOn[2]) {
              for (int k = 0; k < frequencyFactor; k++) {
                line(xtmp+k, ytmp - yStepFFT - offSet4[j], xtmp+k, min(ytmp-yStepFFT-offSet4[j], max(yTitle+2+offSet4[3-j], ytmp - offSet4[j] - PApplet.parseInt(scaleFFT*fft_result[j][i])/4)) );
              }
            }
            else {
              for (int k = 0; k < frequencyFactor; k++) {
                line(xtmp+k, ytmp - yStepFFT - offSet2[j], xtmp+k, min(ytmp-yStepFFT-offSet2[j], max(yTitle+2+offSet2[1-j], ytmp - offSet2[j] - PApplet.parseInt(scaleFFT*fft_result[j][i])/2)) );
              }
            }
          }
          else {
            line(xtmp, ytmp - yStepFFT, xtmp, min(ytmp-yStepFFT, max(yTitle+2, ytmp - PApplet.parseInt(scaleFFT*fft_result[j][i]))) );
          }
        }
      }
    }
  }
}
/************************* END TimeDomainPlot PAGE ***********************/



/************************* BEGIN WORKOUT PAGE ***********************/
public class workoutPage implements pagesClass {
  // variables
  GuiButton[] buttons;
  int buttonNumber = 0;
  int
    breset = buttonNumber++, 
    bsetreps1 = buttonNumber++, 
    bsetreps2 = buttonNumber++, 
    bthresh1up = buttonNumber++, 
    bthresh1down = buttonNumber++, 
    bthresh2up = buttonNumber++, 
    bthresh2down = buttonNumber++, 
    bchan1 = buttonNumber++, 
    bchan2 = buttonNumber++, 
    bchan1up = buttonNumber++, 
    bchan2up = buttonNumber++, 
    bchan1down = buttonNumber++, 
    bchan2down = buttonNumber++, 
    bchan1name = buttonNumber++, 
    bchan2name = buttonNumber++;


  // workout
  int reps = 0, work = 1;
  int workoutType = reps;
  int repsTargetDefault = 10;
  int repsTarget[] = {     
    repsTargetDefault, repsTargetDefault
  };
  int repThreshDefault = 64;
  int repThresh[] = {    
    repThreshDefault, repThreshDefault
  };
  int repThreshStep = 10;
  int repsCounter[] = {     
    0, 0
  };
  int flexOnCounter[] = {     
    0, 0
  };
  boolean chanFlexed[] = {     
    false, false
  };
  int tRepCounter = 0, tDataLogger = 1;
  int trainingMode = tRepCounter;
  int dataThresh[] = {    
    545, 545
  };
  int[][] tMax;
  int trainChan[] = {    
    0, 1
  };

  String pageName = "FlexVolt Training";
  String typing = "";
  String savedname = "";
  boolean namesFlag = false;
  int namesNumber = 0;
  int repBarWidth = 30;
  int xPos = 0;
  boolean buttonPressedFlag = false;

  // constructor
  workoutPage() {
    // set input variables
    initializeButtons();
  }

  public void initializeButtons() {
    buttons = new GuiButton[buttonNumber];
    buttons[breset]       = new GuiButton("Reset", ' ', dummypage, xStep+halfPlotWidth+65, yTitle+plotheight/2+5, 120, bheights, color(colorBIdle), color(0), "Reset workout", bMomentary, false, showButton);
    buttons[bsetreps1]    = new GuiButton("Setreps1", ' ', dummypage, xStep+halfPlotWidth+30, yTitle+70, 50, bheights, color(colorBIdle), color(0), str(repsTarget[0]), bOnOff, false, showButton);
    buttons[bsetreps2]    = new GuiButton("Setreps2", ' ', dummypage, xStep+halfPlotWidth+30, yTitle+plotheight/2+90, 50, bheights, color(colorBIdle), color(0), str(repsTarget[1]), bOnOff, false, showButton);
    buttons[bthresh1up]   = new GuiButton("repthresh1up", ' ', dummypage, xStep+halfPlotWidth+20, yTitle+plotheight/2-50, 30, bheights, color(colorBIdle), color(0), "up", bMomentary, false, showButton);
    buttons[bthresh1down] = new GuiButton("repthresh1dn", ' ', dummypage, xStep+halfPlotWidth+20, yTitle+plotheight/2-26, 30, bheights, color(colorBIdle), color(0), "dn", bMomentary, false, showButton);
    buttons[bthresh2up]   = new GuiButton("repthresh2up", ' ', dummypage, xStep+halfPlotWidth+20, yTitle+plotheight-29, 30, bheights, color(colorBIdle), color(0), "up", bMomentary, false, showButton);
    buttons[bthresh2down] = new GuiButton("repthresh2dn", ' ', dummypage, xStep+halfPlotWidth+20, yTitle+plotheight-5, 30, bheights, color(colorBIdle), color(0), "dn", bMomentary, false, showButton);
    buttons[bchan1]       = new GuiButton("Chan1", ' ', dummypage, xStep+halfPlotWidth+65, yTitle+40, 30, bheights, color(colorBIdle), colorSigM[trainChan[0]], str(trainChan[0]+1), bOnOff, true, showButton);
    buttons[bchan1name]   = new GuiButton("Name1", ' ', dummypage, xStep+halfPlotWidth+65, yTitle+15, 120, bheights, color(colorBIdle), color(0), "name1", bOnOff, false, showButton);
    buttons[bchan1up]     = new GuiButton("Ch1up", ' ', dummypage, xStep+halfPlotWidth+105, yTitle+40, bheights, bheights, color(colorBIdle), color(0), ">", bMomentary, false, showButton);
    buttons[bchan1down]   = new GuiButton("Ch1dn", ' ', dummypage, xStep+halfPlotWidth+25, yTitle+40, bheights, bheights, color(colorBIdle), color(0), "<", bMomentary, false, showButton);
    buttons[bchan2]       = new GuiButton("Chan2", ' ', dummypage, xStep+halfPlotWidth+65, yTitle+plotheight/2+60, 30, bheights, color(colorBIdle), colorSigM[trainChan[1]], str(trainChan[1]+1), bOnOff, false, showButton);
    buttons[bchan2name]   = new GuiButton("Name2", ' ', dummypage, xStep+halfPlotWidth+65, yTitle+plotheight/2+35, 120, bheights, color(colorBIdle), color(0), "name2", bOnOff, false, showButton);
    buttons[bchan2up]     = new GuiButton("Ch2up", ' ', dummypage, xStep+halfPlotWidth+105, yTitle+plotheight/2+60, bheights, bheights, color(colorBIdle), color(0), ">", bMomentary, false, showButton);
    buttons[bchan2down]   = new GuiButton("Ch2dn", ' ', dummypage, xStep+halfPlotWidth+25, yTitle+plotheight/2+60, bheights, bheights, color(colorBIdle), color(0), "<", bMomentary, false, showButton);
  }

  public void switchToPage() {

    downSampleCount = downSampleCountTraining; //!!!!!!!!!!!!!!!
    userFreqIndex = userFreqIndexTraining;
    userFrequency = userFreqArray[userFreqIndex];
    checkSerialDelay = (long)max( checkSerialMinTime, 1000.0f/((float)userFrequency/checkSerialNSamples) );
    smoothFilterFlag = true;
    bitDepth10 = false;
    offsetFlag = true;
    pauseFlag = false;
    channelsOn[trainChan[0]] = true;
    channelsOn[trainChan[1]] = true;
    buttons[bchan1].bOn = channelsOn[trainChan[0]];
    buttons[bchan2].bOn = channelsOn[trainChan[1]];
    plotwidth = halfPlotWidth;
    //    background(colorBackground);
    labelAxes();
    blankPlot();
    updateSettings();
    println("workout Turned ON");
  }

  public void drawPage() {
    if (buttonPressedFlag) {
      if (millis() > buttonColorTimer) {
        buttonPressedFlag = false;
        println("Current Button = " + currentbutton);
        if (buttons[currentbutton] != null && currentbutton < buttons.length) {
          buttons[currentbutton].changeColorUnpressed();
        }
      }
    }

    drawTrace();
    drawThresh();
    if (trainingMode == tRepCounter) {
      countreps();
      drawRepBar();
    }
  }

  public String getPageName() {
    return pageName;
  }

  public void labelAxes() {
    fill(colorLabel);
    stroke(colorLabel);
    strokeWeight(2);
    textAlign(CENTER, CENTER);

    // title
    textSize(titlesize);
    text("Flex Training", xStep+fullPlotWidth/2+20, yTitle-45);

    // y-axis
    float val = 0;
    textSize(20);
    for (int i = 0; i < nYTicksHalf+1; i++) {
      text(nf(val, 1, 0), xStep-25, ytmp - PApplet.parseInt(map(val, 0, maxVoltage, 0, plotheight/2-20)));
      text(nf(val, 1, 0), xStep-25, ytmp - PApplet.parseInt(map(val, 0, maxVoltage, 0, plotheight/2-10)) - plotheight/2 - 10);
      val += (maxVoltage)/nYTicksHalf;
    }

    textSize(labelsizes);
    translate(15, height/2);
    rotate(-PI/2);
    text("Muscle Voltage, mV", 0, 0);
    rotate(PI/2);
    translate(-15, -height/2);

    textSize(labelsizes);
    // fill(100);
    // rectMode(CENTER);
    // rect(xStep+580, 230, 100, 50,15);
    // rect(xStep+580, yTitle+plotheight-150, 100, 50,15);
    fill(colorLabel);
    text("Set reps", xStep+plotwidth+100, yTitle+70);
    text("Set reps", xStep+plotwidth+100, yTitle+plotheight/2+90);
    text("Threshold", xStep+plotwidth+90, yTitle+plotheight/2-40);
    text("Threshold", xStep+plotwidth+90, yTitle+plotheight-20);

    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        buttons[i].drawButton();
      }
    }

    labelRepBar(3);
  }

  public boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
    boolean outflag = false;

    if (namesFlag) {
      if (key == '\n' ) {
        println("here");
        println(typing);
        int tmpint = 0;
        savedname = typing;
        if (namesNumber == bsetreps1 || namesNumber == bsetreps2) {
          tmpint = getIntFromString(typing, repsTargetDefault);
          savedname = str(tmpint);
        }
        buttons[namesNumber].label = savedname;
        if (namesNumber == bsetreps1) {
          repsTarget[0] = tmpint;
          clearRepBar(1);
          labelRepBar(1);
        }
        else if (namesNumber == bsetreps2) {
          repsTarget[1] = tmpint;
          clearRepBar(2);
          labelRepBar(2);
        }
        namesFlag = !namesFlag;
        buttons[currentbutton].bOn = !buttons[currentbutton].bOn;
        buttons[namesNumber].drawButton();
        typing = "";
        namesNumber = -1;
        outflag = true;
      }
      else if ((key >= 'a' && key <= 'z') || (key >= 'A' && key <= 'Z') || (key == ' ') || (key >='0' && key <= '9')) {
        // Otherwise, concatenate the String - Each character typed by the user is added to the end of the String variable.
        typing = typing + key;
        buttons[namesNumber].label = typing;
        buttons[namesNumber].drawButton();
        outflag = true;
      }
    }
    else if (!namesFlag) {
      currentbutton = -1;
      for (int i = 0; i < buttons.length; i++) {
        if (buttons[i] != null) {
          if ( (inputDev == mouseInput && buttons[i].IsMouseOver(x, y)) || (inputDev == keyInput && tkey == buttons[i].hotKey) ) {
            outflag = true;
            buttons[i].bOn = !buttons[i].bOn;
            buttons[i].changeColorPressed();
            buttonColorTimer = millis()+buttonColorDelay;
            buttonPressedFlag = true;
            currentbutton = i;

            if (currentbutton == breset) {
              resetworkout();
            }
            if (currentbutton == bsetreps1 || currentbutton == bsetreps2 || currentbutton == bchan1name || currentbutton == bchan2name) {
              if (namesNumber == currentbutton) {
                int tmpint = 0;
                savedname = typing;
                if (namesNumber == bsetreps1 || namesNumber == bsetreps2) {
                  tmpint = getIntFromString(typing, repsTargetDefault);
                  savedname = str(tmpint);
                }
                println(tmpint);
                buttons[namesNumber].label = savedname;
                if (namesNumber == bsetreps1) {
                  repsTarget[0] = tmpint;
                  println("int saved");
                  println(repsTarget[0]);
                  clearRepBar(1);
                  labelRepBar(1);
                }
                else if (namesNumber == bsetreps2) {
                  repsTarget[1] = tmpint;
                  println("int saved");
                  println(repsTarget[0]);
                  clearRepBar(2);
                  labelRepBar(2);
                }

                namesFlag = !namesFlag;
                //buttons[currentbutton].bOn = !buttons[currentbutton].bOn;

                buttons[namesNumber].drawButton();
                typing = "";
                namesNumber = -1;
              }
              else {
                namesNumber = currentbutton;
                namesFlag = true;
                buttons[currentbutton].bOn = true;
                typing = "";
                buttons[namesNumber].label = typing;
                buttons[namesNumber].drawButton();
              }
              println("Names Toggled");
            }
            if (currentbutton == bchan1) {
              channelsOn[0] = !channelsOn[0];
              println("Chan1 Toggled");
            }
            if (currentbutton == bchan2) {
              channelsOn[1] = !channelsOn[1];
              println("Chan2 Toggled");
            }
            if (currentbutton == bchan1up) {
              trainChan[0]++;
              if (trainChan[0]>=currentSignalNumber) {
                trainChan[0]=currentSignalNumber-1;
              }
              if (trainChan[0] == trainChan[1]) {
                trainChan[0]++;
                if (trainChan[0]>=currentSignalNumber) {
                  trainChan[0]=trainChan[1]-1;
                }
              }
              buttons[bchan1].ctext = colorSigM[trainChan[0]];
              buttons[bchan1].label = str(trainChan[0]+1);
              buttons[bchan1].drawButton();
              channelsOn[trainChan[0]] = buttons[bchan1].bOn;
            }
            if (currentbutton == bchan1down) {
              trainChan[0]--;
              if (trainChan[0]<0) {
                trainChan[0]=0;
              }
              if (trainChan[0] == trainChan[1]) {
                trainChan[0]--;
                if (trainChan[0]<0) {
                  trainChan[0]=trainChan[1]+1;
                }
              }
              buttons[bchan1].ctext = colorSigM[trainChan[0]];
              buttons[bchan1].label = str(trainChan[0]+1);
              buttons[bchan1].drawButton();
              channelsOn[trainChan[0]] = buttons[bchan1].bOn;
            }
            if (currentbutton == bchan2up) {
              trainChan[1]++;
              if (trainChan[1]>=currentSignalNumber) {
                trainChan[1]=currentSignalNumber-1;
              }
              if (trainChan[1] == trainChan[0]) {
                trainChan[1]++;
                if (trainChan[1]>=currentSignalNumber) {
                  trainChan[1]=trainChan[0]-1;
                }
              }
              buttons[bchan2].ctext = colorSigM[trainChan[1]];
              buttons[bchan2].label = str(trainChan[1]+1);
              buttons[bchan2].drawButton();
              channelsOn[trainChan[1]] = buttons[bchan2].bOn;
            }
            if (currentbutton == bchan2down) {
              trainChan[1]--;
              if (trainChan[1]<0) {
                trainChan[1]=0;
              }
              if (trainChan[1] == trainChan[0]) {
                trainChan[1]--;
                if (trainChan[1]<0) {
                  trainChan[1]=trainChan[0]+1;
                }
              }
              buttons[bchan2].ctext = colorSigM[trainChan[1]];
              buttons[bchan2].label = str(trainChan[1]+1);
              buttons[bchan2].drawButton();
              channelsOn[trainChan[1]] = buttons[bchan2].bOn;
            }
            if (currentbutton == bthresh1up) {
              repThresh[0]+=repThreshStep;
              if (repThresh[0]>=maxSignalVal) {
                repThresh[0]=maxSignalVal;
              }
            }
            if (currentbutton == bthresh1down) {
              repThresh[0]-=repThreshStep;
              if (repThresh[0]<0) {
                repThresh[0]=0;
              }
            }
            if (currentbutton == bthresh2up) {
              repThresh[1]+=repThreshStep;
              if (repThresh[1]>=maxSignalVal) {
                repThresh[1]=maxSignalVal;
              }
            }
            if (currentbutton == bthresh2down) {
              repThresh[1]-=repThreshStep;
              if (repThresh[1]<0) {
                repThresh[1]=0;
              }
            }

            labelAxes();
          }
        }
      }
    }
    return outflag;
  }

  public boolean useKeyPressed() {
    boolean outflag = false;
    if (namesFlag) {
      if (key == '\n' ) {
        println("here");
        println(typing);
        int tmpint = 0;
        savedname = typing;
        if (namesNumber == bsetreps1 || namesNumber == bsetreps2) {
          tmpint = getIntFromString(typing, repsTargetDefault);
          println(tmpint);
          savedname = str(tmpint);
        }
        buttons[namesNumber].label = savedname;
        if (namesNumber == bsetreps1) {
          repsTarget[0] = tmpint;
          println("int saved");
          println(repsTarget[0]);
          clearRepBar(1);
          labelRepBar(1);
        }
        else if (namesNumber == bsetreps2) {
          repsTarget[1] = tmpint;
          println("int saved");
          println(repsTarget[0]);
          clearRepBar(2);
          labelRepBar(2);
        }
        namesFlag = !namesFlag;
        buttons[currentbutton].bOn = !buttons[currentbutton].bOn;

        buttons[namesNumber].drawButton();
        typing = "";
        namesNumber = -1;
        outflag = true;
      }
      else if ((key >= 'a' && key <= 'z') || (key >= 'A' && key <= 'Z') || (key == ' ') || (key >='0' && key <= '9')) {
        // Otherwise, concatenate the String
        // Each character typed by the user is added to the end of the String variable.
        typing = typing + key;
        buttons[namesNumber].label = typing;
        buttons[namesNumber].drawButton();
        println("adjusting");
        outflag = true;
      }
    }
    return outflag;
  }

  public void useSerialEvent() {
  }

  public void useMousePressed() {
    currentbutton = -1;
    println("mouse pressed");
    int x = mouseX, y = mouseY;
    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        if (buttons[i].IsMouseOver(x, y)) {
          buttons[i].bOn = !buttons[i].bOn;
          buttons[i].changeColorPressed();
          currentbutton = i;
          buttonColorTimer = millis()+buttonColorDelay;
          buttonPressedFlag = true;
        }
      }
    }
    if (currentbutton == breset) {
      resetworkout();
    }
    if (currentbutton == bsetreps1 || currentbutton == bsetreps2 || currentbutton == bchan1name || currentbutton == bchan2name) {
      if (namesNumber == currentbutton) {
        int tmpint = 0;
        savedname = typing;
        if (namesNumber == bsetreps1 || namesNumber == bsetreps2) {
          tmpint = getIntFromString(typing, repsTargetDefault);
          savedname = str(tmpint);
        }
        println(tmpint);
        buttons[namesNumber].label = savedname;
        if (namesNumber == bsetreps1) {
          repsTarget[0] = tmpint;
          println("int saved");
          println(repsTarget[0]);
          clearRepBar(1);
          labelRepBar(1);
        }
        else if (namesNumber == bsetreps2) {
          repsTarget[1] = tmpint;
          println("int saved");
          println(repsTarget[0]);
          clearRepBar(2);
          labelRepBar(2);
        }

        namesFlag = !namesFlag;
        //buttons[currentbutton].bOn = !buttons[currentbutton].bOn;

        buttons[namesNumber].drawButton();
        typing = "";
        namesNumber = -1;
      }
      else {
        namesNumber = currentbutton;
        namesFlag = true;
        buttons[currentbutton].bOn = true;
        typing = "";
        buttons[namesNumber].label = typing;
        buttons[namesNumber].drawButton();
      }
      println("Names Toggled");
    }
    if (currentbutton == bchan1) {
      channelsOn[0] = !channelsOn[0];
      println("Chan1 Toggled");
    }
    if (currentbutton == bchan2) {
      channelsOn[1] = !channelsOn[1];
      println("Chan2 Toggled");
    }
    if (currentbutton == bchan1up) {
      trainChan[0]++;
      if (trainChan[0]>=currentSignalNumber) {
        trainChan[0]=currentSignalNumber-1;
      }
      if (trainChan[0] == trainChan[1]) {
        trainChan[0]++;
        if (trainChan[0]>=currentSignalNumber) {
          trainChan[0]=trainChan[1]-1;
        }
      }
      buttons[bchan1].ctext = colorSigM[trainChan[0]];
      buttons[bchan1].label = str(trainChan[0]+1);
      buttons[bchan1].drawButton();
      channelsOn[trainChan[0]] = buttons[bchan1].bOn;
    }
    if (currentbutton == bchan1down) {
      trainChan[0]--;
      if (trainChan[0]<0) {
        trainChan[0]=0;
      }
      if (trainChan[0] == trainChan[1]) {
        trainChan[0]--;
        if (trainChan[0]<0) {
          trainChan[0]=trainChan[1]+1;
        }
      }
      buttons[bchan1].ctext = colorSigM[trainChan[0]];
      buttons[bchan1].label = str(trainChan[0]+1);
      buttons[bchan1].drawButton();
      channelsOn[trainChan[0]] = buttons[bchan1].bOn;
    }
    if (currentbutton == bchan2up) {
      trainChan[1]++;
      if (trainChan[1]>=currentSignalNumber) {
        trainChan[1]=currentSignalNumber-1;
      }
      if (trainChan[1] == trainChan[0]) {
        trainChan[1]++;
        if (trainChan[1]>=currentSignalNumber) {
          trainChan[1]=trainChan[0]-1;
        }
      }
      buttons[bchan2].ctext = colorSigM[trainChan[1]];
      buttons[bchan2].label = str(trainChan[1]+1);
      buttons[bchan2].drawButton();
      channelsOn[trainChan[1]] = buttons[bchan2].bOn;
    }
    if (currentbutton == bchan2down) {
      trainChan[1]--;
      if (trainChan[1]<0) {
        trainChan[1]=0;
      }
      if (trainChan[1] == trainChan[0]) {
        trainChan[1]--;
        if (trainChan[1]<0) {
          trainChan[1]=trainChan[0]+1;
        }
      }
      buttons[bchan2].ctext = colorSigM[trainChan[1]];
      buttons[bchan2].label = str(trainChan[1]+1);
      buttons[bchan2].drawButton();
      channelsOn[trainChan[1]] = buttons[bchan2].bOn;
    }
    if (currentbutton == bthresh1up) {
      repThresh[0]+=repThreshStep;
      if (repThresh[0]>=maxSignalVal) {
        repThresh[0]=maxSignalVal;
      }
    }
    if (currentbutton == bthresh1down) {
      repThresh[0]-=repThreshStep;
      if (repThresh[0]<0) {
        repThresh[0]=0;
      }
    }
    if (currentbutton == bthresh2up) {
      repThresh[1]+=repThreshStep;
      if (repThresh[1]>=maxSignalVal) {
        repThresh[1]=maxSignalVal;
      }
    }
    if (currentbutton == bthresh2down) {
      repThresh[1]-=repThreshStep;
      if (repThresh[1]<0) {
        repThresh[1]=0;
      }
    }
  }

  public void drawHelp() {
    drawGenericHelp();
  }

  public void drawTrace() {
    int sigtmp = 0;
    loadPixels();
    while (datacounter > 1) {
      xPos++;//=downSampleCount;
      if (xPos >= plotwidth && !pauseFlag) {
        xPos = -1;
        updatePixels();
        return;
      }
      else if (xPos >= plotwidth && pauseFlag) {
        xPos = plotwidth-1;
        updatePixels();
        return;
      }
      else if (xPos == 0) {
        updatePixels();
        blankPlot();
        return;
      }

      for (int j = 0; j < currentSignalNumber;j++) {
        if (channelsOn[j]) {
          if (j == trainChan[0] || j == trainChan[1]) {
            int tmpind = signalindex-datacounter;//*downSampleCount;
            while (tmpind < 0) {
              tmpind+=maxSignalLength;
            }
            if (j == trainChan[0]) {
              sigtmp = PApplet.parseInt(map((signalIn[j][tmpind]+calibration[j] - halfSignalVal)*scaleVoltage, 0, maxSignalVal, plotheight/2, plotheight));
              sigtmp = constrain(sigtmp, plotheight/2+pointThickness+1, plotheight-pointThickness-1);
            }
            if (j==trainChan[1]) {
              sigtmp = PApplet.parseInt(map((signalIn[j][tmpind]+calibration[j] - halfSignalVal)*scaleVoltage, 0, maxSignalVal, 0, plotheight/2));
              sigtmp = constrain(sigtmp, pointThickness+1, plotheight/2 - pointThickness-1)-plot2offset;
            }
            drawMyLine(xPos+xStep-1, ytmp - oldPlotSignal[j], xPos+xStep, ytmp - sigtmp, colorSigM[j], pointThickness);
            oldPlotSignal[j] = sigtmp;
          }
        }
      }
      datacounter --;
    }
    updatePixels();
  }

  public void drawThresh() {
    int sigtmp;
    stroke(255, 255, 0);
    strokeWeight(1);

    // channel 1
    sigtmp = PApplet.parseInt(map(repThresh[0], 0, maxSignalVal, plotheight/2, plotheight));
    sigtmp = constrain(sigtmp, plotheight/2 + pointThickness, plotheight-pointThickness);
    line(xStep, ytmp-sigtmp, xStep+plotwidth, ytmp-sigtmp);

    // channel 2
    sigtmp = PApplet.parseInt(map(repThresh[1], 0, maxSignalVal, 0-plot2offset, plotheight/2-plot2offset));
    sigtmp = constrain(sigtmp, pointThickness-plot2offset, plotheight/2-pointThickness-plot2offset);
    line(xStep, ytmp-sigtmp, xStep+plotwidth, ytmp-sigtmp);
  }

  public void resetworkout() {
    chanFlexed[0] = false;
    chanFlexed[0] = false;
    repsCounter[0] = 0;
    repsCounter[1] = 0;
    flexOnCounter[0] = 0;
    flexOnCounter[1] = 0;
    if (trainingMode == tRepCounter) {
      clearRepBar(3);
      labelRepBar(3);
    }
    else if (trainingMode == tDataLogger) {
      tMax = new int[2][100];
      clearRepBar(3);
      labelTData();
    }
  }

  public void labelTData() {
    textAlign(CENTER, CENTER);
    stroke(0);
    fill(0);
    text("Max Voltages", xStep+880, 40);
  }

  public void countreps() {
    int tmpind = 0;
    tmpind = signalindex-datacounter;
    while (tmpind < 0) {
      tmpind+=maxSignalLength;
    }
    for (int i = 0; i < 2; i++) {
      if (channelsOn[trainChan[i]]) {
        if ((signalIn[trainChan[i]][tmpind]-halfSignalVal)>repThresh[i]) {
          if (!chanFlexed[i]) {
            flexOnCounter[i]++;
            if (flexOnCounter[i] > 2) {
              chanFlexed[i] = true;
              if (repsCounter[i] < repsTarget[i]) {
                repsCounter[i]++;
              }
              flexOnCounter[i]=0;
            }
          }
        }
        else if ((signalIn[trainChan[i]][tmpind]-halfSignalVal)<repThresh[i]) {
          chanFlexed[i] = false;
          flexOnCounter[i] = 0;
        }
      }
    }
  }

  public void clearRepBar(int barN) {
    fill(colorBackground);
    stroke(colorBackground);
    rectMode(CENTER);
    if (barN == 1 || barN == 3) {
      rect(xStep+plotwidth+200, yTitle+plotheight/2, 80, plotheight-40);
    }
    if (barN == 2 || barN == 3) {
      rect(xStep+plotwidth+300, yTitle+plotheight/2, 80, plotheight-40);
    }
  }

  public void drawRepBar() {
    if (channelsOn[trainChan[0]]) {
      int top = min(plotheight, PApplet.parseInt(map(repsCounter[0], 0, repsTarget[0], 0, plotheight-60)));
      rectMode(CENTER);
      stroke(0);
      strokeWeight(2);
      fill(colorSigM[trainChan[0]]);
      rect(xStep+plotwidth+200, ytmp-top/2-20, repBarWidth, top);
    }
    if (channelsOn[trainChan[1]]) {
      int top = min(plotheight, PApplet.parseInt(map(repsCounter[1], 0, repsTarget[1], 0, plotheight-60)));
      rectMode(CENTER);
      stroke(0);
      fill(colorSigM[trainChan[1]]);
      rect(xStep+plotwidth+300, ytmp-top/2-20, repBarWidth, top);
    }
    rectMode(CENTER);
  }

  public void labelRepBar(int ChanN) {
    int val;
    textAlign(CENTER, CENTER);
    stroke(colorLabel);
    fill(colorLabel);
    if (ChanN == 1 || ChanN == 3) {
      if (channelsOn[trainChan[0]]) {
        val = 0;
        for (int i = 0; i <= repsTarget[0]; i++) {
          text(nf(val, 1, 0), plotwidth+220, ytmp - 20 - PApplet.parseInt(map(val, 0, repsTarget[0], 0, plotheight-60)));
          val ++;
        }
        text(buttons[bchan1].label, plotwidth+260, yTitle+20);
      }
    }
    if (ChanN == 2 || ChanN == 3) {
      if (channelsOn[trainChan[1]]) {
        val = 0;
        for (int i = 0; i <= repsTarget[1]; i++) {
          text(nf(val, 1, 0), plotwidth+320, ytmp - 20 - PApplet.parseInt(map(val, 0, repsTarget[1], 0, plotheight-60)));
          val ++;
        }
        text(buttons[bchan2].label, plotwidth+360, yTitle+20);
      }
    }
  }

  public void tLogData() {
    for (int i = 0; i < 2; i++) {
      if (channelsOn[i]) {
        if (signalIn[trainChan[i]][signalindex]>dataThresh[i]) {
          if (!chanFlexed[i]) {
            flexOnCounter[i]++;
            if (flexOnCounter[i] > 15) {
              chanFlexed[i] = true;
              repsCounter[i]++;
              //flexOnCounter[i]=0;
            }
          }
          else if (chanFlexed[i]) {
            tMax[i][repsCounter[i]] = max(tMax[i][repsCounter[i]], PApplet.parseInt(signalIn[trainChan[i]][signalindex]));
          }
        }
        else if (signalIn[trainChan[i]][signalindex]<dataThresh[i]) {
          if (chanFlexed[i]) {
            flexOnCounter[i]--;
            if (flexOnCounter[i] <= 0) {
              chanFlexed[i] = false;
              flexOnCounter[i] = 0;
            }
          }
        }
      }
    }
  }

  public void drawTData() {
    int xstart = 750;
    int sigtmp = 0;
    for (int i = 0; i < 100; i++) {
      int j = 0;
      if (channelsOn[j]) {
        stroke(0, 255, 0);
        fill(0, 255, 0);
        sigtmp = PApplet.parseInt(map(tMax[j][i], maxSignalVal/2, maxSignalVal, 0, plotheight));
        sigtmp = max(sigtmp, 0);
        line(xstart, yTitle+plotheight/2, xstart, yTitle+plotheight/2-sigtmp);
        line(xstart+1, yTitle+plotheight/2, xstart+1, yTitle+plotheight/2-sigtmp);
      }
      j = 1;
      if (channelsOn[j]) {
        stroke(0, 0, 255);
        fill(0, 0, 255);
        sigtmp = PApplet.parseInt(map(tMax[j][i], maxSignalVal/2, maxSignalVal, 0, plotheight));
        sigtmp = max(sigtmp, 0);
        line(xstart, yTitle+plotheight, xstart, yTitle+plotheight-sigtmp);
        line(xstart+1, yTitle+plotheight, xstart+1, yTitle+plotheight-sigtmp);
      }
      xstart+=4;
    }
  }
}
//############################END WORKOUT PAGE#######################################


/************************* BEGIN TARGET PRACTICE Page ***********************/
public class TargetPracticePage implements pagesClass {
  // variables
  GuiButton[] buttons;
  int buttonNumber = 0;
  int
    bclear = buttonNumber++, 
  bpause = buttonNumber++, 
//  bchan1 = buttonNumber++, 
//  bchan2 = buttonNumber++, 
  b2chctrl = buttonNumber++,
  b4chctrl = buttonNumber++,
  badjustthresh = buttonNumber++;
//  bchan1up = buttonNumber++, 
//  bchan2up = buttonNumber++, 
//  bchan3up = buttonNumber++, 
//  bchan4up = buttonNumber++, 
//  bchan1down = buttonNumber++, 
//  bchan2down = buttonNumber++, 
//  bchan3down = buttonNumber++, 
//  bchan4down = buttonNumber++;

  // MouseGame
  int gameTargetX;
  int gameTargetY;
  int gamedelayTime = 10;
  int gamedelayTimeMin = 1;
  int gamedelaymaxPlotTime = 10;
  int gamedelayTimeIncrement = 1;
  int gamenextStep;
  int gametargetsize = 60;
  int gameScore = 0;
  boolean mouseTuneFlag = false;
  char mouseAxis = 'X';
  boolean mouseXAxisFlip = false;
  boolean mouseYAxisFlip = false;

  int threshStep = 4;
  int mouseThreshStandOff = 5;
  int mouseThreshInd = 0;
  int xMouseFactor1 = 2;
  int xMouseFactor2 = 2;
  int xMouseFactor3 = 2;
  int yMouseFactor1 = 2;
  int yMouseFactor2 = 2;
  int yMouseFactor3 = 2;
  int xMouse=0, yMouse=0;
  int mouseSpeed = 3;
  boolean buttonPressedFlag = false;
  String pageName = "Target Practice";

  // constructor
  TargetPracticePage() {
    // set input variables
    // Mouse Page Buttons
    initializeButtons();
  }

  public void initializeButtons() {
    buttons = new GuiButton[buttonNumber];
    int buttony = yTitle+195;
    int controlsy = yTitle+30;
    buttons[bpause]        = new GuiButton("Pause",    'p', dummypage, xStep+plotwidth+45, controlsy+10, 60, bheight, color(colorBIdle), color(0), "Play", bOnOff, false, showButton);
    buttons[bclear]        = new GuiButton("Clear",    'c', dummypage, xStep+plotwidth+45, controlsy+40, 60, bheight, color(colorBIdle), color(0), "Clear", bMomentary, false, showButton);
    buttons[b2chctrl]      = new GuiButton("M2chCtrl", '2', dummypage, xStep+plotwidth+27, yTitle+150, 36, bheight, color(colorBIdle), color(0), "2Ch", bOnOff, true, showButton);
    buttons[b4chctrl]      = new GuiButton("M4chCtrl", '4', dummypage, xStep+plotwidth+63, yTitle+150, 36, bheight, color(colorBIdle), color(0), "4Ch", bOnOff, false, showButton);
    buttons[badjustthresh] = new GuiButton("Adjthresh",'a', dummypage, xStep+90, yTitle+plotheight+20, 170, bheight, color(colorBIdle), color(0), "Adjust Thresholds 'a'", bOnOff, false, showButton);

//    buttons[bchan1up]  = new GuiButton("MChan1up", ' ', dummypage, xStep+plotwidth+80, yTitle+200, 20, 20, color(colorBIdle), color(0), ">", bMomentary, false, showButton);
//    buttons[bchan1down]= new GuiButton("MChan1down", ' ', dummypage, xStep+plotwidth+16, yTitle+200, 20, 20, color(colorBIdle), color(0), "<", bMomentary, false, showButton);
//    buttons[bchan2up]  = new GuiButton("MChan2up", ' ', dummypage, xStep+plotwidth+80, yTitle+250, 20, 20, color(colorBIdle), color(0), ">", bMomentary, false, showButton);
//    buttons[bchan2down]= new GuiButton("MChan2down", ' ', dummypage, xStep+plotwidth+16, yTitle+250, 20, 20, color(colorBIdle), color(0), "<", bMomentary, false, showButton);
//    buttons[bchan3up]  = new GuiButton("MChan3up", ' ', dummypage, xStep+plotwidth+80, yTitle+300, 20, 20, color(colorBIdle), color(0), ">", bMomentary, false, hideButton);
//    buttons[bchan3down]= new GuiButton("MChan3down", ' ', dummypage, xStep+plotwidth+16, yTitle+300, 20, 20, color(colorBIdle), color(0), "<", bMomentary, false, hideButton);
//    buttons[bchan4up]  = new GuiButton("MChan4up", ' ', dummypage, xStep+plotwidth+80, yTitle+350, 20, 20, color(colorBIdle), color(0), ">", bMomentary, false, hideButton);
//    buttons[bchan4down]= new GuiButton("MChan5down", ' ', dummypage, xStep+plotwidth+16, yTitle+350, 20, 20, color(colorBIdle), color(0), "<", bMomentary, false, hideButton);

  }

  public void switchToPage() {
    plotwidth = fullPlotWidth;

    downSampleCount = downSampleCountMouse; //!!!!!!!!!!!!!!!
    userFreqIndex = userFreqIndexMouse;
    userFrequency = userFreqArray[userFreqIndex];
    checkSerialDelay = (long)max( checkSerialMinTime, 1000.0f/((float)userFrequency/checkSerialNSamples) );

    pauseFlag = true;
    smoothFilterFlag = true;
    bitDepth10 = false;
    channelsOn[mouseChan[0]] = true;
    channelsOn[mouseChan[1]] = true;
//    buttons[bchan1].bOn = channelsOn[mouseChan[0]];
//    buttons[bchan2].bOn = channelsOn[mouseChan[1]];
    buttons[bpause].bOn = pauseFlag;

    updateSettings();
    //    background(colorBackground);
    labelAxes();
    blankPlot();
    drawTarget();
    gamenextStep = second()+gamedelayTime;
    println(gamenextStep);
    gameScore = 0;
    println("Mouse Turned ON");
    xMouse = xx+width/2;
    yMouse = yy+height/2;
    robot.mouseMove(xMouse, yMouse);
    mouseTuneFlag = false;
  }

  public void drawPage() {
    // draw subfunctions
    if (buttonPressedFlag) {
      if (millis() > buttonColorTimer) {
        buttonPressedFlag = false;
        println("Current Button = " + currentbutton);
        if (buttons[currentbutton] != null && currentbutton < buttons.length) {
          buttons[currentbutton].changeColorUnpressed();
        }
      }
    }

    drawTargetPractice();
  }

  public String getPageName() {
    return pageName;
  }

  public void labelAxes() {
    fill(colorLabel);
    stroke(colorLabel);
    strokeWeight(2);
    textAlign(CENTER, CENTER);

    // title
    textSize(titlesize);
    text("Flex Mouse", xStep+fullPlotWidth/2+20, yTitle-45);


    // blankPlot();
    for (int i = 0; i < buttons.length; i++) {
      buttons[i].drawButton();
    }
    
    textSize(labelsize);
    text("Plotting", xStep+fullPlotWidth+45, yTitle+10);
    text("Control", xStep+fullPlotWidth+45,yTitle+100);
    text("Mode", xStep+fullPlotWidth+45,yTitle+120);
    
    textSize(labelsizes);
    text("'p' (pause) to get your mouse back!", xStep+plotwidth/2+80, yTitle+plotheight+15);
//    text("'k' = set sensitivity for mouse control.", xStep+plotwidth/2, yTitle+plotheight+26);
//    text("x=left/right", xStep+plotwidth+barWidth/2, yTitle+120);
//    text("y=up/down", xStep+plotwidth+barWidth/2, yTitle+140);
    
    
    if (buttons[b2chctrl].bOn){
      textSize(labelsizexs);
      text("X-Axis", xStep+fullPlotWidth+30, yTitle+190);
      text("Y-Axis", xStep+fullPlotWidth+30, yTitle+220);
      
      
      fill(colorPlotBackground);
      rect(xStep+plotwidth+70, yTitle+190, 25, bheight);
      rect(xStep+plotwidth+70, yTitle+220, 25, bheight);
      fill(colorSigM[mouseChan[0]]);
      text(""+(mouseChan[0]+1),xStep+plotwidth+70, yTitle+190-2);
      fill(colorSigM[mouseChan[1]]);
      text(""+(mouseChan[1]+1),xStep+plotwidth+70, yTitle+220-2);
    } else if (buttons[b4chctrl].bOn){
      textSize(labelsizexs);
      text("Left",  xStep+fullPlotWidth+30, yTitle+190);
      text("Right", xStep+fullPlotWidth+30, yTitle+220);
      text("Up",    xStep+fullPlotWidth+30, yTitle+250);
      text("Down",  xStep+fullPlotWidth+30, yTitle+280);
      
      
      fill(colorPlotBackground);
      rect(xStep+plotwidth+70, yTitle+190, 25, bheight);
      rect(xStep+plotwidth+70, yTitle+220, 25, bheight);
      rect(xStep+plotwidth+70, yTitle+250, 25, bheight);
      rect(xStep+plotwidth+70, yTitle+280, 25, bheight);
      fill(colorSigM[mouseChan[0]]);
      text(""+(mouseChan[0]+1),xStep+plotwidth+70, yTitle+190-2);
      fill(colorSigM[mouseChan[1]]);
      text(""+(mouseChan[1]+1),xStep+plotwidth+70, yTitle+220-2);
      fill(colorSigM[mouseChan[2]]);
      text(""+(mouseChan[2]+1),xStep+plotwidth+70, yTitle+250-2);
      fill(colorSigM[mouseChan[3]]);
      text(""+(mouseChan[3]+1),xStep+plotwidth+70, yTitle+280-2);
    }
  }

  public boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
    boolean outflag = false;

    if (key == 'F' || key == 'f') {
      if (mouseAxis == 'X') {
        mouseXAxisFlip = !mouseXAxisFlip;
        print("xMouseAxis Flipped. Axis = ");
        println(mouseXAxisFlip);
      }
      else if (mouseAxis == 'Y') {
        mouseYAxisFlip = !mouseYAxisFlip;
        print("MouseYAxis Flipped. Axis = ");
        println(mouseYAxisFlip);
      }
      //      outflag = true;
      return outflag = true;
    }
    if (key == 'K' || key == 'k') {
      mouseTuneFlag = !mouseTuneFlag;
      if (!mouseTuneFlag) {
        drawTarget();
        gamenextStep = second()+gamedelayTime;
        println(gamenextStep);
        gameScore = 0;
      }
      outflag = true;
    }
    if (mouseTuneFlag) {
      if (key == CODED) {
        if (keyCode == LEFT) {
          mouseThreshInd --;
          if (mouseThreshInd < 0) {
            mouseThreshInd = 3;
          }
          outflag = true;
        }
        else if (keyCode == RIGHT) {
          mouseThreshInd ++;
          if (mouseThreshInd > 3) {
            mouseThreshInd = 0;
          }
          outflag = true;
        }
        else if (keyCode == UP) {
          if (buttons[b2chctrl].bOn){
            if (mouseThreshInd == thresh2chyLow && mouseThresh2Ch[thresh2chyLow] > (mouseThresh2Ch[thresh2chyHigh]-mouseThreshStandOff)) {
              // do nothing - can't have low >= high!
            }
            else if (mouseThreshInd == thresh2chxLow && mouseThresh2Ch[thresh2chxLow] > (mouseThresh2Ch[thresh2chxHigh]-mouseThreshStandOff)) {
              // do nothing - can't have low >= high!
            }
            else {
              mouseThresh2Ch[mouseThreshInd] = constrain(mouseThresh2Ch[mouseThreshInd]+threshStep, maxSignalVal, maxSignalVal*2);
            }
            println("New mouseThresh = "+mouseThresh2Ch[mouseThreshInd]);
          }
          else if (buttons[b4chctrl].bOn){
            mouseThresh4Ch[mouseThreshInd] = constrain(mouseThresh4Ch[mouseThreshInd]+threshStep, maxSignalVal, maxSignalVal*2);
            println("ind = "+mouseThreshInd+", New mouseThresh = "+mouseThresh4Ch[mouseThreshInd]);
          }
          outflag = true;
        }
        else if (keyCode == DOWN) {
          if (buttons[b2chctrl].bOn){
            if (mouseThreshInd == thresh2chyHigh && mouseThresh2Ch[thresh2chyLow] > (mouseThresh2Ch[thresh2chyHigh]-mouseThreshStandOff)) {
              // do nothing - can't have low >= high!
            }
            else if (mouseThreshInd == thresh2chxHigh && mouseThresh2Ch[thresh2chxLow] > (mouseThresh2Ch[thresh2chxHigh]-mouseThreshStandOff)) {
              // do nothing - can't have low >= high!
            }
            else {
              mouseThresh2Ch[mouseThreshInd] = constrain(mouseThresh2Ch[mouseThreshInd]-threshStep, maxSignalVal, maxSignalVal*2);
            }
            println("New mouseThresh = "+mouseThresh2Ch[mouseThreshInd]);
          }
          else if (buttons[b4chctrl].bOn){
            mouseThresh4Ch[mouseThreshInd] = constrain(mouseThresh4Ch[mouseThreshInd]-threshStep, maxSignalVal, maxSignalVal*2);
            println("ind = "+mouseThreshInd+", New mouseThresh = "+mouseThresh4Ch[mouseThreshInd]);
          }
          outflag = true;
        }
        
      }
    }

    currentbutton = -1;
    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        if ( (inputDev == mouseInput && buttons[i].IsMouseOver(x, y)) || (inputDev == keyInput && tkey == buttons[i].hotKey) ) {
          outflag = true;
//          buttons[i].bOn = !buttons[i].bOn;
          if (buttons[i].bMomentary){
            buttons[i].changeColorPressed();
            buttonColorTimer = millis()+buttonColorDelay;
            buttonPressedFlag = true;
          }
          currentbutton = i;

          if (currentbutton == badjustthresh){
            mouseTuneFlag = !mouseTuneFlag;
            buttons[i].bOn = !buttons[i].bOn;
            if (!mouseTuneFlag) {
              drawTarget();
              gamenextStep = second()+gamedelayTime;
              println(gamenextStep);
              gameScore = 0;
            }
          }
          if (currentbutton == bclear) {
            blankPlot();
            labelAxes();
            println("Plot Cleared");
          }
          if (currentbutton == bpause) {
            pauseFlag = !pauseFlag;
            buttons[i].bOn = !buttons[i].bOn;
            if (!pauseFlag) {
              buttons[currentbutton].label = "Pause";
              buttons[currentbutton].drawButton();
            }
            else if (pauseFlag) {
              buttons[currentbutton].label = "Play";
              buttons[currentbutton].drawButton();
            }
            println("Pause Toggled");
          }
          if (currentbutton == b2chctrl){
            if (!buttons[currentbutton].bOn){
              buttons[currentbutton].bOn = true;
              buttons[b4chctrl].bOn = false;
              clearRightBar();
              
//              buttons[bchan3up].bHidden = hideButton;
//              buttons[bchan3down].bHidden = hideButton;
//              buttons[bchan4up].bHidden = hideButton;
//              buttons[bchan4down].bHidden = hideButton;
              
//              background(colorBackground);
//              labelGUI();
//              switchToPage();
            }
          }
          if (currentbutton == b4chctrl){
            if (!buttons[currentbutton].bOn){
              buttons[currentbutton].bOn = true;
              buttons[b2chctrl].bOn = false;
              clearRightBar();
              
//              buttons[bchan3up].bHidden = showButton;
//              buttons[bchan3down].bHidden = showButton;
//              buttons[bchan4up].bHidden = showButton;
//              buttons[bchan4down].bHidden = showButton;
              
//              background(colorBackground);
//              labelGUI();
//              switchToPage();
              
              
            }
          }
//          if (currentbutton == bchan1up) {
//            mouseChan[0]++;
//            if (mouseChan[0]>=currentSignalNumber) {
//              mouseChan[0]=currentSignalNumber-1;
//            }
//            if (mouseChan[0] == mouseChan[1]) {
//              mouseChan[0]++;
//              if (mouseChan[0]>=currentSignalNumber) {
//                mouseChan[0]=mouseChan[1]-1;
//              }
//            }
////            buttons[bchan1].ctext = colorSigM[mouseChan[0]];
////            buttons[bchan1].label = str(mouseChan[0]+1);
////            buttons[bchan1].drawButton();
////            channelsOn[mouseChan[0]] = buttons[bchan1].bOn;
//          }
//          if (currentbutton == bchan1down) {
//            mouseChan[0]--;
//            if (mouseChan[0]<0) {
//              mouseChan[0]=0;
//            }
//            if (mouseChan[0] == mouseChan[1]) {
//              mouseChan[0]--;
//              if (mouseChan[0]<0) {
//                mouseChan[0]=mouseChan[1]+1;
//              }
//            }
////            buttons[bchan1].ctext = colorSigM[mouseChan[0]];
////            buttons[bchan1].label = str(mouseChan[0]+1);
////            buttons[bchan1].drawButton();
////            channelsOn[mouseChan[0]] = buttons[bchan1].bOn;
//          }
//          if (currentbutton == bchan2up) {
//            mouseChan[1]++;
//            if (mouseChan[1]>=currentSignalNumber) {
//              mouseChan[1]=currentSignalNumber-1;
//            }
//            if (mouseChan[1] == mouseChan[0]) {
//              mouseChan[1]++;
//              if (mouseChan[1]>=currentSignalNumber) {
//                mouseChan[1]=mouseChan[0]-1;
//              }
//            }
////            buttons[bchan2].ctext = colorSigM[mouseChan[1]];
////            buttons[bchan2].label = str(mouseChan[1]+1);
////            buttons[bchan2].drawButton();
////            channelsOn[mouseChan[1]] = buttons[bchan2].bOn;
//          }
//          if (currentbutton == bchan2down) {
//            mouseChan[1]--;
//            if (mouseChan[1]<0) {
//              mouseChan[1]=0;
//            }
//            if (mouseChan[1] == mouseChan[0]) {
//              mouseChan[1]--;
//              if (mouseChan[1]<0) {
//                mouseChan[1]=mouseChan[0]+1;
//              }
//            }
////            buttons[bchan2].ctext = colorSigM[mouseChan[1]];
////            buttons[bchan2].label = str(mouseChan[1]+1);
////            buttons[bchan2].drawButton();
////            channelsOn[mouseChan[1]] = buttons[bchan2].bOn;
//          }

          labelAxes();
        }
      }
    }
    return outflag;
  }

  public void useSerialEvent() {
  }

  public void drawHelp() {
    drawGenericHelp();
  }

  public void drawTargetPractice() {
    int tmp = 0;
    if (mouseTuneFlag) {
      // println("MousetuneFlag!");
      blankPlot();
      textSize(labelsizes);
      strokeWeight(4);
      textAlign(CENTER, CENTER);
      fill(colorBackground);
      rectMode(CENTER);
      rect(xStep+125, yTitle+plotheight/2, 250-2, plotheight-2);
      fill(0);
      text("Mouse calibration", xStep+125, yTitle+12);
      textSize(labelsizes);
      
      int tmpind = signalindex-datacounter;
      datacounter = 0;
      while (tmpind < 0) {
        tmpind+=maxSignalLength;
      }
      
      if (buttons[b2chctrl].bOn){
        // x-low
        tmp = constrain(PApplet.parseInt(map(mouseThresh2Ch[thresh2chxLow]-maxSignalVal, 0, maxSignalVal, 0, plotheight/2)), 0, plotheight/2);
        stroke(255, 255, 0);
        fill(0);
        line(xStep+250, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
        if (mouseThreshInd == thresh2chxLow) {          fill(255, 255, 0);        }
        text("X Low", xStep+plotwidth*13/16, constrain(ytmp-tmp+10,yTitle+20,ytmp-20));

        // y-low
        tmp = constrain(PApplet.parseInt(map(mouseThresh2Ch[thresh2chyLow]-maxSignalVal, 0, maxSignalVal, plotheight/2, plotheight)), plotheight/2, plotheight);
        line(xStep+250, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
        fill(0);
        if (mouseThreshInd == thresh2chyLow) {          fill(255, 255, 0);        }
        text("Y Low", xStep+plotwidth*11/16, ytmp-tmp+20);
        
        // x-high
        stroke(255, 0, 0);
        tmp = constrain(PApplet.parseInt(map(mouseThresh2Ch[thresh2chxHigh]-maxSignalVal, 0, maxSignalVal, 0, plotheight/2)), 0, plotheight/2);
        line(xStep+250, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
        fill(0);
        if (mouseThreshInd == thresh2chxHigh) {          fill(255, 255, 0);        }
        text("X High", xStep+plotwidth*15/16, constrain(ytmp-tmp+10,yTitle+20,ytmp-20));

        // y-high
        tmp = constrain(PApplet.parseInt(map(mouseThresh2Ch[thresh2chyHigh]-maxSignalVal, 0, maxSignalVal, plotheight/2, plotheight)), plotheight/2, plotheight);
        line(xStep+250, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
        fill(0);
        if (mouseThreshInd == thresh2chyHigh) {          fill(255, 255, 0);        }
        text("Y High", xStep+plotwidth*15/16, ytmp-tmp+20);
  
        // actual signals
        stroke(0, 255, 0);
        fill(0, 255, 0);
        
        tmp = constrain(PApplet.parseInt(map(signalIn[mouseChan[0]][tmpind]+calibration[mouseChan[0]]-maxSignalVal, 0, maxSignalVal, 0, plotheight/2)), 0, plotheight/2);
        line(xStep+250, ytmp - tmp, xStep+plotwidth, ytmp - tmp);
        text("X-axis", xStep+plotwidth*13/16, constrain(ytmp-tmp+10,yTitle+20,ytmp-20));
  
        tmp = constrain(PApplet.parseInt(map(signalIn[mouseChan[1]][tmpind]+calibration[mouseChan[1]]-maxSignalVal, 0, maxSignalVal, plotheight/2, plotheight)), plotheight/2, plotheight);
        line(xStep+250, ytmp - tmp, xStep+plotwidth, ytmp - tmp);
        text("Y-axis", xStep+plotwidth*13/16, constrain(ytmp-tmp+10,yTitle+20,ytmp-20));
  
        String mouse_msg = "";
        mouse_msg += "In > high => move up/right\nIn < low => move down/left\nlow<In<high => hold position\n";
        mouse_msg += "\n";
        mouse_msg += "To Set Thresholds:\n";
        mouse_msg += " Left/Right = select threshold\n";
        // mouse_msg += " (Selected threshold turns yellow)\n";
        mouse_msg += " Up/Down = change threshold\n";
        // mouse_msg += " (Threshold will move\n";
        mouse_msg += "\n";
        mouse_msg += "Adjust green bar below low when completely relaxed, between low and high when slightly flexed, above high when fully flexed.";
        textSize(labelsizexs);
        fill(0);
        textAlign(LEFT, CENTER);
        text(mouse_msg, xStep+125+3, yTitle+plotheight/2, 250-12, plotheight);
        textAlign(CENTER, CENTER);
      } 
      else if (buttons[b4chctrl].bOn){
        // Left
        tmp = constrain(PApplet.parseInt(map(mouseThresh4Ch[thresh4chLeft]-maxSignalVal, 0, maxSignalVal, 0, plotheight/2)), 0, plotheight/2);
        stroke(255, 255, 0);
        fill(0);
        line(xStep+250, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
        if (mouseThreshInd == thresh4chLeft) {          fill(255, 255, 0);        }
        text("Left", xStep+plotwidth*13/16, constrain(ytmp-tmp+10,yTitle+20,ytmp-20));

        // Right
        tmp = constrain(PApplet.parseInt(map(mouseThresh4Ch[thresh4chRight]-maxSignalVal, 0, maxSignalVal, plotheight/2, plotheight)), plotheight/2, plotheight);
        line(xStep+250, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
        fill(0);
        if (mouseThreshInd == thresh4chRight) {          fill(255, 255, 0);        }
        text("Right", xStep+plotwidth*11/16, ytmp-tmp+20);
        
        // Down
        stroke(255, 0, 0);
        tmp = constrain(PApplet.parseInt(map(mouseThresh4Ch[thresh4chDown]-maxSignalVal, 0, maxSignalVal, 0, plotheight/2)), 0, plotheight/2);
        line(xStep+250, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
        fill(0);
        if (mouseThreshInd == thresh4chDown) {          fill(255, 255, 0);        }
        text("Down", xStep+plotwidth*15/16, constrain(ytmp-tmp+10,yTitle+20,ytmp-20));

        // Up
        tmp = constrain(PApplet.parseInt(map(mouseThresh4Ch[thresh4chUp]-maxSignalVal, 0, maxSignalVal, plotheight/2, plotheight)), plotheight/2, plotheight);
        line(xStep+250, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
        fill(0);
        if (mouseThreshInd == thresh4chUp) {          fill(255, 255, 0);        }
        text("Up", xStep+plotwidth*15/16, ytmp-tmp+20);
  
        // actual signals
        stroke(0, 255, 0);
        fill(0, 255, 0);
        
        tmp = constrain(PApplet.parseInt(map(signalIn[mouseChan[0]][tmpind]+calibration[mouseChan[0]]-maxSignalVal, 0, maxSignalVal, 0, plotheight/2)), 0, plotheight/2);
        line(xStep+250, ytmp - tmp, xStep+plotwidth, ytmp - tmp);
        text("Left", xStep+plotwidth*13/16, constrain(ytmp-tmp+10,yTitle+20,ytmp-20));
  
        tmp = constrain(PApplet.parseInt(map(signalIn[mouseChan[1]][tmpind]+calibration[mouseChan[1]]-maxSignalVal, 0, maxSignalVal, plotheight/2, plotheight)), plotheight/2, plotheight);
        line(xStep+250, ytmp - tmp, xStep+plotwidth, ytmp - tmp);
        text("Right", xStep+plotwidth*13/16, constrain(ytmp-tmp+10,yTitle+20,ytmp-20));
        
        tmp = constrain(PApplet.parseInt(map(signalIn[mouseChan[2]][tmpind]+calibration[mouseChan[0]]-maxSignalVal, 0, maxSignalVal, 0, plotheight/2)), 0, plotheight/2);
        line(xStep+250, ytmp - tmp, xStep+plotwidth, ytmp - tmp);
        text("Down", xStep+plotwidth*13/16, constrain(ytmp-tmp+10,yTitle+20,ytmp-20));
  
        tmp = constrain(PApplet.parseInt(map(signalIn[mouseChan[3]][tmpind]+calibration[mouseChan[1]]-maxSignalVal, 0, maxSignalVal, plotheight/2, plotheight)), plotheight/2, plotheight);
        line(xStep+250, ytmp - tmp, xStep+plotwidth, ytmp - tmp);
        text("Up", xStep+plotwidth*13/16, constrain(ytmp-tmp+10,yTitle+20,ytmp-20));
  
        String mouse_msg = "";
        mouse_msg += "In > threshold => move\nIn < threshold => hold position\n";
        mouse_msg += "\n";
        mouse_msg += "To Set Thresholds:\n";
        mouse_msg += " Left/Right = select threshold\n";
        // mouse_msg += " (Selected threshold turns yellow)\n";
        mouse_msg += " Up/Down = change threshold\n";
        // mouse_msg += " (Threshold will move\n";
        mouse_msg += "\n";
        mouse_msg += "Adjust so green bar is below threshold when relaxed, above threshold when flexed.";
        textSize(labelsizexs);
        fill(0);
        textAlign(LEFT, CENTER);
        text(mouse_msg, xStep+125+3, yTitle+plotheight/2, 250-12, plotheight);
        textAlign(CENTER, CENTER);
      }


      if (!pauseFlag) {
        moveMouse(tmpind);
      }
    }
    else if (!mouseTuneFlag) {
      if (!pauseFlag) {//Mousegame
        int tmpind = 0;
        tmpind = signalindex-datacounter;
        datacounter = 0;
        while (tmpind < 0) {
          tmpind+=maxSignalLength;
        }
        moveMouse(tmpind);
        drawcrosshair(xMouse, yMouse);
        if (iswinner()) {
          print("Winner");
          gameScore ++;
          // delayTime -= delayTimeIncrement;
          // if (delayTime < delayTimeMin){delayTime = delayTimeMin;}
          gamenextStep = second()+gamedelayTime;
          println(gamenextStep);
          drawTarget();
        }
        if (second() > gamenextStep) {
          gamedelayTime += gamedelayTimeIncrement;
          if (gamedelayTime > gamedelaymaxPlotTime) {
            gamedelayTime = gamedelaymaxPlotTime;
          }
          drawTarget();
          gamenextStep = second()+gamedelayTime;
          print("Out Of Time!");
          println(gamenextStep);
        }
      }
      else {
        //blankPlot();
        stroke(0);
        fill(255, 69, 0);
        ellipse(xStep+gameTargetX, ytmp-gameTargetY, gametargetsize, gametargetsize);
        drawcrosshair(xMouse, yMouse);
        gamenextStep = second()+gamedelayTime;
      }
    }
  }

  public void moveMouse(int tmpind) {
    int tmp = 0;
    int mouseMoveX = 0, mouseMoveY = 0;
    int mouseOffset = 40;
    if (buttons[b2chctrl].bOn){
      tmp = PApplet.parseInt(signalIn[mouseChan[0]][tmpind]+calibration[mouseChan[0]]);
      //print("tmp = ");print(tmp);print(". Thresh = ");println(mouseThresh[0]);
      if      (tmp < mouseThresh2Ch[0]) {      mouseMoveX = -1*mouseSpeed;}
      else if (tmp < mouseThresh2Ch[1]) {      mouseMoveX = 0;    }
      else                              {      mouseMoveX = 1*mouseSpeed;}
      
      if (!mouseXAxisFlip) {      xMouse += mouseMoveX;    }
      else                 {      xMouse -= mouseMoveX;    }
  
      tmp = PApplet.parseInt(signalIn[mouseChan[1]][tmpind]+calibration[mouseChan[1]]);
      if      (tmp < mouseThresh2Ch[2]) {      mouseMoveY = 1*mouseSpeed;}//(mouseThresh[2] - tmp)*yMouseFactor1;    }
      else if (tmp < mouseThresh2Ch[3]) {      mouseMoveY = 0;}//(mouseThresh[3] - tmp)*yMouseFactor2;    }
      else                              {      mouseMoveY = -1*mouseSpeed;}//(tmp - mouseThresh[3])*yMouseFactor3;    }
      
      if (!mouseYAxisFlip) {      yMouse += mouseMoveY;    }
      else                 {      yMouse -= mouseMoveY;    }
    }
    else if (buttons[b4chctrl].bOn){
      int tmp1 = PApplet.parseInt(signalIn[mouseChan[0]][tmpind]+calibration[mouseChan[0]]);
      int tmp2 = PApplet.parseInt(signalIn[mouseChan[1]][tmpind]+calibration[mouseChan[1]]);
      
      if      (tmp1 > mouseThresh4Ch[0] && tmp2 > mouseThresh4Ch[1]) {
        if       (tmp1 > tmp2)  {mouseMoveX = -1*mouseSpeed;}
        else {mouseMoveX = +1*mouseSpeed;}
      }
      else if (tmp1 > mouseThresh4Ch[0]) { mouseMoveX = -1*mouseSpeed;}
      else if (tmp2 > mouseThresh4Ch[1]) { mouseMoveX = 1*mouseSpeed;}
      else {mouseMoveX = 0;}
      
      if (!mouseXAxisFlip) {      xMouse += mouseMoveX;    }
      else                 {      xMouse -= mouseMoveX;    }
  
      tmp1 = PApplet.parseInt(signalIn[mouseChan[2]][tmpind]+calibration[mouseChan[2]]);
      tmp2 = PApplet.parseInt(signalIn[mouseChan[3]][tmpind]+calibration[mouseChan[3]]);
      if      (tmp1 > mouseThresh4Ch[2] && tmp2 > mouseThresh4Ch[3]) {
        if       (tmp1 > tmp2) {mouseMoveY = -1*mouseSpeed;}
        else                   {mouseMoveY = +1*mouseSpeed;}
      }
      else if (tmp1 > mouseThresh4Ch[2]) { mouseMoveY = 1*mouseSpeed;}
      else if (tmp2 > mouseThresh4Ch[3]) { mouseMoveY = -1*mouseSpeed;}
      else {mouseMoveY = 0;}
      
      if (!mouseYAxisFlip) {      yMouse += mouseMoveY;    }
      else                 {      yMouse -= mouseMoveY;    }
    }

    // println("MouseMoveX = "+MouseMoveX+". MouseMoveY = "+MouseMoveY);
    xMouse = constrain(xMouse, xStep+mouseOffset, xStep+plotwidth-mouseOffset);
    yMouse = constrain(yMouse, yTitle+mouseOffset, yTitle+plotheight-mouseOffset);
    robot.mouseMove(xMouse+xx, yMouse+yy);
  }

  public void drawcrosshair(int hx, int hy) {
    fill(255);
    stroke(255, 0, 0);
    int CHs = 15;
    if (hx < xStep+CHs) {
      hx=xStep+CHs;
    }
    if (hx > xStep+plotwidth-CHs) {
      hx=xStep+plotwidth-CHs;
    }
    if (hy < yTitle+CHs) {
      hy=yTitle+CHs;
    }
    if (hy > yTitle+plotheight-CHs) {
      hy=yTitle+plotheight-CHs;
    }
    rectMode(CENTER);
    rect(hx, hy, 2*CHs, 2*CHs);
  }

  public void drawTarget() {
    blankPlot();
    stroke(0);
    fill(255, 69, 0);
    gameTargetX = PApplet.parseInt(random(0+gametargetsize, plotwidth-gametargetsize));
    gameTargetY = PApplet.parseInt(random(0+gametargetsize, plotheight-gametargetsize));
    // ellipseMode(RADIUS);
    ellipse(xStep+gameTargetX, ytmp-gameTargetY, gametargetsize, gametargetsize);
    drawScore();
  }

  public void drawScore() {
    textSize(32);
    textAlign(CENTER, CENTER);
    stroke(0, 0, 0);
    fill(0, 255, 0);
    text("SCORE = ", 180, 120);
    text(nf(gameScore, 5, 0), 320, 120);
  }

  public boolean iswinner() {
    int rx = ((mouseX-xStep)-gameTargetX);
    rx = rx*rx;
    int ry = ((ytmp-mouseY)-gameTargetY);
    ry = ry*ry;
    float r = sqrt(PApplet.parseFloat(rx+ry));
    if (r < gametargetsize) {
      return true;
    }
    else {
      return false;
    }
  }
}
/************************* END TARGET PRACTICE PAGE ***********************/


//######################Begin SnakeGame Page#######################################
// snake game class/object. constructor looks like:
//SnakeGame mySnakeGame;
//mySnakeGame = new SnakeGame(this,xStep+plotwidth/2,yTitle+plotheight/2,plotwidth,plotheight,foodsize,gamespeed);

// mySnakeGame.drawSnakeGame()
public class SnakeGamePage implements pagesClass {
  PApplet parent;

  GuiButton[] buttons;
  int buttonNumber = 0;
  int
  bclear = buttonNumber++, 
  bpause = buttonNumber++, 
  bchan1 = buttonNumber++, 
  bchan2 = buttonNumber++, 
  bchan1up = buttonNumber++, 
  bchan2up = buttonNumber++, 
  bchan1down = buttonNumber++, 
  bchan2down = buttonNumber++;

  int snakecolor;
  int foodcolor;
  int colorBackground;
  int textcolor;

  int gamex;
  int gamey;
  int gamewidth;
  int gameheight;

  int foodSize;
  int foodX;
  int foodY;
  int gridX;
  int gridY;
  int gridXstart;
  int gridYstart;

  int speed;
  int movewhen;
  int movecounter;
  int movestep;
  int stepX;
  int stepY;

  int snakeSize;
  int maxSnakeSize;
  int snakeX[];
  int snakeY[];

  boolean gameOver;
  boolean freeBoundaries;
  boolean foodflag;
  boolean buttonPressedFlag = false;

  String pageName = "FlexVolt Snake Game";

  SnakeGamePage(PApplet parent) {
    this.parent = parent;

    initializeButtons();

    snakecolor = color(250, 220, 180);
    foodcolor = color(255, 0, 0);
    colorBackground = color(0, 0, 0);
    textcolor = color(240, 240, 240);

    gamex = xStep+fullPlotWidth/2;
    gamey = yTitle+plotheight/2;
    gamewidth = fullPlotWidth;
    gameheight = plotheight;

    foodSize = 30;
    gridX = gamewidth/(foodSize);
    gridY = gameheight/(foodSize);
    gridXstart = gamex - ((gridX-1)*foodSize)/2;
    gridYstart = gamey - ((gridY-1)*foodSize)/2;
    println("x = "+gamex+". y = "+gamey+". w = "+plotwidth+". h = "+plotheight);
    println("gridX = "+gridX+". GridY = "+gridY+". xstart = "+gridXstart+". ystart = "+gridYstart);

    speed = 2; // moves/second
    movewhen = (int)frameRate/speed;
    movecounter = 0;
    movestep = 1;
    stepX = 0;
    stepY = 0;

    snakeSize = 1;
    maxSnakeSize = gridX*gridY;
    snakeX = new int[maxSnakeSize];
    snakeY = new int[maxSnakeSize];
    snakeX[0] = gridX/2;
    snakeY[0] = gridY/2;

    gameOver = false;
    freeBoundaries = true;
    foodflag = true;
  }

  public void initializeButtons() {
    gamex = xStep+fullPlotWidth/2;
    gamey = yTitle+plotheight/2;
    gamewidth = fullPlotWidth;
    gameheight = plotheight;

    foodSize = 30*fullPlotWidth/500;
    gridX = gamewidth/(foodSize);
    gridY = gameheight/(foodSize);
    gridXstart = gamex - ((gridX-1)*foodSize)/2;
    gridYstart = gamey - ((gridY-1)*foodSize)/2;
    
    int buttony = yTitle+195;
    int controlsy = yTitle+30;
    buttons = new GuiButton[buttonNumber];
    buttons[bpause]    = new GuiButton("Pause ", 'p', dummypage, xStep+plotwidth+45, controlsy+10, 60, bheight, color(colorBIdle), color(0), "Pause", bOnOff, false, showButton);
    buttons[bclear]    = new GuiButton("Clear ", 'c', dummypage, xStep+plotwidth+45, controlsy+40, 60, bheight, color(colorBIdle), color(0), "Clear", bMomentary, false, showButton);
    buttons[bchan1up]  = new GuiButton("MCh1up", ' ', dummypage, xStep+plotwidth+80, yTitle+200, 20, 20, color(colorBIdle), color(0), ">", bMomentary, false, showButton);
    buttons[bchan1down]= new GuiButton("MCh1dn", ' ', dummypage, xStep+plotwidth+16, yTitle+200, 20, 20, color(colorBIdle), color(0), "<", bMomentary, false, showButton);
    buttons[bchan1]    = new GuiButton("MChan1", ' ', dummypage, xStep+plotwidth+50, yTitle+200, 30, bheight, color(colorBIdle), colorSigM[mouseChan[0]], ""+(mouseChan[0]+1), bOnOff, true, showButton);
    buttons[bchan2up]  = new GuiButton("MCh2up", ' ', dummypage, xStep+plotwidth+80, yTitle+260, 20, 20, color(colorBIdle), color(0), ">", bMomentary, false, showButton);
    buttons[bchan2down]= new GuiButton("MCh2dn", ' ', dummypage, xStep+plotwidth+16, yTitle+260, 20, 20, color(colorBIdle), color(0), "<", bMomentary, false, showButton);
    buttons[bchan2]    = new GuiButton("MChan2", ' ', dummypage, xStep+plotwidth+50, yTitle+260, 30, bheight, color(colorBIdle), colorSigM[mouseChan[1]], ""+(mouseChan[1]+1), bOnOff, true, showButton);
  }

  public void switchToPage() {

    pauseFlag = true;

    buttons[bpause].bOn = pauseFlag;

    plotwidth = fullPlotWidth;
    labelAxes();
    clearGameScreen();
    println("SnakeDomain");
  }

  public void drawPage() {
    if (buttonPressedFlag) {
      if (millis() > buttonColorTimer) {
        buttonPressedFlag = false;
        println("Current Button = " + currentbutton);
        if (buttons[currentbutton] != null && currentbutton < buttons.length) {
          buttons[currentbutton].changeColorUnpressed();
        }
      }
    }

    movecounter++;
    if (movecounter > movewhen) {
      movecounter = 0;
      clearGameScreen();
      runSnakeGame();
    }
  }

  public String getPageName() {
    return pageName;
  }

  public void useSerialEvent() {
  }

  public boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
    boolean outflag = false;

    if (keyCode == UP) {
      if (stepY != -movestep) {
        stepY = -movestep; 
        stepX = 0;
      }
      outflag = true;
    }
    if (keyCode == DOWN) {
      if (stepY != movestep) {
        stepY = movestep; 
        stepX = 0;
      }
      outflag = true;
    }
    if (keyCode == LEFT) {
      if (stepX != -movestep) {
        stepX = -movestep; 
        stepY = 0;
      }
      outflag = true;
    }
    if (keyCode == RIGHT) {
      if (stepX != movestep) {
        stepX = movestep; 
        stepY = 0;
      }
      outflag = true;
    }
    if (key == 'N' || key == 'n') {
      resetSnakeGame();
      outflag = true;
    }
    // if(keyCode == '+'){
    // increasedifficulty();
    // }
    // if(keyCode == '-'){
    // decreasedifficulty();
    // }

    currentbutton = -1;
    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        if ( (inputDev == mouseInput && buttons[i].IsMouseOver(x, y)) || (inputDev == keyInput && tkey == buttons[i].hotKey) ) {
          outflag = true;
          buttons[i].bOn = !buttons[i].bOn;
          buttons[i].changeColorPressed();
          buttonColorTimer = millis()+buttonColorDelay;
          buttonPressedFlag = true;
          currentbutton = i;

          if (currentbutton == bclear) {
            blankPlot();
            labelAxes();
            println("Plot Cleared");
          }
          if (currentbutton == bpause) {
            pauseFlag = !pauseFlag;
            if (!pauseFlag) {
              buttons[currentbutton].label = "Pause";
              buttons[currentbutton].drawButton();
            }
            else if (pauseFlag) {
              buttons[currentbutton].label = "Play";
              buttons[currentbutton].drawButton();
            }
            println("Pause Toggled");
          }

          labelAxes();
        }
      }
    }
    return outflag;
  }

  public void labelAxes() {
  }

  public void drawHelp() {
    drawGenericHelp();
  }

  public void clearGameScreen() {
    fill(colorBackground);
    stroke(colorBackground);
    rectMode(CENTER);
    rect(gamex, gamey, gamewidth, gameheight);
  }

  public void resetSnakeGame() {
    gameOver = false;
    foodflag = true;
    freeBoundaries = false;
    snakeSize = 1;
    stepX = 0;
    stepY = 0;
    snakeX = new int[maxSnakeSize];
    snakeY = new int[maxSnakeSize];
    snakeX[0] = gridX/2;
    snakeY[0] = gridY/2;
  }

  public void runSnakeGame() {
    if (!gameOver) {
      drawFood();
      drawSnake();
      moveSnake();
      checkAteFood();
      checkSelfImpact();
    } 
    else if (gameOver) {
      textAlign(CENTER, CENTER);
      textSize(20);
      fill(textcolor);
      text("Game Over!\n'n' for new game", gamex, gamey);
    }
  }

  public void checkSelfImpact() {
    for (int i = 1; i < snakeSize; i++) {
      if (snakeX[0] == snakeX[i] && snakeY[0] == snakeY[i]) {
        gameOver = true;
      }
    }
  }

  public void checkAteFood() {
    if (foodX == snakeX[0] && foodY == snakeY[0]) {
      foodflag = true;
      snakeSize ++;
    }
  }

  public void drawFood() {
    fill(foodcolor);
    while (foodflag) {
      foodX = (int)random(1, gridX);
      foodY = (int)random(1, gridY);

      for (int i = 0; i < snakeSize; i ++) {
        if (foodX == snakeX[i] && foodY == snakeY[i]) {
          foodflag = true;
          break;
        } 
        else {
          foodflag = false;
        }
      }
    }
    int fX = (foodX-1)*foodSize+gridXstart;
    int fY = (foodY-1)*foodSize+gridYstart;
    rect(fX, fY, foodSize, foodSize);
  }

  public void drawSnake() {
    fill(snakecolor);
    int sX;
    int sY;
    // draw blocks
    for (int i = 0; i < snakeSize; i++) {
      sX = (snakeX[i]-1)*foodSize+gridXstart;
      sY = (snakeY[i]-1)*foodSize+gridYstart;
      rect(sX, sY, foodSize, foodSize);
    }
    // shift blocks
    for (int i = snakeSize; i > 0; i--) {
      snakeX[i] = snakeX[i-1];
      snakeY[i] = snakeY[i-1];
    }
  }

  public void moveSnake() {
    int sX = snakeX[1] + stepX;
    int sY = snakeY[1] + stepY;
    if (freeBoundaries) {
      if (sX > gridX) {
        sX = 1;
      }
      if (sX < 1) {
        sX = gridX;
      }
      if (sY > gridY) {
        sY=1;
      }
      if (sY < 1) {
        sY = gridY;
      }
    } 
    else {
      if (sX > gridX || sX < 1 || sY > gridY || sY < 1) {
        println("out of bounds!");
        gameOver = true;
      }
    }
    snakeX[0] = sX;
    snakeY[0] = sY;
  }
}

//#######################End WormGame Object#########################################

//######################Begin MuscleMusic Page#######################################

public class MuscleMusicPage implements pagesClass {
  String pageName = "Muscle Music";

  GuiButton[] buttons;
  int buttonNumber = 0;
  int
    bclear = buttonNumber++, 
  bpause = buttonNumber++;

  MuscleMusicPage() {
    initializeButtons();
  }

  public void initializeButtons() {
    int buttony = yTitle+195;
    int controlsy = yTitle+30;
    buttons = new GuiButton[buttonNumber];
    buttons[bpause]    = new GuiButton("Pause ", 'p', dummypage, xStep+plotwidth+45, controlsy+10, 60, bheight, color(colorBIdle), color(0), "Pause", bOnOff, false, showButton);
    buttons[bclear]    = new GuiButton("Clear ", 'c', dummypage, xStep+plotwidth+45, controlsy+40, 60, bheight, color(colorBIdle), color(0), "Clear", bMomentary, false, showButton);
  }

  public void switchToPage() {
  }

  public void drawPage() {
  }

  public String getPageName() {
    return pageName;
  }

  public void useSerialEvent() {
  }

  public void useMousePressed() {
  }

  public boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
    boolean outflag = false;

    if (keyCode == UP) {
      outflag = true;
    }
    if (keyCode == DOWN) {
      outflag = true;
    }
    if (keyCode == LEFT) {
      outflag = true;
    }
    if (keyCode == RIGHT) {
      outflag = true;
    }
    if (key == 'N' || key == 'n') {
      outflag = true;
    }

    currentbutton = -1;
    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        if ( (inputDev == mouseInput && buttons[i].IsMouseOver(x, y)) || (inputDev == keyInput && tkey == buttons[i].hotKey) ) {
          outflag = true;
          buttons[i].bOn = !buttons[i].bOn;
          buttons[i].changeColorPressed();
          buttonColorTimer = millis()+buttonColorDelay;
          buttonPressedFlag = true;
          currentbutton = i;

          if (currentbutton == bclear) {
            blankPlot();
            labelAxes();
            println("Plot Cleared");
          }
          if (currentbutton == bpause) {
            pauseFlag = !pauseFlag;
            if (!pauseFlag) {
              buttons[currentbutton].label = "Pause";
              buttons[currentbutton].drawButton();
            }
            else if (pauseFlag) {
              buttons[currentbutton].label = "Play";
              buttons[currentbutton].drawButton();
            }
            println("Pause Toggled");
          }

          labelAxes();
        }
      }
    }
    return outflag;
  }

  public void labelAxes() {
  }

  public boolean useKeyPressed() {
    boolean outflag = false;
    println("key = "+key+", keyCode = "+keyCode);
    if (keyCode == UP) {
      outflag = true;
    }
    if (keyCode == DOWN) {
      outflag = true;
    }
    if (keyCode == LEFT) {
      outflag = true;
    }
    if (keyCode == RIGHT) {
      outflag = true;
    }
    if (key == 'N' || key == 'n') {
      outflag = true;
    }
    return outflag;
  }

  public void drawHelp() {
    drawGenericHelp();
  }
}

//#######################End MuscleMusic Object#########################################


//######################Begin SerialPort Object#######################################
// Class SerialPortObj
/* object to hold all Serial related functions inclduing:
 * PollSerialDevices() - build list of available ports that could be flexvolt
 * TrySerialConnect() - try/catch of opening a serial port
 */

//General Use:
// Constructor:
// SerialPortObj FVserial;
// FVserial = new SerialPortObj(this);
//
//to start connecting
//in Draw()
// Run FVserial.connectserial();
// the function will poll devices, set connecting flag, and set current try port index to 0
//
//in Draw(),
// if(FVserial.connectingflag){
// FVserial.TryPort(); - handles all connecting attempts. monitors timeout for each attempt, increments port to try, etc.
// }
//
// in serialEvent()
// if (inChar == 'x'){
// FVserial.flexvoltconnected = true; - this flag tells the SerialPortObj that a flexvolt port has been found. Searching stops, and that port is now connnected
// }

// in resetserial()
// call FVserial.connectserial(); // runs FVserial.reset(); then PollSerialDevices(), then FVserial.connectingflag = true;

public class SerialPortObj {
  PApplet parent;
  String usbPORTs[];
  String bluetoothPORTs[];
  boolean foundPorts;
  boolean connectingflag;
  boolean portopenflag;
  boolean flexvoltconnected;
  boolean flexvoltfound;
  boolean testingUSBcom;
  boolean connectinglongertime;
  boolean serialReceivedFlag;
  long timer;
  int portindex;
  int usbPortsN;
  int bluetoothPortsN;
  int shortwaittimeUSB;
  int longwaittimeUSB;
  int shortwaittimeBT;
  int longwaittimeBT;
  int connectionindicator;
  int indicator_noconnection;
  int indicator_connecting;
  int indicator_connected;
  int connectionAtimer = 0;
  int connectionAdelay = 500;
  long checkSerialTimer = 0;


  public SerialPortObj(PApplet parent_) {
    this.parent = parent_;
    usbPORTs = new String[0];
    bluetoothPORTs = new String[0];
    foundPorts = false;
    connectingflag = false;
    portopenflag = false;
    flexvoltconnected = false;
    flexvoltfound = false;
    testingUSBcom = true;
    serialReceivedFlag = false;
    timer = 0;
    portindex = 0;
    usbPortsN = 0;
    bluetoothPortsN = 0;
    shortwaittimeUSB = 500;
    longwaittimeUSB = 2000;
    shortwaittimeBT = 500;
    longwaittimeBT = 2000;
    connectionindicator = 0;
    indicator_noconnection = 0;
    indicator_connecting = 1;
    indicator_connected = 2;
  }

  public boolean manageConnection(boolean data_flag) {
    if (connectingflag) {
      TryPort(); // handles all connecting attempts. monitors timeout for each attempt, increments port to try, etc.
    }

    if (!flexvoltconnected) {
      if (millis()>connectionAtimer) {
        connectionAtimer = millis()+connectionAdelay;
        if (!flexvoltfound) {
          if (myPort != null) {
            println("Wrote 'X' to myport = "+myPort);
            try {  
              myPort.write('X');
              myPort.write('X');
            }
            catch (RuntimeException e) {
              println("couldn't connect to that one");
              portopenflag = false;
              if (e.getMessage().contains("Port not opened")) {
                println("Error = "+e.getMessage());
              }
            }
          } 
          else {
            println("No Ports to Write X To!");
          }
        } 
        else if (flexvoltfound) {
          if (myPort != null) {
            println("Wrote 'A' to myport = "+myPort);
            myPort.write('A');
          } 
          else {
            println("No Ports to Write To!");
          }
        }
      }
    }

    if (data_flag) {
      if (checkSerialTimer == 0) {
        checkSerialTimer = millis()+checkSerialDelay;
        println("addon");
      }
      if (millis()>checkSerialTimer) {
        checkSerialTimer = millis()+checkSerialDelay;
        if (!serialReceivedFlag) {
          println(checkSerialTimer);
          flexvoltconnected = false;
          communicationsflag = false;
          data_flag = false;
          println("Serial Timeout");
          connectionindicator = FVserial.indicator_noconnection;
          drawConnectionIndicator();
          display_error("FlexVolt Connection Lost");
        }
        serialReceivedFlag = false;
      }
    }
    
    drawConnectionIndicator();
    
    return data_flag;
  }

  public void connectserial() {
    reset();
    FVserial.PollSerialDevices();  //!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
    if (foundPorts) {
      connectionindicator = indicator_connecting;
      connectingflag = true;
      connectionAtimer = millis()+connectionAdelay;
    }
  }

  public void drawConnectionIndicator() {
    fill(150);
    strokeWeight(2);
    stroke(0);
    ellipse(xStep+fullPlotWidth+10, yTitle/2, 24, 24);
    if (connectionindicator == indicator_connected) {
      fill(color(0, 255, 0));
    }
    else if (connectionindicator == indicator_connecting) {
      fill(color(255, 200, 0));
    }
    else if (connectionindicator == indicator_noconnection) {
      fill(color(255, 0, 0));
    }
    stroke(0);
    ellipse(xStep+fullPlotWidth+10, yTitle/2, 14, 14);
  }

  public void TryPort() {
    if (!foundPorts) {
      PollSerialDevices();
      testingUSBcom = true;
      portindex = 0;
    }
    if (foundPorts) {
      if (millis() > timer) {
        if (flexvoltfound) {
          connectingflag = false;
          return;
        } 
        else if (!flexvoltfound) {
          if (testingUSBcom) { // try USB connections first. On MAC these are different than the BT ports. WINDOWS - doesn't differentiate com ports....
            if (portindex >= usbPortsN) {
              portindex = 0;
              if (connectinglongertime) {
                testingUSBcom = false;
                connectinglongertime = false;
                println("found no USB at long times");
              } 
              else if (!connectinglongertime) {
                // testingUSBcom = false;
                connectinglongertime = true;
                println("found no USB at short times");
              }
            } 
            else {
              if (connectinglongertime) {
                TrySerialConnect(usbPORTs[portindex], longwaittimeUSB);
              } 
              else if (!connectinglongertime) {
                TrySerialConnect(usbPORTs[portindex], shortwaittimeUSB);
              }
              portindex++;
            }
          }
          else {
            if (portindex >= bluetoothPortsN) {
              portindex = 0;
              if (connectinglongertime) {
                connectingflag = false;
                println("found no BT at long times");
                println("found no FlexVolts!");
              } 
              else if (!connectinglongertime) {
                connectinglongertime = true;
                // testingUSBcom = true;
                println("found no BT at short times");
              }
            } 
            else {
              if (connectinglongertime) {
                TrySerialConnect(bluetoothPORTs[portindex], longwaittimeBT);
              } 
              else if (!connectinglongertime) {
                TrySerialConnect(bluetoothPORTs[portindex], shortwaittimeBT);
              }
              portindex++;
            }
          }
        }
      }
    }
  }

  public void reset() {
    usbPORTs = new String[0];
    bluetoothPORTs = new String[0];
    foundPorts = false;
    connectingflag = false;
    portopenflag = false;
    flexvoltconnected = false;
    flexvoltfound = false;
    testingUSBcom = true;
    timer = 0;
    portindex = 0;
    usbPortsN = 0;
    bluetoothPortsN = 0;
    connectionindicator = indicator_noconnection;
  }

  public void TrySerialConnect(String portname, int waittime) {
    try {
      if (myPort != null) {
        myPort.clear();
        myPort.stop();
      }
      myPort = new Serial(parent, portname, serialPortSpeed);//38400
      myPort.clear();
      portopenflag = true;
      println("WroteX");
      myPort.write('X');
      timer = millis() + waittime;
      println(timer);
    } 
    catch (RuntimeException e) {
      println("couldn't connect to that one");
      portopenflag = false;
      if (e.getMessage().contains("Port busy")) {
        println("Error = "+e.getMessage());
      }
    }
  }

  public void PollSerialDevices() {
    // find serial port
    String[] m1;
    usbPORTs = new String[0];
    bluetoothPORTs = new String[0];

    println(Serial.list());

    String USBname = "";
    String Bluetoothname = "";
    if (platform == MACOSX) {
      println("Found a MAC!");
      USBname = "tty.usbmodem";
      Bluetoothname = "tty.FlexVolt";
    }
    else if (platform == WINDOWS) {
      println("Found a PC!");
      USBname = "COM";
      Bluetoothname = "tty.FlexVolt";
    }
    else if (platform == LINUX) {
      println("Found a Penguin!");
      display_error("Found a Penguin!\n FlexVoltViewer v1.0 has not been tested with the Linux OS!");
      USBname = "tty"; // typically will be dev/ttyS, ttyACMO, ttyUSB, etc.
      Bluetoothname = "tty.FlexVolt";
    }
    else if (platform == OTHER) {
      println("Found an Unknown Operating System!");
      display_error("Found an Unknown Operating System!\n FlexVoltViewer does not yet know how to connect with your OS!");
      USBname = "COM";
      Bluetoothname = "tty.FlexVolt";
      display_error("Found an Unknown Operating System!");
    }
    for (int i = 0; i<Serial.list().length; i++) {
      m1 = match(Serial.list()[i], USBname);
      if (m1 != null) {
        usbPORTs = append(usbPORTs, Serial.list()[i]);
        println("USB Device Found is " + Serial.list()[i]);
      }
    }
    for (int i = 0; i<Serial.list().length; i++) {
      m1 = match(Serial.list()[i], Bluetoothname);
      if (m1 != null) {
        bluetoothPORTs = append(bluetoothPORTs, Serial.list()[i]);
        println("Bluetooth Device Found is " + Serial.list()[i]);
      }
    }

    usbPortsN = usbPORTs.length;
    if (usbPortsN == 0) {
      println("USB ports = null");
    } 
    else {
      println("USB ports = ");
      println(usbPORTs);
      foundPorts = true;
    }
    bluetoothPortsN = bluetoothPORTs.length;
    if (bluetoothPortsN == 0) {
      println("BT ports = null");
    } 
    else {
      println("BT ports = ");
      println(bluetoothPORTs);
      foundPorts = true;
    }
  }
}
//######################End SerialPort Object#########################################


//####################################################################################
// Gui Class





//####################################################################################


//####################################################################################
// Button Classes

class GuiButton {
  String name;
  int xpos;
  int ypos;
  int xsize;
  int ysize;
  int cbox;
  int ctext;
  String label;
  char hotKey;
  int pageRef;
  boolean mouseOver;
  boolean bOn;
  boolean bMomentary;
  boolean bHidden;

  GuiButton(String name_, char hotKey_, int pageRef_, int xpos_, int ypos_, int xsize_, int ysize_, int cbox_, int ctext_, String label_, boolean bMomentary_, boolean bOn_, boolean bHidden_) {
    name  = name_;
    hotKey = hotKey_;
    pageRef = pageRef_;
    xpos  = xpos_;
    ypos  = ypos_;
    xsize = xsize_;
    ysize = ysize_;
    cbox  = cbox_;
    ctext = ctext_;
    label = label_;
    bMomentary = bMomentary_;
    bOn = bOn_;
    bHidden = bHidden_;
  }

  public boolean IsMouseOver(int x, int y) {
    if (bHidden){return false;}
    if (x >= xpos - xsize/2 && x <= xpos+xsize/2 &&
      y >= ypos - ysize/2 && y <= ypos+ysize/2) {
      return true;
    }
    else {
      return false;
    }
  }

  public void drawButton() {
    if (bHidden) return;
    int ctext_tmp = color(0);
    int rectradius = 0;
    if (!bMomentary) {
      if (bOn) {
        // println("on/off, changing color to On");
        cbox = colorbOn;
        ctext_tmp = ctext;
      }
      else if (!bOn) {
        // println("on/off, changing color to Off");
        cbox = colorBIdle;
        ctext_tmp = 0;
      }
    }
    fill(cbox);
    stroke(colorBOutline);
    strokeWeight(2);
    rectMode(CENTER);
    // rect(xpos, ypos, xsize, ysize, rectradius);
    rect(xpos, ypos, xsize, ysize, rectradius);
    int cstep = 40;
    ctext_tmp = color(max(0, red(ctext_tmp)-cstep), max(0, green(ctext_tmp)-cstep), max(0, blue(ctext_tmp)-cstep));
    fill(ctext_tmp);
    textAlign(CENTER, CENTER);
    textSize(buttontextsize);
    String[] m1 = match(label, ",");
    if (m1 == null) {
      text(label, xpos, ypos-2);
    }
    else {
      String[] list = split(label, ',' );
      text(list[0], xpos, ypos-10-2);
      text(list[1], xpos, ypos+10-2);
    }
  }

  public void changeColorUnpressed() {
    cbox = colorBIdle;
    drawButton();
  }

  public void changeColorPressed() {
    cbox = colorBPressed;
    drawButton();
  }
}

//####################################################################################


//####################################################################################
// FFT Classes:
class FFTutils {
  int WINDOW_SIZE, WS2;
  int BIT_LEN;
  int[] _bitrevtable;
  float _normF;
  float[] _equalize;
  float[] _envelope;
  float[] _fft_result;
  float[][] _fftBuffer;
  float[] _cosLUT, _sinLUT;
  float[] _FIRCoeffs;
  boolean _isEqualized, _hasEnvelope;

  public FFTutils(int windowSize) {
    WINDOW_SIZE=WS2=windowSize;
    WS2>>=1;
    BIT_LEN = (int)(Math.log((double)WINDOW_SIZE)/0.693147180559945f+0.5f);
    _normF=2f/WINDOW_SIZE;
    _hasEnvelope=false;
    _isEqualized=false;
    initFFTtables();
  }

  public void initFFTtables() {
    _cosLUT=new float[BIT_LEN];
    _sinLUT=new float[BIT_LEN];
    println(WINDOW_SIZE);
    _fftBuffer=new float[WINDOW_SIZE][2];
    _fft_result=new float[WS2];

    // only need to compute sin/cos at BIT_LEN angles
    float phi=PI;
    for (int i=0; i<BIT_LEN; i++) {
      _cosLUT[i]=cos(phi);
      _sinLUT[i]=sin(phi);
      phi*=0.5f;
    }

    // precalc bit reversal lookup table ala nullsoft
    int i, j, bitm, temp;
    _bitrevtable = new int[WINDOW_SIZE];

    for (i=0; i<WINDOW_SIZE; i++) _bitrevtable[i] = i;
    for (i=0,j=0; i < WINDOW_SIZE; i++) {
      if (j > i) {
        temp = _bitrevtable[i];
        _bitrevtable[i] = _bitrevtable[j];
        _bitrevtable[j] = temp;
      }
      bitm = WS2;
      while (bitm >= 1 && j >= bitm) {
        j -= bitm;
        bitm >>= 1;
      }
      j += bitm;
    }
  }

  // taken from nullsoft VMS
  // reduces impact of bassy freqs and slightly amplifies top range
  public void useEqualizer(boolean on) {
    _isEqualized=on;
    if (on) {
      int i;
      float scaling = -0.02f;
      float inv_half_nfreq = 1.0f/WS2;
      _equalize = new float[WS2];
      for (i=0; i<WS2; i++) _equalize[i] = scaling * (float)Math.log( (double)(WS2-i)*inv_half_nfreq );
    }
  }

  // bell filter envelope to reduce artefacts caused by the edges of standard filter rect
  // 0.0 < power < 2.0
  public void useEnvelope(boolean on, float power) {
    _hasEnvelope=on;
    if (on) {
      int i;
      float mult = 1.0f/(float)WINDOW_SIZE * TWO_PI;
      _envelope = new float[WINDOW_SIZE];
      if (power==1.0f) {
        for (i=0; i<WINDOW_SIZE; i++) _envelope[i] = 0.5f + 0.5f*sin(i*mult - HALF_PI);
      }
      else {
        for (i=0; i<WINDOW_SIZE; i++) _envelope[i] = pow(0.5f + 0.5f*sin(i*mult - HALF_PI), power);
      }
    }
  }

  // compute actual FFT with current settings (eq/filter etc.)
  public float[] computeFFT(float[] waveInData) {
    float u_r, u_i, w_r, w_i, t_r, t_i;
    int l, le, le2, j, jj, ip, ip1, i, ii, phi;

    // check if we need to apply window function or not
    if (_hasEnvelope) {
      for (i=0; i<WINDOW_SIZE; i++) {
        int idx = _bitrevtable[i];
        if (idx < WINDOW_SIZE) _fftBuffer[i][0] = waveInData[idx]*_envelope[idx];
        else _fftBuffer[i][0] = 0;
        _fftBuffer[i][1] = 0;
      }
    }
    else {
      for (i=0; i<WINDOW_SIZE; i++) {
        int idx = _bitrevtable[i];
        if (idx < WINDOW_SIZE) _fftBuffer[i][0] = waveInData[idx];
        else _fftBuffer[i][0] = 0;
        _fftBuffer[i][1] = 0;
      }
    }

    for (l = 1,le=2, phi=0; l <= BIT_LEN; l++) {
      le2 = le >> 1;
      w_r = _cosLUT[phi];
      w_i = _sinLUT[phi++];
      u_r = 1f;
      u_i = 0f;
      for (j = 1; j <= le2; j++) {
        for (i = j; i <= WINDOW_SIZE; i += le) {
          ip = i + le2;
          ip1 = ip-1;
          ii = i-1;
          float[] currFFT=_fftBuffer[ip1];
          t_r = currFFT[0] * u_r - u_i * currFFT[1];
          t_i = currFFT[1] * u_r + u_i * currFFT[0];
          currFFT[0] = _fftBuffer[ii][0] - t_r;
          currFFT[1] = _fftBuffer[ii][1] - t_i;
          _fftBuffer[ii][0] += t_r;
          _fftBuffer[ii][1] += t_i;
        }
        t_r = u_r * w_r - w_i * u_i;
        u_i = w_r * u_i + w_i * u_r;
        u_r = t_r;
      }
      le<<=1;
    }
    // normalize bands or apply EQ
    float[] currBin;
    if (_isEqualized) {
      for (i=0; i<WS2; i++) {
        currBin=_fftBuffer[i];
        _fft_result[i]=_equalize[i]*sqrt(currBin[0]*currBin[0]+currBin[1]*currBin[1]);
      }
    }
    else {
      for (i=0; i<WS2; i++) {
        currBin=_fftBuffer[i];
        _fft_result[i]=_normF*sqrt(currBin[0]*currBin[0]+currBin[1]*currBin[1]);
      }
    }
    return _fft_result;
  }
}

// FIR filter based on http://www.dsptutor.freeuk.com/KaiserFilterDesign/KaiserFilterDesign.html

class FIRFilter {
  float[] a, x;
  float kaiserV, f1, f2, fN, atten, trband;
  int order, filterType, freqPoints;

  static final int LOW_PASS = 1;
  static final int HIGH_PASS = 2;
  static final int BAND_PASS = 3;

  public FIRFilter(int type, float fr, float fq1, float fq2, float att, float bw) {
    filterType=type;
    fN=fr*0.5f;
    f1=fq1;
    f2=fq2;
    atten=att;
    trband=bw;
    initialize();
  }

  public float I0 (float x) {
    // zero order Bessel function of the first kind
    float eps = 1.0e-6f; // accuracy parameter
    float fact = 1.0f;
    float x2 = 0.5f * x;
    float p = x2;
    float t = p * p;
    float s = 1.0f + t;
    for (int k = 2; t > eps; k++) {
      p *= x2;
      fact *= k;
      t = sq(p / fact);
      s += t;
    }
    return s;
  }

  public int computeOrder() {
    // estimate filter order
    order = 2 * (int) ((atten - 7.95f) / (14.36f*trband/fN) + 1.0f);
    // estimate Kaiser window parameter
    if (atten >= 50.0f) kaiserV = 0.1102f*(atten - 8.7f);
    else
      if (atten > 21.0f)
        kaiserV = 0.5842f*(float)Math.exp(0.4f*(float)Math.log(atten - 21.0f))+ 0.07886f*(atten - 21.0f);
    if (atten <= 21.0f) kaiserV = 0.0f;
    println("filter oder: "+order);
    return order;
  }

  public void initialize() {
    computeOrder();
    // window function values
    float I0alpha = 1f/I0(kaiserV);
    int m = order>>1;
    float[] win = new float[m+1];
    for (int n=1; n <= m; n++)
      win[n] = I0(kaiserV*sqrt(1.0f - sq((float)n/m))) * I0alpha;

    float w0 = 0.0f;
    float w1 = 0.0f;
    switch (filterType) {
    case LOW_PASS:
      w0 = 0.0f;
      w1 = PI*(f2 + 0.5f*trband)/fN;
      break;
    case HIGH_PASS:
      w0 = PI;
      w1 = PI*(1.0f - (f1 - 0.5f*trband)/fN);
      break;
    case BAND_PASS:
      w0 = HALF_PI * (f1 + f2) / fN;
      w1 = HALF_PI * (f2 - f1 + trband) / fN;
      break;
    }

    // filter coefficients (NB not normalised to unit maximum gain)
    a = new float[order+1];
    a[0] = w1 / PI;
    for (int n=1; n <= m; n++)
      a[n] = sin(n*w1)*cos(n*w0)*win[n]/(n*PI);
    // shift impulse response to make filter causal:
    for (int n=m+1; n<=order; n++) a[n] = a[n - m];
    for (int n=0; n<=m-1; n++) a[n] = a[order - n];
    a[m] = w1 / PI;
  }

  public float[] apply(float[] ip) {
    float[] op = new float[ip.length];
    x=new float[order];
    float sum;
    for (int i=0; i<ip.length; i++) {
      x[0] = ip[i];
      sum = 0.0f;
      for (int k=0; k<order; k++) sum += a[k]*x[k];
      op[i] = sum;
      for (int k=order-1; k>0; k--) x[k] = x[k-1];
    }
    return op;
  }
}

// FFT Classes End
//####################################################################################


//####################################################################################

  static public void main(String[] passedArgs) {
    String[] appletArgs = new String[] { "FlexVoltViewer" };
    if (passedArgs != null) {
      PApplet.main(concat(appletArgs, passedArgs));
    } else {
      PApplet.main(appletArgs);
    }
  }
}
