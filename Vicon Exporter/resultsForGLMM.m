function [headers out] = resultsForGLMM(poseHeaders, poseData, gazeData)

% Calculates a csv file for GLMM stats from analyse() results
% created 03. 2. 2014
% @author Toby Harris
%
%
% Input: pose [time, persubject: [x y z gx gy gz]]
%        gaze [persubject: [distTo 1..n],[distFromGazeAxis 1..n]
%        ie. analyse()
%
% Output: Time Movement lookingAt pLookedAt aLookedAt
%
%       Note: time value is passed through, can be dataset or mocap time
%             For each audience member:
%             Movement - movement in time interval, a composite of translation and rotation
%             lookingAt - 1 'Performer', 2 'Audience', 3 'Floor', 0 'Other'
%             pLookedAt - 2 RPG 'Reciprocating performer gaze', 1 IPG 'In performer gaze', 0 NPG 'Not in performer gaze'
%             aLookedAt - 2 RAAG 'Reciprocating an audience member's gaze', 1 IAAG'In an audience member?s gaze', 0 NAAG 'Not in an audience member's gaze'
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

entriesPerSubject = 10;
subjectCount = (length(poseHeaders)-1)/entriesPerSubject;
frameCount = size(poseData,1);

% Currently using distance from gaze axis as test.
% Test will create a cylinder of with test value as radius.
% Seats are ~900mm apart, but a value >900 won't get both sides as
% precondition of test is others are in front, ie. exactly 180deg.
% With current innaccurate orientation offsets, a value of ~1500 is needed
% to get RAAG values.
maxDistFromGazeAxis = 1000; 
% maxGazeAngle = pi/6; % an arbitrary 30deg for now.
        
performerIndex = -1;
for i = 1:subjectCount
    if ~isempty(strfind(poseHeaders{1 + i*entriesPerSubject}, 'Performer'))
        performerIndex = i;
    end
end

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
    
        gxIdx = 1 + (j-1)*entriesPerSubject + 8;
        gzIdx = 1 + (j-1)*entriesPerSubject + 10;
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
for frame = 1:frameCount
    
    poseFrame = poseData(frame, :);
    time = poseFrame(1);
    poseFrame(1) = []; % remove time entry
    
    poseFrame = reshape(poseFrame, entriesPerSubject, []);
    gazeFrame = reshape(gazeData(frame, :), 2*subjectCount, []);
    distanceToOthersRange = 1:subjectCount;
    distFromGazeAxisToOthersRange = subjectCount+1:2*subjectCount;
    
    % Matrix [subject x subject], rows are lookingAt, columns then become lookedAt
    lookingAtMatrix = [];
    for subjectFrom = 1:subjectCount
        fromGazeAxisToOthers = gazeFrame(distFromGazeAxisToOthersRange, subjectFrom);
        isLookingAtOthers = fromGazeAxisToOthers < maxDistFromGazeAxis;
        lookingAtMatrix = [lookingAtMatrix ; isLookingAtOthers'];
    end
    
    outLine = [time];
    for subject = 1:subjectCount
        % \item[Movement] A measure of how much movement is being made by the head, computed from the head pose data. The value is a composite of distance travelled and rotation made in one time interval.
        movement = translatedMag(frame,subject)/translatedMagAv + rotatedMag(frame,subject)/rotatedMagAv;
        
        % \item[Is looking at] A state of ?Performer?, ?Audience member?, ?Floor?, ?Other?, computed from the head pose data. For our purposes, gaze here is not direct eye contact, but rather a field of view from the observer?s head within which their attention is likely to be located. We use a figure of X, motivated by Y.
        % Technique: 
        % 1. find subject with minimum gaze angle (gaze is cone) or dist (gaze is cylinder)
        % 2. if angle is within some bounds, see whether performer or audience
        % 3. if not, see whether gaze is downwards.
        % 4. if not, it's other
        
        isLookingAt = 0; %'Other';
        
        distFromGazeAxisToOthers = gazeFrame(distFromGazeAxisToOthersRange, subject);
        % distanceToOthers = gazeFrame(distanceToOthersRange, subject);
        % angleToOthers = asin(distFromGazeAxisToOthers ./ distanceToOthers);
 
        [minValue minIndex] = min (distFromGazeAxisToOthers);
        if minValue < maxDistFromGazeAxis
            if minIndex == performerIndex
                isLookingAt = 1; %'Performer';
            else
                isLookingAt = 2; %'Audience';
            end
        else
            % to test looking at floor, we use isinfront(), testing the
            % person's position on the floor (ie. can they see their feet).
            testPoint = poseFrame(1:3, subject); % head position
            testPoint(3) = 0; % set z to floor
            headPosition = poseFrame(1:3, subject);
            headOrientation = poseFrame(8:10, subject);
            if isinfront(testPoint', headPosition', headOrientation')
                isLookingAt = 3; %'Floor';
            end
        end
        
        % \item[Is being looked at by performer] A state of ?Reciprocating performer gaze?, ?In performer gaze?, ?Not in performer gaze?, computed from the head pose data as above. 
        % Technique:
        % 1. Decide test: is gaze a cone or cylinder, and of what size?
        % 2. Compile boolean matrix for whether subject is looking at others
        % 3. Any true in other axis of matrix is 'being looked at'
        
        isBeingLookedAtByPerformer = 0; %'NPG'; % Not in Performer Gaze
        
        if performerIndex > 0
            if lookingAtMatrix(performerIndex, subject)
                isBeingLookedAtByPerformer = 1; %'IPG'; % In Performer Gaze
                if lookingAtMatrix(subject, performerIndex)
                    isBeingLookedAtByPerformer = 2; %'RPG'; % Reciprocating Performer Gaze
                end
            end
        end
        
        % \item[Is being looked at by audience member] A state of ?Reciprocating an audience member?s gaze?, ?In an audience member?s gaze?, ?Not in an audience member?s gaze?, computed from the head pose data as above.
        % Technique: as above
        
        isBeingLookedAtByAudienceMember = 0; %'NAG'; % Not in Audience member's Gaze
        
        % Null performer lookingAt entries, as we are now only concerned by audience
        if performerIndex > 0
            lookingAtMatrix(performerIndex, :) = 0;
        end
        
        if any(lookingAtMatrix(:, subject))
            isBeingLookedAtByAudienceMember = 1; %'IAG'; % In Audience member's Gaze
            lookedAtIndices = find(lookingAtMatrix(:, subject));
            for lookedAtIndex = lookedAtIndices
                if lookingAtMatrix(subject, lookedAtIndex)
                    isBeingLookedAtByAudienceMember = 2; %'RAG'; % Reciprocating Audience member's Gaze
                end
            end
        end
        
        outLine = [outLine movement isLookingAt isBeingLookedAtByPerformer isBeingLookedAtByAudienceMember];
    end
    
    out = [out; outLine];
end

headers = {'Time'};
for i=1:subjectCount
    name = strsplit(poseHeaders{2+(i-1)*entriesPerSubject},'/');
    name = name{1};
    
    headers = [headers [name '/Movement']];
    headers = [headers [name '/isLookingAt']];
    headers = [headers [name '/isBeingLookedAtByPerformer']];
    headers = [headers [name '/isBeingLookedAtByAudienceMember']];
end
