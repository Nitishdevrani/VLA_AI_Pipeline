
=== page 1 ===
1 
 
Frasky README 
Document Version: 2.0 – 15/10/2026 
Frasky is a robotic platform created for precision inspection and maintenance tasks in 
agricultural settings [1]. This README provides the AI BOOST challenge participants with a 
brief overview of the platform and its core functionalities together with a technical 
description of the platform architecture and structured list of available robot actions and 
workflow description. 
1 Frasky Functionalities and Missions Definition 
Based on a known map of the environment1, Frasky can perform autonomously precision 
agriculture tasks in vineyards, such as data collection and localized treatment applications. 
A typical mission is structured as follows: 
• Phase 1 – Grape mapping: during this phase, Frasky navigates the environment to 
identify and localize each grape present in the map. During grape mapping, each 
grape cluster is assigned an ID, and its pose in map frame is stored in a .JSON file. 
This phase is preparatory for the following task execution and shall be performed at 
least once before starting Phase 2. Note that in the simulator package is provided the 
.JSON file related to the grape mapping of the first vineyard row. 
 
Figure 1: grape mapping process: while the robot autonomously navigates through the vineyard (left), it detects the grapes 
and registers their position which could be retrieved for subsequent actions (right). 
 
• Phase 2 – Task Execution: during this phase the user can call one or more Frasky 
actions; available capabilities are: data collection and localized treatment 
applications. These tasks can be performed either on a specific ID, or on all the grape 
 
1 During the competition a map of the testing site will be available on the robot. 


=== page 2 ===
2 
 
clusters in memory. Depending on the Frasky current pose, the task execution may 
require composing navigation and manipulation subtasks.  
 
Main Frasky functionalities are briefly described below: 
• Navigation action: this task enables natural navigation in the map; it requires in input 
a list of waypoints in map frame. 
• Manipulation actions: Frasky manipulation capabilities are required for performing 
two different types of action, namely: “APPROACH” and “SPRAY”, which respectively 
correspond to data collection and localized treatment application. Each action type 
corresponds to a specific list of end-effector waypoints in object frame. Moreover, 
the action type defines the specific end-effector involved and its related parameters. 
 
Detailed descriptions of the specific ROS call of each task are reported in the following 
sections of the document. 
2 System overview 
Figure 2 shows the set-up provided to AIBOOST Challenge participants, that consists of a  
digital twin of the robotic platform and a vineyard simulator (GAZEBO). 
 The Frasky control modules are embedded in a docker file. Please note that the robot pc is 
configured as a Linux machine with ROS (Ubuntu 20.04 LTS - ROS 1 Noetic [2]), and 
communication should be implemented through standard ROS-1 calls. 
 
 
 
Figure 2: Frasky Digital Twin and Vineyard simulator. 
 


=== page 3 ===
3 
 
The Frasky robot is a mobile manipulator composed of a Husky A-200 ClearPath mobile base 
and a Franka Emika Panda arm Fr3 (7DoF). Figure 3 shows the location of the main sensors 
and components. It is worth noticing that at the end-effector a depth camera (RealSense 
D415), a custom designed spray nozzle and a soft end-effector (SoftHand Research by qb 
Robotics) are integrated.  
 
Figure 3: Frasky’s Components Overview 
 
3 Frasky Software Architecture 
Frasky’s software is divided into navigation, perception, and manipulation modules 
coordinated by a task manager. Navigation provides localization, filtering, mapping, 
obstacle avoidance, and base status; perception detects, tracks, identifies, and geo-
localizes grapes; manipulation performs inspection, precision spray, and physical 
interaction. For more detailed information, please see [1], pages 5–8, section “IV. Software 
Architecture.” 


=== page 4 ===
4 
 
 
Figure 4: Frasky Software Architecture [1]. 
 
3.1 Shared materials and folder structure 
The shared materials are organized over three folders: 
--- >Documents 
--- > Frasky_Vineyard_simulator 
--- > Grapes_Dataset 
 
Which respectively collect the challenge documents and readme, the simulation packages 
and the images composing the grapes dataset. 
Frasky Vineyard simulator comprises the robot digital twin (kinematic model and controls) 
and a simulated vineyard for development purposes. Additional files provided to enable 
testing all the robot functions are: 
• environment occupancy map (inside Gazebo simulator),  
• “husky_nav_out.json” waypoints on the occupancy map to be used as the navigation 
input, 
• “mapping_first_row.json” grape mapping of the first row (to use as baseline for testing 
the system) 


=== page 5 ===
5 
 
3.2 Pc Minimum requirements 
This information refers to the PC on which the docker container for Frasky simulator has 
been tested 
3.2.1 Hardware 
inxi 
–Fz  
        
System:
 
        
Kernel: 5.15.0
- 139 - generic x86_64 bits: 64 
 
        
Desktop: Gnome 3.36.9 
 
        
Distro
: Ubuntu 20.04.6 LTS (Focal Fossa) 
 
        
Machine:
 
        
Type: Laptop System: Dell 
 
        
product: Dell G15 Special Edition 5521 v: N/A 
 
        
serial: <filter> 
 
        
Mobo: Dell model: 0371KJ v: A01 serial: <filter> 
 
        
UEFI: Dell v: 1.42.0 date: 05/26/2026 
 
        
Battery:
 
        
ID - 1: BAT0 charge: 41.9 Wh 
 
        
condition: 41.9/84.3 Wh (50%) 
 
        
CPU:  
        
Topology: 10
- Core  
        
model: 12th Gen Intel Core i7
- 12700H bits: 64 
 
        
type: MT MCP L2 cache: 24.0 MiB 
 
        
Speed: 2300 MHz min/max: 400/4600 MHz 
 
        
Core speeds (MHz): 1: 2299 2: 2298 3: 2298 4: 2298 
 
        
5: 2128 6: 2131 7: 2126 8: 2126 9: 2218 10: 2210 
 
        
11: 2210 12: 2213 13: 2303 14: 2306 15: 2312 16: 2309 
 
        
17: 2299 18: 2299 19: 2310 20: 2307 
 
        
Graphics:
 
        
Device - 1: Intel driver: i915 v: kernel 
 
        
Device - 2: NVIDIA driver: nvidia v: 570.133.07 
 
        
Display: x11 server: X.Org 1.20.13 driver: nvidia resolution: 
2560x1440~240Hz, 
 
        
1920x1080~60Hz, 1920x1080~60Hz 
 
        
OpenGL: 
 
        
renderer: NVIDIA GeForce RTX 3060 Laptop GPU/PCIe/SSE2 
 
        
v: 4.6.0 NVIDIA 570.133.07 
 
        
Audio:  
        
Device - 1: Intel driver: sof
- audio - pci - intel
- tgl 
 
        
Device - 2: NVIDIA driver: snd_hda_intel 
 
        
Device - 3: Sony DualShock 4 [CUH
- ZCT2x] type: USB 
 
        
driver: snd
- usb - audio,sony,usbhid 
 
        
Sound Server: ALSA v: k5.15.0
- 139 - generic 
 
        
Network:  
        
Device - 1: Intel driver: iwlwifi 
 
        
IF: wlp0s20f3 state: down mac: <filter> 
 
        
Device - 2: Realtek driver: r8169 
 
        
IF: enp58s0 state: down mac: <filter> 
 
        
Device - 3: Realtek RTL8153 Gigabit Ethernet Adapter 
 
        
type: USB driver: r8152 
 
        
IF: enxa0cec8e1c6da state: up speed: 1000 Mbps 
 
        
duplex: full mac: <filter> 
 


=== page 6 ===
6 
 
        
IF - ID - 1: br
- 2928e49ccd0e state: down mac: <filter> 
 
        
IF - ID - 2: br
- 2a1f91e3219d state: down mac: <filter> 
 
        
IF - ID - 3: br
- d590ab0fa9b3 state: down mac: <filter> 
 
        
IF - ID - 4: docker0 state: down mac: <filter> 
 
        
IF - ID - 5: docker_gwbridge state: down mac: <filter> 
 
        
IF - ID - 6: mpqemubr0 state: down mac: <filter> 
 
        
IF - ID - 7: ztdiyrn5tr state: unknown speed: 10 Mbps 
 
        
duplex: full mac: <filter> 
 
        
IF - ID - 8: ztksetiecy state: unknown speed: 10 Mbps 
 
        
duplex: full mac: <filter> 
 
        
Drives:
 
        
Local Storage: total: 1.86 TiB 
 
        
used: 757.38 GiB (39.7%) 
 
        
ID - 1: /dev/nvme0n1 model: PC SN530 NVMe WDC 1024GB 
 
        
size: 953.87 GiB 
 
        
ID - 2: /dev/sda type: USB vendor: Intenso model: SSD 
 
        
size: 953.87 GiB 
 
        
RAID:  
        
Hardware - 1: Intel Volume Management Device NVMe RAID 
 
        
Controller 
 
        
driver: vmd 
 
        
Partition:
 
        
ID - 1: / size: 457.53 GiB used: 408.39 GiB (89.3%) 
 
        
fs: ext4 dev: /dev/nvme0n1p5 
 
        
Sensors:
 
        
System Temperatures: cpu: 74.0 C mobo: N/A 
 
        
gpu: nvidia temp: 69 C 
 
        
Fan Speeds (RPM): N/A 
 
        
Info:
 
        
Processes: 674 Uptime: 2h 00m Memory: 31.03 GiB 
 
        
used: 16.73 GiB (53.9%) Shell: bash inxi: 3.0.38
 
 
3.2.2 Graphical Card NVIDIA  
nvidia
- smi  
Thu Oct 15 15:54:10 2026       
 
+------------------------------------------------------------------------------
-----------
+ 
| NVIDIA
- SMI 570.133.07             Driver Version: 570.133.07     CUDA 
Version: 12.8     |
 
|-----------------------------------------
+------------------------
+-----------
-----------
+ 
| GPU  Name
                 
Persistence
- M | Bus
- Id          Disp.A | Volatile 
Uncorr. ECC |
 
| Fan  Temp   Perf          Pwr:Usage/Cap |           Memory
- Usage | GPU
- Util  
Compute M. |
 
|                                         |                        |               
MIG M. |
 
|=========================================+========================+===========
===========|
 
|   0  NVIDIA GeForce RTX 3060 ...    Off |   00000000:01:00.0 Off |                  
N/A |  
| N/A   59C    P5             31W /  115
W |    1368MiB /   6144MiB |     36%      
Default |
 
|                                         |                        |                  


=== page 7 ===
7 
 
N/A |  
+-----------------------------------------
+------------------------
+-----------
-----------
+ 
                                                                                         
 
+------------------------------------------------------------------------------
-----------
+ 
| Processes:                                                                              
| 
|  GPU   GI   CI              PID   Type   Process name                        
GPU Memory |  
|        ID   ID                                                               
Usage      |
 
|==============================================================================
===========|
 
+------------------------------------------------------------------------------
-----------
+ 
3.2.3 PC Docker version 
docker version
 
  
        Client: Docker Engine - Community 
        Version:           28.1.1 
        API version:       1.49 
        Go version:        go1.23.8 
        Git commit:        4eba377 
        Built:             Fri Apr 18 09:52:18 2025 
        OS/Arch:           linux/amd64 
        Context:           default 
  
        Server: Docker Engine - Community 
        Engine: 
        Version:          28.1.1 
        API version:      1.49 (minimum version 1.24) 
        Go version:       go1.23.8 
        Git commit:       01f442b 
        Built:            Fri Apr 18 09:52:18 2025 
        OS/Arch:          linux/amd64 
        Experimental:     false 


=== page 8 ===
8 
 
        containerd: 
        Version:          1.7.27 
        GitCommit:        05044ec0a9a75232cad458027ca83437aae3f4da 
        runc: 
        Version:          1.2.5 
        GitCommit:        v1.2.5-0-g59923ef 
        docker-init: 
        Version:          0.19.0 
        GitCommit:        de40ad0 
3.3 Prerequisites 
AI BOOST challenge participants should be able to communicate with ROS Noetic. 
3.4 Start the simulator 
1. Download the shared folder  
2. Open the folder “Frasky_Vineyard_simulator” using visual studio code 
3. Open a terminal in that folder due to launch the following commands 
a. Load the image: 
docker load 
-- input frasky_test.tar.gz
 
Expected output:  
Loaded image: frasky_test:latest
 
b. Launch the container  
source start_sim.sh
 
c. Launch the simulator in the terminator open 
frasky_
sim_ start
 
3.5 To stop the simulator and close the container 
1. Stop the simulator 
frasky_sim_stop
 
2. Close the container (In the terminal the the souce start_sim.sh open) 
exit  
3. Stop the container 
docker stop frasky_test 
 


=== page 9 ===
9 
 
4 Examples of End-to-end workflows 
Supported high-level workflows are: 
1. Grape mapping along a preprogrammed route; 
2. Monitoring task: Navigation to all grapes, followed by inspection  
3. Precision Task on a specific ID: Navigation to one grape, followed by precision spray  
4. Cancellation through routine exit and, when necessary, base-goal cancellation. 
 
4.1 Grape Mapping 
4.1.1 Description 
Grape mapping is the process where the robot navigates autonomously in the vineyard and 
collects data related to each detected grape, to be used later for different manipulation and 
navigation tasks. 
This routine identifies grapes and records each ID, confidence, grape pose, robot pose, and 
task pose and store it in a .JSON file. We provide the .JSON file corresponding to the grape 
mapping of the first vineyard row. High quality and extension of the grape mapping will reflect 
in higher scoring. 
 
4.1.2 Sequence steps 
4.1.2.1Start the mapping node: 
Inline command from your host terminal: 
docker exec frasky_test bash 
- lc 'source /opt/ros/noetic/setup.bash && source 
$HOME/catkin_ws/devel/setup.bash && roslaunch 
-- screen 
--
pid=/tmp/mapping_roslaunch.pid frasky_detection mapping.launch'
 
expected output 
... logging to /root/.ros/log/b21758e2
- 9243 - 11f1 - 904d - 00d49eaf3589/roslaunch
-
jntlbz1
- 982026.log
 
Checking log directory for disk usage. This may take a while.
 
Press Ctrl
- C to interrupt
 
WARNING: disk usage in log directory [/root/.ros/log] is over 1GB.
 
It's recommended that you use the 'rosclean' command.
 
 
started roslaunch server http://jntlbz1:33621/
 
 
SUMMARY 


=== page 10 ===
10 
 
========  
 
PARAMETERS  
/robot_frasky/
frasky_detection
/add_pose_sn: /robot_frasky/Add...
 
/robot_frasky/
frasky_detection
/attention_threshold: 2.0
 
/robot_frasky/
frasky_detection
/camera_tf: /robot_frasky/C_1
 
/robot_frasky/
frasky_detection
/confidence: 0.7
 
/robot_frasky/
frasky_detection
/confidence_min: 0.01
 
/robot_frasky/
frasky_detection
/crop_estimator_log_folder: /code/src/detecti...
 
/robot_frasky/
frasky_detection
/detection_output_tn: crop_data
 
/robot_frasky/
frasky_detection
/full_map_to_task_sn: full_map_to_task
 
/robot_frasky/
frasky_detection
/grape_distance_max_to_update: 2.0
 
/robot_frasky/
frasky_detection
/grasp_step_config: ee_wrt_arm_base
 
/robot_frasky/
frasky_detection
/image_input_tn: /robot_frasky/cam...
 
/robot_frasky/
frasky_detection
/image_output_tn: /robot_frasky/det...
 
/robot_frasky/
frasky_detection
/localization_tf: /robot_frasky
/EE_3  
/robot_frasky/
frasky_detection
/map_json_name: test
 
/robot_frasky/
frasky_detection
/map_tf: /robot_frasky/world
 
/robot_frasky/
frasky_detection
/map_to_task_sn: export_map_to_task
 
/robot_frasky/
frasky_detection
/mode: robot
 
/robot_frasky/
frasky_detection
/nav_step_config: frasky_nav
 
/robot_frasky/
frasky_detection
/node_loop_rate: 30
 
/robot_frasky/
frasky_detection
/pointcloud_input_tn: /robot_frasky/cam...
 
/robot_frasky/
frasky_detection
/reset_task_sn: /robot_frasky/Res...
 
/robot_frasky/
frasky_detection
/sample_map_to_task_sn: sample_map_to_task
 
/robot_frasky/
frasky_detection
/save_task_sn: /robot_frasky/Sav...
 
/robot_frasky/
frasky_detection
/store_crop_data_sn: store_crop_map
 
/rosdistro: noetic
 
/rosversion: 1.16.0
 
 
NODES 
/robot_frasky/
frasky_detection
/ 
crop_estimator_x_coord (
frasky_detection
/crop_estimator_x_coord)
 
crop_map_db (
frasky_detection
/crop_map_db.py)
 
yolo_tracking (
frasky_detection
/yolo_tracking.py)
 
 
ROS_MASTER_URI=http://localhost:11311
 
 
process[robot
frasky/
frasky_
dection
/yolo_tracking
- 1]: started with pid [982105]
 
process[robot_frasky/
frasky_
dection
/crop_estimator_x_coord
- 2]: started with pid 
[982106]
 
process[robot_frasky/
frasky_
dection
/crop_map_db
- 3]: started with pid [982107]
 
Crop map database online
 
 
4.1.2.2 Check the presence of important topics  
rostopic hz /robot_frasky/camera/color/image_raw
 
rostopic hz /robot_frasky/camera/depth/color/points
 
 
4.1.2.3 Call manipulator homing routine as: 
rosservice call /robot_frasky/
Routine "name: 
HOMING" 
 


=== page 11 ===
11 
 
4.1.2.4 Call the grape mapping routine as: 
rosservice call /robot_frasky/
Routine "name: 
MAP" 
 
The result will be a .JSON file. (file name is “test_mapping.json”) 
4.1.2.5 Wait untill the task is being executed  
Subscribe to the routine status topic  
/robot_frasky/routine_status
 
Its value changes over time in this way: 
Before command        data: false 
Routine accepted      data: true 
Routine executing      data: true 
Routine completed   data: false 
 
4.1.2.6 Kill mapping nodes 
After the Grape mapping phase is executed, kill the mapping nodes following the 
Inline command: 
 
docker exec frasky_test bash 
- lc 'kill 
- INT "$(cat 
/tmp/mapping_roslaunch.pid)"'
 
Expected output (in the previous terminal): 
 
Crop map database online
 
[robot_frasky/
frasky_detection
/crop_map_db
- 3] killing on exit
 
[robot_frasky/
frasky_detection
/crop_estimator_x_coord
- 2] killing on exit
 
[robot_frasky/
frasky_detection
/yolo_tracking
- 1] killing on exit
 
shutting down processing monitor...
 
... shutting down processing monitor complete
 
done  
Connection to 
192.168.26.163
 closed.
 
 
4.1.2.7 Verify that new JSON files exist, and if it exist, it saves the file on your pc  
The mapping json is shared between the container and the host in the test_mapping.json of 
the downloaded folder. You can get the json looking at that file or you can use the following 
command: 
docker exec frasky
_test bash 
- lc 'source /opt/ros/noetic/setup.bash && source 
$HOME/catkin_ws
/devel/setup.bash && cat 
\ " \ $(rospack find 
frasky_detection
)/crop_map_db/test_
mapping .json
\ "' > test_filtered_pose.json && 
echo "Saved to: $(
realpath test_filtered_pose.json)" && python3 
- m json.tool 
test_filtered_pose.json
 
expected output: 


=== page 12 ===
12 
 
Saved to: /home/jntlbgr/gr/test_filtered_pose.json
 
[  
{  
"id": 3,
 
"confidence": 0.785522496138794,
 
"grape_pose": {
 
"position": {
 
"x": 0.06629361123067257,
 
"y": 
- 0.8003778636646057,
 
"z": 0.9634559294648198
 
},  
"orientation": {
 
"x": 0.0,
 
"y": 0.0,
 
"z": 0.0,
 
"w": 0.0
 
}  
},  
"robot_pose": {
 
"position": {
 
"x": 
- 0.42914081166739426,
 
"y": 
- 0.07399513883185659,
 
"z": 0.0
 
},  
"orientation": {
 
"x": 0.0,
 
"y": 0.0,
 
"z": 
- 0.01321055430196256,
 
"w": 0.9999127368200862
 
}  
},  
"grasping_pose": {
 
"position": {
 
"x": 0.5370159394582306,
 
"y": 
- 0.11604059981656886,
 
"z": 1.0330432564928587
 
},  
"orientation": {
 
"x": 
- 0.04463280879809732,
 
"y": 0.7819839102348213,
 
"z": 
- 0.6211802619128513,
 
"w": 
- 0.02538028216023125
 
}  
}  
},  
***** SAME FOR EACH FOUND IDS ****
 
]  
 


=== page 13 ===
13 
 
4.2 Monitoring task: Navigation to all grapes, followed by inspection 
4.2.1 Description  
Monitoring tasks will be autonomous navigation to all the detected id’s on the vineyard and 
execute the inspection task on the targeted grapes. 
 
4.2.2 Sequence Steps  
The following steps are to reach an ID. To reach all ID identified in the grape mapping, you 
have to iterate on JSON entries in file order. For each entry, complete the one-target workflow 
from 4.3.2.1 to 4.3.2.6 and kill the navigation nodes when you have reached all the ID’s. 
 
4.2.2.1Start the navigation node 
Inline command 
docker exec frasky_test bash 
- lc 'source /opt/ros/noetic/setup.bash && source 
$HOME/catkin_ws/devel/setup.bash && 
roslaunch 
-- screen 
--
pid=/tmp/navigation_roslaunch.pid frasky_detection navigation.launch'
 
expected output: 
... logging to /root/.ros/log/b21758e2
- 9243 - 11f1 - 904d - 00d49eaf3589/roslaunch
-
jntlbz1
- 1021500.log
 
Checking log directory for disk usage. This may take a while.
 
Press Ctrl
- C to interrupt
 
WARNING: disk usage in log directory [/root/.ros/log] is over 1GB.
 
It's recommended that you use the 'rosclean' command.
 
 
started roslaunch server http://jntlbz1:42745/
 
 
SUMMARY 
========  
 
PARAMETERS  
 * /robot_frasky/
frasky_detection
/add_pose_sn: /robot_frasky/Add...
 
 * /robot_frasky/
frasky_detection
/attention_threshold: 2.0
 
 * /robot_frasky/
frasky_detection
/camera_tf: /robot_frasky/C_1
 
 * /robot_frasky/
frasky_detection
/confidence: 0.7
 
 * /robot_frasky/
frasky_detection
/confidence_min: 0.01
 
 * /robot_frasky/
frasky_detection
/crop_estimator_log_folder: 
/code/src/detecti...
 
 * /robot_frasky/
frasky_detection
/detection_output_tn: crop_data
 
 * /robot_frasky/
frasky_detection
/full_map_to_task_sn: full_map_to_task
 
 * / robot_frasky/
frasky_detection
/grape_distance_max_to_update: 2.0
 
 * /robot_frasky/
frasky_detection
/grasp_step_config: ee_wrt_arm_base
 
 * /robot_frasky/
frasky_detection
/image_input_tn: /robot_frasky/cam...
 
 * /robot_frasky/
frasky_detection
/image_output_tn: /robot_frasky/det...
 
 * /robot_frasky/
frasky_detection
/localization_tf: /robot_frasky/EE_3
 


=== page 14 ===
14 
 
 * /robot_frasky/
frasky_detection
/map_json_name: test
 
 * /robot_frasky/
frasky_detection
/map_tf: /robot_frasky/world
 
 * /robot_frasky/
frasky_detection
/map_to_task_sn: 
export_map_to_task
 
 * /robot_frasky/
frasky_detection
/mode: robot
 
 * /robot_frasky/
frasky_detection
/nav_step_config: frasky_nav
 
 * /robot_frasky/
frasky_detection
/node_loop_rate: 30
 
 * /robot_frasky/
frasky_detection
/pointcloud_input_tn: /robot_frasky/cam...
 
 * /robot_frasky/
frasky_detection
/reset_task_sn: /robot_frasky/Res...
 
 * /robot_frasky/
frasky_detection
/sample_map_to_task_sn: sample_map_to_task
 
 * /robot_frasky/
frasky_detection
/save_task_sn: /robot_frasky/Sav...
 
 * /robot_frasky/
frasky_detection
/ store_crop_data_sn: store_crop_map
 
 * /rosdistro: noetic
 
 * /rosversion: 1.16.0
 
 
NODES 
  /robot_frasky/
frasky_detection
/ 
    
active_perception (
frasky_detection
/active_perception)
 
    
yolo_tracking_no_labels (
frasky_detection
/yolo_tracking_no_labels.py)
 
 
ROS_MASTER_URI=http://localhost:11311
 
 
process[robot_frasky/
frasky_detection
/yolo_tracking_no_labels
- 1]: started with 
pid [1021572]
 
process[robot_frasky/
frasky_detection
/active_perception
- 2]: started with pid 
[1021573]
 
 
4.2.2.2 Load a JSON file and find an exact ID match, publishing the related robot pose 
 
In the Json file the robot_pose represents the mobile-base pose saved when that grape was 
mapped. Consequently, the robot navigates back to the position from which the grape was 
originally observed, rather than directly to the grape’s three-dimensional position. For 
navigation, the user orchestrator should read the robot_pose associated with the selected 
grape from the .JSON file and convert it into a geometry_msgs/PoseStamped message. Then 
it sets the message header.frame_id to robot_pose and continuously publishes the target on 
/orchestrator/robot_pose
.  
4.2.2.3 call the navigation routine as:  
this routine will enable the robot navigation to the requested ID. 
rosservice call /robot_frasky/
Routine "name: 
NAV" 
 
4.2.2.4 Wait untill the task is being executed  
Subscribe to the routine status topic  
/robot_frasky/routine_status
 
Its value changes over time in this way: 


=== page 15 ===
15 
 
Before command        data: false 
Routine accepted      data: true 
Routine executing      data: true 
Routine completed   data: false 
 
4.2.2.5 Then call the monitoring routine as:  
 
rosservice call /robot_frasky/
Routine "name: 
APPROACH" 
 
4.2.2.6 Wait untill the task is being executed  
Subscribe to the routine status topic  
/robot_frasky/routine_status
 
Its value changes over time in this way: 
Before command        data: false 
Routine accepted      data: true 
Routine executing      data: true 
Routine completed   data: false 
 
4.2.2.7 Kill navigation nodes (Just when you have to stop the navigation task, when you have 
finished reaching the selected ID’s) 
Before killing the nodes, it is possible to send the robot to base location, calling the routine  
 
rosservice call /robot_frasky/
Routine "name: 
BASE_HOME" 
 
Inline command: 
 
docker exec frasky_test bash 
- lc 'kill 
- INT "$(cat 
/tmp/navigation_roslaunch.pid)"'
 
Expected output (of previous terminal): 
 
process[robot_frasky/
frasky_detection
/yolo_tracking_no_labels
- 1]: started with 
pid [1021572]
 
process[robot_frasky/
frasky_detection
/active_perception
- 2]: started with pid 
[1021573]
 
[ robot_frasky/
frasky_detection
/active_perception
- 2] killing on exit
 
[robot_frasky/
frasky_detection
/yolo_tracking_no_labels
- 1] killing on exit
 
shutting down processing monitor...
 
... shutting down processing monitor complete
 


=== page 16 ===
16 
 
done  
Connection to 
192.168.26.163
 closed.
 
 
4.3 Precision Task on a specific ID: Navigation to one grape, 
followed by precision spray 
4.3.1 Description  
Precision task will be autonomous navigation to a detected id on the vineyard and execute 
the spray task on the grape. 
 
4.3.2 Sequence Steps  
4.3.2.1Start the navigation node 
Inline command 
docker exec frasky_test bash 
- lc 'source /opt/ros/noetic/setup.bash && source 
$HOME/catkin_ws/devel/setup.bash && roslaunch 
-- screen 
--
pid=/tmp/navigation_roslaunch.pid frasky_detection navigation.launch'
 
expected output: 
... logging to /root/.ros/log/b21758e2
- 9243 - 11f1 - 904d - 00d49eaf3589/roslaunch
-
jntlbz1
- 1021500.log
 
Checking log directory for disk usage. This may take a while.
 
Press Ctrl
- C to interrupt
 
WARNING: disk usage in log directory [/root/.ros
/log] is over 1GB.
 
It's recommended that you use the 'rosclean' command.
 
 
started roslaunch server http://jntlbz1:42745/
 
 
SUMMARY 
========  
 
PARAMETERS  
 * /robot_frasky/frasky_detection/add_pose_sn: /robot_frasky/Add...
 
 * /robot_frasky/frasky_detection/attention_threshold: 2.0
 
 * /robot_frasky/frasky_detection/camera_tf: /robot_frasky/C_1
 
 * /robot_frasky/frasky_detection/confidence: 0.7
 
 * /robot_frasky/frasky_detection/confidence_min: 0.01
 
 * /robot_frasky/frasky_detection/crop_estimator_log_folder
: 
/code/src/detecti...
 
 * /robot_frasky/frasky_detection/detection_output_tn: crop_data
 
 * /robot_frasky/frasky_detection/full_map_to_task_sn: full_map_to_task
 
 * /robot_frasky/frasky_detection/grape_distance_max_to_update: 2.0
 
 * /robot_frasky/frasky_detection/grasp_step_config: ee_wrt_arm_base
 
 * /robot_frasky/frasky_detection/image_input_tn: /robot_frasky/cam...
 
 * /robot_frasky/frasky_detection/image_output_tn: /robot_frasky/det...
 
 * /robot_frasky/frasky_detection/localization_tf: /robot_frasky/EE_3
 
 * /robot_frasky/frasky_detection/map_json_name: test
 


=== page 17 ===
17 
 
 * /robot_frasky/frasky_detection/map_tf: /robot_frasky/world
 
 * /robot_frasky/frasky_detection/map_to_task_sn: export_map_to_task
 
 * /robot_frasky/frasky_detection/mode: robot
 
 * /robot_frasky/frasky_detection/nav_step_config: frasky_nav
 
 * /robot_frasky/frasky_detection/node_loop_rate: 30
 
 * /robot_frasky/frasky_detection/pointcloud_input_tn: /robot_frasky/cam...
 
 * /robot_frasky/frasky_detection/reset_task_sn: /robot_frasky/Res...
 
 * /robot_frasky/
frasky_detection/sample_map_to_task_sn: sample_map_to_task
 
 * /robot_frasky/frasky_detection/save_task_sn: /robot_frasky/Sav...
 
 * /robot_frasky/frasky_detection/store_crop_data_sn: store_crop_map
 
 * /rosdistro: noetic
 
 * /rosversion: 1.16.0
 
 
NODES 
  /robot_frasky/frasky_detection/
 
    
active_perception (frasky_detection/active_perception)
 
    
yolo_tracking_no_labels (frasky_detection/yolo_tracking_no_labels.py)
 
 
ROS_MASTER_URI=http://localhost:11311
 
 
process[robot_frasky/frasky_detection/yolo_tracking_no_labels
- 1]: started with 
pid [1021572]
 
process[robot_frasky/frasky_detection/active_perception
- 2]: started with pid 
[1021573]
 
 
 
 
4.3.2.2 Load a JSON file and find an exact ID match, publishing the related robot pose 
 
In the Json file the robot_pose represents the mobile-base pose saved when that grape was 
mapped. Consequently, the robot navigates back to the position from which the grape was 
originally observed, rather than directly to the grape’s three-dimensional position. For 
navigation, the user orchestrator should read the robot_pose associated with the selected 
grape from the .JSON file and convert it into a geometry_msgs/PoseStamped message. Then 
it sets the message header.frame_id to robot_pose and continuously publishes the target on 
/orchestrator/robot_pose
.  
4.3.2.3 call the navigation routine as:  
this routine will enable the robot navigation to the requested ID. 
rosservice call /robot_frasky/
Routine "name: 
NAV" 
 
4.3.2.4 Wait untill the task is being executed  
Subscribe to the routine status topic  
/robot_frasky/routine_status
 
Its value changes over time in this way: 


=== page 18 ===
18 
 
Before command        data: false 
Routine accepted      data: true 
Routine executing      data: true 
Routine completed   data: false 
 
4.3.2.5 Then call the manipulation routine (treatment application) as:  
 
rosservice call /robot_frasky/
Routine "name: 
SPRAY " 
 
4.3.2.6 Wait untill the task is being executed  
Subscribe to the routine status topic  
/robot_frasky/routine_status
 
Its value changes over time in this way: 
Before command        data: false 
Routine accepted      data: true 
Routine executing      data: true 
Routine completed   data: false 
 
4.3.2.7 Kill navigation nodes (Just when you have to stop the navigation task, when you have 
finished reaching the selected ID’s) 
Before killing the nodes, it is possible to send the robot to base location, calling the routine  
 
rosservice call /robot_frasky/
Routine "name: 
BASE_HOME" 
 
Inline command: 
 
docker exec frasky_test bash 
- lc 'kill 
- INT "$(cat 
/tmp/navigation_roslaunch.pid)"'
 
Expected output (of previous terminal): 
 
process[robot_frasky/frasky_detection/yolo_tracking_no_labels
- 1]: started with 
pid [1021572]
 
process[robot_frasky/frasky_detection/active_perception
- 2]: started with pid 
[1021573]
 
[robot_frasky/frasky_detection
/active_perception
- 2] killing on exit
 
[robot_frasky/frasky_detection/yolo_tracking_no_labels
- 1] killing on exit
 
shutting down processing monitor...
 
... shutting down processing monitor complete
 


=== page 19 ===
19 
 
done  
Connection to 
192.168.26.163
 closed.
 
 
 
4.4 Pause, resume, stop, and recovery: 
4.4.1 If there is any error during the manipulation process 
4.4.1.1 Send the fr3 in Home position 
  
rosservice call /robot_frasky/
Routine "name: 
HOMING" 
 
4.4.2 To stop the active work 
You have to call the followings: 
Service  
Description 
rosservice call 
/ robot_frasky/RoutineExit "{}"
 
 Stops the robot while manipulating 
and navigating 
rosservice call 
/auto2ark/cancelGoal "{}"
 
Stops the robot while navigating 
 
Then wait for routine_status=false, active_replay=false, and a source-confirmed safe base 
state (see details for /robot_frasky/robot_status topic). 
 
5 Id randomizer 
5.1 To get an id random from the test_mapping.json 
source $HOME/catkin_ws/src/randomizer.sh 
/home/frasky_ws_container/catkin_ws/src/frasky_ws/frasky_detection/c
rop_map_db/test_mapping.json
 


=== page 20 ===
20 
 
 
Successfully loaded JSON data: 
[{'id': 1, 'confidence': 0.8500942337897517, 'grape_pose': {'position': {'x': -2.4054659502800178, 'y': 
0.07999195804389758, 'z': 1.1944008064022844}, 'orientation': {'x': 0.0, 'y': 0.0, 'z': 0.0, 'w': 0.0}}, 
'robot_pose': {'position': {'x': -2.519841023552747, 'y': 0.8626016624745917, 'z': -2.6386844114156816e-
05}, 'orientation': {'x': -3.327990406401234e-05, 'y': 2.6159251501577266e-05, 'z': -0.08958817346519674, 
**** ] 
ids found: [1, 3, 5, 2, 4, 6, 7, 8, 25, 29, 9, 14, 18, 22, 27, 30, 42, 37, 41, 44, 45, 46] 
Random value selected: 8 
 
5.2 To get an id random from the mapping_first_row.json 
source $HOME/catkin_ws/src/randomizer.sh 
/home/frasky_ws_container/catkin_ws/src/frasky_ws/frasky_detection/c
rop_map_db/mapping_first_row.json
 
Successfully loaded JSON data: 
[{'id': 1, 'confidence': 0.8500942337897517, 'grape_pose': {'position': {'x': -2.4054659502800178, 'y': 
0.07999195804389758, 'z': 1.1944008064022844}, 'orientation': {'x': 0.0, 'y': 0.0, 'z': 0.0, 'w': 0.0}}, 
'robot_pose': {'position': {'x': -2.519841023552747, 'y': 0.8626016624745917, 'z': -2.6386844114156816e-
05}, 'orientation': {'x': -3.327990406401234e-05, 'y': 2.6159251501577266e-05, 'z': -0.08958817346519674, 
**** ] 
ids found: [1, 3, 5, 2, 4, 6, 7, 8, 25, 29, 9, 14, 18, 22, 27, 30, 42, 37, 41, 44, 45, 46] 
Random value selected: 8 
 


=== page 21 ===
21 
 
6 Topic reference 
6.1 External command, state, and feedback topics 
/orchestrator/robot_pose
 
 Message Type: geometry_msgs/PoseStamped
 
 Usage: Navigation target. Populate header.stamp
, header.frame_id: robot_pose
, 
position x,y,z
, and a normalized quaternion. A topic which reads robot_pose
from the 
JSON database, publish and allow discovery before Routine(NAV)
. 
Valid target publication example: 
rostopic pub 
- r 100 /orchestrator/robot_pose 
geometry_msgs/PoseStamped 
\ 
"header:
 
  stamp: now
 
  frame_id: 'robot_pose'
 
pose:  
  position: {x: 
- 1.0771456, y: 4.8287010, z: 0.1322787}
 
  orientation: {x: 0.0, y: 0.0, z: 0.7339026, w: 0.6792547}"
 
  
/robot_frasky/routine_status
 
 Message Type: std_msgs/Bool
 
 Usage: It is used to get the feedback when the system is executing different tasks. 
data=true
when routine executing/waiting on a task. data=false
: routine idle or ended. 
 Feedback: Require a false → true → false
 cycle after a command. A lone false
 is not 
proof the requested routine ran. 
  
/auto2ark/robot_state
 
 Message Type: std_msgs
/Int64
 
 Usage: Get the status value of the robot, referring to the below table.  
 feedback:  
 
Table 1: State machine description 
State 
Meaning 
Note 
-1 
Idle 
Waiting for a goal 
1 
Goal received 
Mobile base has received a goal and 
accepted 
2 
In progress 
Mobile base is moving toward the 
goal 
3 
In progress 
Mobile base is moving toward the 
goal 
4 
Rejected 
Goal is rejected 
6 
Not defined 
Mobile base internal error 
7 
Not defined 
Mobile base internal error 
 
   


=== page 22 ===
22 
 
6.2 Readiness topics 
/robot_frasky/franka_ee_pose
 
 Message Type: geometry_msgs/PoseStamped
 
 Usage: To check the Cartesian pose of the E-E in the robotic arm base frame 
  
/robot_frasky/right_hand_measurement
 
 Message Type: std_msgs/Float64
 
 Usage: Hand closure state from 0 (full open) to 1 (full close)  
6.3 Topics created by child launches 
/robot_frasky/camera/color/image_raw
 
 Message Type: sensor_msgs/Image
 
 Usage: RGB input; standard header , dimensions, encoding, data 
  
/robot_frasky/camera/depth/color/points
 
 Message Type: sensor_msgs/PointCloud2
 
 Usage: Organized depth cloud indexed at grape bounding-box center 
  
/robot_frasky/
frasky_detection
/crop_data
 
 Message Type: frasky_detection
/TrackingData
 
 Usage: hader ; counter ; bb_list[]
. Each box: id , p1{x,y}
, p2{x,y}
, conf  in model 
confidence range 
  
/robot_frasky/detection_img
 
 Message Type: sensor_msgs/Image
 
 Usage: Visual diagnostic only; Annotated RGB8 detection image 
  
/robot_frasky/
frasky_detection
/closest_grape_pose
 
 Message Type: geometry_msgs/PoseStamped
 
 Usage: Pose of nearest detected grape in camera coordinates; orientation identity. 
header.frame_id
 is left empty in current code. Position in m; suppressed while active 
replay or streaming is disabled 
  
/robot_frasky/active_replay
 
 Message Type: std_msgs/Bool
 
 Usage: true  while a task trajectory is being emitted; false
 idle. Used to freeze near-grape 
stream during replay. 
 feedback: Internal execution feedback; routine completion uses routine_status
 
  
/tf , /tf_static
 
 Message Type: tf2_msgs/TFMessage
 
 Usage: provide map-to-base and map/camera transforms; robot config names 
/robot_frasky/world
, /robot_frasky/EE_3
, /robot_frasky/C_1
. Transform units 
m/quaternion; timestamp within 3 s lookup wait  


=== page 23 ===
23 
 
7 Service reference 
7.1 Externally usable mission services 
/robot_frasky/Routine
 
 Type jntlb_fwk_msgs/SetName
 
 Purpose: Queue a named routine 
 Request fields: string name
: one deployed routine parameter, configured values are: 
MAP, NAV, APPROACH, GRASP , SPRAY , HOMING, BASE_HOME. 
 Response fields/success: Empty response. A successful service transport call only 
means callback accepted the name. Require routine_status
 true then false. 
 Preconditions/side effects: Routine must be idle and parameter /robot_frasky/<name>
 
must resolve to a nonempty task list. Causes base/arm/tool motion depending on name. 
 Failure cases: Missing parameter is printed as “THIS ROUTINE DOES NOT EXIST”; no 
structured error. Concurrent calls can replace globals. 
  
/robot_frasky/RoutineExit
 
 Type: std_srvs/Empty
 
 Purpose: Stop the current routine and call underlying /robot_frasky/Exit
 
 Request fields: No fields 
 Response fields/success: Empty response; final confirmation is routine_status=false
 
and active_replay=false
 
 Preconditions/side effects: Safety-critical mission interruption. 
 Failure cases: Calling while idle can leave an exit flag that aborts the next routine when it 
reaches wait state. 
  
/auto2ark/cancelGoal
 
 Type: std_srvs/Empty
 
 Purpose: Cancel active mobile-base navigation goal 
 Request fields: No fields 
 Response fields/success: Empty response. 
 Preconditions/side effects: Use with RoutineExit
 when base motion may be active; 
wait for safe/idle state before another target 
 Failure cases: Service unavailable, goal already inactive, base bridge unavailable; exact 
errors not confirmed 
 
/robot_frasky/GetVision
 
 Type: std_srvs/Empty
 
 Purpose: Set vision_on=true
 so bridge accepts the next vision-derived pose 
 Request fields: No fields 
 Response fields/success: Empty response. 
 Preconditions/side effects: Robot bridge must run and its vision_pose
 chain must 
subscribe to the deployed active-perception output. 
  


=== page 24 ===
24 
 
7.2 Mapping/perception services created by child launches 
/robot_frasky/
frasky_detection
/store_crop_map
 
 Type: frasky_detection
/CropMap  
 Purpose: Append mapped grapes and write three JSON variants 
 Request fields: name; timestamp ; map[] . Each Grape  has id , conf , grape_pose
, 
robot_pose
, grasping_pose
 
 Response fields: bool result
 
 Preconditions/side 
effects/success: 
Writes 
<startup
- time>_<name>.json
, 
_filtered.json
 (conf > confidence
 and robot quaternion w != 0
), and 
_filtered_pose.json
 (w != 0
). Estimator calls after a grape is unseen longer than 
attention_threshold
. 
 Failure cases: Returns false only before initialization; filesystem exceptions are not 
handled. 
8 References  
[1]  E. Khiali, A. Marchetti, G. Ribolla, F. Negrello, et al. "Towards a Robotic Platform for 
Precision Vineyard Operations." IEEE Access (2026). 
[2] https://wiki.ros.org/noetic  
 
