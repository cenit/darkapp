//#define TRACK_OPTFLOW      //you must define this symbol before including <yolo_v2_class.hpp> if you want to enable those routines

#include <iostream>
#include <yolo_v2_class.hpp>
#include <darknet.h>

#ifdef TRACK_OPTFLOW
#ifndef OPENCV               // do not define this symbol manually, CMake will take care of exporting it if Darknet was built with OpenCV support!
#ifndef GPU                  // do not define this symbol manually, CMake will take care of exporting it if Darknet was built with GPU support!
#error "TRACK_OPTFLOW requires Darknet built with OPENCV and CUDA support"
#endif
#endif
#endif

int main(int argc, char* argv[])
{
  Detector detector("cfg_file", "weights_file");

  /* ... */

  return 0;
}
