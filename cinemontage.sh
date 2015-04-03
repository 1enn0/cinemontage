# simple script for creating a "cinema redux"-like montage
# author: lennart hannink (lennart@hannink.de)
# dependencies: avconv, imagemagick

#! /bin/bash -

usage () {
	echo ""
	echo "cinemontage - look at an entire movie in a single image"
	echo ""
	echo "Usage: CINEMONTAGE [options] infile"
	echo ""
	echo "OPTIONS:"
	echo "  -c columns       set number of images per row (default: 60)"
	echo "  -h help          display this help"
	echo "  -r remove        remove thumbnails after finishing"
	echo "  -s space         set space between rows (default: 44 px; 4 px in tiny mode)"
	echo "  -t tiny          create tiny 16x9 px thumbnails (default: 160x90 px)"
	echo ""
	echo "EXAMPLES:"
	echo "cinemontage video.mp4              creates a montage with 60 images per"
	echo "                                   row, each 160x90 px in size and keeps"
	echo "                                   thumbnails after finishing."
	echo ""
	echo "cinemontage -c 25 -t -r video.mp4  creates a montage with 25 images per"
	echo "                                   row, each 16x9 px in size and deletes" 
	echo "                                   thumbnails after finishing."
	echo ""
}

# set initial values
COLUMNS=60
REMOVE_FLAG=0
TINY_FLAG=0

if [[ $@ == "" ]]; then
	printf "You have to specify an input file.\n"
	usage && exit 1
fi

# read the options
ARGS=`getopt -o c:hrs:t --long columns:,help,remove,space:,tiny -n 'cinemontage.sh' -- "$@"`
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
        -r|--remove) REMOVE_FLAG=1 ; shift ;;
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

TMPDIR=./"$BASENAME"_thumbnails
if [ ! -d $TMPDIR ]; then
	# thumbnail are not available
	mkdir $TMPDIR

	printf "Creating thumbnails...\n"
	# take one image every second and resize to 160x90 px
	avconv -v quiet -i $INPUTFILE -s 160x90 -vsync 1 -r 1 -an -y $TMPDIR/'%04d.jpg'
else
	#thumbnails are available, i.e. NO avconv
	printf "Found previously created thumbnails :)\n"
fi

if [[ $SPACE ]]; then
	printf "Stitching montage, %s images/row, %s px space between rows...\n" $COLUMNS $SPACE
else
	printf "Stitching montage, %s images/row...\n" $COLUMNS
fi

# create the montage
montage -background black "$TMPDIR"/*.jpg -tile "$COLUMNS"x -geometry "$H_SIZE"x"$V_SIZE"\>+"$H_SPACE"+"$V_SPACE" "$FILENAME"

# clean up
if [[ $REMOVE_FLAG == 1 ]]; then
	printf "Cleaning up...\n"
	rm -r $TMPDIR
else
	printf "Keeping thumbnails for further use.\n"
fi

printf "\nDone.\n"