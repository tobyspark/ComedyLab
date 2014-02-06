function  offsets = calcOffset(performerTime, audienceTime, aligned, dofs, data, dataStartTime, dataSampleRate)

% calculates the rotation offsets for all participants 
% created 31.1.2014
% @author Chris Frauenberger
% @author Toby Harris
%
% Input: performerTime time at which performer looks forward
%        audienceTime time at which all audience members look forward
%        aligned if 'Performer', audience are taken as looking at performer
%        dofs labels for data
%        data the data set
%        dataStartTime seconds
%        dataSampleRate Hertz
%
% Output: rotation matrices for each person in the audience (dofs/12 -1)
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

dataEndTime = dataStartTime + (length(data)*dataSampleRate);
assert(dataStartTime < audienceTime < dataEndTime, 'Audience time outside of data');
assert(dataStartTime < performerTime < dataEndTime, 'Performer time outside of data');

audienceFrame = timeToFrame(audienceTime, dataStartTime, dataSampleRate);
performerFrame = timeToFrame(performerTime, dataStartTime, dataSampleRate);

alignForward = true;

% Do we have a performer, and if so what is the start index in the data
pIndex = -1;
for i=1:12:length(dofs)
    if ~isempty(strfind(dofs{i}, 'Performer'))
        pIndex = i;
    end
end

% Are we aligning straight forward, 
% or is the audience aligned to the performer
if strcmpi(aligned,'performer') && pIndex ~= -1
    alignForward = false;
    pPos = data(audienceframe, (pIndex+3):(pIndex+5));
end

offsets = cell(length(dofs)/12);
for i=1:12:length(dofs)
    % If audience
    if ~isempty(strfind(dofs{i}, 'Audience'))
        apos = data(audienceFrame, (i+3):(i+5));
        axrot = data(audienceFrame, i:(i+2));
        axrot = [axrot, sqrt(sum(axrot.^2,2))'];
        amrot = vrrotvec2mat(axrot);
        if alignForward
            offsets{ceil(i/12)} = amrot';
        else
            dirvec = [1 0 0] * amrot;
            offrot = vrrotvec2mat(vrrotvec(pPos - apos,dirvec));
            offsets{ceil(i/12)} = offrot;
        end
    % If performer    
    elseif i == pIndex
        pxrot = data(performerFrame, i:(i+2));
        pxrot = [pxrot, sqrt(sum(pxrot.^2,2))'];
        pmrot = vrrotvec2mat(pxrot);
        offsets{ceil(i/12)} = pmrot';
    else
        error('Found non-performer or audience entry in dataset');
    end
end

