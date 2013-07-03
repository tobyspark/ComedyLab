#!/usr/bin/env python

import sys


def parseFile(file):
    '''Parse the file'''

    # parse each line
    for line in source:
        parseLine(line)


def parseLine(line):
    '''Parse the line and...'''

    # empty dict
    dictionary = {}

    # iterate through items
    for item in line.split(" "):

        # get the key and value from the item
        key, value = parseItem(item)

        # add to the dictionary
        dictionary[key] = value

    return dictionary


def parseItem(item):
    ''''''

    itemList = item.split("=")

    if len(itemList) == 3:
        return itemList[0], itemList[2]

    # handle the case where value is missing (e.g. 'Gender=')
    elif len(itemList) == 2:
        return itemList[0], None

    else:
        sys.exit('Error: structure of the input file is invalid. Item: ' + item)


''' main '''
if __name__ == '__main__':
    
    # check if the the filename exists as a parameter
    if (len(sys.argv) < 2):
        sys.exit('Missing input file')

    # read the filename from the 1st argument
    filename = sys.argv[1]

    # open the file
    source = open(filename, 'r')

    # parse the file
    parseFile(source)

    # close the file
    source.close()
