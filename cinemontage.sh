# simple script for creating a "cinema redux"-like montage
# author: lennart hannink (lennart@hannink.de)
# dependencies: avconv, imagemagick

#! /bin/bash -

usage () {
	echo "Usage: CINEMONTAGE [options] infile"
	echo ""
	echo "OPTIONS:"
	echo "  -c columns       set number of images per row (default: 60)"
	echo "  -h help          display this help"
	echo "  -k keep          keep thumbnails"
	echo "  -m montage-only  use existing thumbnails"
	echo "  -s space         set space between rows (default: 44 px, 4 px in tiny mode)"
	echo "  -t tiny          create tiny 16x9 px thumbnails (default: 160x90 px)"
	echo ""
	echo "EXAMPLES:"
	echo "cinemontage -k video.mp4           creates a montage with 60 images per"
	echo "                                   row, each 160x90 px in size and keeps"
	echo "                                   them after finishing."
	echo ""
	echo "cinemontage -m -c 25 -t video.mp4  creates a montage with 25 images per"
	echo "                                   row, each 16x9 px in size and deletes" 
	echo "                                   the thumbnail folder after finishing."
	echo "                                   only works if the thumbnail folder exists,"
	echo "                                   i.e. if you have used the »keep« option"
	echo "                                   previously."
	echo ""
}

# set initial values
COLUMNS=60
KEEP_FLAG=0
MONTAGE_ONLY_FLAG=0
TINY_FLAG=0

if [[ $@ == "" ]]; then
	printf "You have to specify an input file.\n"
	usage && exit 1
fi

# read the options
ARGS=`getopt -o c:hkms:t --long columns:,help,keep,montage-only,space:,tiny -n 'cinemontage.sh' -- "$@"`
eval set -- "$ARGS"


# extract options set flags
while true ; do
    case "$1" in
		-c|--columns)
            case "$2" in
                "") shift 2 ;;
                *) COLUMNS=$2 ; shift 2 ;;
            esac ;;
        -h|--help) usage && exit 1 ; shift ;;
        -k|--keep) KEEP_FLAG=1 ; shift ;;
        -m|--montage-only) MONTAGE_ONLY_FLAG=1 ; shift ;;
		-s|--space)
            case "$2" in
                "") shift 2 ;;
                *) SPACE=$2 ; shift 2 ;;
            esac ;;
        -t|--tiny) TINY_FLAG=1 ; shift ;;
		--) shift ; break ;;
        *) echo "Internal error!" ; exit 1 ;;
    esac
done


printf "~~~~~~~~~~~~~~~~\n  cinemontage   \n~~~~~~~~~~~~~~~~\n"
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
	if [[ $SPACE ]]; then
		let "V_SPACE=$SPACE/2"
	else
		V_SPACE=2
	fi
	FILENAME="$BASENAME"_tiny.jpg
else
	H_SIZE=160
	V_SIZE=90
	H_SPACE=0
	if [[ $SPACE ]]; then
		let "V_SPACE=$SPACE/2"
	else
		V_SPACE=22
	fi
	FILENAME=$BASENAME.jpg
fi

# only take images from video, if MONTAGE_ONLY_FLAG is not set
if [[ $MONTAGE_ONLY_FLAG == 0 ]]; then
	printf "Creating thumbnails...\n"
	# take one image every second and resize to 160x90 px
	avconv -v quiet -i $INPUTFILE -s 160x90 -vsync 1 -r 1 -an -y $TMPDIR/'%04d.jpg'
else
	printf "Using previously created thumbnails.\n"
fi


if [[ $SPACE ]]; then
	printf "Stitching montage, %s images/row, %s px space between rows...\n" $COLUMNS $SPACE
else
	printf "Stitching montage, %s images/row...\n" $COLUMNS
fi


# create the montage
montage -background black "$TMPDIR"/*.jpg -tile "$COLUMNS"x -geometry "$H_SIZE"x"$V_SIZE"\>+"$H_SPACE"+"$V_SPACE" "$FILENAME"


# clean up
if [[ $KEEP_FLAG == 0 ]]; then
	printf "Cleaning up...\n"
	rm -r $TMPDIR
else
	printf "Keeping thumbnails.\n"
fi

printf "Done.\n"