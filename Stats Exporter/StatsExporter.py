#!/usr/bin/env python

import sys
import json
import numpy as np


def parseFile(configuration):
    '''Parse the file'''

    elanConfig = configuration['source']['elan']
    bbConfig = configuration['source']['bb']

    for subject in configuration['subjects']:

        # for each subject, start at beginning of bb file
        bbConfig['file'].seek(0)

        for time in np.arange(configuration['timeStart'], configuration['timeEnd'], configuration['timeStep']):

            time = round(time, 1)

            infoDict = {}

            # elan -------
            
            subjectIdx = 1 # TODO: config
            timeStartIdx = 2
            timeEndIdx = 4
            annotationIdx = 8
            lightStateSet = set(['Lit', 'Unlit'])
            laughStateSet = set(['Not Laughing', 'Smiling', 'Laughing'])

            # scan the complete elan file line by line, as tiers are listed sequentially, so the same time has multiple occurences in the file
            
            elanConfig['file'].seek(0)
            for line in elanConfig['file']:

                # get data from line by stripping new line character from end and then splitting by tabs
                lineSplit = line.rstrip().split('\t')

                # is this line's data for the current subject?
                if lineSplit[subjectIdx] == subject:
                    
                    # and if so, is the current time within the time range for this annotation?
                    timeStart = float(lineSplit[timeStartIdx])
                    timeEnd = float(lineSplit[timeEndIdx])
                    if timeStart <= time < timeEnd:
                        
                        # classify annotation and add to current infoDict
                        annotation = lineSplit[annotationIdx]
                        if annotation in lightStateSet:
                            infoDict['lightState'] = annotation
                        elif annotation in laughStateSet:
                            infoDict['laughState'] = annotation
                        else:
                            print 'Unclassified elan annotation: {} at time: {}'.format(annotation, time)


            # breathing belts -----------

            # scan the bb file line by line starting where we last finished
            
            for line in bbConfig['file']:

                # get data from line by stripping new line character from end and then splitting by comma
                lineSplit = line.rstrip().split(', ')

                try:
                    lineTime = float(lineSplit[0])
                except ValueError:
                    # value wasn't a number, ie heading text
                    print "Skipping line: " + line
                    continue

                if lineTime == time: # beware, float compare. have verified works for our data/purposes here.
                    subjectIdx = bbConfig['columns'].index(subject)
                    infoDict['bb'] = lineSplit[subjectIdx]

                    #break here so file position doesn't run through to end
                    break
            
            # shore -----------

            # TODO

            # handle parsed data for this subject and time --------

            if len(infoDict):
                infoDict['subject'] = subject
                infoDict['time'] = time
                
                #TODO: config
                for field in ['lightState', 'laughState', 'bb']:
                    if field not in infoDict: infoDict[field] = 'n/a'

                exportLine = '{}, {}, {}, {}, {}'.format(infoDict['subject'], infoDict['time'], infoDict['lightState'], infoDict['laughState'], infoDict['bb'])
                print exportLine
                # write line to output
                configuration['output'].write(exportLine + '\n')



def openFilesInConfiguration(configuration):
    '''Open files in configuration and write the header'''

    # open file for writing
    filename = configuration['filename']
    output = open(filename, 'w')

    # add output to the dictionary
    configuration['output'] = output

    # open source files for reading and add to the dictionary
    source = configuration['source']
    for key, value in source.items():
        filename = value['filename']
        source[key]['file'] = open(filename, 'r')

    # write the header row
    header = 'AudienceID, TimeStamp, Light State, Laugh State, Breathing Belt' # TODO: config

    # new line and write the header
    header += "\n"
    output.write(header)


def closeFilesInConfiguration(configuration):
    '''Close files in configuration'''

    # read the output from the dictionary
    output = configuration['output']

    # close the output object
    output.close()

    # close the source objects
    source = configuration['source']
    for key in source:
        source[key]['file'].close()


''' main '''
if __name__ == '__main__':

    # check if the the input filename exists as a parameter
    if (len(sys.argv) < 2):
        sys.exit('Missing configuration file')


    # read files from arguments
    confFile = sys.argv[1]

    # open files
    confSource = open(confFile, 'r')

    # convert json file to python object
    configuration = json.loads(confSource.read())

    # open files in configuration
    openFilesInConfiguration(configuration)

    # parse the file with given configuration
    parseFile(configuration)

    # close files
    confSource.close()
    closeFilesInConfiguration(configuration)
