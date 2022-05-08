/**
 * Create an animation that illustrates differential rotation in the disk of the Milky Way.
 *
 * Anthony Brown May 2022 - May 2022
 */
 
import java.awt.Color;

int timeStep = -1;

float sunRadius = 8.277; // Distance from sun to Galactic centre in kpc
float sunVcirc = 234.0;  // Circular velocity at position of the sun in km/s
float slopeVcirc = -3.6; // Slope of rotation curve near Sun in km/s/kpc
float rInner = 0.1;      // Disk inner radius in kpc
float rOuter = 13.5;     // Disk outer radius in kpc

float time;
float periodSunInSeconds = 10.0;
float duration = 4.5;  // animation duration in units of Sun rotation period
int fRate = 60;
float timeScaling = 1.0 / (periodSunInSeconds * fRate);
float phiDotScaling = fRate * periodSunInSeconds;  // Scale factor for rotation curve angular velocities, such that at solar radius 1 
                                                   //revolution is the specified number of seconds
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
float[] distp = new float[nParticles];
float maxpml, minpml;
float vxp, vyp;
float phiSun, xsun, ysun, vxsun, vysun;
float phiZeroSun = PI;
float phiDotSun = -TWO_PI;
float galon, angle;

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
  if (time>duration) {
    exit();
  }
  
  if (time<=3) {
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
    translate((time-3.5)/0.25*sunRadius*sizeUnit, 0);
  }
  if (time>3.75) {
    translate(sunRadius*sizeUnit, 0);
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
      galon = atan2(yp[i]-ysun, xp[i]-xsun);
      pml[i] = (-sin(galon)*(vxp-vxsun) + cos(galon)*(vyp-vysun))/(4.74*distp[i]);
    }
  }
  maxpml = max(pml);
  minpml = min(pml);
  for (int i=0; i<nParticles; i++) {
    if (time>2) {
      pmlColor = lut.getColour(1-(pml[i]-minpml)/(maxpml-minpml));
      fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue());
      if (time>3.25 && time<=3.5 && (distp[i]<4 || distp[i]>5)) {
        fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue(), 255*(1.0-(time-3.25)/0.25));
      }
      if (time>3.5 && (distp[i]<4 || distp[i]>5)) {
        fill(0,0);
      }
    }
    ellipse(xp[i]*sizeUnit, yp[i]*sizeUnit, particleRadius, particleRadius);
  }
  fill(255,127,14);
  ellipse(xsun*sizeUnit, ysun*sizeUnit, 3*particleRadius, 3*particleRadius);
  
  if (time>3.75) {
    pushStyle();
    stroke(0);
    fill(0);
    strokeWeight(2);
    for (int k=0; k<12; k++) {
      galon = k*30;
      angle = radians(galon);
      line((xsun+6*cos(angle))*sizeUnit, (ysun+6*sin(angle))*sizeUnit, 
        (xsun+8*cos(angle))*sizeUnit, (ysun+8*sin(angle))*sizeUnit);
      pushMatrix();
      applyMatrix(rightHanded2DtoP2D);
      if (galon>270 || galon<90) {
        textAlign(LEFT, CENTER);
      } else if (galon>90 && galon<270) {
        textAlign(RIGHT, CENTER);
      } else if (galon==90) {
        textAlign(CENTER, BOTTOM);
      } else {
        textAlign(CENTER, TOP);
      }
      text("l="+String.valueOf(int(galon)), (xsun+8.1*cos(angle))*sizeUnit, -(ysun+8.1*sin(angle))*sizeUnit);
      popMatrix();
    }
    popStyle();
  }
  
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
