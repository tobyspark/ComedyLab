function [position orientation vecToOthers angleToOthers] = geometryForSubjectAtFrame(subjectIndex, frameData, subjectForwards, subjectOffsets)

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
%         orientation of subject
%         vecToOthers a cell array of translation vector from subject to others
%         angleToOthers a matrix of angles extended from subject gaze to position of others
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

ax = frameData(1:3,:);
ax = [ax; sqrt(sum(ax'.^2,2))'];

rm = vrrotvec2mat(ax(:,subjectIndex));
orientation = subjectForwards{subjectIndex} * rm * subjectOffsets{subjectIndex};
position = frameData(4:6,subjectIndex)';
angleToOthers = [];
vecToOthers = {};
for toIndex = 1:length(ax)
    if subjectIndex~=toIndex && isinfront(frameData(4:6,toIndex)', position, orientation)
        % only check people within view (180 deg sphere)
        dist = distancePointLine3d(frameData(4:6,toIndex)',[position orientation]);      
        angleToOthers = [angleToOthers, asin(dist/norm(frameData(4:6,toIndex)'-position))];
        vecToOthers = [vecToOthers, [frameData(4:6,toIndex)'-position]];
    else
        angleToOthers = [angleToOthers, inf];
        vecToOthers = [vecToOthers, [inf inf inf]];
    end            
end
