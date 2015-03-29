# simple script for creating a "cinema redux"-like montage
# author: lennart hannink (lennart@hannink.de)
# dependencies: avconv, imagemagick

#! /bin/bash -

printf "\n-----------------\n   cinemontage   \n-----------------\n"

# set initial values
TINY_FLAG=0
KEEP_FLAG=0
PICS_PER_ROW=60

# read the options
ARGS=`getopt -o kt --long keep,tiny -n 'cinemontage.sh' -- "$@"`
eval set -- "$ARGS"

# extract options set flags
while true ; do
    case "$1" in
        -k|--k) KEEP_FLAG=1 ; shift ;;
        -t|--tiny) TINY_FLAG=1 ; shift ;;
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

printf "Creating thumbnails...\n"
# take one image every second and resize to 160x90 px
avconv -v quiet -i $INPUTFILE -s 160x90 -vsync 1 -r 1 -an -y $TMPDIR/'%04d.jpg'

printf "Stitching montage, %s images per row...\n" $PICS_PER_ROW
# create the montage
montage -background black "$TMPDIR"/*.jpg -tile "$PICS_PER_ROW"x -geometry "$H_SIZE"x"$V_SIZE"\>+"$H_SPACE"+"$V_SPACE" "$FILENAME"

if [[ $KEEP_FLAG == 0 ]]; then
	printf "Cleaning up...\n"
	rm -r $TMPDIR
fi


printf "Done.\n"