Vicon Exporter
==============

MATLAB via Chris Frauenberger wizardry

Performance 1 Incantation
-------------------------

clear all

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm001 mk3.V', 10);
offsets = calcOffset(496.5, 473, 'straight', dofs, data, 464, 10);
[poseHeaders1 poseData1 gazeHeaders1 gazeData1] = analyse(dofs, data, 464, 10, -1, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm002 mk5.V', 10);
[poseHeaders2 poseData2 gazeHeaders2 gazeData2] = analyse(dofs, data, 789.2, 10, -1, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm003 mk1.V', 10);
[poseHeaders3 poseData3 gazeHeaders3 gazeData3] = analyse(dofs, data, 1109.6, 10, -1, offsets);

poseData = [poseData1; poseData2; poseData3];
gazeData = [gazeData1; gazeData2; gazeData3];
writeCSVFile(poseHeaders1, poseData, 'TUESDAY 3pm 123.csv');

[glmmHeaders glmmData] = resultsForGLMM(poseHeaders1, poseData, gazeData);
writeCSVFile(glmmHeaders, glmmData, 'Performance 1 Mocap.csv');

Performance 2 Incantation
-------------------------

clear all

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm005 mk1.V', 10);
dofs(:,1:12) = []; % delete clapperboard subject
data(:,1:12) = [];
offsets = calcOffset(0, 270, 'straight', dofs, data, 249.7, 10);
[poseHeaders5 poseData5 gazeHeaders5 gazeData5] = analyse(dofs, data, 249.7, 10, -1, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm006 mk1.V', 10);
[poseHeaders6 poseData6 gazeHeaders6 gazeData6] = analyse(dofs, data, 687, 10, -1, offsets);

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 3pm007 mk1.V', 10);
[poseHeaders7 poseData7 gazeHeaders7 gazeData7] = analyse(dofs, data, 999.7, 10, 3000, offsets);

poseData = [poseData5; poseData6; poseData7];
gazeData = [gazeData5; gazeData6; gazeData7];
writeCSVFile(poseHeaders5, poseData, 'TUESDAY 3pm 567.csv');

[glmmHeaders glmmData] = resultsForGLMM(poseHeaders5, poseData, gazeData);
writeCSVFile(glmmHeaders, glmmData, 'Performance 2 Mocap.csv');

Performance 3 Incantation
-------------------------

clear all

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Data - Raw/Motion Capture/TUESDAY 5pm002 mk5.V', 10);
offsets = calcOffset(380.9, 336, 'straight', dofs, data, 297.7, 10);

data1 = data(1:1483, :); 	% 297.7 - 445.9s
data2 = data(1484:1803, :); 	% 446 - 477.9s
data3 = data(1804:2533, :);	% 478 - 550.9s
data4 = data(2534:10588, :);	% 551 - 1356.4s

offsets1 = calcOffset(380.9, 336, 'straight', dofs, data, 297.7, 10);
offsets2 = calcOffset(464.2, 336, 'straight', dofs, data, 297.7, 10);
offsets3 = calcOffset(498.3, 336, 'straight', dofs, data, 297.7, 10);
offsets4 = calcOffset(1070.8, 336, 'straight', dofs, data, 297.7, 10);

[poseHeaders poseData1 gazeHeaders gazeData1] = analyse(dofs, data1, 297.7, 10, -1, offsets1);
[poseHeaders poseData2 gazeHeaders gazeData2] = analyse(dofs, data2, 446, 10, -1, offsets2);
[poseHeaders poseData3 gazeHeaders gazeData3] = analyse(dofs, data3, 478, 10, -1, offsets3);
[poseHeaders poseData4 gazeHeaders gazeData4] = analyse(dofs, data4, 551, 10, -1, offsets4);

poseData = [poseData1; poseData2; poseData3; poseData4];
gazeData = [gazeData1; gazeData2; gazeData3; gazeData4];

writeCSVFile(poseHeaders, poseData, 'TUESDAY 5pm 002.csv');

[glmmHeaders glmmData] = resultsForGLMM(poseHeaders, poseData, gazeData);
writeCSVFile(glmmHeaders, glmmData, 'Performance 3 Mocap.csv');
