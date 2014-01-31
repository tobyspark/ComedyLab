function [fr, dofs, data] = readV(filename,samplingrate)

% Reads in a Vicon V file
% created 13. June 2013
% @author Chris Frauenberger
%
%
% Input: filename
%
% Output: fr    original framerate
%         dofs  labels 
%         data  data (num frames x dofs)

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%


fid = fopen(filename);

% read the file header (4 bytes)
fread(fid,4);

sections = true;
while sections
   slength = fread(fid, 1,'uint32');
   if slength == 0
       disp ('end of sections');
       sections = false;
       % move to the end of the empty section header
       % this is also 2 bytes longer than in the specs... see below
       fseek(fid, 30, 'cof');
   else
       eos = false;
       name = '';
       while ~eos
           c = fread(fid,1,'char');
           if c == 0
               eos = true;
           else
               name = [name, c];
           end
       end
       % move to the end of the section header
       fseek(fid, 27 - length(name), 'cof');
       % read section content
       if strcmp(name, 'DATAGROUP')
           % read in the static data we need from the datagroup section
           reclen = fread(fid,1,'uint16');
           gid = fread(fid,1,'uint16');
           dl = fread(fid,1,'uint8');
           desc = char(reshape(fread(fid,dl,'char'),1,[]));
           type = fread(fid,1,'uint8');
           width = fread(fid,1,'uint8');
           if type == 3
               doftype = 'int16';
               doftypeL = 2;
           elseif type == 4
               doftype = 'int32';
               doftypeL = 4;
           elseif type == 5
               doftype = 'float';
               doftypeL = 4;
           elseif type == 6
               doftype = 'double';
               doftypeL = 8;
           else
               doftype = 'int8';
               doftypeL = 1;
           end
           % despite being a float in the specs, sampling frequency is
           % given as a double!
           fr = fread(fid,1,'double');
           numdofs = fread(fid,1,'uint16');
           disp('*** Datagroup information header:');
           disp(['File name: ', filename]);
           disp(['Section name: ', name]);
           disp(['Record Length: ', num2str(reclen)]);
           disp(['Group ID ', num2str(gid)]);
           disp(['Data description: ', desc]);
           disp(['DOF type: ', doftype]);
           disp(['DOF type width: ', num2str(width)]);
           disp(['Sampling frequency: ', num2str(fr)]);
           disp(['Number of DOFs: ', num2str(numdofs)]);
           disp('Labels:');
           dofs = [];
           for i = 1:numdofs 
               label = '';
               eoflabel = false;
               labellen = fread(fid,1,'char');
               while ~eoflabel
                   c = fread(fid,1,'char');
                   if c == 0
                       eoflabel = true;
                   else
                       label = [label, c];
                   end
               end
               dofs = [dofs, ',', label];
%                disp(label);
           end           
           dofs = strsplit(dofs,',');
           dofs(1) = []; % cut out first element (extra ,)
           disp('---------------------------------');
       else
           disp(name);
           % move to the end of the section
           fseek(fid, slength, 'cof');
       end
   end
end

if nargin < 2
  samplingrate = fr;
end

disp(['reading data with samplingrate: ',  num2str(samplingrate)]);
skipvalues = floor(fr/samplingrate) - 1;
% read raw motion data
rawdata = [];
skip=0;
lineLength = 8 + numdofs * doftypeL;
while ~feof(fid)
    if skip == 0
        reclen = fread(fid,1,'int16');
        grid = fread(fid,1,'int16');
        framenum = fread(fid,1,'uint32');
        if grid == gid
            % make sure we read in records for the datagroup
            rawdata = [rawdata; reshape(fread(fid,numdofs,doftype), 1, [])];
        end
    else                
        fseek(fid, lineLength, 'cof');
        if skip == skipvalues
            skip = -1;
        end
    end
    skip = skip +1;
end
data = rawdata;

