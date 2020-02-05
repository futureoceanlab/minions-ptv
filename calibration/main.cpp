#include <opencv2/opencv.hpp>
#include <iostream>
#include <string.h>
#include <stdlib.h>
#include <stdio.h>
#include <math.h>
#include <unistd.h>

using namespace std;

string curPath;

void help(char *argv[]) {
  cout
      << "\n\nExample 19-3. Stereo calibration, rectification, and "
         "correspondence"
      << "\n    Reads in list of locations of a sequence of checkerboard "
         "calibration"
      << "\n    objects from a left,right stereo camera pair. Calibrates, "
         "rectifies and then"
      << "\n    does stereo correspondence."
      << "\n"
      << "\n    This program will run on default parameters assuming you "
         "created a build directory"
      << "\n    directly below the Learning-OpenCV-3 directory and are "
         "running programs there.   NOTE: the list_of_stereo_pairs> must"
      << "\n    give the full path name to the left right images, in "
         "alternating"
      << "\n    lines: left image, right image, one path/filename per line, see"
      << "\n    stereoData/example_19-03_list.txt file, you can comment out "
         "lines"
      << "\n    there by starting them with #."
      << "\n"
      << "\nDefault Call (with parameters: board_w = 9, board_h = 6, list = "
         "../stereoData_19-03_list.txt):"
      << "\n" << argv[0] << "\n"
      << "\nManual call:"
      << "\n" << argv[0] << " [<board_w> <board_h> <path/list_of_stereo_pairs>]"
      << "\n\n PRESS ANY KEY TO STEP THROUGH RESULTS AT EACH STAGE."
      << "\n" << endl;
}

string concatFileName(int camNo, int curFrame)
{
    string fileName = "cam_" + std::to_string(camNo) + "_" + std::to_string(curFrame);
    return fileName;
}

string concatFilePath(string dataDir, string fileName)
{
  string filePath = "../" + dataDir + "/" + fileName + ".jpg";
  return filePath;
}

static void StereoCalib(int nImages, int nx, int ny,
                        string dataDir,
                        bool useUncalibrated) {
  bool displayCorners = false;
  bool showUndistorted = true;
  bool isVerticalStereo = false; // horiz or vert cams
  const int maxScale = 1;
  const float squareSize = 1.f;
  int nCam = 2;

  // actual square size
  int i, j, k, lr;
  int N = nx * ny;
  cv::Size board_sz = cv::Size(nx, ny);
  vector<string> imageNames[2];
  vector<cv::Point3f> boardModel;
  vector<vector<cv::Point3f> > objectPoints;
  vector<vector<cv::Point2f> > points[2];
  vector<cv::Point2f> corners[2];
  bool found[2] = {false, false};
  cv::Size imageSize;

  for (i = 0; i < ny; i++) {
    for (j = 0; j < nx; j++) {
      boardModel.push_back(cv::Point3f((float)(i * squareSize), (float)(j * squareSize), 0.f));
    }
  }

  for (k = 1; k <= nImages; k++) {
    for (lr = 0; lr < nCam; lr++) {
      string imgName = concatFileName(lr+1, k);
      string ymlName = imgName + ".yml";
      cv::FileStorage fs(ymlName, cv::FileStorage::READ);
      bool hasData = false;
      if (fs.isOpened()) {
        cv::Mat mcorners;
        fs[imgName] >> mcorners;
        cout << mcorners.size() << endl;
        if (mcorners.cols == 1 && mcorners.rows == N ) {
          mcorners = mcorners.reshape(2, N);
          corners[lr] = mcorners.clone();
          found[lr] = true;
          cout << corners[lr] << endl;
          hasData = true;
        }
      }
      string imgPath = concatFilePath(dataDir, imgName);
      cout << imgPath << endl;
      imageNames[lr].push_back(imgPath);
      cv::Mat img = cv::imread(imgPath, 0);
      imageSize = img.size();

      if (!hasData) {
        if (img.empty())
          break;

        // Find circle grids and centers therein:
        for (int s = 1; s <= maxScale; s++) {
          cv::Mat timg;
          img.convertTo(timg, -1, 4, 0);
          if (s > 1)
            resize(img, timg, cv::Size(), s, s, cv::INTER_CUBIC);
          // Just as example, this would be the call if you had circle calibration
          // boards ...
          //      found[lr] = cv::findCirclesGrid(timg, cv::Size(nx, ny),
          //      corners[lr],
          //                                      cv::CALIB_CB_ASYMMETRIC_GRID |
          //                                          cv::CALIB_CB_CLUSTERING);
          //...but we have chessboards in our images
          found[lr] = cv::findChessboardCorners(timg, board_sz, corners[lr]);
          cout << corners[lr].size() << endl;
          if (found[lr] || s == maxScale) {
            cv::Mat mcorners(corners[lr]);
            mcorners *= (1. / s);
            cv::FileStorage fs(ymlName, cv::FileStorage::WRITE);

            cout << mcorners.size() << endl;
            fs << imgName << mcorners;
            fs.release();
          }
          if (found[lr])
            break;
        }
      }
      if (displayCorners) {

        // draw chessboard corners works for circle grids too
        cv::drawChessboardCorners(img, cv::Size(nx, ny), corners[lr], found[lr]);
        cv::imshow("Corners", img);
        if ((cv::waitKey(0) & 255) == 27) // Allow ESC to quit
          exit(-1);
      }
      if (lr == 1 && found[0] && found[1]) {
        objectPoints.push_back(boardModel);
        points[0].push_back(corners[0]);
        points[1].push_back(corners[1]);
        cout << imageSize << endl;
      }
    }
  }
  // CALIBRATE THE STEREO CAMERAS
  cv::Mat M1 = cv::Mat::eye(3, 3, CV_64F);
  cv::Mat M2 = cv::Mat::eye(3, 3, CV_64F);
  cv::Mat D1, D2, R, T, E, F;
  cout << "\nRunning stereo calibration ...\n";
  cv::stereoCalibrate(
      objectPoints, points[0], points[1], M1, D1, M2, D2, imageSize, R, T, E, F,
      cv::CALIB_FIX_ASPECT_RATIO | cv::CALIB_ZERO_TANGENT_DIST |
          cv::CALIB_SAME_FOCAL_LENGTH,
      cv::TermCriteria(cv::TermCriteria::COUNT | cv::TermCriteria::EPS, 100,
                       1e-5));
  cout << "Done! Press any key to step through images, ESC to exit\n\n";
  cout << M1 << endl;
  // CALIBRATION QUALITY CHECK
  // because the output fundamental matrix implicitly
  // includes all the output information,
  // we can check the quality of calibration using the
  // epipolar geometry constraint: m2^t*F*m1=0
  vector<cv::Point3f> lines[2];
  double avgErr = 0;
  int nframes = (int)objectPoints.size();
  for (i = 0; i < nframes; i++) {
    vector<cv::Point2f> &pt0 = points[0][i];
    vector<cv::Point2f> &pt1 = points[1][i];
    cv::undistortPoints(pt0, pt0, M1, D1, cv::Mat(), M1);
    cv::undistortPoints(pt1, pt1, M2, D2, cv::Mat(), M2);
    cv::computeCorrespondEpilines(pt0, 1, F, lines[0]);
    cv::computeCorrespondEpilines(pt1, 2, F, lines[1]);

    for (j = 0; j < N; j++) {
      double err = fabs(pt0[j].x * lines[1][j].x + pt0[j].y * lines[1][j].y +
                        lines[1][j].z) +
                   fabs(pt1[j].x * lines[0][j].x + pt1[j].y * lines[0][j].y +
                        lines[0][j].z);
      avgErr += err;
    }
  }
  cout << "avg err = " << avgErr / (nframes * N) << endl;

  // COMPUTE AND DISPLAY RECTIFICATION
  //
  if (showUndistorted) {
    cv::Mat R1, R2, P1, P2, map11, map12, map21, map22;

    // IF BY CALIBRATED (BOUGUET'S METHOD)
    //
    if (!useUncalibrated) {
      stereoRectify(M1, D1, M2, D2, imageSize, R, T, R1, R2, P1, P2,
                    cv::noArray(), 0);
      isVerticalStereo = fabs(P2.at<double>(1, 3)) > fabs(P2.at<double>(0, 3));
      // Precompute maps for cvRemap()
      initUndistortRectifyMap(M1, D1, R1, P1, imageSize, CV_16SC2, map11,
                              map12);
      initUndistortRectifyMap(M2, D2, R2, P2, imageSize, CV_16SC2, map21,
                              map22);
    }

    // OR ELSE HARTLEY'S METHOD
    //
    else {

      // use intrinsic parameters of each camera, but
      // compute the rectification transformation directly
      // from the fundamental matrix
      vector<cv::Point2f> allpoints[2];
      for (i = 0; i < nframes; i++) {
        copy(points[0][i].begin(), points[0][i].end(),
             back_inserter(allpoints[0]));
        copy(points[1][i].begin(), points[1][i].end(),
             back_inserter(allpoints[1]));
      }
      cv::Mat F = findFundamentalMat(allpoints[0], allpoints[1], cv::FM_8POINT);
      cv::Mat H1, H2;
      cv::stereoRectifyUncalibrated(allpoints[0], allpoints[1], F, imageSize,
                                    H1, H2, 3);
      R1 = M1.inv() * H1 * M1;
      R2 = M2.inv() * H2 * M2;

      // Precompute map for cvRemap()
      //
      cv::initUndistortRectifyMap(M1, D1, R1, P1, imageSize, CV_16SC2, map11,
                                  map12);
      cv::initUndistortRectifyMap(M2, D2, R2, P2, imageSize, CV_16SC2, map21,
                                  map22);
    }

    // RECTIFY THE IMAGES AND FIND DISPARITY MAPS
    //
    cv::Mat pair;
    pair.create(imageSize.height, imageSize.width * 2, CV_8UC3);
    // Setup for finding stereo corrrespondences
    //
    cv::Ptr<cv::StereoSGBM> stereo = cv::StereoSGBM::create(
        -64, 128, 11, 100, 1000, 32, 0, 15, 1000, 16, cv::StereoSGBM::MODE_HH);

    for (i = 0; i < nframes; i++) {
      cv::Mat img1 = cv::imread(imageNames[0][i], 0);
      cv::Mat img2 = cv::imread(imageNames[1][i], 0);
      cv::Mat img1r, img2r, disp, vdisp;
      if (img1.empty() || img2.empty())
        continue;
      cv::remap(img1, img1r, map11, map12, cv::INTER_LINEAR);
      cv::remap(img2, img2r, map21, map22, cv::INTER_LINEAR);

      cv::Mat part = pair.colRange(0, imageSize.width);
      cvtColor(img1r, part, cv::COLOR_GRAY2BGR);
      part = pair.colRange(imageSize.width, imageSize.width * 2);
      cvtColor(img2r, part, cv::COLOR_GRAY2BGR);
      for (j = 0; j < imageSize.height; j += 16)
        cv::line(pair, cv::Point(0, j), cv::Point(imageSize.width * 2, j),
                  cv::Scalar(0, 255, 0));
      cv::imshow("rectified", pair);
      // Compute disparity
      // cv::Mat disparity;
      // cv::Ptr<cv::StereoMatcher> pStereo = cv::StereoSGBM::create(0,   // minimum disparity
      //                                                           256,  // maximum disparity
      //                                                           5);  // block size
      // pStereo->compute(img1r, img2r, disparity);
      // cv::imshow("depth", disparity);
      if ((cv::waitKey() & 255) == 27)
        break;
    }
  }
}

//
//Default Call (with parameters: board_w = 9, board_h = 6, list =
//  ../stereoData_19-03_list.txt):
//./example_19-03
//
//Manual call:
//./example_19-03 [<board_w> <board_h> <path/list_of_stereo_pairs>]
//
// Press any key to step through results, ESC to exit
//


int main(int argc, char **argv) {
  char cCurrentPath[FILENAME_MAX];
  if (!getcwd(cCurrentPath, sizeof(cCurrentPath)))
  {
    return errno;
  }

  int board_w = 9, board_h = 5;
  int nImages;
  string dataDir;
  if (argc == 5) {
    nImages = atoi(argv[1]);
    board_w = atoi(argv[2]);
    board_h = atoi(argv[3]);
    dataDir = argv[4];
    StereoCalib(nImages, board_w, board_h, dataDir, true);
  } else {
    help(argv);
  }
  return 0;
}