function [headers out] = analyse(dofs, data, samplerate, stopAt, timeOffset, offsets)

% Calculates a csv file with analytic data
% created 30. 1. 2014
% @author Chris Frauenberger
%
%
% Input: dofs   list of labels available in data
%        data   data (num frames x dofs)
%        samplerate of the data
%        timeOffset time in secs of first frame
%        offsets offset rotation matrices
%        stopAt frame number (not plot the whole thing)
%
% Output: csv file in the folllowing format
%
%       time x,y,z,gx,gy,gz,np,npa,npx,npy,npz
%
%
%       Note: time is mocap time (not video)
%             For each person in the scene:
%             x,y,z   position of the person
%             gx,gy,gz gaze vector at position (length  = 1)
%             np   index of nearest person in line of gaze (min angle)
%             npa  gaze angle to the nearest person 
%             npx, npy, npy  distance to nearest person in each dimension
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 5
    offsets = cell(length(dofs)/12);
    for i = 1:length(dofs)/12
        offsets{i} = eye(3);
    end
end
if nargin < 4 || stopAt == -1
  stopAt = length(data);
end

% OUT: matrix [1 + entriesPerSubject*subjectCount; frames]
out = [];
for i=1:stopAt
    draw_data = reshape(data(i,:), 12, []);
    ax = draw_data(1:3,:);
    ax = [ax; sqrt(sum(ax'.^2,2))'];
    outline = [timeOffset+((i-1)/samplerate)];
    for j = 1:length(ax)
        if isempty(strfind(dofs{j*12}, 'Performer'))
            forward = [-1 0 0]; % Audience
        else
            forward = [1 0 0]; % Performer
        end
        rm = vrrotvec2mat(ax(:,j));
        vec = forward * rm * offsets{j};
        pos = draw_data(4:6,j)';
        angle = [];
        for k = 1:length(ax)
            if j~=k && isinfront(draw_data(4:6,k)', pos, vec)
                % only check people within view (180 deg sphere)
                dist = distancePointLine3d(draw_data(4:6,k)',[pos vec]);      
                angle = [angle, asin(dist/norm(draw_data(4:6,k)'-pos))];
            else
                angle = [angle, inf];
            end            
        end
        [minangle minindex] = min (angle);        
        outline = [outline pos vec minindex minangle draw_data(4:6,minindex)'-pos];
    end
    out = [out; outline];
end

% HEADERS: cell array {1 + entriesPerSubject*subjectCount}
headers = {'Time'};
for i=1:12:length(dofs)
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