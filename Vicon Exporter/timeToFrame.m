function frame = timeToFrame(time, dataStartTime, dataSampleRate)

% Convert between dataset time and capture frame number
% created 06.2.2014
% @author Toby Harris after Chris F
%
% Note: First frame is 1 not 0

frame = 1 + round((time - dataStartTime) * dataSampleRate);