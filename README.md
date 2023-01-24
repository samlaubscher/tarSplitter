# tarSplitter

    This script is used to split .tar files into smaller parts to bypass upload file size limits.
    It can also be used to rejoin split files back to original state.
    You are required to specify the method for split/join.
    MD5Sum hash comparison verifies file integrity.

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
