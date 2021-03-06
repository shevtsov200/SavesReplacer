@echo off
setlocal enabledelayedexpansion

REM files to store profiles, games and current profile
set GAMES_FILE_NAME=games.txt
set PROFILES_FILE_NAME=profiles.txt
set CURRENT_PROFILE_FILE_NAME=currentProfile.txt
REM location of profiles
set PROFILES_LOCATION=profiles

REM save type codes
set DIRECTORY_SAVE_CHAR=D
set REGISTRY_SAVE_CHAR=R

if not exist %GAMES_FILE_NAME% type nul>%GAMES_FILE_NAME%
if not exist %PROFILES_FILE_NAME% type nul>%PROFILES_FILE_NAME%
if not exist %CURRENT_PROFILE_FILE_NAME% type nul>%CURRENT_PROFILE_FILE_NAME%

:menu
REM get name of current profile
set /p currentProfile=<%CURRENT_PROFILE_FILE_NAME%

REM menu promt
echo current profile: !currentProfile!
echo 1 create profile
echo 2 choose profile
echo 3 add game
echo 4 exit

REM check for chosen menu item
choice /C 1234 /n
REM create new profile
if "%ERRORLEVEL%" == "1" (
	REM read new profile name
	echo write profile name
	set /p profileName=
	echo "!profileName!"
	echo %PROFILES_FILE_NAME%
	
	REM check if this profile already exists
	>nul find "!profileName!" %PROFILES_FILE_NAME% && (
		echo profile !profileName! already exists
	) || (
		echo !profileName! created.
		
		REM create new profile directory
		echo !profileName!>>%PROFILES_FILE_NAME%
		mkdir "%PROFILES_LOCATION%\!profileName!"
		
		REM add games to this profile directory
		REM parse games file for game names and saves locations
		for /F "tokens=1,2,3 delims=#" %%A in (%GAMES_FILE_NAME%) do (
			REM create game directory
			mkdir "%PROFILES_LOCATION%\!profileName!\%%A"
			
			if %%C == %DIRECTORY_SAVE_CHAR% (			
				REM copy game saves to this profile directory
				robocopy "%%B" "%PROFILES_LOCATION%\!profileName!\%%A" /e /njh /njs /ndl /nc /ns
			) else if %%C == %REGISTRY_SAVE_CHAR% (
				REM export registry to this profile directory
				REG EXPORT "%B%" "%PROFILES_LOCATION%\!profileName!\%%A\%%A.reg"
			) else (
				echo unrecognized save type: %%C
			)
			echo name: "%%A" location: "%%B" type: "%%C"
			
		)
	)
REM choose another profile
) else if "%ERRORLEVEL%" == "2" (
	
	REM read name of profile to which we switch
	echo write profile name
	set /p profileName=
	
	REM check that such profile exists
	>nul find "!profileName!" %PROFILES_FILE_NAME% && (
		REM parse games file for game names and save locations
		for /F "tokens=1,2,3 delims=#" %%A in (%GAMES_FILE_NAME%) do (
			echo name: "%%A" location: "%%B" type: "%%C"
			if %%C == %DIRECTORY_SAVE_CHAR% (
				REM copy current profile saves to its directory
				robocopy "%%B" "%PROFILES_LOCATION%\!currentProfile!\%%A" /e /njh /njs /ndl /nc /ns
				REM replace current saves with saves of new profile
				robocopy "%PROFILES_LOCATION%\!profileName!\%%A" "%%B" /e /njh /njs /ndl /nc /ns
			) else if %%C == %REGISTRY_SAVE_CHAR% (
				REM export current profile save registry to its directory
				echo "%%B" "%PROFILES_LOCATION%\!currentProfile!\%%A\%%A.reg"
				REG EXPORT "%%B" "%PROFILES_LOCATION%\!currentProfile!\%%A\%%A.reg" /y
				REM replace current save registry with saves of new profile
				REG IMPORT "%PROFILES_LOCATION%\!profileName!\%%A\%%A.reg"
			) else (
				echo unrecognized save type: %%C
			)

		)
		REM save new current profile name
		echo !profileName!>%CURRENT_PROFILE_FILE_NAME%
	) || (
		echo profile "!profileName!" doesn't exist
	)
REM add new game
) else if "%ERRORLEVEL%" == "3" (
	REM read save type ^(directory or registry key^)
	echo write save type ^(^'%DIRECTORY_SAVE_CHAR%^' for directory or ^'%REGISTRY_SAVE_CHAR%^' for registry key^)
	set /p saveType=
	echo "!saveType!"
	
	REM check save type
	if "!saveType!" == "%DIRECTORY_SAVE_CHAR%" (
		REM saves in directory
		
		echo directory save
		REM read new game name
		echo write game name
		set /p gameName=
		
		echo "!gameName!"
		REM read location of saves
		echo write saves location
		set /p savesLocation=
		echo !savesLocation!
		
		REM append game name and save location to games file
		(
			echo ^#!gameName!^#!savesLocation!^#!saveType!
		) >> %GAMES_FILE_NAME%
		
		REM copy saves of this game to every profile
		for /F "tokens=*" %%A in (%PROFILES_FILE_NAME%) do (
			echo "%%A"
			mkdir "%PROFILES_LOCATION%\%%A\!gameName!"
			robocopy "!savesLocation!" "%PROFILES_LOCATION%\%%A\!gameName!" /e /njh /njs /ndl /nc /ns
		) 
	) else if "!saveType!" == "%REGISTRY_SAVE_CHAR%" (
		REM saves in registry key
		echo registry key save
		
		REM read new game name
		echo write game name
		set /p gameName=
		
		echo "!gameName!"
		REM read location of saves
		echo write saves registry key
		set /p registryKey=
		echo !registryKey!
		
		REM append game name and save location to games file
		(
			echo ^#!gameName!^#!registryKey!^#!saveType!
		) >> %GAMES_FILE_NAME%
		
		REM copy saves of this game to every profile
		for /F "tokens=*" %%A in (%PROFILES_FILE_NAME%) do (
			echo "%%A"
			mkdir "%PROFILES_LOCATION%\%%A\!gameName!"
			REM export game registry branch
			echo "!registryKey!" "%cd%\%PROFILES_LOCATION%\%%A\!gameName!"
			REG EXPORT "!registryKey!" "%cd%\%PROFILES_LOCATION%\%%A\!gameName!\!gameName!.reg"
		) 
	) else (
		REM incorrect save type char
		echo save type "!saveType!" is not recognized
	)
) else if "%ERRORLEVEL%" == "4" (
	goto exit
)
goto menu

:exit
PAUSE

: