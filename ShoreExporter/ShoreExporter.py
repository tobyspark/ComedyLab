#!/usr/bin/env python

import sys
import json
import re
from datetime import datetime


def transformLine(line):
    '''Replace space separators with ", "
       and only use space in the TimeStamp'''

    return re.sub(r'[ ]([a-zA-Z])', r', \1', line)


def parseFile(file, configuration):
    '''Parse the file'''

    # get people
    people = configuration['people']

    # get start date and frame for the timestamp
    start_date = parseDate(configuration['start_date'])

    # init current dict and frame
    current_dict = None
    current_frame = -1

    # parse each line
    for line in source:

        # use ', ' as a separator
        line = transformLine(line)

        # get dictionary from line
        dict_line = parseLine(line, start_date)

        # get timestamp and frame (global for all persons)
        timestamp = dict_line['TimeStamp']
        frame = dict_line['Frame']

        # based on the dict_line, get the person
        person = getPerson(dict_line, configuration)

        # if we have a new frame
        if frame > current_frame:

            # export the current_dict
            if (current_dict):
                export(current_dict, configuration)

            # init a new one
            current_dict = {}

            # set Frame and TimeStamp
            current_dict['TimeStamp'] = timestamp
            current_dict['Frame'] = frame

            # set this as the current one
            current_frame = frame

        # add person to the current_dict
        if person:
            current_dict[person] = dict_line


def getPerson(dict_line, configuration):
    '''Get the person, based on the dict_line'''

    # iterate through items in configuration
    for item in configuration['people']:

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

        # check if the line fits the configuration item requirements
        # 0,0 point is Top-Left
        if (line_left >= conf_left and
                line_top >= conf_top and
                line_right <= conf_right and
                line_bottom <= conf_bottom):

            # line fits the requirements of the configuration item
            # return the name
            return item['name']

    # Person was not found, just return None
    return None


def parseLine(line, start):
    '''Parse the line and return in dictionary'''

    # empty dict
    dictionary = {}

    # iterate through items
    for item in line.split(', '):

        # get the key and value from the item
        key, value = parseItem(item)

        # cast value based on the key
        if (key in ['Left', 'Top', 'Right', 'Bottom', "Uptime", "Score"]):

            # Might need these as well:
            #'Surprised', 'Sad', 'Happy', 'Angry',
            #'Age', 'MouthOpen',
            #'LeftEyeClosed', 'RightEyeClosed'

            # float value
            if value:
                value = float(value)

        elif (key in ['Id', 'Frame']):

            # int value
            if value:
                value = int(value)

        elif (key == 'TimeStamp'):

            # save it as a datetime object
            timestamp = parseDate(value)

            # find the deltatime
            deltatime = timestamp - start

            # string value in seconds
            value = str(deltatime.total_seconds())

        # add to the dictionary
        dictionary[key] = value

    # return
    return dictionary


def parseDate(date):
    '''Parse a date in string and return a datetime object'''

    if len(date) == 20:
        # Datetime format: '2013-Jul-02 16:32:46'
        value = datetime.strptime(date, '%Y-%b-%d %H:%M:%S')
    else:
        # Datetime format: '2013-Jul-02 16:32:46.396849'
        value = datetime.strptime(date, '%Y-%b-%d %H:%M:%S.%f')

    return value


def parseItem(item):
    '''Parse the item and return key, value (in string)'''

    # format should be key=value
    itemList = item.split('=')

    # normal case (key=value)
    if len(itemList) == 2:

        # set the key
        key = itemList[0]

        # set the value
        if itemList[1] == 'nil':
            value = None
        else:
            value = itemList[1]

    # handle the case where value is missing (e.g. 'Gender=')
    elif len(itemList) == 1:

        # set the key
        key = itemList[0]

        # set the value to None
        value = None

    else:
        sys.exit('Error: structure of input file is invalid. Item: ' + item)

    # return
    return key, value


def openFilesInConfiguration(configuration):
    '''Open files in configuration and write the header'''

    # get items that will be exported from log file
    exportFields = configuration['exportFields']

    # get people
    people = configuration['people']

    # open file for writing
    filename = configuration['filename']
    output = open(filename, 'w')

    # add output to the dictionary
    configuration['output'] = output

    # write the requiered TimeStamp and Frame as first items
    header = ('TimeStamp, Frame, ')

    # Add one field for each person
    header += ', '.join(
        (person['name'] + '_' + field)
        for person in people for field in exportFields)

    # new line and write the header
    header += "\n"
    output.write(header)


def closeFilesInConfiguration(configuration):
    '''Close files in configuration'''

    # read the output from the dictionary
    output = configuration['output']

    # close the output object
    output.close()


def export(current_dict, configuration):
    '''export the current_dict'''

    # get items that will be exported from log file
    exportFields = configuration['exportFields']

    # get people
    people = configuration['people']

    # get the output
    output = configuration['output']

    # write the requiered TimeStamp and Frame as first items
    line = str(current_dict['TimeStamp']) + ', '
    line += str(current_dict['Frame']) + ', '

    # Add one field for each person
    field_list = []

    # missing value
    missing_value = '-5'
    missing_people = '-10'

    # iterate through people and fields
    for person in people:
        for field in exportFields:

            # if the person exists
            if person['name'] in current_dict.keys():

                # if the field exists
                if field in current_dict[person['name']].keys():

                    # add the field value
                    field_list.append(str(current_dict[person['name']][field]))

                else:
                    field_list.append(missing_value)

            else:
                field_list.append(missing_people)

    # Add to the line the contents of the list separated by ', '
    line += ', '.join(field_list)

    # new line and write the line
    line += "\n"
    output.write(line)


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
