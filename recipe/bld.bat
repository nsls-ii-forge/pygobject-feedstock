@ECHO ON

@REM I cannot for the life of me figure out how Cygwin/MSYS2 figures out its
@REM root directory, which it uses to find the /etc/fstab which *sometimes*
@REM affects the choice of the cygdrive prefix. But, regardless of *why*,
@REM I find that we need this to work:
mkdir %BUILD_PREFIX%\Library\etc
echo none / cygdrive binary,user 0 0 >%BUILD_PREFIX%\Library\etc\fstab
echo none /tmp usertemp binary,posix=0 0 0 >>%BUILD_PREFIX%\Library\etc\fstab

@REM Here we ditch the -GL flag, which messes up symbol resolution.
set "CFLAGS=-MD"
set "CXXFLAGS=-MD"

mkdir forgebuild
cd forgebuild

@REM pkg-config setup
FOR /F "delims=" %%i IN ('cygpath.exe -m "%LIBRARY_PREFIX%"') DO set "LIBRARY_PREFIX_M=%%i"
set PKG_CONFIG_PATH=%LIBRARY_PREFIX_M%/lib/pkgconfig

@REM NB: We should provide Cairo, but it's a bit tricky on Windows
@REM so we're punting on it for now.
%PYTHON% %PREFIX%\Scripts\meson --buildtype=release --prefix=%LIBRARY_PREFIX_M% --backend=ninja -Dpython=%PYTHON% -Dpycairo=false ..
if errorlevel 1 exit 1

ninja -v
if errorlevel 1 exit 1

ninja test
if errorlevel 1 exit 1

ninja install
if errorlevel 1 exit 1

@REM Meson doesn't put the Python files in the right place.
cd %LIBRARY_PREFIX%\lib\python*
cd site-packages
move *.egg-info %PREFIX%\lib\site-packages
move gi %PREFIX%\lib\site-packages\gi
move pygtkcompat %PREFIX%\lib\site-packages\gi
