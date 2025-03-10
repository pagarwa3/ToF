@ECHO off
SETLOCAL

::this script downloads and installs the dependencies (glog, protobuf and websockets) and builds the sdk.

::global variables
for %%F in (cd %0 ..) do set source_dir=%%~dpF
set /a display_help=0
set /a answer_yes=0
set /a set_build=0
set /a set_deps=0
set /a set_deps_install=0
set /a use_depth_compute_stubs=0
set /a use_depth_compute_opensource=0
set /a threads=4

set build_dire=""
set deps_dir=""
set deps_install_dir=""
set generator=""

set config_type=""
set generator=""
set /a set_config=0
set /a set_generator=0

::interpret the arguments
:interpret_arg
if "%1" neq "" (
   if /I "%1" EQU "-h" (
   set /a display_help=1
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "--help" (
   set /a display_help=1
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "-y" (
   set /a answer_yes=1
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "--yes" (
   set /a answer_yes=1
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "-b" (
   set build_dire=%2
   set /a set_build=1
   shift
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "--buildir" (
   set build_dire=%2
   set /a set_build=1
   shift
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "-d" (
   set deps_dir=%2
   set /a set_deps=1
   shift
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "--depsdir" (
   set deps_dir=%2
   set /a set_deps=1
   shift
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "-i" (
   set deps_install_dir=%2
   set /a set_deps_install=1
   shift
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "--depsinstalldir" (
   set deps_install_dir=%2
   set /a set_deps_install=1
   shift
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "-g" (
   set generator=%2
   set /a set_generator=1
   shift
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "--generator" (
   set generator=%2
   set /a set_generator=1
   shift
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "-c" (
   set config_type=%2
   set /a set_config=1
   shift
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "--configuration" (
   set config_type=%2
   set /a set_config=1
   shift
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "--use_depth_compute_stubs" (
   set /a use_depth_compute_stubs=1
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "--use_depth_compute_opensource" (
   set /a use_depth_compute_opensource=1
   shift
   goto :interpret_arg
   )
   if /I "%1" EQU "-j" (
   set threads=%2
   shift
   shift
   goto :interpret_arg
   )
   shift
   goto :interpret_arg
)

if %display_help%==1 (
   call :print_help
   EXIT /B 0
   )
   
if %use_depth_compute_opensource%==1 (
	if %use_depth_compute_stubs%==1 (
		echo Please choose only one between stubs and opensource
		EXIT /B %ERRORLEVEL%
	)
)
::check if the configuration is correct
set /a opt=0
if "%config_type%"=="Release" (
    set /a opt=1
)
if "%config_type%"=="Debug" (
    set /a opt=1
)
if %set_config%==0 ( 
    set /a opt=1
    set config_type=Release
    )
if %opt%==0 (
    echo Please enter a correct configuration (Release or Debug^)
    EXIT /B %ERRORLEVEL%
)
echo Setup will continue with the configuration: %config_type%

::check if the generator is correct
set /a opt=0
set opencv_vs=15
if %generator%=="Visual Studio 17 2022" (
    set /a opt=1
    set opencv_vs=15
)
if %generator%=="Visual Studio 16 2019" (
    set /a opt=1
    set opencv_vs=15
)
if %generator%=="Visual Studio 15 2017 Win64" (
    set /a opt=1
    set opencv_vs=15
)
if %generator%=="Visual Studio 14 2015 Win64" (
    set /a opt=1
    set opencv_vs=14
)

if %set_generator%==0 (
   set /a opt=1
   set generator="Visual Studio 16 2019"
   set opencv_vs=16
   )
if %opt%==0 (
    echo Please enter a correct configuration ("Visual Studio 17 2022";"Visual Studio 16 2019"; "Visual Studio 15 2017 Win64" or "Visual Studio 14 2015 Win64"^)
    EXIT /B %ERRORLEVEL%
)
echo Setup will continue with the generator: %generator%

::set the diretories
if %set_build%==0 (
   set build_dire=%CD%\build
   )
echo The sdk will be built in: %build_dire%

if %set_deps%==0 (
   set deps_dir=%CD%\deps
   )
echo The deps will be downloaded in: %deps_dir%

if %set_deps_install%==0 (
   set deps_install_dir=%deps_dir%\installed
   )
echo The deps will be installed in:  %deps_install_dir%

::ask for permission to continue the setup
if %answer_yes%==0 (
   call :yes_or_exit "Do you want to continue?"
   )

::create the missing folders
if not exist %build_dire% md %build_dire%
if not exist %deps_dir% md %deps_dir%
if not exist %deps_install_dir% md %deps_install_dir%

pushd %deps_install_dir%
    set deps_install_dir=%CD%
popd

::call functions that install the dependencies
CALL :install_glog %config_type% %generator%
CALL :install_protobuf %config_type% %generator%
CALL :install_websockets %config_type% %generator%

::build the project with the selected options
pushd %build_dire%
if %use_depth_compute_stubs%==1 (
   cmake -G %generator% -DWITH_PYTHON=on -DCMAKE_PREFIX_PATH="%deps_install_dir%\glog;%deps_install_dir%\protobuf;%deps_install_dir%\libwebsockets" %source_dir% -DUSE_DEPTH_COMPUTE_STUBS=ON -DCMAKE_BUILD_TYPE=%config_type%
   ) else (
		if %use_depth_compute_opensource%==1 (
			cmake -G %generator% -DWITH_PYTHON=on -DCMAKE_PREFIX_PATH="%deps_install_dir%\glog;%deps_install_dir%\protobuf;%deps_install_dir%\libwebsockets" %source_dir% -DUSE_DEPTH_COMPUTE_OPENSOURCE=ON -DCMAKE_BUILD_TYPE=%config_type%
		) else (
			cmake -G %generator% -DWITH_PYTHON=on -DCMAKE_PREFIX_PATH="%deps_install_dir%\glog;%deps_install_dir%\protobuf;%deps_install_dir%\libwebsockets" %source_dir% -DCMAKE_BUILD_TYPE=%config_type%
		) 
)
cmake --build . --config %config_type% -j %threads%
popd
EXIT /B %ERRORLEVEL%

:print_help
ECHO setup.bat [OPTIONS]
ECHO -h^|--help
ECHO        Print a usage message briefly summarizing the command line options available, then exit.
ECHO -y^|--yes
ECHO        Automatic yes to prompts.
ECHO -b^|--buildir
ECHO        Specify the build directory of the SDK.
ECHO -d^|--depsdir
ECHO        Specify the directory where the dependencies will be downloaded.
ECHO -i^|--depsinstalldir
ECHO        Specify the directory where the dependencies will be installed.
ECHO -g^|--generator
ECHO        Visual Studio 16 2019 = Generates Visual Studio 2019 project files.
ECHO        Visual Studio 15 2017 Win64 = Generates Visual Studio 2017 project files.
ECHO        Visual Studio 14 2015 Win64 = Generates Visual Studio 2015 project files.
ECHO -c^|--configuration
ECHO        Release = Configuration for Release build.
ECHO        Debug   = Configuration for Debug build.
ECHO --use_depth_compute_stubs
ECHO        Used when building with stubs in place of the depth compute libraries.
ECHO --use_depth_compute_opensource
ECHO        Used when building with opensource in place of the depth compute libraries.
ECHO -j
ECHO        Set the number of threads used for building, by default is set to 4.
EXIT /B 0

:yes_or_exit
:choice
set /P c="%~1 [Y/N]"
if /I "%c%" EQU "Y" goto :end_yes_or_exit
if /I "%c%" EQU "N" EXIT 
goto :choice
:end_yes_or_exit
EXIT /B 0

:install_glog
set configuration=%~1
echo "Installing glog with config=%configuration% and generator=%generator%"
pushd %deps_dir%
if not exist "glog" ( git clone --branch v0.6.0 --depth 1 https://github.com/google/glog )
pushd glog
git checkout tags/v0.6.0
if not exist "build_0_6_0" ( mkdir build_0_6_0 )
pushd build_0_6_0
cmake -DWITH_GFLAGS=off -DCMAKE_INSTALL_PREFIX=%deps_install_dir%\glog -G %generator% ..
cmake --build . --target install --config %configuration% -j %threads%
popd
popd
popd
EXIT /B 0

:install_protobuf
set configuration=%~1
echo "Installing protobuf with config=%configuration% and generator=%generator%"
pushd %deps_dir%
if not exist "protobuf" ( git clone --branch v3.9.0 --depth 1 https://github.com/protocolbuffers/protobuf )
pushd protobuf
if not exist "build_3_9_0" ( mkdir build_3_9_0 )
pushd build_3_9_0
cmake -Dprotobuf_BUILD_TESTS=OFF -DCMAKE_INSTALL_PREFIX=%deps_install_dir%\protobuf -Dprotobuf_MSVC_STATIC_RUNTIME=OFF -G %generator% ..\cmake\
cmake --build . --target install --config %configuration% -j %threads%
popd
popd
popd
EXIT /B 0

:install_websockets
set configuration=%~1
echo "Installing websockets with config=%configuration% and generator=%generator%"
pushd %deps_dir%
if not exist "libwebsockets" ( git clone --branch v3.1-stable --depth 1  https://libwebsockets.org/repo/libwebsockets )
pushd libwebsockets
if not exist "build_3_1_stable" ( mkdir build_3_1_stable )
pushd build_3_1_stable
cmake -DLWS_WITH_SSL=OFF -DLWS_WITHOUT_TESTAPPS=ON -DLWS_WITHOUT_TEST_SERVER=ON -DLWS_WITH_SHARED=ON -DLWS_WITH_STATIC=OFF -DCMAKE_INSTALL_PREFIX=%deps_install_dir%\libwebsockets -G %generator% ..
cmake --build . --target install --config %configuration% -j %threads%
popd
popd
popd
EXIT /B 0