# L2 Robotic Simulation Demo

## Objective

Demonstrate a simulated robotics environment for experimentation, with vision and interaction in VR.

## Steps

1. (DONE) Set up gazebo server, gzweb (docker-compose gz, gzweb)
1. (DONE) Verify ability to add a robot to gazebo via SDF format 
   *  start gz, gzweb
   *  `cd ./infra/ros/sim/ && docker-compose up sdf2`
1. (DONE) Set up ros bridge, client mode to vr (l2vr, bridge)