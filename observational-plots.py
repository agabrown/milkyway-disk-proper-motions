"""
Produce observational counterparts of the material contained in the animation that explains Milky Way differential
rotation and how this leads to the observed proper motion in galactic longitude vs galactic longitude plot.

Anthony Brown May 2022 - May 2022
"""

import numpy as np
import matplotlib.pyplot as plt
import argparse
from matplotlib.gridspec import GridSpec
from matplotlib.cm import ScalarMappable
from matplotlib.colors import LogNorm, Normalize
from mpl_toolkits.axes_grid1.inset_locator import inset_axes

from astropy.table import Table
import astropy.units as u
import astropy.constants as c
from astropy.coordinates import Galactocentric, ICRS, CartesianDifferential
from astropy.visualization import HistEqStretch, ImageNormalize
au_km_year_per_sec = (c.au / (1*u.yr).to(u.s)).to(u.km/u.s).value

from agabpylib.plotting.plotstyles import useagab, apply_tufte
from agabpylib.stats.robuststats import rse
from pygaia.astrometry.constants import au_km_year_per_sec as Av
from pygaia.astrometry.coordinates import Transformations, CoordinateTransformation

from gala.potential.potential.builtin.special import BovyMWPotential2014
from diskkinematicmodel import *
from icrstogal import *

_Rsun = 8277.0*u.pc
_Zsun = 20.8*u.pc


def load_data(infile):
    """
    Load the data from the input file and calculate quantities in the Galactic (Cartesian) coordinate system.

    Parameters
    ----------

    infile : string
        Location of input file.

    Returns
    -------

    Astropy Table with the data.
    """
    obatable = Table.read(infile, format='fits')
    obatable['parallax_over_error'] = obatable['parallax']/obatable['parallax_error']
    obatable['vtan'] = (au_km_year_per_sec/obatable['parallax'] * np.sqrt(obatable['pmra']**2 +
        obatable['pmdec']**2)).value*u.km/u.s

    ct = CoordinateTransformation(Transformations.ICRS2GAL)

    l, b = ct.transform_sky_coordinates(np.deg2rad(obatable['ra']), np.deg2rad(obatable['dec']))
    obatable['l'] = np.rad2deg(l)
    obatable['b'] = np.rad2deg(b)
    obatable['pml'], obatable['pmb'] = ct.transform_proper_motions(np.deg2rad(obatable['ra']),
            np.deg2rad(obatable['dec']), obatable['pmra'], obatable['pmdec'])
    obatable['pml_error'], obatable['pmb_error'], obatable['pml_pmb_corr'] = \
            ct.transform_proper_motion_errors(np.deg2rad(obatable['ra']), np.deg2rad(obatable['dec']),
                    obatable['pmra_error'], obatable['pmdec_error'], rho_muphi_mutheta=obatable['pmra_pmdec_corr'])

    icrs_coords = ICRS(ra = (obatable['ra'].data*u.deg).to(u.rad),
            dec = (obatable['dec'].data*u.deg).to(u.rad),
            distance = (1000/obatable['parallax'].data)*u.pc,
            pm_ra_cosdec = obatable['pmra'].data*u.mas/u.yr,
            pm_dec = obatable['pmdec'].data*u.mas/u.yr,
            radial_velocity = obatable['ra'].value*0.0*u.km/u.s)

    galactic_coords, galactocentric_cartesian, galactocentric_cylindrical = transform_to_galactic(icrs_coords,
            galcendist=_Rsun, sunheight=_Zsun)

    obatable['x_gc'] = galactocentric_cartesian.x
    obatable['y_gc'] = galactocentric_cartesian.y
    obatable['z_gc'] = galactocentric_cartesian.z
    obatable['R_gc'] = galactocentric_cylindrical.rho

    return obatable


def make_plots(args):
    """
    Excecute the various steps to create the plots.

    Parameters
    ----------

    args : dict
        Command line arguments

    Returns
    -------

    Nothing
    """
    if args['type'] in ['O','B','A']:
        dr3table = load_data('data/OBA_NORR_R03_extended_redd.fits')
    elif args['type'] in ['F', 'G', 'K', 'M', 'giants']:
        dr3table = load_data('data/FGKM_gold.fits')
    else:
        print("Unknown source type!")
        exit(0);

    plx_snrlim = 10
    vtanhalo = 180.0
    zmax = 250

    plxfilter = dr3table['parallax_over_error']>plx_snrlim
    nonhalo = dr3table['vtan'] < vtanhalo
    zfilter = np.abs(np.sin(np.deg2rad(dr3table['b']))*1000/dr3table['parallax']) < zmax

    if args['type'] in ['O','B','A']:
        startype = (dr3table['spectraltype_esphs'] == args['type'])
    elif args['type'] == 'F':
        startype = (dr3table['logg_gspphot'] > 4.0) & (dr3table['teff_gspphot'] > 6000)
    elif args['type'] == 'G':
        startype = (dr3table['logg_gspphot'] > 4.0) & (dr3table['teff_gspphot'] <= 6000) & (dr3table['teff_gspphot'] > 5000)
    elif args['type'] == 'K':
        startype = (dr3table['logg_gspphot'] > 4.0) & (dr3table['teff_gspphot'] <= 5000) & (dr3table['teff_gspphot'] > 4000)
    elif args['type'] == 'M':
        startype = (dr3table['logg_gspphot'] > 4.0) & (dr3table['teff_gspphot'] <= 4000)
    else:
        startype = (dr3table['logg_gspphot'] <= 3.0)

    name = args['type']+'_'
    annotation = args['type']+' stars'

    sample_filter =  startype & plxfilter & nonhalo & zfilter

    print(f"Number of stars in selected sample: {dr3table['ra'][sample_filter].size}")

    useagab(axislinewidths=2)
    fig, ax_lmul = plt.subplots(1, 1, tight_layout=True, figsize=(14,5))

    im_lmul = ax_lmul.hexbin(dr3table['l'][sample_filter], dr3table['pml'][sample_filter], 
                             gridsize=[360,100], mincnt=1, bins='log', extent=[0,360,-20,20])
    ax_lmul.set_xlabel(r'Galactic longitude')
    ax_lmul.xaxis.set_major_formatter('${x:.0f}^\circ$')
    if args['simpleLang']:
        ax_lmul.set_ylabel(r'$\mu$ [mas yr$^{-1}$]')
        #ax_lmul.set_ylabel(r'Speed on the sky $\longrightarrow$')
        #ax_lmul.tick_params(left=False, labelleft=False)
    else:
        ax_lmul.set_ylabel(r'$\mu_{\ell*}$ [mas yr$^{-1}$]')
    ax_lmul.set_xlim(0,360)

    plt.savefig('img/'+name+'star_pml_vs_galon.png')
    plt.close()

    fig, ax_xy = plt.subplots(1, 1, figsize=(8,8), tight_layout=True)
    ax_xy.hexbin(dr3table['x_gc'][sample_filter]/1000, dr3table['y_gc'][sample_filter]/1000, mincnt=1, bins='log',
            extent=[-15,-4,-8,8], gridsize=200)
    ax_xy.set_xlabel(r'$X$ [kpc]')
    ax_xy.set_ylabel(r'$Y$ [kpc]')

    plt.savefig('img/'+name+'star_galactic_xy.png')
    plt.close()

    fig = plt.figure(constrained_layout=True, figsize=(10,8))
    gs = GridSpec(1, 2, figure=fig, width_ratios=[8,2])
    ax_xy_pml = fig.add_subplot(gs[0,0])

    im_xy_pml = ax_xy_pml.hexbin(dr3table['x_gc'][sample_filter]/1000, dr3table['y_gc'][sample_filter]/1000, mincnt=0,
            C=dr3table['pml'][sample_filter], extent=[-15,-4,-8,8], gridsize=200, reduce_C_function=np.median,
            cmap='plasma')
    ax_xy_pml.clear()
    imnorm = ImageNormalize(im_xy_pml.get_array(), stretch=HistEqStretch(im_xy_pml.get_array()))
    im_xy_pml =ax_xy_pml.hexbin(dr3table['x_gc'][sample_filter]/1000, dr3table['y_gc'][sample_filter]/1000, mincnt=0,
            C=dr3table['pml'][sample_filter], extent=[-15,-4,-8,8], gridsize=200, reduce_C_function=np.median,
            cmap='plasma', norm=imnorm)
    ax_xy_pml.set_xlabel(r'$X$ [kpc]')
    ax_xy_pml.set_ylabel(r'$Y$ [kpc]')
    cax_xy_pml = inset_axes(ax_xy_pml, "2.5%", "90%", loc='center left', 
                       bbox_to_anchor=(1.05, 0., 1, 1),
                       bbox_transform=ax_xy_pml.transAxes,
                       borderpad=0)
    cbar = fig.colorbar(im_xy_pml, cax=cax_xy_pml, ticks=[-5,-2,0,1])
    cbar.set_label(r'median $\mu_{\ell*}$ [mas yr$^{-1}$]')

    plt.savefig('img/'+name+'star_galactic_xy_pml.png')
    plt.close()


def parseCommandLineArguments():
    """
    Set up command line parsing.
    """
    parser = argparse.ArgumentParser(description="""Observational plots to accompany animation""")
    parser.add_argument("--type", type=str, default='B', help="""Source type to plot: O, B, A, F, G, K, M, giants""")
    parser.add_argument("-l", action="store_true", dest="simpleLang", help="Simplify language on the axes")
    parser.add_argument("-p", action="store_true", dest="pdfOutput", help="Make PDF plots")
    parser.add_argument("-b", action="store_true", dest="pngOutput", help="Make PNG plots")
    cmdargs = vars(parser.parse_args())
    return cmdargs


if __name__ in ('__main__'):
    make_plots(parseCommandLineArguments())

