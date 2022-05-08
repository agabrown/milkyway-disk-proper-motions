#!/bin/sh

# Create the Milky disk rotation animation from the individual png images.

# Steps taken in the ffmpeg lines below
#
# 1 ffmpeg command
# 2 set frame rate and frames folder
# 3 select video codec and set resolution of output animation

USAGE="Usage: makevideo [-h]"
USAGELONG="Usage: makevideo [-h]\n -h help\n"
RESOLUTION="960x960"
IMFOLDER="frames"

while getopts "h" options;
do
    case $options in
        h)
            echo -e $USAGELONG
            exit 0
            ;;
        \?)
            echo $USAGE
            exit 1
            ;;
    esac
done
shift $(($OPTIND-1))


ffmpeg \
    -framerate 60 -i "${IMFOLDER}/frame-%06d.png" \
    -vcodec libx264 -s $RESOLUTION milkyway-rotation.mp4
