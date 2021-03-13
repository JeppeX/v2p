#!/bin/bash
FPS=$2

if [ -z "$1" ];then
	echo "v2p - Video to Pictures Converter"
	echo "Converts target video into pictures and saves them to current working directory."
	echo ""
	echo "usage: v2p [video] {fps} {test period}"
	echo ""
	echo "[video]: Path to the video that you want to make pictures out of."
	echo "{fps}: (optional) Amount of frames to be outputted per second in video. Defaults to 999. (all frames)"
	echo "{test period}: (optional) The length of video sample (in seconds) that is used to calculate iframe rate. Defaults to 30."
	exit
fi

if [ -z "$FPS" ];then FPS=999;fi

TEST=30

FRAMES=`ffprobe -loglevel error -select_streams v:0 -read_intervals %+$TEST -show_entries frame=pict_type -of csv=print_section=0 $1 | grep I | wc -l`
CLIPTIME=`ffprobe -i $1 -show_entries format=duration -v quiet -of csv="p=0"`

TIME=$TEST
if [ `echo "$CLIPTIME < $TEST" | bc -l` = "1" ];then
	TIME=$CLIPTIME
fi

echo $FRAMES iframes detected in $TIME seconds.
IFPS=`echo "$FRAMES / $TIME" | bc -l`
echo Iframes / sec: $IFPS
N=`echo "$IFPS / $FPS" | bc -l | cut -d . -f 1`
if [ -z $N ];then N=1;fi
TOTAL=`echo "$CLIPTIME * $IFPS / $N" | bc -l | cut -d . -f 1`
echo Rendering 1 out of $N frames, about $TOTAL frames total.
echo ""
echo "Are you sure? (Ctrl+C to cancel, enter to continue)"
read
ffmpeg -hide_banner -i $1 -vf "select=eq(pict_type\,I),select=not(mod(n\,$N))" -vsync vfr out%d.png
