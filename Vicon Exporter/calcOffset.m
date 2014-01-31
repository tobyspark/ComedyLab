function  offsets = calcOffset(dofs, data, sr, offsettime, dsync, msync, straight)

% calculates the rotation offsets for all participants 
% created 31.1.2014
% @author Chris Frauenberger
%
%
% Input: dofs labels for data
%        data the data set
%        sr samplerate of the dataset
%        offsettime the time at which all participants in the audience look
%        at the performer (dataset time)
%        dsync sync time in the dataset (seconds)
%        msync corresponding mocap sync time (seconds)
%
% Output: rotation matrices for each person in the audience (dofs/12 -1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

[mtime, mframe] = dataToMocapTime(offsettime, dsync, msync, sr);

if nargin < 7
    % find performer xyz index
    pindex = 0;
    for i=1:12:length(dofs)
        if ~isempty(strfind(dofs{i}, 'Performer'))
            pindex = i;
        end
    end
    ppos = data(mframe, (pindex+3):(pindex+5));
    straight = 0;
end

offsets = cell(length(dofs)/12);
for i=1:12:length(dofs)
    if ~isempty(strfind(dofs{i}, 'Audience'))
        apos = data(mframe, (i+3):(i+5));
        axrot = data(mframe, i:(i+2));
        axrot = [axrot, sqrt(sum(axrot.^2,2))'];
        amrot = vrrotvec2mat(axrot);
        if straight == 0
            dirvec = [1 0 0] * amrot;
            offrot = vrrotvec2mat(vrrotvec(ppos - apos,dirvec));
            offsets{ceil(i/12)} = offrot;
        else
            offsets{ceil(i/12)} = amrot';
        end
    else % Performer
        offsets{ceil(i/12)} = eye(3);
    end
end

