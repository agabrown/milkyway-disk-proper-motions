# Proper motions in the disk of the Milky Way

A simple animation is made with [Processing](https://processing.org/) which illustrates how the pattern of proper motions in galactic longitude, plotted as a function of longitude, arises from the differential rotation of the Milky Way's disk. This is part of the outreach for [Gaia DR3](https://www.cosmos.esa.int/web/gaia/data-release-3) in connection with the paper _Gaia Data Release 3: Golden Sample of Astrophysical Parameters Gaia Collaboration, Creevey, O.L., et al_.

## Reproducing the video

1. Download the necessary data (TODO: describe how)
2. Run `python observational-plots.py -l` and then do `cp img/B_star_pml_vs_galon.png`
3. Run `python intro-frames.py`
4. Run the Processing script and do not forget to uncomment the line `saveFrame("../frames/frame-######.png");`
5. Run `./makevideo.sh`
