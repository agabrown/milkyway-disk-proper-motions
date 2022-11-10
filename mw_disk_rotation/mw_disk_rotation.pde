/**
 * Create an animation that illustrates differential rotation in the disk of the Milky Way and how this gives
 * rise to the sine-wave like variation of the value of the proper motion in galactic longitude as a function
 * of galactic longitude.
 *
 * Animation steps
 * ---------------
 *
 * 1. Start schematic model of the Milky Way
 * 3. Show solid body rotation
 * 4. Show differential rotation
 * 5. Colour code stars by the value of proper motion in l
 * 6. Focus on ring of stars around the sun and indicate the values of l around the ring
 * 7. Move the stars in the ring to a pml vs l plot
 * 8. Show the corresponding Gaia plot for comparison
 *
 * Anthony Brown May 2022 - Jun 2022
 */
 
import java.awt.Color;
import java.util.List;

int timeStep = -1;

float sunRadius = 8.277; // Distance from sun to Galactic centre in kpc
float sunVcirc = 234.0;  // Circular velocity at position of the sun in km/s
float rInner = 0.1;      // Disk inner radius in kpc
float rOuter = 13.5;     // Disk outer radius in kpc

float time;
float periodSunInSeconds = 10.0;
int fRate = 30;
float timeScaling = 1.0 / (periodSunInSeconds * fRate);

/*
 * The animation sequence durations in units of the sun's revolution period.
 */
float START_UP = 1.0;
float SOLIDBODY_END = START_UP + 1;
float PMCOLORS_START = START_UP + 2;
float ROTATION_END = START_UP + 3;
float POSTROTATION_PAUSE_END = START_UP + 3.25;
float FOCUSONRING_END = START_UP + 3.5;
float TRANSLATERING_END = START_UP + 3.75;
float RINGTOPLOT_START = START_UP + 4.25;
float RINGTOPLOT_END = START_UP + 4.75;
float SHOWDATA_START = START_UP + 5.25;
/*
 * animation duration in units of Sun's revolution period
 */
float DURATION_REVS = START_UP + SHOWDATA_START + 0.25;

/*
 * Inner and our radii of ring of stars around sun for pml vs l plot, in kpc
 */
float ringInner = 4;
float ringOuter = 5;

int sizeUnit;
int videoSizeKpc = 30;    // Width and height of video in kpc (to set units) 
float particleRadius;
float textW;
float textH;
float textX = 15;
float textY = 15;

int nParticles = 7000;
float[] r = new float[nParticles];
float[] phiZero = new float[nParticles];
float[] phiDot = new float[nParticles];
float[] xp = new float[nParticles];
float[] yp = new float[nParticles];
float[] pml = new float[nParticles];
float[] pmlscaled = new float[nParticles];
float[] phip = new float[nParticles];
float[] galon = new float[nParticles];
float[] distp = new float[nParticles];
float maxpml, minpml;
float vxp, vyp, xplotp, yplotp;
float phiSun, xsun, ysun, vxsun, vysun;
float phiZeroSun = PI;
float phiDotSun = -TWO_PI;
float angle, galontext;

PMatrix2D rightHanded2DtoP2D = new PMatrix2D(1,  0, 0, 
                                             0, -1, 0);

ColourLookUpTable lut = ColourLuts.PLASMA.getLut();
Color pmlColor;
String modelIntro, animIntro, solidBodyText, differentialText;
String colourCodingText, focusRingText, moveRingText, speedVsLonText;
String showDataText;
String DEG = "°";
List<String> ffmpegInstructions = new ArrayList<String>();

PImage pmlVsLImg;

void setup() {
  size(1080, 1080, P2D);
  sizeUnit = width / videoSizeKpc;
  textW = 10*sizeUnit;
  textH = 7*sizeUnit;
  particleRadius = round(sizeUnit * 0.1);
  frameRate(fRate);
  ellipseMode(RADIUS);
  
  /*
   * Simulate star particles uniformly distributed between galactocentric radii rInner and rOuter.
   */
  float rOutSqr = rOuter*rOuter;
  float rInSqr = rInner*rInner;
  for (int i=0; i<nParticles; i++) {
    r[i] = sqrt(random(1) * (rOutSqr - rInSqr) + rInSqr);
    phiZero[i] = TWO_PI * random(1);
  }
  phiDot = rotationCurve(r);
  
  textSize(20);
  textLeading(24);
  
  animIntro = loadText("../text/anim-intro.txt");
  solidBodyText = loadText("../text/solid-body.txt");
  differentialText = loadText("../text/differential.txt");
  colourCodingText = loadText("../text/colour-coding.txt");
  focusRingText = loadText("../text/focus-on-ring.txt");
  moveRingText = loadText("../text/move-ring.txt");
  speedVsLonText = loadText("../text/speed-vs-longitude.txt");
  showDataText = loadText("../text/compare-to-data.txt");

  ffmpegInstructions.addAll(ffmpegLines("text/anim-intro.txt", 0.0, START_UP*periodSunInSeconds, 60, 80));
  ffmpegInstructions.addAll(ffmpegLines("text/solid-body.txt", START_UP*periodSunInSeconds, 
    SOLIDBODY_END*periodSunInSeconds, 60, 80));
  ffmpegInstructions.addAll(ffmpegLines("text/differential.txt", SOLIDBODY_END*periodSunInSeconds, 
    PMCOLORS_START*periodSunInSeconds, 60, 80));
  ffmpegInstructions.addAll(ffmpegLines("text/colour-coding.txt", PMCOLORS_START*periodSunInSeconds, 
    ROTATION_END*periodSunInSeconds, 60, 80));
  ffmpegInstructions.addAll(ffmpegLines("text/focus-on-ring.txt", ROTATION_END*periodSunInSeconds, 
    FOCUSONRING_END*periodSunInSeconds, 60, 80));
  ffmpegInstructions.addAll(ffmpegLines("text/move-ring.txt", FOCUSONRING_END*periodSunInSeconds, 
    RINGTOPLOT_START*periodSunInSeconds, 60, 80));
  ffmpegInstructions.addAll(ffmpegLines("text/speed-vs-longitude.txt", RINGTOPLOT_START*periodSunInSeconds, 
    DURATION_REVS*periodSunInSeconds, 60, 80));
  ffmpegInstructions.addAll(ffmpegLines("text/compare-to-data.txt", SHOWDATA_START*periodSunInSeconds, 
    DURATION_REVS*periodSunInSeconds, 60, 300));
  
  saveStrings("../lines-ffmpeg.txt", ffmpegInstructions.toArray(new String[0]));
  
  pmlVsLImg = loadImage("../frames/B_star_pml_vs_galon.png");
  imageMode(CENTER);
}

void draw() {
  background(0);
  timeStep = timeStep + 1;
  time = timeStep * timeScaling;
  
  /*
   * Stop after a time equal to "numSunRevolutions" revolutions of the sun around the milky way.
   */
  if (time > DURATION_REVS) {
    exit();
  }
  
  /*
   * Only animate milky way rotation up to ROTATION_END sun revolutions.
   */
  
  if (time <= START_UP) {
    phiSun = phiZeroSun;
  } else if (time > START_UP && time <= ROTATION_END) {
    phiSun = phiZeroSun + (time-START_UP)*phiDotSun;
  }
    
  xsun = sunRadius * cos(phiSun);
  ysun = sunRadius * sin(phiSun);
  vxsun = -sunRadius*phiDotSun*sin(phiSun);
  vysun = sunRadius*phiDotSun*cos(phiSun);
 
  /*
  pushMatrix();
  translate(width/2+sizeUnit, height/2);
  image(milkyWayImg, 0, 0);
  popMatrix();
  */

  pushMatrix();
  pushStyle();
  applyTransformation(width/2+sizeUnit, height/2);
  
  stroke(192);
  strokeWeight(2);

  /*
   * Show Galactic coordinate axes (co-rotating with Sun) up to the moment we 
   * focus on the ring of stars around the sun.
   */
  if (time<=FOCUSONRING_END) {
    line(rOuter*cos(phiSun+PI)*sizeUnit, rOuter*sin(phiSun+PI)*sizeUnit, 
      rOuter*cos(phiSun)*sizeUnit, rOuter*sin(phiSun)*sizeUnit);
    line(rOuter*cos(phiSun+HALF_PI)*sizeUnit, rOuter*sin(phiSun+HALF_PI)*sizeUnit,
      rOuter*cos(phiSun-HALF_PI)*sizeUnit, rOuter*sin(phiSun-HALF_PI)*sizeUnit);
  }
  
  /*
   * Translate the scene of the sun and the ring of stars to the bottom of the screen and keep it there.
   */
  if (time>FOCUSONRING_END && time<=TRANSLATERING_END) {
    translate((time-FOCUSONRING_END)/(TRANSLATERING_END-FOCUSONRING_END)*sunRadius*sizeUnit,
    -(time-FOCUSONRING_END)/(TRANSLATERING_END-FOCUSONRING_END)*0.75*sunRadius*sizeUnit);
  }
  if (time>TRANSLATERING_END) {
    translate(sunRadius*sizeUnit, -0.75*sunRadius*sizeUnit);
  }
  
  /*
   * Section with drawing instructions for the star particles.
   */
  fill(192);
  noStroke();
  /*
   * Show solid boy rotation first and the switch to differential rotation of the star particles.
   */
  for (int i=0; i<nParticles; i++) {
    if (time <= START_UP) {
      phip[i] = phiZero[i];
    } else if (time > START_UP && time <= SOLIDBODY_END) {
      phip[i] = phiZero[i] + (time-START_UP)*phiDotSun;
    } else if (time <= ROTATION_END) {
      phip[i] = phiZero[i] + (time-SOLIDBODY_END)*phiDot[i];
    }
    xp[i] = r[i] * cos(phip[i]);
    yp[i] = r[i] * sin(phip[i]);
    /*
     * Calculate the galactic longitude and proper motions of the stars.
     */
    if (time > PMCOLORS_START && time <= ROTATION_END) {
      distp[i] = sqrt(pow(xp[i]-xsun,2) + pow(yp[i]-ysun,2));
      vxp = -r[i]*phiDot[i]*sin(phip[i]);
      vyp = r[i]*phiDot[i]*cos(phip[i]);
      galon[i] = atan2(yp[i]-ysun, xp[i]-xsun);
      pml[i] = (-sin(galon[i])*(vxp-vxsun) + cos(galon[i])*(vyp-vysun))/(4.74*distp[i]);
    }
  }
  
  pushStyle();
  stroke(0);
  strokeWeight(2);
  noFill();
  /*
   * Draw the plot box and annotate the axes
   */
  if (time>RINGTOPLOT_START) {
    pushStyle();
    fill(255);
    rect((xsun-4*PI-2.5)*sizeUnit, (ysun+9.0)*sizeUnit, (8*PI+3)*sizeUnit, 10.0*sizeUnit);
    popStyle();
    rect((xsun-4*PI-0.5)*sizeUnit, (ysun+12.0)*sizeUnit, 8*PI*sizeUnit, 6.0*sizeUnit);
    pushStyle();
    fill(0);
    pushMatrix();
    applyMatrix(rightHanded2DtoP2D);
    for (int k=0; k<8; k++) {
      textAlign(CENTER, BOTTOM);
      text(String.valueOf(k*50)+DEG, (xsun-4*PI-0.5+(k*50/360.0)*8*PI)*sizeUnit, -((ysun+12.0)*sizeUnit-30));
    }
    textAlign(CENTER, BOTTOM);
    text("Galactic longitude", xsun*sizeUnit, -((ysun+12.0)*sizeUnit-60));
    translate((xsun-4*PI-0.5)*sizeUnit-30, -((ysun+12.5)*sizeUnit));
    rotate(-HALF_PI);
    textAlign(LEFT, CENTER);
    text("velocity across sky", 0, 0);
    popMatrix();
    popStyle();
  }
  popStyle();
  
  pmlscaled = Tools.histEqualize(pml);
  maxpml = max(pml);
  minpml = min(pml);
  for (int i=0; i<nParticles; i++) {
    /*
     * Colour code the particles according to the proper motion value.
     */
    if (time <= PMCOLORS_START) {
      ellipse(xp[i]*sizeUnit, yp[i]*sizeUnit, particleRadius, particleRadius);
    } else if (time > PMCOLORS_START && time<=RINGTOPLOT_START) {
      //pmlColor = lut.getColour(1-(pml[i]-minpml)/(maxpml-minpml));
      pmlColor = lut.getColour(pmlscaled[i]);
      fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue());
      /*
       * Fade out the stars outisde the ring we want to focus on.
       */
      if (time>=POSTROTATION_PAUSE_END && time<=FOCUSONRING_END && (distp[i]<ringInner || distp[i]>ringOuter)) {
        fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue(), 
        255*(1.0-(time-POSTROTATION_PAUSE_END)/(POSTROTATION_PAUSE_END-ROTATION_END)));
      }
      if (time>FOCUSONRING_END && (distp[i]<ringInner || distp[i]>ringOuter)) {
        fill(0,0);
      }
      ellipse(xp[i]*sizeUnit, yp[i]*sizeUnit, particleRadius, particleRadius);
    } else if (time>RINGTOPLOT_START && time<=RINGTOPLOT_END && distp[i]>=ringInner && distp[i]<=ringOuter) {
      /*
       * Transform the ring of stars to the pml vs l plot, but keep a copy of the ring in place.
       */
      pmlColor = lut.getColour(pmlscaled[i]);
      fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue());
      if (galon[i]<0) {
        xplotp = xp[i]+(xsun-4*PI-0.5-xp[i]+(galon[i]+TWO_PI)*4)*(time-RINGTOPLOT_START)/(RINGTOPLOT_END-RINGTOPLOT_START);
      } else {
        xplotp = xp[i]+(xsun-4*PI-0.5-xp[i]+galon[i]*4)*(time-RINGTOPLOT_START)/(RINGTOPLOT_END-RINGTOPLOT_START);
      }
      yplotp = yp[i]+(ysun+13-yp[i]+4*(pml[i]-minpml)/(maxpml-minpml)) * 
        (time-RINGTOPLOT_START)/(RINGTOPLOT_END-RINGTOPLOT_START);
      ellipse(xp[i]*sizeUnit, yp[i]*sizeUnit, particleRadius, particleRadius);
      ellipse(xplotp*sizeUnit, yplotp*sizeUnit, particleRadius, particleRadius);
    } else if (time>RINGTOPLOT_END && distp[i]>=ringInner && distp[i]<=ringOuter) {
      /*
       * Keep plotting the stars in the plotbox and on the ring.
       */
      pmlColor = lut.getColour(pmlscaled[i]);
      fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue());
      if (galon[i]<0) {
        xplotp = xsun-4*PI-0.5+(galon[i]+TWO_PI)*4;
      } else {
        xplotp = xsun-4*PI-0.5+galon[i]*4;
      }
      yplotp = ysun+13+4*(pml[i]-minpml)/(maxpml-minpml);
      if (time<=SHOWDATA_START) {
        ellipse(xp[i]*sizeUnit, yp[i]*sizeUnit, particleRadius, particleRadius);
      }
      ellipse(xplotp*sizeUnit, yplotp*sizeUnit, particleRadius, particleRadius);
    }
  }
  
  fill(255,127,14);
  if (time<=SHOWDATA_START) {
    ellipse(xsun*sizeUnit, ysun*sizeUnit, 4*particleRadius, 4*particleRadius);
  }
  
  /*
   * Indicate Galactic longitude around the ring.
   */
  if (time>TRANSLATERING_END && time<SHOWDATA_START) {
    pushStyle();
    stroke(255);
    fill(255);
    strokeWeight(2);
    textSize(24);
    for (int k=0; k<12; k++) {
      galontext = k*30;
      angle = radians(galontext);
      line((xsun+6*cos(angle))*sizeUnit, (ysun+6*sin(angle))*sizeUnit, 
        (xsun+7*cos(angle))*sizeUnit, (ysun+7*sin(angle))*sizeUnit);
      pushMatrix();
      applyMatrix(rightHanded2DtoP2D);
      if (galontext>270 || galontext<90) {
        textAlign(LEFT, CENTER);
      } else if (galontext>90 && galontext<270) {
        textAlign(RIGHT, CENTER);
      } else if (galontext==90) {
        textAlign(CENTER, BOTTOM);
      } else if (galontext==270) {
        textAlign(CENTER, TOP);
      }
      text("l="+String.valueOf(int(galontext))+DEG, (xsun+7.2*cos(angle))*sizeUnit, -(ysun+7.2*sin(angle))*sizeUnit);
      popMatrix();
    }
    popStyle();
  }
  
  popStyle();
  popMatrix();
  
  if (time > SHOWDATA_START) {
    image(pmlVsLImg, width/2, 20*sizeUnit, (8*PI+3)*sizeUnit, (8*PI+3)*sizeUnit/pmlVsLImg.width*pmlVsLImg.height);
  }
  
  saveFrame("../frames/frame-######.png");
}

/**
 * Applies the transformation from world coordinates (right-handed 2D Cartesian) to the P2D
 * coordinate system. First translated to the desired screen location, then apply the 
 * conversion from the conventional Cartesian system to P2D.
 *
 * @param x
 *    Translation in P2D x (pixels).
 * @param y
 *    Translation in P2D y (pixels).   
 */
void applyTransformation(float x, float y) {
  translate(x, y);
  applyMatrix(rightHanded2DtoP2D);
}

/**
 * Provide the circular velocity of the star at Galactocentric radius R, converted to an angular 
 * velocity in aziumth d_phi/d_t. The angular velocities are normalized to the angular speed at the sun's 
 * radius (Vcirc_sun/R_sun).
 *
 * @param radii
 *  float[] with the Galactocentric radii of the stars in kpc.
 *
 * @return
 *   float[] with the angular velocities (d_phi/d_t) of the stars.
 */
float[] rotationCurve(float[] radii) {
  
  float[] phiDot = new float[radii.length];
  float vcirc;
  float v0;
  float h = 3.0;
  float p = -0.55;
  
  v0 = sunVcirc/brunettiPfennigerRotCurve(h, p, sunRadius);
  
  for (int i=0; i<radii.length; i++) {
    vcirc = v0 * brunettiPfennigerRotCurve(h, p, radii[i]);
    phiDot[i] = -TWO_PI*(vcirc/sunVcirc) * (sunRadius/radii[i]);
  }
  return phiDot;
}

/**
 * Unscaled version of the Brunetti & Pfenniger (2010) rotation curve.
 *
 * @param h
 *  Scale length in kpc
 * @param p
 *  Exponent parameter in equation
 * @param r
 *  Galactocentric radius of star (kpc)
 *
 * @return
 *  Unscaled circular velocity in 1/kpc.
 */
float brunettiPfennigerRotCurve(float h, float p, float r) {
  float roverh = r/h;
  return (roverh)*pow(1+(roverh)*(roverh), (p-2/4));
}

/**
 * Load a text from a file and combine multiple lines into a single string.
 *
 * @param file
 *  Name of input file.
 *
 * @return
 *  The text combined into a string.
 */
String loadText(String file) {
  String result = "";
  for (String s : loadStrings(file)) {
    result = result + s + " ";
  }
  return result.trim();
}

/**
 * Generate the ffmpeg instructions with the correct timing for the text overlays in the video produced with ../makevideo.sh.
 *
 * @param textfile
 *  Name of textfile for text input to video
 * @param start
 *  Start time of text rendering (from start of this animation)
 * @param end
 *  End time of text rendering (from start of this animation)
 * @param x
 *  Horizontal position of text from left edge of video (pixels).
 * @param y
 *  Vertical position of text from top edge of video (pixels).
 *
 * @return
 *  Array with two lines for the ffmpeg command string.
 */
List<String> ffmpegLines(String textFile, float start, float end, int x, int y) {
  List<String> out = new ArrayList<String>();
  out.add("drawtext=fontfile=${FONTFILE}:textfile="+textFile+":fontcolor_expr=ffffff:");
  out.add("fontsize=${FONTSIZE}:line_spacing=${LINESPACING}:box=0:x="+String.valueOf(x)+
    ":y="+String.valueOf(y)+":enable=\"'between(t,"+
    String.valueOf(start)+","+String.valueOf(end)+")'\",");
  return out;
}
