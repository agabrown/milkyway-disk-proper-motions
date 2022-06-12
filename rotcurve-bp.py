"""
Plot the rotation curve from Brunetti & Pfenniger (2010) for specified values of v0, h, and p.
The paper can be found at: https://ui.adsabs.harvard.edu/abs/2010A%26A...510A..34B/abstract

Anthony Brown May 2022 - June 2022
"""

import sys
sys.path.insert(1, './notebooks/')

import numpy as np
import matplotlib.pyplot as plt
import argparse

from plotstyles import useagab, apply_tufte


def make_plot(args):
    """
    Create the plot according to the specified command line arguments.

    Parameters
    ----------

    args : dict
        Command line parameters

    Return
    ------

    Nothing
    """

    r = np.linspace(0, 16, 1000)
    h = args['hlen']
    p = args['pexp']
    rotcur = lambda x : x/h * np.power(1 + (x/h)**2, (p-2)/4)

    v0 = args['vcsun']/rotcur(args['rsun'])
    vc = v0*rotcur(r)

    x = args['rsun']
    slopesun = v0*( (1/h)*np.power(1 + (x/h)**2, (p-2)/4) + (x**2/h**3)*((p-2)/2)*np.power(1 + (x/h)**2, (p-6)/4) )
    
    useagab()
    fig, ax = plt.subplots(1, 1, figsize=(8,6), tight_layout=True)
    apply_tufte(ax)

    ax.plot(r, vc, zorder=-1)
    if not args['dr3story']:
        ax.set_xlabel(r'$R$ [kpc]')
        ax.set_ylabel(r'$V_\mathrm{circ}$ [km s$^{-1}$]')
        ax.text(0.95, 0.33, fr"$p = {args['pexp']:.2f}$",
                transform=ax.transAxes, ha='right', fontsize=12)
        ax.text(0.95, 0.26, fr"$h = {args['hlen']:.1f}$ kpc",
                transform=ax.transAxes, ha='right', fontsize=12)
        ax.text(0.95, 0.19, fr"$R_\odot = {args['rsun']:.1f}$ kpc",
                transform=ax.transAxes, ha='right', fontsize=12)
        ax.text(0.95, 0.12, fr"$V_{{\mathrm{{circ}},\odot}} = {args['vcsun']:.1f}$ km s$^{{-1}}$",
                transform=ax.transAxes, ha='right', fontsize=12)
        ax.text(0.95, 0.05, fr'$dV_\mathrm{{circ}}/dR$ at sun: {slopesun:.1f} km s$^{{-1}}$ kpc$^{{-1}}$',
                transform=ax.transAxes, ha='right', fontsize=12)
    else:
        ax.scatter(x, v0*rotcur(x), c='C1', s=100)
        ax.set_xlabel(r'Distance $R$ in kiloparsec')
        ax.set_ylabel(r'Rotation speed $V$ in km/s')


    basename = 'RotationCurve-BP2010'
    if args['pdfOutput']:
        plt.savefig('img/'+basename+'.pdf')
    elif args['pngOutput']:
        plt.savefig('img/'+basename+'.png')
    else:
        plt.show()



def parseCommandLineArguments():
    """
    Set up command line parsing.
    """
    parser = argparse.ArgumentParser(description="""Rotation curve from Brunetti and Pfenniger (2010).""")
    parser.add_argument("--pexp", dest='pexp', type=float, default=-0.55, help="""Exponent p in equation""")
    parser.add_argument("--scalelength", dest='hlen', type=float, default=3.0, help="""Potential scale length (kpc)""")
    parser.add_argument("--vcsun", dest='vcsun', type=float, default=234.0, help="""Circular velocity for the sun (km/s)""")
    parser.add_argument("--rsun", dest='rsun', type=float, default=8.277, help="""Distance sun to Galactic centre (kpc)""")
    parser.add_argument("--dr3story", action="store_true", dest="dr3story", help="""Produce a version for the Gaia DR3 story on Milky Way rotation""")
    parser.add_argument("-p", action="store_true", dest="pdfOutput", help="Make PDF plot")
    parser.add_argument("-b", action="store_true", dest="pngOutput", help="Make PNG plot")
    cmdargs = vars(parser.parse_args())
    return cmdargs


if __name__ in ('__main__'):
    make_plot(parseCommandLineArguments())

