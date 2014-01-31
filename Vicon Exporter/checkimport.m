function checkimport(dofs, data, samplerate, stopAt, speedUp, offsets)

% Produces video from data import
% created 30. 1. 2014
% @author Chris Frauenberger
%
%
% Input: dofs   list of labels available in data
%        data   data (num frames x dofs)
%        samplerate of the data
%        stopAt frame number (not plot the whole thing)
%        speedUp downsample for video by speedUp times
%        offsets offset rotation matrices
%
% Output: video 

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

if nargin < 6
    offsets = cell(length(dofs)/12);
    for i = 1:length(dofs)/12
        offsets{i} = eye(3);
    end
end

if nargin < 5 
    speedUp = 1; % no speedup
end

if nargin < 4 || stopAt == -1
  stopAt = length(data);
end

f=figure;
mov = VideoWriter('ImportCheck.mp4','MPEG-4');
mov.FrameRate = samplerate/speedUp;
open(mov);
for i=1:speedUp:stopAt
    draw_data = reshape(data(i,:), 12, []);
    ax = draw_data(1:3,:);
    ax = [ax; sqrt(sum(ax'.^2,2))'];
    vec = [];
    for j = 1:length(ax)
        if isempty(strfind(dofs{j*12}, 'Performer'))
            forward = [-1 0 0]; % Audience
        else
            forward = [1 0 0]; % Performer
        end
        rm = vrrotvec2mat(ax(:,j));
        vec = [vec, (forward * rm * offsets{j})'];
    end
    % only draws xyz ofthe root bone of participants
    quiver3(draw_data(4,:), draw_data(5,:), draw_data(6,:), vec(1,:), vec(2,:), vec(3,:)); hold on;
    scatter3(draw_data(4,:), draw_data(5,:), draw_data(6,:)); hold off;
%     view (0,90);
    set (gca, 'XLim', [0 5000], 'YLim', [-2500 2500], 'ZLim', [0 2500])
    drawnow
    writeVideo(mov, getframe(f));
end
close(f)
close(mov);