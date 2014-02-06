function [headers out] = analyse(dofs, data, dataStartTime, dataSampleRate, stopAt, offsets)

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
% Output: csv file in the folllowing format
%
%       time x,y,z,gx,gy,gz,np,npa,npx,npy,npz
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

% OUT: matrix [1 + outEntriesPerSubject*subjectCount; frames]
out = [];
for frame=1:stopAt
    outline = [frameToTime(frame, dataStartTime, dataSampleRate)];
    
    frameData = reshape(data(frame,:), entriesPerSubject, []);
    
    subjectForwards = {};
    for subjectIndex = 1:subjectCount
        if isempty(strfind(dofs{subjectIndex*entriesPerSubject}, 'Performer'))
            forward = [-1 0 0]; % Audience
        else
            forward = [1 0 0]; % Performer
        end
        subjectForwards = [subjectForwards forward];
    end
    
    for subjectIndex = 1:subjectCount
        [pos vec vecToOthers angleToOthers] = geometryForSubjectAtFrame(subjectIndex, frameData, subjectForwards, offsets);
        
        [minangle minindex] = min (angleToOthers);
        if minangle == inf
            outline = [outline pos vec -1 minangle vecToOthers{minindex}];
        else
            outline = [outline pos vec minindex minangle vecToOthers{minindex}];
        end
    end
    out = [out; outline];
end

% HEADERS: cell array {1 + outEntriesPerSubject*subjectCount}
headers = {'Time'};
for i=1:entriesPerSubject:length(dofs)
    name = strsplit(dofs{i},':');
    name = name{1};
    
    headers = [headers [name '/x']];
    headers = [headers [name '/y']];
    headers = [headers [name '/z']];
    headers = [headers [name '/gx']];
    headers = [headers [name '/gy']];
    headers = [headers [name '/gz']];
    headers = [headers [name '/np']];
    headers = [headers [name '/npa']];
    headers = [headers [name '/npx']];
    headers = [headers [name '/npy']];
    headers = [headers [name '/npz']];
end

writeCSVFile(headers, out, 'Results.csv');