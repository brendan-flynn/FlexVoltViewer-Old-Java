//  Author:  Brendan Flynn - FlexVolt
//  Date Modified:    4 June 2014
/*  FlexVolt Viewer v1.1

    Recent Changes:
    app size - all GUI features now scale with plot window size
    
    
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

// Robot is used to move the computer mouse pointer
Robot robot;

// Constants
String ViewerVersion = "v1.1";
Serial myPort;
//String RENDERMODE = "P2D";
int FullPlotWidth = 500;
int plotwidth = FullPlotWidth;
int HalfPlotWidth = FullPlotWidth/2;
int plotheight = 300;
int plot2offset = 5;
int xx, yy;
int xStep = 60;
int yStep = 40;
int yTitle = 60;
int barwidth = 100;
int SerialBufferN = 5;
int SerialBurstN = 2;
int SerialPortSpeed = 230400;
int serialwritedelay = 50;
int axisnumbersize = 16;
int labelsize = 20;
int labelsizes = 16;
int labelsizexs = 14;
int titlesize = 26;
int buttontextsize = 16;
int RepBarWidth = 30;


float fps = 30;
float FreqMax = 500;//Hz for fft display window
float FreqAmpMin = 0;
float FreqAmpMax = 1;
int FFTscale = 80; // multiplying fft amplitude
int VoltScale = 1;
float VoltageMax = 10/VoltScale;
float VoltageMin = -10/VoltScale;
float AmpGain = 1845; // 495 from Instrumentation Amp, 3.73 from second stage.  1845 total.
float DynamicRange = 1.355;//mV.  5V max, split around 2.5.  2.5V/1845 = 1.355mV.
int MaxSignalVal = 512;//4095;
int HalfSignalVal = 512;
int Nxticks = 5;
int Nyticks = 4;
int NyticksHalf = 2;
int TimeDomain = 0, FreqDomain = 1, MouseDomain = 2, TrainingDomain = 3, SettingsDomain = 4, HelpDomain = 5, OldDomain = 0;
int MaxSignalLength = 1000;
int FFTSignalLength = 1024;
int SMscroll = 1, SMtrace = 0;
int pointThickness = 3;
int ytmp;
int MedianFiltN = 3;
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

int UserFrequencyTmp;
int UserFreqIndexTmp;
int SmoothFilterValTmp;
int DownSampleCountTmp;
int Timer0AdjustValTmp;
int PrescalerTmp;
int DataRecordTimeTmp;
int SignalNumberTmp;

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
color plotbackground = 100;
color plotoutline = 0;
color backgroundcolor = 200;
color plotlinecolor = 255;


// GUi Class Objects //
// Buttons
GuiButton[] buttonsTDP;
int ButtonNumTDP = 0;
int
//     Bplay = ButtonNumTDP++,
BTDPsettings = ButtonNumTDP++,
BTDPhelp = ButtonNumTDP++,
//BTDPrecorddata = ButtonNumTDP++,
BTDPrecordnextdata = ButtonNumTDP++,
//BTDPdomain = ButtonNumTDP++,
BTDPtimedomain = ButtonNumTDP++, 
BTDPfreqdomain = ButtonNumTDP++,
BTDPtraindomain = ButtonNumTDP++,
BTDPmousedomain = ButtonNumTDP++,
BTDPserialreset = ButtonNumTDP++,
BTDPoffset = ButtonNumTDP++,
BTDPsmooth = ButtonNumTDP++,
BTDPclear = ButtonNumTDP++,
BTDPpause = ButtonNumTDP++,
BTDPsave = ButtonNumTDP++,
BTDPchan1 = ButtonNumTDP++,
BTDPchan2 = ButtonNumTDP++,
BTDPchan3 = ButtonNumTDP++,
BTDPchan4 = ButtonNumTDP++,
BTDPchan5 = ButtonNumTDP++,
BTDPchan6 = ButtonNumTDP++,
BTDPchan7 = ButtonNumTDP++,
BTDPchan8 = ButtonNumTDP++;

GuiButton[] buttonsFDP;
int ButtonNumFDP = 0;
int
// Bplay = ButtonNumFDP++,
BFDPsettings = ButtonNumFDP++,
BFDPhelp = ButtonNumFDP++,
//BFDPrecorddata = ButtonNumFDP++,
BFDPrecordnextdata = ButtonNumFDP++,
//BFDPdomain = ButtonNumFDP++,
BFDPtimedomain = ButtonNumFDP++,
BFDPfreqdomain = ButtonNumFDP++,
BFDPtraindomain = ButtonNumFDP++,
BFDPmousedomain = ButtonNumFDP++,
BFDPserialreset = ButtonNumFDP++,
BFDPoffset = ButtonNumFDP++,
//BFDPsmooth = ButtonNumFDP++,
//BFDPclear = ButtonNumFDP++,
BFDPpause = ButtonNumFDP++,
BFDPsave = ButtonNumFDP++,
BFDPchan1 = ButtonNumFDP++,
BFDPchan2 = ButtonNumFDP++,
BFDPchan3 = ButtonNumFDP++,
BFDPchan4 = ButtonNumFDP++,
BFDPchan5 = ButtonNumFDP++,
BFDPchan6 = ButtonNumFDP++,
BFDPchan7 = ButtonNumFDP++,
BFDPchan8 = ButtonNumFDP++;

GuiButton[] buttonsTP;
int ButtonNumTP = 0;
int
BTPsettings = ButtonNumTP++,
BTPhelp = ButtonNumTP++,
//BTPrecorddata = ButtonNumTP++,
BTPrecordnextdata = ButtonNumTP++,
//BTPdomain = ButtonNumTP++,
BTPtimedomain = ButtonNumTP++,
BTPfreqdomain = ButtonNumTP++,
BTPtraindomain = ButtonNumTP++,
BTPmousedomain = ButtonNumTP++,
BTPserialreset = ButtonNumTP++,
BTPoffset = ButtonNumTP++,
BTPsmooth = ButtonNumTP++,
//BTPclear = ButtonNumTP++,
//BTPpause = ButtonNumTP++,
BTPsave = ButtonNumTP++,
BTPreset = ButtonNumTP++,
BTPsetReps1 = ButtonNumTP++,
BTPsetReps2 = ButtonNumTP++,
BTPthresh1up = ButtonNumTP++,
BTPthresh1down = ButtonNumTP++,
BTPthresh2up = ButtonNumTP++,
BTPthresh2down = ButtonNumTP++,
BTPchan1 = ButtonNumTP++,
BTPchan2 = ButtonNumTP++,
BTPchan1up = ButtonNumTP++,
BTPchan2up = ButtonNumTP++,
BTPchan1down = ButtonNumTP++,
BTPchan2down = ButtonNumTP++,
BTPchan1name = ButtonNumTP++,
BTPchan2name = ButtonNumTP++;

GuiButton[] buttonsMP;
int ButtonNumMP = 0;
int
BMPsettings = ButtonNumMP++,
BMPhelp = ButtonNumMP++,
//BMPrecorddata = ButtonNumMP++,
BMPrecordnextdata = ButtonNumMP++,
//BMPdomain = ButtonNumMP++,
BMPtimedomain = ButtonNumMP++,
//BMPfreqdomain = ButtonNumMP++,
BMPtraindomain = ButtonNumMP++,
BMPmousedomain = ButtonNumMP++,
BMPserialreset = ButtonNumMP++,
//BMPoffset = ButtonNumMP++,
//BMPsmooth = ButtonNumMP++,
BMPclear = ButtonNumMP++,
BMPpause = ButtonNumMP++,
BMPsave = ButtonNumMP++,
BMPchan1 = ButtonNumMP++,
BMPchan2 = ButtonNumMP++,
BMPchan1up = ButtonNumMP++,
BMPchan2up = ButtonNumMP++,
BMPchan1down = ButtonNumMP++,
BMPchan2down = ButtonNumMP++;

GuiButton[] buttonsSP;
int ButtonNumSP = 0;
int
BSPfolder = ButtonNumSP++,
BSPfiltup = ButtonNumSP++,
BSPfiltdown = ButtonNumSP++,
BSPfrequp = ButtonNumSP++,
BSPfreqdown = ButtonNumSP++,
BSPrecordtimeup = ButtonNumSP++,
BSPrecordtimedown = ButtonNumSP++,
BSP1chan = ButtonNumSP++,
BSP2chan = ButtonNumSP++,
BSP4chan = ButtonNumSP++,
BSP8chan = ButtonNumSP++,
BSPcancel = ButtonNumSP++,
BSPsave = ButtonNumSP++,
BSPdefaults = ButtonNumSP++,
BSPdownsampleup = ButtonNumSP++,
BSPdownsampledown = ButtonNumSP++,
BSPtimeradjustup = ButtonNumSP++,
BSPtimeradjustdown = ButtonNumSP++,
//BSPbitdepth8 = ButtonNumSP++,
//BSPbitdepth10 = ButtonNumSP++,
BSPprescalerup = ButtonNumSP++,
BSPprescalerdown = ButtonNumSP++;

String folder = "";
String folderTmp = "";
String tmpfolder = "";
String HomePath = System.getProperty("user.home"); // default path to save settings files
String typing = "";
String savedname = "";
boolean NamesFlag = false;
int NameNumber = 0;

FFTutils fft;
FIRFilter filter1, filter2;

// Variables
int xPos = 0;
int CurrentDomain = TimeDomain;
float[] filtered;
float[][] fft_result;//1, fft_result2, fft_result3, fft_result4;
float[][] signalIn;//1, signalIn2, signalIn3, signalIn4;
float[][] FFTsignalIn; // longer for FFT calculation
int[] oldPlotSignal;


int ScrollMode = SMtrace;
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
float TimeMax = float(FullPlotWidth)/float(UserFrequency);
int FreqFactor = 2;//UserFrequency/500;
int datacounter = 0;
int signalindex = 0;
int ringcounter = 0;
int SignalNumber = 4;
int MaxSignalNumber = 8;
long[] TimeStamp;
long ButtonColorTimer = 0;
long ButtonColorDelay = 100;
long CheckSerialTimer = 0;
int CheckSerialNSamples = 2;
int CheckSerialMinTime = 100;
long CheckSerialDelay = (long)max( CheckSerialMinTime, 1000.0/((float)UserFrequency/CheckSerialNSamples) );//2000;//UserFrequency/10; // millis. check at 10Hz
int TSind = 0;
int CalibrateN = 50;
int CalibrateCounter = CalibrateN;
int Calibration[] = {
  0, 0, 0, 0, 0, 0, 0, 0
};
int OffSet[] = {
  +plotheight*7/8, +plotheight*5/8, +plotheight*3/8, +plotheight*1/8, -100, -150, 40, 60
};
int OffSetFFT2[] = {
  0, plotheight/2
};
int OffSetFFT4[] = {
  0, plotheight/4, plotheight/2, plotheight*3/4
};
int OffSetFFT8[] = {
  0, plotheight/8, plotheight/4, plotheight*3/8, plotheight/2, plotheight*5/8, plotheight*3/4, plotheight*7/8
};
int currentbutton = -1;
int imagesavecounter = 1;
int[][] DataRecord;
int DataRecordCols = 9;
int DataRecordTime = 10; // seconds
int DataRecordLength = DataRecordTime*UserFrequency;
int DataRecordIndex = 0;
int DataRecordedCounter = 0;
int DataRecordTimeMax = 50;
int DataRecordTimeMin = 1;

// MouseVariables
int XLow = 0, XHigh = 1, YLow = 2, YHigh = 3;
int MouseThresh[] = {
  MaxSignalVal*5/4, MaxSignalVal*6/4, MaxSignalVal*5/4, MaxSignalVal*6/4
};// xlow, xhigh, ylow, yhigh
int[] MouseChan = {
  0, 1
};
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


// Flags
boolean InitFlag = true;
boolean dataflag = false;
boolean initializeFlag = true;
boolean MouseTuneFlag = false;
char MouseAxis = 'X';
boolean MouseXAxisFlip = false;
boolean MouseYAxisFlip = false;
boolean MouseReleaseFlag = false;
boolean PauseFlag = false;
boolean OffSetFlag = false;
boolean SmoothFilterFlag = false;
boolean ButtonPressedFlag = false;
boolean Bonoff = false;
boolean Bmomentary = true;
//boolean ChannelOn[]= {true, false, false, false, false, false};
boolean ChannelOn[]= {
  true, true, true, true, false, false, false, false
};
boolean DataRecordFlag = false;
//boolean FreezeFlag = false;
boolean SerialReceivedFlag = false;
boolean MedianFilter = false;
boolean PlugTestFlag = false;
int PlugTestDelay = 0;
boolean DataRegWriteFlag = false;
boolean snakeGameFlag = false;
int connectionAtimer = 0;
int connectionAdelay = 500;
int testcounter = 0;

// Frequency testing
//long oldtime;
//long newtime;
//int deltatime;
//float timeaverage;
//int timeaverageN = 500;
//int timeaveragecounter = 0;

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

boolean commentflag = false;

SerialPortObj FVserial;
SnakeGame mySnakeGame;


void setup () {
  HalfPlotWidth = FullPlotWidth/2;
  FreqFactor = FullPlotWidth/125;
  println("FreqFactor "+FreqFactor);
  // Setup mouse control robot
  try {
    robot = new Robot();
  }
  catch (AWTException e) {
    e.printStackTrace();
  }

  importSettings();


  // set the window size TODO get window size, modify
  // size(FullPlotWidth+barwidth+xStep, plotheight+yStep+yTitle, P2D);
  size(FullPlotWidth+barwidth+xStep, plotheight+yStep+yTitle);
  XMIN = xStep+pointThickness;
  XMAX = xStep+plotwidth-pointThickness;
  YMIN = yTitle+pointThickness;
  YMAX = yTitle+plotheight-pointThickness;
  frameRate(fps);
  ytmp = height - yStep;


  InitializeButtons();

  folderTmp = folder;
  UserFreqIndexTmp = UserFreqIndex;
  UserFrequencyTmp = UserFreqArray[UserFreqIndexTmp];
  SmoothFilterValTmp = SmoothFilterVal;
  DownSampleCountTmp = DownSampleCount;
  Timer0AdjustValTmp = Timer0AdjustVal;
  PrescalerTmp = Prescaler;
  DataRecordTimeTmp = DataRecordTime;
  SignalNumberTmp = SignalNumber;


  img = loadImage("FlexVolt_Image1.png");

  // fft setup
  fft=new FFTutils(FFTSignalLength);
  fft.useEqualizer(false);
  fft.useEnvelope(true, 1);
  fft_result = new float[MaxSignalNumber][FFTSignalLength];
  signalIn = new float[MaxSignalNumber][MaxSignalLength];
  FFTsignalIn = new float[MaxSignalNumber][FFTSignalLength];
  oldPlotSignal = new int[MaxSignalNumber];
  // Calibration = new int[MaxSignalNumber];
  // signalIn1 = new float[MaxSignalLength];
  // signalIn2 = new float[MaxSignalLength];
  // signalIn3 = new float[MaxSignalLength];
  // signalIn4 = new float[MaxSignalLength];
  filter1=new FIRFilter(FIRFilter.LOW_PASS, 2000f, 0, 1000, 60, 3400);
  filter2=new FIRFilter(FIRFilter.HIGH_PASS, 2000f, 20, 10, 60, 3400);

  TimeStamp = new long[5000];

  FVserial = new SerialPortObj(this);
  // int foodsize = 20;
  // int gamespeed = 3;
  // mySnakeGame = new SnakeGame(this,xStep+plotwidth/2,yTitle+plotheight/2,plotwidth,plotheight,foodsize,gamespeed);

  // initialize background
}

void draw () {
  if (InitFlag) {
    InitCount ++;
    if (InitCount == 1) {
      labelaxes();
      blankplot();
      display_error("Searching for FlexVolt Devices");
    }
    if (InitCount >= 2) {
      background(backgroundcolor);
      labelaxes();
      blankplot();
      startTime = System.nanoTime();
      // frame.setLocation(1481, 0);//1441
      frame.setLocation(0, 0);//1441
      xx = frame.getX()+2;
      if (platform == MACOSX){
        yy = frame.getY()+42; // add space for the mac top bar + the app top bar
      } else if (platform == WINDOWS){
        yy = frame.getY()+22; // add space for teh app top bar
      }
      println("X = "+xx+". Y = "+yy);
      println("Height = "+height+", Width = "+width);
      InitFlag = false;
      FVserial.connectserial();// the function will poll devices, set connecting flag, and set current try port index to 0
      // ConnectSerial();
      connectionAtimer = millis()+connectionAdelay;
    }
  }

  if (ButtonPressedFlag) {
    if (millis() > ButtonColorTimer) {
      ButtonPressedFlag = false;
      println("Current Button = " + currentbutton);
      if (CurrentDomain == TimeDomain && currentbutton < ButtonNumTDP) {
        if (buttonsTDP[currentbutton] != null) {
          buttonsTDP[currentbutton].ChangeColorUnpressed();
        }
      }
      else if (CurrentDomain == FreqDomain && currentbutton < ButtonNumFDP) {
        if (buttonsFDP[currentbutton] != null) {
          buttonsFDP[currentbutton].ChangeColorUnpressed();
        }
      }
      else if (CurrentDomain == TrainingDomain && currentbutton < ButtonNumTP) {
        if (buttonsTP[currentbutton] != null) {
          buttonsTP[currentbutton].ChangeColorUnpressed();
        }
      }
      else if (CurrentDomain == SettingsDomain && currentbutton < ButtonNumSP) {
        if (buttonsSP[currentbutton] != null) {
          buttonsSP[currentbutton].ChangeColorUnpressed();
        }
      }
    }
  }

  if (FVserial.connectingflag) {
    FVserial.TryPort(); // handles all connecting attempts. monitors timeout for each attempt, increments port to try, etc.
  }


  if (!FVserial.flexvoltconnected) {
    if (millis()>connectionAtimer) {
      connectionAtimer = millis()+connectionAdelay;
      if (!FVserial.flexvoltfound) {
        if (myPort != null) {
          println("Wrote 'X' to myport = "+myPort);
          myPort.write('X');
        } 
        else {
          println("No Ports to Write X To!");
        }
      } 
      else if (FVserial.flexvoltfound) {
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
    if (millis()>CheckSerialTimer) {
      CheckSerialTimer = millis()+CheckSerialDelay;
      if (SerialReceivedFlag) {
        SerialReceivedFlag = false;
      }
      else if (!SerialReceivedFlag) {
        FVserial.flexvoltconnected = false;
        dataflag = false;
        println("Serial Timeout");
        FVserial.connectionindicator = FVserial.indicator_noconnection;
        drawConnectionIndicator();
        display_error("FlexVolt Connection Lost");
      }
      SerialReceivedFlag = false;
    }
  }


  if (CurrentDomain == TimeDomain) {
    // long tmp = System.nanoTime()-startTime;
    // startTime = System.nanoTime();
    // float tmp2 = ((float)tmp)/1000000000; // convert from ns to s
    // int pointstep = int(UserFrequency*tmp); // FREQ*timeelapsed = number of points to plot
    if (!(xPos == plotwidth && PauseFlag)) {
      // startTime = System.nanoTime()/1000;
      DrawTrace();
      // endTime = System.nanoTime()/1000;
      // println("DrawTrace takes "+(endTime-startTime));
    }
  }
  if (CurrentDomain == FreqDomain) {
    if (!PauseFlag) {
      DrawFFT();
    }
  }
  if (CurrentDomain == MouseDomain) {
    if (!snakeGameFlag) {
      DrawMouseGame();
    } 
    else if (snakeGameFlag) {
      mySnakeGame.drawSnakeGame();
    }
  }
  if (CurrentDomain == TrainingDomain) {
    DrawTrainingProgram();
  }
}

void stop() {
  if (myPort != null){
    myPort.write('X');
    myPort.clear();
  }
}

void serialEvent (Serial myPort) {
  // newtime = System.nanoTime();
  // deltatime = int(newtime-oldtime)/1000;
  // timeaveragecounter++;
  // timeaverage += (float)deltatime;
  // oldtime = newtime;
  // timeaveragecounter++;
  // if(timeaveragecounter >= timeaverageN){
  // timeaveragecounter = 0;
  // timeaverage /= timeaverageN;
  // println("timing = "+timeaverage);
  // fill(20,255,20);
  // text(timeaverage,100,70);
  // }
  // startTime = System.nanoTime();
  // println("bt = "+(startTime-endTime));
  // println("Serial Event. T = "+startTime);
  // Store current fill and stroke settings
  // println("Fill = "+red(g.fillColor)+","+green(g.fillColor)+","+blue(g.fillColor));
  int tmpfillColor = g.fillColor;
  int tmpstrokeColor = g.strokeColor;
  float tmpstrokeWeight = g.strokeWeight;

  //println(myPort.available());
  if (!dataflag) {
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
        // FVserial.flexvoltconnected = true;
        // println("FlexVolt_connected = "+FVserial.flexvoltconnected);
        FVserial.connectionindicator = FVserial.indicator_connecting;
        myPort.clear();
        myPort.write('1');
        println("1st");
      }
      else if (inChar == 'b') {
        // FVserial.flexvoltconnected = true;
        // println("FlexVolt_connected = "+FVserial.flexvoltconnected);
        myPort.clear();
        // ConnectingFlag = true;
        FVserial.flexvoltconnected = true;
        FVserial.connectionindicator = FVserial.indicator_connecting;
        drawConnectionIndicator();
        UpdateSettings();
        println("updates settings");
        EstablishDataLink();
      }
      else if (inChar == 'g') {
        myPort.clear();
        println("dataflag = true g");
        blankplot();
        dataflag = true;
        CheckSerialTimer = millis()+CheckSerialDelay;
        // ConnectingFlag = false;
        FVserial.connectionindicator = FVserial.indicator_connected;
        drawConnectionIndicator();
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
    // println("avail = "+myPort.available());
    while (myPort.available () > SerialBufferN) {
      // println((System.nanoTime()-startTime)/1000);

      // println(myPort.available());
      int inChar = myPort.readChar(); // get ASCII
      // print("data, ");println(inChar);
      if (inChar != -1) {
        SerialReceivedFlag = true;
        // if (inChar == 'a') {
        // dataflag = false;
        // println("got an A in data");
        // ConnectingFlag = false;
        // }
        // if (inChar == 'b') {
        // myPort.clear();
        // myPort.write('G');
        // }
        if (inChar == 'C' || inChar == 'D' || inChar == 'E' || inChar == 'F') {
          myPort.readBytes(inBuffer);
          // println("Received8bit - "+inChar+", buffer = "+SerialBufferN);
          // println(inBuffer);
          for (int i = 0; i < SignalNumber; i++) {
            int tmp = inBuffer[i]; // last 2 bits of each signal discarded
            tmp = tmp&0xFF; // account for translation from unsigned to signed
            tmp = tmp << 2; // shift to proper position
            float rawVal = float(tmp);

            if (CurrentDomain == FreqDomain) {
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
          // println("sigindex = "+signalindex+", datacounter = "+datacounter);

          if (CurrentDomain == TrainingDomain) {
            CountReps();
          }
        }
        else if (inChar == 'H' || inChar == 'I' || inChar == 'J' || inChar == 'K') {
          myPort.readBytes(inBuffer);
          // println(inBuffer);
          for (int i = 0; i < SignalNumber; i++) {
            int tmplow = inBuffer[SerialBufferN-1]; // last 2 bits of each signal stored here
            tmplow = tmplow&0xFF; // account for translation from unsigned to signed
            tmplow = tmplow >> (2*(3-i)); // shift to proper position
            tmplow = tmplow & (3); //3 (0b00000011) is a mask.
            int tmphigh = inBuffer[i];
            tmphigh = tmphigh & 0xFF; // account for translation from unsigned to signed
            tmphigh = tmphigh << 2; // shift to proper position
            float rawVal = float(tmphigh+tmplow);
            if (CurrentDomain == FreqDomain) {
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
          // println("sigindex = "+signalindex+", datacounter = "+datacounter);

          if (CurrentDomain == TrainingDomain) {
            CountReps();
          }
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

// keyboard button handling section
void keyPressed() {
  // Store current fill and stroke settings
  int tmpfillColor = g.fillColor;
  int tmpstrokeColor = g.strokeColor;
  float tmpstrokeWeight = g.strokeWeight;

  if (keyCode == ESC||key == ESC) {
    key = 0;
    keyCode = 0;
  }
  if (NamesFlag) {
    if (CurrentDomain == TrainingDomain) {
      if (key == '\n' ) {
        println("here");
        println(typing);
        int tmpint = 0;
        savedname = typing;
        if (NameNumber == BTPsetReps1 || NameNumber == BTPsetReps2) {
          tmpint = getIntFromString(typing, RepsTargetDefault);
          println(tmpint);
          savedname = str(tmpint);
        }
        buttonsTP[NameNumber].label = savedname;
        if (NameNumber == BTPsetReps1) {
          RepsTarget[0] = tmpint;
          println("int saved");
          println(RepsTarget[0]);
          ClearRepBar(1);
          LabelRepBar(1);
        }
        else if (NameNumber == BTPsetReps2) {
          RepsTarget[1] = tmpint;
          println("int saved");
          println(RepsTarget[0]);
          ClearRepBar(2);
          LabelRepBar(2);
        }
        NamesFlag = !NamesFlag;
        buttonsTP[currentbutton].BOn = !buttonsTP[currentbutton].BOn;

        buttonsTP[NameNumber].DrawButton();
        typing = "";
        NameNumber = -1;
      }
      else if ((key >= 'a' && key <= 'z') || (key >= 'A' && key <= 'Z') || (key == ' ') || (key >='0' && key <= '9')) {
        // Otherwise, concatenate the String
        // Each character typed by the user is added to the end of the String variable.
        typing = typing + key;
        buttonsTP[NameNumber].label = typing;
        buttonsTP[NameNumber].DrawButton();
        println("adjusting");
      }
    }
  }
  else if (CurrentDomain == HelpDomain) {
    ChangeDomain(OldDomain);
  }
  else if (CurrentDomain == SettingsDomain) {
    if (key == 0) {
      key = 'c';
    }
    if (key == 'C' || key == 'c') {
      ChangeDomain(OldDomain);
    }
    else if (key == 'S' || key == 's') {
      saveSettings();
      ChangeDomain(OldDomain);
    }
  }
  else {
    if (key == 'D' || key == 'd') {
      if (CurrentDomain == TimeDomain || CurrentDomain == FreqDomain) {
        if (CurrentDomain == TimeDomain) {
          ChangeDomain(FreqDomain);
        }
        else {
          ChangeDomain(TimeDomain);
        }
      }
    }
    if (key == 'V' || key == 'v') {
      PollVersion();
    }
    if (key == 'T' || key == 't') {
      ChangeDomain(TimeDomain);
    }
    if (key == 'F' || key == 'f') {
      ChangeDomain(FreqDomain);
    }
    if (key == 'M' || key == 'm') {
      if (CurrentDomain != MouseDomain) {
        ChangeDomain(MouseDomain);
      }
      else {
        ChangeDomain(TimeDomain);
      }
    }
    if (key == 'W' || key == 'w') {
      if (CurrentDomain != TrainingDomain) {
        ChangeDomain(TrainingDomain);
      }
      else {
        ChangeDomain(TimeDomain);
        println("Workout Turned OFF");
      }
    }
    if (key == 'S' || key == 's') {
      if (CurrentDomain != SettingsDomain) {
        ChangeDomain(SettingsDomain);
      }
      else {
        ChangeDomain(OldDomain);
      }
    }
    if (key == 'U' || key == 'u') {
      PlugTestFlag = !PlugTestFlag;
      if (PlugTestFlag) {
        PlugTestDelay = 10;
      }
      else if (!PlugTestFlag) {
        PlugTestDelay = 0;
      }
      UpdateSettings();
    }
    if (key == 'z' || key == 'Z') {
      UserFreqCustom = 750;
      UpdateSettings();
    }
    if (key == 'i' || key == 'I') {
      BitDepth10 = !BitDepth10;
      println("BitDepth10 = "+BitDepth10);
      UpdateSettings();
    }
    if (key == 'R' || key == 'r') {
      ResetSerialConnection();
    }
    if (key == 'H' || key == 'h') {
      if (CurrentDomain != HelpDomain) {
        ChangeDomain(HelpDomain);
      }
      else {
        ChangeDomain(OldDomain);
      }
    }
    if (key == 'P' || key == 'p') {
      PauseFlag = !PauseFlag;
      GetPageButtons();
    }
    if (key == 'C' || key == 'c') {
      datacounter = 0;
      xPos = 0;
      blankplot();
      labelaxes();
      println("Plot Cleared");
    }
    if (key == 'O' || key == 'o') {
      OffSetFlag = !OffSetFlag;
      ClearYAxis();
      labelaxes();
      GetPageButtons();
    }
    if ((key == 'J' || key == 'j')&&CurrentDomain==TimeDomain) {
      SmoothFilterFlag = !SmoothFilterFlag;
      if (SmoothFilterFlag) {
        DownSampleCount = 10;
        BitDepth10 = false;
      }
      else {
        DownSampleCount = 1;
        BitDepth10 = true;
      }
      GetPageButtons();
      UpdateSettings();
    }
    // if (CurrentDomain == TrainingDomain) {
    // if (key == 'Q' || key == 'q') {
    // if (TrainingMode == TRepCounter) {
    // TrainingMode = TDataLogger;
    // }
    // else if (TrainingMode == TDataLogger) {
    // TrainingMode = TRepCounter;
    // }
    // resetWorkout();
    // }
    // }
    if (CurrentDomain == MouseDomain) {
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
      }
      // Switch axis - which (x or y) is controlled. True = Y
      // if (key == 'S' || key == 's') {
      // if (MouseAxis == 'X') {
      // MouseAxis = 'Y';
      // println("MouseAxis Flipped. Axis = Y");
      // }
      // else if (MouseAxis == 'Y') {
      // MouseAxis = 'X';
      // println("MouseAxis Flipped. Axis = X");
      // }
      // }
      if (key == 'K' || key == 'k') {
        MouseTuneFlag = !MouseTuneFlag;
        if (!MouseTuneFlag) {
          drawTarget();
          GamenextStep = second()+GamedelayTime;
          println(GamenextStep);
          GameScore = 0;
        }
      }
      if (key == 'G' || key == 'g') {
        if (!snakeGameFlag) {
          int foodsize = 30;
          int gamespeed = 5;
          snakeGameFlag = true;
          mySnakeGame = new SnakeGame(this, xStep+plotwidth/2, yTitle+plotheight/2, plotwidth, plotheight, foodsize, gamespeed);
        } 
        else if (snakeGameFlag) {
          snakeGameFlag = false;
          mySnakeGame = null;
          drawTarget();
          GamenextStep = second()+GamedelayTime;
          println(GamenextStep);
          GameScore = 0;
        }
      }
      if (snakeGameFlag) {
        mySnakeGame.keyInput(key, keyCode);
        // if (key == CODED){
        // mySnakeGame.keyInput(key,keyCode);
        // }
        // else if (key == 'N' || key == 'n'){
        // mySnakeGame.resetSnakeGame();
        // }
      }
      if (MouseTuneFlag) {
        if (key == CODED) {
          if (keyCode == LEFT) {
            MouseThreshInd --;
            if (MouseThreshInd < 0) {
              MouseThreshInd = 3;
            }
          }
          else if (keyCode == RIGHT) {
            MouseThreshInd ++;
            if (MouseThreshInd > 3) {
              MouseThreshInd = 0;
            }
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
          }
          println("New MouseThresh = "+MouseThresh[MouseThreshInd]);
        }
      }
    }
  }

  // Restore fill and stroke settings
  fill(tmpfillColor);
  stroke(tmpstrokeColor);
  strokeWeight(tmpstrokeWeight);
}


// Mouse Button Handling Section
void mousePressed() {

  // Store current fill and stroke settings
  int tmpfillColor = g.fillColor;
  int tmpstrokeColor = g.strokeColor;
  float tmpstrokeWeight = g.strokeWeight;

  currentbutton = -1;
  println("mouse pressed");
  if (mouseButton == LEFT) {
    int x = mouseX, y = mouseY;
    // Help Page Handler - exit on any click or key
    if (CurrentDomain == HelpDomain) {
      ChangeDomain(OldDomain);
    }
    // Settings Page Handler
    else if (CurrentDomain == SettingsDomain) {
      for (int i = 0; i < buttonsSP.length; i++) {
        if (buttonsSP[i] != null) {
          if (buttonsSP[i].IsMouseOver(x, y)) {
            println("current button about to be " + i);
            buttonsSP[i].BOn = !buttonsSP[i].BOn;
            buttonsSP[i].ChangeColorPressed();
            currentbutton = i;
            ButtonColorTimer = millis()+ButtonColorDelay;
            ButtonPressedFlag = true;
          }
        }
      }
      if (currentbutton == BSPfolder) {
        println("getting folder");
        waitForFolder();
        println(folder);
      }
      if (currentbutton == BSPfrequp) {
        UserFreqIndexTmp++;
        if (UserFreqIndexTmp >= UserFreqArray.length)UserFreqIndexTmp=UserFreqArray.length-1;
        println(UserFreqIndexTmp);
        UserFrequencyTmp = UserFreqArray[UserFreqIndexTmp];
      }
      if (currentbutton == BSPfreqdown) {
        UserFreqIndexTmp--;
        if (UserFreqIndexTmp < 0)UserFreqIndexTmp=0;
        println(UserFreqIndexTmp);
        UserFrequencyTmp = UserFreqArray[UserFreqIndexTmp];
      }
      if (currentbutton == BSPfiltup) {
        SmoothFilterValTmp++;
        if (SmoothFilterValTmp > SmoothFilterValMax) SmoothFilterValTmp = SmoothFilterValMax;
      }
      if (currentbutton == BSPfiltdown) {
        SmoothFilterValTmp--;
        if (SmoothFilterValTmp < SmoothFilterValMin) SmoothFilterValTmp = SmoothFilterValMin;
      }
      if (currentbutton == BSPdownsampleup) {
        DownSampleCountTmp++;
        if (DownSampleCountTmp > DownSampleCountMax) DownSampleCountTmp = DownSampleCountMax;
      }
      if (currentbutton == BSPdownsampledown) {
        DownSampleCountTmp--;
        if (DownSampleCountTmp < DownSampleCountMin) DownSampleCountTmp = DownSampleCountMin;
      }
      if (currentbutton == BSPtimeradjustup) {
        Timer0AdjustValTmp++;
        if (Timer0AdjustValTmp > Timer0AdjustValMax) Timer0AdjustValTmp = Timer0AdjustValMax;
      }
      if (currentbutton == BSPtimeradjustdown) {
        Timer0AdjustValTmp--;
        if (Timer0AdjustValTmp < Timer0AdjustValMin) Timer0AdjustValTmp = Timer0AdjustValMin;
      }
      if (currentbutton == BSPprescalerup) {
        PrescalerTmp++;
        if (PrescalerTmp > PrescalerMax) PrescalerTmp = PrescalerMax;
      }
      if (currentbutton == BSPprescalerdown) {
        PrescalerTmp--;
        if (PrescalerTmp < PrescalerMin) PrescalerTmp = PrescalerMin;
      }
      if (currentbutton == BSPrecordtimeup) {
        DataRecordTimeTmp++;
        if (DataRecordTimeTmp > DataRecordTimeMax) DataRecordTimeTmp = DataRecordTimeMax;
      }
      if (currentbutton == BSPrecordtimedown) {
        DataRecordTimeTmp--;
        if (DataRecordTimeTmp < DataRecordTimeMin) DataRecordTimeTmp = DataRecordTimeMin;
      }
      if (currentbutton == BSP1chan) {
        SignalNumberTmp = 1;
        buttonsSP[BSP1chan].BOn = false;
        buttonsSP[BSP2chan].BOn = false;
        buttonsSP[BSP4chan].BOn = false;
        buttonsSP[BSP8chan].BOn = false;
        buttonsSP[currentbutton].BOn = true;
      }
      if (currentbutton == BSP2chan) {
        SignalNumberTmp = 2;
        buttonsSP[BSP1chan].BOn = false;
        buttonsSP[BSP2chan].BOn = false;
        buttonsSP[BSP4chan].BOn = false;
        buttonsSP[BSP8chan].BOn = false;
        buttonsSP[currentbutton].BOn = true;
      }
      if (currentbutton == BSP4chan) {
        SignalNumberTmp = 4;
        buttonsSP[BSP1chan].BOn = false;
        buttonsSP[BSP2chan].BOn = false;
        buttonsSP[BSP4chan].BOn = false;
        buttonsSP[BSP8chan].BOn = false;
        buttonsSP[currentbutton].BOn = true;
      }
      if (currentbutton == BSP8chan) {
        SignalNumberTmp = 8;
        buttonsSP[BSP1chan].BOn = false;
        buttonsSP[BSP2chan].BOn = false;
        buttonsSP[BSP4chan].BOn = false;
        buttonsSP[BSP8chan].BOn = false;
        buttonsSP[currentbutton].BOn = true;
      }
      if (currentbutton == BSPsave) {
        saveSettings();
        ChangeDomain(OldDomain);
        buttonsSP[currentbutton].BOn = false;
        return;
      }
      if (currentbutton == BSPcancel) {
        ChangeDomain(OldDomain);
        buttonsSP[currentbutton].BOn = false;
        return;
      }
      DrawSettings();
    }
    // TimeDomain/FreqDomain handler (basically the same button set)
    else if (CurrentDomain == TimeDomain) {
      for (int i = 0; i < buttonsTDP.length; i++) {
        if (buttonsTDP[i].IsMouseOver(x, y)) {
          buttonsTDP[i].BOn = !buttonsTDP[i].BOn;
          buttonsTDP[i].ChangeColorPressed();
          currentbutton = i;
          ButtonColorTimer = millis()+ButtonColorDelay;
          ButtonPressedFlag = true;
        }
      }
      if (currentbutton == BTDPsettings) {
        ChangeDomain(SettingsDomain);
      }
      if (currentbutton == BTDPhelp) {
        ChangeDomain(HelpDomain);
      }
      if (currentbutton == BTDPtimedomain) {
        ChangeDomain(TimeDomain);
      }
      if (currentbutton == BTDPfreqdomain) {
        ChangeDomain(FreqDomain);
      }
      if (currentbutton == BTDPtraindomain) {
        ChangeDomain(TrainingDomain);
      }
      if (currentbutton == BTDPmousedomain) {
        ChangeDomain(MouseDomain);
      }

      if (currentbutton == BTDPserialreset) {
        ResetSerialConnection();
      }
      if (currentbutton == BTDPrecordnextdata) {
        DataRecordFlag = true;
        println("UserFreq = "+UserFrequency+", DataRecordTime = "+DataRecordTime);
        DataRecordLength = DataRecordTime*UserFrequency;
        DataRecord = new int[DataRecordCols][DataRecordLength];
        DataRecordIndex = 0;
      }
      if (currentbutton == BTDPoffset) {
        OffSetFlag = !OffSetFlag;
        ClearYAxis();
        labelaxes();
        println("OffSet Changed");
      }
      if (currentbutton == BTDPsmooth) {
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
        labelaxes();
        println("Smoothing Toggled");
      }
      if (currentbutton == BTDPclear) {
        datacounter = 0;
        xPos = 0;
        blankplot();
        labelaxes();
        println("Plot Cleared");
      }
      if (currentbutton == BTDPpause) {
        PauseFlag = !PauseFlag;
        if (!PauseFlag) {
          buttonsTDP[currentbutton].label = "Pause";
          buttonsTDP[currentbutton].DrawButton();
          datacounter = 0;
          xPos = 0;
          labelaxes();
        }
        else if (PauseFlag) {
          buttonsTDP[currentbutton].label = "Play";
          buttonsTDP[currentbutton].DrawButton();
        }
        println("Pause Toggled");
      }
      if (currentbutton == BTDPsave) {
        imagesavecounter = saveImage(imagesavecounter);
        println(imagesavecounter);
      }
      if (currentbutton == BTDPchan1) {
        ChannelOn[0] = !ChannelOn[0];
        println("Chan1 Toggled");
      }
      if (currentbutton == BTDPchan2) {
        ChannelOn[1] = !ChannelOn[1];
        println("Chan2 Toggled");
      }
      if (currentbutton == BTDPchan3) {
        ChannelOn[2] = !ChannelOn[2];
        println("Chan3 Toggled");
      }
      if (currentbutton == BTDPchan4) {
        ChannelOn[3] = !ChannelOn[3];
        println("Chan4 Toggled");
      }
      if (currentbutton == BTDPchan5) {
        ChannelOn[4] = !ChannelOn[4];
        println("Chan4 Toggled");
      }
      if (currentbutton == BTDPchan6) {
        ChannelOn[5] = !ChannelOn[5];
        println("Chan4 Toggled");
      }
      if (currentbutton == BTDPchan7) {
        ChannelOn[6] = !ChannelOn[6];
        println("Chan4 Toggled");
      }
      if (currentbutton == BTDPchan8) {
        ChannelOn[7] = !ChannelOn[7];
        println("Chan4 Toggled");
      }
    }
    // Frequency Domain
    else if (CurrentDomain == FreqDomain) {
      for (int i = 0; i < buttonsFDP.length; i++) {
        if (buttonsFDP[i].IsMouseOver(x, y)) {
          buttonsFDP[i].BOn = !buttonsFDP[i].BOn;
          buttonsFDP[i].ChangeColorPressed();
          currentbutton = i;
          ButtonColorTimer = millis()+ButtonColorDelay;
          ButtonPressedFlag = true;
        }
      }
      if (currentbutton == BFDPsettings) {
        ChangeDomain(SettingsDomain);
        println("Settings Menu");
      }
      if (currentbutton == BFDPhelp) {
        ChangeDomain(HelpDomain);
      }
      // if (currentbutton == BFDPtimedomain){ChangeDomain(TimeDomain);}
      if (currentbutton == BFDPfreqdomain) {
        ChangeDomain(TimeDomain);
      }
      if (currentbutton == BFDPtraindomain) {
        ChangeDomain(TrainingDomain);
      }
      if (currentbutton == BFDPmousedomain) {
        ChangeDomain(MouseDomain);
      }
      if (currentbutton == BFDPserialreset) {
        ResetSerialConnection();
      }
      if (currentbutton == BFDPrecordnextdata) {
        DataRecordFlag = true;
        DataRecordLength = DataRecordTime*UserFrequency;
        DataRecord = new int[DataRecordCols][DataRecordLength];
        DataRecordIndex = 0;
      }
      if (currentbutton == BFDPoffset) {
        OffSetFlag = !OffSetFlag;
        ClearYAxis();
        labelaxes();
        println("OffSet Changed");
      }
      if (currentbutton == BFDPpause) {
        PauseFlag = !PauseFlag;
        if (!PauseFlag) {
          buttonsFDP[currentbutton].label = "Pause";
          buttonsFDP[currentbutton].DrawButton();
          if (CurrentDomain == TimeDomain) {
            if (ScrollMode == SMtrace) {
              datacounter = 0;
              xPos = 0;
              labelaxes();
            }
          }
        }
        else if (PauseFlag) {
          buttonsFDP[currentbutton].label = "Play";
          buttonsFDP[currentbutton].DrawButton();
        }
        println("Pause Toggled");
      }
      if (currentbutton == BFDPsave) {
        imagesavecounter = saveImage(imagesavecounter);
        println(imagesavecounter);
      }
      if (currentbutton == BFDPchan1) {
        ChannelOn[0] = !ChannelOn[0];
        println("Chan1 Toggled");
      }
      if (currentbutton == BFDPchan2) {
        ChannelOn[1] = !ChannelOn[1];
        println("Chan2 Toggled");
      }
      if (currentbutton == BFDPchan3) {
        ChannelOn[2] = !ChannelOn[2];
        println("Chan3 Toggled");
      }
      if (currentbutton == BFDPchan4) {
        ChannelOn[3] = !ChannelOn[3];
        println("Chan4 Toggled");
      }
      if (currentbutton == BFDPchan5) {
        ChannelOn[4] = !ChannelOn[4];
        println("Chan4 Toggled");
      }
      if (currentbutton == BFDPchan6) {
        ChannelOn[5] = !ChannelOn[5];
        println("Chan4 Toggled");
      }
      if (currentbutton == BFDPchan7) {
        ChannelOn[6] = !ChannelOn[6];
        println("Chan4 Toggled");
      }
      if (currentbutton == BFDPchan8) {
        ChannelOn[7] = !ChannelOn[7];
        println("Chan4 Toggled");
      }
    }
    // Training Domain Handler
    else if (CurrentDomain == TrainingDomain) {
      for (int i = 0; i < buttonsTP.length; i++) {
        if (buttonsTP[i] != null) {
          if (buttonsTP[i].IsMouseOver(x, y)) {
            buttonsTP[i].BOn = !buttonsTP[i].BOn;
            buttonsTP[i].ChangeColorPressed();
            currentbutton = i;
            ButtonColorTimer = millis()+ButtonColorDelay;
            ButtonPressedFlag = true;
          }
        }
      }
      if (currentbutton == BTPsettings) {
        ChangeDomain(SettingsDomain);
        println("Settings Menu");
      }
      else if (currentbutton == BTPhelp) {
        ChangeDomain(HelpDomain);
      }
      // if (currentbutton == BTPclear) {
      // datacounter = 0;
      // xPos = 0;
      // blankplot();
      // labelaxes();
      // println("Plot Cleared");
      // }
      if (currentbutton == BTPtimedomain) {
        ChangeDomain(TimeDomain);
      }
      if (currentbutton == BTPfreqdomain) {
        ChangeDomain(FreqDomain);
      }
      if (currentbutton == BTPtraindomain) {
        ChangeDomain(TrainingDomain);
      }
      if (currentbutton == BTPmousedomain) {
        ChangeDomain(MouseDomain);
      }
      if (currentbutton == BTPserialreset) {
        ResetSerialConnection();
      }
      if (currentbutton == BTPrecordnextdata) {
        DataRecordFlag = true;
        DataRecordLength = DataRecordTime*UserFrequency;
        DataRecord = new int[DataRecordCols][DataRecordLength];
        DataRecordIndex = 0;
      }
      // if (currentbutton == BTPpause) {
      // PauseFlag = !PauseFlag;
      // if (!PauseFlag) {
      // buttonsTP[currentbutton].label = "Pause";
      // buttonsTP[currentbutton].DrawButton();
      // if (CurrentDomain == TimeDomain) {
      // if (ScrollMode == SMtrace) {
      // datacounter = 0;
      // xPos = 0;
      // labelaxes();
      // }
      // }
      // }
      // else if (PauseFlag) {
      // buttonsTP[currentbutton].label = "Play";
      // buttonsTP[currentbutton].DrawButton();
      // }
      // println("Pause Toggled");
      // }
      if (currentbutton == BTPsave) {
        imagesavecounter = saveImage(imagesavecounter);
        println(imagesavecounter);
      }
      if (currentbutton == BTPreset) {
        resetWorkout();
      }
      if (currentbutton == BTPsetReps1 || currentbutton == BTPsetReps2 || currentbutton == BTPchan1name || currentbutton == BTPchan2name) {
        if (NameNumber == currentbutton) {
          int tmpint = 0;
          savedname = typing;
          if (NameNumber == BTPsetReps1 || NameNumber == BTPsetReps2) {
            tmpint = getIntFromString(typing, RepsTargetDefault);
            savedname = str(tmpint);
          }
          println(tmpint);
          buttonsTP[NameNumber].label = savedname;
          if (NameNumber == BTPsetReps1) {
            RepsTarget[0] = tmpint;
            println("int saved");
            println(RepsTarget[0]);
            ClearRepBar(1);
            LabelRepBar(1);
          }
          else if (NameNumber == BTPsetReps2) {
            RepsTarget[1] = tmpint;
            println("int saved");
            println(RepsTarget[0]);
            ClearRepBar(2);
            LabelRepBar(2);
          }

          NamesFlag = !NamesFlag;
          //buttonsTP[currentbutton].BOn = !buttonsTP[currentbutton].BOn;

          buttonsTP[NameNumber].DrawButton();
          typing = "";
          NameNumber = -1;
        }
        else {
          NameNumber = currentbutton;
          NamesFlag = true;
          buttonsTP[currentbutton].BOn = true;
          typing = "";
          buttonsTP[NameNumber].label = typing;
          buttonsTP[NameNumber].DrawButton();
        }
        println("Names Toggled");
      }
      if (currentbutton == BTPchan1) {
        ChannelOn[0] = !ChannelOn[0];
        println("Chan1 Toggled");
      }
      if (currentbutton == BTPchan2) {
        ChannelOn[1] = !ChannelOn[1];
        println("Chan2 Toggled");
      }
      if (currentbutton == BTPchan1up) {
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
        buttonsTP[BTPchan1].ctext = SigColorM[TrainChan[0]];
        buttonsTP[BTPchan1].label = str(TrainChan[0]+1);
        buttonsTP[BTPchan1].DrawButton();
        ChannelOn[TrainChan[0]] = buttonsTP[BTPchan1].BOn;
      }
      if (currentbutton == BTPchan1down) {
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
        buttonsTP[BTPchan1].ctext = SigColorM[TrainChan[0]];
        buttonsTP[BTPchan1].label = str(TrainChan[0]+1);
        buttonsTP[BTPchan1].DrawButton();
        ChannelOn[TrainChan[0]] = buttonsTP[BTPchan1].BOn;
      }
      if (currentbutton == BTPchan2up) {
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
        buttonsTP[BTPchan2].ctext = SigColorM[TrainChan[1]];
        buttonsTP[BTPchan2].label = str(TrainChan[1]+1);
        buttonsTP[BTPchan2].DrawButton();
        ChannelOn[TrainChan[1]] = buttonsTP[BTPchan2].BOn;
      }
      if (currentbutton == BTPchan2down) {
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
        buttonsTP[BTPchan2].ctext = SigColorM[TrainChan[1]];
        buttonsTP[BTPchan2].label = str(TrainChan[1]+1);
        buttonsTP[BTPchan2].DrawButton();
        ChannelOn[TrainChan[1]] = buttonsTP[BTPchan2].BOn;
      }
      if (currentbutton == BTPthresh1up) {
        RepThresh[0]+=RepThreshStep;
        if (RepThresh[0]>=MaxSignalVal) {
          RepThresh[0]=MaxSignalVal;
        }
      }
      if (currentbutton == BTPthresh1down) {
        RepThresh[0]-=RepThreshStep;
        if (RepThresh[0]<0) {
          RepThresh[0]=0;
        }
      }
      if (currentbutton == BTPthresh2up) {
        RepThresh[1]+=RepThreshStep;
        if (RepThresh[1]>=MaxSignalVal) {
          RepThresh[1]=MaxSignalVal;
        }
      }
      if (currentbutton == BTPthresh2down) {
        RepThresh[1]-=RepThreshStep;
        if (RepThresh[1]<0) {
          RepThresh[1]=0;
        }
      }
    }
    // Mouse Domain
    else if (CurrentDomain == MouseDomain) {
      for (int i = 0; i < buttonsMP.length; i++) {
        if (buttonsMP[i] != null) {
          if (buttonsMP[i].IsMouseOver(x, y)) {
            buttonsMP[i].BOn = !buttonsMP[i].BOn;
            buttonsMP[i].ChangeColorPressed();
            currentbutton = i;
            ButtonColorTimer = millis()+ButtonColorDelay;
            ButtonPressedFlag = true;
          }
        }
      }
      if (currentbutton == BMPsettings) {
        ChangeDomain(SettingsDomain);
        println("Settings Menu");
      }
      else if (currentbutton == BMPhelp) {
        ChangeDomain(HelpDomain);
      }
      if (currentbutton == BMPtimedomain) {
        ChangeDomain(TimeDomain);
      }
      // if (currentbutton == BMPfreqdomain){ChangeDomain(FreqDomain);}
      if (currentbutton == BMPtraindomain) {
        ChangeDomain(TrainingDomain);
      }
      if (currentbutton == BMPmousedomain) {
        ChangeDomain(MouseDomain);
      }
      if (currentbutton == BMPserialreset) {
        ResetSerialConnection();
      }
      // // TODO - add record video button?
      // if (currentbutton == BMPrecordnextdata){
      // DataRecordFlag = true;
      // DataRecordLength = DataRecordTime*UserFrequency;
      // DataRecord = new int[DataRecordCols][DataRecordLength];
      // DataRecordIndex = 0;
      // }
      if (currentbutton == BMPclear) {
        blankplot();
        labelaxes();
        println("Plot Cleared");
      }
      if (currentbutton == BMPpause) {
        PauseFlag = !PauseFlag;
        if (!PauseFlag) {
          buttonsMP[currentbutton].label = "Pause";
          buttonsMP[currentbutton].DrawButton();
        }
        else if (PauseFlag) {
          buttonsMP[currentbutton].label = "Play";
          buttonsMP[currentbutton].DrawButton();
        }
        println("Pause Toggled");
      }
      if (currentbutton == BMPsave) {
        imagesavecounter = saveImage(imagesavecounter);
        println(imagesavecounter);
      }
      if (currentbutton == BMPchan1up) {
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
        buttonsMP[BMPchan1].ctext = SigColorM[MouseChan[0]];
        buttonsMP[BMPchan1].label = str(MouseChan[0]+1);
        buttonsMP[BMPchan1].DrawButton();
        ChannelOn[MouseChan[0]] = buttonsMP[BMPchan1].BOn;
      }
      if (currentbutton == BMPchan1down) {
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
        buttonsMP[BMPchan1].ctext = SigColorM[MouseChan[0]];
        buttonsMP[BMPchan1].label = str(MouseChan[0]+1);
        buttonsMP[BMPchan1].DrawButton();
        ChannelOn[MouseChan[0]] = buttonsMP[BMPchan1].BOn;
      }
      if (currentbutton == BMPchan2up) {
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
        buttonsMP[BMPchan2].ctext = SigColorM[MouseChan[1]];
        buttonsMP[BMPchan2].label = str(MouseChan[1]+1);
        buttonsMP[BMPchan2].DrawButton();
        ChannelOn[MouseChan[1]] = buttonsMP[BMPchan2].BOn;
      }
      if (currentbutton == BMPchan2down) {
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
        buttonsMP[BMPchan2].ctext = SigColorM[MouseChan[1]];
        buttonsMP[BMPchan2].label = str(MouseChan[1]+1);
        buttonsMP[BMPchan2].DrawButton();
        ChannelOn[MouseChan[1]] = buttonsMP[BMPchan2].BOn;
      }
    }
    x = 0;
    y = 0;
  }

  // Restore fill and stroke settings
  fill(tmpfillColor);
  stroke(tmpstrokeColor);
  strokeWeight(tmpstrokeWeight);
}

void MoveMouse(int tmpind) {
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

// End of mouse handling section



//void drawdata(int inVal) {
// //stroke(plotlinecolor);
// point(xPos+xStep, inVal);
// fill(0);
// stroke(255);
//}

void DrawTrace() {
  // println("datacounter = "+datacounter);
  int sigtmp = 0;
  // strokeWeight(pointThickness*2);
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
        // Training Domain!!
        if (CurrentDomain == TrainingDomain && (j == TrainChan[0] || j == TrainChan[1])) {
          int tmpind = signalindex-datacounter;//*DownSampleCount;
          while (tmpind < 0) {
            tmpind+=MaxSignalLength;
          }
          if (j == TrainChan[0]) {
            sigtmp = int(map((signalIn[j][tmpind]+Calibration[j] - HalfSignalVal)*VoltScale, 0, MaxSignalVal, plotheight/2, plotheight));
            sigtmp = constrain(sigtmp, plotheight/2+pointThickness+1, plotheight-pointThickness-1);
            // oldPlotSignal[j] = constrain(oldPlotSignal[j],plotheight/2 + pointThickness, plotheight-pointThickness);
          }
          if (j==TrainChan[1]) {
            sigtmp = int(map((signalIn[j][tmpind]+Calibration[j] - HalfSignalVal)*VoltScale, 0, MaxSignalVal, 0, plotheight/2));
            sigtmp = constrain(sigtmp, pointThickness+1, plotheight/2 - pointThickness-1)-plot2offset;
            // oldPlotSignal[j] = constrain(oldPlotSignal[j],pointThickness,plotheight/2-pointThickness);
          }
          drawMyLine(xPos+xStep-1, ytmp - oldPlotSignal[j], xPos+xStep, ytmp - sigtmp, SigColorM[j], pointThickness);
          oldPlotSignal[j] = sigtmp;
        }
        else if (CurrentDomain==TimeDomain) {
          int tmpind = signalindex-datacounter;//*DownSampleCount;
          while (tmpind < 0) {
            tmpind+=MaxSignalLength;
          }
          if (!OffSetFlag) {
            sigtmp = int(map((signalIn[j][tmpind]+Calibration[j]-HalfSignalVal)*VoltScale, -MaxSignalVal, +MaxSignalVal, 0, plotheight));
          }
          else {
            sigtmp = OffSet[j]+int(map((signalIn[j][tmpind]+Calibration[j]-HalfSignalVal)*VoltScale, -MaxSignalVal, +MaxSignalVal, -plotheight/(2*SignalNumber), plotheight/(2*SignalNumber)));//*VoltScale)-plotheight*3/2);
          }
          sigtmp = constrain( sigtmp, pointThickness, plotheight - pointThickness);
          // sigtmp = max(min(sigtmp,plotheight-pointThickness),0+pointThickness);
          drawMyLine(xPos+xStep-1, ytmp - oldPlotSignal[j], xPos+xStep, ytmp - sigtmp, SigColorM[j], pointThickness);
          oldPlotSignal[j] = sigtmp;
        }
      }
    }
    datacounter --;
  }
  updatePixels();
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
  // x = constrain(x,XMIN,XMAX);
  // y = constrain(y,YMIN,YMAX);
  // if (x < XMIN || x >= XMAX) return;
  // if (y < YMIN || y >= YMAX) return;
  // int N = 4;
  // for (int j = y-N; j<=y+N;j++){
  // pixels[x + j * width] = c;
  // }
  pixels[x + y * width] = c;
}

int FFTstep = 2;
void DrawFFT() {
  blankplot();
  stroke(FFTcolor);
  // filtered=filter1.apply(signalIn);
  // filtered = signalIn1;
  for (int j = 0; j < SignalNumber; j++) {
    System.arraycopy(fft.computeFFT(FFTsignalIn[j]), 0, fft_result[j], 0, FFTSignalLength/2);
  }
  for (int i = 2; i<min(fft.WS2/FreqFactor,plotwidth/FreqFactor); i++) {
    // for (int i = 2; i<min(fft.WS2/FreqFactor,plotwidth/2); i++) {
    int xtmp = xStep+FreqFactor*(i-1);
    // int xtmp = xStep+2*i-2;
    for (int j = 0; j < SignalNumber;j++) {
      if (ChannelOn[j]) {
        stroke(SigColorM[j]);
        if (OffSetFlag) {
          if (ChannelOn[4] || ChannelOn[5] || ChannelOn[6] || ChannelOn[7]) {
            for (int k = 0; k < FreqFactor; k++) {
              line(xtmp+k, ytmp - FFTstep - OffSetFFT8[j], xtmp+k, min(ytmp-FFTstep-OffSetFFT8[j], max(yTitle+2+OffSetFFT8[7-j], ytmp - OffSetFFT8[j] - int(FFTscale*fft_result[j][i])/8)) );
            }
          }
          else if (ChannelOn[3] || ChannelOn[2]) {
            for (int k = 0; k < FreqFactor; k++) {
              line(xtmp+k, ytmp - FFTstep - OffSetFFT4[j], xtmp+k, min(ytmp-FFTstep-OffSetFFT4[j], max(yTitle+2+OffSetFFT4[3-j], ytmp - OffSetFFT4[j] - int(FFTscale*fft_result[j][i])/4)) );
            }
          }
          else {
            for (int k = 0; k < FreqFactor; k++) {
              line(xtmp+k, ytmp - FFTstep - OffSetFFT2[j], xtmp+k, min(ytmp-FFTstep-OffSetFFT2[j], max(yTitle+2+OffSetFFT2[1-j], ytmp - OffSetFFT4[j] - int(FFTscale*fft_result[j][i])/2)) );
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

void DrawSettings() {
  textAlign(CENTER, CENTER);
  blankplot();
  stroke(0);
  strokeWeight(4);
  fill(200);
  rectMode(CENTER);
  rect(width/2, height/2, FullPlotWidth+20, plotheight+40, 12);

  strokeWeight(2);
  textSize(labelsizexs);
  textAlign(CENTER, CENTER);
  fill(200);
  rect(width/2-90, height/2-90, 300, Bheights);
  if (int(textWidth(folderTmp)) < 300) {
    fill(0);
    text(folderTmp, width/2-90, height/2-90);
  }
  else if (textWidth(folderTmp) >= 450) {
    fill(200);
    rect(width/2-90, height/2-70, 300, Bheights);
    fill(0);
    text(folderTmp, width/2-90, height/2-80, 300, Bheights*2);
  }


  fill(0);
  textSize(titlesize);
  text("FlexVolt Settings Menu", width/2, height/2-plotheight/2);

  textSize(labelsizes);
  text("Saving Data & Images", width/2, height/2-115);
  textSize(labelsizexs);
  text("Directory", width/2-340, height/2-175);

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


  for (int i = 0; i < buttonsSP.length; i++) {
    if (buttonsSP[i] != null) {
      buttonsSP[i].DrawButton();
    }
  }
}

void DrawHelp() {
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

void DrawMouseGame() {
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
      MoveMouse(tmpind);
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
      MoveMouse(tmpind);
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


void DrawTrainingProgram() {
  DrawTrace();
  DrawThresh();
  if (TrainingMode == TRepCounter) {
    CountReps();
    DrawRepBar();
  }
  // else if (TrainingMode == TDataLogger) {
  // TLogData();
  // DrawTData();
  // }
}

void DrawThresh() {
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

void DrawTData() {

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

void ClearYAxis() {
  fill(backgroundcolor);
  stroke(backgroundcolor);
  rectMode(CENTER);
  // stroke(0);
  rect(xStep/2, yTitle+plotheight/2, xStep, plotheight);
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

void DrawRepBar() {
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
      text(buttonsTP[BTPchan1].label, plotwidth+260, yTitle+20);
    }
  }
  if (ChanN == 2 || ChanN == 3) {
    if (ChannelOn[TrainChan[1]]) {
      val = 0;
      for (int i = 0; i <= RepsTarget[1]; i++) {
        text(nf(val, 1, 0), plotwidth+320, ytmp - 20 - int(map(val, 0, RepsTarget[1], 0, plotheight-60)));
        val ++;
      }
      text(buttonsTP[BTPchan2].label, plotwidth+360, yTitle+20);
    }
  }
}

void blankplot() {
  fill(plotbackground);
  stroke(plotoutline);
  strokeWeight(2);
  rectMode(CENTER);
  if (CurrentDomain == TimeDomain || CurrentDomain == FreqDomain || CurrentDomain == MouseDomain) {
    rect(xStep+plotwidth/2, yTitle+plotheight/2, plotwidth, plotheight);
  }
  if (CurrentDomain == TrainingDomain) {
    rect(xStep+plotwidth/2, yTitle+(plotheight/2)/2, plotwidth, plotheight/2);
    rect(xStep+plotwidth/2, yTitle+plotheight/2+5+(plotheight/2)/2, plotwidth, plotheight/2);
  }
  rectMode(CENTER);
}

void drawConnectionIndicator() {
  fill(150);
  strokeWeight(2);
  stroke(0);
  ellipse(xStep+FullPlotWidth+10, yTitle-26, 24, 24);
  if (FVserial.connectionindicator == FVserial.indicator_connected) {
    fill(color(0, 255, 0));
  }
  else if (FVserial.connectionindicator == FVserial.indicator_connecting) {
    fill(color(255, 200, 0));
  }
  else if (FVserial.connectionindicator == FVserial.indicator_noconnection) {
    fill(color(255, 0, 0));
  }
  stroke(0);
  ellipse(xStep+FullPlotWidth+10, yTitle-26, 14, 14);
}

void labelaxes() {

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
  stroke(labelcolor);
  strokeWeight(2);
  textAlign(CENTER, CENTER);
  if (CurrentDomain == TimeDomain) {
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


    for (int i = 0; i < buttonsTDP.length; i++) {
      buttonsTDP[i].DrawButton();
    }

    textSize(labelsize);
    text("Channel", xStep+FullPlotWidth+45, yTitle+165);
    text("Plotting", xStep+FullPlotWidth+45, yTitle+10);
    textSize(labelsizes);
    text("Connection", xStep+FullPlotWidth+45, yTitle-50);
    drawConnectionIndicator();
  }
  else if (CurrentDomain == FreqDomain) {
    // title
    textSize(titlesize);
    text("Signal Frequency", xStep+FullPlotWidth/2+20, yTitle-45);

    textSize(axisnumbersize);
    // x-axis
    float val = 0;
    FreqMax = UserFrequency/(MaxSignalLength/plotwidth)/FreqFactor;
    for (int i = 0; i < Nxticks+1; i++) {
      text(nf(val, 1, 0), xStep+int(map(val, 0, FreqMax, 0, plotwidth-20)), height-yStep+10);
      val += FreqMax/Nxticks;
    }

    // y-axis
    // if (OffSetFlag) {
    // val = FreqAmpMin;
    // for (int i = 0; i < Nyticks+1; i++) {
    // text(nf(val, 1, 1), xStep-30, height - yStep +0 - int(map(val, FreqAmpMin, FreqAmpMax, 0, plotheight/2-20)));
    // text(nf(val, 1, 1), xStep-30, height - yStep -plotheight/2 -20 +10 - int(map(val, FreqAmpMin, FreqAmpMax, 0, plotheight/2-20)));
    // println("etst");
    // val += (FreqAmpMax-FreqAmpMin)/Nyticks;
    // }
    // }
    // else {
    // val = FreqAmpMin;
    // for (int i = 0; i < Nyticks+1; i++) {
    // text(nf(val, 1, 1), xStep-30, height - yStep +0 - int(map(val, FreqAmpMin, FreqAmpMax, 0, plotheight-20)));
    // val += (FreqAmpMax-FreqAmpMin)/Nyticks;
    // }
    // }

    // axis labels
    textSize(labelsizes);
    translate(40, height/2);
    rotate(-PI/2);
    text("Intensity, a.u.", 0, 0);
    rotate(PI/2);
    translate(-40, -height/2);
    text("Frequency, Hz", xStep + plotwidth/2, height-20);

    // blankplot();
    for (int i = 0; i < buttonsFDP.length; i++) {
      buttonsFDP[i].DrawButton();
    }

    textSize(labelsize);
    text("Channel", xStep+FullPlotWidth+45, yTitle+165);
    text("Plotting", xStep+FullPlotWidth+45, yTitle+10);
    textSize(labelsizes);
    text("Connection", xStep+FullPlotWidth+45, yTitle-50);
    drawConnectionIndicator();
  }
  else if (CurrentDomain == MouseDomain) {
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
    for (int i = 0; i < buttonsMP.length; i++) {
      buttonsMP[i].DrawButton();
    }
    textSize(labelsize);
    text("X-Axis", xStep+FullPlotWidth+50, yTitle+170);
    text("Y-Axis", xStep+FullPlotWidth+50, yTitle+230);
    text("Plotting", xStep+FullPlotWidth+45, yTitle+10);
    textSize(labelsizes);
    text("Connection", xStep+FullPlotWidth+45, yTitle-50);
    drawConnectionIndicator();
  }
  else if (CurrentDomain == TrainingDomain) {
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

    for (int i = 0; i < buttonsTP.length; i++) {
      if (buttonsTP[i] != null) {
        buttonsTP[i].DrawButton();
      }
    }

    LabelRepBar(3);
    textSize(labelsizes);
    text("Connection", xStep+FullPlotWidth+45, yTitle-50);
    drawConnectionIndicator();
  }
  // else if (CurrentDomain == SettingsDomain) {
  // fill(200);
  // rectMode(CENTER);
  // rect(width/2, height/2, 200,150,12);
  // text(folder,width/2,height/2+30);
  // for (int i = 0; i < buttonsSP.length; i++) {
  // if(buttonsSP[i] != null){
  // buttonsSP[i].DrawButton();
  // }
  // }
  // }

  loadPixels();
}
// End of plotting section

void UpdatePorts(int ports) {
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
  if (CurrentDomain == TimeDomain) {
    a0 += "Voltage_";
  }
  else if (CurrentDomain == FreqDomain) {
    a0 += "Frequency_";
  }
  else if (CurrentDomain == TrainingDomain) {
    a0 += "Training_";
  }
  a0 += nf(imagesavecounter, 3);

  a0 += ".jpg";
  save(a0);
  println("Image Saved");
  println(a0);
  imagesavecounter++;
  return imagesavecounter;
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

void ResetSerialConnection() {
  StopData();
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
  drawConnectionIndicator();
}

//void ConnectSerial(){
// PollSerialDevices();
// USBPORT_correct = false;
// TestingConnectionFlag = true;
// // Connect - if only one USB device was found, try that one
// if (USBPORTs.length > 0){
// println("USB Devices Found");
// display_error("USB Devices Found! Looking for FlexVolt...");
// for (int i = 0; i < USBPORTs.length; i++) {
// println("Testing USB ports"+i);
// if (!USBPORT_correct){
// println("Trying USB Device #" + (i+1) + "/" + USBPORTs.length + ", at port "+USBPORTs[i]);
// TrySerialConnect(USBPORTs[i],500);
// } else {println("Already found our port");}
// }
// }
// if (BluetoothPORTs.length > 0 && !USBPORT_correct){
// println("Bluetooth Ports Found");
// display_error("No USB FlexVolts Found! Checking Bluetooth Ports...");
// for (int i = 0; i < BluetoothPORTs.length; i++) {
// println("Testing BT ports"+i);
// if (!USBPORT_correct){
// println("Trying Bluetooth Device #" + (i+1) + "/" + BluetoothPORTs.length + ", at port "+BluetoothPORTs[i]);
// TrySerialConnect(BluetoothPORTs[i],4000);
// } else {println("Already found our port");}
// }
// }
//
// if(USBPORT_correct){
// TestingConnectionFlag = false;
// println(myPort+" connected!");
// delay(100);
// myPort.clear();
// display_error("FlexVolt Device Connected!");
// myPort.buffer(1);
// // kill some time!
// delay(200); // custom function - not standard
// }
// else if(!USBPORT_correct){
// display_error("No FlexVolts Found!");
// myPort = null;
// }
//}


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

void EstablishDataLink() {
  if (myPort == null){
    println("no port to connect to");
    return;
  }
  myPort.write('G'); // tells Arduino to start sending data
  if (commentflag)println("sent G");

  SerialBufferN = SignalNumber;
  if (commentflag)println("Signum = "+SignalNumber);
  if (BitDepth10) {
    SerialBufferN += 1;
    if (SignalNumber > 4) {
      SerialBufferN += 1;
    }
  }
  if (commentflag)println("SignalBuffer = "+SerialBufferN);

  // if (BitDepth10){
  // if (SignalNumber > 4){
  // SerialBufferN = SignalNumber+2;
  // }
  // else if(SignalNumber <= 4){
  // SerialBufferN = SignalNumber+1;
  // }
  // }
  // else if(!BitDepth10){
  // SerialBufferN = SignalNumber;
  // }

  myPort.buffer((SerialBufferN+1)*SerialBurstN);
}

void StopData() {
  if (myPort == null) {
    println("no port to stop");
    return;
  }
  myPort.write('Q');
  dataflag = false;
  println("Stopped Data");
  FVserial.connectionindicator = FVserial.indicator_noconnection;
  // ConnectingFlag = false;
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
  buttonsTDP[BTDPrecordnextdata].label = "Record "+DataRecordTime+"s";
  buttonsFDP[BFDPrecordnextdata].label = "Record "+DataRecordTime+"s";
  buttonsTP[BTPrecordnextdata].label = "Record "+DataRecordTime+"s";
  buttonsMP[BMPrecordnextdata].label = "Record "+DataRecordTime+"s";
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
  if (myPort == null){
    println("no port to poll");
    return;
  }
  StopData(); // turn data off
  // handle changes to the Serial buffer coming out of settings
  delay(serialwritedelay);
  myPort.clear();
  println("sent Q");
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
  //  folder = folderTmp;
  //  UserFreqIndex = UserFreqIndexTmp;
  //  SmoothFilterVal = SmoothFilterValTmp;
  //  DownSampleCount = DownSampleCountTmp;
  //  Timer0AdjustVal = Timer0AdjustValTmp;
  //  Prescaler = PrescalerTmp;
  //  DataRecordTime = DataRecordTimeTmp;
  //  SignalNumber = SignalNumberTmp;

  if (myPort == null){
    println("no port to updatesettings on");
    return;
  }
  if (FVserial.flexvoltconnected) {
    StopData(); // turn data off
    // handle changes to the Serial buffer coming out of settings


    DataRegWriteFlag = true;
    delay(serialwritedelay);
    myPort.clear();
    println("sent Q");
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

void ChangeDomain(int NewDomain) {
  OldDomain = CurrentDomain;
  NamesFlag = false;
  // handle changes to the Serial buffer coming out of settings
  if (OldDomain == SettingsDomain) {
    EstablishDataLink();
  }
  if (NewDomain == SettingsDomain) {
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
    if (myPort != null){
      myPort.clear();
    }
    buttonsTDP[BTDPsettings].ChangeColorPressed();
    buttonsFDP[BFDPsettings].ChangeColorPressed();
    buttonsTP[BTPsettings].ChangeColorPressed();
    buttonsMP[BMPsettings].ChangeColorPressed();
    CurrentDomain = SettingsDomain;
    DrawSettings();
    println("Settings Menu");
  }
  else if (NewDomain == HelpDomain) {
    buttonsTDP[BTDPhelp].ChangeColorPressed();
    buttonsFDP[BFDPhelp].ChangeColorPressed();
    buttonsTP[BTPhelp].ChangeColorPressed();
    buttonsMP[BMPhelp].ChangeColorPressed();
    CurrentDomain = HelpDomain;
    DrawHelp();
    println("Help Page");
  }
  else if (NewDomain == TimeDomain) {
    CurrentDomain = TimeDomain;
    buttonsTDP[BTDPsettings].ChangeColorUnpressed();
    buttonsTDP[BTDPhelp].ChangeColorUnpressed();
    buttonsTDP[BTDPtimedomain].BOn = false;
    buttonsTDP[BTDPfreqdomain].BOn = false;
    buttonsTDP[BTDPtraindomain].BOn = false;
    buttonsTDP[BTDPmousedomain].BOn = false;
    buttonsTDP[BTDPtimedomain].BOn = true;

    OffSetFlag = false;
    PauseFlag = false;
    datacounter = 0;
    plotwidth = FullPlotWidth;
    xPos = 0;
    GetChannelButtons(buttonsTDP);
    background(backgroundcolor);
    labelaxes();
    blankplot();
    println("TimeDomain");
  }
  else if (NewDomain == FreqDomain) {
    CurrentDomain = FreqDomain;
    buttonsFDP[BFDPsettings].ChangeColorUnpressed();
    buttonsFDP[BFDPhelp].ChangeColorUnpressed();
    buttonsFDP[BFDPfreqdomain].label = "Switch to Time";
    buttonsFDP[BFDPtimedomain].BOn = false;
    buttonsFDP[BFDPfreqdomain].BOn = false;
    buttonsFDP[BFDPtraindomain].BOn = false;
    buttonsFDP[BFDPmousedomain].BOn = false;
    // buttonsFDP[BFDPfreqdomain].BOn = true;
    buttonsFDP[BFDPtimedomain].BOn = true;
    PauseFlag = false;
    plotwidth = FullPlotWidth;
    GetChannelButtons(buttonsFDP);
    background(backgroundcolor);
    labelaxes();
    blankplot();
    println("FreqDomain");
  }
  else if (NewDomain == TrainingDomain) {
    CurrentDomain = TrainingDomain;
    buttonsTP[BTPsettings].ChangeColorUnpressed();
    buttonsTP[BTPhelp].ChangeColorUnpressed();
    buttonsTP[BTPtimedomain].BOn = false;
    buttonsTP[BTPfreqdomain].BOn = false;
    buttonsTP[BTPtraindomain].BOn = false;
    buttonsTP[BTPmousedomain].BOn = false;
    buttonsTP[BTPtraindomain].BOn = true;

    DownSampleCount = DownSampleCountTraining; //!!!!!!!!!!!!!!!
    UserFreqIndex = UserFreqIndexTraining;
    UserFrequency = UserFreqArray[UserFreqIndex];
    CheckSerialDelay = (long)max( CheckSerialMinTime, 1000.0/((float)UserFrequency/CheckSerialNSamples) );
    SmoothFilterFlag = true;
    BitDepth10 = false;

    OffSetFlag = true;
    PauseFlag = false;
    plotwidth = HalfPlotWidth;
    GetChannelButtons(buttonsTP);
    background(backgroundcolor);
    labelaxes();
    blankplot();
    UpdateSettings();
    println("Workout Turned ON");
  }
  else if (NewDomain == MouseDomain) {
    CurrentDomain = MouseDomain;
    buttonsMP[BMPsettings].ChangeColorUnpressed();
    buttonsMP[BMPhelp].ChangeColorUnpressed();
    buttonsMP[BMPtimedomain].BOn = false;
    // buttonsMP[BMPfreqdomain].BOn = false;
    buttonsMP[BMPtraindomain].BOn = false;
    buttonsMP[BMPmousedomain].BOn = false;
    buttonsMP[BMPmousedomain].BOn = true;
    plotwidth = FullPlotWidth;

    DownSampleCount = DownSampleCountMouse; //!!!!!!!!!!!!!!!
    UserFreqIndex = UserFreqIndexMouse;
    UserFrequency = UserFreqArray[UserFreqIndex];
    CheckSerialDelay = (long)max( CheckSerialMinTime, 1000.0/((float)UserFrequency/CheckSerialNSamples) );

    PauseFlag = true;
    SmoothFilterFlag = true;
    BitDepth10 = false;
    UpdateSettings();
    GetChannelButtons(buttonsMP);
    background(backgroundcolor);
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
}

void GetPageButtons() {
  if (CurrentDomain == TimeDomain) {
    GuiButton[] obj = buttonsTDP;
    obj[BTDPsmooth].BOn = SmoothFilterFlag;
    obj[BTDPoffset].BOn = OffSetFlag;
    obj[BTDPpause].BOn = PauseFlag;
  }
  else if (CurrentDomain == FreqDomain) {
    GuiButton[] obj = buttonsFDP;
    obj[BFDPoffset].BOn = OffSetFlag;
    obj[BFDPpause].BOn = PauseFlag;
  }
  else if (CurrentDomain == TrainingDomain) {
    GuiButton[] obj = buttonsTP;
    // obj[BTPpause].BOn = PauseFlag;
  }
  else if (CurrentDomain == MouseDomain) {
    GuiButton[] obj = buttonsMP;
    obj[BMPpause].BOn = PauseFlag;
  }
  labelaxes();
}


void GetChannelButtons(GuiButton[] obj) {
  if (CurrentDomain == TimeDomain) {
    obj[BTDPchan1].BOn = ChannelOn[0];
    obj[BTDPchan2].BOn = ChannelOn[1];
    obj[BTDPchan3].BOn = ChannelOn[2];
    obj[BTDPchan4].BOn = ChannelOn[3];
    obj[BTDPchan5].BOn = ChannelOn[4];
    obj[BTDPchan6].BOn = ChannelOn[5];
    obj[BTDPchan7].BOn = ChannelOn[6];
    obj[BTDPchan8].BOn = ChannelOn[7];
    obj[BTDPsmooth].BOn = SmoothFilterFlag;
    obj[BTDPoffset].BOn = OffSetFlag;
    obj[BTDPpause].BOn = PauseFlag;
  }
  else if (CurrentDomain == FreqDomain) {
    obj[BFDPchan1].BOn = ChannelOn[0];
    obj[BFDPchan2].BOn = ChannelOn[1];
    obj[BFDPchan3].BOn = ChannelOn[2];
    obj[BFDPchan4].BOn = ChannelOn[3];
    obj[BFDPchan5].BOn = ChannelOn[4];
    obj[BFDPchan6].BOn = ChannelOn[5];
    obj[BFDPchan7].BOn = ChannelOn[6];
    obj[BFDPchan8].BOn = ChannelOn[7];
    // obj[BFDPsmooth].BOn = SmoothFilterFlag;
    obj[BFDPoffset].BOn = OffSetFlag;
    obj[BFDPpause].BOn = PauseFlag;
  }
  else if (CurrentDomain == TrainingDomain) {
    ChannelOn[TrainChan[0]] = true;
    ChannelOn[TrainChan[1]] = true;
    ;
    obj[BTPchan1].BOn = ChannelOn[TrainChan[0]];
    obj[BTPchan2].BOn = ChannelOn[TrainChan[1]];
    // obj[BTPpause].BOn = PauseFlag;
  }
  else if (CurrentDomain == MouseDomain) {
    obj[BMPpause].BOn = PauseFlag;
  }
}

int Bheight = 25; // button height
int Bheights = 20; // button height

void InitializeButtons() {
  // Time Domain (start page) Buttons
  buttonsTDP = new GuiButton[ButtonNumTDP];
  int buttony = yTitle+195;
  int controlsy = yTitle+30;
  buttonsTDP[BTDPsettings] = new GuiButton("Settings", xStep+plotwidth+45, yTitle+plotheight+yStep/2, 80, Bheight, color(BIdleColor), color(0), "Settings", Bmomentary, false);
  buttonsTDP[BTDPhelp] = new GuiButton("Help", xStep+plotwidth-35, yTitle-30, 50, 40, color(BIdleColor), color(0), "Help,?", Bmomentary, false);
  buttonsTDP[BTDPsave] = new GuiButton("Store", xStep+50, yTitle-45, 100, 20, color(BIdleColor), color(0), "Save Image", Bmomentary, false);
  buttonsTDP[BTDPpause] = new GuiButton("Pause", xStep+plotwidth+45, controlsy+10, 60, Bheight, color(BIdleColor), color(0), "Pause", Bonoff, false);
  buttonsTDP[BTDPclear] = new GuiButton("Clear", xStep+plotwidth+45, controlsy+40, 60, Bheight, color(BIdleColor), color(0), "Clear", Bmomentary, false);
  buttonsTDP[BTDPoffset] = new GuiButton("OffSet", xStep+plotwidth+45, controlsy+70, 60, Bheight, color(BIdleColor), color(0), "OffSet", Bonoff, false);
  buttonsTDP[BTDPsmooth] = new GuiButton("Smooth", xStep+plotwidth+45, controlsy+100, 60, Bheight, color(BIdleColor), color(0), "Filter", Bonoff, false);
  buttonsTDP[BTDPrecordnextdata] = new GuiButton("SaveRecord", xStep+50, yTitle-20, 100, 20, color(BIdleColor), color(0), "Record "+DataRecordTime+"s", Bmomentary, false);
  buttonsTDP[BTDPtimedomain] = new GuiButton("TimeDomain", xStep+FullPlotWidth/2-73, yTitle-10, 100, 20, color(BIdleColor), color(0), "Plot Signals", Bonoff, true);
  buttonsTDP[BTDPfreqdomain] = new GuiButton("FreqDomain", xStep+80, yTitle+plotheight+30, 160, 18, color(BIdleColor), color(0), "Switch to Frequency", Bonoff, false);
  buttonsTDP[BTDPtraindomain] = new GuiButton("TrainDomain", xStep+FullPlotWidth/2+19, yTitle-10, 75, 20, color(BIdleColor), color(0), "Workout", Bonoff, false);
  buttonsTDP[BTDPmousedomain] = new GuiButton("MouseDomain", xStep+FullPlotWidth/2+115, yTitle-10, 110, 20, color(BIdleColor), color(0), "MouseGames", Bonoff, false);
  buttonsTDP[BTDPserialreset] = new GuiButton("SerialReset", xStep+FullPlotWidth+55, yTitle-25, 60, 20, color(BIdleColor), color(0), "Reset", Bmomentary, false);
  buttonsTDP[BTDPchan1] = new GuiButton("Chan1", xStep+plotwidth+25, buttony, 30, Bheight, color(BIdleColor), Sig1Color, "1", Bonoff, true);
  buttonsTDP[BTDPchan2] = new GuiButton("Chan2", xStep+plotwidth+25, buttony+30, 30, Bheight, color(BIdleColor), Sig2Color, "2", Bonoff, true);
  buttonsTDP[BTDPchan3] = new GuiButton("Chan3", xStep+plotwidth+25, buttony+60, 30, Bheight, color(BIdleColor), Sig3Color, "3", Bonoff, true);
  buttonsTDP[BTDPchan4] = new GuiButton("Chan4", xStep+plotwidth+25, buttony+90, 30, Bheight, color(BIdleColor), Sig4Color, "4", Bonoff, true);
  buttonsTDP[BTDPchan5] = new GuiButton("Chan5", xStep+plotwidth+65, buttony, 30, Bheight, color(BIdleColor), Sig5Color, "5", Bonoff, false);
  buttonsTDP[BTDPchan6] = new GuiButton("Chan6", xStep+plotwidth+65, buttony+30, 30, Bheight, color(BIdleColor), Sig6Color, "6", Bonoff, false);
  buttonsTDP[BTDPchan7] = new GuiButton("Chan7", xStep+plotwidth+65, buttony+60, 30, Bheight, color(BIdleColor), Sig7Color, "7", Bonoff, false);
  buttonsTDP[BTDPchan8] = new GuiButton("Chan8", xStep+plotwidth+65, buttony+90, 30, Bheight, color(BIdleColor), Sig8Color, "8", Bonoff, false);


  // Frequency Domain buttons (Same as time Domain!)
  buttonsFDP = new GuiButton[ButtonNumFDP];
  buttonsFDP[BFDPsettings] = new GuiButton("Settings", xStep+plotwidth+45, yTitle+plotheight+yStep/2, 80, Bheight, color(BIdleColor), color(0), "Settings", Bmomentary, false);
  buttonsFDP[BFDPhelp] = new GuiButton("Help", xStep+plotwidth-35, yTitle-30, 50, 40, color(BIdleColor), color(0), "Help,?", Bmomentary, false);
  buttonsFDP[BFDPpause]= new GuiButton("Pause", xStep+plotwidth+45, controlsy+10, 60, Bheight, color(BIdleColor), color(0), "Pause", Bonoff, false);
  buttonsFDP[BFDPsave] = new GuiButton("Store", xStep+50, yTitle-45, 100, 20, color(BIdleColor), color(0), "Save Image", Bmomentary, false);
  buttonsFDP[BFDPrecordnextdata] = new GuiButton("SaveRecord", xStep+50, yTitle-20, 100, 20, color(BIdleColor), color(0), "Record "+DataRecordTime+"s", Bmomentary, false);
  buttonsFDP[BFDPtimedomain] = new GuiButton("TimeDomain", xStep+FullPlotWidth/2-73, yTitle-10, 100, 20, color(BIdleColor), color(0), "Plot Signals", Bonoff, true);
  buttonsFDP[BFDPfreqdomain] = new GuiButton("FreqDomain", xStep+80, yTitle+plotheight+30, 160, 18, color(BIdleColor), color(0), "Switch to Frequency", Bonoff, false);
  buttonsFDP[BFDPtraindomain] = new GuiButton("TrainDomain", xStep+FullPlotWidth/2+19, yTitle-10, 75, 20, color(BIdleColor), color(0), "Workout", Bonoff, false);
  buttonsFDP[BFDPmousedomain] = new GuiButton("MouseDomain", xStep+FullPlotWidth/2+115, yTitle-10, 110, 20, color(BIdleColor), color(0), "MouseGames", Bonoff, false);
  buttonsFDP[BFDPserialreset] = new GuiButton("SerialReset", xStep+FullPlotWidth+55, yTitle-25, 60, 20, color(BIdleColor), color(0), "Reset", Bmomentary, false);
  buttonsFDP[BFDPoffset] = new GuiButton("OffSet", xStep+plotwidth+45, controlsy+70, 60, Bheight, color(BIdleColor), color(0), "OffSet", Bonoff, false);
  buttonsFDP[BFDPchan1] = new GuiButton("Chan1", xStep+plotwidth+25, buttony, 30, Bheight, color(BIdleColor), Sig1Color, "1", Bonoff, true);
  buttonsFDP[BFDPchan2] = new GuiButton("Chan2", xStep+plotwidth+25, buttony+30, 30, Bheight, color(BIdleColor), Sig2Color, "2", Bonoff, true);
  buttonsFDP[BFDPchan3] = new GuiButton("Chan3", xStep+plotwidth+25, buttony+60, 30, Bheight, color(BIdleColor), Sig3Color, "3", Bonoff, true);
  buttonsFDP[BFDPchan4] = new GuiButton("Chan4", xStep+plotwidth+25, buttony+90, 30, Bheight, color(BIdleColor), Sig4Color, "4", Bonoff, true);
  buttonsFDP[BFDPchan5] = new GuiButton("Chan5", xStep+plotwidth+65, buttony, 30, Bheight, color(BIdleColor), Sig5Color, "5", Bonoff, false);
  buttonsFDP[BFDPchan6] = new GuiButton("Chan6", xStep+plotwidth+65, buttony+30, 30, Bheight, color(BIdleColor), Sig6Color, "6", Bonoff, false);
  buttonsFDP[BFDPchan7] = new GuiButton("Chan7", xStep+plotwidth+65, buttony+60, 30, Bheight, color(BIdleColor), Sig7Color, "7", Bonoff, false);
  buttonsFDP[BFDPchan8] = new GuiButton("Chan8", xStep+plotwidth+65, buttony+90, 30, Bheight, color(BIdleColor), Sig8Color, "8", Bonoff, false);

  // Mouse Page Buttons
  buttonsMP = new GuiButton[ButtonNumMP];
  buttonsMP[BMPsettings] = new GuiButton("Settings", xStep+plotwidth+45, yTitle+plotheight+yStep/2, 80, Bheight, color(BIdleColor), color(0), "Settings", Bmomentary, false);
  buttonsMP[BMPhelp] = new GuiButton("Help", xStep+plotwidth-35, yTitle-30, 50, 40, color(BIdleColor), color(0), "Help,?", Bmomentary, false);
  buttonsMP[BMPpause]= new GuiButton("Pause", xStep+plotwidth+45, controlsy+10, 60, Bheight, color(BIdleColor), color(0), "Pause", Bonoff, false);
  buttonsMP[BMPsave] = new GuiButton("Store", xStep+50, yTitle-45, 100, 20, color(BIdleColor), color(0), "Save Image", Bmomentary, false);
  buttonsMP[BMPclear] = new GuiButton("Clear", xStep+plotwidth+45, controlsy+40, 60, Bheight, color(BIdleColor), color(0), "Clear", Bmomentary, false);
  buttonsMP[BMPrecordnextdata] = new GuiButton("SaveRecord", xStep+50, yTitle-20, 100, 20, color(BIdleColor), color(0), "Record "+DataRecordTime+"s", Bmomentary, false);
  buttonsMP[BMPtimedomain] = new GuiButton("TimeDomain", xStep+FullPlotWidth/2-73, yTitle-10, 100, 20, color(BIdleColor), color(0), "Plot Signals", Bonoff, true);
  buttonsMP[BMPtraindomain] = new GuiButton("TrainDomain", xStep+FullPlotWidth/2+19, yTitle-10, 75, 20, color(BIdleColor), color(0), "Workout", Bonoff, false);
  buttonsMP[BMPmousedomain] = new GuiButton("MouseDomain", xStep+FullPlotWidth/2+115, yTitle-10, 110, 20, color(BIdleColor), color(0), "MouseGames", Bonoff, false);
  buttonsMP[BMPserialreset] = new GuiButton("SerialReset", xStep+FullPlotWidth+55, yTitle-25, 60, 20, color(BIdleColor), color(0), "Reset", Bmomentary, false);
  buttonsMP[BMPchan1up] = new GuiButton("MChan1up", xStep+plotwidth+80, yTitle+200, 20, 20, color(BIdleColor), color(0), ">", Bmomentary, false);
  buttonsMP[BMPchan1down] = new GuiButton("MChan1down", xStep+plotwidth+16, yTitle+200, 20, 20, color(BIdleColor), color(0), "<", Bmomentary, false);
  buttonsMP[BMPchan1] = new GuiButton("MChan1", xStep+plotwidth+50, yTitle+200, 30, Bheight, color(BIdleColor), SigColorM[MouseChan[0]], ""+(MouseChan[0]+1), Bonoff, true);
  buttonsMP[BMPchan2up] = new GuiButton("MChan2up", xStep+plotwidth+80, yTitle+260, 20, 20, color(BIdleColor), color(0), ">", Bmomentary, false);
  buttonsMP[BMPchan2down] = new GuiButton("MChan2down", xStep+plotwidth+16, yTitle+260, 20, 20, color(BIdleColor), color(0), "<", Bmomentary, false);
  buttonsMP[BMPchan2] = new GuiButton("MChan2", xStep+plotwidth+50, yTitle+260, 30, Bheight, color(BIdleColor), SigColorM[MouseChan[1]], ""+(MouseChan[1]+1), Bonoff, true);

  // Training Page Buttons
  buttonsTP = new GuiButton[ButtonNumTP];
  buttonsTP[BTPsettings] = new GuiButton("Settings", xStep+FullPlotWidth+45, yTitle+plotheight+yStep/2, 80, Bheight, color(BIdleColor), color(0), "Settings", Bmomentary, false);
  buttonsTP[BTPhelp] = new GuiButton("Help", xStep+FullPlotWidth-35, yTitle-30, 50, 40, color(BIdleColor), color(0), "Help,?", Bmomentary, false);
  // buttonsTP[BTPpause]= new GuiButton("Pause", xStep+FullPlotWidth+45, controlsy+10, 60, Bheight, color(BIdleColor), color(0), "Pause", Bonoff, false);
  buttonsTP[BTPsave] = new GuiButton("Store", xStep+50, yTitle-45, 100, 20, color(BIdleColor), color(0), "Save Image", Bmomentary, false);
  buttonsTP[BTPrecordnextdata] = new GuiButton("SaveRecord", xStep+50, yTitle-20, 100, 20, color(BIdleColor), color(0), "Record "+DataRecordTime+"s", Bmomentary, false);
  buttonsTP[BTPtimedomain] = new GuiButton("TimeDomain", xStep+FullPlotWidth/2-73, yTitle-10, 100, 20, color(BIdleColor), color(0), "Plot Signals", Bonoff, true);
  buttonsTP[BTPfreqdomain] = new GuiButton("FreqDomain", xStep+FullPlotWidth/2-40, 80, 70, 20, color(BIdleColor), color(0), "FFT", Bonoff, false);
  buttonsTP[BTPtraindomain] = new GuiButton("TrainDomain", xStep+FullPlotWidth/2+19, yTitle-10, 75, 20, color(BIdleColor), color(0), "Workout", Bonoff, false);
  buttonsTP[BTPmousedomain] = new GuiButton("MouseDomain", xStep+FullPlotWidth/2+115, yTitle-10, 110, 20, color(BIdleColor), color(0), "MouseGames", Bonoff, false);
  buttonsTP[BTPserialreset] = new GuiButton("SerialReset", xStep+FullPlotWidth+55, yTitle-25, 60, 20, color(BIdleColor), color(0), "Reset", Bmomentary, false);
  buttonsTP[BTPreset] = new GuiButton("TReset", xStep+HalfPlotWidth+65, yTitle+plotheight/2+5, 120, Bheights, color(BIdleColor), color(0), "Reset Workout", Bmomentary, false);
  // buttonsTP[BTPWork] = new GuiButton("TWorkOutpuwt", 1025, 150, 80, 60, color(BIdleColor), color(0), "Work Output", Bonoff, false);
  buttonsTP[BTPsetReps1] = new GuiButton("TSetReps1", xStep+HalfPlotWidth+30, yTitle+70, 50, Bheights, color(BIdleColor), color(0), ""+RepsTarget[0], Bonoff, false);
  buttonsTP[BTPsetReps2] = new GuiButton("TSetReps2", xStep+HalfPlotWidth+30, yTitle+plotheight/2+90, 50, Bheights, color(BIdleColor), color(0), ""+RepsTarget[1], Bonoff, false);
  // buttonsTP[BTPReps] = new GuiButton("TReps", xStep+FullPlotWidth+60, 150, 80, 60, color(BIdleColor), color(0), "Reps", Bonoff, false);
  buttonsTP[BTPthresh1up] = new GuiButton("Trepthresh1up", xStep+HalfPlotWidth+20, yTitle+plotheight/2-50, 30, Bheights, color(BIdleColor), color(0), "up", Bmomentary, false);
  buttonsTP[BTPthresh1down] = new GuiButton("Trepthresh1dn", xStep+HalfPlotWidth+20, yTitle+plotheight/2-26, 30, Bheights, color(BIdleColor), color(0), "dn", Bmomentary, false);
  buttonsTP[BTPthresh2up] = new GuiButton("Trepthresh2up", xStep+HalfPlotWidth+20, yTitle+plotheight-29, 30, Bheights, color(BIdleColor), color(0), "up", Bmomentary, false);
  buttonsTP[BTPthresh2down] = new GuiButton("Trepthresh2dn", xStep+HalfPlotWidth+20, yTitle+plotheight-5, 30, Bheights, color(BIdleColor), color(0), "dn", Bmomentary, false);
  buttonsTP[BTPchan1] = new GuiButton("TChan1", xStep+HalfPlotWidth+65, yTitle+40, 30, Bheights, color(BIdleColor), SigColorM[TrainChan[0]], ""+(TrainChan[0]+1), Bonoff, true);
  buttonsTP[BTPchan1name] = new GuiButton("TName1", xStep+HalfPlotWidth+65, yTitle+15, 120, Bheights, color(BIdleColor), color(0), "name1", Bonoff, false);
  buttonsTP[BTPchan1up] = new GuiButton("TName1", xStep+HalfPlotWidth+105, yTitle+40, Bheights, Bheights, color(BIdleColor), color(0), ">", Bmomentary, false);
  buttonsTP[BTPchan1down] = new GuiButton("TName1", xStep+HalfPlotWidth+25, yTitle+40, Bheights, Bheights, color(BIdleColor), color(0), "<", Bmomentary, false);
  buttonsTP[BTPchan2] = new GuiButton("TChan2", xStep+HalfPlotWidth+65, yTitle+plotheight/2+60, 30, Bheights, color(BIdleColor), SigColorM[TrainChan[1]], ""+(TrainChan[1]+1), Bonoff, false);
  buttonsTP[BTPchan2name] = new GuiButton("TName2", xStep+HalfPlotWidth+65, yTitle+plotheight/2+35, 120, Bheights, color(BIdleColor), color(0), "name2", Bonoff, false);
  buttonsTP[BTPchan2up] = new GuiButton("TChan2", xStep+HalfPlotWidth+105, yTitle+plotheight/2+60, Bheights, Bheights, color(BIdleColor), color(0), ">", Bmomentary, false);
  buttonsTP[BTPchan2down] = new GuiButton("TChan2", xStep+HalfPlotWidth+25, yTitle+plotheight/2+60, Bheights, Bheights, color(BIdleColor), color(0), "<", Bmomentary, false);

  // Settings Page Buttons
  buttonsSP = new GuiButton[ButtonNumSP];
  buttonsSP[BSPfolder] = new GuiButton("Folder", width/2-200, height/2-110, 80, Bheights, color(BIdleColor), color(0), "change", Bmomentary, false);
  buttonsSP[BSPfiltup] = new GuiButton("FilterUp", width/2+115, height/2+10, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
  buttonsSP[BSPfiltdown] = new GuiButton("FilterDown", width/2+65, height/2+10, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
  buttonsSP[BSPfrequp] = new GuiButton("FreqUp", width/2-160, height/2+10, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
  buttonsSP[BSPfreqdown] = new GuiButton("FreqDown", width/2-230, height/2+10, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
  buttonsSP[BSPrecordtimeup] = new GuiButton("RecordTimeUp", width/2+200, height/2-70, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
  buttonsSP[BSPrecordtimedown] = new GuiButton("RecordTimeDown", width/2+130, height/2-70, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
  buttonsSP[BSP1chan] = new GuiButton("1chanmodel", width/2-105, height/2+10, 30, Bheights, color(BIdleColor), color(0), "1", Bonoff, false);
  buttonsSP[BSP2chan] = new GuiButton("2chanmodel", width/2-70, height/2+10, 30, Bheights, color(BIdleColor), color(0), "2", Bonoff, false);
  buttonsSP[BSP4chan] = new GuiButton("4chanmodel", width/2-35, height/2+10, 30, Bheights, color(BIdleColor), color(0), "4", Bonoff, true);
  buttonsSP[BSP8chan] = new GuiButton("8chanmodel", width/2+0, height/2+10, 30, Bheights, color(BIdleColor), color(0), "8", Bonoff, false);
  buttonsSP[BSPdownsampleup] = new GuiButton("DownSampleUp", width/2+220, height/2+10, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
  buttonsSP[BSPdownsampledown] = new GuiButton("DownSampleDown", width/2+170, height/2+10, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
  buttonsSP[BSPtimeradjustup] = new GuiButton("TimerAdjustUp", width/2-70, height/2+80, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
  buttonsSP[BSPtimeradjustdown] = new GuiButton("TimerAdjustDown", width/2-130, height/2+80, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
  buttonsSP[BSPprescalerup] = new GuiButton("PrescalerUp", width/2+60, height/2+80, 20, Bheights, color(BIdleColor), color(0), "+", Bmomentary, false);
  buttonsSP[BSPprescalerdown] = new GuiButton("PrescalerDown", width/2+0, height/2+80, 20, Bheights, color(BIdleColor), color(0), "-", Bmomentary, false);
  buttonsSP[BSPsave] = new GuiButton("Save", width/2-160, height/2+130, 140, 30, color(BIdleColor), color(0), "Save & Exit (s)", Bonoff, false);
  buttonsSP[BSPdefaults] = new GuiButton("Defaults", width/2+160, height/2+130, 140, 30, color(BIdleColor), color(0), "Restore Defaults", Bonoff, false);
  buttonsSP[BSPcancel] = new GuiButton("Exit", width/2, height/2+130, 120, 30, color(BIdleColor), color(0), "Cancel (c)", Bonoff, false);
}

//####################################################################################


//######################Begin SnakeGame Object#######################################
// snake game class/object. constructor looks like:
//SnakeGame mySnakeGame;
//mySnakeGame = new SnakeGame(this,xStep+plotwidth/2,yTitle+plotheight/2,plotwidth,plotheight,foodsize,gamespeed);

// mySnakeGame.drawSnakeGame()
public class SnakeGame {
  PApplet parent;

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

  SnakeGame(PApplet parent, int x, int y, int w, int h, int fsize, int gamespeed) {
    this.parent = parent;

    snakecolor = color(250, 220, 180);
    foodcolor = color(255, 0, 0);
    backgroundcolor = color(0, 0, 0);
    textcolor = color(240, 240, 240);

    gamex = x;
    gamey = y;
    gamewidth = w;
    gameheight = h;

    foodSize = fsize;
    drawFood();
    gridX = gamewidth/(foodSize);
    gridY = gameheight/(foodSize);
    gridXstart = x - ((gridX-1)*foodSize)/2;
    gridYstart = y - ((gridY-1)*foodSize)/2;
    println("x = "+x+". y = "+y+". w = "+w+". h = "+h);
    println("gridX = "+gridX+". GridY = "+gridY+". xstart = "+gridXstart+". ystart = "+gridYstart);

    speed = gamespeed; // moves/second
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

  void clearGameScreen() {
    fill(backgroundcolor);
    stroke(backgroundcolor);
    rectMode(CENTER);
    rect(gamex, gamey, gamewidth, gameheight);
  }

  void drawSnakeGame() {
    movecounter++;
    if (movecounter > movewhen) {
      movecounter = 0;
      clearGameScreen();
      runSnakeGame();
    }
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

  void keyInput(char pkey, int pkeyCode) {
    println("key = "+pkey+", keyCode = "+pkeyCode);
    if (pkeyCode == UP) {
      if (stepY != -movestep) {
        stepY = -movestep; 
        stepX = 0;
      }
    }
    if (pkeyCode == DOWN) {
      if (stepY != movestep) {
        stepY = movestep; 
        stepX = 0;
      }
    }
    if (pkeyCode == LEFT) {
      if (stepX != -movestep) {
        stepX = -movestep; 
        stepY = 0;
      }
    }
    if (pkeyCode == RIGHT) {
      if (stepX != movestep) {
        stepX = movestep; 
        stepY = 0;
      }
    }
    if (pkey == 'N' || pkey == 'n') {
      resetSnakeGame();
    }
    // if(keyCode == '+'){
    // increasedifficulty();
    // }
    // if(keyCode == '-'){
    // decreasedifficulty();
    // }
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

  public SerialPortObj(PApplet parent) {
    this.parent = parent;
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

  void connectserial() {
    reset();
    FVserial.PollSerialDevices();
    if (foundPorts) {
      connectionindicator = indicator_connecting;
      connectingflag = true;
    }
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
  boolean MouseOver;
  boolean BOn;
  boolean Bmomentary;

  GuiButton(String tname, int txpos, int typos, int txsize, int tysize, color tcbox, color tctext, String tlabel, boolean tBmomentary, boolean tBOn) {
    name = tname;
    xpos = txpos;
    ypos = typos;
    xsize = txsize;
    ysize = tysize;
    cbox = tcbox;
    ctext = tctext;
    label = tlabel;
    Bmomentary = tBmomentary;
    BOn = tBOn;
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

  void DrawButton() {
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
    DrawButton();
  }

  void ChangeColorPressed() {
    cbox = BPressedColor;
    DrawButton();
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

