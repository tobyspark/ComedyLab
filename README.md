ComedyLab DataSet
=================

The dataset for a series of live performance experiments researching performer-audience-audience interaction. http://tobyz.net/projects/comedylab

TASKS
=====

Getting a dataset
-----------------

DONE / Use Audience recording as base track
DONE / Combine Performer recordings to correspond with audience recording
DONE / Create BB dataset with 0.1sec granularity 
-> LabChartExporter python script
DONE / BB into ELAN
DONE / Sync up Breathing Belt - get time offset
DONE / Shore into ELAN
-> ShoreExporter python script
DONE / Tweak Shore dataset for time?
DONE / Sync up Shore
DONE / Annotate lit/unlit
DONE / annotate overall audience laughter by audio?
DONE / Tweak main video so side-by side
DONE / Tweak main video performance 1 performer is BACK IN SYNC (currently ~sec ahead)
DONE / Tweak main video so pert audio and audience audio sep L/R as much as possible
DONE / Sort out ELAN so paths are the same. No link strategy worked out, using /User/Shared/ComedyLab
-> Fuck ELAN. No really. 100% CPU usage on the second press of pause, and then annotating accurately or efficiently becomes impossible. Tried on windows, tried everything.
-> Find alternative. Fork and tweak. http://tobyz.net/tobyzstuff/diary/2013/08/forked-video-annotation-app
DONE / Annotate laughing vs not for each audience member
DONE / Assemble data for annotations, breathing belts, shore
DONE / Create dataset for state of every audience member at 0.1s intervals
-> StatsExporter python script

Performance 2
-------------
DONE / Annotate Lit/Unlit
DONE / Annotate Laughing vs not
DONE / Dataset

Live vs Recorded Analysis
-------------------------

DONE / SPSS stats comparing Performance 1 and 2
-> core findings into CHI2014 paper

Performance 3
-------------

DONE / Annotate Lit/Unlit
DONE / Annotate Laughing vs not
DONE / Dataset

check audience tier order in élan p1+p2, aud12 was in aud15 as copied p2 to make p3 document.

tweak StatsExporter.py to cope with missing shore data so we can include Audience01 (which was out of camera’s field of view) in Performance 1+2+3.

January Analysis
----------------

DONE / Add all lit / all unlit / some lit
DONE / Include sadness, anger, surprise measures from SHORE
DONE / Swap ‘Light State’ for ‘Light State While’, ie. Lit -> Lit while all lit.

Motion Capture Performance 1,2,3
--------------------------------

DONE / Post process markers into rigid bodies
Export 6DOF for performer's head
Export 6DOF for each audience member's head
Analyse how?
- Measure of movement, i.e. distance travelled / rotated in 0.1 sec
- Measure of movement correlation between performer and audience member
- Measure of movement correlation between audience member and every other member
Do we need absolute measures, ie. reference rigid body to head facing forward? Cross reference with video.

