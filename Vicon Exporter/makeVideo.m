function makeVideo(dofs, data, samplerate, stopAt, speedUp, offsets, checkGazeOf)

% Produces video from data
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
if nargin < 7
    checkGazeOf = 1;
end

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
mov = VideoWriter('Video.mp4','MPEG-4');
mov.FrameRate = samplerate/speedUp;
open(mov);
for i=1:speedUp:stopAt
    draw_data = reshape(data(i,:), 12, []);
    % Colour mapping for all 3D scatter plots
    colmap = repmat([0,0,0],length(draw_data(1,:)),1);
    markersize = repmat (20,length(draw_data(1,:)),1);
    colmap(checkGazeOf,:) = [0,1,0]; %colour the person we check the gaze for
    markersize(checkGazeOf) = 40;
    ax = draw_data(1:3,:);
    ax = [ax; sqrt(sum(ax'.^2,2))'];
    vecs = [];
    lookAt = [];
    for j = 1:length(ax)
        if isempty(strfind(dofs{j*12}, 'Performer'))
            forward = [-1 0 0]; % Audience
        else
            forward = [1 0 0]; % Performer
        end
        rm = vrrotvec2mat(ax(:,j));
        vec = forward * rm * offsets{j};
        vecs = [vecs, vec'];
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
        lookAt = [lookAt, minindex];
    end
    % color the target of the person we check the gaze for
    colmap(lookAt(checkGazeOf),:) = [1, 0, 0];
    markersize(lookAt(checkGazeOf)) = 40;
    % only draws xyz ofthe root bone of participants
    quiver3(draw_data(4,:), draw_data(5,:), draw_data(6,:), vecs(1,:), vecs(2,:), vecs(3,:)); hold on;
    scatter3(draw_data(4,:), draw_data(5,:), draw_data(6,:), markersize, colmap,'fill'); hold off;
%     view (0,90);
    set (gca, 'XLim', [0 5000], 'YLim', [-2500 2500], 'ZLim', [0 2500])
    drawnow
    writeVideo(mov, getframe(f));
end
close(f)
close(mov);