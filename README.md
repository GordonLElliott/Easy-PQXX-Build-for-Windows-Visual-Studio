Easy-PQXX-Build-for-Windows-Visual-Studio (0.0.3)
-------------------------------------------------

Build libpqxx for Windows quickly, with both Debug and Release
configurations, install in Program Files, create property sheets to easily
use in Visual Studio applications, with named versions for configurations
and options. Skip past the notes to **Easy-PQXX Batch Build for Visual
Studio** to jump right in with:

1. Automated batch file to build and install in the selected location
   (typically C:\Program Files\libpqxx), asking for administrator
   privileges if needed to copy the files.
2. Configure for Unicode or MultiByte character sets. (For example Unicode
   character set may be needed to interface wxWidgets in the same
   application.)
3. Keep named installations for different configurations.
4. One library installation with both Debug and Release compiles that
   automatically switch in Visual Studio.
5. Property Sheets so your Visual Studio application (with both Debug and
   Release compiles) can be instantly configured.
6. Gather DLLs from PostgreSQL library into your application automatically.

Additionally various configuration solving selections can be made, for
example if you have more than one PostgreSQL library or want to compile for
more than one version of Visual Studio.

Notes
-----

The new libpqxx version 7 and beyond can most easily be built for Windows
Visual Studio using the "CMake" build process. Since version 7 requires C++
17 standard, to build for Microsoft Visual Studio, the 2017 or later is
required.
 
CMake is a wonderful "make" like system that runs on a large variety of
operating systems. This allows a single build methodology to be used by the
libpqxx developers which targets an enormous variety of operating systems
and compiler options. However due to the requirements of compatibility of
this large number of target systems, bugs and issues with CMake, and
programming methods needed for the CMake process to be compatible with this
large number of targets, some problems remain for the specific installation
on Windows operating system using Visual Studio compiler.

CMake is available for several compilers for Windows, including Microsoft
Visual Studio. Only Visual Studio 2017 and later support the C++ 17
standard required by libpqxx 7. And libpqxx version 7 can most easily be
compiled for Visual Studio using the CMake build process.
 
Unfortunately there are a few bugs and pitfalls in the CMake process, which
show up in Windows. The methods here show how to get past those problems if
they occur for you, and a configurable batch file is presented which will
fully automate the installation of the libpqxx library with options and
features discussed in the introduction.

Basics of the Cmake Build for Visual Studio
-------------------------------------------

You can do the basic CMake build process without using the batch file and
advanced features, and understand the underlying steps, according to these
instructions. This will build and install only one configuration, and can't
be directly placed in a privileged location.
 
In my opinion the best way to build a static libpqxx library on Windows for
Visual Studio is an "out-of-source build" using CMake, in which source and
build files are subdirectories of a top-level directory. (Check that your
version of CMake is up to date. The minimum CMake version should be 3.17.1
and the latest is preferred.) In this method you put the input source files
subdirectory (`libpqxx-master` or `libpqxx-<version>`) into the top-level
directory. Then in this top-level directory execute the following two
commands:

```
cmake -S libpqxx-master -B build -DCMAKE_INSTALL_PREFIX="libpqxx"
```

This constructs a Visual Studio solution with multiple projects and CMake
build information, in the 'build' subdirectory, but does not build those
projects. The CMAKE_INSTALL_PREFIX parameter establishes the final install
directory in advance as a third subdirectory 'libpqxx', of the build
directory. This cannot be located in the protected Program Files directory
without running CMake as administrator. Leaving off the
CMAKE_INSTALL_PREFIX parameter usually causes CMake to default to
`C:\Program Files (x86)\libpqxx` in the next step. This is often the wrong
install subdirectory, requires administrative privileges or will fail, and
those privileges are not granted just by logging in as admin.
 
Then
```
cmake --build build --target INSTALL
```

will build the projects, including copying the final installation files
into the libpqxx subdirectory of your build directory, as previously
established. That libpqxx subdirectory can be manually copied into the
`C:\Program Files` directory if desired, to give it a standardized location
that may be expected on Windows. A manual copy wil ask for administrative
rights.

A version of PostgreSQL must be installed on the build computer, at least
the libraries must be installed. See the notes on additional flags below if
the first cmake command cannot locate the correct PostgreSQL library.

One way to automate this build process is to copy the following lines and paste
into a good programming editor, which will fix any Windows new line problems.
Then save as `build.bat` batch script file, into your top-level directory. Click
on the batch file to automate the build process:

```bat
REM Automated build of libpqxx placing install files in libpqxx subdirectory.
cmake -S libpqxx-master -B build -DCMAKE_INSTALL_PREFIX="libpqxx"
if %errorlevel%==0  cmake --build build --target INSTALL
pause
```

Any changes can be made by clicking the batch build file again and only
necessary changes will be compiled, as is normal for a "make" process.
 
Flags that can be added on the first cmake line include: `-A x64` or `-A
Win32` These will select the target architecture as 64 or 32 bit. `-G
"Visual Studio 15 2017"`  may be used to select the 2017 version of Visual
Studio, or explicitly select `-G "Visual Studio 16 2019"` (default  if
installed). The architecture and generator parameter values must be exactly
as shown. Use `-DPostgreSQL_ROOT="C:\Program Files\PostgreSQL\12"`   to
select the version of PostgreSQL at the specified location. To compile for
Win32, the `"C:\Program Files (x86)\PostgreSQL\10"` version of libpq will
probably be required from the x86 directory (and include `-A Win32`).

The second (build) cmake command can also have: `--config Release` to
switch the install from a Debug to a Release configuration.

A slightly more complex sequence of commands will build (completely
separate) Debug and Release installations:

```bat
REM Automated build of libpqxx, both Debug and Release
cmake -S libpqxx-master -B build
if %errorlevel%==0  cmake --build build   --config Debug
if %errorlevel%==0  cmake --build build   --config Release
if %errorlevel%==0  cmake --install build --config Debug   --prefix "libpqxx/Debug"
if %errorlevel%==0  cmake --install build --config Release --prefix "libpqxx/Release"
pause
```

Easy-PQXX Batch Build for Visual Studio
---------------------------------------

The batch file 'Easy-PQXX.bat' supplied here does basically the same thing
as the last example above, building libpqxx with both Release and Debug
libraries, but also creates appropriate property sheet for use of the
library, installs the libraries and DLLs in a standardized location
(usually C:\Program Files\libpqxx), and automatically asks for admin
privileges. Furthermore it organizes the installation as a single directory
with include and 'share' directories (with documentation), but the lib
directory has both a Debug and Release subdirectory with the respective
library.

This batch file has a top section to allow the user to configure the build.
As noted in the batch file, it should be copied to the top level directory
used to build the libpqxx system, **using your favorite programming text
editor.** Since presumably you are using Visual Studio 2017 or later for
the compile (you wouldn't be here otherwise), Visual Studio can be used for
that purpose, and check that you have the menu `Edit--Advanced--End of Line
Sequence` set to CRLF when you save. (Hopefully any code-page issues would
be resolved in this step as well.) Set the configuration variables (top
section) to the values you want, then save the edited batch file in that
top level directory for the install.

**Please do not change the operations sections of this batch file! This
batch file can recursively run itself as administrator for the last
installation step (just using xcopy), but that gives the batch file
privileges to do almost anything!**

To activate the batch file (in the top-level subdirectory for the project)
just click (or double click) the file. It will open in a command window,
and has a pause at the end so you can read the results. After build it may
ask permissions to run in administrative mode to do the final copy to the
Program Files directory. After giving permission, a yellow background
command window is doing the final copy. Then hit a key to end each window,
after checking for proper operation.
 
This batch file first configures the build, compiles the libraries (both
Release and Debug as selected), but in separate local pre-installation
directories. The CMake methods are only configured to do this as separate
file groupings. Then the batch file copies the separate installations into
a singe coherent directory with just one include subdirectory, just one
'share' subdirectory with documentation, and with a lib directory that is
subdivided by Debug and Release folders. Another subdirectory, 'bin' is
added to contain the external PostgreSQL libraries and DLL files required
for applications using the libpqxx library. Property page files are also
added to this directory, which can be used in Visual Studio projects to
easily reference the libraries and DLL files needed.

Using the PQXX Library
----------------------

Create your new project in Visual Studio. (Often a completely new project
will be required, because the changes are significant from previous
versions if you are upgrading old work. For example you don't need to
provide locations for libraries and include files any more!)

The first setting that is **required** is to change your C++ Language
Standard to ISO C++ 17. (We can't do that from Property Pages.)

Then in the "Property Manager" tab, select each of your Debug and Release
versions (in sequence). Right click and "Add Existing Property Sheet".
Unfortunately VS seems to forget where you were, so you have to click
around to the install directory each time. Find the appropriately named
subdirectory of the libpqxx install directory, for the respective build
library to be used. At the base of that directory are three property sheets
(.props) named libpqxx, libpqxx-ALL, and libpqxx-DLL. The first is just the
library (no DLL). The -DLL version just copies the DLL's to your executable
directory as a post-build event. And the -ALL version does it all. Select
the libpqxx-ALL.props sheet. (You need to do this for both the Debug and
the Release configurations, but use the same property sheet for both.)
 
Then compile your application! (Thats all.)

You can switch your application between Debug and Release configurations
and the correctly built library is chosen automatically.

(If you are building both x64 and Win32 versions of your application, you
will have to configure a 2nd copy of the batch file for Win32, and the
output libraries will appear in a separate subdirectory of the libpqxx
installation. When adding property sheets, add the sheets from the
appropriate subdirectory in the respective configuration from the Property
Manager.)

Note that the installation directory looks like this:
```
bin
include
lib
libpqxx.props
libpqxx_ALL.props
libpqxx_DLL.props
share
```

The lib subdirectory is different from the normal libpqxx make, since it
contains separate Debug and Release subdirectories, each with a library.
The libpqxx_ALL.props property page causes the application to refer to the
library, the include files, and also copy the DLLs for PostgreSQL to the
execute directory. THe libpqxx.props refers to the
library, the include files, but does not copy the DLLs. The
libpqxx_DLL.props property page only copies the DLLs. (This last can be
used in the test suite generated in the CMake build.)

