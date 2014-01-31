function writeCVSFile(dofs, data, filename)

% writes the analytical data into a cvs file
% created 30. 1. 2014
% @author Chris Frauenberger
%
%
% Input: dofs   list of labels available in data
%        data   output from analyse.m
%        filename of the file to write
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fid = fopen(filename, 'w');
fprintf(fid,'Time');
for i=1:12:length(dofs)
    name = strsplit(dofs{i},':');
    fprintf(fid,',%s', name{1});
end
fprintf(fid,'\n');
fclose(fid);

dlmwrite(filename, data, '-append');