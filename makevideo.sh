#!/bin/sh

# Create the Milky disk rotation animation from the individual png images.

# Steps taken in the ffmpeg lines below
#
# 1 ffmpeg command
# 2 set frame rate and frames folder
# 3 select video codec and set resolution of output animation

USAGE="Usage: makevideo [-hf]"
USAGELONG="Usage: makevideo [-hf]\n -f framerate (frames/sec)\n -h help\n"
RESOLUTION="960x960"
IMFOLDER="frames"

while getopts ":hf:" options;
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
#shift $(($OPTIND-1))


ffmpeg \
    -framerate ${FRAMERATE} -i "${IMFOLDER}/frame-%06d.png" \
    -vcodec libx264 -s $RESOLUTION milkyway-rotation.mp4
