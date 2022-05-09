/**
 * Create an animation that illustrates differential rotation in the disk of the Milky Way and how this gives
 * rise to the sine-wave like variation of the value of the proper motion in galactic longitude as a function
 * of galactic longitude.
 *
 * Animation steps
 * ---------------
 *
 * 1. Start with artist's impression image of Milky Way (TODO)
 * 2. Overlay the simulated stars
 * 3. Show solid body rotation
 * 4. Show differential rotation
 * 5. Colour code stars by the value of proper motion in l
 * 6. Focus on ring of stars around the sun and indicate the values of l around the ring
 * 7. Move the stars in the ring to a pml vs l plot
 * 8. Show the corresponding Gaia plot for comparison (TODO)
 *
 * Anthony Brown May 2022 - May 2022
 */
 
import java.awt.Color;

int timeStep = -1;

float sunRadius = 8.277; // Distance from sun to Galactic centre in kpc
float sunVcirc = 234.0;  // Circular velocity at position of the sun in km/s
float rInner = 0.1;      // Disk inner radius in kpc
float rOuter = 13.5;     // Disk outer radius in kpc

float time;
float periodSunInSeconds = 5.0;
float numSunRevolutions = 5.5;  // animation duration in units of Sun's revolution period
int fRate = 30;
float timeScaling = 1.0 / (periodSunInSeconds * fRate);
float ROTATION_DURATION = 3;

int sizeUnit;
int diskRadius = 16;    // Milky Way disk radius in kpc (distance out to which particles are drawn)
float particleRadius;

int nParticles = 5000;
float[] r = new float[nParticles];
float[] phiZero = new float[nParticles];
float[] phiDot = new float[nParticles];
float[] xp = new float[nParticles];
float[] yp = new float[nParticles];
float[] pml = new float[nParticles];
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

ListedColourLuts lut = ListedColourLuts.VIRIDIS;
Color pmlColor;

void setup() {
  size(960, 960, P2D);
  sizeUnit = width / (2*diskRadius);
  particleRadius = sizeUnit * 0.1;
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
}

void draw() {
  background(192);
  timeStep = timeStep + 1;
  time = timeStep * timeScaling;
  
  /*
   * Stop after a time equal to "numSunRevolutions" revolutions of the sun around the milky way.
   */
  if (time>numSunRevolutions) {
    exit();
  }
  
  /*
   * Only animate milky way rotation for ROTATION_DURATION sun revolutions.
   */
  if (time <= ROTATION_DURATION) {
    phiSun = phiZeroSun + time*phiDotSun;
  }
  xsun = sunRadius * cos(phiSun);
  ysun = sunRadius * sin(phiSun);
  vxsun = -sunRadius*phiDotSun*sin(phiSun);
  vysun = sunRadius*phiDotSun*cos(phiSun);

  pushMatrix();
  pushStyle();
  applyTransformation(width/2, height/2);
  
  stroke(0);
  strokeWeight(2);
  //line(0, 0, rOuter*cos(phiSun)*sizeUnit, rOuter*sin(phiSun)*sizeUnit);
  if (time<=3.5) {
    line(rOuter*cos(phiSun+PI)*sizeUnit, rOuter*sin(phiSun+PI)*sizeUnit, 
      rOuter*cos(phiSun)*sizeUnit, rOuter*sin(phiSun)*sizeUnit);
    line(rOuter*cos(phiSun+HALF_PI)*sizeUnit, rOuter*sin(phiSun+HALF_PI)*sizeUnit,
      rOuter*cos(phiSun-HALF_PI)*sizeUnit, rOuter*sin(phiSun-HALF_PI)*sizeUnit);
  }
  if (time>3.5 && time<=3.75) {
    translate((time-3.5)/0.25*sunRadius*sizeUnit, -(time-3.5)/0.25*0.75*sunRadius*sizeUnit);
  }
  if (time>3.75) {
    translate(sunRadius*sizeUnit, -0.75*sunRadius*sizeUnit);
  }
  fill(0);
  noStroke();
  for (int i=0; i<nParticles; i++) {
    if (time<1) {
      phip[i] = phiZero[i] + time*phiDotSun;
    } else if (time <=3) {
      phip[i] = phiZero[i] + (time-1)*phiDot[i];
    }
    xp[i] = r[i] * cos(phip[i]);
    yp[i] = r[i] * sin(phip[i]);
    if (time>2) {
      distp[i] = sqrt(pow(xp[i]-xsun,2) + pow(yp[i]-ysun,2));
      vxp = -r[i]*phiDot[i]*sin(phip[i]);
      vyp = r[i]*phiDot[i]*cos(phip[i]);
      galon[i] = atan2(yp[i]-ysun, xp[i]-xsun);
      pml[i] = (-sin(galon[i])*(vxp-vxsun) + cos(galon[i])*(vyp-vysun))/(4.74*distp[i]);
    }
  }
  maxpml = max(pml);
  minpml = min(pml);
  for (int i=0; i<nParticles; i++) {
    if (time<=2) {
      ellipse(xp[i]*sizeUnit, yp[i]*sizeUnit, particleRadius, particleRadius);
    } else if (time>2 && time<=4.25) {
      pmlColor = lut.getColour(1-(pml[i]-minpml)/(maxpml-minpml));
      fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue());
      if (time>3.25 && time<=3.5 && (distp[i]<4 || distp[i]>5)) {
        fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue(), 255*(1.0-(time-3.25)/0.25));
      }
      if (time>3.5 && (distp[i]<4 || distp[i]>5)) {
        fill(0,0);
      }
      ellipse(xp[i]*sizeUnit, yp[i]*sizeUnit, particleRadius, particleRadius);
    } else if (time>4.25 && time<=4.75 && (distp[i]>=4 && distp[i]<=5)) {
      pmlColor = lut.getColour(1-(pml[i]-minpml)/(maxpml-minpml));
      fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue());
      if (galon[i]<0) {
        xplotp = xp[i]+(xsun-4*PI-xp[i]+(galon[i]+TWO_PI)*4)*(time-4.25)/0.5;
      } else {
        xplotp = xp[i]+(xsun-4*PI-xp[i]+galon[i]*4)*(time-4.25)/0.5;
      }
      yplotp = yp[i]+(ysun+14-yp[i]+4*(pml[i]-minpml)/(maxpml-minpml))*(time-4.25)/0.5;
      ellipse(xplotp*sizeUnit, yplotp*sizeUnit, particleRadius, particleRadius);
    } else if (time>4.75 && (distp[i]>=4 && distp[i]<=5)) {
      pmlColor = lut.getColour(1-(pml[i]-minpml)/(maxpml-minpml));
      fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue());
      if (galon[i]<0) {
        xplotp = xsun-4*PI+(galon[i]+TWO_PI)*4;
      } else {
        xplotp = xsun-4*PI+galon[i]*4;
      }
      yplotp = ysun+14+4*(pml[i]-minpml)/(maxpml-minpml);
      ellipse(xplotp*sizeUnit, yplotp*sizeUnit, particleRadius, particleRadius);
    }
  }
  
  fill(255,127,14);
  ellipse(xsun*sizeUnit, ysun*sizeUnit, 3*particleRadius, 3*particleRadius);
  
  if (time>3.75) {
    pushStyle();
    stroke(0);
    fill(0);
    strokeWeight(2);
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
      text("l="+String.valueOf(int(galontext)), (xsun+7.2*cos(angle))*sizeUnit, -(ysun+7.2*sin(angle))*sizeUnit);
      popMatrix();
    }
    popStyle();
  }
  
  pushStyle();
  stroke(0);
  strokeWeight(2);
  noFill();
  if (time>4.25) {
    rect((xsun-4*PI)*sizeUnit, (ysun+13.0)*sizeUnit, 8*PI*sizeUnit, 6.0*sizeUnit);
    pushStyle();
    fill(0);
    pushMatrix();
    applyMatrix(rightHanded2DtoP2D);
    for (int k=0; k<4; k++) {
      textAlign(CENTER, BOTTOM);
      text(String.valueOf(k*90), (xsun-4*PI+k/4.0*8*PI)*sizeUnit, -((ysun+13.0)*sizeUnit-30));
    }
    textAlign(CENTER, BOTTOM);
    text("Sky position", xsun*sizeUnit, -((ysun+13.0)*sizeUnit-60));
    translate((xsun-4*PI)*sizeUnit-30, -((ysun+14.0)*sizeUnit));
    rotate(-HALF_PI);
    textAlign(LEFT, CENTER);
    text("speed across sky", 0, 0);
    popMatrix();
    popStyle();
  }
  popStyle();
  
  popStyle();
  popMatrix();
  
  fill(0);
  if (time<1) {
    text("Solid Body rotation", 20, 28);
  } else if (time>=1 && time<2) {
    text("Differential rotation", 20, 28);
  } else if (time>=2 && time<3) {
    text("Colour: speed of motion across the sky", 20, 28);
  }
  
  //saveFrame("../frames/frame-######.png");
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
 * Provide the circular velocity of the star at Galactocentric radius R, converted to and angular 
 * speed in aziumth d_phi/d_t. The angular speeds are normalized to the angular speed at the sun's 
 * radius (Vcirc_sun/R_sun).
 *
 * @param radii
 *  float[] with the Galactocentric radii of the stars in kpc.
 *
 * @return
 *   float[] with the angular speeds (d_phi/d_t) of the stars.
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
