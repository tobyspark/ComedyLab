function out = resultsForGLMM(analyseHeaders, analyseData)

% Calculates a csv file for GLMM stats from analyse() results
% created 03. 2. 2014
% @author Toby Harris
%
%
% Input: [time x y z gx gy gz np npa npx npy npz, frame]
%        ie. analyse()
%
% Output: csv file in the folllowing format
%
%       time m t r lookingAt pLookedAt aLookedAt
%
%
%       Note: time is mocap time (not video)
%             For each audience member:
%             m - movement in time interval, a composite of t and r
%             t - translation
%             r - rotation
%             lookingAt - ?Performer?, ?Audience?, ?Floor?, ?Other?
%             pLookedAt - RPG ?Reciprocating performer gaze?, IPG ?In performer gaze?, NPG ?Not in performer gaze?
%             aLookedAt - RAAG ?Reciprocating an audience member?s gaze?, IAAG ?In an audience member?s gaze?, NAAG ?Not in an audience member?s gaze?
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

subjectCount = 13;
entriesPerSubject = 11;
frameCount = size(analyseData,1);

% TASK: Find representative extents for translated and rotated amounts

% Calculate all translated and rotated amounts
%   No need to take hypotenuse, sum will suffice
translatedMag = zeros(frameCount,subjectCount);
rotateMag = zeros(frameCount,subjectCount);
for i = 2:frameCount
    for j = 1:subjectCount
        xIdx = 1 + (j-1)*entriesPerSubject + 2;
        yIdx = 1 + (j-1)*entriesPerSubject + 4;
        translated = analyseData(i, xIdx:yIdx) - analyseData(i-1, xIdx:yIdx);
        translatedMag(i,j) = sum(translated);
    
        gxIdx = 1 + (j-1)*entriesPerSubject + 5;
        gzIdx = 1 + (j-1)*entriesPerSubject + 7;
        rotated = analyseData(i, gxIdx:gzIdx) - analyseData(i-1, gxIdx:gzIdx);
        rotatedMag(i,j) = sum(rotated);
    end
end

% Average the absolute values for each subject, 
%   then take the max of all subjects
translatedMagMedian = max(mean(abs(translatedMag)));
rotatedMagMedian = max(mean(abs(rotatedMag)));

% TASK: Produce dataset now we've pre-computed globals
out = [];
for i=1:frameCount
    outLine = [analyseData(i,1)];
    
    for j = 1:subjectCount
        movement = translatedMag(i,j)/translatedMagMedian + rotatedMag(i,j)/rotatedMagMedian;
        
        outLine = [outLine movement translatedMag(i,j) rotatedMag(i,j)];
    end
    
    out = [out; outLine];
end

headers = {'Time'};
for i=1:subjectCount
    name = strsplit(analyseHeaders{2+(i-1)*entriesPerSubject},'/');
    name = name{1};
    
    headers = [headers [name '/m']];
    headers = [headers [name '/t']];
    headers = [headers [name '/r']];
end


writeCSVFile(headers, out, 'Results.csv');