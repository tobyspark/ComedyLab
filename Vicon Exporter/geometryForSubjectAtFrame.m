function [position rotation gazeDirection distanceToOthers distFromGazeAxisToOthers] = geometryForSubjectAtFrame(subjectIndex, frameData, subjectForwards, subjectOffsets)

% Calculates the geometry between subject and other subjects for given frame
% created 30. 1. 2014
% @author Chris Frauenberger, refactored into function by Toby Harris
%
%
% Input: subjectIndex
%        frameData  [data x subjects] for frame, ie. reshape(data(frame,:), entriesPerSubject, []);
%        subjectForwards cell array of forward vec for each subject
%        subjectOffsets cell array of each subject's rotation matrix offset
%
% Output: position of subject
%         rotation of subject as axis-angle
%         gazeDirection of subject
%         distanceToOthers a matrix of distances between the subject
%             and other subjects visible to them
%         distFromGazeAxisToOthers a matrix of distances to the other visible 
%              subjects from the subject's gaze axis
%
% Note:   angle extended from gaze to other subject is easy to recover 
%              asin(distFromGazeAxis/distance)
% 
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% Vicon V-File uses axis-angle represented in three datum, the axis is the xyz vector and the angle is the magnitude of the vector
% [x y z, |xyz| ]
ax = frameData(1:3,:);
ax = [ax; sqrt(sum(ax'.^2,2))'];
rotation = ax(:,subjectIndex)';

rm = vrrotvec2mat(rotation);
%% if generating offsets via calcOffset then use this
% gazeDirection = subjectForwards{subjectIndex} * rm * subjectOffsets{subjectIndex};
%% if generating offsets via Comedy Lab Dataset Viewer then use this
rotation = vrrotmat2vec(subjectsOffsets{subjectIndex} * rm);
gazeDirection = [1 0 0] * subjectOffsets{subjectIndex} * rm;

position = frameData(4:6,subjectIndex)';
distanceToOthers = [];
distFromGazeAxisToOthers = [];
for toIndex = 1:length(ax)
    if subjectIndex~=toIndex && isinfront(frameData(4:6,toIndex)', position, gazeDirection)
        % only check people within view (180 deg sphere)
        distance = norm(frameData(4:6,toIndex)'-position);
        distanceToOthers = [distanceToOthers, distance];
        
        distFromGazeAxis = distancePointLine3d(frameData(4:6,toIndex)',[position gazeDirection]);      
        distFromGazeAxisToOthers = [distFromGazeAxisToOthers, distFromGazeAxis];
    else
        distanceToOthers = [distanceToOthers, inf];
        distFromGazeAxisToOthers = [distFromGazeAxisToOthers, inf];
    end            
end
