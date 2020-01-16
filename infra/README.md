# Level 2 Makerspace Infra

Code and configuration for infrastructure deployable into an L2 makerspace.

## Capabilities

### VR

In the `vr/` folder is a number of software tools and programs for running a VR makerspace. Details at [./vr/README.md]

### VDI

The `vdi/` folder is for virtual desktop infra - virtual desktops are created for individual projects, and 
future work will allow these virtual desktops to migrate around the physical (or virtual) makerspace as their
user moves from place to place. Details at [./vdi/README.md]

### Storage

`storage/` contains a docker-compose environment for running a postgres DB hooked up to a ROS2 node, which can
store data at rest for access over the ROS2 network. Details at [./storage/README.md]

### Raspberry Pi

`rpi/` simulates a raspberry pi in a Docker container - useful for testing software to be deployed on multiple raspberry pi's
in a physical makerspace. Details at [./rpi/README.md]

### App

The `app/` folder hosts a native and web compatible app for managing makerspace projects that plugs into the other capabilities
in the space. Details at [./app/README.md]
