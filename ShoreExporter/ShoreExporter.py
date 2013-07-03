#!/usr/bin/env python

import sys
import json


def parseFile(file, configuration):
    '''Parse the file'''

    # parse each line
    for line in source:

        # get dictionary from line
        dict_line = parseLine(line)

        # export the line based on the configuration
        export(dict_line, line, configuration)


def parseLine(line):
    '''Parse the line and return in dictionary'''

    # empty dict
    dictionary = {}

    # iterate through items
    for item in line.split(' '):

        # get the key and value from the item
        key, value = parseItem(item)

        # add to the dictionary
        dictionary[key] = value

    return dictionary


def parseItem(item):
    '''Parse the item and return key, value'''

    itemList = item.split('=')

    # normal case (key=value)
    if len(itemList) == 2:
        return itemList[0], itemList[1]

    # handle the case where value is missing (e.g. 'Gender=')
    elif len(itemList) == 1:
        return itemList[0], None

    else:
        sys.exit('Error: structure of input file is invalid. Item: ' + item)


def openFilesInConfiguration(configuration):
    '''Open files in configuration'''

    # iterate items
    for item in configuration:

        # open file for writing
        output = open(item['filename'], 'w')

        # add output file object into the dictionary
        item['output'] = output


def closeFilesInConfiguration(configuration):
    '''Close files in configuration'''

    # iterate items
    for item in configuration:

        # close the output object
        item['output'].close()


def export(dict_line, line, configuration):
    '''export the line based on the given configuration'''

    pass


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

    # open files in configuration
    openFilesInConfiguration(configuration)

    # parse the file with given configuration
    parseFile(source, configuration)

    # close files
    source.close()
    conf_source.close()
    closeFilesInConfiguration(configuration)
