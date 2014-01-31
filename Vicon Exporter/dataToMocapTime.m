function [mtime, mframe] = dataToMocapTime(dtime, dsync, msync, msr)

% calculates mocap frame number for corresponding dataset time
% created 31.1.2014
% @author Chris Frauenberger
%
%
% Input: dtime dataset time
%        dsync dataset sync time 
%        msync corresponding mocap sync time
%        msr mocap samplerate (or downsampled data rate)
%
% Output: frame in mocap capture

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

mtime = msync + (dtime - dsync);
mframe = round(mtime*msr);