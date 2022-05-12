"""
Classes and functions that implemet a very simple kinematic model for the Milky Way disk. This assumes stars describe
strictly circular orbits around the vertical axis of the Milky Way disk plane. Thus in galactocentric cylindrical
coordinates the velocity vectors of the stars are (V_R, V_phi, V_z) = (0, V_phi(R), 0), where V_phi(R) is the rotation
curve of the disk. The velocity field does not change with z.

Anthony Brown Feb 2022 - Feb 2022
"""

import numpy as np

import astropy.units as u
import astropy.constants as c
from astropy.coordinates import cartesian_to_spherical

from gala.potential.potential.builtin.special import BovyMWPotential2014

from pygaia.astrometry.vectorastrometry import normal_triad

_au_km_year_per_sec = (c.au / (1*u.yr).to(u.s)).to(u.km/u.s).value


class FlatRotationCurve(BovyMWPotential2014):
    """
    Implements a very simple kinematic model of the disk in which the circular velocity is constant everywhere. 
    It corresponds to constant V_phi(R) in the model above.
    
    This is a hack to make it easy to switch between the simple kinematic model and a model with a rotation curve
    derived from a proper potential.
    
    THIS IS NOT A PROPER Gala POTENTIAL, ONLY USE THE circular_velocity METHOD.
    """
    
    def __init__(self, vcirc):
        """
        Class constructor/initializer.
        
        Parameters
        ----------
        
        vcirc: float
            Circular velocity in km/s.
        """
        self.the_pot = BovyMWPotential2014()
        self.vcirc = vcirc*u.km/u.s
    
    def circular_velocity(self, q):
        return self.the_pot.circular_velocity(q)*0.0 + self.vcirc


class SolidBodyRotationCurve(BovyMWPotential2014):
    """
    Implements a very simple kinematic model of the disk in which the circular velocity follows a solid body rotation
    curve. That is, the angular velocity at all radii is the same and V_phi(R) increases linearly with R.
    
    This is a hack to make it easy to switch between the simple kinematic model and a model with a rotation curve
    derived from a proper potential.
    
    THIS IS NOT A PROPER Gala POTENTIAL, ONLY USE THE circular_velocity METHOD.
    """
    
    def __init__(self, vcircsun, rsun):
        """
        Class constructor/initializer.
        
        Parameters
        ----------
        
        vcircsun: float
            Circular velocity at the position of the Sun in km/s.
        rsun: float
            Galactocentric distance of the Sun in pc.
        """
        self.the_pot = BovyMWPotential2014()
        self.vcircsun = vcircsun*u.km/u.s
        self.rsun = rsun*u.pc
    
    def circular_velocity(self, q):
        rq = np.sqrt(q[0]**2 + q[1]**2).to(u.pc)
        return self.the_pot.circular_velocity(q)*0.0 + self.vcircsun*(rq/self.rsun).value


class BrunettiPfennigerRotationCurve(BovyMWPotential2014):
    """
    Implements a very simple kinematic model of the disk in which the circular velocity follows the rotation
    curve from Brunetti & Pfenniger, 2010, https://ui.adsabs.harvard.edu/abs/2010A%26A...510A..34B/abstract
    
    This is a hack to make it easy to switch between the simple kinematic model and a model with a rotation curve
    derived from a proper potential.
    
    THIS IS NOT A PROPER Gala POTENTIAL, ONLY USE THE circular_velocity METHOD.
    """
    
    def __init__(self, vcircsun, rsun, h, p):
        """
        Class constructor/initializer.
        
        Parameters
        ----------
        
        vcircsun: float
            Circular velocity at the position of the Sun in km/s.
        rsun: float
            Galactocentric distance of the Sun in pc.
        h : float
            Potential scale length in kpc
        p : float
            Exponent p in rotation curve equation
        """
        self.the_pot = BovyMWPotential2014()
        self.vcircsun = vcircsun*u.km/u.s
        self.rsun = rsun*u.pc
        self.h = h*u.kpc
        self.p = p
        self.v0 = (self.vcircsun/(self.rsun.to(u.kpc)/self.h * np.power(1 + (self.rsun.to(u.kpc)/self.h)**2, (self.p-2)/4))).to(u.km/u.s)
    
    def circular_velocity(self, q):
        rq = np.sqrt(q[0]**2 + q[1]**2).to(u.kpc)
        return self.the_pot.circular_velocity(q)*0.0 + self.v0*(rq/self.h * np.power(1 + (rq/self.h).value**2, (self.p-2)/4))


class DiskKinematicModel:
    """
    Implements a very simple kinematic model for the Milky Way disk. This assumes stars describe strictly circular orbits
    around the vertical axis of the Milky Way disk plane. Thus in galactocentric cylindrical coordinates the velocity
    vectors of the stars are (V_R, V_phi, V_z) = (0, V_phi(R), 0), where V_phi(R) is the rotation curve of the disk. The
    velocity field does not change with z.
    """

    def __init__(self, gala_pot_instance, sunpos, vsunpeculiar):
        """
        Class constructor/initializer.

        Parameters
        ----------

        gala_pot_instance: gala.potential.potential.PotentialBase instance
            The potential from which the rotation curve will be extracted for the disk kinematic model. The units used
            by the potential object are assumed to be 'galactic', i.e. (kpc, Myr, solMass, rad). See Gala documentation.
        sunpos: astropy Quantity, 3-element array
            3-vector with the sun's position in the Milky Way in galactocentric Cartesian coordinates. Default units are kpc.
        vsunpeculiar: astropy Quantity, 3-element array
            Sun's peculiar velocity in galactocentric Cartesian coordinates. Default units are km/s.
        """
        self.pot = gala_pot_instance
        self.sunpos = sunpos
        self.vsunpec = vsunpeculiar
        self.vphisun = -self.pot.circular_velocity(self.sunpos)[0]
        self.vsun = np.array([0, -self.vphisun.value, 0])*u.km/u.s + self.vsunpec

    def get_circular_velocity(self, pos):
        """
        Get the circular velocity at the input positions.

        Parameters
        ----------

        pos: float array of shape (3,N)
            Array of positions for which to retrieve the circular velocity, units of kpc.

        Return
        ------

        Circular velocity as array of shape (N). Units of km/s.
        """
        return self.pot.circular_velocity(pos)

    def observables(self, distance, l, b, vsunpec=np.nan, sunpos=np.nan):
        """
        Calculate the proper motions and radial velocities for stars at a given distance and galactic coordinate (l,b).

        Parameters
        ----------

        distance: astropy length Quantity, float array
            The distances to the stars. Default unit is kpc.
        l: astropy angle-like Quantity, float array
            The Galactic longitude of the stars. Default unit is radians.
        b: astropy angle-like Quantity, float array
            The Galactic latitude of the stars. Default unit is radians.
        
        Keyword arguments
        -----------------
        
        vsunpec: astropy quantity, float 3-array
            Custom value for the sun's peculiar velocity, by default same as value used for model initialization
        sunpos: astropy quantity, float 3-array
            Custom value for the sun's position, by default same as value used for model initialization

        Returns
        -------

        Proper motions in l and b, and the radial velocities. Units are mas/yr and km/s.
        pml, pmb, vrad = observables(distance, l, b).
        """
        p, q, r = normal_triad(l,b)
        if np.any(np.isnan(vsunpec)):
            vsunpec = self.vsunpec
        if np.any(np.isnan(sunpos)):
            sunpos = self.sunpos
        vsun = np.array([0, -self.vphisun.value, 0])*u.km/u.s + vsunpec

        starpos = ((distance*r).T+sunpos).T
        vphistar = -self.pot.circular_velocity(starpos)
        phi = np.arctan2(starpos[1,:], starpos[0,:])

        vstar = np.vstack((-vphistar*np.sin(phi), vphistar*np.cos(phi), np.zeros_like(vphistar)))
        vdiff = (vstar.T-vsun).T

        vrad = np.zeros(distance.size)*u.km/u.s
        pml = np.zeros(distance.shape)*u.mas/u.yr
        pmb = np.zeros(distance.shape)*u.mas/u.yr
        for i in range(distance.size):
            vrad[i] = np.dot(r[:,i], vdiff[:,i])
            pml[i] = (np.dot(p[:,i], vdiff[:,i]).to(u.km/u.s)/(distance[i].to(u.kpc) *
                _au_km_year_per_sec)).value*u.mas/u.yr
            pmb[i] = (np.dot(q[:,i], vdiff[:,i]).to(u.km/u.s)/(distance[i].to(u.kpc) *
                _au_km_year_per_sec)).value*u.mas/u.yr

        return pml, pmb, vrad

    def differential_velocity_field(self, xgrid, ygrid, z):
        """
        Calculate the differntial velocity field for a grid in galactocentric Cartesian (x,y) and fixed z.

        Parameters
        ----------

        xgrid: astropy Quantity, float array, shape (N,N)
            Values of galactocentric x-coordinates over grid (as generated with np.mgrid for example). Default units are kpc.
        ygrid: astropy Quantity, float array, shape (N,N)
            Values of galactocentric y-coordinates over grid (as generated with np.mgrid for example). Default units are kpc.
        z: astropy Quantity, float
            Value of the fixed galactocentric z-coordinate. Default unit is kpc.

        Return
        ------

        The differential velocity at each (x, y, z) as proper motions, radial velocities, and tangential velocities, all
        with respect to the solar system barycentre. In addition return the normal triad vectors for each (x,y,z).
        pml, pmb, vrad, vtan, p, q, r = differential_velocity_field(xgrid, ygrid, z). Units mas/yr, mas/yr, km/s, km/s
        """

        zgrid = np.zeros_like(xgrid) + z
        phi=np.arctan2(ygrid, xgrid)

        vphistar = -self.pot.circular_velocity([xgrid, ygrid, zgrid])
        vstar = np.stack((-vphistar*np.sin(phi), vphistar*np.cos(phi), np.zeros_like(vphistar)))
        vdiff = (vstar.T-self.vsun).T

        dist, b, l = cartesian_to_spherical(xgrid-self.sunpos[0], ygrid-self.sunpos[1], zgrid-self.sunpos[2])
        p, q, r = normal_triad(l, b)

        vrad = np.zeros(xgrid.shape) * u.km/u.s
        pml = np.zeros(xgrid.shape) * u.mas/u.yr
        pmb = np.zeros(xgrid.shape) * u.mas/u.yr
        vtan = np.zeros(xgrid.shape) * u.km/u.s
        for i in range(xgrid.shape[0]):
            for j in range(xgrid.shape[1]):
                vrad[i,j] = np.dot(r[:,i,j], vdiff[:,i,j])
                pml[i,j] = (np.dot(p[:,i,j], vdiff[:,i,j]).to(u.km/u.s)/(dist[i,j].to(u.kpc) *
                    _au_km_year_per_sec)).value*u.mas/u.yr
                pmb[i,j] = (np.dot(q[:,i,j], vdiff[:,i,j]).to(u.km/u.s)/(dist[i,j].to(u.kpc) *
                    _au_km_year_per_sec)).value*u.mas/u.yr
        vtan = np.sqrt(vdiff[0,:,:]**2+vdiff[1,:,:]**2+vdiff[2,:,:]**2-vrad**2)

        return pml, pmb, vrad, vtan, p, q, r

