/*
 * Stan implementation of a simple Milky Way disk rotation model which is intended
 * to fit observed proper motions of a sample of OBA stars.
 *
 * In this model the rotation curve is entirely flat, i.e. the circular velocity does not depend on galactocentric R.
 * The free parameters are:
 *
 *  Vcirc_sun: circular velocity at the location of the sun (positive value by convention, km/s)
 *  Vsun_pec_x: peculiar motion of the sun in Cartesian galactocentric X (km/s)
 *  Vsun_pec_y: peculiar motion of the sun in Cartesian galactocentric Y (km/s)
 *  Vsun_pec_z: peculiar motion of the sun in Cartesian galactocentric Z (km/s)
 *  Zsun: Position of the sun in Cartesian galactocentric Z (pc)
 *  vdisp: Velocity dispersion of the stars around the circular motion (km/s)
 *
 * Fixed parameters:
 *
 *  Rsun: Distance from sun to Galactic centre (8277 pc, GRAVITY)
 *  Ysun: Position of the sun in Cartesian galactocentric Y (0 pc, by definition)
 *
 * A right handed coordinate system is used in which (X,Y,Z)_sun = (-Rsun, Ysun, Zsun)
 * and Vphi(sun) = -Vcirc(sun).
 *
 * Anthony Brown Mar 2022 - Mar 2022
 * <brown@strw.leidenuniv.nl>
 */

functions{
  array[] vector predicted_proper_motions(vector plx, array[] vector p, array[] vector q, array[] vector r,
      real Av, vector sunpos, vector Vsun_pec, real Vcirc_sun) {
    /*
     * Using a simple Milky Way disk kinematics model, predict observed proper motions.
     *
     * Parameters
     *  plx: vector of size N
     *    Observed values of the source parallaxes (mas)
     *  p, q, r: arrays of size N of 3-vectors
     *    The normal triads corresponding to the (l,b) positions of the sources
     *  Av: real
     *    Value of the constant relating velocity and proper motion units (4.74... km*yr/s)
     *  sunpos: vector of size 3
     *    Galactocentric Cartesian position of the sun (pc)
     *  Vsun_pec: vector of size 3
     *    Galactocentric Cartesian peculiar velocity of the sun (km/s)
     *  Vcirc_sun: real
     *    Circular velocity at the position of the sun (km/s, positive)
     *
     * Returns 
     *  array[N] vector[2] of predicted proper motions (mas/yr)
     */
    array[size(plx)] vector[2] predicted_pm;

    vector[3] vsun = [0.0, Vcirc_sun, 0.0]' + Vsun_pec;
    vector[3] starpos;
    vector[3] vdiff;
    real vphistar;
    real phi;

    for (i in 1:size(plx)) {
      starpos = (1000.0/plx[i])*r[i] + sunpos;
      vphistar = -Vcirc_sun;
      phi = atan2(starpos[2], starpos[1]);
      vdiff = [-vphistar*sin(phi), vphistar*cos(phi), 0.0]' - vsun;
      predicted_pm[i][1] = dot_product(p[i], vdiff) * plx[i] / Av;
      predicted_pm[i][2] = dot_product(q[i], vdiff) * plx[i] / Av;
    }

    return predicted_pm;
  }
}

data {
  int<lower=0> N;
  vector[N] galon;
  vector[N] galat;
  vector[N] pml_obs;
  vector[N] pml_obs_unc;
  vector[N] pmb_obs;
  vector[N] pmb_obs_unc;
  vector[N] pml_pmb_corr;
  vector[N] plx_obs;
}

transformed data {
  real Rsun = 8277.0;             // Distance from Sun to Galactic centre, taken as known from GRAVITY
  real Ysun = 0.0;                // Sun galactocentric Cartesian y-coordinate (0 by definition)
  
  // Parameters for priors
  real Vcirc_sun_prior_mean = 220.0;
  real Vcirc_sun_prior_sigma = 50.0;
  real Vsun_pec_x_prior_mean = 11.0;
  real Vsun_pec_y_prior_mean = 12.0;
  real Vsun_pec_z_prior_mean = 7.0;
  real Vsun_pec_x_prior_sigma = 20.0;
  real Vsun_pec_y_prior_sigma = 20.0;
  real Vsun_pec_z_prior_sigma = 20.0;
  real Zsun_prior_mean = 20.0;
  real Zsun_prior_sigma = 50.0;
  real vdisp_prior_alpha = 2.0;
  real vdisp_prior_beta = 0.1;

  real auInMeter = 149597870700.0;
  real julianYearSeconds = 365.25 * 86400.0;
  real auKmYearPerSec = auInMeter/(julianYearSeconds*1000.0);

  array[N] cov_matrix[2] cov_pm;             // Covariance matrix of the proper motions (auxiliary variable only)
  array[N] vector[2] pm_obs;                 // Observed proper motions
  array[N] vector[3] pvec;
  array[N] vector[3] qvec;
  array[N] vector[3] rvec;

  for (n in 1:N) {
    cov_pm[n][1,1] = pml_obs_unc[n]^2;
    cov_pm[n][2,2] = pmb_obs_unc[n]^2;
    cov_pm[n][1,2] = pml_obs_unc[n]*pmb_obs_unc[n]*pml_pmb_corr[n];
    cov_pm[n][2,1] = cov_pm[n][1,2];

    pm_obs[n][1] = pml_obs[n];
    pm_obs[n][2] = pmb_obs[n];

    pvec[n][1] = -sin(galon[n]);
    pvec[n][2] = cos(galon[n]);
    pvec[n][3] = 0.0;
    
    qvec[n][1] = -sin(galat[n])*cos(galon[n]);
    qvec[n][2] = -sin(galat[n])*sin(galon[n]);
    qvec[n][3] = cos(galat[n]);
    
    rvec[n][1] = cos(galat[n])*cos(galon[n]);
    rvec[n][2] = cos(galat[n])*sin(galon[n]);
    rvec[n][3] = sin(galat[n]);
  }
}

parameters {
  real Vcirc_sun;              // Circular velocity at the sun's position
  real Vsun_pec_x;             // Peculiar velocity of Sun in Galactocentric Cartesian X
  real Vsun_pec_y;             // Peculiar velocity of Sun in Galactocentric Cartesian Y
  real Vsun_pec_z;             // Peculiar velocity of Sun in Galactocentric Cartesian Z
  real Zsun;                   // Sun's Galactocentric Z-coordinate
  real vdisp;                  // Velocity dispersion around circular motion (3D isotropic Gaussian)
}

transformed parameters {
  array[N] vector[2] model_pm;

  model_pm = predicted_proper_motions(plx_obs, pvec, qvec, rvec, auKmYearPerSec, [-Rsun, Ysun, Zsun]',
    [Vsun_pec_x, Vsun_pec_y, Vsun_pec_z]', Vcirc_sun);
}

model {
  real diagterm;

  Vcirc_sun ~ normal(Vcirc_sun_prior_mean, Vcirc_sun_prior_sigma);
  Vsun_pec_x ~ normal(Vsun_pec_x_prior_mean, Vsun_pec_x_prior_sigma);
  Vsun_pec_y ~ normal(Vsun_pec_y_prior_mean, Vsun_pec_y_prior_sigma);
  Vsun_pec_z ~ normal(Vsun_pec_z_prior_mean, Vsun_pec_z_prior_sigma);
  Zsun ~ normal(Zsun_prior_mean, Zsun_prior_sigma);
  vdisp ~ gamma(vdisp_prior_alpha, vdisp_prior_beta);
  
  for (i in 1:N) {
    diagterm = (plx_obs[i]/auKmYearPerSec*vdisp)^2;
    pm_obs[i] ~ multi_normal(model_pm[i], cov_pm[i] + [[diagterm, 0.0], [0.0, diagterm]]);
  }
}

generated quantities {
  real diagterm;
  vector[N] pred_pml;
  vector[N] pred_pmb;
  vector[2] pred_pm;
  for (i in 1:N) {
    diagterm = (plx_obs[i]/auKmYearPerSec*vdisp)^2;
    pred_pm = multi_normal_rng(model_pm[i], cov_pm[i] + [[diagterm, 0.0], [0.0, diagterm]]);
    pred_pml[i] = pred_pm[1];
    pred_pmb[i] = pred_pm[2];
  }
}
