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
#if defined(__sun) || defined(__sun__)
 #include <sys/processor.h>
#endif
#ifdef _HPUX_SOURCE
 #include <pthread.h>
 #include <sys/pstat.h>
 #define _have_cpu_clock
 #define _have_cpu_type
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

#ifdef _HPUX_SOURCE

/*
 * HP specific function to return the clock-speed of a specified CPU in MHz.
 */
int proc_get_mhz(int id) {
    struct pst_processor st;
    int result = 0;
    if( !(result = pstat_getprocessor(&st, sizeof(st), (size_t)1, id)) ) {

        /* Maybe the CPU id too high, so try for CPU 0, instead. */
        result = pstat_getprocessor(&st, sizeof(st), (size_t)1, 0);
    }

    if( result ) {
        return st.psp_iticksperclktick * sysconf(_SC_CLK_TCK) / 1000000;
    }

    /* Call failed - return 0 for unknown clock speed. */
    return 0;
}

/*
 * Depending on your version of HP-UX, you may or may not already have these
 * but we need them, so make sure that they are defined.
 */
#ifndef CPU_PA_RISC1_0
#define CPU_PA_RISC1_0      0x20B    /* HP PA-RISC1.0 */
#endif

#ifndef CPU_PA_RISC1_1
#define CPU_PA_RISC1_1      0x210    /* HP PA-RISC1.1 */
#endif

#ifndef CPU_PA_RISC1_2
#define CPU_PA_RISC1_2      0x211    /* HP PA-RISC1.2 */
#endif

#ifndef CPU_PA_RISC2_0
#define CPU_PA_RISC2_0      0x214    /* HP PA-RISC2.0 */
#endif

#ifndef CPU_PA_RISC_MAX
#define CPU_PA_RISC_MAX     0x2FF    /* Maximum for HP PA-RISC systems. */
#endif

#ifndef CPU_IA64_ARCHREV_0
#define CPU_IA64_ARCHREV_0  0x300    /* IA-64 archrev 0 */
#endif

const char *proc_get_type_name () {
    long cpuvers = sysconf(_SC_CPU_VERSION);

    switch(cpuvers) {
        case CPU_PA_RISC1_0:
            return "HP PA-RISC1.0";
        case CPU_PA_RISC1_1:
            return "HP PA-RISC1.1";
        case CPU_PA_RISC1_2:
            return "HP PA-RISC1.2";
        case CPU_PA_RISC2_0:
            return "HP PA-RISC2.0";
        case CPU_IA64_ARCHREV_0:
            return "IA-64 archrev 0";
        default:
            if( CPU_IS_PA_RISC(cpuvers) ) {
	        return "HP PA-RISC";
	    }
    }

    return "UNKNOWN HP-UX";
}

#endif /* _HPUX_SOURCE */

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
#ifdef _HPUX_SOURCE /* HP-UX */
    ret = pthread_num_processors_np();
#else               /*other unix - try sysconf*/
    ret = (int )sysconf(_SC_NPROCESSORS_ONLN);
#endif  /* HP-UX */
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
#endif /* not linux, not windows, not hpux */
#ifdef _HPUX_SOURCE
    /* Try to get the clock speed for processor 0 - assume all the same. */
    clock = proc_get_mhz(0);
#endif
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
#ifdef _HPUX_SOURCE
    value = proc_get_type_name();
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


