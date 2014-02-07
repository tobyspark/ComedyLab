function [poseHeaders poseData gazeHeaders gazeData] = analyse(dofs, data, dataStartTime, dataSampleRate, stopAt, offsets)

% Calculates a csv file with analytic data
% created 30. 1. 2014
% @author Chris Frauenberger
% @author Toby Harris
%
%
% Input: dofs   list of labels available in data
%        data   data (num frames x dofs)
%        dataSampleRate of the data
%        dataStartTime time in secs of first frame
%        offsets offset rotation matrices
%        stopAt frame number (not plot the whole thing)
%
% Output: csv file with pose data, ie. plain text export of mocap data
%         in the folllowing format: time,x,y,z,gx,gy,gz
%
%         also calculated is gaze information
%
%
%       Note: For each person in the scene:
%             x,y,z   position of the person
%             gx,gy,gz gaze vector at position (length  = 1)
%             np   index of nearest person in line of gaze (min angle)
%             npa  gaze angle to the nearest person 
%             npx, npy, npy  distance to nearest person in each dimension
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 6
    offsets = cell(length(dofs)/12);
    for i = 1:length(dofs)/12
        offsets{i} = eye(3);
    end
end
if nargin < 5 || stopAt == -1
  stopAt = length(data);
end

entriesPerSubject = 12;
subjectCount = length(dofs)/entriesPerSubject;

% HEADERS: cell array {1 + outEntriesPerSubject*subjectCount}
poseHeaders = {'Time'};
for i=1:entriesPerSubject:length(dofs)
    name = strsplit(dofs{i},':');
    name = name{1};
    
    poseHeaders = [poseHeaders [name '/x']];
    poseHeaders = [poseHeaders [name '/y']];
    poseHeaders = [poseHeaders [name '/z']];
    poseHeaders = [poseHeaders [name '/gx']];
    poseHeaders = [poseHeaders [name '/gy']];
    poseHeaders = [poseHeaders [name '/gz']];
end

% HEADERS: cell array {outEntriesPerSubject*subjectCount}
gazeHeaders = {};
for i=1:entriesPerSubject:length(dofs)
    name = strsplit(dofs{i},':');
    name = name{1};
    
    for j = 1:subjectCount
        gazeHeaders = [gazeHeaders [name '/d' int2str(j)]];
    end
    for j = 1:subjectCount
        gazeHeaders = [gazeHeaders [name '/gd' int2str(j)]];
    end
end

% OUT: matrix [1 + outEntriesPerSubject*subjectCount; frames]
subjectForwards = {};
for subjectIndex = 1:subjectCount
    if isempty(strfind(dofs{subjectIndex*entriesPerSubject}, 'Performer'))
        forward = [-1 0 0]; % Audience
    else
        forward = [1 0 0]; % Performer
    end
    subjectForwards = [subjectForwards forward];
end

poseData = [];
gazeData = [];
for frame=1:stopAt
    poseline = [frameToTime(frame, dataStartTime, dataSampleRate)];
    gazeline = [];
    frameData = reshape(data(frame,:), entriesPerSubject, []);
    for subjectIndex = 1:subjectCount
        [position orientation distanceToOthers distFromGazeAxisToOthers] = geometryForSubjectAtFrame(subjectIndex, frameData, subjectForwards, offsets);
        
        poseline = [poseline position orientation];
        gazeline = [gazeline distanceToOthers distFromGazeAxisToOthers];
    end
    poseData = [poseData; poseline];
    gazeData = [gazeData; gazeline];
end



writeCSVFile(poseHeaders, poseData, 'Results-Pose.csv');