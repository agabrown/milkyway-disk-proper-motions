"""
Provide functions for calculating Galactocentric phase space coordinates from Gaia data.

Code from https://github.com/agabrown/gaiadr2-6dgold-example

Anthony Brown Jan 2022 - Jan 2022
"""

import numpy as np
import astropy.units as u
from astropy.coordinates import ICRS, Galactic, CartesianDifferential, Galactocentric

# Choice for Sun's phase space coordinates for transformation to Galactocentric reference frame.
# Distance from https://ui.adsabs.harvard.edu/abs/2021A%26A...647A..59G/abstract
# zsun from https://ui.adsabs.harvard.edu/#abs/2019MNRAS.482.1417B/abstract
# vc from https://ui.adsabs.harvard.edu/#abs/2014ApJ...783..130R/abstract
# uvw from https://doi.org/10.1111/j.1365-2966.2010.16253.x

_Rsun = 8277.0*u.pc
_zsun = 20.8*u.pc
_vc = 240.0*u.km/u.s
_Usun = 11.1
_Vsun = 12.24
_Wsun = 7.25

def transform_to_galactic(icrs_coords, galcendist=_Rsun, sunheight=_zsun, vcircsun=_vc, 
        vsunpec=np.array([_Usun, _Vsun, _Wsun])*u.km/u.s):
    """
    For the input astrometry plus radial velocity in the ICRS system calculate the barycentric Galactic
    coordinates as well as Galactocentric coordinates.

    Parameters
    ----------

    icrs_coords: astropy.coordinates.ICRS
        ICRS instance constructed from the 5-parameter Gaia DR2 astrometry and the radial velocity.

    Kwargs
    ------

    galcendist: astropy Quantity
        Distance from sun to Galactic centre, in pc
    sunheight: astropy Quantity
        Height of sun above the Galactic plane, in pc
    vcircsun: astropy Quantity
        Circular velocity at the sun's galactocentric radius, in km/s
    vsunpec: astropy Quantity 3-element array
        Sun's peculiar velocity in galactocentric Cartesian coordinates, in km/s.

    Returns
    -------

    Galactic and Galactocentric objects containing the astrometry in Galactic coordinates, the
    galactocentric Cartesian coordinates, and the galactocentric cylindrical coordinates.
    """

    galactic_coords = icrs_coords.transform_to(Galactic())
    sun_motion = CartesianDifferential(vsunpec[0], vcircsun+vsunpec[1], vsunpec[2])
    galactocentric_cartesian = icrs_coords.transform_to(Galactocentric(galcen_distance=galcendist, z_sun=sunheight, galcen_v_sun=sun_motion))
    galactocentric_cartesian.set_representation_cls(base='cartesian')
    galactocentric_cylindrical = icrs_coords.transform_to(Galactocentric(galcen_distance=galcendist, z_sun=sunheight, galcen_v_sun=sun_motion))
    galactocentric_cylindrical.set_representation_cls(base='cylindrical')

    return galactic_coords, galactocentric_cartesian, galactocentric_cylindrical
