Vicon Exporter
==============

MATLAB via Chris Frauenberger wizardry

Performance 3 Incantation
-------------------------

[dfr, dofs, data] = readV('/Users/Shared/ComedyLab/Vicon Exporter/TUESDAY 5pm002 mk5.V', 10);
offsets = calcOffset(dofs, data, 10, 336, 303.9, 6.2, 'straight');
[headers out] = analyse(dofs, data, 10, 10588, offsets);
resultsForGLMM(headers, out);