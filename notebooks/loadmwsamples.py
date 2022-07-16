"""
Functions for loading the Gaia DR3 samples from FITS files downloaded from the archive. These are samples intended for
analysis of the Milky Way disk rotation curve and residual kinematics. The following are calculated from the input data:
    - radial velocity corrections as reported in Blomme et al (arXiv:2206.05486) and Katz et al (arXiv:2206.05902)
    - radial velocity uncertainty corrections as reported in Babusiaux et al (arXiv:2206.05989)
    - transformations to galactic coordinates (positions, proper motions)
    - transformations to Galactocentric Cartesian and cylindrical coordinates
    - Apply extinction corrections to G, G_BP, G_RP

Anthony Brown Jul 2022 - Jul 2022
"""

import numpy as np

from astropy.table import Table
import astropy.units as u
import astropy.constants as c
from astropy.coordinates import Galactocentric, ICRS, CartesianDifferential
au_km_year_per_sec = (c.au / (1*u.yr).to(u.s)).to(u.km/u.s).value

from pygaia.astrometry.coordinates import Transformations, CoordinateTransformation
from icrstogal import *
from diskkinematicmodel import *

ct = CoordinateTransformation(Transformations.ICRS2GAL)

_Rsun = 8277.0*u.pc
_zsun = 20.8*u.pc
_sunpos = np.array([-_Rsun.value, 0, _zsun.value])*u.pc
_vsunpeculiar = np.array([11.1, 12.24, 7.25])*u.km/u.s
_diskmodel = DiskKinematicModel(BovyMWPotential2014(), _sunpos, _vsunpeculiar)
_vcircsun = _diskmodel.get_circular_velocity(_sunpos)[0]


def correct_radvel_uncertainty(dr3_radvel_unc, dr3_grvs):
    """
    Apply the radial velocity uncertainty inflation factors recommended for Gaia DR3.

    Parameters
    ----------

    dr3_radvel_unc: float array
        Radial velocity uncertainty as listed in Gaia DR3
    dr3_grvs: float array
        G_rvs magnitude

    Returns
    -------

    Inflated radial velocity uncertainties as float array.
    """
    infl_factor = np.ones_like(dr3_radvel_unc)
    bright = (dr3_grvs>8) & (dr3_grvs<=12.0)
    faint = dr3_grvs>12.0
    infl_factor[bright] = 0.318 + 0.3884*dr3_grvs[bright] - 0.02778*dr3_grvs[bright]**2
    infl_factor[faint] = 16.554 - 2.4899*dr3_grvs[faint] + 0.09933*dr3_grvs[faint]**2
    return infl_factor * dr3_radvel_unc


def correct_radvel(dr3_radvel, dr3_template_teff, dr3_grvs):
    """
    Apply the radial velocity corrections recommended for Gaia DR3.

    Parameters
    ----------

    dr3_radvel : float array
        Radial velocity as listed in Gaia DR3
    dr3_template_teff: float array
        Effective temperature of spectral template used for radial velocity determination
    dr3_grvs: float array
        G_rvs magnitude

    Returns
    -------

    Corrected radial velocities as float array.
    """
    radvel_correct = dr3_radvel
    hot = (dr3_template_teff>=8500.0) & (dr3_template_teff<=14500.0) & (dr3_grvs>=6.0) & (dr3_grvs<=12.0)
    cool = (dr3_grvs>=11.0) & (dr3_template_teff<8500.0)
    radvel_correct[hot] = radvel_correct[hot] - 7.98 + 1.135*dr3_grvs[hot]
    radvel_correct[cool] = radvel_correct[cool] + 0.02755*dr3_grvs[cool]**2 - 0.55863*dr3_grvs[cool] + 2.81129
    return radvel_correct


def load_mwtable(file, esphs=True, Rsun=_Rsun, zsun=_zsun, sunpos=_sunpos, vsunpeculiar=_vsunpeculiar, vcircsun=_vcircsun):
    """
    Load the table. The table is expected to be in FITS format and the following Gaia DR3 data are expected to be
    present:

    gaiadr3.gaia_source: ra, dec, parallax, pmra, pmdec, radial_velocity, parallax_over_error,
                         pmra_error, pmdec_error, pmra_pmdec_corr,
                         radial_velocity_error, grvs_mag, rv_template_teff, phot_g_mean_mag, bp_rp

    gaiadr3.astrophysical_parameters: ag_gspphot, ebpminrp_gspphot
    Optional gaiadr3.astrophysical_parameters: ag_esphs, ebpminrp_esphs

    Parameters
    ----------

    file : string
        Path to the FITS file with the Gaia DR3 archive data
    esphs: boolean
        If true the esphs columns from gaiadr3.astrophysical_parameters are present

    Returns
    -------

    Table with additional columns containing the corrections applied and the quantities calculated from the input data.
    """

    gaiatable = Table.read(file, format='fits')

    gaiatable['rvvalid'] = np.logical_not(np.isnan(gaiatable['radial_velocity']))
    gaiatable['parallax_over_error'] = gaiatable['parallax']/gaiatable['parallax_error']
    gaiatable['vtan'] = (au_km_year_per_sec/gaiatable['parallax']*np.sqrt(gaiatable['pmra']**2+gaiatable['pmdec']**2)).value*u.km/u.s
    gaiatable['radial_velocity_corrected'] = gaiatable['radial_velocity']
    gaiatable['radial_velocity_corrected'][gaiatable['rvvalid']] = correct_radvel(gaiatable['radial_velocity'][gaiatable['rvvalid']], 
        gaiatable['rv_template_teff'][gaiatable['rvvalid']], gaiatable['grvs_mag'][gaiatable['rvvalid']])
    gaiatable['radial_velocity_error_corrected'] = gaiatable['radial_velocity_error']
    gaiatable['radial_velocity_error_corrected'][gaiatable['rvvalid']] = correct_radvel_uncertainty(gaiatable['radial_velocity_error'][gaiatable['rvvalid']], 
        gaiatable['grvs_mag'][gaiatable['rvvalid']])
    vrad = gaiatable['radial_velocity_corrected'].data
    vrad[np.logical_not(gaiatable['rvvalid'])] = 0.0
 
    icrs_coords = ICRS(ra = (gaiatable['ra'].data*u.deg).to(u.rad),
            dec = (gaiatable['dec'].data*u.deg).to(u.rad),
            distance = (1000/gaiatable['parallax'].data)*u.pc,
            pm_ra_cosdec = gaiatable['pmra'].data*u.mas/u.yr,
            pm_dec = gaiatable['pmdec'].data*u.mas/u.yr,
            radial_velocity = vrad*u.km/u.s)

    galactic_coords, galactocentric_cartesian, galactocentric_cylindrical = transform_to_galactic(icrs_coords,
            galcendist=Rsun, sunheight=zsun, vcircsun=vcircsun, vsunpec=vsunpeculiar)

    l, b = ct.transform_sky_coordinates(np.deg2rad(gaiatable['ra']), np.deg2rad(gaiatable['dec']))
    gaiatable['l'] = np.rad2deg(l)
    gaiatable['b'] = np.rad2deg(b)
    gaiatable['pml'], gaiatable['pmb'] = ct.transform_proper_motions(np.deg2rad(gaiatable['ra']), 
        np.deg2rad(gaiatable['dec']), gaiatable['pmra'], gaiatable['pmdec'])
    gaiatable['pml_error'], gaiatable['pmb_error'], gaiatable['pml_pmb_corr'] = \
        ct.transform_proper_motion_errors(np.deg2rad(gaiatable['ra']), np.deg2rad(gaiatable['dec']), \
        gaiatable['pmra_error'], gaiatable['pmdec_error'], rho_muphi_mutheta=gaiatable['pmra_pmdec_corr'])

    gaiatable['l'] = galactic_coords.l.to(u.deg)
    gaiatable['b'] = galactic_coords.b.to(u.deg)
    gaiatable['pml'] = galactic_coords.pm_l_cosb
    gaiatable['pmb'] = galactic_coords.pm_b

    gaiatable['x_gc'] = galactocentric_cartesian.x
    gaiatable['y_gc'] = galactocentric_cartesian.y
    gaiatable['z_gc'] = galactocentric_cartesian.z
    gaiatable['v_x_gc'] = galactocentric_cartesian.v_x
    gaiatable['v_y_gc'] = galactocentric_cartesian.v_y
    gaiatable['v_z_gc'] = galactocentric_cartesian.v_z

    # Convert Cylindrical into conventional units (km/s for the velocities, making v_phi positive along
    # the direction of Galactic rotation).
    #
    gaiatable['R_gc'] = galactocentric_cylindrical.rho
    phi = galactocentric_cylindrical.phi.to(u.deg)
    gaiatable['phi_gc'] = np.where(phi<0*u.deg, phi+360*u.deg, phi.to(u.deg))*u.deg
    gaiatable['v_R_gc'] = galactocentric_cylindrical.d_rho.to(u.km/u.s)
    #
    # In the literature vphi is calculated for a left-handed coordinate system! 
    # This is for the convenience of having postive values of vphi at the position of the sun.
    #
    gaiatable['v_phi_gc'] = -(galactocentric_cylindrical.d_phi.to(u.rad/u.yr)/u.rad * galactocentric_cylindrical.rho).to(u.km/u.s)
    gaiatable['vtot_lsr'] = np.sqrt(gaiatable['v_R_gc']**2 + (gaiatable['v_phi_gc']-vcircsun.value)**2 + gaiatable['v_z_gc']**2)

    gaiatable['gmag0_gspphot'] = gaiatable['phot_g_mean_mag'] - gaiatable['ag_gspphot']
    gaiatable['bp_rp0_gspphot'] = gaiatable['bp_rp'] - gaiatable['ebpminrp_gspphot']
    gaiatable['mg_abs0_gspphot'] = gaiatable['gmag0_gspphot'] + 5*np.log10(gaiatable['parallax'])-10
    if (esphs):
        gaiatable['gmag0_esphs'] = gaiatable['phot_g_mean_mag'] - gaiatable['ag_esphs']
        gaiatable['bp_rp0_esphs'] = gaiatable['bp_rp'] - gaiatable['ebpminrp_esphs']
        gaiatable['mg_abs0_esphs'] = gaiatable['gmag0_esphs'] + 5*np.log10(gaiatable['parallax'])-10
        
    return gaiatable
