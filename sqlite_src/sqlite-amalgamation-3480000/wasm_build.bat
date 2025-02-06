@echo off
setlocal enabledelayedexpansion

set "MyClangDir=C:\Users\rmast\Downloads\wasi-sdk-25.0-x86_64-windows\bin"  '# Path to the clang *directory*
set "PATH=%MyClangDir%;%PATH%"  '# Prepend to the existing path

for /f "delims=" %%i in ('orca sdk-path') do set "ORCA_DIR=%%i"
echo ORCA_DIR
set "wasmFlags=--target=wasm32 -mbulk-memory -g -O2"
set "wasmFlags=%wasmFlags% -Wl,--no-entry -Wl,--export-dynamic "
set "wasmFlags=%wasmFlags% --sysroot "%ORCA_DIR%\orca-libc""
set "wasmFlags=%wasmFlags% -I "%ORCA_DIR%\src" -I "%ORCA_DIR%\src\ext""

where clang

clang %wasmFlags% -L "%ORCA_DIR%\bin" -lorca_wasm ^
-D SQLITE_OS_OTHER=1 -D SQLITE_OMIT_LOCALTIME -D SQLITE_THREADSAFE=0 ^
-o sqlite3.o -c sqlite3.c

endlocal