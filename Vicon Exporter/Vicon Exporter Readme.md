Vicon Exporter
==============

MATLAB via Chris Frauenberger wizardry

TODO:
Performer Offset
lookedAt function


Performance 1 Incantation
-------------------------
[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm001 mk3.V', 10);
offsets = calcOffset(dofs, data, 10, 473, 484.9, 20.9, 'straight');
[headers out] = analyse(dofs, data, 10, 3220, 464, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm002 mk5.V', 10);
[headers2 out2] = analyse(dofs, data, 10, 3193, 789.2, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm003 mk1.V', 10);
[headers3 out3] = analyse(dofs, data, 10, 3042, 1109.6, offsets);

perf1 = [out; out2; out3];
writeCSVFile(headers, perf1, 'TUESDAY 3pm 123.csv');

resultsForGLMM(headers, perf1);

Performance 2 Incantation
-------------------------

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm005 mk1.V', 10);
offsets = calcOffset(dofs, data, 10, 270, 252.1, 2.4, 'straight');
[headers out] = analyse(dofs, data, 10, 4359, 249.7, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm006 mk1.V', 10);
[headers2 out2] = analyse(dofs, data, 10, 3107, 687, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm007 mk1.V', 10);
[headers3 out3] = analyse(dofs, data, 10, 3000, 999.7, offsets);

headers(:,2:12) = []; % delete clapperboard subject
out(:,2:12) = [];

perf2 = [out; out2; out3];
writeCSVFile(headers, perf2, 'TUESDAY 3pm 567.csv');



Performance 3 Incantation
-------------------------

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 5pm002 mk5.V', 10);
offsets = calcOffset(dofs, data, 10, 336, 303.9, 6.2, 'straight');
[headers out] = analyse(dofs, data, 10, 10588, 297.7, offsets);
resultsForGLMM(headers, out);