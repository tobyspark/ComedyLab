function [headers out] = resultsForGLMM(poseHeaders, poseData)

% Calculates a csv file for GLMM stats from analyse() results
% created 03. 2. 2014
% @author Toby Harris
%
%
% Input: pose [time, persubject: [x y z rx ry rz ra gx gy gz]]
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

    function frameDataZeroIndex = zeroIndexForSubject(aSubjectIndex)
       frameDataZeroIndex = 1 + ((aSubjectIndex-1) * entriesPerSubject);
    end
    
    entriesPerSubject = 10;
    subjectCount = (length(poseHeaders)-1)/entriesPerSubject;
    frameCount = size(poseData,1);
    
    %% TASK: Calculate out inter-subject gaze data from pose data
    %  ie gazeData = [persubject: [distTo 1..n],[distFromGazeAxis 1..n]
    
    gazeData = [];
    for frameIndex = 1:frameCount
        frameData = poseData(frameIndex, :);
        gazeline = [];
        for subjectIndex = 1:subjectCount
            position = frameData(zeroIndexForSubject(subjectIndex)+1:zeroIndexForSubject(subjectIndex)+3);
            gazeDirection = frameData(zeroIndexForSubject(subjectIndex)+8:zeroIndexForSubject(subjectIndex)+10);
            distanceToOthers = [];
            distFromGazeAxisToOthers = [];
            for toIndex = 1:subjectCount
                toPosition = frameData(zeroIndexForSubject(toIndex)+1:zeroIndexForSubject(toIndex)+3);
                if subjectIndex~=toIndex && isinfront(toPosition, position, gazeDirection)
                    % only check people within view (180 deg sphere)
                    distance = norm(toPosition - position);
                    distanceToOthers = [distanceToOthers, distance];
            
                    distFromGazeAxis = distancePointLine3d(toPosition, [position gazeDirection]);      
                    distFromGazeAxisToOthers = [distFromGazeAxisToOthers, distFromGazeAxis];
                else
                    distanceToOthers = [distanceToOthers, inf];
                    distFromGazeAxisToOthers = [distFromGazeAxisToOthers, inf];
                end           
            end
            gazeline = [gazeline distanceToOthers distFromGazeAxisToOthers];
        end
        gazeData = [gazeData; gazeline];
    end
    
    % Test for in-gaze is a cylinder of radius 700m rather than cone etc.
    % Determined via visualisation in Dataset Viewer
    maxDistFromGazeAxis = 700; 
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
        
        lookingAtMatrixNulledPerformer = lookingAtMatrix;
        if performerIndex > 0
            lookingAtMatrixNulledPerformer(performerIndex, :) = 0;
        end

        outLine = [time];
        for subject = 1:subjectCount
            % \item[Movement] A measure of how much movement is being made by the head, computed from the head pose data. The value is a composite of distance travelled and rotation made in one time interval.
            movement = translatedMag(frame,subject)/translatedMagAv + rotatedMag(frame,subject)/rotatedMagAv;
            
            % \item[Is looking at Performer] For our purposes, gaze here is not direct eye contact, but rather a field of view from the observer?s head within which their attention is likely to be located. Note we test for looking at an Audience and Performer separately as we do not model occlusion.
            % Technique: 
            % 1. Decide test: is gaze a cone or cylinder, and of what size?
            % 2. Compile boolean matrix for whether subject is looking at others
            % 3. Take performer value 'looking at an audience member'
            
            isLookingAtPerformer = lookingAtMatrix(subject, performerIndex);
            
            % \item[Is looking at Audience] For our purposes, gaze here is not direct eye contact, but rather a field of view from the observer?s head within which their attention is likely to be located. Note we test for looking at an Audience and Performer separately as we do not model occlusion.
            % Technique: 
            % 1. Decide test: is gaze a cone or cylinder, and of what size?
            % 2. Compile boolean matrix for whether subject is looking at others
            % 3. Take any true for non-performer values
            
            isLookingAtAudience = any(lookingAtMatrixNulledPerformer(subject, :));
            
            % \item[Is being looked at by performer] A state of ?Reciprocating performer gaze?, ?In performer gaze?, ?Not in performer gaze?, computed from the head pose data as above. 
            % Technique:
            % 1. Decide test: is gaze a cone or cylinder, and of what size?
            % 2. Compile boolean matrix for whether subject is being looked at
            % 3. Take performer value
            
            isBeingLookedAtByPerformer = lookingAtMatrix(performerIndex, subject); 
            
            % \item[Is being looked at by audience member] A state of ?Reciprocating an audience member?s gaze?, ?In an audience member?s gaze?, ?Not in an audience member?s gaze?, computed from the head pose data as above.
            % 1. Decide test: is gaze a cone or cylinder, and of what size?
            % 2. Compile boolean matrix for whether subject is being looked at
            % 3. Take any true for non-performer values
            
            isBeingLookedAtByAudienceMember = any(lookingAtMatrixNulledPerformer(:, subject));
            
            % \item[Is looking at virtual performer screen]
            % Technique: Does gaze vector intersect with screen rectangle (extended by maxDistFromGazeAxis?)
            
            % Screen x,y approximation
            % median performer position = median(poseData2(:,[2 3 4])) = 10.62  -26.70  1784.31
            % Measured size - w: 984mm x h: 1715mm, hung with top 1540mm below bar at height 3550mm
            % x = 10.62
            % y = -26.7 +/- 984/2 = -519, 465
            % z top = 3550 - 1540 = 2010
            % z bottom = 2010 - 1715 = 295
            
            screenCornerCoords = [11 -492 295; 11 -492 2010; 11 465 2010; 11 465 295];
            gazeVector = [poseFrame(1:3, subject)' poseFrame(8:10, subject)'];
            
            [inter inside] = intersectLinePolygon3d(gazeVector, screenCornerCoords);
            
            isLookingAtVPScreen = inside;
            
            outLine = [outLine movement isLookingAtPerformer isLookingAtAudience isBeingLookedAtByPerformer isBeingLookedAtByAudienceMember isLookingAtVPScreen];
        end
        
        out = [out; outLine];
    end
    
    headers = {'Time'};
    for i=1:subjectCount
        name = strsplit(poseHeaders{2+(i-1)*entriesPerSubject},'/');
        name = name{1};
        
        headers = [headers [name '/Movement']];
        headers = [headers [name '/isLookingAtPerformer']];
        headers = [headers [name '/isLookingAtAudience']];
        headers = [headers [name '/isBeingLookedAtByPerformer']];
        headers = [headers [name '/isBeingLookedAtByAudienceMember']];
        headers = [headers [name '/isLookingAtVPScreen']];
    end
end