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

#define MAX_IDENT_SIZE 256
#if defined(_WIN32) || defined(WIN32) 
  #define _have_cpu_type
  #define _have_cpu_clock
  #define WINDOWS
#endif

#ifdef WINDOWS /* WINDOWS */
 #include <stdlib.h>
 #include <windows.h>                                  
 #include <winbase.h>
 #include <winreg.h>
#else                /* other (try unix) */
 #include <unistd.h>
 #include <sys/unistd.h>
#endif
#ifdef __sun__
 #include <sys/processor.h>
#endif


#ifdef WINDOWS
/* Registry Functions */

int GetSysInfoKey(char *key_name,char *output) {
	// Get values from registry, use REGEDIT to see how data is stored while sample is running
	int ret;
	HKEY hTestKey, hSubKey;
	DWORD dwRegType, dwBuffSize;
	 
	// Access using preferred 'Ex' functions
	if (RegOpenKeyEx(HKEY_LOCAL_MACHINE, "Hardware\\Description\\System\\CentralProcessor", 0, KEY_READ,  &hTestKey) == ERROR_SUCCESS) {
		if (RegOpenKey(hTestKey, "0",  &hSubKey) == ERROR_SUCCESS) {
			dwBuffSize = MAX_IDENT_SIZE;
			ret = RegQueryValueEx(hSubKey, key_name, NULL,  &dwRegType,  output,  &dwBuffSize);
			if (ret != ERROR_SUCCESS) {
				sprintf(output,"Failed to get Value for key : %d\n",GetLastError());
				return(1);
			}
			RegCloseKey(hSubKey);
		} else {
			sprintf(output,"Failed to open sub-key : %d\n",GetLastError());
			return(1);
		}		 
		RegCloseKey(hTestKey);
	}
	else 
	{
		sprintf(output,"Failed to open test key : %d\n",GetLastError());
		return(1);
	}
	return(0);
}

#endif /* WINDOWS */

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

#ifdef WINDOWS /* WINDOWS */                                  
   SYSTEM_INFO info;                                                         
                                                       
   GetSystemInfo(&info);                              
   ret = info.dwNumberOfProcessors;                  
#else               /*other (try *nix)*/
    ret = (int )sysconf(_SC_NPROCESSORS_ONLN);
#endif  /* WINDOWS */
    return ret;
}


MODULE = Sys::CPU		PACKAGE = Sys::CPU		

int
cpu_count()
CODE:
{
    int i = 0;
    i = get_cpu_count();
    if (i) {
	    ST(0) = sv_newmortal();
	    sv_setiv (ST(0), i);
    } else {
	    ST(0) = &PL_sv_undef;
    }   
}


int
cpu_clock()
CODE:
{
    int clock = 0;
    int retcode = 0;
#ifdef __linux__
    int value = proc_cpuinfo_clock();
    if (value) clock = value;
#endif
#ifdef WINDOWS
    char *clock_str = malloc(MAX_IDENT_SIZE); 
    /*!! untested !!*/
    retcode = GetSysInfoKey("~MHz",clock_str);
    if (retcode != 0) {
        clock = 0;
    } else {
        clock = atoi(clock_str);
    }     
#endif /* not linux, not windows */
#ifndef _have_cpu_clock
    processor_info_t info, *infop=&info;
    if ( processor_info(0, infop) == 0 && infop->pi_state == P_ONLINE) {
        if (clock < infop->pi_clock) {
            clock = infop->pi_clock;
        }
    }
#endif
    if (clock) {
	    ST(0) = sv_newmortal();
	    sv_setiv (ST(0), clock);
    } else {
	    ST(0) = &PL_sv_undef;
    }   
}

SV *
cpu_type()
CODE:
{
    char *value = malloc(MAX_IDENT_SIZE);
    int retcode = 0;
#ifdef __linux__
    value = proc_cpuinfo_field ("model name");
    if (!value) value = proc_cpuinfo_field ("machine");
#endif
#ifdef WINDOWS
    retcode = GetSysInfoKey("Identifier",value);
    if (retcode != 0) {
        value = NULL;
    }                                                                           
#endif 
#ifndef _have_cpu_type  /* not linux, not windows */
    processor_info_t info, *infop=&info;
    if (processor_info (0, infop)==0) {
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

