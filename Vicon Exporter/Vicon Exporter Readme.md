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
[poseHeaders poseData gazeHeaders gazeData] = analyse(dofs, data, 297.7, 10, -1, offsets);
writeCSVFile(poseHeaders, poseData, 'TUESDAY 5pm 002.csv');

[glmmHeaders glmmData] = resultsForGLMM(poseHeaders, poseData, gazeData);
writeCSVFile(glmmHeaders, glmmData, 'Performance 3 Mocap.csv');
