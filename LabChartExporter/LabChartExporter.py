#!/usr/bin/env python

import sys
import json


def parseFile(file, configuration):
    '''Parse the file'''

    nextTime = 0
    values = {} 

    # parse each line
    for line in source:

        # get dictionary from line
        dict_line = parseLine(line)

        # we only want timestamped lines
        if 'time' in dict_line:

            # update our values we will average when reaching an export time
            for key in dict_line:
                if key[0] == 'audience':
                    if key not in values:
                        values[key] = [dict_line[key]]
                    else:
                        values[key].append(dict_line[key])

            # have we reached an export time? (beware, float comparison)
            if dict_line['time'] >= nextTime - 0.0001:
                
                # average our values and write back into this dict_line
                for key in values:
                    dict_line[key] = sum(values[key]) / float(len(values[key]))

                # export the line based on the configuration
                export(dict_line, line, configuration)

                # monitor progress
                print dict_line['time'], nextTime, map(len, values.values())

                # reset and prepare for next export time
                nextTime = dict_line['time'] + configuration['granularity']
                values = {}    
                

def parseLine(line):
    '''Parse the line and return in dictionary'''

    # empty dict
    dictionary = {}

    # iterate through items
    for index, value in enumerate(line.split()):

        try:
            # parse column 0 as time, columns 1+ as value
            if index == 0:
                key = "time"
            else:
                key = "audience", configuration[ 'audienceIDForColumn', index ]

            # all values are floats so cast
            value = float(value)

            # add to the dictionary
            dictionary[key] = value

        except ValueError:
            # value wasn't a number, ie heading text
            print "Skipping line: " + line
            break

        except KeyError:
            # there is no audienceID for this column
            pass

    return dictionary


def openFilesInConfiguration(configuration):
    '''Open files in configuration'''

    # create list of audience IDs
    configuration['audienceIDs'] = range(configuration['audienceIDMin'], configuration['audienceIDMax'] + 1)

    # create mapping of audience ID to column index
    for item in configuration['mapping']:
        configuration[ 'audienceIDForColumn', item['column index'] ] = item['audience']

    # open file for writing (it's just the one for this export)
    output = open(configuration['filename'], 'w')

    # add output file object into the dictionary
    configuration['output'] = output

    # write headers into output
    headers = 'Time, {} \n'.format(", ".join("Audience{:02}".format(k) for k in configuration['audienceIDs']))
    configuration['output'].write(headers)


def closeFilesInConfiguration(configuration):
    '''Close files in configuration'''

    # close the output object
    configuration['output'].close()


def export(dict_line, line, configuration):
    '''export the line based on the given configuration'''

    # construct line from dictionary

    audienceOrderLine = str(dict_line['time'])

    for audienceID in configuration['audienceIDs']:
        audienceOrderLine += ", "
        if ('audience', audienceID) in dict_line:
            audienceOrderLine += str(dict_line[ 'audience', audienceID ])
        else:
            audienceOrderLine += "0"

    audienceOrderLine += "\n"

    # write line to output
    configuration['output'].write(audienceOrderLine)


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
