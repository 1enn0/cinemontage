# simple script for creating a "cinema redux"-like montage
# author: lennart hannink (lennart@hannink.de)
# dependencies: avconv, imagemagick

#! /bin/bash -

# set initial values for flags
TINY_FLAG=0
KEEP_FLAG=0

# read the options
ARGS=`getopt -o kt --long keep,tiny -n 'cinemontage.sh' -- "$@"`
eval set -- "$ARGS"

# extract options set flags
while true ; do
    case "$1" in
        -k|--k) KEEP_FLAG=1 && echo "KEEP_FLAG set" ; shift ;;
        -t|--tiny) TINY_FLAG=1 && echo "TINY_FLAG set" ; shift ;;
        --) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done

INPUTFILE=$1
BASENAME=${INPUTFILE%.*}

TMPDIR=./thumbnails
if [ ! -d $TMPDIR ]; then
mkdir $TMPDIR
fi

# Find framerate of the video
# framerates can be one of the following: 23.97, 24, 25, 29.97, 30, 48, 50, 60
FPS_TXT=`avconv -i $INPUTFILE 2>&1 | grep fps | cut -f5 -d ',' | cut -f2 -d ' '`

if [[ "24 25 30 48 50 60" =~ $FPS_TXT ]]; then
	let "FPS=$FPS_TXT"
	echo "Framerate: $FPS fps"
elif [[ "23.976 23.97 23.98" =~ $FPS_TXT ]]; then
	FPS=24
 	echo "Approximate framerate: $FPS fps"
elif [[ "29.976 29.97 29.98" =~ $FPS_TXT ]]; then
	FPS=30
 	echo "Approximate framerate: $FPS fps"
else
	echo "Oops. Framerate not recognized."
	exit 1
fi


if [[ $TINY_FLAG == 1 ]]; then
	H_SIZE=16
	V_SIZE=9
	H_SPACE=0
	V_SPACE=2
	FILENAME=`printf "%s_tiny.jpg" $BASENAME`
else
	H_SIZE=160
	V_SIZE=90
	H_SPACE=0
	V_SPACE=22
	FILENAME=$BASENAME.jpg
fi

printf "\nCreating thumbnails...\n"
# take one image every second and resize to 160x90 px
avconv -i $INPUTFILE -s 160x90 -vsync 1 -r 1 -an -y $TMPDIR/'%04d.jpg'

printf "Stitching montage [%s images per row]...\n" $FPS
# create the montage
montage -background black $TMPDIR/*.jpg -tile `echo $FPS`x -geometry `echo $H_SIZE`x`echo $V_SIZE`\>+`echo $H_SPACE`+`echo $V_SPACE` $FILENAME

if [[ $KEEP_FLAG == 0 ]]; then
	printf "Cleaning up...\n"
	rm -r $TMPDIR
fi


printf "All done.\n"