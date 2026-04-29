@echo off
REM Debug build script for amigahid-pico on Windows with Visual Studio

REM Set up Visual Studio environment
call "C:\Program Files\Microsoft Visual Studio\18\Enterprise\VC\Auxiliary\Build\vcvarsall.bat" x64 >nul

REM Add Python to PATH (in case not in environment)
set PATH=%LOCALAPPDATA%\Programs\Python\Python312;%LOCALAPPDATA%\Programs\Python\Python312\Scripts;%PATH%

REM Add ARM GCC to PATH
set PATH=C:\Program Files (x86)\Arm GNU Toolchain arm-none-eabi\14.3 rel1\bin;%PATH%

cd /d "%~dp0"

REM Clean build directory if requested
if "%1"=="clean" (
    rmdir /s /q build_pico2 2>nul
    echo Build directory cleaned.
    goto :eof
)

REM Configure CMake with Debug flags
echo Configuring CMake for Pico 2 (RP2350) DEBUG BUILD...
cmake -S . -B build_pico2 -G Ninja ^
    -DPICO_PLATFORM=rp2350 ^
    -DPICO_BOARD=pico2 ^
    -DBOARD_TYPE=BOARD_HIDPICO_REV4 ^
    -DCMAKE_BUILD_TYPE=Debug ^
    -DPICO_DEOPTIMIZED_DEBUG=0

if errorlevel 1 (
    echo CMake configuration failed!
    exit /b 1
)

REM Build
echo Building DEBUG version...
cmake --build build_pico2

if errorlevel 1 (
    echo Build failed!
    exit /b 1
)

echo.
echo DEBUG build complete!
echo Output: build_pico2\src\amigahid-pico.elf
echo WARNING: Debug build is larger and slower - use only for debugging!
