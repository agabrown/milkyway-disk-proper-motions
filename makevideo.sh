#!/bin/sh

# Create the Milky disk rotation animation from the individual png images.

# Steps taken in the ffmpeg lines below
#
# 1 ffmpeg command
# 2 generate black backgrond image (stream [0:v])
# 2 set frame rate and frames folder
# 3 select video codec and set resolution of output animation

USAGE="Usage: makevideo [-hf]"
USAGELONG="Usage: makevideo [-hf]\n -f framerate (frames/sec)\n -h help\n"
RESOLUTION="1920x1080"
IMFOLDER="frames"
FILEFMT="png"
FONTFILE="/usr/share/fonts/corefonts/andalemo.ttf"
FRAMERATE=30
EXPLFILE_A="text/introA.txt"
EXPLFILE_B="text/introB.txt"
EXPLFILE_C="text/introC.txt"
EXPLFILE_D="text/introD.txt"

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


#    -framerate ${FRAMERATE} -i "${IMFOLDER}/frame-%06d.${FILEFMT}" \

#    -filter_complex \
#    "[0:v][1:v]overlay=shortest=1, \
#    drawbox=w=iw:h=ih:color=black@0.5:t=fill,drawtext=fontfile=${FONTFILE}: \
#    textfile=${EXPLFILE_A}:fontcolor_expr=ffffff:fontsize=28:line_spacing=14:box=0: \
#    x=(w-text_w)/2:y=80, \
#    fade=type=out:duration=1:start_time=9,format=yuv420p[v0]; \
#    [2:v]fade=type=out:duration=1:start_time=19,format=yuv420p[v1]; \
#    [v0][v1]concat=n=2" \
ffmpeg \
    -f lavfi -i "color=c=black:s=${RESOLUTION}:r=${FRAMERATE}" \
    -loop 1 -framerate $FRAMERATE -t 10 -i "${IMFOLDER}/intro-frame-A.${FILEFMT}" \
    -loop 1 -framerate $FRAMERATE -t 10 -i "${IMFOLDER}/intro-frame-B.${FILEFMT}" \
    -loop 1 -framerate $FRAMERATE -t 10 -i "${IMFOLDER}/intro-frame-C.${FILEFMT}" \
    -loop 1 -framerate $FRAMERATE -t 10 -i "${IMFOLDER}/intro-frame-D.${FILEFMT}" \
    -filter_complex \
    "[0:v][1:v]overlay=shortest=1,
    drawtext=fontfile=${FONTFILE}:textfile=${EXPLFILE_A}:fontcolor_expr=ffffff:
    fontsize=28:line_spacing=14:box=0:x=(w-text_w)/2:y=80,
    format=yuv420p[v0];
    [0:v][2:v]overlay=shortest=1,
    drawtext=fontfile=${FONTFILE}:textfile=${EXPLFILE_B}:fontcolor_expr=ffffff:
    fontsize=28:line_spacing=14:box=0:x=(w-text_w)/2:y=80,
    format=yuv420p[v1];
    [0:v][3:v]overlay=shortest=1,
    drawtext=fontfile=${FONTFILE}:textfile=${EXPLFILE_C}:fontcolor_expr=ffffff:
    fontsize=28:line_spacing=14:box=0:x=(w-text_w)/2:y=80,
    format=yuv420p[v2];
    [0:v][4:v]overlay=shortest=1,
    drawtext=fontfile=${FONTFILE}:textfile=${EXPLFILE_D}:fontcolor_expr=ffffff:
    fontsize=28:line_spacing=14:box=0:x=(w-text_w)/2:y=80,
    format=yuv420p[v3];
    [v0][v1][v2][v3]concat=n=4" \
    -pix_fmt yuv420p -vcodec libx264 -s $RESOLUTION video/milkyway-rotation.mp4
