"""
Create a set of introductory frames for the animated infographic on the proper motions of B stars.

Anthony Brown May 2022 - May 2022
"""
import argparse
import numpy as np
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from matplotlib.patches import FancyArrowPatch, ArrowStyle
import cartopy.crs as ccrs


def make_frames():
    """
    Execute the steps to create the frames.

    Parameters
    ----------

    Returns
    -------

    Nothing
    """
    gaiasky = plt.imread('img/Gaia_EDR3_flux_cartesian_2k.png')
    milkyway = plt.imread('img/mw_payne_wardenaar_rotated.jpg')

    default_proj = ccrs.PlateCarree()
    sky_proj = ccrs.Mollweide()

    fig = plt.figure(figsize=(16, 9), dpi=120, frameon=False, tight_layout={'pad': 0.01})
    gs = GridSpec(1, 1, figure=fig)
    ax = fig.add_subplot(gs[0, 0], projection=sky_proj)
    ax.imshow(gaiasky, transform=default_proj, origin='upper')
    plt.savefig("frames/intro-frame-A.png")
    
    ax.plot([-180,180], [0,0], c='w', lw=6, alpha=0.5, transform=default_proj)
    plt.savefig("frames/intro-frame-B.png")

    for galon, label in zip([-120,-60, 0, 60, 120], [120, 60, 0, 300, 240]):
        ax.plot([galon, galon], [-5,5], c='w', lw=3, transform=default_proj)
        ax.text(galon, -20, fr"$l={label}^\circ$", color='w', ha='center', fontsize=28, transform=default_proj)
    plt.savefig("frames/intro-frame-C.png")

    for galon in np.arange(-150,180,30):
        ax.arrow(galon, 15, -10, 0, color='w', linewidth=3, head_width=2, transform=default_proj)
    plt.savefig("frames/intro-frame-D.png")

    plt.close(fig)

    fig, ax = plt.subplots(1, 1, figsize=(9, 9), dpi=120, frameon=False, tight_layout={'pad': 0.01})
    ax.imshow(milkyway, origin='upper')
    ax.axis('off')
    rsun = 280
    ax.scatter(540-rsun, 540, color='C1', s=120)
    ax.text(540-rsun-20, 540, "Sun", ha='right', va='center', color='w', fontsize=20)
    ax.text(540, 960, "Milky way face-on view - artist's impression", ha='center', color='w', fontsize=20)
    startAngleDeg = 10
    endAngleDeg=70
    startAngle = np.deg2rad(startAngleDeg)
    endAngle = np.deg2rad(endAngleDeg)
    rotA = (540-np.cos(startAngle)*rsun, 540-np.sin(startAngle)*rsun)
    rotB = (540-np.cos(endAngle)*rsun, 540-np.sin(endAngle)*rsun)
    rotarrow = FancyArrowPatch(posA=rotA, posB=rotB, connectionstyle=f"angle3, angleA={90-startAngleDeg}, angleB={90-endAngleDeg}", 
        color='w', linewidth=3, arrowstyle="->, head_length=6, head_width=4")
    ax.add_artist(rotarrow)
    plt.savefig("frames/intro-frame-mw.png")

    plt.close(fig)


if __name__ in '__main__':
    make_frames()
