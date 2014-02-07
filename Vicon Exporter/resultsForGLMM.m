function out = resultsForGLMM(poseHeaders, poseData, gazeData)

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

entriesPerSubject = 6;
subjectCount = (length(poseHeaders)-1)/entriesPerSubject;
frameCount = size(poseData,1);

% TASK: Find representative extents for translated and rotated amounts

% Calculate all translated and rotated amounts
translatedMag = zeros(frameCount,subjectCount);
rotateMag = zeros(frameCount,subjectCount);
for i = 2:frameCount
    for j = 1:subjectCount
        xIdx = 1 + (j-1)*entriesPerSubject + 1;
        zIdx = 1 + (j-1)*entriesPerSubject + 3;
        translated = poseData(i, xIdx:zIdx) - poseData(i-1, xIdx:zIdx);
        translatedMag(i,j) = norm(translated);
    
        gxIdx = 1 + (j-1)*entriesPerSubject + 4;
        gzIdx = 1 + (j-1)*entriesPerSubject + 6;
        rotated = poseData(i, gxIdx:gzIdx) - poseData(i-1, gxIdx:gzIdx);
        rotatedMag(i,j) = norm(rotated);
    end
end

% Average the absolute values for each subject, 
%   then take the max of all subjects
translatedMagAv = max(mean(abs(translatedMag)));
rotatedMagAv = max(mean(abs(rotatedMag)));

% TASK: Produce dataset now we've pre-computed globals
out = [];
for i=1:frameCount
    outLine = [poseData(i,1)];
    
    for j = 1:subjectCount
        % \item[Movement] A measure of how much movement is being made by the head, computed from the head pose data. The value is a composite of distance travelled and rotation made in one time interval.
        movement = translatedMag(i,j)/translatedMagAv + rotatedMag(i,j)/rotatedMagAv;
        
        % \item[Is looking at] A state of ?Performer?, ?Audience member?, ?Floor?, ?Other?, computed from the head pose data. For our purposes, gaze here is not direct eye contact, but rather a field of view from the observer?s head within which their attention is likely to be located. We use a figure of X, motivated by Y.
        % Technique: 
        % 1. find subject with minimum gaze angle (gaze is cone) or dist (gaze is cylinder)
        % 2. if angle is within some bounds, see whether performer or audience
        % 3. if not, see whether gaze is downwards.
        % 4. if not, it's other
        
        maxGazeAngle = pi/6; % an arbitrary 30deg for now.
        
        angleToOthers = asin(distFromGazeAxisToOthers ./ distanceToOthers);
 
        [minangle minindex] = min (angleToOthers);
        if minangle < maxGazeAngle
            %...........
        end
        %...........
        
        % \item[Is being looked at by performer] A state of ?Reciprocating performer gaze?, ?In performer gaze?, ?Not in performer gaze?, computed from the head pose data as above. 
        % Technique:
        % 1. Decide test: is gaze a cone or cylinder, and of what size?
        % 2. Compile boolean matrix for whether subject is looking at others
        % 3. Any true in other axis of matrix is 'being looked at'
        
        % \item[Is being looked at by audience member] A state of ?Reciprocating an audience member?s gaze?, ?In an audience member?s gaze?, ?Not in an audience member?s gaze?, computed from the head pose data as above.
        % Technique: as above
        
        
        outLine = [outLine movement ];
    end
    
    out = [out; outLine];
end

headers = {'Time'};
for i=1:subjectCount
    name = strsplit(poseHeaders{2+(i-1)*entriesPerSubject},'/');
    name = name{1};
    
    headers = [headers [name '/m']];
    headers = [headers [name '/t']];
    headers = [headers [name '/r']];
end

writeCSVFile(headers, out, 'Results-GLMM.csv');