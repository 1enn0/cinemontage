# simple script for creating a "cinema redux"-like montage
# author: lennart hannink (lennart@hannink.de)
# dependencies: avconv, imagemagick

#! /bin/bash -

INPUTFILE=$1
BASENAME=${INPUTFILE%.*}
FILENAME=$BASENAME.jpg

TMPDIR=./tmp
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

printf "\nCreating thumbnails...\n"
# take one image every second and resize to 160x90 px
avconv -i $INPUTFILE -s 160x90 -vsync 1 -r 1 -an -y $TMPDIR/'%04d.jpg'

printf "\nStitching montage [%s images per row]...\n" $FPS
# create the montage with 25px vertical spacing, tiling $FPS pics horizontally
montage -background black -fill white $TMPDIR/*.jpg -tile `echo $FPS`x -geometry 160x90\>+0+25 -title $BASENAME $FILENAME



if [[ $2 == "clean" ]]; then
	rm -r $TMPDIR
fi

printf "\nAll done.\n"