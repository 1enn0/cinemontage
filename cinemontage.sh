# simple script for creating a "cinema redux"-like montage
# author: lennart hannink (lennart@hannink.de)
# dependencies: avconv, imagemagick

#! /bin/bash -

printf "\n-----------------\n   cinemontage   \n-----------------\n"

# set initial values
COLUMNS=60
KEEP_FLAG=0
MONTAGE_ONLY_FLAG=0
TINY_FLAG=0

# read the options
ARGS=`getopt -o c:kmt --long columns:,keep,montage-only,tiny -n 'cinemontage.sh' -- "$@"`
eval set -- "$ARGS"

# extract options set flags
while true ; do
    case "$1" in
		-c|--columns)
            case "$2" in
                "") shift 2 ;;
                *) COLUMNS=$2 ; shift 2 ;;
            esac ;;
        -k|--keep) KEEP_FLAG=1 ; shift ;;
        -m|--montage-only) MONTAGE_ONLY_FLAG=1 ; shift ;;
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
	FILENAME="$BASENAME"_tiny.jpg
else
	H_SIZE=160
	V_SIZE=90
	H_SPACE=0
	V_SPACE=22
	FILENAME=$BASENAME.jpg
fi

# only take images from video, if MONTAGE_ONLY_FLAG is not set
if [[ $MONTAGE_ONLY_FLAG == 0 ]]; then
	printf "Creating thumbnails...\n"
	# take one image every second and resize to 160x90 px
	avconv -v quiet -i $INPUTFILE -s 160x90 -vsync 1 -r 1 -an -y $TMPDIR/'%04d.jpg'
else
	printf "Using previously created thumnails..."
fi


printf "Stitching montage, %s images per row...\n" $COLUMNS
# create the montage
montage -background black "$TMPDIR"/*.jpg -tile "$COLUMNS"x -geometry "$H_SIZE"x"$V_SIZE"\>+"$H_SPACE"+"$V_SPACE" "$FILENAME"


# clean up
if [[ $KEEP_FLAG == 0 ]]; then
	printf "Cleaning up...\n"
	rm -r $TMPDIR
fi

printf "Done.\n"