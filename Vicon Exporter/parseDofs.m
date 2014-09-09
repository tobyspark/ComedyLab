function [poseHeaders poseData] = parseDofs(dofs, data, dataStartTime, dataSampleRate, stopAt, offsets)

% Parses .V data imported via readV.m
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
% Output: pose in the folllowing format: time,x,y,z,gx,gy,gz
%        pose is the export of the .V data
%
%       Note: For each person in the scene:
%             x,y,z   position of the person
%             rx, ry, rz, ra axis-angle orientation of the person
%             gx,gy,gz gaze vector at position (length  = 1)
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
    poseHeaders = [poseHeaders [name '/rx']];
    poseHeaders = [poseHeaders [name '/ry']];
    poseHeaders = [poseHeaders [name '/rz']];
    poseHeaders = [poseHeaders [name '/ra']];    
    poseHeaders = [poseHeaders [name '/gx']];
    poseHeaders = [poseHeaders [name '/gy']];
    poseHeaders = [poseHeaders [name '/gz']];
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
for frame=1:stopAt
    poseline = [frameToTime(frame, dataStartTime, dataSampleRate)];
    frameData = reshape(data(frame,:), entriesPerSubject, []);
    for subjectIndex = 1:subjectCount
        
        %% POSITION
        position = frameData(4:6,subjectIndex)';
        
        %% ORIENTATION
        % Vicon V-File uses axis-angle represented in three datum, the axis is the xyz vector and the angle is the magnitude of the vector
        % [x y z, |xyz| ]
        ax = frameData(1:3,:);
        ax = [ax; sqrt(sum(ax'.^2,2))'];
        rotation = ax(:,subjectIndex)';
        
        %% ORIENTATION CORRECTED FOR OFF-AXIS ORIENTATION OF MARKER STRUCTURE
        rm = vrrotvec2mat(rotation);
        
        %% if generating offsets via calcOffset then use this
        % rotation = vrrotmat2vec(rm * offsets{subjectIndex});
        % gazeDirection = subjectForwards{subjectIndex} * rm * offsets{subjectIndex};
        
        %% if generating offsets via Comedy Lab Dataset Viewer then use this
        rotation = vrrotmat2vec(offsets{subjectIndex} * rm);
        gazeDirection = [1 0 0] * offsets{subjectIndex} * rm;
        
        poseline = [poseline position rotation gazeDirection];
    end
    poseData = [poseData; poseline];
end
