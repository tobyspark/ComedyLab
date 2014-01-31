function out = analyse(dofs, data, samplerate, stopAt, offsets)

% Calculates a csv file with analytic data
% created 30. 1. 2014
% @author Chris Frauenberger
%
%
% Input: dofs   list of labels available in data
%        data   data (num frames x dofs)
%        samplerate of the data
%        offsets offset rotation matrices
%        stopAt frame number (not plot the whole thing)
%
% Output: csv file in the folllowing format
%
%       time x,y,z,x',y',z' ...
%
%
%       Note: time is dataset time (video not mocap)
%             x',y',z' is a gaze vector from the location x,y,z
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

out = [];
for i=1:stopAt
    draw_data = reshape(data(i,:), 12, []);
    ax = draw_data(1:3,:);
    ax = [ax; sqrt(sum(ax'.^2,2))'];
    outline = [i/samplerate];
    for j = 1:length(ax)
        if isempty(strfind(dofs{j*12}, 'Performer'))
            forward = [-1 0 0]; % Audience
        else
            forward = [1 0 0]; % Performer
        end
        rm = vrrotvec2mat(ax(:,j));
        vec = forward * rm * offsets{j};
        pos = draw_data(4:6,j)';
        dist = [];
%         for k = 1:length(ax)
%             % careful - this is not considering points BEHIND the person
%             dist = [dist, distancePointLine3d(draw_data(1:3,k),[pos vec])];            
%         end
        [mindist minindex] = min (dist);
        outline = [outline  pos vec minindex mindist];
    end
    out = [out; outline];
end