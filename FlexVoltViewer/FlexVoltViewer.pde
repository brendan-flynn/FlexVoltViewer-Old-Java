//  Author:  Brendan Flynn - FlexVolt
//  Date Modified:    31 July 2014
/*  FlexVolt Viewer v1.2
 
 Recent Changes:
 page objects
   huge change, now each page/sub-app is it's own object
   this makes it easier to add pages/mini apps
 
 app resize - app can now be resized!
 
 
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
import processing.serial.*;
import java.awt.AWTException;
import java.awt.Robot;

// interface to wrap all page objects
public interface pagesClass {
  public void switchToPage(); // anything that should be done during switch to this page
  public void drawPage(); // 
  public boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev);
  //  public boolean useKeyPressed(); // don't need to pass key, keyCode
  public void useSerialEvent(); // may not need this one
  //  public void useMousePressed(); // don't need to pass mouseButton, etc.
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
//  no longer used
//  boolean useKeyPressed(){
//    boolean outflag = false;
//    if (key == 'a' ) {
//      //do stuff
//      outflag = true;
//    }
//    if (key == CODED){
//      if (keyCode == LEFT){
//        // do stuff
//        outflag = true;
//      }
//    }
//    return outflag;
//  }
//  
//  no longer used
//  void useMousePressed(){
//    for (int i = 0; i < buttons.length; i++) {
//        if (buttons[i] != null) {
//          if (buttons[i].IsMouseOver(x, y)) {
//            buttons[i].BOn = !buttons[i].BOn;
//            buttons[i].ChangeColorPressed();
//            currentbutton = i;
//            ButtonColorTimer = millis()+ButtonColorDelay;
//            ButtonPressedFlag = true;
//          }
//        }
//      }
//      if (currentbutton == Bsettings) {
//        ChangeDomain(SettingsDomain);
//        println("Settings Menu");
//      }
//      else if (currentbutton == Bhelp) {
//        ChangeDomain(HelpDomain);
//      }
//  }
//  
//  void useSerialEvent(){
//    if (dataflag) {
//    byte[] inBuffer = new byte[SerialBufferN];
//    while (myPort.available () > SerialBufferN) {
//      int inChar = myPort.readChar(); // get ASCII
//      if (inChar != -1) {
//        SerialReceivedFlag = true;
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
///************************* END EXALE PAGE ***********************/


// Constants
String ViewerVersion = "v1.1";
String HomePath = System.getProperty("user.home"); // default path to save settings files
String folder = "";
Serial myPort;
//String RENDERMODE = "P2D";
int FullPlotWidth = 500;
int plotwidth = FullPlotWidth;
int HalfPlotWidth = FullPlotWidth/2;
int plotheight = 400;
int plot2offset = 5;
int xx, yy;
int xStep = 60;
int yStep = 40;
int yTitle = 70;
int barwidth = 100;

int SerialBufferN = 5;
int SerialBurstN = 2;
int SerialPortSpeed = 230400;
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
int ButtonNumCommon = 0;
int
BCsettings = ButtonNumCommon++, 
BChelp = ButtonNumCommon++, 
BCrecordnextdata = ButtonNumCommon++, 
BCtimedomain = ButtonNumCommon++, 
BCtraindomain = ButtonNumCommon++, 
BCmousedomain = ButtonNumCommon++, 
BCsnakedomain = ButtonNumCommon++, 
BCserialreset = ButtonNumCommon++, 
BCsave = ButtonNumCommon++;


int Bheight = 25; // button height
int Bheights = 20; // button height

float fps = 30;
int VoltScale = 1;
float VoltageMax = 10/VoltScale;
float VoltageMin = -10/VoltScale;
float AmpGain = 1845; // 495 from Instrumentation Amp, 3.73 from second stage.  1845 total.
float DynamicRange = 1.355;//mV.  5V max, split around 2.5.  2.5V/1845 = 1.355mV.
float Resolution = DynamicRange/1024;// mV, 1.355mV/1024 = 1.3uV.  NOTE - resolution is likely worse than this - most ADCs' botton 2-3 bits are just noise.  10uV is a more reasonable estimate
int MaxSignalVal = 512;//1024 / 2 (-512 : +512);
int HalfSignalVal = 512; // same
int Nxticks = 5;
int Nyticks = 4;
int NyticksHalf = 2;
int MaxSignalLength = 1000;
int FFTSignalLength = 1024;
int pointThickness = 3;
int ytmp;
int MedianFiltN = 3;

// Register variables and constants
int[] UserFreqArray = {  
  1, 10, 50, 100, 200, 300, 400, 500, 1000, 1500, 2000
};
int UserFreqIndexTraining = 7;
int UserFreqIndexMouse = 7;
int UserFreqIndexFFT = 8;
int UserFreqIndexDefault = 7;
int UserFreqIndex = UserFreqIndexDefault;
int UserFrequency = UserFreqArray[UserFreqIndex];//40;//1000;
int UserFreqCustom = 0;
int UserFreqCustomMax = 4000;
int UserFreqCustomMin = 0;
int SmoothFilterVal = 8;
int SmoothFilterValDefault = 8;
int SmoothFilterValMin = 0, SmoothFilterValMax = 50;
int Timer0PartialCount = 0;
Boolean BitDepth10 = true;
int Timer0AdjustVal = 2;
int Timer0AdjustValMin = -5;
int Timer0AdjustValMax = 248;
int Prescaler = 2;
int PrescalerMin = 0;
int PrescalerMax = 2;
int DownSampleCount = 1;
int DownSampleCountMax = 100;
int DownSampleCountMin = 0;
int DownSampleCountTraining = 5;
int DownSampleCountMouse = 5;

// Colors
color BoutlineColor = color(0);
color BIdleColor = color(160);
color BOnColor = color(100);
color BPressedColor = color(70);
color Sig1Color = color(255, 0, 0);//red
color Sig2Color = color(0, 255, 0);//green
color Sig3Color = color(0, 0, 255);//blue
color Sig4Color = color(255, 128, 0);//orange
color Sig5Color = color(0, 255, 255);//cyan
color Sig6Color = color(255, 255, 0);//yellow
color Sig7Color = color(255, 0, 255);//fushcia
color Sig8Color = color(255, 255, 255);//white
color SigColorM[] = {  
  Sig1Color, Sig2Color, Sig3Color, Sig4Color, Sig5Color, Sig6Color, Sig7Color, Sig8Color
};
color Signalcolor = color(255);
color FFTcolor = color(255, 255, 0);
color labelcolor = color(0);
color plotbackground = color(100);
color plotoutline = color(0);
color backgroundcolor = color(200);

// FFT variables
FFTutils fft;
FIRFilter filter1, filter2;
float[] filtered;
float[][] fft_result;//1, fft_result2, fft_result3, fft_result4;
float[][] FFTsignalIn; // longer for FFT calculation


//int xPos = 0;
float[][] signalIn;//1, signalIn2, signalIn3, signalIn4;
int[] oldPlotSignal;



float TimeMax = float(FullPlotWidth)/float(UserFrequency);
int datacounter = 0;
int signalindex = 0;
int SignalNumber = 4;
int MaxSignalNumber = 8;
long[] TimeStamp;
long ButtonColorTimer = 0;
long ButtonColorDelay = 100;

int CheckSerialNSamples = 2;
int CheckSerialMinTime = 250;
long CheckSerialDelay = (long)max( CheckSerialMinTime, 1000.0/((float)UserFrequency/CheckSerialNSamples) );//2000;//UserFrequency/10; // millis. check at 10Hz
int CalibrateN = 50;
int CalibrateCounter = CalibrateN;
int Calibration[] = {  
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
int[][] DataRecord;
int DataRecordCols = 9;
int DataRecordTime = 10; // seconds
int DataRecordLength = DataRecordTime*UserFrequency;
int DataRecordIndex = 0;
int DataRecordedCounter = 0;
int DataRecordTimeMax = 50;
int DataRecordTimeMin = 1;

/*********** Page Variables ************/
// any page variables that require access for saving and loading should go here

// MouseVariables
int XLow = 0, XHigh = 1, YLow = 2, YHigh = 3;
int MouseThresh[] = {    
  MaxSignalVal*5/4, MaxSignalVal*6/4, MaxSignalVal*5/4, MaxSignalVal*6/4
};// xlow, xhigh, ylow, yhigh
int[] MouseChan = {    
  0, 1
};
// Frequency variables
int FrequencyMax = 200;
/*********** End Page Variables ************/

// Flags
boolean InitFlag = true;
boolean dataflag = false;
boolean initializeFlag = true;
boolean MouseReleaseFlag = false;
boolean PauseFlag = false;
boolean OffSetFlag = false;
boolean SmoothFilterFlag = false;
boolean ButtonPressedFlag = false;
boolean Bonoff = false;
boolean Bmomentary = true;
boolean ChannelOn[]= {  
  true, true, true, true, false, false, false, false
};
boolean DataRecordFlag = false;
boolean SerialReceivedFlag = false;
boolean MedianFilter = false;
boolean PlugTestFlag = false;
boolean helpFlag = false;
boolean DataRegWriteFlag = false;
boolean snakeGameFlag = false;

int PlugTestDelay = 0;
int testcounter = 0;

long startTime = System.nanoTime();
// ... the code being measured ...
long estimatedTime = System.nanoTime() - startTime;
long endTime;

int InitCount = 0;
int XMIN;
int XMAX;
int YMIN;
int YMAX;

String[] USBPORTs = new String[0];
String[] BluetoothPORTs = new String[0];

PImage img;

int VersionBufferN = 4;
int VERSION;
int SERIALNUMBER;
int MODELNUMBER;

SerialPortObj FVserial;

ArrayList<pagesClass> FVpages;
int settingspage, timedomainpage, frequencydomainpage, workoutpage, targetpracticepage, snakegamepage, musclemusicpage;

boolean commentflag = true;
boolean communicationsflag = false;
int currentWidth;
int currentHeight;

void setup () {

  FVpages = new ArrayList<pagesClass>();
  int tmpindex = 0;
  FVpages.add(new SettingsPage(this));       
  settingspage = tmpindex++;
  FVpages.add(new TimeDomainPlotPage()); 
  timedomainpage = tmpindex++;
  FVpages.add(new WorkoutPage());        
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
  frame.setTitle("Hello!");

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
  fft=new FFTutils(FFTSignalLength);
  fft.useEqualizer(false);
  fft.useEnvelope(true, 1);
  fft_result = new float[MaxSignalNumber][FFTSignalLength];
  signalIn = new float[MaxSignalNumber][MaxSignalLength];
  FFTsignalIn = new float[MaxSignalNumber][FFTSignalLength];
  oldPlotSignal = new int[MaxSignalNumber];

  filter1=new FIRFilter(FIRFilter.LOW_PASS, 2000f, 0, 1000, 60, 3400);
  filter2=new FIRFilter(FIRFilter.HIGH_PASS, 2000f, 20, 10, 60, 3400);

  TimeStamp = new long[5000];

  FVserial = new SerialPortObj(this);
}

void stop() {  // doesn't actually get called on closed, but it should, and hopefully will in future versions!
  if (myPort != null) {
    myPort.write('X');
    myPort.clear();
  }
}

void initializeEverything() {

  HalfPlotWidth = FullPlotWidth/2;
  // set the window size TODO get window size, modify
  // size(FullPlotWidth+barwidth+xStep, plotheight+yStep+yTitle, P2D);
  size(FullPlotWidth+barwidth+xStep, plotheight+yStep+yTitle);
  currentWidth = width;
  currentHeight = height;
  ytmp = height - yStep;
  println("w = "+currentWidth+", h = "+currentHeight+", ytmp = "+ytmp);

  XMIN = xStep+pointThickness;
  XMAX = xStep+FullPlotWidth-pointThickness;
  YMIN = yTitle+pointThickness;
  YMAX = yTitle+plotheight-pointThickness;

  Bheight = 25; // button height
  Bheights = 20; // button height

  initializeButtons();

  for (int i = 0; i < FVpages.size(); i++) {
    FVpages.get(i).initializeButtons();
  }
}

void checkResize() {
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
    barwidth = 100;
    FullPlotWidth = width - xStep - barwidth;
    plotheight = height - yTitle - yStep;
    plotwidth = FullPlotWidth;
    HalfPlotWidth = FullPlotWidth/2;
    XMIN = xStep+pointThickness;
    XMAX = xStep+FullPlotWidth-pointThickness;
    YMIN = yTitle+pointThickness;
    YMAX = yTitle+plotheight-pointThickness;

    Bheight = 25; // button height
    Bheights = 20; // button height

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
      EstablishDataLink();
    }
  }
}

void initializeButtons() {
  buttonsCommon = new GuiButton[ButtonNumCommon];
  buttonsCommon[BCsettings]       = new GuiButton("Settings", 's', settingspage, xStep+plotwidth+55, yTitle+plotheight+yStep/2, 70, Bheight, color(BIdleColor), color(0), "Settings", Bmomentary, false);
  buttonsCommon[BChelp]           = new GuiButton("Help", 'h', dummypage, xStep+plotwidth-35, 30, 25, 25, color(BIdleColor), color(0), "?", Bmomentary, false);
  buttonsCommon[BCsave]           = new GuiButton("Store", 'i', dummypage, xStep+50, yTitle-45, 100, 20, color(BIdleColor), color(0), "Save Image", Bmomentary, false);
  buttonsCommon[BCrecordnextdata] = new GuiButton("SaveRecord", 'd', dummypage, xStep+50, yTitle-20, 100, 20, color(BIdleColor), color(0), "Record "+DataRecordTime+"s", Bmomentary, false);
  buttonsCommon[BCtimedomain]     = new GuiButton("TimePage", 't', timedomainpage, xStep+FullPlotWidth/2-73, yTitle-10, 100, 20, color(BIdleColor), color(0), "Plot Signals", Bonoff, true);
  buttonsCommon[BCtraindomain]    = new GuiButton("WorkoutPage", 'w', workoutpage, xStep+FullPlotWidth/2+19, yTitle-10, 75, 20, color(BIdleColor), color(0), "Workout", Bonoff, false);
  buttonsCommon[BCmousedomain]    = new GuiButton("MousePage", 'm', targetpracticepage, xStep+FullPlotWidth/2+115, yTitle-10, 110, 20, color(BIdleColor), color(0), "MouseGames", Bonoff, false);
  buttonsCommon[BCsnakedomain]    = new GuiButton("SnakeGame", 'n', snakegamepage, xStep+FullPlotWidth/2+115, yTitle-10, 110, 20, color(BIdleColor), color(0), "MouseGames", Bonoff, false);
  buttonsCommon[BCserialreset]    = new GuiButton("SerialReset", 'r', dummypage, xStep+FullPlotWidth+55, yTitle/2, 60, 20, color(BIdleColor), color(0), "Reset", Bmomentary, false);
}

void draw () {
  if (InitFlag) {
    InitCount ++;
    if (InitCount == 1) {
      frame.setLocation(0, 0);//1441
      xx = frame.getX()+2;
      if (platform == MACOSX) {
        yy = frame.getY()+42; // add ace for the mac top bar + the app top bar
      } 
      else if (platform == WINDOWS) {
        yy = frame.getY()+22; // add ace for teh app top bar
      }

      background(backgroundcolor);

      for (int i = 0; i < buttonsCommon.length; i++) {
        buttonsCommon[i].drawButton();
      }
      FVpages.get(currentpage).switchToPage();
      FVpages.get(currentpage).drawPage();

      labelGUI();

      display_error("Searching for FlexVolt Devices");
    }
    if (InitCount >= 2) {
      startTime = System.nanoTime();
      // frame.setLocation(1481, 0);//1441

      InitFlag = false;
      FVserial.connectserial();// the function will poll devices, set connecting flag, and set current try port index to 0
    }
  }

  checkResize();

  if (ButtonPressedFlag) {
    if (millis() > ButtonColorTimer) {
      ButtonPressedFlag = false;
      println("Current Button = " + currentbutton);
      if (buttonsCommon[currentbuttonCommon] != null && currentbuttonCommon < buttonsCommon.length) {
        buttonsCommon[currentbuttonCommon].ChangeColorUnpressed();
        labelGUI();
      }
    }
  }

  dataflag = FVserial.manageConnection(dataflag, SerialReceivedFlag);
  SerialReceivedFlag = false;

  if (!helpFlag) {
    FVpages.get(currentpage).drawPage();
  }
}

void serialEvent (Serial myPort) {
  int tmpfillColor = g.fillColor;
  int tmpstrokeColor = g.strokeColor;
  float tmpstrokeWeight = g.strokeWeight;

  //  println(myPort.available()+"dataflag = "+dataflag+", communicationflag = "+communicationsflag);
  if (!communicationsflag && !dataflag) {
    int inChar = myPort.readChar(); // get ASCII
    if (inChar != -1) {
      SerialReceivedFlag = true;
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
        FVserial.drawConnectionIndicator();
        UpdateSettings(); //EstablishDataLink is rolled in
        println("updated settings");
        communicationsflag = true;
      }
    }
  } 
  else if (communicationsflag && !dataflag) {
    int inChar = myPort.readChar(); // get ASCII
    if (inChar != -1) {
      SerialReceivedFlag = true;
      println("handshaking, "+inChar+", count = "+testcounter);
      if (inChar == 'g') {
        myPort.clear();
        println("dataflag = true g");
        blankplot();
        dataflag = true;
        FVserial.connectionindicator = FVserial.indicator_connected;
        FVserial.drawConnectionIndicator();
        myPort.buffer((SerialBufferN+1)*SerialBurstN);
      }
      else if (inChar == 'y') {
        println("Received 'Y'");
      }
      else if (inChar == 'v') {
        byte[] inBuffer = new byte[VersionBufferN];
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
    byte[] inBuffer = new byte[SerialBufferN];
    //    println("avail = "+myPort.available());
    while (myPort.available () > SerialBufferN) {
      // println((System.nanoTime()-startTime)/1000);

      //      println(myPort.available());
      int inChar = myPort.readChar(); // get ASCII
      // print("data, ");println(inChar);
      if (inChar != -1) {
        SerialReceivedFlag = true;

        if (inChar == 'C' || inChar == 'D' || inChar == 'E' || inChar == 'F') {
          myPort.readBytes(inBuffer);
          //          println("Received8bit - "+inChar+", buffer = "+SerialBufferN);
          // println(inBuffer);
          for (int i = 0; i < SignalNumber; i++) {
            int tmp = inBuffer[i]; // last 2 bits of each signal discarded
            tmp = tmp&0xFF; // account for translation from unsigned to signed
            tmp = tmp << 2; // shift to proper position
            float rawVal = float(tmp);

            if (currentpage == frequencydomainpage) {
              arrayCopy(FFTsignalIn[i], 1, FFTsignalIn[i], 0, FFTSignalLength-1);
              FFTsignalIn[i][FFTSignalLength-1]=rawVal;
            }
            else {
              signalIn[i][signalindex]=rawVal;
            }
            if (DataRecordFlag && DataRecordIndex < DataRecordLength) {
              DataRecord[i][DataRecordIndex]=int(rawVal);
            }
          }
          if (DataRecordFlag) {
            DataRecordIndex++;
            if (DataRecordIndex >= DataRecordLength) {
              if ((DataRecordIndex % 10) == 0) {
                println("Saving"+str(DataRecord[1][DataRecordIndex-1]));
              }
              DataRecordedCounter = SaveRecordedData(DataRecordedCounter);
              DataRecordFlag = false;
            }
          }
          signalindex ++;//= DownSampleCount;
          if (signalindex >= MaxSignalLength)signalindex = 0;
          datacounter++;
          if (datacounter >= MaxSignalLength)datacounter = MaxSignalLength;
        }
        else if (inChar == 'H' || inChar == 'I' || inChar == 'J' || inChar == 'K') {
          myPort.readBytes(inBuffer);
          for (int i = 0; i < SignalNumber; i++) {
            int tmplow = inBuffer[SerialBufferN-1]; // last 2 bits of each signal stored here
            tmplow = tmplow&0xFF; // account for translation from unsigned to signed
            tmplow = tmplow >> (2*(3-i)); // shift to proper position
            tmplow = tmplow & (3); //3 (0b00000011) is a mask.
            int tmphigh = inBuffer[i];
            tmphigh = tmphigh & 0xFF; // account for translation from unsigned to signed
            tmphigh = tmphigh << 2; // shift to proper position
            float rawVal = float(tmphigh+tmplow);
            if (currentpage == frequencydomainpage) {
              arrayCopy(FFTsignalIn[i], 1, FFTsignalIn[i], 0, FFTSignalLength-1);
              FFTsignalIn[i][FFTSignalLength-1]=rawVal;
            }
            else {
              signalIn[i][signalindex]=rawVal;
            }
            if (DataRecordFlag && (DataRecordIndex < DataRecordLength)) {
              // println("Saving Point: "+DataRecordIndex);
              DataRecord[i][DataRecordIndex]=int(rawVal);
            }
          }
          if (DataRecordFlag) {
            DataRecordIndex++;
            if ((DataRecordIndex % 10) == 0) {
              println("Saving"+DataRecordIndex);
            }
            if (DataRecordIndex >= DataRecordLength) {
              DataRecordedCounter = SaveRecordedData(DataRecordedCounter);
              DataRecordFlag = false;
            }
          }
          signalindex ++;//= DownSampleCount;
          if (signalindex >= MaxSignalLength)signalindex = 0;
          datacounter++;
          if (datacounter >= MaxSignalLength)datacounter = MaxSignalLength;
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
int keyInput = 1;
int mouseInput = 2;

void useKeyPressedOrMousePressed(int inputDev) {
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
    buttonsCommon[BChelp].BOn = false;
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
        if (buttonsCommon[i].pageRef >= 0 && buttonsCommon[i].pageRef < FVpages.size()) {
          buttonsCommon[i].BOn = true;
          buttonsCommon[i].ChangeColorPressed();
          changePage(buttonsCommon[i].pageRef); // calls labelGUI
          println("Going to page"+buttonsCommon[i].pageRef);
        } 
        else {
          buttonsCommon[i].BOn = true;
          buttonsCommon[i].ChangeColorPressed();
          ButtonColorTimer = millis()+ButtonColorDelay;
          ButtonPressedFlag = true;
          currentbuttonCommon = i;

          if (buttonsCommon[currentbuttonCommon].hotKey == 'h') {
            FVpages.get(currentpage).drawHelp();
            helpFlag = true;
          }
          if (buttonsCommon[currentbuttonCommon].hotKey == 'r') {
            ResetSerialConnection();
          }
          if (buttonsCommon[currentbuttonCommon].hotKey == 'g') {
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
void keyPressed() {
  if (keyCode == ESC||key == ESC) {
    key = 0;
    keyCode = 0;
  }
  useKeyPressedOrMousePressed(keyInput);
}

// Mouse Button Handling Section
void mousePressed() {
  useKeyPressedOrMousePressed(mouseInput);
}


void drawMyLine(int x1, int y1, int x2, int y2, color c, int w) {
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

void setPixel(int x, int y, color c) {
  x = constrain(x, XMIN, XMAX);
  y = constrain(y, YMIN, YMAX);
  // if (x < XMIN || x >= XMAX) return;
  // if (y < YMIN || y >= YMAX) return;
  // int N = 4;
  // for (int j = y-N; j<=y+N;j++){
  // pixels[x + j * width] = c;
  // }
  //  println("x = "+x+", y = "+y+", width = "+width);
  pixels[x + y * width] = c;
}


void drawHelp() {
  blankplot();
  stroke(0);
  strokeWeight(4);
  fill(200);
  rectMode(CENTER);
  textAlign(CENTER, CENTER);
  rect(width/2, height/2+10, width/2+200, height/2+180, 12);

  fill(0);
  textSize(30);
  text("Help Page", width/2-200, height/2-240);

  fill(0);
  textSize(20);
  text("Press Any Key or Click Anywhere To Go Back", width/2+150, height/2-240);

  String helpdoc = "";
  helpdoc = helpdoc + "This App should connect FlexVolt to your computer automatically.\n";
  helpdoc = helpdoc + " For troubleshooting, try resetting the connection using 'Reset'.\n";
  helpdoc = helpdoc + " If that does not work, unplug the USB cable, then plug back in and click 'Reset'.\n";
  helpdoc = helpdoc + "\n";
  helpdoc = helpdoc + "Use View Mode Button or Hotkeys to go to Pages:\n";
  helpdoc = helpdoc + " Time (hotkey 't') - home page, plot signals vs. time\n";
  helpdoc = helpdoc + " Frequency (hotkey 'f') - plot signal frequencies (using FFT).\n";
  helpdoc = helpdoc + " Train (Workout) (hotey 'w') - monitor reps, work towards a goal\n";
  helpdoc = helpdoc + " Mouse (hotkey 'm') - control your computer mouse\n";
  helpdoc = helpdoc + "\n";
  helpdoc = helpdoc + "Hot Keys Can Also be Used to Toggle:\n";
  helpdoc = helpdoc + " 'h' = help page 's' = settings page 'r' = reset connection\n";
  helpdoc = helpdoc + " 'c' = clear plot 'p' = pause/unpause 'k' = calibrate mouse\n";
  helpdoc = helpdoc + " 'o' = offset plot lines 'j ' = smoothing filter\n";
  helpdoc = helpdoc + "\n";
  helpdoc = helpdoc + "For addtional help, go to www.flexvoltbiosensor.com\n";
  fill(0);
  textSize(18);
  textAlign(LEFT, CENTER);
  text(helpdoc, width/2, height/2+40, width/2+140, height/2+120);
  textAlign(CENTER, CENTER);
}


void ClearYAxis() {
  fill(backgroundcolor);
  stroke(backgroundcolor);
  rectMode(CENTER);
  // stroke(0);
  rect(xStep/2, yTitle+plotheight/2, xStep, plotheight);
}


void blankplot() {
  fill(plotbackground);
  stroke(plotoutline);
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

void labelGUI() {

  // Logo
  if (img != null) {
    image(img, 5, yTitle/2-(yTitle-30)/2, xStep-10, yTitle-30);
  }
  else if (img == null) {
    textSize(labelsizexs);
    fill(20, 150, 20);
    textAlign(CENTER, CENTER);
    text("FlexVolt\nViewer\n"+ViewerVersion, xStep/2, yTitle/2-2);
  }

  fill(labelcolor);
  textSize(labelsizes);
  text("Connection", xStep+FullPlotWidth+45, yTitle*3/16);

  FVserial.drawConnectionIndicator();

  for (int i = 0; i < buttonsCommon.length; i++) {
    buttonsCommon[i].drawButton();
  }
}
// End of plotting section

void UpdatePorts(int ports) {
}

void saveData() {
  DataRecordFlag = true;
  println("UserFreq = "+UserFrequency+", DataRecordTime = "+DataRecordTime);
  DataRecordLength = DataRecordTime*UserFrequency;
  DataRecord = new int[DataRecordCols][DataRecordLength];
  DataRecordIndex = 0;
}

int SaveRecordedData(int datasavecounter) {
  String[] lines = new String[DataRecordLength];
  for (int i=0; i<DataRecordLength;i++) {
    lines[i] = nf(i, 6)+", ";
    for (int j=0; j<SignalNumber;j++) {
      lines[i] += str(DataRecord[j][i]) +", ";
    }
  }
  String[] saveheader = {
    "FlexVolt Saved Data", "Frequency = "+UserFrequency, "Signal Amplification Factor = "+AmpGain, "Index , Ch1, Ch2, Ch3, Ch4, Ch5, Ch6, Ch7, Ch8"
  };
  String[] savearray = concat(saveheader, lines);
  if (platform == MACOSX) {
    saveStrings(folder+"/FlexVoltData_"+year()+"-"+nf(month(), 2)+"-"+nf(day(), 2)+"_"+ nf(hour(), 2) +"h-"+ nf(minute(), 2) +"m-"+ nf(second(), 2)+"s_"+nf(datasavecounter, 3)+".txt", savearray);
  }
  else if (platform == WINDOWS) {
    saveStrings(folder+"\\FlexVoltData_"+year()+"-"+nf(month(), 2)+"-"+nf(day(), 2)+"_"+ nf(hour(), 2) +"h-"+ nf(minute(), 2) +"m-"+ nf(second(), 2)+"s_"+nf(datasavecounter, 3)+".txt", savearray);
  }
  datasavecounter ++;
  return datasavecounter;
}

int saveImage(int imagesavecounter) {
  String a0 = "";
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

void display_error(String msg) {
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

void delay(int delay)
{
  int time = millis();
  while (millis () - time <= delay);
}

void ResetSerialConnection() {
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
  initializeFlag = true;
  FVserial.connectserial();
  FVserial.drawConnectionIndicator();
}


void EstablishDataLink() {
  if (myPort == null) {
    println("no port to connect to");
    return;
  }
  myPort.write('G'); // tells Arduino to start sending data
  if (commentflag)println("sent G at establishdatalink");

  SerialBufferN = SignalNumber;
  if (commentflag)println("Signum = "+SignalNumber);
  if (BitDepth10) {
    SerialBufferN += 1;
    if (SignalNumber > 4) {
      SerialBufferN += 1;
    }
  }
  if (commentflag)println("SignalBuffer = "+SerialBufferN);

  myPort.buffer((SerialBufferN+1)*SerialBurstN);
}


void StopData() {
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

void importSettings() {
  String loadedsettings[] = loadStrings(HomePath+"/FlexVoltViewerSettings.txt");
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
      UserFreqIndex = int(loadedsettings[2]);
      UserFrequency = UserFreqArray[UserFreqIndex];
    } 
    else {
      UserFreqIndex = UserFreqIndexDefault;
      UserFrequency = UserFreqArray[UserFreqIndex];
    }
    CheckSerialDelay = (long)max( CheckSerialMinTime, 1000.0/((float)UserFrequency/CheckSerialNSamples) );
    TimeMax = float(FullPlotWidth)/float(UserFrequency);
    println("UserFrequencyIndex = " + UserFreqIndex);
    println("UserFrequency = " + UserFrequency);

    // smoothing filter factor
    m = match(loadedsettings[3], "null");
    if (m == null) {
      SmoothFilterVal = int(loadedsettings[3]);
    } 
    else {
      SmoothFilterVal = SmoothFilterValDefault;
    }
    println("SmoothFilterVal = " + SmoothFilterVal);

    // mouse calibration values
    m = match(loadedsettings[4], "null");
    if (m == null) {
      MouseThresh[XLow] = int(loadedsettings[4]);
    }
    m = match(loadedsettings[5], "null");
    if (m == null) {
      MouseThresh[XHigh] = int(loadedsettings[5]);
    }
    m = match(loadedsettings[6], "null");
    if (m == null) {
      MouseThresh[YLow] = int(loadedsettings[6]);
    }
    m = match(loadedsettings[7], "null");
    if (m == null) {
      MouseThresh[YHigh] = int(loadedsettings[7]);
    }

    println(MouseThresh);
  }
}

void PollVersion() {
  if (myPort == null) {
    println("no port to poll");
    return;
  }
  StopData(); // turn data off
  // handle changes to the Serial buffer coming out of settings
  delay(serialwritedelay);
  myPort.clear();
  println("sent Q version");
  myPort.buffer(VersionBufferN+1);
  myPort.clear();

  myPort.write('V'); // Poll version and SN
  delay(serialwritedelay);

  EstablishDataLink();
}

void UpdateSettings() {
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


    DataRegWriteFlag = true;
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
    if (SignalNumber == 8)tmp = 3;
    if (SignalNumber == 4)tmp = 2;
    if (SignalNumber == 2)tmp = 1;
    if (SignalNumber == 1)tmp = 0;
    println(binary(tmp));
    REGtmp = tmp << 6;
    REGtmp += UserFreqIndex << 2;
    tmp = 0;
    if (SmoothFilterFlag) {
      tmp = 1;
    }
    REGtmp += tmp << 1;
    tmp = 0;
    if (BitDepth10) {
      tmp = 1;
    }
    REGtmp += tmp;
    myPort.write(REGtmp);//10100001
    delay(serialwritedelay);

    REGtmp = 0;
    REGtmp += Prescaler << 5;
    REGtmp += SmoothFilterVal;
    myPort.write(REGtmp);
    delay(serialwritedelay);//01000101

    REGtmp = UserFreqCustom;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = UserFreqCustom>>8;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = Timer0AdjustVal+6;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = Timer0PartialCount;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = Timer0PartialCount>>8;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = DownSampleCount;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    REGtmp = PlugTestDelay;
    myPort.write(REGtmp);
    delay(serialwritedelay);

    myPort.write('Y');
    delay(serialwritedelay);

    EstablishDataLink();
  }
}

int getIntFromString(String savedname, int defaultval) {
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

void changePage(int newPage) {
  oldpage = currentpage;
  currentpage = newPage;
  println("oldpage = "+oldpage+", newpage = "+currentpage);

  if (newPage != settingspage) {
    background(backgroundcolor);
  }

  buttonsCommon[BCsettings].ChangeColorUnpressed();
  buttonsCommon[BChelp].ChangeColorUnpressed();
  buttonsCommon[BCtimedomain].BOn = false;
  buttonsCommon[BCtraindomain].BOn = false;
  buttonsCommon[BCmousedomain].BOn = false;

  FVpages.get(currentpage).switchToPage();
  labelGUI();

  loadPixels();
}



/************************* BEGIN SETTINGS Page ***********************/
public class SettingsPage implements pagesClass {
  // variables
  PApplet parent;

  GuiButton[] buttons;
  int ButtonNum = 0;
  int
    Bfolder = ButtonNum++, 
  Bfiltup = ButtonNum++, 
  Bfiltdown = ButtonNum++, 
  Bfrequp = ButtonNum++, 
  Bfreqdown = ButtonNum++, 
  Brecordtimeup = ButtonNum++, 
  Brecordtimedown = ButtonNum++, 
  B1chan = ButtonNum++, 
  B2chan = ButtonNum++, 
  B4chan = ButtonNum++, 
  B8chan = ButtonNum++, 
  Bcancel = ButtonNum++, 
  Bsave = ButtonNum++, 
  Bdefaults = ButtonNum++, 
  Bdownsampleup = ButtonNum++, 
  Bdownsampledown = ButtonNum++, 
  Btimeradjustup = ButtonNum++, 
  Btimeradjustdown = ButtonNum++, 
  //Bbitdepth8 = ButtonNum++,
  //Bbitdepth10 = ButtonNum++,
  Bprescalerup = ButtonNum++, 
  Bprescalerdown = ButtonNum++;
  // Settings Page Buttons

  String pageName = "Settings";
  String folderTmp = "";
  String tmpfolder = "";
  int currentbutton = 0;
  int UserFrequencyTmp;
  int UserFreqIndexTmp;
  int SmoothFilterValTmp;
  int DownSampleCountTmp;
  int Timer0AdjustValTmp;
  int PrescalerTmp;
  int DataRecordTimeTmp;
  int SignalNumberTmp;
  boolean ButtonPressedFlag = false;

  // constructor
  SettingsPage(PApplet parent) {
    this.parent = parent;
    // set input variables
    initializeButtons();

    folderTmp = folder;
    UserFreqIndexTmp = UserFreqIndex;
    UserFrequencyTmp = UserFreqArray[UserFreqIndexTmp];
    SmoothFilterValTmp = SmoothFilterVal;
    DownSampleCountTmp = DownSampleCount;
    Timer0AdjustValTmp = Timer0AdjustVal;
    PrescalerTmp = Prescaler;
    DataRecordTimeTmp = DataRecordTime;
    SignalNumberTmp = SignalNumber;
  }

  void initializeButtons() {
    buttons = new GuiButton[ButtonNum];
    println("width here = "+width);
    buttons[Bfolder]         = new GuiButton("Folder", ' ', dummypage, width/2-200, height/2-110, 80, Bheights, color(BIdleColor), color(0), "change", Bmomentary, false);
    buttons[Bfiltup]         = new GuiButton("FilterUp", ' ', dummypage, width/2+115, height/2+10, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
    buttons[Bfiltdown]       = new GuiButton("FilterDn", ' ', dummypage, width/2+65, height/2+10, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
    buttons[Bfrequp]         = new GuiButton("FreqUp", ' ', dummypage, width/2-160, height/2+10, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
    buttons[Bfreqdown]       = new GuiButton("FreqDn", ' ', dummypage, width/2-230, height/2+10, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
    buttons[Brecordtimeup]   = new GuiButton("RecordTimeUp", ' ', dummypage, width/2+200, height/2-70, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
    buttons[Brecordtimedown] = new GuiButton("RecordTimeDn", ' ', dummypage, width/2+130, height/2-70, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
    buttons[B1chan]          = new GuiButton("1chanmodel", ' ', dummypage, width/2-105, height/2+10, 30, Bheights, color(BIdleColor), color(0), "1", Bonoff, false);
    buttons[B2chan]          = new GuiButton("2chanmodel", ' ', dummypage, width/2-70, height/2+10, 30, Bheights, color(BIdleColor), color(0), "2", Bonoff, false);
    buttons[B4chan]          = new GuiButton("4chanmodel", ' ', dummypage, width/2-35, height/2+10, 30, Bheights, color(BIdleColor), color(0), "4", Bonoff, true);
    buttons[B8chan]          = new GuiButton("8chanmodel", ' ', dummypage, width/2+0, height/2+10, 30, Bheights, color(BIdleColor), color(0), "8", Bonoff, false);
    buttons[Bdownsampleup]   = new GuiButton("DownSampleUp", ' ', dummypage, width/2+220, height/2+10, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
    buttons[Bdownsampledown] = new GuiButton("DownSampleDn", ' ', dummypage, width/2+170, height/2+10, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
    buttons[Btimeradjustup]  = new GuiButton("TimerAdjustUp", ' ', dummypage, width/2-70, height/2+80, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
    buttons[Btimeradjustdown]= new GuiButton("TimerAdjustDn", ' ', dummypage, width/2-130, height/2+80, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
    buttons[Bprescalerup]    = new GuiButton("PrescalerUp", ' ', dummypage, width/2+60, height/2+80, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
    buttons[Bprescalerdown]  = new GuiButton("PrescalerDn", ' ', dummypage, width/2+0, height/2+80, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
    buttons[Bsave]           = new GuiButton("Save", 's', dummypage, width/2-160, height/2+130, 140, 30, color(BIdleColor), color(0), "Save & Exit (s)", Bonoff, false);
    buttons[Bdefaults]       = new GuiButton("Defaults", 'd', dummypage, width/2+160, height/2+130, 140, 30, color(BIdleColor), color(0), "Restore Defaults", Bonoff, false);
    buttons[Bcancel]         = new GuiButton("Exit", 'c', dummypage, width/2, height/2+130, 120, 30, color(BIdleColor), color(0), "Cancel (c)", Bonoff, false);
  }

  void switchToPage() {
    folderTmp = folder;
    UserFreqIndexTmp = UserFreqIndex;
    UserFrequencyTmp = UserFrequency;
    SmoothFilterValTmp = SmoothFilterVal;
    DownSampleCountTmp = DownSampleCount;
    Timer0AdjustValTmp = Timer0AdjustVal;
    PrescalerTmp = Prescaler;
    DataRecordTimeTmp = DataRecordTime;
    SignalNumberTmp = SignalNumber;

    StopData(); // turn data off
    delay(serialwritedelay);
    if (myPort != null) {
      myPort.clear();
    }
    println("width = "+width+", height = "+height+". but parent.width = "+parent.width);
  }

  void drawPage() {
    // draw subfunctions
    if (ButtonPressedFlag) {
      if (millis() > ButtonColorTimer) {
        ButtonPressedFlag = false;
        println("Current Button = " + currentbutton);
        if (buttons[currentbutton] != null && currentbutton < buttons.length) {
          buttons[currentbutton].ChangeColorUnpressed();
        }
      }
    }

    drawSettings();
  }

  String getPageName() {
    return pageName;
  }

  void saveSettings() {
    // save all tmp vals from the settings menu in the actual variables
    folder = folderTmp;
    UserFreqIndex = UserFreqIndexTmp;
    SmoothFilterVal = SmoothFilterValTmp;
    DownSampleCount = DownSampleCountTmp;
    Timer0AdjustVal = Timer0AdjustValTmp;
    Prescaler = PrescalerTmp;
    DataRecordTime = DataRecordTimeTmp;
    SignalNumber = SignalNumberTmp;

    UserFrequency = UserFreqArray[UserFreqIndex];
    TimeMax = float(FullPlotWidth)/float(UserFrequency);
    UserFreqCustom = 0;
    CheckSerialDelay = (long)max( CheckSerialMinTime, 1000.0/((float)UserFrequency/CheckSerialNSamples) );
    DataRecordLength = DataRecordTime*UserFrequency;
    buttonsCommon[BCrecordnextdata].label = "Record "+DataRecordTime+"s";
    for (int i = 0; i<MaxSignalNumber;i++) {
      if (i < SignalNumber) {
        ChannelOn[i]=true;
      } 
      else if (i >= SignalNumber) {
        ChannelOn[i]=false;
      }
    }
    TimeMax = float(FullPlotWidth)/float(UserFrequency);

    // build and save a txt file of settings
    String[] SettingString = new String[8];
    SettingString[0] = "FlexVoltViewer User Settings";
    SettingString[1] = folder;
    SettingString[2] = str(UserFreqIndex);
    SettingString[3] = str(SmoothFilterVal);
    SettingString[4] = str(MouseThresh[XLow]);
    SettingString[5] = str(MouseThresh[XHigh]);
    SettingString[6] = str(MouseThresh[YLow]);
    SettingString[7] = str(MouseThresh[YHigh]);

    saveStrings(HomePath+"/FlexVoltViewerSettings.txt", SettingString);
    UpdateSettings();
  }

  boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
    boolean outflag = false;
    currentbutton = -1;
    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        if ( (inputDev == mouseInput && buttons[i].IsMouseOver(x, y)) || (inputDev == keyInput && tkey == buttons[i].hotKey) ) {
          outflag = true;
          buttons[i].BOn = !buttons[i].BOn;
          buttons[i].ChangeColorPressed();
          ButtonColorTimer = millis()+ButtonColorDelay;
          ButtonPressedFlag = true;
          currentbutton = i;

          if (currentbutton == Bfolder) {
            println("getting folder");
            waitForFolder();
            println(folder);
          }
          if (currentbutton == Bfrequp) {
            UserFreqIndexTmp++;
            if (UserFreqIndexTmp >= UserFreqArray.length)UserFreqIndexTmp=UserFreqArray.length-1;
            println(UserFreqIndexTmp);
            UserFrequencyTmp = UserFreqArray[UserFreqIndexTmp];
          }
          if (currentbutton == Bfreqdown) {
            UserFreqIndexTmp--;
            if (UserFreqIndexTmp < 0)UserFreqIndexTmp=0;
            println(UserFreqIndexTmp);
            UserFrequencyTmp = UserFreqArray[UserFreqIndexTmp];
          }
          if (currentbutton == Bfiltup) {
            SmoothFilterValTmp++;  
            SmoothFilterVal = constrain(SmoothFilterValTmp, SmoothFilterValMin, SmoothFilterValMax);
          }
          if (currentbutton == Bfiltdown) {
            SmoothFilterValTmp--;  
            SmoothFilterVal = constrain(SmoothFilterValTmp, SmoothFilterValMin, SmoothFilterValMax);
          }
          if (currentbutton == Bdownsampleup) {
            DownSampleCountTmp++;  
            DownSampleCountTmp = constrain(DownSampleCountTmp, DownSampleCountMin, DownSampleCountMax);
          }
          if (currentbutton == Bdownsampledown) {
            DownSampleCountTmp--;  
            DownSampleCountTmp = constrain(DownSampleCountTmp, DownSampleCountMin, DownSampleCountMax);
          }
          if (currentbutton == Btimeradjustup) {
            Timer0AdjustValTmp++;  
            Timer0AdjustValTmp = constrain(Timer0AdjustValTmp, Timer0AdjustValMin, Timer0AdjustValMax);
          }
          if (currentbutton == Btimeradjustdown) {
            Timer0AdjustValTmp--;  
            Timer0AdjustValTmp = constrain(Timer0AdjustValTmp, Timer0AdjustValMin, Timer0AdjustValMax);
          }
          if (currentbutton == Bprescalerup) {
            PrescalerTmp++;
            if (PrescalerTmp > PrescalerMax) PrescalerTmp = PrescalerMax;
          }
          if (currentbutton == Bprescalerdown) {
            PrescalerTmp--;
            if (PrescalerTmp < PrescalerMin) PrescalerTmp = PrescalerMin;
          }
          if (currentbutton == Brecordtimeup) {
            DataRecordTimeTmp++;
            if (DataRecordTimeTmp > DataRecordTimeMax) DataRecordTimeTmp = DataRecordTimeMax;
          }
          if (currentbutton == Brecordtimedown) {
            DataRecordTimeTmp--;
            if (DataRecordTimeTmp < DataRecordTimeMin) DataRecordTimeTmp = DataRecordTimeMin;
          }
          if (currentbutton == B1chan) {
            SignalNumberTmp = 1;
            buttons[B1chan].BOn = false;
            buttons[B2chan].BOn = false;
            buttons[B4chan].BOn = false;
            buttons[B8chan].BOn = false;
            buttons[currentbutton].BOn = true;
          }
          if (currentbutton == B2chan) {
            SignalNumberTmp = 2;
            buttons[B1chan].BOn = false;
            buttons[B2chan].BOn = false;
            buttons[B4chan].BOn = false;
            buttons[B8chan].BOn = false;
            buttons[currentbutton].BOn = true;
          }
          if (currentbutton == B4chan) {
            SignalNumberTmp = 4;
            buttons[B1chan].BOn = false;
            buttons[B2chan].BOn = false;
            buttons[B4chan].BOn = false;
            buttons[B8chan].BOn = false;
            buttons[currentbutton].BOn = true;
          }
          if (currentbutton == B8chan) {
            SignalNumberTmp = 8;
            buttons[B1chan].BOn = false;
            buttons[B2chan].BOn = false;
            buttons[B4chan].BOn = false;
            buttons[B8chan].BOn = false;
            buttons[currentbutton].BOn = true;
          }
          if (currentbutton == Bsave) {
            println("Got the save 's'");
            saveSettings();
            changePage(oldpage);
            buttons[currentbutton].BOn = false;
            return outflag;
          }
          if (currentbutton == Bcancel) {
            changePage(oldpage);
            EstablishDataLink();
            buttons[currentbutton].BOn = false;
            return outflag;
          }
          if (currentbutton == Bdefaults) {
            restoreDefaults();
          }
          drawSettings();
        }
      }
    }
    return outflag;
  }

  void useSerialEvent() {
  }

  void drawHelp() {
    // help text
  }

  void restoreDefaults() {
  }

  void waitForFolder() {
    tmpfolder = null;
    selectFolder("Select a folder to process:", "folderSelected");
    while (tmpfolder == null) delay(200);

    // labelaxes();
    // for (String csv: filenames = folder.list(csvFilter)) println(csv);
  }

  void folderSelected(File selection) {
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

  void drawSettings() {
    textAlign(CENTER, CENTER);
    blankplot();
    stroke(labelcolor);
    strokeWeight(4);
    fill(backgroundcolor);
    rectMode(CENTER);
    rect(width/2, height/2, FullPlotWidth+20, plotheight+40, 12);

    strokeWeight(2);
    textSize(labelsizexs);
    textAlign(CENTER, CENTER);

    stroke(labelcolor);
    fill(backgroundcolor);
    rect(width/2-90, height/2-90, 300, Bheights);
    if (int(textWidth(folderTmp)) < 300) {
      fill(labelcolor);
      text(folderTmp, width/2-90, height/2-90);
    }
    else if (textWidth(folderTmp) >= 450) {
      rect(width/2-90, height/2-70, 300, Bheights);
      fill(labelcolor);
      text(folderTmp, width/2-90, height/2-80, 300, Bheights*2);
    }

    textSize(titlesize);
    text("FlexVolt Settings Menu", width/2, height/2-plotheight/2);

    textSize(labelsizes);
    text("Saving Data & Images", width/2, height/2-115);
    textSize(labelsizexs);
    text("Save Directory", width/2-200, height/2-130);

    text("Data Recording Time (s)", width/2+170, height/2-95);
    text(str(DataRecordTimeTmp), width/2+170, height/2-70);

    textSize(labelsizes);
    text("Data Sampling Settings", width/2, height/2-40);
    textSize(labelsizexs);
    text("Frequency, Hz", width/2-195, height/2-15);
    text(str(UserFrequencyTmp), width/2-195, height/2+10);

    text("Number of Channels", width/2-50, height/2-15); // reserved for future use

    text("Smooth Filter", width/2+90, height/2-15);
    text(str(SmoothFilterValTmp), width/2+90, height/2+10);

    text("Downsample", width/2+200, height/2-15);
    text(str(DownSampleCountTmp), width/2+200, height/2+10);

    textSize(labelsizes);
    text("Timing Settings (Advanced)", width/2, height/2+40);
    textSize(labelsizexs);
    text("Timer Adjust", width/2-100, height/2+60);
    text(str(Timer0AdjustValTmp), width/2-100, height/2+80);

    text("Prescaler", width/2+30, height/2+60);
    text(str(PrescalerTmp), width/2+30, height/2+80);


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
  int ButtonNum = 0;
  int
    Boffset = ButtonNum++, 
  Bpause = ButtonNum++, 
  Bsmooth = ButtonNum++, 
  Bclear = ButtonNum++, 
  Bchan1 = ButtonNum++, 
  Bchan2 = ButtonNum++, 
  Bchan3 = ButtonNum++, 
  Bchan4 = ButtonNum++, 
  Bchan5 = ButtonNum++, 
  Bchan6 = ButtonNum++, 
  Bchan7 = ButtonNum++, 
  Bchan8 = ButtonNum++,
  Bdomain = ButtonNum++;

  String pageName = "Muscle Voltage";
  int xPos = 0;
  int[] OffSet2 = {    
    +plotheight*3/4, +plotheight*1/4
  };
  int[] OffSet8 = {    
    +plotheight*7/8, +plotheight*5/8, +plotheight*3/8, +plotheight*1/8, +plotheight*7/8, +plotheight*5/8, +plotheight*3/8, +plotheight*1/8
  };
  int[] OffSet4 = {    
    +plotheight*7/8, +plotheight*5/8, +plotheight*3/8, +plotheight*1/8
  };
  
  float FreqMax = 500;//Hz for fft dilay window
  float FreqAmpMin = 0;
  float FreqAmpMax = 1;
  int FFTscale = 80; // multiplying fft amplitude
  //  int FreqFactor = FullPlotWidth/250;
  int FFTstep = 2;
  float FreqFactor = (float)plotwidth/FrequencyMax;

  boolean ButtonPressedFlag = false;
  boolean flagTimeDomain = true;
  boolean flagFreqDomain = false;
  
  String domainStr;

  // constructor
  TimeDomainPlotPage() {
    // set input variables
    domainStr = "Switch to Frequency";
    initializeButtons();
  }

  void initializeButtons() {
    buttons = new GuiButton[ButtonNum];
    int buttony = yTitle+195;
    int controlsy = yTitle+30;

    buttons[Boffset] =new GuiButton("OffSet", 'o', dummypage, xStep+plotwidth+45, controlsy+70, 60, Bheight, color(BIdleColor), color(0), "OffSet", Bonoff, false);
    buttons[Bpause] = new GuiButton("Pause",  'p', dummypage, xStep+plotwidth+45, controlsy+10, 60, Bheight, color(BIdleColor), color(0), "Pause", Bonoff, false);
    buttons[Bsmooth] =new GuiButton("Smooth", 'f', dummypage, xStep+plotwidth+45, controlsy+100, 60, Bheight, color(BIdleColor), color(0), "Filter", Bonoff, false);
    buttons[Bclear] = new GuiButton("Clear",  'c', dummypage, xStep+plotwidth+45, controlsy+40, 60, Bheight, color(BIdleColor), color(0), "Clear", Bmomentary, false);
    buttons[Bchan1] = new GuiButton("Chan1",  '1', dummypage, xStep+plotwidth+25, buttony, 30, Bheight, color(BIdleColor), Sig1Color, "1", Bonoff, true);
    buttons[Bchan2] = new GuiButton("Chan2",  '2', dummypage, xStep+plotwidth+25, buttony+30, 30, Bheight, color(BIdleColor), Sig2Color, "2", Bonoff, true);
    buttons[Bchan3] = new GuiButton("Chan3",  '3', dummypage, xStep+plotwidth+25, buttony+60, 30, Bheight, color(BIdleColor), Sig3Color, "3", Bonoff, true);
    buttons[Bchan4] = new GuiButton("Chan4",  '4', dummypage, xStep+plotwidth+25, buttony+90, 30, Bheight, color(BIdleColor), Sig4Color, "4", Bonoff, true);
    buttons[Bchan5] = new GuiButton("Chan5",  '5', dummypage, xStep+plotwidth+65, buttony, 30, Bheight, color(BIdleColor), Sig5Color, "5", Bonoff, false);
    buttons[Bchan6] = new GuiButton("Chan6",  '6', dummypage, xStep+plotwidth+65, buttony+30, 30, Bheight, color(BIdleColor), Sig6Color, "6", Bonoff, false);
    buttons[Bchan7] = new GuiButton("Chan7",  '7', dummypage, xStep+plotwidth+65, buttony+60, 30, Bheight, color(BIdleColor), Sig7Color, "7", Bonoff, false);
    buttons[Bchan8] = new GuiButton("Chan8",  '8', dummypage, xStep+plotwidth+65, buttony+90, 30, Bheight, color(BIdleColor), Sig8Color, "8", Bonoff, false);
    buttons[Bdomain]= new GuiButton("Domain", 'd', dummypage, xStep+80, yTitle+plotheight+30, 160, 18, color(BIdleColor), color(0), domainStr, Bmomentary, false);

    if (flagTimeDomain){
      OffSet2[0] = plotheight*3/4;
      OffSet2[1] = plotheight*1/4;
  
      OffSet4[0] = plotheight*7/8;
      OffSet4[1] = plotheight*5/8;
      OffSet4[2] = plotheight*3/8;
      OffSet4[3] = plotheight*1/8;
  
      OffSet8[0] = plotheight*7/8;
      OffSet8[1] = plotheight*5/8;
      OffSet8[2] = plotheight*3/8;
      OffSet8[3] = plotheight*1/8;
      OffSet8[4] = plotheight*7/8;
      OffSet8[5] = plotheight*5/8;
      OffSet8[6] = plotheight*3/8;
      OffSet8[7] = plotheight*1/8;
    } else if(flagFreqDomain){
      OffSet2[0] = 0;
      OffSet2[1] = plotheight/2;
  
      OffSet4[0] = 0;
      OffSet4[1] = plotheight/4;
      OffSet4[2] = plotheight/2;
      OffSet4[3] = plotheight*3/4;
  
      OffSet8[0] = 0;
      OffSet8[1] = plotheight/8;
      OffSet8[2] = plotheight/4;
      OffSet8[3] = plotheight*3/8;
      OffSet8[4] = plotheight/2;
      OffSet8[5] = plotheight*5/8;
      OffSet8[6] = plotheight*3/4;
      OffSet8[7] = plotheight*7/8;
      
      FreqFactor = (float)plotwidth/FrequencyMax;
    }
  }

  void switchToPage() {
    //    SmoothFilterFlag = false; //todo make this stay as it was for this page
    //    OffSetFlag = false;
    //PauseFlag = false;
    for (int i = 0; i < MaxSignalNumber; i++) {
      buttons[Bchan1+i].BOn = ChannelOn[i];
    }
    buttons[Boffset].BOn = OffSetFlag;
    buttons[Bsmooth].BOn = SmoothFilterFlag;
    buttons[Bpause].BOn = PauseFlag;

    datacounter = 0;
    plotwidth = FullPlotWidth;
    xPos = 0;
    //    background(backgroundcolor);
    labelAxes();
    blankplot();
    println("TimeDomain");
  }

  void drawPage() {
    // draw subfunctions
    if (ButtonPressedFlag) {
      if (millis() > ButtonColorTimer) {
        ButtonPressedFlag = false;
        println("Current Button = " + currentbutton);
        if (buttons[currentbutton] != null && currentbutton < buttons.length) {
          buttons[currentbutton].ChangeColorUnpressed();
        }
      }
    }

    if (!(xPos == plotwidth && PauseFlag)) {
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

  String getPageName() {
    return pageName;
  }
  
  void labelAxes(){
    if(flagTimeDomain){
      labelAxesTime();
    }
    else if(flagFreqDomain){
      labelAxesFFT();
    }
  }

  void labelAxesTime() {
    fill(labelcolor);
    stroke(labelcolor);
    strokeWeight(2);
    textAlign(CENTER, CENTER);

    // title
    textSize(titlesize);
    text("Muscle Voltage", xStep+FullPlotWidth/2+20, yTitle-45);

    textSize(axisnumbersize);
    // x-axis
    float val = 0;
    for (int i = 0; i < Nxticks+1; i++) {
      text(nf(val, 1, 0), xStep+int(map(val, 0, TimeMax, 0, plotwidth-10)), height-yStep+10);
      val += TimeMax/Nxticks;
    }

    // y-axis
    if (!OffSetFlag) {
      val = VoltageMin;
      for (int i = 0; i < Nyticks+1; i++) {
        if (val > 0) {
          text(("+"+nf(val, 1, 0)), xStep-20, ytmp -5 - int(map(val, VoltageMin, VoltageMax, 0, plotheight-10)));
        } 
        else {
          text(nf(val, 1, 0), xStep-20, ytmp -5 - int(map(val, VoltageMin, VoltageMax, 0, plotheight-10)));
        }
        val += (VoltageMax-VoltageMin)/Nyticks;
      }
    }
    else if (OffSetFlag) {
      val = VoltageMin/2;
      // val = VoltageMin;
      int xtmp = 0;
      for (int i = 0; i < NyticksHalf+1; i++) {
        xtmp = xStep-20;
        if (val > 0) {
          text(("+"+nf(val, 1, 0)), xtmp, ytmp - int(map(val, VoltageMin, VoltageMax, 0, plotheight/4)));
          text(("+"+nf(val, 1, 0)), xtmp, ytmp - int(map(val, VoltageMin, VoltageMax, plotheight/4, plotheight/2)));
          text(("+"+nf(val, 1, 0)), xtmp, ytmp - int(map(val, VoltageMin, VoltageMax, plotheight/2, plotheight*3/4)));
          text(("+"+nf(val, 1, 0)), xtmp, ytmp - int(map(val, VoltageMin, VoltageMax, plotheight*3/4, plotheight)));
        } 
        else {
          text(nf(val, 1, 0), xtmp, ytmp - int(map(val, VoltageMin, VoltageMax, 0, plotheight/4)));
          text(nf(val, 1, 0), xtmp, ytmp - int(map(val, VoltageMin, VoltageMax, plotheight/4, plotheight/2)));
          text(nf(val, 1, 0), xtmp, ytmp - int(map(val, VoltageMin, VoltageMax, plotheight/2, plotheight*3/4)));
          text(nf(val, 1, 0), xtmp, ytmp - int(map(val, VoltageMin, VoltageMax, plotheight*3/4, plotheight)));
        }
        val += ((VoltageMax/2)-(VoltageMin/2))/NyticksHalf;
        // val += ((VoltageMax)-(VoltageMin))/Nyticks;
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
    text("Channel", xStep+FullPlotWidth+45, yTitle+165);
    text("Plotting", xStep+FullPlotWidth+45, yTitle+10);

    for (int i = 0; i < buttons.length; i++) {
      buttons[i].drawButton();
    }
  }
  
  void labelAxesFFT() {
    fill(labelcolor);
    stroke(labelcolor);
    strokeWeight(2);
    textAlign(CENTER, CENTER);

    // title
    textSize(titlesize);
    text("Signal Frequency", xStep+FullPlotWidth/2+20, yTitle-45);

    // x-axis
    textSize(axisnumbersize);
    float val = 0;
    //    println("MSL = "+MaxSignalLength+", plotwidth = "+plotwidth+", freqfac = "+FreqFactor);
    //    float tmp = (float)MaxSignalLength/plotwidth;
    //    tmp = max(tmp,1);
    //    FreqMax = (int)(float(UserFrequency)/(tmp)/float(FreqFactor));
    //    println("fm = "+FreqMax);
    for (int i = 0; i < Nxticks+1; i++) {
      text(nf(val, 1, 0), xStep+int(map(val, 0, FrequencyMax, 0, plotwidth)), height-yStep+10);
      val += FrequencyMax/Nxticks;
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
    text("Channel", xStep+FullPlotWidth+45, yTitle+165);
    text("Plotting", xStep+FullPlotWidth+45, yTitle+10);
    textSize(labelsizes);

    for (int i = 0; i < buttons.length; i++) {
      buttons[i].drawButton();
    }
  }

  boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
    boolean outflag = false;
    currentbutton = -1;
    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        if ( (inputDev == mouseInput && buttons[i].IsMouseOver(x, y)) || (inputDev == keyInput && tkey == buttons[i].hotKey) ) {
          outflag = true;
          buttons[i].BOn = !buttons[i].BOn;
          buttons[i].ChangeColorPressed();
          ButtonColorTimer = millis()+ButtonColorDelay;
          ButtonPressedFlag = true;
          currentbutton = i;

          if (currentbutton == Bdomain){
            if (flagTimeDomain){
              flagTimeDomain = false;
              flagFreqDomain = true;
              domainStr = "Switch to Time";
              buttons[i].label = "Switch to Time";
              buttons[i].ChangeColorUnpressed();
              ButtonPressedFlag = false;
              background(backgroundcolor);
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
              buttons[i].ChangeColorUnpressed();
              ButtonPressedFlag = false;
              background(backgroundcolor);
              labelGUI();
              initializeButtons();
              switchToPage();
              return outflag;
            }
          }
          if (currentbutton == Boffset) {
            OffSetFlag = !OffSetFlag;
            ClearYAxis();
          }
          if (currentbutton == Bsmooth) {
            SmoothFilterFlag = !SmoothFilterFlag;
            if (SmoothFilterFlag) {
              DownSampleCount = 10;
              BitDepth10 = false;
            }
            else {
              DownSampleCount = 1;
              BitDepth10 = true;
            }
            UpdateSettings();
          }
          if (currentbutton == Bclear) {
            datacounter = 0;
            xPos = 0;
            blankplot();
          }
          if (currentbutton == Bpause) {
            PauseFlag = !PauseFlag;
            if (!PauseFlag) {
              buttons[currentbutton].label = "Pause";
              datacounter = 0;
              xPos = 0;
            }
            else if (PauseFlag) {
              buttons[currentbutton].label = "Play";
            }
          }
          if (currentbutton == Bchan1) {
            ChannelOn[0] = !ChannelOn[0];
          }
          if (currentbutton == Bchan2) {
            ChannelOn[1] = !ChannelOn[1];
          }
          if (currentbutton == Bchan3) {
            ChannelOn[2] = !ChannelOn[2];
          }
          if (currentbutton == Bchan4) {
            ChannelOn[3] = !ChannelOn[3];
          }
          if (currentbutton == Bchan5) {
            ChannelOn[4] = !ChannelOn[4];
          }
          if (currentbutton == Bchan6) {
            ChannelOn[5] = !ChannelOn[5];
          }
          if (currentbutton == Bchan7) {
            ChannelOn[6] = !ChannelOn[6];
          }
          if (currentbutton == Bchan8) {
            ChannelOn[7] = !ChannelOn[7];
          }

          labelAxes();
        }
      }
    }
    return outflag;
  }

  void useSerialEvent() {
  }

  void drawHelp() {
    // help text
  }

  void drawTrace() {
    int sigtmp = 0;
    loadPixels();
    while (datacounter > 1) {
      xPos++;//=DownSampleCount;
      if (xPos >= plotwidth && !PauseFlag) {
        xPos = -1;
        updatePixels();
        return;
      }
      else if (xPos >= plotwidth && PauseFlag) {
        xPos = plotwidth-1;
        updatePixels();
        return;
      }
      else if (xPos == 0) {
        updatePixels();
        blankplot();
        return;
      }

      for (int j = 0; j < SignalNumber;j++) {
        if (ChannelOn[j]) {
          int tmpind = signalindex-datacounter;//*DownSampleCount;
          while (tmpind < 0) {
            tmpind+=MaxSignalLength;
          }
          if (!OffSetFlag) {
            sigtmp = int(map((signalIn[j][tmpind]+Calibration[j]-HalfSignalVal)*VoltScale, -MaxSignalVal, +MaxSignalVal, 0, plotheight));
          }
          else {
            if (ChannelOn[4] || ChannelOn[5] || ChannelOn[6] || ChannelOn[7]) {
              sigtmp = OffSet8[j]+int(map((signalIn[j][tmpind]+Calibration[j]-HalfSignalVal)*VoltScale, -MaxSignalVal, +MaxSignalVal, -plotheight/(2*SignalNumber), plotheight/(2*SignalNumber)));
            } 
            else if (ChannelOn[3] || ChannelOn[2]) {
              sigtmp = OffSet4[j]+int(map((signalIn[j][tmpind]+Calibration[j]-HalfSignalVal)*VoltScale, -MaxSignalVal, +MaxSignalVal, -plotheight/(2*SignalNumber), plotheight/(2*SignalNumber)));
            } 
            else if (ChannelOn[1]) {
              sigtmp = OffSet2[j]+int(map((signalIn[j][tmpind]+Calibration[j]-HalfSignalVal)*VoltScale, -MaxSignalVal, +MaxSignalVal, -plotheight/(2*SignalNumber), plotheight/(2*SignalNumber)));
            }
          }
          sigtmp = constrain( sigtmp, pointThickness, plotheight - pointThickness);
          drawMyLine(xPos+xStep-1, ytmp - oldPlotSignal[j], xPos+xStep, ytmp - sigtmp, SigColorM[j], pointThickness);
          oldPlotSignal[j] = sigtmp;
        }
      }
      datacounter --;
    }
    updatePixels();
  }
  
  void drawFFT() {
    blankplot();
    stroke(FFTcolor);
    // filtered=filter1.apply(signalIn);
    // filtered = signalIn1;

    for (int j = 0; j < SignalNumber; j++) {
      System.arraycopy(fft.computeFFT(FFTsignalIn[j]), 0, fft_result[j], 0, FFTSignalLength/2);
    }

    for (int i = 2; i<min(fft.WS2,FrequencyMax); i++) {
      int xtmp = xStep+int(FreqFactor*float(i-1));
      for (int j = 0; j < SignalNumber;j++) {
        if (ChannelOn[j]) {
          stroke(SigColorM[j]);
          if (OffSetFlag) {
            if (ChannelOn[4] || ChannelOn[5] || ChannelOn[6] || ChannelOn[7]) {
              for (int k = 0; k < FreqFactor; k++) {
                line(xtmp+k, ytmp - FFTstep - OffSet8[j], xtmp+k, min(ytmp-FFTstep-OffSet8[j], max(yTitle+2+OffSet8[7-j], ytmp - OffSet8[j] - int(FFTscale*fft_result[j][i])/8)) );
              }
            }
            else if (ChannelOn[3] || ChannelOn[2]) {
              for (int k = 0; k < FreqFactor; k++) {
                line(xtmp+k, ytmp - FFTstep - OffSet4[j], xtmp+k, min(ytmp-FFTstep-OffSet4[j], max(yTitle+2+OffSet4[3-j], ytmp - OffSet4[j] - int(FFTscale*fft_result[j][i])/4)) );
              }
            }
            else {
              for (int k = 0; k < FreqFactor; k++) {
                line(xtmp+k, ytmp - FFTstep - OffSet2[j], xtmp+k, min(ytmp-FFTstep-OffSet2[j], max(yTitle+2+OffSet2[1-j], ytmp - OffSet2[j] - int(FFTscale*fft_result[j][i])/2)) );
              }
            }
          }
          else {
            line(xtmp, ytmp - FFTstep, xtmp, min(ytmp-FFTstep, max(yTitle+2, ytmp - int(FFTscale*fft_result[j][i]))) );
          }
        }
      }
    }
  }
}
/************************* END TimeDomainPlot PAGE ***********************/



/************************* BEGIN WORKOUT PAGE ***********************/
public class WorkoutPage implements pagesClass {
  // variables
  GuiButton[] buttons;
  int ButtonNum = 0;
  int
    Breset = ButtonNum++, 
  BsetReps1 = ButtonNum++, 
  BsetReps2 = ButtonNum++, 
  Bthresh1up = ButtonNum++, 
  Bthresh1down = ButtonNum++, 
  Bthresh2up = ButtonNum++, 
  Bthresh2down = ButtonNum++, 
  Bchan1 = ButtonNum++, 
  Bchan2 = ButtonNum++, 
  Bchan1up = ButtonNum++, 
  Bchan2up = ButtonNum++, 
  Bchan1down = ButtonNum++, 
  Bchan2down = ButtonNum++, 
  Bchan1name = ButtonNum++, 
  Bchan2name = ButtonNum++;


  // Workout
  int Reps = 0, Work = 1;
  int BTWorkoutType = Reps;
  int RepsTargetDefault = 10;
  int RepsTarget[] = {     
    RepsTargetDefault, RepsTargetDefault
  };
  int RepThreshDefault = 64;
  int RepThresh[] = {    
    RepThreshDefault, RepThreshDefault
  };
  int RepThreshStep = 10;
  int RepsCounter[] = {     
    0, 0
  };
  int FlexOnCounter[] = {     
    0, 0
  };
  boolean ChanFlexed[] = {     
    false, false
  };
  int TRepCounter = 0, TDataLogger = 1;
  int TrainingMode = TRepCounter;
  int DataThresh[] = {    
    545, 545
  };
  int[][] TMax;
  int TrainChan[] = {    
    0, 1
  };

  String pageName = "FlexVolt Training";
  String typing = "";
  String savedname = "";
  boolean NamesFlag = false;
  int NameNumber = 0;
  int RepBarWidth = 30;
  int xPos = 0;
  boolean ButtonPressedFlag = false;

  // constructor
  WorkoutPage() {
    // set input variables
    initializeButtons();
  }

  void initializeButtons() {
    buttons = new GuiButton[ButtonNum];
    buttons[Breset]       = new GuiButton("Reset", ' ', dummypage, xStep+HalfPlotWidth+65, yTitle+plotheight/2+5, 120, Bheights, color(BIdleColor), color(0), "Reset Workout", Bmomentary, false);
    buttons[BsetReps1]    = new GuiButton("SetReps1", ' ', dummypage, xStep+HalfPlotWidth+30, yTitle+70, 50, Bheights, color(BIdleColor), color(0), str(RepsTarget[0]), Bonoff, false);
    buttons[BsetReps2]    = new GuiButton("SetReps2", ' ', dummypage, xStep+HalfPlotWidth+30, yTitle+plotheight/2+90, 50, Bheights, color(BIdleColor), color(0), str(RepsTarget[1]), Bonoff, false);
    buttons[Bthresh1up]   = new GuiButton("repthresh1up", ' ', dummypage, xStep+HalfPlotWidth+20, yTitle+plotheight/2-50, 30, Bheights, color(BIdleColor), color(0), "up", Bmomentary, false);
    buttons[Bthresh1down] = new GuiButton("repthresh1dn", ' ', dummypage, xStep+HalfPlotWidth+20, yTitle+plotheight/2-26, 30, Bheights, color(BIdleColor), color(0), "dn", Bmomentary, false);
    buttons[Bthresh2up]   = new GuiButton("repthresh2up", ' ', dummypage, xStep+HalfPlotWidth+20, yTitle+plotheight-29, 30, Bheights, color(BIdleColor), color(0), "up", Bmomentary, false);
    buttons[Bthresh2down] = new GuiButton("repthresh2dn", ' ', dummypage, xStep+HalfPlotWidth+20, yTitle+plotheight-5, 30, Bheights, color(BIdleColor), color(0), "dn", Bmomentary, false);
    buttons[Bchan1]       = new GuiButton("Chan1", ' ', dummypage, xStep+HalfPlotWidth+65, yTitle+40, 30, Bheights, color(BIdleColor), SigColorM[TrainChan[0]], str(TrainChan[0]+1), Bonoff, true);
    buttons[Bchan1name]   = new GuiButton("Name1", ' ', dummypage, xStep+HalfPlotWidth+65, yTitle+15, 120, Bheights, color(BIdleColor), color(0), "name1", Bonoff, false);
    buttons[Bchan1up]     = new GuiButton("Ch1up", ' ', dummypage, xStep+HalfPlotWidth+105, yTitle+40, Bheights, Bheights, color(BIdleColor), color(0), ">", Bmomentary, false);
    buttons[Bchan1down]   = new GuiButton("Ch1dn", ' ', dummypage, xStep+HalfPlotWidth+25, yTitle+40, Bheights, Bheights, color(BIdleColor), color(0), "<", Bmomentary, false);
    buttons[Bchan2]       = new GuiButton("Chan2", ' ', dummypage, xStep+HalfPlotWidth+65, yTitle+plotheight/2+60, 30, Bheights, color(BIdleColor), SigColorM[TrainChan[1]], str(TrainChan[1]+1), Bonoff, false);
    buttons[Bchan2name]   = new GuiButton("Name2", ' ', dummypage, xStep+HalfPlotWidth+65, yTitle+plotheight/2+35, 120, Bheights, color(BIdleColor), color(0), "name2", Bonoff, false);
    buttons[Bchan2up]     = new GuiButton("Ch2up", ' ', dummypage, xStep+HalfPlotWidth+105, yTitle+plotheight/2+60, Bheights, Bheights, color(BIdleColor), color(0), ">", Bmomentary, false);
    buttons[Bchan2down]   = new GuiButton("Ch2dn", ' ', dummypage, xStep+HalfPlotWidth+25, yTitle+plotheight/2+60, Bheights, Bheights, color(BIdleColor), color(0), "<", Bmomentary, false);
  }

  void switchToPage() {

    DownSampleCount = DownSampleCountTraining; //!!!!!!!!!!!!!!!
    UserFreqIndex = UserFreqIndexTraining;
    UserFrequency = UserFreqArray[UserFreqIndex];
    CheckSerialDelay = (long)max( CheckSerialMinTime, 1000.0/((float)UserFrequency/CheckSerialNSamples) );
    SmoothFilterFlag = true;
    BitDepth10 = false;
    OffSetFlag = true;
    PauseFlag = false;
    ChannelOn[TrainChan[0]] = true;
    ChannelOn[TrainChan[1]] = true;
    buttons[Bchan1].BOn = ChannelOn[TrainChan[0]];
    buttons[Bchan2].BOn = ChannelOn[TrainChan[1]];
    plotwidth = HalfPlotWidth;
    //    background(backgroundcolor);
    labelaxes();
    blankplot();
    UpdateSettings();
    println("Workout Turned ON");
  }

  void drawPage() {
    if (ButtonPressedFlag) {
      if (millis() > ButtonColorTimer) {
        ButtonPressedFlag = false;
        println("Current Button = " + currentbutton);
        if (buttons[currentbutton] != null && currentbutton < buttons.length) {
          buttons[currentbutton].ChangeColorUnpressed();
        }
      }
    }

    drawTrace();
    drawThresh();
    if (TrainingMode == TRepCounter) {
      CountReps();
      drawRepBar();
    }
  }

  String getPageName() {
    return pageName;
  }

  void labelaxes() {
    fill(labelcolor);
    stroke(labelcolor);
    strokeWeight(2);
    textAlign(CENTER, CENTER);

    // title
    textSize(titlesize);
    text("Flex Training", xStep+FullPlotWidth/2+20, yTitle-45);

    // y-axis
    float val = 0;
    textSize(20);
    for (int i = 0; i < NyticksHalf+1; i++) {
      text(nf(val, 1, 0), xStep-25, ytmp - int(map(val, 0, VoltageMax, 0, plotheight/2-20)));
      text(nf(val, 1, 0), xStep-25, ytmp - int(map(val, 0, VoltageMax, 0, plotheight/2-10)) - plotheight/2 - 10);
      val += (VoltageMax)/NyticksHalf;
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
    fill(labelcolor);
    text("Set Reps", xStep+plotwidth+100, yTitle+70);
    text("Set Reps", xStep+plotwidth+100, yTitle+plotheight/2+90);
    text("Threshold", xStep+plotwidth+90, yTitle+plotheight/2-40);
    text("Threshold", xStep+plotwidth+90, yTitle+plotheight-20);

    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        buttons[i].drawButton();
      }
    }

    LabelRepBar(3);
  }

  boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
    boolean outflag = false;

    if (NamesFlag) {
      if (key == '\n' ) {
        println("here");
        println(typing);
        int tmpint = 0;
        savedname = typing;
        if (NameNumber == BsetReps1 || NameNumber == BsetReps2) {
          tmpint = getIntFromString(typing, RepsTargetDefault);
          savedname = str(tmpint);
        }
        buttons[NameNumber].label = savedname;
        if (NameNumber == BsetReps1) {
          RepsTarget[0] = tmpint;
          ClearRepBar(1);
          LabelRepBar(1);
        }
        else if (NameNumber == BsetReps2) {
          RepsTarget[1] = tmpint;
          ClearRepBar(2);
          LabelRepBar(2);
        }
        NamesFlag = !NamesFlag;
        buttons[currentbutton].BOn = !buttons[currentbutton].BOn;
        buttons[NameNumber].drawButton();
        typing = "";
        NameNumber = -1;
        outflag = true;
      }
      else if ((key >= 'a' && key <= 'z') || (key >= 'A' && key <= 'Z') || (key == ' ') || (key >='0' && key <= '9')) {
        // Otherwise, concatenate the String - Each character typed by the user is added to the end of the String variable.
        typing = typing + key;
        buttons[NameNumber].label = typing;
        buttons[NameNumber].drawButton();
        outflag = true;
      }
    }
    else if (!NamesFlag) {
      currentbutton = -1;
      for (int i = 0; i < buttons.length; i++) {
        if (buttons[i] != null) {
          if ( (inputDev == mouseInput && buttons[i].IsMouseOver(x, y)) || (inputDev == keyInput && tkey == buttons[i].hotKey) ) {
            outflag = true;
            buttons[i].BOn = !buttons[i].BOn;
            buttons[i].ChangeColorPressed();
            ButtonColorTimer = millis()+ButtonColorDelay;
            ButtonPressedFlag = true;
            currentbutton = i;

            if (currentbutton == Breset) {
              resetWorkout();
            }
            if (currentbutton == BsetReps1 || currentbutton == BsetReps2 || currentbutton == Bchan1name || currentbutton == Bchan2name) {
              if (NameNumber == currentbutton) {
                int tmpint = 0;
                savedname = typing;
                if (NameNumber == BsetReps1 || NameNumber == BsetReps2) {
                  tmpint = getIntFromString(typing, RepsTargetDefault);
                  savedname = str(tmpint);
                }
                println(tmpint);
                buttons[NameNumber].label = savedname;
                if (NameNumber == BsetReps1) {
                  RepsTarget[0] = tmpint;
                  println("int saved");
                  println(RepsTarget[0]);
                  ClearRepBar(1);
                  LabelRepBar(1);
                }
                else if (NameNumber == BsetReps2) {
                  RepsTarget[1] = tmpint;
                  println("int saved");
                  println(RepsTarget[0]);
                  ClearRepBar(2);
                  LabelRepBar(2);
                }

                NamesFlag = !NamesFlag;
                //buttons[currentbutton].BOn = !buttons[currentbutton].BOn;

                buttons[NameNumber].drawButton();
                typing = "";
                NameNumber = -1;
              }
              else {
                NameNumber = currentbutton;
                NamesFlag = true;
                buttons[currentbutton].BOn = true;
                typing = "";
                buttons[NameNumber].label = typing;
                buttons[NameNumber].drawButton();
              }
              println("Names Toggled");
            }
            if (currentbutton == Bchan1) {
              ChannelOn[0] = !ChannelOn[0];
              println("Chan1 Toggled");
            }
            if (currentbutton == Bchan2) {
              ChannelOn[1] = !ChannelOn[1];
              println("Chan2 Toggled");
            }
            if (currentbutton == Bchan1up) {
              TrainChan[0]++;
              if (TrainChan[0]>=SignalNumber) {
                TrainChan[0]=SignalNumber-1;
              }
              if (TrainChan[0] == TrainChan[1]) {
                TrainChan[0]++;
                if (TrainChan[0]>=SignalNumber) {
                  TrainChan[0]=TrainChan[1]-1;
                }
              }
              buttons[Bchan1].ctext = SigColorM[TrainChan[0]];
              buttons[Bchan1].label = str(TrainChan[0]+1);
              buttons[Bchan1].drawButton();
              ChannelOn[TrainChan[0]] = buttons[Bchan1].BOn;
            }
            if (currentbutton == Bchan1down) {
              TrainChan[0]--;
              if (TrainChan[0]<0) {
                TrainChan[0]=0;
              }
              if (TrainChan[0] == TrainChan[1]) {
                TrainChan[0]--;
                if (TrainChan[0]<0) {
                  TrainChan[0]=TrainChan[1]+1;
                }
              }
              buttons[Bchan1].ctext = SigColorM[TrainChan[0]];
              buttons[Bchan1].label = str(TrainChan[0]+1);
              buttons[Bchan1].drawButton();
              ChannelOn[TrainChan[0]] = buttons[Bchan1].BOn;
            }
            if (currentbutton == Bchan2up) {
              TrainChan[1]++;
              if (TrainChan[1]>=SignalNumber) {
                TrainChan[1]=SignalNumber-1;
              }
              if (TrainChan[1] == TrainChan[0]) {
                TrainChan[1]++;
                if (TrainChan[1]>=SignalNumber) {
                  TrainChan[1]=TrainChan[0]-1;
                }
              }
              buttons[Bchan2].ctext = SigColorM[TrainChan[1]];
              buttons[Bchan2].label = str(TrainChan[1]+1);
              buttons[Bchan2].drawButton();
              ChannelOn[TrainChan[1]] = buttons[Bchan2].BOn;
            }
            if (currentbutton == Bchan2down) {
              TrainChan[1]--;
              if (TrainChan[1]<0) {
                TrainChan[1]=0;
              }
              if (TrainChan[1] == TrainChan[0]) {
                TrainChan[1]--;
                if (TrainChan[1]<0) {
                  TrainChan[1]=TrainChan[0]+1;
                }
              }
              buttons[Bchan2].ctext = SigColorM[TrainChan[1]];
              buttons[Bchan2].label = str(TrainChan[1]+1);
              buttons[Bchan2].drawButton();
              ChannelOn[TrainChan[1]] = buttons[Bchan2].BOn;
            }
            if (currentbutton == Bthresh1up) {
              RepThresh[0]+=RepThreshStep;
              if (RepThresh[0]>=MaxSignalVal) {
                RepThresh[0]=MaxSignalVal;
              }
            }
            if (currentbutton == Bthresh1down) {
              RepThresh[0]-=RepThreshStep;
              if (RepThresh[0]<0) {
                RepThresh[0]=0;
              }
            }
            if (currentbutton == Bthresh2up) {
              RepThresh[1]+=RepThreshStep;
              if (RepThresh[1]>=MaxSignalVal) {
                RepThresh[1]=MaxSignalVal;
              }
            }
            if (currentbutton == Bthresh2down) {
              RepThresh[1]-=RepThreshStep;
              if (RepThresh[1]<0) {
                RepThresh[1]=0;
              }
            }

            labelaxes();
          }
        }
      }
    }
    return outflag;
  }

  boolean useKeyPressed() {
    boolean outflag = false;
    if (NamesFlag) {
      if (key == '\n' ) {
        println("here");
        println(typing);
        int tmpint = 0;
        savedname = typing;
        if (NameNumber == BsetReps1 || NameNumber == BsetReps2) {
          tmpint = getIntFromString(typing, RepsTargetDefault);
          println(tmpint);
          savedname = str(tmpint);
        }
        buttons[NameNumber].label = savedname;
        if (NameNumber == BsetReps1) {
          RepsTarget[0] = tmpint;
          println("int saved");
          println(RepsTarget[0]);
          ClearRepBar(1);
          LabelRepBar(1);
        }
        else if (NameNumber == BsetReps2) {
          RepsTarget[1] = tmpint;
          println("int saved");
          println(RepsTarget[0]);
          ClearRepBar(2);
          LabelRepBar(2);
        }
        NamesFlag = !NamesFlag;
        buttons[currentbutton].BOn = !buttons[currentbutton].BOn;

        buttons[NameNumber].drawButton();
        typing = "";
        NameNumber = -1;
        outflag = true;
      }
      else if ((key >= 'a' && key <= 'z') || (key >= 'A' && key <= 'Z') || (key == ' ') || (key >='0' && key <= '9')) {
        // Otherwise, concatenate the String
        // Each character typed by the user is added to the end of the String variable.
        typing = typing + key;
        buttons[NameNumber].label = typing;
        buttons[NameNumber].drawButton();
        println("adjusting");
        outflag = true;
      }
    }
    return outflag;
  }

  void useSerialEvent() {
  }

  void useMousePressed() {
    currentbutton = -1;
    println("mouse pressed");
    int x = mouseX, y = mouseY;
    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        if (buttons[i].IsMouseOver(x, y)) {
          buttons[i].BOn = !buttons[i].BOn;
          buttons[i].ChangeColorPressed();
          currentbutton = i;
          ButtonColorTimer = millis()+ButtonColorDelay;
          ButtonPressedFlag = true;
        }
      }
    }
    if (currentbutton == Breset) {
      resetWorkout();
    }
    if (currentbutton == BsetReps1 || currentbutton == BsetReps2 || currentbutton == Bchan1name || currentbutton == Bchan2name) {
      if (NameNumber == currentbutton) {
        int tmpint = 0;
        savedname = typing;
        if (NameNumber == BsetReps1 || NameNumber == BsetReps2) {
          tmpint = getIntFromString(typing, RepsTargetDefault);
          savedname = str(tmpint);
        }
        println(tmpint);
        buttons[NameNumber].label = savedname;
        if (NameNumber == BsetReps1) {
          RepsTarget[0] = tmpint;
          println("int saved");
          println(RepsTarget[0]);
          ClearRepBar(1);
          LabelRepBar(1);
        }
        else if (NameNumber == BsetReps2) {
          RepsTarget[1] = tmpint;
          println("int saved");
          println(RepsTarget[0]);
          ClearRepBar(2);
          LabelRepBar(2);
        }

        NamesFlag = !NamesFlag;
        //buttons[currentbutton].BOn = !buttons[currentbutton].BOn;

        buttons[NameNumber].drawButton();
        typing = "";
        NameNumber = -1;
      }
      else {
        NameNumber = currentbutton;
        NamesFlag = true;
        buttons[currentbutton].BOn = true;
        typing = "";
        buttons[NameNumber].label = typing;
        buttons[NameNumber].drawButton();
      }
      println("Names Toggled");
    }
    if (currentbutton == Bchan1) {
      ChannelOn[0] = !ChannelOn[0];
      println("Chan1 Toggled");
    }
    if (currentbutton == Bchan2) {
      ChannelOn[1] = !ChannelOn[1];
      println("Chan2 Toggled");
    }
    if (currentbutton == Bchan1up) {
      TrainChan[0]++;
      if (TrainChan[0]>=SignalNumber) {
        TrainChan[0]=SignalNumber-1;
      }
      if (TrainChan[0] == TrainChan[1]) {
        TrainChan[0]++;
        if (TrainChan[0]>=SignalNumber) {
          TrainChan[0]=TrainChan[1]-1;
        }
      }
      buttons[Bchan1].ctext = SigColorM[TrainChan[0]];
      buttons[Bchan1].label = str(TrainChan[0]+1);
      buttons[Bchan1].drawButton();
      ChannelOn[TrainChan[0]] = buttons[Bchan1].BOn;
    }
    if (currentbutton == Bchan1down) {
      TrainChan[0]--;
      if (TrainChan[0]<0) {
        TrainChan[0]=0;
      }
      if (TrainChan[0] == TrainChan[1]) {
        TrainChan[0]--;
        if (TrainChan[0]<0) {
          TrainChan[0]=TrainChan[1]+1;
        }
      }
      buttons[Bchan1].ctext = SigColorM[TrainChan[0]];
      buttons[Bchan1].label = str(TrainChan[0]+1);
      buttons[Bchan1].drawButton();
      ChannelOn[TrainChan[0]] = buttons[Bchan1].BOn;
    }
    if (currentbutton == Bchan2up) {
      TrainChan[1]++;
      if (TrainChan[1]>=SignalNumber) {
        TrainChan[1]=SignalNumber-1;
      }
      if (TrainChan[1] == TrainChan[0]) {
        TrainChan[1]++;
        if (TrainChan[1]>=SignalNumber) {
          TrainChan[1]=TrainChan[0]-1;
        }
      }
      buttons[Bchan2].ctext = SigColorM[TrainChan[1]];
      buttons[Bchan2].label = str(TrainChan[1]+1);
      buttons[Bchan2].drawButton();
      ChannelOn[TrainChan[1]] = buttons[Bchan2].BOn;
    }
    if (currentbutton == Bchan2down) {
      TrainChan[1]--;
      if (TrainChan[1]<0) {
        TrainChan[1]=0;
      }
      if (TrainChan[1] == TrainChan[0]) {
        TrainChan[1]--;
        if (TrainChan[1]<0) {
          TrainChan[1]=TrainChan[0]+1;
        }
      }
      buttons[Bchan2].ctext = SigColorM[TrainChan[1]];
      buttons[Bchan2].label = str(TrainChan[1]+1);
      buttons[Bchan2].drawButton();
      ChannelOn[TrainChan[1]] = buttons[Bchan2].BOn;
    }
    if (currentbutton == Bthresh1up) {
      RepThresh[0]+=RepThreshStep;
      if (RepThresh[0]>=MaxSignalVal) {
        RepThresh[0]=MaxSignalVal;
      }
    }
    if (currentbutton == Bthresh1down) {
      RepThresh[0]-=RepThreshStep;
      if (RepThresh[0]<0) {
        RepThresh[0]=0;
      }
    }
    if (currentbutton == Bthresh2up) {
      RepThresh[1]+=RepThreshStep;
      if (RepThresh[1]>=MaxSignalVal) {
        RepThresh[1]=MaxSignalVal;
      }
    }
    if (currentbutton == Bthresh2down) {
      RepThresh[1]-=RepThreshStep;
      if (RepThresh[1]<0) {
        RepThresh[1]=0;
      }
    }
  }

  void drawHelp() {
  }

  void drawTrace() {
    int sigtmp = 0;
    loadPixels();
    while (datacounter > 1) {
      xPos++;//=DownSampleCount;
      if (xPos >= plotwidth && !PauseFlag) {
        xPos = -1;
        updatePixels();
        return;
      }
      else if (xPos >= plotwidth && PauseFlag) {
        xPos = plotwidth-1;
        updatePixels();
        return;
      }
      else if (xPos == 0) {
        updatePixels();
        blankplot();
        return;
      }

      for (int j = 0; j < SignalNumber;j++) {
        if (ChannelOn[j]) {
          if (j == TrainChan[0] || j == TrainChan[1]) {
            int tmpind = signalindex-datacounter;//*DownSampleCount;
            while (tmpind < 0) {
              tmpind+=MaxSignalLength;
            }
            if (j == TrainChan[0]) {
              sigtmp = int(map((signalIn[j][tmpind]+Calibration[j] - HalfSignalVal)*VoltScale, 0, MaxSignalVal, plotheight/2, plotheight));
              sigtmp = constrain(sigtmp, plotheight/2+pointThickness+1, plotheight-pointThickness-1);
            }
            if (j==TrainChan[1]) {
              sigtmp = int(map((signalIn[j][tmpind]+Calibration[j] - HalfSignalVal)*VoltScale, 0, MaxSignalVal, 0, plotheight/2));
              sigtmp = constrain(sigtmp, pointThickness+1, plotheight/2 - pointThickness-1)-plot2offset;
            }
            drawMyLine(xPos+xStep-1, ytmp - oldPlotSignal[j], xPos+xStep, ytmp - sigtmp, SigColorM[j], pointThickness);
            oldPlotSignal[j] = sigtmp;
          }
        }
      }
      datacounter --;
    }
    updatePixels();
  }

  void drawThresh() {
    int sigtmp;
    stroke(255, 255, 0);
    strokeWeight(1);

    // channel 1
    sigtmp = int(map(RepThresh[0], 0, MaxSignalVal, plotheight/2, plotheight));
    sigtmp = constrain(sigtmp, plotheight/2 + pointThickness, plotheight-pointThickness);
    line(xStep, ytmp-sigtmp, xStep+plotwidth, ytmp-sigtmp);

    // channel 2
    sigtmp = int(map(RepThresh[1], 0, MaxSignalVal, 0-plot2offset, plotheight/2-plot2offset));
    sigtmp = constrain(sigtmp, pointThickness-plot2offset, plotheight/2-pointThickness-plot2offset);
    line(xStep, ytmp-sigtmp, xStep+plotwidth, ytmp-sigtmp);
  }

  void resetWorkout() {
    ChanFlexed[0] = false;
    ChanFlexed[0] = false;
    RepsCounter[0] = 0;
    RepsCounter[1] = 0;
    FlexOnCounter[0] = 0;
    FlexOnCounter[1] = 0;
    if (TrainingMode == TRepCounter) {
      ClearRepBar(3);
      LabelRepBar(3);
    }
    else if (TrainingMode == TDataLogger) {
      TMax = new int[2][100];
      ClearRepBar(3);
      LabelTData();
    }
  }

  void LabelTData() {
    textAlign(CENTER, CENTER);
    stroke(0);
    fill(0);
    text("Max Voltages", xStep+880, 40);
  }

  void CountReps() {
    int tmpind = 0;
    tmpind = signalindex-datacounter;
    while (tmpind < 0) {
      tmpind+=MaxSignalLength;
    }
    for (int i = 0; i < 2; i++) {
      if (ChannelOn[TrainChan[i]]) {
        if ((signalIn[TrainChan[i]][tmpind]-HalfSignalVal)>RepThresh[i]) {
          if (!ChanFlexed[i]) {
            FlexOnCounter[i]++;
            if (FlexOnCounter[i] > 2) {
              ChanFlexed[i] = true;
              if (RepsCounter[i] < RepsTarget[i]) {
                RepsCounter[i]++;
              }
              FlexOnCounter[i]=0;
            }
          }
        }
        else if ((signalIn[TrainChan[i]][tmpind]-HalfSignalVal)<RepThresh[i]) {
          ChanFlexed[i] = false;
          FlexOnCounter[i] = 0;
        }
      }
    }
  }

  void ClearRepBar(int barN) {
    fill(backgroundcolor);
    stroke(backgroundcolor);
    rectMode(CENTER);
    if (barN == 1 || barN == 3) {
      rect(xStep+plotwidth+200, yTitle+plotheight/2, 80, plotheight-40);
    }
    if (barN == 2 || barN == 3) {
      rect(xStep+plotwidth+300, yTitle+plotheight/2, 80, plotheight-40);
    }
  }

  void drawRepBar() {
    if (ChannelOn[TrainChan[0]]) {
      int top = min(plotheight, int(map(RepsCounter[0], 0, RepsTarget[0], 0, plotheight-60)));
      rectMode(CENTER);
      stroke(0);
      strokeWeight(2);
      fill(SigColorM[TrainChan[0]]);
      rect(xStep+plotwidth+200, ytmp-top/2-20, RepBarWidth, top);
    }
    if (ChannelOn[TrainChan[1]]) {
      int top = min(plotheight, int(map(RepsCounter[1], 0, RepsTarget[1], 0, plotheight-60)));
      rectMode(CENTER);
      stroke(0);
      fill(SigColorM[TrainChan[1]]);
      rect(xStep+plotwidth+300, ytmp-top/2-20, RepBarWidth, top);
    }
    rectMode(CENTER);
  }

  void LabelRepBar(int ChanN) {
    int val;
    textAlign(CENTER, CENTER);
    stroke(labelcolor);
    fill(labelcolor);
    if (ChanN == 1 || ChanN == 3) {
      if (ChannelOn[TrainChan[0]]) {
        val = 0;
        for (int i = 0; i <= RepsTarget[0]; i++) {
          text(nf(val, 1, 0), plotwidth+220, ytmp - 20 - int(map(val, 0, RepsTarget[0], 0, plotheight-60)));
          val ++;
        }
        text(buttons[Bchan1].label, plotwidth+260, yTitle+20);
      }
    }
    if (ChanN == 2 || ChanN == 3) {
      if (ChannelOn[TrainChan[1]]) {
        val = 0;
        for (int i = 0; i <= RepsTarget[1]; i++) {
          text(nf(val, 1, 0), plotwidth+320, ytmp - 20 - int(map(val, 0, RepsTarget[1], 0, plotheight-60)));
          val ++;
        }
        text(buttons[Bchan2].label, plotwidth+360, yTitle+20);
      }
    }
  }

  void TLogData() {
    for (int i = 0; i < 2; i++) {
      if (ChannelOn[i]) {
        if (signalIn[TrainChan[i]][signalindex]>DataThresh[i]) {
          if (!ChanFlexed[i]) {
            FlexOnCounter[i]++;
            if (FlexOnCounter[i] > 15) {
              ChanFlexed[i] = true;
              RepsCounter[i]++;
              //FlexOnCounter[i]=0;
            }
          }
          else if (ChanFlexed[i]) {
            TMax[i][RepsCounter[i]] = max(TMax[i][RepsCounter[i]], int(signalIn[TrainChan[i]][signalindex]));
          }
        }
        else if (signalIn[TrainChan[i]][signalindex]<DataThresh[i]) {
          if (ChanFlexed[i]) {
            FlexOnCounter[i]--;
            if (FlexOnCounter[i] <= 0) {
              ChanFlexed[i] = false;
              FlexOnCounter[i] = 0;
            }
          }
        }
      }
    }
  }

  void drawTData() {
    int xstart = 750;
    int sigtmp = 0;
    for (int i = 0; i < 100; i++) {
      int j = 0;
      if (ChannelOn[j]) {
        stroke(0, 255, 0);
        fill(0, 255, 0);
        sigtmp = int(map(TMax[j][i], MaxSignalVal/2, MaxSignalVal, 0, plotheight));
        sigtmp = max(sigtmp, 0);
        line(xstart, yTitle+plotheight/2, xstart, yTitle+plotheight/2-sigtmp);
        line(xstart+1, yTitle+plotheight/2, xstart+1, yTitle+plotheight/2-sigtmp);
      }
      j = 1;
      if (ChannelOn[j]) {
        stroke(0, 0, 255);
        fill(0, 0, 255);
        sigtmp = int(map(TMax[j][i], MaxSignalVal/2, MaxSignalVal, 0, plotheight));
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
  int ButtonNum = 0;
  int
    Bclear = ButtonNum++, 
  Bpause = ButtonNum++, 
  Bchan1 = ButtonNum++, 
  Bchan2 = ButtonNum++, 
  Bchan1up = ButtonNum++, 
  Bchan2up = ButtonNum++, 
  Bchan1down = ButtonNum++, 
  Bchan2down = ButtonNum++;

  // MouseGame
  int GameTargetX;
  int GameTargetY;
  int GamedelayTime = 10;
  int GamedelayTimeMin = 1;
  int GamedelayTimeMax = 10;
  int GamedelayTimeIncrement = 1;
  int GamenextStep;
  int Gametargetsize = 60;
  int GameScore = 0;
  boolean MouseTuneFlag = false;
  char MouseAxis = 'X';
  boolean MouseXAxisFlip = false;
  boolean MouseYAxisFlip = false;


  int MouseThreshStandOff = 5;
  int MouseThreshInd = 0;
  int XMouseFactor1 = 2;
  int XMouseFactor2 = 2;
  int XMouseFactor3 = 2;
  int YMouseFactor1 = 2;
  int YMouseFactor2 = 2;
  int YMouseFactor3 = 2;
  int MouseX=0, MouseY=0;
  int MouseSpeed = 3;
  boolean ButtonPressedFlag = false;
  String pageName = "Target Practice";

  // constructor
  TargetPracticePage() {
    // set input variables
    // Mouse Page Buttons
    initializeButtons();
  }

  void initializeButtons() {
    buttons = new GuiButton[ButtonNum];
    int buttony = yTitle+195;
    int controlsy = yTitle+30;
    buttons[Bpause]    = new GuiButton("Pause", 'p', dummypage, xStep+plotwidth+45, controlsy+10, 60, Bheight, color(BIdleColor), color(0), "Pause", Bonoff, false);
    buttons[Bclear]    = new GuiButton("Clear", 'c', dummypage, xStep+plotwidth+45, controlsy+40, 60, Bheight, color(BIdleColor), color(0), "Clear", Bmomentary, false);
    buttons[Bchan1up]  = new GuiButton("MChan1up", ' ', dummypage, xStep+plotwidth+80, yTitle+200, 20, 20, color(BIdleColor), color(0), ">", Bmomentary, false);
    buttons[Bchan1down]= new GuiButton("MChan1down", ' ', dummypage, xStep+plotwidth+16, yTitle+200, 20, 20, color(BIdleColor), color(0), "<", Bmomentary, false);
    buttons[Bchan1]    = new GuiButton("MChan1", ' ', dummypage, xStep+plotwidth+50, yTitle+200, 30, Bheight, color(BIdleColor), SigColorM[MouseChan[0]], ""+(MouseChan[0]+1), Bonoff, true);
    buttons[Bchan2up]  = new GuiButton("MChan2up", ' ', dummypage, xStep+plotwidth+80, yTitle+260, 20, 20, color(BIdleColor), color(0), ">", Bmomentary, false);
    buttons[Bchan2down]= new GuiButton("MChan2down", ' ', dummypage, xStep+plotwidth+16, yTitle+260, 20, 20, color(BIdleColor), color(0), "<", Bmomentary, false);
    buttons[Bchan2]    = new GuiButton("MChan2", ' ', dummypage, xStep+plotwidth+50, yTitle+260, 30, Bheight, color(BIdleColor), SigColorM[MouseChan[1]], ""+(MouseChan[1]+1), Bonoff, true);
  }

  void switchToPage() {
    plotwidth = FullPlotWidth;

    DownSampleCount = DownSampleCountMouse; //!!!!!!!!!!!!!!!
    UserFreqIndex = UserFreqIndexMouse;
    UserFrequency = UserFreqArray[UserFreqIndex];
    CheckSerialDelay = (long)max( CheckSerialMinTime, 1000.0/((float)UserFrequency/CheckSerialNSamples) );

    PauseFlag = true;
    SmoothFilterFlag = true;
    BitDepth10 = false;
    ChannelOn[MouseChan[0]] = true;
    ChannelOn[MouseChan[1]] = true;
    buttons[Bchan1].BOn = ChannelOn[MouseChan[0]];
    buttons[Bchan2].BOn = ChannelOn[MouseChan[1]];
    buttons[Bpause].BOn = PauseFlag;

    UpdateSettings();
    //    background(backgroundcolor);
    labelaxes();
    blankplot();
    drawTarget();
    GamenextStep = second()+GamedelayTime;
    println(GamenextStep);
    GameScore = 0;
    println("Mouse Turned ON");
    MouseX = xx+width/2;
    MouseY = yy+height/2;
    robot.mouseMove(MouseX, MouseY);
    MouseTuneFlag = false;
  }

  void drawPage() {
    // draw subfunctions
    if (ButtonPressedFlag) {
      if (millis() > ButtonColorTimer) {
        ButtonPressedFlag = false;
        println("Current Button = " + currentbutton);
        if (buttons[currentbutton] != null && currentbutton < buttons.length) {
          buttons[currentbutton].ChangeColorUnpressed();
        }
      }
    }

    drawTargetPractice();
  }

  String getPageName() {
    return pageName;
  }

  void labelaxes() {
    fill(labelcolor);
    stroke(labelcolor);
    strokeWeight(2);
    textAlign(CENTER, CENTER);

    // title
    textSize(titlesize);
    text("Flex Mouse", xStep+FullPlotWidth/2+20, yTitle-45);

    textSize(labelsizes);
    text("'p' or pause/play = toggle control of your mouse pointer.", xStep+plotwidth/2, yTitle+plotheight+9);
    text("'k' = set sensitivity. 'm' = exit mouse games. 'g' = snakegame!", xStep+plotwidth/2, yTitle+plotheight+26);
    text("x=left/right", xStep+plotwidth+barwidth/2, yTitle+120);
    text("y=up/down", xStep+plotwidth+barwidth/2, yTitle+140);
    // text("Select which input channel controls X (left/right) and Y(up/down) axes.",width/2,yTitle+plotheight+25);


    // blankplot();
    for (int i = 0; i < buttons.length; i++) {
      buttons[i].drawButton();
    }
    textSize(labelsize);
    text("X-Axis", xStep+FullPlotWidth+50, yTitle+170);
    text("Y-Axis", xStep+FullPlotWidth+50, yTitle+230);
    text("Plotting", xStep+FullPlotWidth+45, yTitle+10);
  }

  boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
    boolean outflag = false;

    if (key == 'F' || key == 'f') {
      if (MouseAxis == 'X') {
        MouseXAxisFlip = !MouseXAxisFlip;
        print("MouseXAxis Flipped. Axis = ");
        println(MouseXAxisFlip);
      }
      else if (MouseAxis == 'Y') {
        MouseYAxisFlip = !MouseYAxisFlip;
        print("MouseYAxis Flipped. Axis = ");
        println(MouseYAxisFlip);
      }
      //      outflag = true;
      return outflag = true;
    }
    if (key == 'K' || key == 'k') {
      MouseTuneFlag = !MouseTuneFlag;
      if (!MouseTuneFlag) {
        drawTarget();
        GamenextStep = second()+GamedelayTime;
        println(GamenextStep);
        GameScore = 0;
      }
      outflag = true;
    }
    if (MouseTuneFlag) {
      if (key == CODED) {
        if (keyCode == LEFT) {
          MouseThreshInd --;
          if (MouseThreshInd < 0) {
            MouseThreshInd = 3;
          }
          outflag = true;
        }
        else if (keyCode == RIGHT) {
          MouseThreshInd ++;
          if (MouseThreshInd > 3) {
            MouseThreshInd = 0;
          }
          outflag = true;
        }
        else if (keyCode == UP) {

          if (MouseThreshInd == YLow && MouseThresh[YLow] > (MouseThresh[YHigh]-MouseThreshStandOff)) {
            // do nothing - can't have low >= high!
          }
          else if (MouseThreshInd == XLow && MouseThresh[XLow] > (MouseThresh[XHigh]-MouseThreshStandOff)) {
            // do nothing - can't have low >= high!
          }
          else {
            MouseThresh[MouseThreshInd]+=2;
            MouseThresh[MouseThreshInd] = constrain(MouseThresh[MouseThreshInd], MaxSignalVal, MaxSignalVal*2);
          }
          outflag = true;
        }
        else if (keyCode == DOWN) {
          if (MouseThreshInd == YHigh && MouseThresh[YLow] > (MouseThresh[YHigh]-MouseThreshStandOff)) {
            // do nothing - can't have low >= high!
          }
          else if (MouseThreshInd == XHigh && MouseThresh[XLow] > (MouseThresh[XHigh]-MouseThreshStandOff)) {
            // do nothing - can't have low >= high!
          }
          else {
            MouseThresh[MouseThreshInd]-=2;
            MouseThresh[MouseThreshInd] = constrain(MouseThresh[MouseThreshInd], MaxSignalVal, MaxSignalVal*2);
          }
          outflag = true;
        }
        println("New MouseThresh = "+MouseThresh[MouseThreshInd]);
      }
    }

    currentbutton = -1;
    for (int i = 0; i < buttons.length; i++) {
      if (buttons[i] != null) {
        if ( (inputDev == mouseInput && buttons[i].IsMouseOver(x, y)) || (inputDev == keyInput && tkey == buttons[i].hotKey) ) {
          outflag = true;
          buttons[i].BOn = !buttons[i].BOn;
          buttons[i].ChangeColorPressed();
          ButtonColorTimer = millis()+ButtonColorDelay;
          ButtonPressedFlag = true;
          currentbutton = i;

          if (currentbutton == Bclear) {
            blankplot();
            labelaxes();
            println("Plot Cleared");
          }
          if (currentbutton == Bpause) {
            PauseFlag = !PauseFlag;
            if (!PauseFlag) {
              buttons[currentbutton].label = "Pause";
              buttons[currentbutton].drawButton();
            }
            else if (PauseFlag) {
              buttons[currentbutton].label = "Play";
              buttons[currentbutton].drawButton();
            }
            println("Pause Toggled");
          }
          if (currentbutton == Bchan1up) {
            MouseChan[0]++;
            if (MouseChan[0]>=SignalNumber) {
              MouseChan[0]=SignalNumber-1;
            }
            if (MouseChan[0] == MouseChan[1]) {
              MouseChan[0]++;
              if (MouseChan[0]>=SignalNumber) {
                MouseChan[0]=MouseChan[1]-1;
              }
            }
            buttons[Bchan1].ctext = SigColorM[MouseChan[0]];
            buttons[Bchan1].label = str(MouseChan[0]+1);
            buttons[Bchan1].drawButton();
            ChannelOn[MouseChan[0]] = buttons[Bchan1].BOn;
          }
          if (currentbutton == Bchan1down) {
            MouseChan[0]--;
            if (MouseChan[0]<0) {
              MouseChan[0]=0;
            }
            if (MouseChan[0] == MouseChan[1]) {
              MouseChan[0]--;
              if (MouseChan[0]<0) {
                MouseChan[0]=MouseChan[1]+1;
              }
            }
            buttons[Bchan1].ctext = SigColorM[MouseChan[0]];
            buttons[Bchan1].label = str(MouseChan[0]+1);
            buttons[Bchan1].drawButton();
            ChannelOn[MouseChan[0]] = buttons[Bchan1].BOn;
          }
          if (currentbutton == Bchan2up) {
            MouseChan[1]++;
            if (MouseChan[1]>=SignalNumber) {
              MouseChan[1]=SignalNumber-1;
            }
            if (MouseChan[1] == MouseChan[0]) {
              MouseChan[1]++;
              if (MouseChan[1]>=SignalNumber) {
                MouseChan[1]=MouseChan[0]-1;
              }
            }
            buttons[Bchan2].ctext = SigColorM[MouseChan[1]];
            buttons[Bchan2].label = str(MouseChan[1]+1);
            buttons[Bchan2].drawButton();
            ChannelOn[MouseChan[1]] = buttons[Bchan2].BOn;
          }
          if (currentbutton == Bchan2down) {
            MouseChan[1]--;
            if (MouseChan[1]<0) {
              MouseChan[1]=0;
            }
            if (MouseChan[1] == MouseChan[0]) {
              MouseChan[1]--;
              if (MouseChan[1]<0) {
                MouseChan[1]=MouseChan[0]+1;
              }
            }
            buttons[Bchan2].ctext = SigColorM[MouseChan[1]];
            buttons[Bchan2].label = str(MouseChan[1]+1);
            buttons[Bchan2].drawButton();
            ChannelOn[MouseChan[1]] = buttons[Bchan2].BOn;
          }

          labelaxes();
        }
      }
    }
    return outflag;
  }

  void useSerialEvent() {
  }

  void drawHelp() {
    // help text
  }

  void drawTargetPractice() {
    int tmp = 0;
    if (MouseTuneFlag) {
      // println("MousetuneFlag!");
      blankplot();
      textSize(labelsizes);
      strokeWeight(4);
      textAlign(CENTER, CENTER);
      fill(backgroundcolor);
      rectMode(CENTER);
      rect(xStep+plotwidth*5/16, yTitle+plotheight/2, plotwidth*5/8-2, plotheight-2);
      fill(0);
      text("Mouse Calibration", xStep+plotwidth*1/4, yTitle+12);
      textSize(labelsizes);

      // // arrows indicating axis directions
      // // x-axis
      // int addtmp = -140;
      // line(xStep+plotwidth/4+50+addtmp,yTitle+80,xStep+plotwidth/4+100+addtmp,yTitle+80);
      // line(xStep+plotwidth/4+90+addtmp,yTitle+70,xStep+plotwidth/4+100+addtmp,yTitle+80);
      // line(xStep+plotwidth/4+90+addtmp,yTitle+90,xStep+plotwidth/4+100+addtmp,yTitle+80);
      // line(xStep+plotwidth/4+60+addtmp,yTitle+70,xStep+plotwidth/4+50+addtmp,yTitle+80);
      // line(xStep+plotwidth/4+60+addtmp,yTitle+90,xStep+plotwidth/4+50+addtmp,yTitle+80);
      // // y-axis
      // addtmp = 100;
      // line(xStep+plotwidth/4+75+addtmp,yTitle+60,xStep+plotwidth/4+75+addtmp,yTitle+110);
      // line(xStep+plotwidth/4+75+addtmp,yTitle+60,xStep+plotwidth/4+65+addtmp,yTitle+70);
      // line(xStep+plotwidth/4+75+addtmp,yTitle+60,xStep+plotwidth/4+85+addtmp,yTitle+70);
      // line(xStep+plotwidth/4+75+addtmp,yTitle+110,xStep+plotwidth/4+65+addtmp,yTitle+100);
      // line(xStep+plotwidth/4+75+addtmp,yTitle+110,xStep+plotwidth/4+85+addtmp,yTitle+100);


      // x-low
      tmp = constrain(int(map(MouseThresh[XLow]-MaxSignalVal, 0, MaxSignalVal, 0, plotheight/2)), 0, plotheight/2);
      stroke(255, 255, 0);
      fill(0);
      line(xStep+plotwidth*5/8, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
      if (MouseThreshInd == XLow) {
        fill(255, 255, 0);
      }
      if (ytmp-tmp +20 > yTitle+plotheight-20) {
        text("X Low", xStep+plotwidth*11/16, ytmp-tmp-20);
      }
      else {    
        text("X Low", xStep+plotwidth*11/16, ytmp-tmp+20);
      }
      // y-low
      tmp = constrain(int(map(MouseThresh[YLow]-MaxSignalVal, 0, MaxSignalVal, plotheight/2, plotheight)), plotheight/2, plotheight);
      line(xStep+plotwidth*5/8, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
      fill(0);
      if (MouseThreshInd == YLow) {
        fill(255, 255, 0);
      }
      text("Y Low", xStep+plotwidth*11/16, ytmp-tmp+20);
      // x-high
      stroke(255, 0, 0);
      tmp = constrain(int(map(MouseThresh[XHigh]-MaxSignalVal, 0, MaxSignalVal, 0, plotheight/2)), 0, plotheight/2);
      line(xStep+plotwidth*5/8, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
      fill(0);
      if (MouseThreshInd == XHigh) {
        fill(255, 255, 0);
      }
      if (ytmp-tmp +20 > yTitle+plotheight-20) {
        text("X High", xStep+plotwidth*15/16, ytmp-tmp-20);
      }
      else {    
        text("X High", xStep+plotwidth*15/16, ytmp-tmp+20);
      }
      // y-high
      tmp = constrain(int(map(MouseThresh[YHigh]-MaxSignalVal, 0, MaxSignalVal, plotheight/2, plotheight)), plotheight/2, plotheight);
      line(xStep+plotwidth*5/8, ytmp-tmp, xStep+plotwidth, ytmp-tmp);
      fill(0);
      if (MouseThreshInd == YHigh) {
        fill(255, 255, 0);
      }
      text("Y High", xStep+plotwidth*15/16, ytmp-tmp+20);

      // actual signals
      stroke(0, 255, 0);
      fill(0, 255, 0);
      int tmpind = 0;
      tmpind = signalindex-datacounter;
      datacounter = 0;
      while (tmpind < 0) {
        tmpind+=MaxSignalLength;
      }
      tmp = constrain(int(map(signalIn[MouseChan[0]][tmpind]+Calibration[MouseChan[0]]-MaxSignalVal, 0, MaxSignalVal, 0, plotheight/2)), 0, plotheight/2);
      line(xStep+plotwidth*5/8, ytmp - tmp, xStep+plotwidth, ytmp - tmp);
      if (tmp < 50) {
        text("X-axis", xStep+plotwidth*13/16, ytmp-tmp-20);
      }
      else {
        text("X-axis", xStep+plotwidth*13/16, ytmp-tmp+20);
      }

      tmp = constrain(int(map(signalIn[MouseChan[1]][tmpind]+Calibration[MouseChan[1]]-MaxSignalVal, 0, MaxSignalVal, plotheight/2, plotheight)), plotheight/2, plotheight);
      line(xStep+plotwidth*5/8, ytmp - tmp, xStep+plotwidth, ytmp - tmp);
      if (tmp<plotheight/2+30) {
        text("Y-axis", xStep+plotwidth*13/16, ytmp-tmp-20);
      }
      else {
        text("Y-axis", xStep+plotwidth*13/16, ytmp-tmp+20);
      }

      String mouse_msg = "";
      mouse_msg += "Input > high => mouse moves up/right\nInput < low => mouse moves down/left\nlow<Input<high => mouse does not move\n";
      mouse_msg += "\n";
      mouse_msg += "To Set Thresholds:\n";
      mouse_msg += " Left/Right arrows select threshold (yellow)\n";
      // mouse_msg += " (Selected threshold turns yellow)\n";
      mouse_msg += " Up/Down arrows move selected threshold\n";
      // mouse_msg += " (Threshold will move\n";
      mouse_msg += "\n";
      mouse_msg += "Adjust thresholds so the green bar is below low when completely relaxed, between low and high when slightly flexed, and above high when fully flexed.";
      textSize(labelsizexs);
      fill(0);
      textAlign(LEFT, CENTER);
      text(mouse_msg, xStep+plotwidth*5/16+3, yTitle+plotheight/2, plotwidth*5/8-12, plotheight);
      textAlign(CENTER, CENTER);


      if (!PauseFlag) {
        moveMouse(tmpind);
      }
    }
    else if (!MouseTuneFlag) {
      if (!PauseFlag) {//MouseGame
        int tmpind = 0;
        tmpind = signalindex-datacounter;
        datacounter = 0;
        while (tmpind < 0) {
          tmpind+=MaxSignalLength;
        }
        moveMouse(tmpind);
        drawcrosshair(MouseX, MouseY);
        if (iswinner()) {
          print("Winner");
          GameScore ++;
          // delayTime -= delayTimeIncrement;
          // if (delayTime < delayTimeMin){delayTime = delayTimeMin;}
          GamenextStep = second()+GamedelayTime;
          println(GamenextStep);
          drawTarget();
        }
        if (second() > GamenextStep) {
          GamedelayTime += GamedelayTimeIncrement;
          if (GamedelayTime > GamedelayTimeMax) {
            GamedelayTime = GamedelayTimeMax;
          }
          drawTarget();
          GamenextStep = second()+GamedelayTime;
          print("Out Of Time!");
          println(GamenextStep);
        }
      }
      else {
        //blankplot();
        stroke(0);
        fill(255, 69, 0);
        ellipse(xStep+GameTargetX, ytmp-GameTargetY, Gametargetsize, Gametargetsize);
        drawcrosshair(MouseX, MouseY);
        GamenextStep = second()+GamedelayTime;
      }
    }
  }

  void moveMouse(int tmpind) {
    int tmp = 0;
    int MouseMoveX = 0, MouseMoveY = 0;
    int MouseOffset = 40;
    // if (MouseAxis == 'X'){
    tmp = int(signalIn[MouseChan[0]][tmpind]+Calibration[MouseChan[0]]);
    //print("tmp = ");print(tmp);print(". Thresh = ");println(MouseThresh[0]);
    if (tmp < MouseThresh[0]) {
      MouseMoveX = -1*MouseSpeed;//(MouseThresh[0] - tmp)*XMouseFactor1;
    }
    else if (tmp < MouseThresh[1]) {
      MouseMoveX = 0;
    }
    else {
      MouseMoveX = 1*MouseSpeed;//(tmp - MouseThresh[1])*XMouseFactor3;
    }
    if (!MouseXAxisFlip) {
      MouseX += MouseMoveX;
    }
    else {
      MouseX -= MouseMoveX;
    }

    tmp = int(signalIn[MouseChan[1]][tmpind]+Calibration[MouseChan[1]]);
    if (tmp < MouseThresh[2]) {
      MouseMoveY = 1*MouseSpeed;//(MouseThresh[2] - tmp)*YMouseFactor1;
    }
    else if (tmp < MouseThresh[3]) {
      MouseMoveY = 0;//(MouseThresh[3] - tmp)*YMouseFactor2;
    }
    else {
      MouseMoveY = -1*MouseSpeed;//(tmp - MouseThresh[3])*YMouseFactor3;
    }
    if (!MouseYAxisFlip) {
      MouseY += MouseMoveY;
    }
    else {
      MouseY -= MouseMoveY;
    }
    // }

    // println("MouseMoveX = "+MouseMoveX+". MouseMoveY = "+MouseMoveY);
    MouseX = constrain(MouseX, xStep+MouseOffset, xStep+plotwidth-MouseOffset);
    MouseY = constrain(MouseY, yTitle+MouseOffset, yTitle+plotheight-MouseOffset);
    robot.mouseMove(MouseX+xx, MouseY+yy);
  }

  void drawcrosshair(int hx, int hy) {
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

  void drawTarget() {
    blankplot();
    stroke(0);
    fill(255, 69, 0);
    GameTargetX = int(random(0+Gametargetsize, plotwidth-Gametargetsize));
    GameTargetY = int(random(0+Gametargetsize, plotheight-Gametargetsize));
    // ellipseMode(RADIUS);
    ellipse(xStep+GameTargetX, ytmp-GameTargetY, Gametargetsize, Gametargetsize);
    drawScore();
  }

  void drawScore() {
    textSize(32);
    textAlign(CENTER, CENTER);
    stroke(0, 0, 0);
    fill(0, 255, 0);
    text("SCORE = ", 180, 120);
    text(nf(GameScore, 5, 0), 320, 120);
  }

  boolean iswinner() {
    int rx = ((mouseX-xStep)-GameTargetX);
    rx = rx*rx;
    int ry = ((ytmp-mouseY)-GameTargetY);
    ry = ry*ry;
    float r = sqrt(float(rx+ry));
    if (r < Gametargetsize) {
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
  int ButtonNum = 0;
  int
    Bclear = ButtonNum++, 
  Bpause = ButtonNum++, 
  Bchan1 = ButtonNum++, 
  Bchan2 = ButtonNum++, 
  Bchan1up = ButtonNum++, 
  Bchan2up = ButtonNum++, 
  Bchan1down = ButtonNum++, 
  Bchan2down = ButtonNum++;

  color snakecolor;
  color foodcolor;
  color backgroundcolor;
  color textcolor;

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
  boolean ButtonPressedFlag = false;

  String pageName = "FlexVolt Snake Game";

  SnakeGamePage(PApplet parent) {
    this.parent = parent;

    initializeButtons();

    snakecolor = color(250, 220, 180);
    foodcolor = color(255, 0, 0);
    backgroundcolor = color(0, 0, 0);
    textcolor = color(240, 240, 240);

    gamex = plotwidth/2;
    gamey = plotheight/2;
    gamewidth = plotwidth;
    gameheight = plotheight;

    foodSize = 30;
    drawFood();
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

  void initializeButtons() {
    int buttony = yTitle+195;
    int controlsy = yTitle+30;
    buttons = new GuiButton[ButtonNum];
    buttons[Bpause]    = new GuiButton("Pause ", 'p', dummypage, xStep+plotwidth+45, controlsy+10, 60, Bheight, color(BIdleColor), color(0), "Pause", Bonoff, false);
    buttons[Bclear]    = new GuiButton("Clear ", 'c', dummypage, xStep+plotwidth+45, controlsy+40, 60, Bheight, color(BIdleColor), color(0), "Clear", Bmomentary, false);
    buttons[Bchan1up]  = new GuiButton("MCh1up", ' ', dummypage, xStep+plotwidth+80, yTitle+200, 20, 20, color(BIdleColor), color(0), ">", Bmomentary, false);
    buttons[Bchan1down]= new GuiButton("MCh1dn", ' ', dummypage, xStep+plotwidth+16, yTitle+200, 20, 20, color(BIdleColor), color(0), "<", Bmomentary, false);
    buttons[Bchan1]    = new GuiButton("MChan1", ' ', dummypage, xStep+plotwidth+50, yTitle+200, 30, Bheight, color(BIdleColor), SigColorM[MouseChan[0]], ""+(MouseChan[0]+1), Bonoff, true);
    buttons[Bchan2up]  = new GuiButton("MCh2up", ' ', dummypage, xStep+plotwidth+80, yTitle+260, 20, 20, color(BIdleColor), color(0), ">", Bmomentary, false);
    buttons[Bchan2down]= new GuiButton("MCh2dn", ' ', dummypage, xStep+plotwidth+16, yTitle+260, 20, 20, color(BIdleColor), color(0), "<", Bmomentary, false);
    buttons[Bchan2]    = new GuiButton("MChan2", ' ', dummypage, xStep+plotwidth+50, yTitle+260, 30, Bheight, color(BIdleColor), SigColorM[MouseChan[1]], ""+(MouseChan[1]+1), Bonoff, true);
  }

  void switchToPage() {
    clearGameScreen();
  }

  void drawPage() {
    if (ButtonPressedFlag) {
      if (millis() > ButtonColorTimer) {
        ButtonPressedFlag = false;
        println("Current Button = " + currentbutton);
        if (buttons[currentbutton] != null && currentbutton < buttons.length) {
          buttons[currentbutton].ChangeColorUnpressed();
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

  String getPageName() {
    return pageName;
  }

  void useSerialEvent() {
  }

  boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
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
          buttons[i].BOn = !buttons[i].BOn;
          buttons[i].ChangeColorPressed();
          ButtonColorTimer = millis()+ButtonColorDelay;
          ButtonPressedFlag = true;
          currentbutton = i;

          if (currentbutton == Bclear) {
            blankplot();
            labelaxes();
            println("Plot Cleared");
          }
          if (currentbutton == Bpause) {
            PauseFlag = !PauseFlag;
            if (!PauseFlag) {
              buttons[currentbutton].label = "Pause";
              buttons[currentbutton].drawButton();
            }
            else if (PauseFlag) {
              buttons[currentbutton].label = "Play";
              buttons[currentbutton].drawButton();
            }
            println("Pause Toggled");
          }

          labelaxes();
        }
      }
    }
    return outflag;
  }

  void labelaxes() {
  }

  void drawHelp() {
  }

  void clearGameScreen() {
    fill(backgroundcolor);
    stroke(backgroundcolor);
    rectMode(CENTER);
    rect(gamex, gamey, gamewidth, gameheight);
  }

  void resetSnakeGame() {
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

  void runSnakeGame() {
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

  void checkSelfImpact() {
    for (int i = 1; i < snakeSize; i++) {
      if (snakeX[0] == snakeX[i] && snakeY[0] == snakeY[i]) {
        gameOver = true;
      }
    }
  }

  void checkAteFood() {
    if (foodX == snakeX[0] && foodY == snakeY[0]) {
      foodflag = true;
      snakeSize ++;
    }
  }

  void drawFood() {
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

  void drawSnake() {
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

  void moveSnake() {
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
  int ButtonNum = 0;
  int
    Bclear = ButtonNum++, 
  Bpause = ButtonNum++;

  MuscleMusicPage() {
    initializeButtons();
  }

  void initializeButtons() {
    int buttony = yTitle+195;
    int controlsy = yTitle+30;
    buttons = new GuiButton[ButtonNum];
    buttons[Bpause]    = new GuiButton("Pause ", 'p', dummypage, xStep+plotwidth+45, controlsy+10, 60, Bheight, color(BIdleColor), color(0), "Pause", Bonoff, false);
    buttons[Bclear]    = new GuiButton("Clear ", 'c', dummypage, xStep+plotwidth+45, controlsy+40, 60, Bheight, color(BIdleColor), color(0), "Clear", Bmomentary, false);
  }

  void switchToPage() {
  }

  void drawPage() {
  }

  String getPageName() {
    return pageName;
  }

  void useSerialEvent() {
  }

  void useMousePressed() {
  }

  boolean useKeyPressedOrMousePressed(int x, int y, char tkey, int tkeyCode, int inputDev) {
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
          buttons[i].BOn = !buttons[i].BOn;
          buttons[i].ChangeColorPressed();
          ButtonColorTimer = millis()+ButtonColorDelay;
          ButtonPressedFlag = true;
          currentbutton = i;

          if (currentbutton == Bclear) {
            blankplot();
            labelaxes();
            println("Plot Cleared");
          }
          if (currentbutton == Bpause) {
            PauseFlag = !PauseFlag;
            if (!PauseFlag) {
              buttons[currentbutton].label = "Pause";
              buttons[currentbutton].drawButton();
            }
            else if (PauseFlag) {
              buttons[currentbutton].label = "Play";
              buttons[currentbutton].drawButton();
            }
            println("Pause Toggled");
          }

          labelaxes();
        }
      }
    }
    return outflag;
  }

  void labelaxes() {
  }

  boolean useKeyPressed() {
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

  void drawHelp() {
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
  String USBPORTs[];
  String BlueToothPORTs;
  boolean foundPorts;
  boolean connectingflag;
  boolean portopenflag;
  boolean flexvoltconnected;
  boolean flexvoltfound;
  boolean testingUSBcom;
  boolean connectinglongertime;
  long timer;
  int portindex;
  int USBportsN;
  int BTportsN;
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
  long CheckSerialTimer = 0;


  public SerialPortObj(PApplet parent_) {
    this.parent = parent_;
    USBPORTs = new String[0];
    BluetoothPORTs = new String[0];
    foundPorts = false;
    connectingflag = false;
    portopenflag = false;
    flexvoltconnected = false;
    flexvoltfound = false;
    testingUSBcom = true;
    timer = 0;
    portindex = 0;
    USBportsN = 0;
    BTportsN = 0;
    shortwaittimeUSB = 500;
    longwaittimeUSB = 2000;
    shortwaittimeBT = 500;
    longwaittimeBT = 2000;
    connectionindicator = 0;
    indicator_noconnection = 0;
    indicator_connecting = 1;
    indicator_connected = 2;
  }

  boolean manageConnection(boolean dataflag, boolean serialreceivedflag) {
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

    if (dataflag) {
      if (CheckSerialTimer == 0) {
        CheckSerialTimer = millis()+CheckSerialDelay;
        println("addon");
      }
      if (millis()>CheckSerialTimer) {
        CheckSerialTimer = millis()+CheckSerialDelay;
        if (!serialreceivedflag) {
          flexvoltconnected = false;
          communicationsflag = false;
          dataflag = false;
          println("Serial Timeout");
          connectionindicator = FVserial.indicator_noconnection;
          drawConnectionIndicator();
          display_error("FlexVolt Connection Lost");
        }
      }
    }
    return dataflag;
  }

  void connectserial() {
    reset();
    FVserial.PollSerialDevices();
    if (foundPorts) {
      connectionindicator = indicator_connecting;
      connectingflag = true;
      connectionAtimer = millis()+connectionAdelay;
    }
  }

  void drawConnectionIndicator() {
    fill(150);
    strokeWeight(2);
    stroke(0);
    ellipse(xStep+FullPlotWidth+10, yTitle/2, 24, 24);
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
    ellipse(xStep+FullPlotWidth+10, yTitle/2, 14, 14);
  }

  void TryPort() {
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
            if (portindex >= USBportsN) {
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
                TrySerialConnect(USBPORTs[portindex], longwaittimeUSB);
              } 
              else if (!connectinglongertime) {
                TrySerialConnect(USBPORTs[portindex], shortwaittimeUSB);
              }
              portindex++;
            }
          }
          else {
            if (portindex >= BTportsN) {
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
                TrySerialConnect(BluetoothPORTs[portindex], longwaittimeBT);
              } 
              else if (!connectinglongertime) {
                TrySerialConnect(BluetoothPORTs[portindex], shortwaittimeBT);
              }
              portindex++;
            }
          }
        }
      }
    }
  }

  void reset() {
    USBPORTs = new String[0];
    BluetoothPORTs = new String[0];
    foundPorts = false;
    connectingflag = false;
    portopenflag = false;
    flexvoltconnected = false;
    flexvoltfound = false;
    testingUSBcom = true;
    timer = 0;
    portindex = 0;
    USBportsN = 0;
    BTportsN = 0;
    connectionindicator = indicator_noconnection;
  }

  void TrySerialConnect(String portname, int waittime) {
    try {
      if (myPort != null) {
        myPort.clear();
        myPort.stop();
      }
      myPort = new Serial(parent, portname, SerialPortSpeed);//38400
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

  void PollSerialDevices() {
    // find serial port
    String[] m1;
    USBPORTs = new String[0];
    BluetoothPORTs = new String[0];

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
      USBname = "COM";
      Bluetoothname = "tty.FlexVolt";
    }
    else if (platform == OTHER) {
      println("Found an Unknown Operating System!");
      USBname = "COM";
      Bluetoothname = "tty.FlexVolt";
      display_error("Found an Unknown Operating System!");
    }
    for (int i = 0; i<Serial.list().length; i++) {
      m1 = match(Serial.list()[i], USBname);
      if (m1 != null) {
        USBPORTs = append(USBPORTs, Serial.list()[i]);
        println("USB Device Found is " + Serial.list()[i]);
      }
    }
    for (int i = 0; i<Serial.list().length; i++) {
      m1 = match(Serial.list()[i], Bluetoothname);
      if (m1 != null) {
        BluetoothPORTs = append(BluetoothPORTs, Serial.list()[i]);
        println("Bluetooth Device Found is " + Serial.list()[i]);
      }
    }

    USBportsN = USBPORTs.length;
    if (USBportsN == 0) {
      println("USB ports = null");
    } 
    else {
      println("USB ports = ");
      println(USBPORTs);
      foundPorts = true;
    }
    BTportsN = BluetoothPORTs.length;
    if (BTportsN == 0) {
      println("BT ports = null");
    } 
    else {
      println("BT ports = ");
      println(BluetoothPORTs);
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
  color cbox;
  color ctext;
  String label;
  char hotKey;
  int pageRef;
  boolean MouseOver;
  boolean BOn;
  boolean Bmomentary;

  GuiButton(String name_, char hotKey_, int pageRef_, int xpos_, int ypos_, int xsize_, int ysize_, color cbox_, color ctext_, String label_, boolean Bmomentary_, boolean BOn_) {
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
    Bmomentary = Bmomentary_;
    BOn = BOn_;
  }

  boolean IsMouseOver(int x, int y) {
    if (x >= xpos - xsize/2 && x <= xpos+xsize/2 &&
      y >= ypos - ysize/2 && y <= ypos+ysize/2) {
      return true;
    }
    else {
      return false;
    }
  }

  void drawButton() {
    color ctext_tmp = color(0);
    int rectradius = 0;
    if (!Bmomentary) {
      if (BOn) {
        // println("on/off, changing color to On");
        cbox = BOnColor;
        ctext_tmp = ctext;
      }
      else if (!BOn) {
        // println("on/off, changing color to Off");
        cbox = BIdleColor;
        ctext_tmp = 0;
      }
    }
    fill(cbox);
    stroke(BoutlineColor);
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

  void ChangeColorUnpressed() {
    cbox = BIdleColor;
    drawButton();
  }

  void ChangeColorPressed() {
    cbox = BPressedColor;
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
    BIT_LEN = (int)(Math.log((double)WINDOW_SIZE)/0.693147180559945+0.5);
    _normF=2f/WINDOW_SIZE;
    _hasEnvelope=false;
    _isEqualized=false;
    initFFTtables();
  }

  void initFFTtables() {
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
      phi*=0.5;
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
  void useEqualizer(boolean on) {
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
  void useEnvelope(boolean on, float power) {
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
  float[] computeFFT(float[] waveInData) {
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
    fN=fr*0.5;
    f1=fq1;
    f2=fq2;
    atten=att;
    trband=bw;
    initialize();
  }

  float I0 (float x) {
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

  int computeOrder() {
    // estimate filter order
    order = 2 * (int) ((atten - 7.95) / (14.36*trband/fN) + 1.0f);
    // estimate Kaiser window parameter
    if (atten >= 50.0f) kaiserV = 0.1102f*(atten - 8.7f);
    else
      if (atten > 21.0f)
        kaiserV = 0.5842f*(float)Math.exp(0.4f*(float)Math.log(atten - 21.0f))+ 0.07886f*(atten - 21.0f);
    if (atten <= 21.0f) kaiserV = 0.0f;
    println("filter oder: "+order);
    return order;
  }

  void initialize() {
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

  float[] apply(float[] ip) {
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

