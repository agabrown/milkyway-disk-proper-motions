#!/bin/sh

# Create the Milky disk rotation animation from the individual png images.
#
# Anthony Brown May 2022 - May 2022

# Steps taken in the ffmpeg lines below
#
# 1 ffmpeg command
# 2 Generate black backgrond image (stream [0:v])
# 3 First introductory frame, loop for the number of seconds after "-t" (stream [1:v])
# 4 Second introductory frame, loop for the number of seconds after "-t" (stream [2:v])
# 5 Third introductory frame, loop for the number of seconds after "-t" (stream [3:v])
# 6 Fourth introductory frame, loop for the number of seconds after "-t" (stream [4:v])
# 7 Fifth introductory frame, loop for the number of seconds after "-t" (stream [5:v])
# 8 Fifth introductory frame (repeats here for different text), loop for the number of seconds after "-t" (stream [6:v])
# 9 Sixth introductory frame, loop for the number of seconds after "-t" (stream [7:v])
# 10 Input frames for main animation (stream [8:v])
# 11 Start of complex filter graph for adding text to the animation
# 12-15 Add text for first introductory frame (overlay [1:v] on [0:v], draw text, store in yuv420 format in [v0])
# 16-19 Add text for second introductory frame 
# 20-23 Add text for third introductory frame 
# 24-27 Add text for fourth introductory frame 
# 28-31 Add text for fifth introductory frame
# 32-35 Add text for sixth introductory frame
# 36 Add main animation frames on top of background layer and add the text corresponding to
#    the various animation phases (this is the string $FFLINES)
# 37-40 Add the credits
# 41 Concatenate all streams
# 42 Select video codec and set resolution of output animation

USAGE='Usage: makevideo [-hf]'
USAGELONG='Usage: makevideo [-hf]\n -f framerate (frames/sec)\n -h help\n'
RESOLUTION='1920x1080'
IMFOLDER='frames'
FILEFMT='png'
FONTFILE='/usr/share/fonts/roboto/Roboto-Medium.ttf'
FONTSIZE=32
LINESPACING=16
FONTSIZE_CREDITS=28
LINESPACING_CREDITS=14
FRAMERATE=30
EXPLFILE_A='text/introA.txt'
EXPLFILE_B='text/introB.txt'
EXPLFILE_C='text/introC.txt'
EXPLFILE_D='text/introD.txt'
EXPLFILE_E='text/introE.txt'
EXPLFILE_F='text/introF.txt'
CREDITS='text/credits.txt'
DURATION_INTRO_A=10
DURATION_INTRO_B=10
DURATION_INTRO_C=10
DURATION_INTRO_D=10
DURATION_INTRO_E=12
DURATION_INTRO_F=15
DURATION_CREDITS=20

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

FFLINES=""
while read line;
do
    eval ffline=$line
    FFLINES+="$ffline"
done < lines-ffmpeg.txt

ffmpeg \
    -f lavfi -i "color=c=black:s=${RESOLUTION}:r=${FRAMERATE}" \
    -loop 1 -framerate $FRAMERATE -t ${DURATION_INTRO_A} -i "${IMFOLDER}/intro-frame-A.${FILEFMT}" \
    -loop 1 -framerate $FRAMERATE -t ${DURATION_INTRO_B} -i "${IMFOLDER}/intro-frame-B.${FILEFMT}" \
    -loop 1 -framerate $FRAMERATE -t ${DURATION_INTRO_C} -i "${IMFOLDER}/intro-frame-C.${FILEFMT}" \
    -loop 1 -framerate $FRAMERATE -t ${DURATION_INTRO_D} -i "${IMFOLDER}/intro-frame-D.${FILEFMT}" \
    -loop 1 -framerate $FRAMERATE -t ${DURATION_INTRO_E} -i "${IMFOLDER}/B_star_pml_vs_galon.${FILEFMT}" \
    -loop 1 -framerate $FRAMERATE -t ${DURATION_INTRO_F} -i "${IMFOLDER}/intro-frame-mw.${FILEFMT}" \
    -framerate ${FRAMERATE} -i "${IMFOLDER}/frame-%06d.${FILEFMT}" \
    -loop 1 -framerate $FRAMERATE -t ${DURATION_CREDITS} -i "${IMFOLDER}/intro-frame-A.${FILEFMT}" \
    -filter_complex \
    "[0:v][1:v]overlay=shortest=1,
    drawtext=fontfile=${FONTFILE}:textfile=${EXPLFILE_A}:fontcolor_expr=ffffff:
    fontsize=${FONTSIZE}:line_spacing=${LINESPACING}:box=0:x=(w-text_w)/2:y=80,
    format=yuv420p[v0];
    [0:v][2:v]overlay=shortest=1,
    drawtext=fontfile=${FONTFILE}:textfile=${EXPLFILE_B}:fontcolor_expr=ffffff:
    fontsize=${FONTSIZE}:line_spacing=${LINESPACING}:box=0:x=(w-text_w)/2:y=80,
    format=yuv420p[v1];
    [0:v][3:v]overlay=shortest=1,
    drawtext=fontfile=${FONTFILE}:textfile=${EXPLFILE_C}:fontcolor_expr=ffffff:
    fontsize=${FONTSIZE}:line_spacing=${LINESPACING}:box=0:x=(w-text_w)/2:y=80,
    format=yuv420p[v2];
    [0:v][4:v]overlay=shortest=1,
    drawtext=fontfile=${FONTFILE}:textfile=${EXPLFILE_D}:fontcolor_expr=ffffff:
    fontsize=${FONTSIZE}:line_spacing=${LINESPACING}:box=0:x=(w-text_w)/2:y=80,
    format=yuv420p[v3];
    [0:v][5:v]overlay=shortest=1:x=(main_w-overlay_w)/2:y=(main_h-overlay_h)/2+80,
    drawtext=fontfile=${FONTFILE}:textfile=${EXPLFILE_E}:fontcolor_expr=ffffff:
    fontsize=${FONTSIZE}:line_spacing=${LINESPACING}:box=0:x=(w-text_w)/2:y=80,
    format=yuv420p[v4];
    [0:v][6:v]overlay=shortest=1:x=main_w-overlay_w-60:y=60,
    drawtext=fontfile=${FONTFILE}:textfile=${EXPLFILE_F}:fontcolor_expr=ffffff:
    fontsize=${FONTSIZE}:line_spacing=${LINESPACING}:box=0:x=60:y=80,
    format=yuv420p[v5];
    [0:v][7:v]overlay=shortest=1:x=(main_w-overlay_w)-80:y=(main_h-overlay_h)/2,"$FFLINES"format=yuv420p[v6];
    [0:v][8:v]overlay=shortest=1,
    drawtext=fontfile=${FONTFILE}:textfile=${CREDITS}:fontcolor_expr=ffffff:
    fontsize=${FONTSIZE_CREDITS}:line_spacing=${LINESPACING_CREDITS}:box=0:x=120:y=80,
    format=yuv420p[v7];
    [v0][v1][v2][v3][v4][v5][v6][v7]concat=n=8" \
    -pix_fmt yuv420p -vcodec libx264 -s $RESOLUTION video/milkyway-rotation.mp4
