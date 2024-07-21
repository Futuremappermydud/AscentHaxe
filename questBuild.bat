@RD /S /Q "./quest-build/src/"
@RD /S /Q "./quest-build/include/"
haxe ./cpp.hxml
del %CD%\bin\cpp\src\__lib__.cpp
move %CD%\bin\cpp\src %CD%\quest-build\src
move %CD%\bin\cpp\include %CD%\quest-build\include
cd quest-build
call pwsh scripts/build.ps1