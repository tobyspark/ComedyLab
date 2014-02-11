function makeVideoPoseGaze(poseHeaders, poseData, gazeData, stopFrame, skipFrames)

% Produces video from data
% created 30. 1. 2014
% @author Toby Harris after Chris Frauenberger
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

if nargin < 5 
    skipFrames = 0; 
end

if nargin < 4 || stopFrame == -1
  stopFrame = length(poseData);
end

entriesPerSubject = 6;
subjectCount = (length(poseHeaders)-1)/entriesPerSubject;

f=figure;
mov = VideoWriter('Video.mp4','MPEG-4');

% todo: implement speed rather than skipFrames
dataSampleRate = 10;
movieSampleRate = 30;

open(mov);
for frame = 1:1+skipFrames:stopFrame
    poseFrame = poseData(frame, :);
    time = poseFrame(1);
    poseFrame(1) = []; % remove time entry
    
    poseFrame = reshape(poseFrame, entriesPerSubject, []);
    gazeFrame = reshape(gazeData(frame, :), 2*subjectCount, []);
    
    title(['At time: ' num2str(time)]);
    
    % only draws xyz ofthe root bone of participants
    quiver3(poseFrame(1,:), poseFrame(2,:), poseFrame(3,:), poseFrame(4,:), poseFrame(5,:), poseFrame(6,:)); hold on;
    scatter3(poseFrame(1,:), poseFrame(2,:), poseFrame(3,:)); hold off;
%     view (0,90);
    set (gca, 'XLim', [0 5000], 'YLim', [-2500 2500], 'ZLim', [0 2500])
    title(['Mocap frame: ' int2str(frame) ' Dataset time: ' num2str(time)]);
    drawnow
    writeVideo(mov, getframe(f));
end
close(f)
close(mov);