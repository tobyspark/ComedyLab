#!/usr/bin/env python

# For every subject, list the state at every timestep between start and end
# We're going for something that looks like...
# 
# AudienceID, TimeStamp, Light State, Laugh State, Breathing Belt, Happiness
# Audience 02, 472.0, Unlit, n/a, -0.00885, n/a
# Audience 02, 472.1, Unlit, n/a, -0.00818, n/a
# Audience 02, 472.2, Unlit, Not Laughing, -0.00781, n/a
# Audience 02, 472.3, Unlit, Not Laughing, -0.00735, 71.111
# Audience 03, 472.0, Unlit, Not Laughing, 0.0016, 84.667
# Audience 03, 472.1, Unlit, Not Laughing, -7e-05, 80.222
# Audience 03, 472.2, Unlit, Not Laughing, -0.00165, 92.444
# Audience 03, 472.3, Unlit, Not Laughing, -0.00303, 92.444


import sys
import json
import numpy as np


def parseFile(configuration):
    '''Parse the file'''

    exportConfig = configuration['export']
    elanConfig = configuration['source']['elan']
    bbConfig = configuration['source']['bb']
    shoreConfig = configuration['source']['shore']

    timeStepSearch = float(exportConfig['timeStep']) / 2

    # parse for each subject
    for subject in configuration['subjects']:

        # for each subject, start at beginning of time linear files
        bbConfig['file'].seek(0)
        currentBBTime = exportConfig['timeStart'] - exportConfig['timeStep']
        shoreConfig['file'].seek(0)
        currentShoreTime = exportConfig['timeStart'] - exportConfig['timeStep']

        # within each subject, parse for time
        for time in np.arange(exportConfig['timeStart'], exportConfig['timeEnd'], exportConfig['timeStep']):

            # convert to float and ensure value is precisely x.xx and not x.xx000000000xyz
            # could replace np.arange and this round line if hardcoding step to 0.1 like so [round(x / 10.0, 1) for x in range(configuration['timeStart']*10, configuration['timeEnd']*10)]
            time = round(time, 1)

            infoDict = {}

            # elan -------
            
            # scan the complete elan file for each timestep pass. 
            # as tiers are listed sequentially, the same time has multiple occurences in the file
            
            elanConfig['file'].seek(0)
            for line in elanConfig['file']:

                # get data from line by stripping new line character from end and then splitting by tabs
                lineSplit = line.rstrip().split('\t')

                # is this line's data for the current subject?
                subjectIdx = elanConfig['columns'].index('subject')
                if lineSplit[subjectIdx] == subject:
                    
                    # and if so, is the current time within the time range for this annotation?
                    timeStart = float(lineSplit[elanConfig['columns'].index('timeStart')])
                    timeEnd = float(lineSplit[elanConfig['columns'].index('timeEnd')])
                    if timeStart <= time < timeEnd:
                        
                        # classify annotation and add to current infoDict
                        annotation = lineSplit[elanConfig['columns'].index('annotation')]
                        matched = False
                        for key, value in elanConfig['annotationSets'].items():
                            if (annotation in value):
                                infoDict[key] = annotation
                                matched = True

                        if not matched:
                            print 'Unclassified elan annotation: {} at time: {}'.format(annotation, time)


            # breathing belts -----------

            # partial scan the bb file, starting where last timestep left off and advancing to the next line only if timestep has caught up to last read line
            
            while currentBBTime < time - timeStepSearch:

                line = bbConfig['file'].readline()

                # get data from line by stripping new line character from end and then splitting by comma
                lineSplit = line.rstrip().split(', ')

                # get time from line data
                try:
                    currentBBTime = float(lineSplit[0])
                except ValueError:
                    # value wasn't a number, ie heading text
                    print "Skipping line: " + line
                    continue

                # extract field if correct time and add to infodict
                if abs(currentBBTime - time) < timeStepSearch:
                    subjectIdx = bbConfig['columns'].index(subject)
                    infoDict['Breathing Belt'] = lineSplit[subjectIdx]

            
            # shore -----------

            # partial scan the shore file, starting where last timestep left off and advancing to the next line only if timestep has caught up to last read line

            while currentShoreTime < time - timeStepSearch:

                line = shoreConfig['file'].readline()

                # get data from line by stripping new line character from end and then splitting by comma
                lineSplit = line.rstrip().split(', ')

                # get time from line data
                try:
                    currentShoreTime = float(lineSplit[0])
                except ValueError:
                    # value wasn't a number, ie heading text
                    print "Skipping line: " + line
                    continue

                # extract field if correct time and add to infodict
                if abs(currentShoreTime - time) < timeStepSearch: 
                    for field in ['Happiness', 'MouthOpen']:

                        columnHeader = subject + " " + field
                        subjectIdx = shoreConfig['columns'].index(columnHeader)
                        value = lineSplit[subjectIdx]
                        
                        # shore data is processed to have 'none' or -10 for missing person and -5 for missing value, we should ignore these
                        if value not in ['None', '-10', '-5']:
                            infoDict[field] = value


            # handle parsed data for this subject and time --------

            if len(infoDict):
                infoDict['subject'] = subject
                infoDict['time'] = time
                
                # put in placeholder for missing values
                for field in configuration['export']['fields']:
                    if field not in infoDict: infoDict[field] = configuration['export']['missingValuePlaceholder']

                exportFields = ['subject', 'time'] + configuration['export']['fields']

                exportLine = ", ".join([str(infoDict[x]) for x in exportFields])

                print exportLine
                # write line to output
                configuration['output'].write(exportLine + '\n')



def openFilesInConfiguration(configuration):
    '''Open files in configuration and write the header'''

    # open file for writing
    filename = configuration['export']['filename']
    output = open(filename, 'w')

    # add output to the dictionary
    configuration['output'] = output

    # open source files for reading and add to the dictionary
    source = configuration['source']
    for key, value in source.items():
        filename = value['filename']
        source[key]['file'] = open(filename, 'r')

    # write the header row
    header = 'AudienceID, TimeStamp, ' + ', '.join(configuration['export']['fields'])

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
