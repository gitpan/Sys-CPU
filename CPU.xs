#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sys/types.h>

/**************************************************************************************
* some of the code for the CPU information was copied and modilefied from             *
*  the source for Unix::Processors. All code contained herein in free to use and edit *
*  under the same licence as Perl itself.                                             *
*                                                                                     *
**************************************************************************************/

#if defined(_WIN32)  /* WINDOWS */
#include <stdlib.h>
#include <windows.h>                                  
#include <winbase.h>
#else                /* other (try unix) */
#include <unistd.h>
#include <sys/unistd.h>
#endif
#ifdef __sun__
#include <sys/processor.h>
#endif

/* the following few functions were shamlessly taken from UNIX::Processors *
 * to make this linux compatable. No linux machine to test on, so had to   *
 * use existing code                                                       */

#ifdef __linux__

#define _have_cpu_type
#define _have_cpu_clock

/* Return string from a field of /proc/cpuinfo, NULL if not found */
/* Comparison is case insensitive */
char *proc_cpuinfo_field (const char *field) {
    FILE *fp;
    static char line[1000];
    int len = strlen(field);
    char *result = NULL;
    if (NULL!=(fp = fopen ("/proc/cpuinfo", "r"))) {
	while (!feof(fp) && result==NULL) {
	    fgets (line, 990, fp);
	    if (0==strncasecmp (field, line, len)) {
		char *loc = strchr (line, ':');
		if (loc) {
		    result = loc+2;
		    loc = strchr (result, '\n');
		    if (loc) *loc = '\0';
		}
	    }
	}
	fclose(fp);
    }
    return (result);
}

/* Return clock frequency */
int proc_cpuinfo_clock (void) {
    char *value;
    value = proc_cpuinfo_field ("cpu MHz");
    if (value) return (atoi(value));
    value = proc_cpuinfo_field ("clock");
    if (value) return (atoi(value));
    value = proc_cpuinfo_field ("bogomips");
    if (value) return (atoi(value));
    return (0);
}

#endif

int get_cpu_count() {
    int ret;
    char buffer[255];
    char *p = buffer;

#if defined(_WIN32) /* WINDOWS */
/******************************************
*     p = getenv("NUMBER_OF_PROCESSORS"); *
*     if (p == NULL) {                    *
*         ret = 1;                        *
*     } else {                            *
*         ret = atoi(p);                  *
*     }                                   *
******************************************/                                  
   SYSTEM_INFO info;                                                         
                                                       
   GetSystemInfo(&info);                              
   ret = info.dwNumberOfProcessors;                  
#else               /*other (try *nix)*/
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


int
cpu_clock(cpu_num)
int cpu_num;
CODE:
{
    int clock = 0;
#ifdef __linux__
    int value = proc_cpuinfo_clock();
    if (value) clock = value;
#endif                        
#if defined(_WIN32) 
    /*!! untested !!*/
    /* http://mindcracker.com/mindcracker/c_cafe/winapi/cpu.asp */
    /*  Get from Registry at HKEY_LOCAL_MACHINE\HARDWARE\DESCRIPTION\SYSTEM\CentralProcessor */
    /*  using the key ~MHz */
    clock = 0;
    #define _have_cpu_clock
#endif
#ifndef _have_cpu_clock /* not linux, not windows */
    processor_info_t info, *infop=&info;
    --cpu_num;
    if ( processor_info(cpu_num, infop) == 0 && infop->pi_state == P_ONLINE) {
        if (clock < infop->pi_clock) {
            clock = infop->pi_clock;
        }
    }
#endif
    RETVAL = clock;
}
OUTPUT: RETVAL

SV *
cpu_type(cpu_num)
int cpu_num
CODE:
{
    char *value = NULL;
#ifdef __linux__
    --cpu_num;
	value = proc_cpuinfo_field ("model name");
	if (!value) value = proc_cpuinfo_field ("machine");
#endif
#if defined(_WIN32)
    --cpu_num;                                  
    SYSTEM_INFO info;                                
                                                                               
    GetSystemInfo(&info);                               
    RETVAL = info.dwProcessorType;
    #define _have_cpu_type
#endif
#ifndef _have_cpu_type /* not linux, not windows */
    processor_info_t info, *infop=&info;
    --cpu_num;
    if (processor_info (cpu_num, infop)==0) {
	value = infop->pi_processor_type;
    }
#endif
    if (value) {
	    ST(0) = sv_newmortal();
	    sv_setpv (ST(0), value);
    } else {
	    ST(0) = &PL_sv_undef;
    }
}

