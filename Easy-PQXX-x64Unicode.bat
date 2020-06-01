REM Build and install pqxx library using CMake and source code files.
REM Version 0.0.3
:: ************************************************************************
:: This batch file builds and then installs the pqxx library (libpqxx), for
:: Microsoft Visual Studio on Windows. It should work for any version of
:: libpqxx after 7.0.0, but some features depend upon version 7.0.7 or
:: later. 
::
:: Usage: Use a programming editor (Visual Studio, Notepad++, etc.) to copy
:: this file to a top level directory from which the install will occur.
:: This should be a permanent directory if you intend to build and use the
:: Debug configuration, because debugging of source code using the copy
:: made here will step into the copy of the source code in this directory.
:: Example: Documents\libpqxx 
::
:: This directory should also contain the libpqxx-master or
:: libpqxx-<version> source file directory. (Not the top level but the
:: directory which has source files immediately thereunder.) If not already
:: there, then make it so. Rename with -<version> convention if used, and
:: make sure the PQXX_VERSION variable is configured here to match every
:: character after the first dash in libpqxx-. 
::
:: Using the programming editor, make any changes to the configuration
:: section of this file to tune to your requirements. Each variable is
:: documented and alternative values are provided with REM comment or are
:: uncommented as default. Since GitHub has a tendency to provide files
:: with Unix style linefeeds (instead of the anachronistic Windows CR/LF),
:: using your programming editor to both copy and edit this file can also
:: translate to the proper line terminations for a batch file on Windows.
::
:: No command line arguments should be supplied to this batch file by the
:: user. This file takes command line arguments from an internally
:: generated recursive call to itself with argument: FINAL_INSTALL_CALL
:: which will cause the file to skip from variable configuration directly
:: to the final installation section--and presumes that the (recursively
:: called) file has administrative privileges as needed to do the final
:: installation step, such as placing files in the C:\Program Files
:: directory. A short Visual Basic Script file will trigger this.
::
:: An option allows the addition of the pqxx.psd file to the Debug
:: directory if desired to allow debug linking while the source files are
:: not available or are out of sync.
:: ************************************************************************
@echo off
:: Preliminary settings ---------------------------------------------------
SETLOCAL EnableDelayedExpansion



::             ** Configure these options for your use **

:: Do not change sections bracketed by :: ------------------>> ::

:: Set VERBOSE to 1 to show verbose results in CMake commands and allow the
:: batch file to echo its steps, to debug. Warning: your screen will get
:: ugly. Set to 0 for less output, which will be much more readable. Will
:: default to 0 if not set.
SET VERBOSE=0

:: leave these lines in... VERBOSE block.... ------------------------->> ::
if not defined VERBOSE ( SET VERBOSE=0 )
if %VERBOSE% neq 0 ( @echo on )
:: <<---------------------------------------  .... End of VERBOSE block. ::


:: Set PAUSE_AT_END to pause at the end of batch file runs. This is needed
:: if you click on the batch file to run it. (This is the easiest way!) But
:: at the end the command window will close before you get a chance to read
:: the success or failure. Setting to 1 causes a pause to hit key before
:: end of the batch file. Default is on (1) if not defined here, off (0).
SET PAUSE_AT_END=1

:: Only referenced in this configuration section, PQXX_VERSION only matters
:: in the configuration section of this batch file. Set the version number
:: of the libpqxx being installed. This will be used as a suffix in
:: intermediate directories created in the install process as well as the
:: name of the input source file. (These intermediate directories are
:: normally kept, not deleted.) Optionally the libpqxx-<version> directory
:: used as input may not have a suffix of this version number, as
:: libpqxx-master (in which case enter master for the version here).
:: Otherwise the release copies all have a version number which must be
:: indicated, so that multiple versions may be maintained in this
:: directory. Set version to master, or rename libpqxx-master to
:: libpqxx-master-<version> and insert a version here. Must include
:: master-<version> if you renamed master branch file. Check
:: SOURCE_DIRECTORY setting if you do not name the source directory with
:: version, but this may still apply to intermediate file directories.
REM SET PQXX_VERSION=7.1.2
REM SET PQXX_VERSION=7.1.1
SET PQXX_VERSION=master

:: The POSTGRES_VERSION is a required variable. It must be set to determine
:: which DLL files are copied for use in the post build event in the
:: Property Pages files. This is also used to construct the location of the
:: PostgreSQL database installation.
SET POSTGRES_VERSION=12
REM SET POSTGRES_VERSION=11
REM SET POSTGRES_VERSION=10


:: leave these lines in... PROGRAMFILES block.... -------------------->> ::
:: DON'T MODIFY THIS ...
:: Here we are finding if we are on a 32 bit or 64 bit operating system.
:: This is distinct from the question of what you want to compile for, but
:: the default will be to use the same as your operating system.

:: NOTE PROGRAMFILES_nn_BIT value will have quotes.
if defined programfiles(x86) (
    SET PROGRAMFILES_32_BIT="%PROGRAMFILES(X86)%"
    SET PROGRAMFILES_64_BIT="%PROGRAMFILES%"
    SET OS_64_BIT=1
) ELSE (
    SET PROGRAMFILES_32_BIT="%PROGRAMFILES%"
    SET PROGRAMFILES_64_BIT="%PROGRAMFILES%"
    SET OS_64_BIT=0
)
echo PROGRAMFILES_32_BIT=%PROGRAMFILES_32_BIT%
echo PROGRAMFILES_64_BIT=%PROGRAMFILES_64_BIT%
:: <<----------------------------------  .... End of PROGRAMFILES block. ::




:: PLATFORM (required). Platform (architecture) used for target of
:: compilation (32/64 bit etc.), must be exactly Win32 or x64. This must be
:: set to control search of for programming information, as well to select
:: some input directories. Uncomment one or the other here by removing the
:: "REM" word. Default, next, is to use the same as your operating system.
REM SET PLATFORM=x64
REM SET PLATFORM=Win32
:: ------------------------------------------------------------------->> ::
if not defined PLATFORM (
    if %OS_64_BIT% neq 0 (SET PLATFORM=x64) else (SET PLATFORM=Win32)
)
:: <<------------------------------------------------------------------- ::

:: CHARSET must be exactly "Unicode" or "MultiByte" or else will not work
:: correctly, or leave without setting for the default MultiByte. NOTE this
:: must be used in each case of a --build, even if re-selecting the
:: --target project. This is used with the direct to tool flag: --
:: /property:CharacterSet=%CHARSET% for command line CMake --build runs.

:: Default is MultiByte. But for example linking with wxWidgets, one may
:: need to use a Unicode compiled library. Exactly MultiByte or Unicode .

REM SET CHARSET=MultiByte
SET CHARSET=Unicode

:: ALSO Note that the VS IDE solution is set for MultiByte, regardless of
:: this setting. If you use Unicode and intend to compile using the IDE,
:: you must change pqxx, runner, (and unit_runner if included) projects to
:: Unicode character set, from the property pages of those projects.
:: Building the test applications will recompile the library itself--if
:: this is not done.

:: ------------------------------------------------------------------->> ::
if not defined CHARSET set CHARSET=MultiByte
if %CHARSET% equ MultiByte (set CHARSUFIX=) else (set CHARSUFIX=%CHARSET%)
:: <<------------------------------------------------------------------- ::

:: The SUFFIX may be used to distinguish builds and libraries. This will be
:: used in intermediate file locations. Use the leading '_' if you want the
:: suffix to be set off with that character each place used. Here we are
:: assuming a 64 bit build, and no need to distinguish otherwise. Set blank
:: for no suffix (and no underscore). The =_%PLATFORM% becomes _x64 or
:: _Win32. If not MultiByte character set (default) then appends that.
SET SUFFIX=_%PLATFORM%%CHARSUFIX%
REM SET SUFFIX=
REM SET SUFFIX=_test
:: ------------------------------------------------------------------->> ::
if not defined SUFFIX SET SUFFIX=
:: <<------------------------------------------------------------------- ::



:: File/directory location settings ---------------------------------------


:: The POSTGRES_LOCATION must be set. It can be derived from the
:: POSTGRES_VERSION variable and whether the platform is 64 bit. If this
:: turns out to be wrong, set it yourself. DLL files will be copied from
:: this location to build applications. Note the automation below has
:: problems when the directory includes (x86) because the parenthesis is
:: also a batch language feature, so done in quotes, then removed.
:: ------------------------------------------------------------------->> ::
if "%PLATFORM%" equ "x64" (
    SET PROGRAMFILES_CHOSEN=%PROGRAMFILES_64_BIT%
) else (
    SET PROGRAMFILES_CHOSEN=%PROGRAMFILES_32_BIT%
)
call :DEQUOTE %PROGRAMFILES_CHOSEN%
SET PROGRAMFILES_CHOSEN=%_ret%
SET POSTGRES_LOCATION=%PROGRAMFILES_CHOSEN%\PostgreSQL\%POSTGRES_VERSION%
:: <<------------------------------------------------------------------- ::

:: Uncomment and edit this line if above fails to provide correct value:
REM SET POSTGRES_LOCATION=C:\Program Files\PostgreSQL\12


:: ------------------------------------------------------------------->> ::
IF EXIST "%POSTGRES_LOCATION%" (
    ECHO "PostgreSQL files located at: %POSTGRES_LOCATION%"
) ELSE (
    ECHO "%POSTGRES_LOCATION% does not exist."
    cmake -E false
    goto :error 
)
:: Now setting the list of DLL files from the PostgreSQL, according to the
:: version of Postgres. NOTE includes the main library, libpq.lib as well!
:: ?????????? Need to finish versions 10 and 11!!!!!!!!!!!!!!!!
:: You may need to modify the list below if you find your system requires a
:: DLL file not listed here, in appropriate line. DO NOT ADD COMMENTS!
if %POSTGRES_VERSION% equ 12 (
    set POSTGRES_DLLS=libpq.dll libcrypto-1_1-x64.dll libiconv-2.dll libintl-8.dll libssl-1_1-x64.dll
) else if %POSTGRES_VERSION% equ 11 (
    set POSTGRES_DLLS=libpq.dll libcrypto-1_1-x64.dll libiconv-2.dll libintl-8.dll libssl-1_1-x64.dll
) else if %POSTGRES_VERSION% equ 10 (
    if "%PLATFORM%" equ "x64" (
        set POSTGRES_DLLS=libpq.dll libcrypto-1_1-x64.dll libiconv-2.dll libintl-8.dll libssl-1_1-x64.dll
	) else (
        set POSTGRES_DLLS=libpq.dll libcrypto-1_1.dll libiconv-2.dll libintl-8.dll libssl-1_1.dll
	)
) else (
    echo Don't have list of DLLs for PostgreSQL version %POSTGRES_VERSION%.
    cmake -E false
    goto :error
)
:: <<------------------------------------------------------------------- ::

:: Input source: The SOURCE_DIRECTORY is the location of the source and
:: CMake files for the build. The subdirectory with this name should have
:: the source and CMake files immediately thereunder. Typically specified
:: relative to directory in which this batch file is run. If the actual
:: source files start 2 levels deep, then edit to reflect the nested
:: structure. Use (and rename to) the -<version> form to keep multiple
:: versions in the same directory (matching the PQXX_VERSION variable
:: above). Recommend placing the libpqxx-<version> directory with source
:: files directly under the top level directory with this batch file so the
:: following evaluates to the correct location for CMake files.
SET SOURCE_DIRECTORY=libpqxx-%PQXX_VERSION%

:: The INSTALL_SUBDIRECTORY is the name of a **subdirectory** tree of both
:: the intermediate and final install directories into which this project
:: is installed. This subdirectory will be created if necessary. If not
:: defined, this defaults to 'libpqxx'. It is always a relative
:: subdirectory. Essential to the main operational portion of this batch
:: file.
SET INSTALL_SUBDIRECTORY=libpqxx\%PQXX_VERSION%%SUFFIX%

:: The FINAL_INSTALL_DIRECTORY is a final installation directory for the
:: library. This is the location you expect to use for your library
:: settings in applications that you create. This directory can be in a
:: privileged location, such as C:\Program Files. Use %programfiles% to let
:: the operating system variable supply the correct location for Program
:: Files, which is the location of 64 bit programs on a 64 bit Windows
:: operating system.

:: NOTE this directory must exist, or an attempt will be made to create it
:: without administrator permissions. If that fails, the batch fails.
:: Comment the first and enable the second line to only "install" in the
:: build directory with version and suffix identifiers. Leave undefined to
:: skip final installation completely. Note PROGRAMFILES_CHOSEN is a
:: computed version of the C:\Program Files or the (x86) version directory
:: according to platform. This will cause the batch file to ask for
:: administrative privileges.
SET FINAL_INSTALL_DIRECTORY=%PROGRAMFILES_CHOSEN%
REM SET FINAL_INSTALL_DIRECTORY=final_install


REM Working directories -- Leave these alone ------------------------------
REM                        Unless you really want them different!

:: Work binary: The WORK_BUILD is a relative directory for CMake build
:: configuration and a Visual Studio solution file. This intermediate
:: directory will be created if missing, and will contain the intermediate
:: compiling steps, including a Visual Studio solution file filled with
:: multiple projects that build the library, test the library, and can
:: construct an "INSTALL" directory or "PACKAGE" gzip of the library.
:: Various CMake files will also be kept there, allowing a true "make" file
:: character if the process is run again, only applying to changes.
SET WORK_BUILD=build_%PQXX_VERSION%%SUFFIX%

:: Work Install: The WORK_INSTALL is the relative directory for running the
:: original CMake "install" process. This puts the generated output for
:: each configuration (Debug, Release) into a standardized arrangement.(We
:: wish to rearrange that slightly in the next step.)
SET WORK_INSTALL=work_%PQXX_VERSION%%SUFFIX%

:: The LOCAL_INSTALL is reformatted to include everything that will go into
:: a "FINAL_INSTALL" location, but assembled here with several differences
:: from the normal CMake version. First the Debug and Release copies of the
:: library are broken out. And property pages are added--which could be
:: used from this directory without a final installation, or which will
:: also work in the final location. A 'bin' directory is also added to
:: contain the external library and DLL files from PostgreSQL so this
:: library is not dependent upon the PostgreSQL installation after this
:: step is completed.
SET LOCAL_INSTALL=install



REM Various settings  -----------------------------------------------------
REM                   Set these how you would like them.!

:: Set Generator suitable for CMake -- specific to Visual Studio. Note that
:: Visual Studio 15 2017 is the first to support the C++ 17 required by
:: pqxx version 7, so earlier generations are not included.

:: https://cmake.org/cmake/help/latest/generator/Visual%20Studio%2016%202019.html
:: https://cmake.org/cmake/help/latest/generator/Visual%20Studio%2015%202017.html
::
:: Leave undefined to let CMake choose the generator (generally the latest)
:: version on your machine, presuming your CMake itself is up to date.

REM SET GENERATOR=Visual Studio 16 2019
REM SET GENERATOR=Visual Studio 15 2017


:: NOTE on PSQLROOT and PSQLOC variables. Use only one, preferably PSQLROOT
:: and that must match the location used in POSTGRES_LOCATION and the
:: POSTGRES_VERSION number. (Thus commonly just set one of them to
:: %POSTGRES_LOCATION%.)

:: The build computer must have at least one installation of PostgreSQL. If
:: the build computer has multiple installations of PostgreSQL, then CMake
:: will sometimes find the wrong copy, and it needs to be specified here.
:: For PSQLROOT to work, the minimum release version of pqxx is 7.0.7.

:: PSQLROOT sets flag in CMake to tell where the PostgreSQL is located,
:: which we arleady set to POSTGRES_LOCATION variable. Suggest using that,
:: even if you only have one installation, since it will verify the
:: location we copy DLL files and the like in this batch file. Using the
:: (x86) library means you have to set PLATFORM=Win32 above. Leave
:: undefined if you only have one installation of PostgreSQL and CMake will
:: find it. (Of course match the PLATFORM to that installation)
REM SET PSQLROOT=C:\Program Files\PostgreSQL\12
REM SET PSQLROOT=C:\Program Files\PostgreSQL\11
REM SET PSQLROOT=C:\Program Files\PostgreSQL\10
REM SET PSQLROOT=C:\Program Files (x86)\PostgreSQL\10
SET PSQLROOT=%POSTGRES_LOCATION%



:: Define PSQLOC to establish the directory for PostgreSQL "the hard way."
:: Don't use the PSQLROOT variable if using this one. This triggers three
:: defines: PostgreSQL_LIBRARY, PostgreSQL_INCLUDE_DIR, and
:: PostgreSQL_TYPE_INCLUDE_DIR, so that CMake searching for PostgreSQL is
:: essentially overruled. Typically this would not be used unless CMake was
:: having a difficult time.
REM SET PSQLOC=%POSTGRES_LOCATION%


:: Set cores to number of CPU cores on your machine, or 1 to disable. Set 8 
:: cores only shaves from 5' 20" to 4' compile time on an older computer.
SET CORES=8

:: Set this variable if you have a 64 bit operating system. It will shorten
:: the compile time. Otherwise set value to 0. Value must be 1 or 0. The 0
:: setting lets CMake use default setting for host tool selection, while 1
:: requests that CMake utilize 64 bit tools. (Does not determine compiled
:: output architecture. CMake usually chooses the best for your system.)
REM SET USE_64_BIT_HOST=1
REM SET USE_64_BIT_HOST=0


:: BUILD_DEBUG and BUILD_RELEASE. Select building of Release and Debug
:: compiles. Set at least ONE! Use 1 to enable compiling of that
:: configuration, or else 0 to disable. Building only Release means you
:: don't have to track the source code with the library, but disables any
:: ability to step into the source code during debugging of the
:: applications built with pqxx.lib. MUST SET AT LEAST ONE! I am not sure,
:: but I think one might have to match the app compile to the library
:: configuration.
SET BUILD_DEBUG=1
SET BUILD_RELEASE=1

:: Turn on to have the pqxx.pdb file installed with the Debug library, 
:: only applies if both BUILD_DEBUG=1 and BUILD_RELEASE=1 is set above,
:: so that the debug library is in a special Debug subdirectory of lib. 
:: Some users may find this useful. Disabled by default. Set to 1 to use.
SET INSTALL_PDB=0


:: Turn FORCE_FINAL_INSTALL_AS_ADMIN on (1) to force the run as
:: administrator for final installation, even if not needed according to
:: testing of privileged final directory. Use this to circumvent the test
:: procedures for example if a bug is found and you know the final install
:: directory requires administrative privileges.
SET FORCE_FINAL_INSTALL_AS_ADMIN=0

:: ************************************************************************
:: ************************************************************************
:: ************************************************************************
:: ***                      Operations Section                          ***
:: *** This section implements the build using the configuration.       ***
:: ************************************************************************
:: ************************************************************************
:: ************************************************************************

:: Note that a technique with command line arguments and a special
:: auxiliary method acquiring admin privileges is used for the last step.
:: ANY command line argument at all presumes that these privileges have
:: been acquired, and the special recursive call will not recur (avoiding
:: infinite looping). The acquiring of privileges causes a re-run of this
:: batch file with the privileges. The Configuration section above is run
:: each pass to give the configuration variables their values in the local
:: task.



echo **********************************************************************
echo * STEP 0: Flag processing, adjusts or configures variables           *
echo **********************************************************************

:: Flow control--check if called recursively (with argument) for final
:: install:

:: Doc for inside next if: Got here through recursive call from original
:: batch file. Since called with system login, wrong directory, fix by
:: using the path of the batch file name itself: Use the batch file path to
:: select the path, which would have been lost during the recursive call as
:: administrator. See https://ss64.com/nt/pushd.html re pushd "%~dp0"
:: Continue with argument re-initialization...

if NOT "%~1"=="" pushd "%~dp0"


:: Flags that (may) appear in all CMake commands...

if not defined VERBOSE (
    SET VERBOSE=0
)
if %VERBOSE% neq 0 (
    @echo on
)
:: For use in CMake
if %VERBOSE% neq 0 (
    set VERBOSE_FLG=--verbose
) else (
    set VERBOSE_FLG=
)

:: For use in Robocopy or xcopy
if %VERBOSE% neq 0 (
    set VERBOSE_VFLG=/v
) else (
    set VERBOSE_VFLG=
)



if not defined PAUSE_AT_END (
    set PAUSE_AT_END=1
)

if not defined CORES (
    set CORES=0
)
if %CORES% neq 0 (
    set CORES_FLG=-j %CORES%
) else (
    set CORES_FLG=
)

:: Recursive call parameters (as administrator) requires an argument, even
:: if accidentally not provided below. Or else h**l breaks loose!
set params=DUMMY


:: Flags that appear on the initial construction CMake command...

:: Cmake host=x86 or host=x64, select 32 or 64 bit tools (not compile
:: target). Note that this flag is used in the construction of the VS
:: solution, and will have its effect later in the build activity.
if not defined USE_64_BIT_HOST (
    set USE_64_BIT_HOST=0
)
:: Either choose 64 bit tools, or leave to default of CMake.
if %USE_64_BIT_HOST% neq 0 (
    set HOST_FLG=-T "host=x64"
) else (
    set HOST_FLG=
)

if defined GENERATOR (
    set GENERATOR_FLG=-G "%GENERATOR%"
) else (
    set GENERATOR_FLG=
)

:: Here choosing 32 or 64 bit target compile.
if defined PLATFORM (
    set PLATFORM_FLG=-A "%PLATFORM%"
) else (
    set PLATFORM_FLG=
)

if defined PSQLROOT (
    set PSQLROOT_FLG=-DPostgreSQL_ROOT="%PSQLROOT%"
) else (
    set PSQLROOT_FLG=
)

:: Selecting input library "the hard way", all these flags need to be set:
if defined PSQLOC (
    set PSQLOC_FLGS=-DPostgreSQL_LIBRARY="%PSQLOC%\lib\libpq.lib" -DPostgreSQL_INCLUDE_DIR="%PSQLOC%\include" -DPostgreSQL_TYPE_INCLUDE_DIR="%PSQLOC%\include"
)else (
    set PSQLOC_FLGS=
)

:: Flags that appear on the build or install CMake command...

if not defined BUILD_DEBUG (
    set BUILD_DEBUG=0
)
if not defined BUILD_RELEASE (
    set BUILD_RELEASE=0
)

:: Setting build type for CMake project to Release only if doing Release
:: only, otherwise Debug for either both or just Debug.
SET CMAKE_BUILD_TYPE=Release
if BUILD_DEBUG neq 0 (SET CMAKE_BUILD_TYPE=Debug)


if not defined INSTALL_SUBDIRECTORY (
    set INSTALL_SUBDIRECTORY=libpqxx
)
if "%INSTALL_SUBDIRECTORY%" equ "" (
    echo INSTALL_SUBDIRECTORY must be defined as a non-empty string.
    echo for example to place in \Program Files directory, the install
    echo must be placed in a subdirectory as in C:\Program Files\libpqxx .
    cmake -E false
    goto :error
)

:: Regarding usage of and (%BUILD_RELEASE% equ 0) NOTE AND is for binary 
:: variables not logic. Construct BUILD_DEBUG==0 and BUILD_RELEASE==0.
echo Build flags: BUILD_DEBUG=%BUILD_DEBUG%, BUILD_RELEASE=%BUILD_RELEASE%
if %BUILD_DEBUG% equ 0 (
    if %BUILD_RELEASE% equ 0 (
        echo Both BUILD_DEBUG and BUILD_RELEASE cannot be left undefined or 0.
        cmake -E false
        goto :error
    )
)

:: Note this is a "pass through" flag direct to toolset.
if defined CHARSET (
    set CHARSET_FLG=/property:CharacterSet=%CHARSET%
) else (
    set CHARSET_FLG=
)

:: NOTE that this '--' flag on CMake command line makes all following flags
:: passed to tool. Enable if any of those flags are non-empty. Amend the if
:: condition if more "pass through" flags are defined.
if defined CHARSET (
    set PASS_OPTIONS_FLG=--
) else (
    set PASS_OPTIONS_FLG=
)


if not defined INSTALL_PDB (
    set INSTALL_PDB=0
)

if not defined FORCE_FINAL_INSTALL_AS_ADMIN (
    set FORCE_FINAL_INSTALL_AS_ADMIN=0
)


echo **********************************************************************
echo * STEP 0.5: Batch file control switching.                            *
echo **********************************************************************


:: Logic flow control of this batch file: This batch file may be called
:: recursively with an argument which selects the final install operation.
:: DO NOT continue with normal operations in any case if any argument is
:: present. This recursive call will occur with administrative privileges.  

if NOT "%~1"=="" (
    echo BATCH FILE CALLED with argument: %~1
)

if "%~1"=="FINAL_INSTALL_CALL" goto :final_install_only
:: if "%~1"=="CMAKE_INSTALL" goto :cmake_install_only
:: if "%~1"=="COPY_INSTALL" goto :copy_install_only
if NOT "%~1"=="" (
    echo The recursive command line arguments must be one of:
    echo FINAL_INSTALL_CALL.
    cmake -E false
    goto :error
)



::   * Build occurs in three steps. (Once variables are initialized.)     *
echo **********************************************************************
echo * STEP 1: Creation of Visual Studio solution and build files.        *
echo **********************************************************************


:: Actual  start of processing !

if "%GENERATOR%"=="" (set PRT_G=[NONE]) else (set PRT_G=%GENERATOR%)
if "%CHARSET%"=="" (set PRT_C=[NONE]) else (set PRT_C=%CHARSET%)
echo Start Generator: %PRT_G%, char %PRT_C% build, cores: %CORES% >> build_time_log.txt
echo Start build: %time% >> build_time_log.txt



:: This batch file can be started 'cold' with no settings, but must be in
:: the property directory relative to the directories specified.

:: This step assembles a Visual Studio solution with several projects. It
:: does not 'build' those projects yet, only the project files are created.
:: However several settings are established. Also the target for the
:: "INSTALL" project will be changed to a temporary directory in case the
:: user starts that process from the Visual Studio IDE.

:: This cmake step constructs the Visual Studio solution, without compiling
:: projects:
cmake %VERBOSE_FLG% -S %SOURCE_DIRECTORY% -B "%WORK_BUILD%" %GENERATOR_FLG% %PLATFORM_FLG% %HOST_FLG% %PSQLROOT_FLG% %PSQLOC_FLGS% -DCMAKE_BUILD_TYPE=%CMAKE_BUILD_TYPE% -DCMAKE_INSTALL_PREFIX="%WORK_INSTALL%\temporary"


if %errorlevel% neq 0 goto :error
:: Note that the IDE opens as Debug configuration no matter what. Note that
:: the IDE projects are configured with MultiByte character set, no matter
:: which setting was used for build operations by this batch file. However
:: the project will be Win32 or x64 according to the initial construction.


echo **********************************************************************
echo * STEP 2: Build of Visual Studio solution build files.               *
echo **********************************************************************


:: ************************************************************************
:: Note this will not activate the "INSTALL" or "PACKAGE" steps that create
:: the final install output. This is the actual "build" of the library, in
:: Debug or Release or both as selected.
:: ************************************************************************


:: Usage: cmake --build <dir> [options] [-- [native-options]]
:: Options:
::   <dir>          = Project binary directory to be built.
::   --parallel [<jobs>], -j [<jobs>]
::                  = Build in parallel using the given number of jobs.
::                    If <jobs> is omitted the native build tool's
::                    default number is used.
::                    The CMAKE_BUILD_PARALLEL_LEVEL environment variable
::                    specifies a default parallel level when this option
::                    is not given.
::   --target <tgt>..., -t <tgt>...
::                  = Build <tgt> instead of default targets.
::   --config <cfg> = For multi-configuration tools, choose <cfg>.
::   --clean-first  = Build target 'clean' first, then build.
::                    (To clean only, use --target 'clean'.)
::   --verbose, -v  = Enable verbose output - if supported - including
::                    the build commands to be executed.
::   --             = Pass remaining options to the native tool.
::     (On pass options):
::     https://docs.microsoft.com/en-us/visualstudio/msbuild/msbuild-command-line-reference?view=vs-2019       

::     NOTE that -j parameter more than 1 allows for faster compiling. Set
::     no higher than number of cores on your computer. Note that addition
::     of -- /p:CharacterSet=Unicode does change the compiled library from
::     _MBCS to UNICODE, which can be observed in the CL command line used
::     (as shown by --verbose) in compile, but does not change the Visual
::     Studio solution file. To compile in the IDE, that will have to be
::     set manually.

::     Keeps prior work for the most part (like a makefile), can specify
::     --clean-first to contradict that.

if %BUILD_RELEASE% neq 0 (
    cmake --build %WORK_BUILD% %VERBOSE_FLG% --config Release %CORES_FLG% %PASS_OPTIONS_FLG% %CHARSET_FLG%
    if !errorlevel! neq 0 goto :error
)

if %BUILD_DEBUG% neq 0 (
    cmake --build %WORK_BUILD% %VERBOSE_FLG% --config Debug   %CORES_FLG% %PASS_OPTIONS_FLG% %CHARSET_FLG%
    if !errorlevel! neq 0 goto :error
)


echo **********************************************************************
echo *          STEP 3: Creation of local copy of install library files.  *
echo *          Exception is use with administrative privileges.          *
echo *          Note this assembles library, include, and help files.     *
echo **********************************************************************
echo:
echo **********************************************************************
echo *          STEP 3a: Direct use of CMake to create install files.     *
echo **********************************************************************
:: Direct CMake --install method:
:: Usage: cmake --install <dir> [options]
:: Options:
::   <dir>              = Project binary directory to install.
::   --config <cfg>     = For multi-configuration tools, choose <cfg>.
::   --component <comp> = Component-based install. Only install <comp>.
::   --prefix <prefix>  = The installation prefix CMAKE_INSTALL_PREFIX.
::   --strip            = Performing install/strip.
::   -v --verbose       = Enable verbose output.



:: Additionally we must copy the .pdb file if requested...




if BUILD_DEBUG neq 0 (
    cmake --install %WORK_BUILD% %VERBOSE_FLG% --config Debug   --strip --prefix "%WORK_INSTALL%/%INSTALL_SUBDIRECTORY%/Debug"
    if !errorlevel! neq 0 goto :error
)
if BUILD_RELEASE neq 0 (
    cmake --install %WORK_BUILD% %VERBOSE_FLG% --config Release --strip --prefix "%WORK_INSTALL%/%INSTALL_SUBDIRECTORY%/Release"
    if !errorlevel! neq 0 goto :error
)

echo **********************************************************************
echo *          STEP 3b: Use xcopy to copy pdb file if requested          *
echo **********************************************************************
if %BUILD_DEBUG% neq 0 (
    :: Copy pdb if requested
    if %INSTALL_PDB% neq 0 (
        xcopy "%WORK_BUILD%\src\Debug\*.pdb" "%WORK_INSTALL%/%INSTALL_SUBDIRECTORY%/Debug/lib"  /d /k /y /i
        if !errorlevel! neq 0 goto :error
    )
)

echo **********************************************************************
echo *          STEP 4: Assemble local install library files              *
echo **********************************************************************
:: Must copy include, lib, and share subdirectories. Also a new 'bin'
:: subdirectory will contain files from PostgreSQL, which are referred to
:: in the property pages.

:: Note either debug or release is defined. If debug use that for include
:: and share subdirectories. The lib subdirectory is built individually for
:: each of Debug and Release configurations with respective subdirectories
:: in the lib directory.
if %BUILD_DEBUG% neq 0 (
    SET COMMON_SOURCE=%WORK_INSTALL%/%INSTALL_SUBDIRECTORY%/Debug
) else (
    SET COMMON_SOURCE=%WORK_INSTALL%/%INSTALL_SUBDIRECTORY%/Release
)

xcopy "%COMMON_SOURCE%/include" "%LOCAL_INSTALL%/%INSTALL_SUBDIRECTORY%/include"  /d /k /y /i /s
if %errorlevel% neq 0 goto :error
xcopy "%COMMON_SOURCE%/share" "%LOCAL_INSTALL%/%INSTALL_SUBDIRECTORY%/share"  /d /k /y /i /s
if %errorlevel% neq 0 goto :error

if %BUILD_DEBUG% neq 0 (
    robocopy "%WORK_INSTALL%/%INSTALL_SUBDIRECTORY%/Debug/lib" "%LOCAL_INSTALL%/%INSTALL_SUBDIRECTORY%/lib/Debug" *.lib *.pdb /purge /r:0
    if !errorlevel! gtr 1 goto :error
)
if %BUILD_RELEASE% neq 0 (
    robocopy "%WORK_INSTALL%/%INSTALL_SUBDIRECTORY%/Release/lib" "%LOCAL_INSTALL%/%INSTALL_SUBDIRECTORY%/lib/Release" *.lib /purge /r:0
    if !errorlevel! gtr 1 goto :error
)


:: Copy specified list of library and DLL files to newly created bin
:: subdirectory of the install.
robocopy %VERBOSE_VFLG% "%POSTGRES_LOCATION%/lib" "%LOCAL_INSTALL%/%INSTALL_SUBDIRECTORY%/bin" libpq.lib /r:0
robocopy %VERBOSE_VFLG% "%POSTGRES_LOCATION%/bin" "%LOCAL_INSTALL%/%INSTALL_SUBDIRECTORY%/bin" %POSTGRES_DLLS% /r:0
echo The bin directory copy, robocopy return value %errorlevel%.
if %errorlevel% gtr 8 goto :error



call :generatePropertyPage 1 1 "%LOCAL_INSTALL%/%INSTALL_SUBDIRECTORY%\libpqxx_ALL.props"
if %errorlevel% neq 0 gogo :error
call :generatePropertyPage 1 0 "%LOCAL_INSTALL%/%INSTALL_SUBDIRECTORY%\libpqxx.props"
if %errorlevel% neq 0 gogo :error
call :generatePropertyPage 0 1 "%LOCAL_INSTALL%/%INSTALL_SUBDIRECTORY%\libpqxx_DLL.props"
if %errorlevel% neq 0 gogo :error

:: --------------------------------------------------------------------- ::
:: Batch logic: If got here by recursive call with arguments, this was all
:: that was run, now pause and exit.
if NOT "%~1"=="" goto :exiting
:: --------------------------------------------------------------------- ::

echo **********************************************************************
echo *          STEP 5: Copy to final install library files.              *
echo *          Note this is what you link applications against.          *
echo **********************************************************************


::     ********************************************************************
::     **** Below this point, requires administrator privileges,       ****
::     **** if that is required by the FINAL_INSTALL_DIRECTORY.        ****
::     ********************************************************************

if not defined FINAL_INSTALL_DIRECTORY goto :exiting

:: If requested, skip all testing of requirement for administrative
:: privileges requirements, and just do the install as administrator.
if %FORCE_FINAL_INSTALL_AS_ADMIN% neq 0 (
    echo Forcing final install call as Admin.
    set params=FINAL_INSTALL_CALL
    goto :CallAsAdministrator
)

:: First check if the directory (including subdirectory) exists. If it does
:: not exist, create it. (This will not occur in program files directory.)
:: Then after creating directory, will test if privileges to write.
:: NOTE the FINAL_INSTALL_DIRECTORY may contain parenthesis confounding
:: batch.
set HAS_FINAL_DIRECTORY=0
if exist "%FINAL_INSTALL_DIRECTORY%\" (
    echo "Final install directory exists: %FINAL_INSTALL_DIRECTORY%"
) else (
    echo "%FINAL_INSTALL_DIRECTORY%\ does not exist"
    set HAS_FINAL_DIRECTORY=1
    md "%FINAL_INSTALL_DIRECTORY%"
    echo "Created: %FINAL_INSTALL_DIRECTORY% with errorlevel: !errorlevel!"
    if !errorlevel! neq 0 goto :error
)

if not exist "%FINAL_INSTALL_DIRECTORY%\" (
    echo "After creating final directory: %FINAL_INSTALL_DIRECTORY%"
    echo the directory does not exist.
    cmake -E false
    goto :error
)

:: Test that we have privileges to write to the output folder: Method taken
:: from:
:: https://stackoverflow.com/questions/7272850/best-way-to-check-if-directory-is-writable-in-bat-script
copy /Y NUL "%FINAL_INSTALL_DIRECTORY%\.__writable" > NUL 2<&1 && set INSTALL_WRITEOK=1
IF DEFINED INSTALL_WRITEOK ( 
    echo "%FINAL_INSTALL_DIRECTORY%\"
    erase "%FINAL_INSTALL_DIRECTORY%\.__writable"
    echo did erase command of .__writable
) else (
    echo "No access to %FINAL_INSTALL_DIRECTORY%\, "
    echo need to call as Admin.
    set params=FINAL_INSTALL_CALL
    goto :CallAsAdministrator
)

:: We either fell through the above logic, or we jumped to calling the
:: final step as administrator.

goto :final_install_go
:final_install_only

:: Got here recursively called with admin privileges
color E0

:final_install_go
echo **********************************************************************
echo *              Final Install Copy Step                               *
echo **********************************************************************
:: Got here with final install or because we think we are ready. And
:: furthermore have a defined final install directory:
:: Removed xcopy  with  /c /s /e /y /i to robocopy with /MIR /R:0 
if defined FINAL_INSTALL_DIRECTORY (
    xcopy %VERBOSE_VFLG% "%LOCAL_INSTALL%/%INSTALL_SUBDIRECTORY%" "%FINAL_INSTALL_DIRECTORY%/%INSTALL_SUBDIRECTORY%" /s /e /y /i /d
    echo The xcopy error: !errorlevel!
    if !errorlevel! gtr 1 goto :error
    echo:
    echo Examine above for errors...
    echo Robocopy or xcopy might not report errors and this batch file
    echo may not report them.
)
goto :exiting

::   *********************************************************************
:CallAsAdministrator
echo params: %params%

echo *********************************************************************
echo *                Trigger recursive call as administrator            *
echo *********************************************************************

    :: Variable 'params' must be defined as the command line parameters.
    :: This MUST not be blank -- or recursive calling will occur.
if "%params%" equ "" (
    echo CallAsAdministrator params must not be blank.
    cmake -E false
    goto :error
)

    :: Here we run special program to get privileges, and
    :: recursively call this same batch file with an argument:
    (
        echo Set UAC = CreateObject^("Shell.Application"^)
        echo UAC.ShellExecute "cmd.exe", "/c ""%~s0"" %params:"=""%", "", "runas", 1
    )> "%temp%\getadmin.vbs"

    echo CALLing final installation with privileges....
    "%temp%\getadmin.vbs"
    erase "%temp%\getadmin.vbs"
    goto :exiting


:: ************************************************************************
:: *   :generatePropertyPage callable routine to generate Property Page   *
:: ************************************************************************

:: :generatePropertyPage callable batch segment produces a property page
:: for libpqxx, according to call arguments:

:: 1. %1 is integer 0 no library entries, 1 point to libraries, includes.
:: 2. %2 is integer 0 no copy of the DLL files, 1 copy DLL files.
:: 3. %3 is (probably quoted) output location and file name for the .props
::    property page.

:generatePropertyPage

@setlocal
echo **********************************************************************
if %1 neq 0 (set LIBP=Library) else (set LIBP=No library)
if %2 neq 0 (set DLLP=DLLs) else (set DLLP=No DLLs)
echo Build property page with %LIBP% and %DLLP%, located at:
echo:%~3

:: Note the special escape ^^! is because we EnableDelayedExpansion, and
:: the first ^ is quoted in the parenthetical capture and the remaining ^
:: escapes the ! which normally delimits delayed expansion variable.
:: Without this the ! disappears.

(
echo ^<?xml version="1.0" encoding="utf-8"?^>
echo ^<^^!--
echo     This is a property sheet to be included in MSVS projects of the applications
echo     using libpqxx. Use "View|Property Manager" and choose "Add Existing
echo     Property Sheet..." from the context menu to add it from the IDE.
echo   --^>
echo ^<Project ToolsVersion="4.0" xmlns="http://schemas.microsoft.com/developer/msbuild/2003"^>
echo   ^<ImportGroup Label="PropertySheets" /^>
echo   ^<PropertyGroup Label="UserMacros" /^>
echo   ^<PropertyGroup /^>
echo   ^<ItemDefinitionGroup^>
if %1 neq 0 (
echo     ^<ClCompile^>
echo       ^<AdditionalIncludeDirectories^>$^(MSBuildThisFileDirectory^)include;%%^(AdditionalIncludeDirectories^)^</AdditionalIncludeDirectories^>
echo     ^</ClCompile^>
echo     ^<Link^>
echo       ^<AdditionalLibraryDirectories^>$^(MSBuildThisFileDirectory^)lib\$^(Configuration^);%%^(AdditionalLibraryDirectories^)^</AdditionalLibraryDirectories^>
echo       ^<AdditionalDependencies^>pqxx.lib;$^(MSBuildThisFileDirectory^)bin\libpq.lib;wsock32.lib;ws2_32.lib;%%^(AdditionalDependencies^)^</AdditionalDependencies^>
echo     ^</Link^>
)
if %2 neq 0 (
echo     ^<PostBuildEvent^>
echo       ^<Command^>XCOPY "$(MSBuildThisFileDirectory)bin\*.DLL" "$(TargetDir)" /D /K /Y^</Command^>
echo     ^</PostBuildEvent^>
)
echo   ^</ItemDefinitionGroup^>
echo   ^<ItemGroup /^>
echo ^</Project^>
)>"%~3"

exit /B %errorlevel%

:: ********************************************************************* ::
:: Functions that return value in _ret variable...

:: See
:: https://stackoverflow.com/questions/1645843/resolve-absolute-path-from-relative-path-and-or-file-name/33404867#33404867
:: Return "normalized" path ???
:FULL_FILE_PATH
  SET _ret=%~dpfn1
  EXIT /B

:: Remove quote. Based upon above, noting function quote removing
:: extension for call argument.
:DEQUOTE
  SET _ret=%~1
  EXIT /B

::   **********************************************************************
::                         Successful exit.
:exiting
echo **********************************************************************
echo *                 Error and exit processing                          *
echo **********************************************************************
:: You can double click this file in the top level directory for the
:: project, and it pauses so the command window does not go away before you
:: see the results. The build_time_log.txt file shows start and end times
:: of the batch runs. Turn off PAUSE_AT_END (0) to disable pause.
echo End   build: %time% *** %~1>> build_time_log.txt
if %PAUSE_AT_END% neq 0 pause
goto :EOF



:error
set _errorlevel=%errorlevel%
color 4f
echo **********************************************************************
echo *                          Error Occurred                            *
echo **********************************************************************
echo Failed with error #%_errorlevel%, at %time% *** %~1>> build_time_log.txt
echo Failed with error #%_errorlevel%.
if %PAUSE_AT_END% neq 0 pause
exit /b %_errorlevel%
