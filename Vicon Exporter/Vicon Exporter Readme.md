Vicon Exporter
==============

MATLAB via Chris Frauenberger wizardry

TODO:
lookedAt function


Performance 1 Incantation
-------------------------
[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm001 mk3.V', 10);
offsets = calcOffset(496.5, 473, 'straight', dofs, data, 464, 10);
[headers out] = analyse(dofs, data, 464, 10, -1, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm002 mk5.V', 10);
[headers2 out2] = analyse(dofs, data, 789.2, 10, -1, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm003 mk1.V', 10);
[headers3 out3] = analyse(dofs, data, 1109.6, 10, -1, offsets);

perf1 = [out; out2; out3];
writeCSVFile(headers, perf1, 'TUESDAY 3pm 123.csv');

resultsForGLMM(headers, perf1);

Performance 2 Incantation
-------------------------

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm005 mk1.V', 10);
dofs(:,1:12) = []; % delete clapperboard subject
data(:,1:12) = [];
offsets = calcOffset(0, 270, 'straight', dofs, data, 249.7, 10);
[headers out] = analyse(dofs, data, 249.7, 10, -1, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm006 mk1.V', 10);
[headers2 out2] = analyse(dofs, data, 687, 10, -1, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm007 mk1.V', 10);
[headers3 out3] = analyse(dofs, data, 999.7, 10, 3000, offsets);

perf2 = [out; out2; out3];
writeCSVFile(headers, perf2, 'TUESDAY 3pm 567.csv');

resultsForGLMM(headers, perf2);

Performance 3 Incantation
-------------------------

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 5pm002 mk5.V', 10);
offsets = calcOffset(380.9, 336, 'straight', dofs, data, 297.7, 10);
[headers perf3] = analyse(dofs, data, 297.7, 10, -1, offsets);
writeCSVFile(headers, perf3, 'TUESDAY 5pm 002.csv');

resultsForGLMM(headers, perf3);