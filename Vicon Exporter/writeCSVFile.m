function writeCSVFile(headers, data, filename)

% writes the analytical data into a cvs file
% created 30. 1. 2014
% @author Chris Frauenberger
%
%
% Input: headers    cell array of labels available in data
%        data       matrix of data to write
%        filename   the file to write
%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

fid = fopen(filename, 'w');
fprintf(fid,strjoin(headers, ','));
fprintf(fid,'\n');
fclose(fid);

dlmwrite(filename, data, '-append');