#include <iostream>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include <opencv2/opencv.hpp>


using namespace std;


int main(int argc, char **argv)
{
    // intrinsics file(left and right), extrinsics file, output directory
    return 0;
}


/**
 * createSimulateadParticles: create images of particles falling in simulated
 * volume of water projected onto left and right images with given camera
 * intrinsics and extrinsics. The origin is the center of the left camera.
 *  
 * The scenario for falling particles are very simple. The particles are falling
 * along the z-axis. The distribution follows from a very rough idea in my head
 * (trying to recllect the paper...)
 * 
 * The imaging volume based on simple computation. 0.02mm/px resolution 
 * 2592x1944 (51.84mm x 38.88mm) with DoF 40mm. The imaging volume is centered
 * z = working distance based on the intrinsics, x = y = 0. 
 * 
 * Initialize a 1L volume whose particles are distributed accordingly are projected onto
 * image planes. Reject any particles outside of the imaging plane.Save the accepted
 * particles in the list. 
 * 
 * velocities and accelerations are computed separately, whose values are applied
 * to the particles in every "frame". The frame speed is 1Hz.
 * 
 * particle diameter: density / average velocity
 * 50um:
 * 100um:
 * 250um:
 * 500um:
 * 1000um:
 * 
 */
void createSimulatedParticles() 
{
    // 1. read the intrinsics and extrinsics files from the arguments
    // 2. Initialize the first frame
    // 3. based on the velocity with some noise, update the particles position in
    //    3D position and re-project them onto the imaging plane.
    // 4. save the particle positions as well as their images onto the output directory
    saveSimulations(img1List, img2List);
    return;
}