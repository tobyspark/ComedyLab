#!/usr/bin/env python

import sys
import json

def parseFile(file, configuration):
    '''Parse the file'''

    # parse each line
    for line in source:
        dict_line = parseLine(line)


def parseLine(line):
    '''Parse the line and return in dictionary'''

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
    '''Parse the item and return key, value'''

    itemList = item.split("=")

    # normal case (key=value)
    if len(itemList) == 2:
        return itemList[0], itemList[1]

    # handle the case where value is missing (e.g. 'Gender=')
    elif len(itemList) == 1:
        return itemList[0], None

    else:
        sys.exit('Error: structure of the input file is invalid. Item: ' + item)


''' main '''
if __name__ == '__main__':
    
    # check if the the input filename exists as a parameter
    if (len(sys.argv) < 2):
        sys.exit('Missing input file')

    # check if the the configuration filename exists as a parameter
    if (len(sys.argv) < 3):
        sys.exit('Missing configuration file')

    # read files from arguments
    inputFile = sys.argv[1]
    confFile = sys.argv[2]

    # open files
    source = open(inputFile, 'r')
    conf_source = open(confFile, 'r')

    # convert json file to python object
    configuration = json.loads(conf_source.read())

    # parse the file with given configuration
    parseFile(source, configuration)

    # close files
    source.close()
    conf_source.close()
