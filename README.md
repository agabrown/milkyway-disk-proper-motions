# Proper motions in the disk of the Milky Way

An [animated infographic](https://youtu.be/EjAUqRwGlaQ) is made with which illustrates how the wavy pattern in a plot of proper motions in galactic longitude as a function of longitude arises from the differential rotation of the Milky Way's disk. This is part of the outreach for [Gaia DR3](https://www.cosmos.esa.int/web/gaia/data-release-3) in connection with the paper _Gaia Data Release 3: Golden Sample of Astrophysical Parameters Gaia Collaboration, Creevey, O.L., et al., 2022, A&A_.

<img src=./frames/B_star_pml_vs_galon.png></img>

## Repository contents

* `data` folder with data from the Golden sample paper
* `notebooks` Jupyter notebooks with code to reproduce the analysis of the OBA sample and the Milky Way rotation curve modelling from the Golden Sample paper.
  - This folder also contains the [Stan](https://mc-stan.org/) model code.
* `mw_disk_rotation` folder with the Processing and Java code for the animation of the rotating disk
* `img`, `text`, `frames`, `video` folder containing the images produced with the Python code, the video text and frames, and the video (frames and video are not stored on Github)

## Reproducing the video

1. Download the necessary data (see [this notebook](./notebooks/FitMWDiskKinModel.ipynb)).
2. Run `python observational-plots.py -l` and then do `cp img/B_star_pml_vs_galon.png`
3. Run `python intro-frames.py`
4. Run the Processing script and do not forget to uncomment the line `saveFrame("../frames/frame-######.png");`. NOTE: this also generates a file `lines-ffmpeg.txt` (not stored on Github) which contains the timings and input text files for the captions with the Processing animation. It will be read by the bash-script below.
5. Run `./makevideo.sh`

## Tools used for making the video
* Main animation: [Processing](https://processing.org/)
* Stills: [Python](https://python.org), [Matplotlib](https://matplotlib.org), [Cartopy](https://scitools.org.uk/cartopy/docs/latest/)
* Adding frames together and overlaying text: [FFmpeg](https://ffmpeg.org/), [GNU Bash](https://www.gnu.org/software/bash/)

## Credits

Credits: ESA/Gaia/DPAC

Video license: CC BY-SA 3.0 IGO

### Acknowledgements
Based on the paper by the Gaia Collaboration _Gaia Data Release 3: A Golden Sample of Astrophysical Parameters_

Gaia Data Release 3 was published on June 13, 2022

Main Video/Data sets: ESA/Gaia/DPAC, Anthony Brown, Yves Frémat, Orlagh Creevey, Rosanna Sordo, Céline Reylé, Tineke Roegiers

Narrator: Orlagh Creevey

Ideas for video inspired by: [Brunetti & Pfenniger, 2010, A&A 510, A34](https://ui.adsabs.harvard.edu/abs/2010A%26A...510A..34B/abstract)

Night sky image: ESA/Gaia/DPAC/André Moitinho, CC BY-SA 3.0 IGO

Milky Way image: Stefan Payne-Wardenaar/MPIA
