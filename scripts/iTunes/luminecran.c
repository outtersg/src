// cc -o luminecran luminecran.c -framework IOKit -framework ApplicationServices
// http://osxbook.com/book/bonus/chapter10/light/
// display-brightness.c

#include <stdio.h>
#include <IOKit/graphics/IOGraphicsLib.h>
#include <ApplicationServices/ApplicationServices.h>

#define PROGNAME "display-brightness"

void
usage(void)
{
  fprintf(stderr, "usage: %s <brightness>\n"
          "    where 0.0 <= brightness <= 1.0\n", PROGNAME);
  exit(1);
}

int
main(int argc, char **argv) 
{
  CGDisplayErr      dErr;
  io_service_t      service;
  CGDirectDisplayID targetDisplay;

  CFStringRef key = CFSTR(kIODisplayBrightnessKey);
  float brightness = HUGE_VALF;

  switch (argc) {
  case 1:
    break;

  case 2:
    brightness = strtof(argv[1], NULL);
    break;

  default:
    usage();
    break;
  }

  targetDisplay = CGMainDisplayID();
  service = CGDisplayIOServicePort(targetDisplay);

  if (brightness != HUGE_VALF) { // set the brightness, if requested
    dErr = IODisplaySetFloatParameter(service, kNilOptions, key, brightness);
  }

  // now get the brightness
  dErr = IODisplayGetFloatParameter(service, kNilOptions, key, &brightness);
  if (dErr != kIOReturnSuccess) {
    fprintf(stderr, "operation failed\n");
  } else {
    printf("brightness of main display is %f\n", brightness);
  }
  
  exit(dErr);
}
