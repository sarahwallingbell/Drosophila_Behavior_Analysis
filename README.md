# Drosophila_Behavior_Analysis

Analysis code for experiments combining high-speed video and 3D pose estimation of all leg joints with spatially targeted optogenetic perturbation of proprioceptor subtypes. 

Fruit flies were tethered and placed on a spherical treadmill. A laser optogenetically activated or silenced genetically labelled proprioceptive neurons in the left front leg. Six cameras recorded the flies movements. We used Anipose to quantify 3D position and joint angles of all leg joints (body-coxa, coxa-femur, femur-tibia, and tibia-tarsus). We used Fictrac to track the velocity (forward, rotational, sideslip) of the fly. 

The analysis contained in this repo can be divided into three research goals. 
1. Characterizing the role of femoral chordotonal (FeCO) subtypes in coordinating motor output. 
2. Assessing how joint angles change across the step cycle in correlation with changes in overall fly velocity. 
3. Quantifying the effect of perturbing hair plate neurons. 

Here's some info about the code used in each project. 

### Characterizing the role of femoral chordotonal (FeCO) subtypes in coordinating motor output.



### Assessing how joint angles change across the step cycle in correlation with changes in overall fly velocity. 



### Quantifying the effect of perturbing hair plate neurons. 
The main script for analyzing the effect of perturbing coxa hair plate 8 (CHP8) neurons is [hair_plate_01112023.m](https://github.com/sarahwallingbell/Drosophila_Behavior_Analysis/blob/main/Hair%20Plate/hair_plate_01112023.m). This code loops through four CHP8 datasets and the corresponding split half control data, plotting figures that asses changes in body-coxa joint angles (abduction, rotation, flexion) when activating or silencing the CHP8 neurons. 
