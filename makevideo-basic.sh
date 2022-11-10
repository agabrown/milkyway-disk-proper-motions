#!/bin/sh

# Create the Milky disk rotation animation from the individual png images.
# THIS VERSION CREATES THE VIDEO WITHOUT THE INTRO SLIDES AND WITHOUT THE CREDITS.
#
# Anthony Brown May 2022 - Nov 2022

# Steps taken in the ffmpeg lines below
#
# 1 ffmpeg command
# 2 Generate black backgrond image (stream [0:v])
# 3 Input frames for main animation (stream [8:v])
# 4 Add main animation frames on top of background layer 
# 5 Concatenate all streams
# 6 Select video codec and set resolution of output animation

USAGE='Usage: makevideo-basic [-hf]'
USAGELONG='Usage: makevideo-basic [-hf]\n -f framerate (frames/sec)\n -h help\n'
RESOLUTION='1080x1080'
IMFOLDER='frames'
FILEFMT='png'
FRAMERATE=30

while getopts ':hf:' options;
do
    case "$options" in
        f)
            FRAMERATE=$OPTARG
            echo ${FRAMERATE}
            ;;
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

ffmpeg \
    -framerate ${FRAMERATE} -i "${IMFOLDER}/frame-%06d.${FILEFMT}" \
    -pix_fmt yuv420p -vcodec libx264 -s $RESOLUTION video/milkyway-rotation-bare.mp4
