# Drosophila_Behavior_Analysis
Analysis code for experiments combining high-speed video and 3D pose estimation of all leg joints with spatially targeted optogenetic perturbation of proprioceptor subtypes. 

Fruit flies were tethered and placed on a spherical treadmill. A laser optogenetically activated or silenced genetically labelled proprioceptive neurons in the left front leg. Six cameras recorded the flies movements. We used Anipose to quantify 3D position and joint angles of all leg joints (body-coxa, coxa-femur, femur-tibia, and tibia-tarsus). We used Fictrac to track the velocity (forward, rotational, sideslip) of the fly. 

The analysis contained in this repo can be divided into three research goals. 
1. Characterizing the role of femoral chordotonal (FeCO) subtypes in coordinating motor output. 
2. Assessing how joint angles change across the step cycle in correlation with changes in overall fly velocity. 
3. Quantifying the effect of perturbing hair plate neurons. 

Here's some info about the code used in each project. 

### Characterizing the role of femoral chordotonal (FeCO) subtypes in coordinating motor output.
There are five types of datasets that I analyze in this project. There are four states of the fly, and one dataset where I ramp up laser power.
- Intact + on ball 
- Intact + off ball 
- Headless + on ball 
- Headless + off ball 
- Intact + on ball - laser power 

There are two scripts that analyze the regular (not laser power) datasets. Each script loops through a set of FeCO perturbation datasets and the corresponding split half control data, plotting figures that asses changes in joint angles (particularly of the L1 femur-tibia flexion angle) when activating or silencing the FeCO subtypes. For analyzing intact + on ball data the script is [intact_onball_11102022.m](https://github.com/sarahwallingbell/Drosophila_Behavior_Analysis/blob/main/FeCO/intact_onball_11102022.m). For analyzing intact + off ball, headless + on ball, or headless + off ball data, the script is [headless_and_offball_11292022.m](https://github.com/sarahwallingbell/Drosophila_Behavior_Analysis/blob/main/FeCO/headless_and_offball_11292022.m). 

To check if ramping up the laser power increased or altered the behavioral effect of the stimulus, use the [intact_onball_power_11162022.m](https://github.com/sarahwallingbell/Drosophila_Behavior_Analysis/blob/main/FeCO/intact_onball_power_11162022.m) script. This script loops through laser power datasets and corresponding controls, and plots figures showing how changes in joint angles at stim onset (if any) change as laser power increases. 

### Assessing how joint angles change across the step cycle in correlation with changes in overall fly velocity. 
To analyze how joint angles change as a function of fly velocity, run [Walking_X_Speed_Main_01182023.m](https://github.com/sarahwallingbell/Drosophila_Behavior_Analysis/blob/main/Walking%20x%20Speed/Walking_X_Speed_Main_01182023.m). This script loads split half control data (activation and silencing data combined) and plots figures showing how joint angles change across the step cycle as a function of forward and rotational velocity. It also shows how the tarsus tip position (anterior extreme and posterior extreme positions) and step length and duration shift wtih fly velocity. 

### Quantifying the effect of perturbing hair plate neurons. 
The main script for analyzing the effect of perturbing coxa hair plate 8 (CHP8) neurons is [hair_plate_01112023.m](https://github.com/sarahwallingbell/Drosophila_Behavior_Analysis/blob/main/Hair%20Plate/hair_plate_01112023.m). This code loops through four CHP8 datasets and the corresponding split half control data, plotting figures that asses changes in body-coxa joint angles (abduction, rotation, flexion) when activating or silencing the CHP8 neurons. 




### Other useful code
- The code in the 'preprocessing' folder fixes the raw joint data output from anipose and calculates metadata (step phase, unique walking bout number, etc.) for the data and saves a processed summary parquet file. The main function for this process is [make_metadata_main.m](https://github.com/sarahwallingbell/Drosophila_Behavior_Analysis/blob/main/Preprocessing/make_metadata_main.m). 

- Code used to compare joint angles calculated with two different Anipose reference frames is here [reference_frame_comparison_01132023.m](https://github.com/sarahwallingbell/Drosophila_Behavior_Analysis/blob/main/Troubleshooting%20%26%20Testing/reference_frame_comparison_01132023.m). 

- Code used to transform the FicTrac data from camera to animal coordinates is in the 'Fictrac Correction' folder. 

- Code used to analyze if flies have different walking kinematics at the same speed across temperatures is in the 'Walking x Temp' folder. 

