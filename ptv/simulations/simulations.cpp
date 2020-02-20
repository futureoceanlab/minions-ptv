#include <iostream>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <unistd.h>

#include <opencv2/opencv.hpp>


using namespace std;


// Function declaration
void readInstrinsics(cv::Mat M, cv::Mat D, string intrinsicsPath);
void readExtrinsics(cv::Mat R, cv::Mat T, string extrinsicsPath);


int main(int argc, char **argv)
{
    // intrinsics file(left and right), 
    // extrinsics file, output directory
    if (arc == 5)
    {
        string intrinsicsPath1 = argv[1];
        string intrinsicsPath2 = argv[2];
        string extrinsicsPath = argv[3];
        string outputDir = argv[4];
        createSimulatedParticles(intrinsicsPath1, 
                                intrinsicsPath2, 
                                extrinsicsPath, 
                                outputDir);
    }
    else 
    {
        cout << "Not enough arguments" << endl;
    }
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
void createSimulatedParticles(string intrinsicsPath1, 
                              string intrinsicsPath2, 
                              string extrinsicsPath,
                              string outputDir) 
{
    // 1. read the intrinsics and extrinsics files from the arguments
    // R is rotational matrix and T translational matrix
    // in reference to the left camera
    cv::Mat M1, D1, M2, D2, R, T; 
    readIntrinsics(M1, D1, intrinsicsPath1);
    readIntrinsics(M2, D2, intrinsicsPath2);
    readExtrinsics(R, T, extrinsicsPath);
    
    // 2. Initialize the first frame
    vector<vector<cv::Point3f>> particleObjectPoints;
    vector<vector<cv::Point2f>> particleImagePoints[2];

    initializeParticlePositions(particleObjectPoints);
    projectObjectsToImages(particleObjectPoints, particleImagePoints, 
                           M1, D1, M2, D2, R, T);

    // 3. based on the velocity with some noise, update the particles position
    // in 3D position and re-project them onto the imaging plane.
    for (int i = 0; i < 3; i++) 
    {
        updateParticlePositions(particleObjectPoints, particleImagePoints);
        projectObjectsToImages(particleObjectPoints, particleImagePoints, 
                               M1, D1, M2, D2, R, T);    
    }
    // 4. plot the particles on the image planes
    vector<cv::Mat> particleImages[2];
    drawParticles(particleImagePoints);
    // 5. save the particle positions as well as their images onto the output directory
    saveSimulations(particleImages);
    return;
}

/**
 * Read intrinsics file
 */
void readInstrinsics(cv::Mat M, cv::Mat D, string intrinsicsPath)
{
    cv::FileStorage intrinsicsFile(intrinsicsPath, cv::FileStorage::READ);
    if (intrinsicsFile.isOpned())
    {
        intrinsicsFile["M"] >> M;
        intrinsicsFile["D"] >> D;
    }
    else 
    {
        cout << "Could not open the intrinsics file " << intrinsicsPath << endl; 
    }
    return;
}

/**
 * Read extrinsics file
 */
void readExtrinsics(cv::Mat R, cv::Mat T, string extrinsicsPath)
{
    cv::FileStorage extrinsicsFile(extrinsicsPath, cv::FileStorage::READ);
    if (extrinsicsFile.isOpned())
    {
        extrinsicsFile["R"] >> R;
        extrinsicsFile["T"] >> T;
    }
    else 
    {
        cout << "Could not open the extrinsics file " << extrinsicsPath << endl; 
    }
    return;
}

