#!/bin/bash

FILES=./*
FILESIZE=1GB
FILETARGET=./*
OUTPUT=./
PATHF=./
PREFIX=default
PREFIXLIST=prefixlist.txt
HELP=false
FAILED=0

# TODO check for valid file extension
# TODO output md5sum result to function to return at the end


##############################################################################
# Help                                                                       #
##############################################################################

function help() {
    cat <<EOF
    This script is used to split .tar files into smaller parts to bypass upload file size limits.
    It can also be used to rejoin split files back to original state.
    You are required to specify the method for split/join.

    Usage: $0 [options] [method]
    Example split: $0 -f 5GB -o myfiles/ -s
    Example join: $0 -o myfiles/ -j

    Options:
    -h | --help       Display help text
    -f | --filesize   Size to split file by (default 1GB) [Split only]
    -o | --output     Directory to use of create for output of split. (default ./) [Split only]
    -t | --target     Optional file to target (default targets all ./*.tar) [Split only]
    -p | --path       Path to split files that need joining. [Join only]

    Methods:
    -s | --split      Split files into smaller parts
    -j | --join       Join already split files back into single tar

EOF
HELP=true
}

##############################################################################

function splitfiles() {
    
    if [ "$OUTPUT" != "./" ]; then
        if [ ! -d "$OUTPUT" ]; then
            mkdir $OUTPUT
        fi
    fi
    
    touch $PREFIXLIST
    for file in *.tar*; do
        # TODO Calculate the number of split files to be produced based off filesize and passed split size and echo number of expected files to be produced
        PREFIX=$(echo $file | sed 's/tar//' | sed 's/.gz//')

        echo "[.] Creating md5sum hash for $file"
        md5sum $file > $file-md5sum
        echo ""

        echo "[.] Splitting file $file with file size $FILESIZE..."
        split -b $FILESIZE --verbose $file $PREFIX
        echo ""
        
        echo "[.] Creating prefix list..."
        echo $PREFIX >> $PREFIXLIST
        echo ""

        echo "[.] Moving files"
        mv $PREFIX* $OUTPUT
        mv $OUTPUT$file ./
        
        echo "[.] File split complete"
        echo ""
    done
    echo "[.] Finished files:"
    ls $OUTPUT
    echo ""
    
    mv $PREFIXLIST $OUTPUT
    echo "[.] Prefix List:"
    cat $OUTPUT$PREFIXLIST
    echo ""
}

function joinfiles() {
    pwd=$(pwd)
    cd $PATHF
    if [ ! -d "archive" ]; then
        mkdir archive
        echo "[.] Archive directory created"
    fi
    
    lines=$(cat $PREFIXLIST)
    for line in $lines; do
        line=${line%?}
        echo "[.] Joining file '$line'"

        # TODO Ensure works with tar and tar.gz
        mv $line.tar-md5sum archive/
        cat $line* > $OUTPUT$line.tar
        mv `ls -1 $line* | grep -v $line.tar` archive/
        echo ""
        
        echo "[.] Verifying md5sums..."
        verified=$(md5sum -c --status archive/$line.tar-md5sum)
        if [ $verified != 0 ] ; then
            echo "*** CHECKSUM FAILED: $line ***"
            FAILED=$((FAILED + 1))
        fi
        echo ""
    done
    mv $PREFIXLIST archive/
    
    echo "[.] Files successfully joined"
    echo ""

    if [ $FAILED > 0 ] ; then
        echo "[.] *** $FAILED Files failed to join *** "
        echo ""
    fi
    
    echo "[.] Finished files:"
    ls -1
    echo ""
    cd $pwd
}

function setfilesize() {
    if [ -z $1 ]; then
        echo "[.] No file size specified, default to split by 1GB"
        FILESIZE=$FILESIZE
    else
        FILESIZE=$1
        # Ensure the string is uppercase to allow parsing
        FILESIZE=${FILESIZE^^}
        echo "[.] Set filesize to split by $FILESIZE"
    fi
}

function setfiletarget() {
    echo "[.] Targeting correct files..."
    if [ -z $1 ]; then
        echo "No files specified, targeting all files"
        FILETARGET=$FILETARGET
    else 
        echo "Targeting files '$1'"
        FILETARGET=$1
        
    fi
}

function setoutput() {
    if [ -z $1 ]; then
        echo "No output directory given, using default"
    else 
        echo "[.] Setting output directory to '$1'"
        OUTPUT=$1
    fi
}

function setpath() {
    echo "[.] Setting path to files..."
    if [ -z $1 ]; then
        echo "No file path given, using curent directory"
    else 
        echo "[.] Setting path to files as '$1'"
       PATHF=$1
    fi
}

#########################################

echo ""
echo "[.] Initiating..."
echo ""

while [[ $# -gt 0 ]]; do
    key="$1"
    case $key in

        --split | -s)
            splitfiles
            ;;
        
        --join | -j)
            joinfiles
            ;;

        --filesize | -f)
            setfilesize $2
            shift
            ;;
        
        --target | -t)
            setfiletarget $2
            shift
            ;;
        
        --output | -o)
            setoutput $2
            shift
            ;;
        
        --pathtofiles | -p)
            setpath $2
            shift
            ;;
        
        --help | -h)
            help
            exit
            ;;

        *)
            echo "Unable to parse $key"
        ;;

    esac
    shift
done

if [ "$HELP" != "true" ]; then
    
    echo "[.] Script finished"
fi