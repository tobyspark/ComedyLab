#!/usr/bin/env python

import sys


''' main '''
if __name__ == '__main__':
    
    # check if the the filename exists as a parameter
    if (len(sys.argv) < 2):
        sys.exit('Missing input file')

    # read the filename from the 1st argument
    filename = sys.argv[1]

    # open the file
    source = open(filename, 'r')