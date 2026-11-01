@echo off
setlocal
pushd "%~dp0"
if errorlevel 1 exit /b 1

if exist ".venv\Scripts\python.exe" goto environment_ready
set "PYTHON_LAUNCHER="
where py >nul 2>nul
if not errorlevel 1 set "PYTHON_LAUNCHER=py -3"
if defined PYTHON_LAUNCHER goto check_python
where python >nul 2>nul
if not errorlevel 1 set "PYTHON_LAUNCHER=python"
if not defined PYTHON_LAUNCHER goto missing_python

:check_python
%PYTHON_LAUNCHER% -c "import sys; sys.exit(sys.version_info < (3, 10))" >nul 2>nul
if errorlevel 1 goto missing_python
echo Creating the Python environment. This is only needed on first use.
%PYTHON_LAUNCHER% -m venv ".venv"
if errorlevel 1 goto setup_failed

:environment_ready
".venv\Scripts\python.exe" -c "import sys; sys.exit(sys.version_info < (3, 10))" >nul 2>nul
if errorlevel 1 goto invalid_environment
".venv\Scripts\python.exe" -c "import matplotlib, typst; from importlib.metadata import version; assert tuple(map(int, matplotlib.__version__.split('.')[:2])) >= (3, 7); assert version('typst') == '0.15.0'" >nul 2>nul
if not errorlevel 1 goto run_build
echo Installing the Python requirements. Internet access is needed for this step.
".venv\Scripts\python.exe" -m pip install -r "%~dp0requirements.txt"
if errorlevel 1 goto setup_failed

:run_build
".venv\Scripts\python.exe" "%~dp0build.py" %*
set "BUILD_RESULT=%ERRORLEVEL%"
goto finish

:missing_python
echo Python 3.10 or later is required. Install it from https://www.python.org/downloads/windows/
echo Then reopen the terminal or run this launcher again.
set "BUILD_RESULT=1"
goto finish

:invalid_environment
echo The Python environment is unavailable or too old. Recreate .venv using Python 3.10 or later.
set "BUILD_RESULT=1"
goto finish

:setup_failed
echo Python environment setup failed. Check the error above and run this launcher again.
set "BUILD_RESULT=1"

:finish
popd
if "%~1"=="" pause
exit /b %BUILD_RESULT%
