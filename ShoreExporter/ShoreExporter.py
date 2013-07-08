#!/usr/bin/env python

import sys
import json
import re


def transformLine(line):
    '''Replace space separators with ";"
       and only use space in the TimeStamp'''

    return re.sub(r'[ ]([a-zA-Z])', r', \1', line)


def parseFile(file, configuration):
    '''Parse the file'''

    # parse each line
    for line in source:

        # use ';' as a separator
        line = transformLine(line)

        # get dictionary from line
        dict_line = parseLine(line)

        # export the line based on the configuration
        export(dict_line, line, configuration)


def parseLine(line):
    '''Parse the line and return in dictionary'''

    # empty dict
    dictionary = {}

    # iterate through items
    for item in line.split(', '):

        # get the key and value from the item
        key, value = parseItem(item)

        # cast value based on the key
        # TODO: Add more keys here if you need them (e.g. Uptime, Score etc)
        if (key in ['Left', 'Top', 'Right', 'Bottom']):
            value = float(value)

        # add to the dictionary
        dictionary[key] = value

    return dictionary


def parseItem(item):
    '''Parse the item and return key, value (in string)'''

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

    # iterate through items in configuration
    for item in configuration:

        # open file for writing
        filename = item['filename'].split('.')
        filename[0] += '-' + "-".join("{}".format(field) for field in exportFields)
        output = open(filename[0]+"."+filename[1], 'w')

        # add output file object into the dictionary
        item['output'] = output

        # write headers to output
        lineFromDict = ', '.join('{}'.format(field) for field in exportFields)
        lineFromDict += "\n"
        item['output'].write(lineFromDict)


def closeFilesInConfiguration(configuration):
    '''Close files in configuration'''

    # iterate through items in configuration
    for item in configuration:

        # close the output object
        item['output'].close()


def export(dict_line, line, configuration):
    '''export the line based on the given configuration'''

    # iterate through items in configuration
    for item in configuration:

        # get frame item from configuration
        frame = item['frame']

        # get left, top, right, bottom from frame(configuration)
        conf_left = frame['left']
        conf_top = frame['top']
        conf_right = frame['right']
        conf_bottom = frame['bottom']

        # get left, top, right, bottom from the line(input file)
        line_left = dict_line['Left']
        line_top = dict_line['Top']
        line_right = dict_line['Right']
        line_bottom = dict_line['Bottom']

        # debug
        # print '---'
        # print('conf - l: %f t:%f r:%f b:%f' % (conf_left, conf_top, conf_right, conf_bottom))
        # print('line - l: %f t:%f r:%f b:%f' % (line_left, line_top, line_right, line_bottom))

        # check if the line fits the configuration item requirements
        # 0,0 point is Top-Left
        if (line_left >= conf_left and
                line_top >= conf_top and
                line_right <= conf_right and
                line_bottom <= conf_bottom):

            # line fits the requirements of the configuration item
            # write it on the output and break.

            if dict_line['Happy'] == 'nil':
                break

            lineFromDict = ', '.join('{}'.format(dict_line[field]) for field in exportFields)
            lineFromDict += "\n"
            item['output'].write(lineFromDict)

            # by removing break, the script will export the line into
            # multiple output files when the line fits requirements.

            break


''' main '''
if __name__ == '__main__':

    # TODO: Put in configuration.
    # Only have one data series for valid TimeStamp=Value pairs.
    exportFields = ['TimeStamp', 'Happy']

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
