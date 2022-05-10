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
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;
import java.util.Collections;
import java.util.Comparator;
import java.util.stream.IntStream;

int timeStep = -1;

float sunRadius = 8.277; // Distance from sun to Galactic centre in kpc
float sunVcirc = 234.0;  // Circular velocity at position of the sun in km/s
float rInner = 0.1;      // Disk inner radius in kpc
float rOuter = 13.5;     // Disk outer radius in kpc

float time;
float periodSunInSeconds = 5.0;
int fRate = 30;
float timeScaling = 1.0 / (periodSunInSeconds * fRate);

/*
 * The animation sequence durations in units of the sun's revolution period.
 */
float SOLIDBODY_END = 1;
float PMCOLORS_START = 2;
float ROTATION_END = 3;
float POSTROTATION_PAUSE_END = 3.25;
float FOCUSONRING_END = 3.5;
float TRANSLATERING_END = 3.75;
float RINGTOPLOT_START = 4.25;
float RINGTOPLOT_END = 4.75;
/*
 * animation duration in units of Sun's revolution period
 */
float DURATION_REVS = 5.5;

/*
 * Inner and our radii of ring of stars around sun for pml vs l plot, in kpc
 */
float ringInner = 4;
float ringOuter = 5;

int sizeUnit;
int diskRadius = 16;    // Milky Way disk radius in kpc (distance out to which particles are drawn)
float particleRadius;

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
  if (time > DURATION_REVS) {
    exit();
  }
  
  /*
   * Only animate milky way rotation up to ROTATION_END sun revolutions.
   */
  if (time <= ROTATION_END) {
    phiSun = phiZeroSun + time*phiDotSun;
  }
  xsun = sunRadius * cos(phiSun);
  ysun = sunRadius * sin(phiSun);
  vxsun = -sunRadius*phiDotSun*sin(phiSun);
  vysun = sunRadius*phiDotSun*cos(phiSun);

  pushMatrix();
  pushStyle();
  applyTransformation(width/2+sizeUnit, height/2);
  
  stroke(0);
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
  fill(0);
  noStroke();
  /*
   * Show solid boy rotation first and the switch to differential rotation of the star particles.
   */
  for (int i=0; i<nParticles; i++) {
    if (time <= SOLIDBODY_END) {
      phip[i] = phiZero[i] + time*phiDotSun;
    } else if (time <=3) {
      phip[i] = phiZero[i] + (time-1)*phiDot[i];
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
  
  pmlscaled = histEqualize(pml);
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
      //pmlColor = lut.getColour(1-(pml[i]-minpml)/(maxpml-minpml));
      pmlColor = lut.getColour(pmlscaled[i]);
      fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue());
      if (galon[i]<0) {
        xplotp = xp[i]+(xsun-4*PI-xp[i]+(galon[i]+TWO_PI)*4)*(time-RINGTOPLOT_START)/(RINGTOPLOT_END-RINGTOPLOT_START);
      } else {
        xplotp = xp[i]+(xsun-4*PI-xp[i]+galon[i]*4)*(time-RINGTOPLOT_START)/(RINGTOPLOT_END-RINGTOPLOT_START);
      }
      yplotp = yp[i]+(ysun+14-yp[i]+4*(pml[i]-minpml)/(maxpml-minpml)) * 
        (time-RINGTOPLOT_START)/(RINGTOPLOT_END-RINGTOPLOT_START);
      ellipse(xp[i]*sizeUnit, yp[i]*sizeUnit, particleRadius, particleRadius);
      ellipse(xplotp*sizeUnit, yplotp*sizeUnit, particleRadius, particleRadius);
    } else if (time>RINGTOPLOT_END && distp[i]>=ringInner && distp[i]<=ringOuter) {
      /*
       * Keep plotting the stars in the plotbox and on the ring.
       */
      //pmlColor = lut.getColour(1-(pml[i]-minpml)/(maxpml-minpml));
      pmlColor = lut.getColour(pmlscaled[i]);
      fill(pmlColor.getRed(), pmlColor.getGreen(), pmlColor.getBlue());
      if (galon[i]<0) {
        xplotp = xsun-4*PI+(galon[i]+TWO_PI)*4;
      } else {
        xplotp = xsun-4*PI+galon[i]*4;
      }
      yplotp = ysun+14+4*(pml[i]-minpml)/(maxpml-minpml);
      ellipse(xp[i]*sizeUnit, yp[i]*sizeUnit, particleRadius, particleRadius);
      ellipse(xplotp*sizeUnit, yplotp*sizeUnit, particleRadius, particleRadius);
    }
  }
  
  fill(255,127,14);
  ellipse(xsun*sizeUnit, ysun*sizeUnit, 3*particleRadius, 3*particleRadius);
  
  /*
   * Indicate Galactic longitude around the ring.
   */
  if (time>TRANSLATERING_END) {
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
  /*
   * Draw the plot box and annotate the axes
   */
  if (time>RINGTOPLOT_START) {
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

  /*
   * Captions for the animation phases.
   */
  fill(0);
  if (time <= SOLIDBODY_END) {
    text("Motions of the stars if the Milky Way would rotate as a solid body", 20, 28, 8*sizeUnit, 5*sizeUnit);
  } else if (time > SOLIDBODY_END && time <= PMCOLORS_START) {
    text("In reality stars move in a differential rotation pattern", 20, 28, 8*sizeUnit, 5*sizeUnit);
  } else if (time > PMCOLORS_START && time <= ROTATION_END) {
    text("Now the stars are colour coded according to the speed of their motion across the sky", 20, 28, 8*sizeUnit, 5*sizeUnit);
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

float[] histEqualize(final float[] data) {
  final List<Integer> sortedIndices = sortIndices(toFloatList(data));
  Map<Boolean, List<Integer>> nanPartitioned = IntStream.range(0, data.length).boxed().collect(Collectors.partitioningBy(i -> Double.isNaN(data[i])));

  final int nMinOne = nanPartitioned.get(false).size() - 1;
  float[] transformedData = new float[data.length];
  for (int i = 0; i < data.length; i++) {
    transformedData[sortedIndices.get(i)] = Float.isNaN(data[sortedIndices.get(i)]) ? Float.NaN : (float) i / nMinOne;
  }
  return transformedData;
}

<T extends Comparable<T>> List<Integer> sortIndices(final List<T> key) {
  if (key.size() < 2) {
    final List<Integer> indices = new ArrayList<>();
    for (int i = 0; i < key.size(); i++) {
      indices.add(i);
    }
    return indices;
  }

  /*
   * Indices of the input list.
   */
  final List<Integer> indices = IntStream.range(0, key.size()).boxed().collect(Collectors.toList());

  /*
   * Sort the indices based on the keys.
   */
  Collections.sort(indices, new Comparator<Integer>() {
    @Override
    public int compare(final Integer i, final Integer j) {
      return key.get(i).compareTo(key.get(j));
    }
  });

  return indices;
}

List<Float> toFloatList(final float[] array) {
  final ArrayList<Float> list = new ArrayList<>();
  for (final float entry : array) {
    list.add(entry);
  }
  list.trimToSize();
  return list;
}
