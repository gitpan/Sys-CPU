#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#if defined(_WIN32)  /* WINDOWS */
#include <stdlib.h>
#else                /* other (try unix) */
#include <unistd.h>
#include <sys/unistd.h>
#endif

int get_cpu_count() {
    int ret;
    char buffer[255];
    char *p = buffer;

#if defined(_WIN32) /* WINDOWS */
    p = getenv("NUMBER_OF_PROCESSORS");
    if (p == NULL) {
        ret = 1;
    } else {
        ret = atoi(p);
    }
#else               /*other (try unix)*/
    ret = (int )sysconf(_SC_NPROCESSORS_ONLN);
#endif
    return ret;
}

MODULE = Sys::CPU		PACKAGE = Sys::CPU		

int
cpu_count()
    CODE:
      RETVAL = get_cpu_count();
    OUTPUT:
      RETVAL
