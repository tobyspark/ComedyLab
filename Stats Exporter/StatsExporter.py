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
import math
import numpy as np


class SeatMeasures():
    
    #        P
    #
    #    4  3  2  1
    #    8  7  6  5
    #    12 11 10 9
    #    16 15 14 13

    # seating plan geometry in meters
    columnSpacing = 0.9
    rowSpacing = 1.2
    rowSpacePerformer = 2.0

    # calculate maximum distance for 4x4 seating configuration
    maxDistance = math.hypot( 3 * rowSpacing, 3 * columnSpacing )

    # create base lists for use in methods
    seats = [x+1 for x in range(16)] # ie. 1-16
    seatIndexes = range(16) # ie. 0-15

    def row(self, seat): 
        '''Return row of supplied seat, as per theatre seating rows (actually y coord by above diagram)'''
        return (seat - 1) / 4 # integer division

    def column(self, seat): 
        '''Return column of supplied seat'''
        return (seat - 1) % 4

    def vectorFromPerformer(self, seat):
        '''Return r,c vector from performer to supplied seat'''

        r = self.rowSpacePerformer + self.row(seat)*self.rowSpacing
        c = (self.column(seat) - 1.5) * self.columnSpacing

        return (r,c)

    def vectorFromSeatToSeat(self, seat1, seat2):
        '''Return x,y vector from seat1 to seat2'''

        r = ( self.row(seat2) - self.row(seat1) ) * self.rowSpacing
        c = ( self.column(seat2) - self.column(seat1) ) * self.columnSpacing

        return (r,c)

    def vectorsToSeats(self, seat):
        '''Return list of distance vectors to every seat from supplied seat'''
        return [self.vectorFromSeatToSeat(seat, x) for x in self.seats]

    def seatMeasure(self, seat, seatMultipliers):
        '''Return a measure of how enclosed the supplied seat is by others'''

        # calculate closeness, where most distant seat has value of 1
        closenessToSeats = [self.maxDistance - math.hypot(r,c) + 1 for r,c in self.vectorsToSeats(seat)]

        # modify closeness by seatMultiplers
        if len(self.seats) is len(seatMultipliers):
            for index in self.seatIndexes:
                closenessToSeats[index] *= seatMultipliers[index]
        else: 
            print 'seatMultipliers not valid: length {} should be {}'.format( len(seatMultipliers), len(self.seats) )

        # remove seat from list, we don't want to sum ourselves just those around us

        del closenessToSeats[self.seats.index(seat)]

        # sum closeness to return enclosedMeasure

        return sum(closenessToSeats)


def parseFile(configuration):
    '''Parse the file'''

    exportConfig = configuration['export']
    elanConfig = configuration['source']['elan']
    bbConfig = configuration['source']['bb']
    shoreConfig = configuration['source']['shore']

    timeStepSearch = float(exportConfig['timeStep']) / 2

    seatMeasures = SeatMeasures()

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
            
            # scan the complete elan file, pulling out each annotation line that encompasses the current timestep
            
            elanConfig['file'].seek(0)
            lineSplitsForTime = []

            for line in elanConfig['file']:

                # get data from line by stripping new line character from end and then splitting by tabs
                lineSplit = line.rstrip().split('\t')

                #is the current time within the time range for this annotation?
                timeStart = float(lineSplit[elanConfig['columns'].index('timeStart')])
                timeEnd = float(lineSplit[elanConfig['columns'].index('timeEnd')])
                if timeStart <= time + float(elanConfig['offset']) < timeEnd:
                    lineSplitsForTime.append(lineSplit)

            # do what needs to be done from the annotations
            lightStateForTime = {}
            for lineSplit in lineSplitsForTime:

                annotation = lineSplit[elanConfig['columns'].index('annotation')]

                # is this line's data for the current subject?
                subjectIdx = elanConfig['columns'].index('subject')
                if lineSplit[subjectIdx] == subject:
                    
                    # classify annotation and add to current infoDict
                    matched = False
                    for key, value in elanConfig['annotationSets'].items():
                        if annotation in value:
                            infoDict[key] = annotation
                            matched = True

                    if not matched:
                        print 'Unclassified elan annotation: {} at time: {}'.format(annotation, time)

                # is the annotation needed for seat measures, ie. light state?
                if annotation in elanConfig['annotationSets']['Light State']:
                    lightStateForTime[lineSplit[subjectIdx]] = annotation

            # breathing belts -----------

            # partial scan the bb file, starting where last timestep left off and advancing to the next line only if timestep has caught up to last read line
            
            while currentBBTime < time - timeStepSearch:

                line = bbConfig['file'].readline()

                # get data from line by stripping new line character from end and then splitting by comma
                lineSplit = line.rstrip().split(', ')

                # get time from line data
                try:
                    currentBBTime = float(lineSplit[0])
                    currentBBTime += float(bbConfig['offset'])
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
                    currentShoreTime += float(shoreConfig['offset'])
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

            # seat measures --------------

            seatSubjectNames = ['Audience {:02}'.format(x) for x in seatMeasures.seats]

            seat = seatMeasures.seats[configuration['subjects'].index(subject)]

            performerSeatVector = seatMeasures.vectorFromPerformer(seat)

            infoDict['Distance from Performer'] = math.hypot(*performerSeatVector)
            infoDict['Angle from Performer'] = abs( math.atan(performerSeatVector[1] / performerSeatVector[0]) )

            presenceMultiplier = 1.0
            noPresenceMultiplier = 0.0
            presenceSeatMultipliers = [presenceMultiplier if name in configuration['subjects'] else noPresenceMultiplier for name in seatSubjectNames]

            forwardMultiplier = 1.0
            rearMultiplier = 0.0
            forwardSeatMultipliers = [forwardMultiplier if r <= 0 else rearMultiplier for r,c in seatMeasures.vectorsToSeats(seat)]

            measuresDict = {}
            measuresDict['Enclosed Measure NoBias'] = [1.0 for x in seatMeasures.seats]
            measuresDict['Enclosed Measure PresenceBias'] = presenceSeatMultipliers
            measuresDict['Enclosed Measure ForwardBias'] = forwardSeatMultipliers
            
            if len(lightStateForTime):
                
                litMultiplier = 1.0
                unlitMultiplier = 0.0
                lightStateSeatMultipliers = [litMultiplier if name in lightStateForTime and lightStateForTime[name] == 'Lit' else unlitMultiplier for name in seatSubjectNames]

                measuresDict['Enclosed Measure LightStateBias'] = lightStateSeatMultipliers

            for key, value in measuresDict.items():
                infoDict[key] = seatMeasures.seatMeasure(seat, value)


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
