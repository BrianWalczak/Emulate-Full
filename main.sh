#!/bin/bash
underline=$(tput smul)
nounderline=$(tput rmul)

clear
echo "\033[0;35m█▀▀ █▀▄▀█ █ █ █   ▄▀█ ▀█▀ █▀▀ ▄▄ █▀▀ █ █ █   █  
██▄ █ ▀ █ █▄█ █▄▄ █▀█  █  ██▄    █▀  █▄█ █▄▄ █▄▄"
echo "A simple solution for macOS users to use Android Emulator full-screen!"
echo "Developed and maintained by Briann.\n\033[0m"

# Function to retrieve screen resolution
getDisplaySize() {
    local screenWidth=$(system_profiler SPDisplaysDataType | awk '/Resolution/{print $2}')
    local screenHeight=$(system_profiler SPDisplaysDataType | awk '/Resolution/{print $4}')

    # Open Terminal
    osascript -e 'tell application "Terminal" to activate' -e 'tell application "Terminal" to do script "clear"' >/dev/null 2>&1

    # Resize the Terminal window to full screen
    osascript -e 'tell application "System Events" to tell process "Terminal" to set position of window 1 to {0, 0}' -e 'tell application "System Events" to tell process "Terminal" to set size of window 1 to {'"$screenWidth"', '"$screenHeight"'}' >/dev/null 2>&1

    # Get the actual window size after resizing
    local windowSize=$(osascript -e 'tell application "System Events" to get size of window 1 of process "Terminal"') >/dev/null 2>&1

    # Close the Terminal window
    osascript -e 'tell application "Terminal" to close front window' >/dev/null 2>&1

    # Replace ', ' with ' x ' in windowSize
    windowSize=$(echo "$windowSize" | sed 's/, / x /g')
		
    echo "$windowSize"
}

echo "Here is a list of your emulators:"
cd ~/.android/avd && ls -d */ | sed 's/\.avd\///' | sed 's/^/- /'

printf "\n\033[1;33mPlease enter the name of your preferred emulator: \033[0m"
read option

clear

path="$HOME/.android/avd/${option}.avd/config.ini"
if [ -e $path ]; then
	echo "The following emulator is being read: $option"
	printf "\n\033[1;31mBefore you continue, please be aware that this edit is permanent and cannot be undone.\nIt's highly recommended that you save a backup of your configuration.\n\nYou can locate your configuration file at ${underline}${path}${nounderline}. Would you like to continue? \033[0;32m"
	read accept

	clear

	echo "\033[0mPlease wait, we're attempting to get your screen display resolution. This shouldn't take long!"

	# Exit Terminal full screen (if applicable)
	fullscreen=$(osascript -e 'tell application "System Events" to tell process "Terminal" to get value of attribute "AXFullScreen" of window 1')
	if [ "$fullscreen" = "true" ]; then
			echo "\033[1;33mWARNING: Please wait as Terminal is minimized (this is done to ensure accuracy).\033[0m"
	    osascript -e 'tell application "System Events" to tell process "Terminal" to set value of attribute "AXFullScreen" of window 1 to false
	    delay 2' > /dev/null 2>&1
	fi

	windowSize=$(getDisplaySize)
	shortWindowSize=$(echo "$windowSize" | sed 's/ x /x/g')
	width=${shortWindowSize%x*}
	height=${shortWindowSize#*x}


	new_file=""
	new_density_replaced_file=""
	emulatorWidthNum=""
	emulatorHeightNum=""
	emulatorDensity=""
	
	while IFS= read -r line || [ -n "$line" ]; do
	    first_word=$(echo "$line" | awk -F'=' '{print $1}' | sed 's/ *$//')
			
			# ------- CONFIGURE THE DENSITY ------- #
			
			# Check if the first word is "hw.lcd.width"
			if [ "$first_word" = "hw.lcd.density" ]; then
				emulatorDensity=$(echo "$line" | cut -d '=' -f 2- | sed 's/^ *//')
			fi
			
			# ------- HANDLE THE HEIGHT ------- #
			
			# Check if the first word is "hw.lcd.width"
			if [ "$first_word" = "hw.lcd.width" ]; then
				emulatorWidthNum=$(echo "$line" | cut -d '=' -f 2- | sed 's/^ *//')
				
				line="hw.lcd.width=$height"
			fi
			
			# Check if the first word is "skin.name"
			if [ "$first_word" = "skin.name" ]; then
				line="skin.name=$shortWindowSize"
			fi
			
			# ------- HANDLE THE WIDTH ------- #
			
			# Check if the first word is "hw.lcd.height"
			if [ "$first_word" = "hw.lcd.height" ]; then
				emulatorHeightNum=$(echo "$line" | cut -d '=' -f 2- | sed 's/^ *//')
				
				line="hw.lcd.height=$width"
			fi
			
			# Check if the first word is "hw.sensor.hinge.areas"
			if [ "$first_word" = "hw.sensor.hinge.areas" ]; then
				line="hw.sensor.hinge.areas=$height-0-0-$width"
			fi
			
			# ------- OTHERS ------- #
			
			# Check if the first word is "showDeviceFrame"
			if [ "$first_word" = "showDeviceFrame" ]; then
				line="showDeviceFrame=no"
			fi
			
			# Check if the first word is "showDeviceFrame"
			if [ "$first_word" = "skin.path" ]; then
				line="skin.path=_no_skin"
			fi
			
			# Check if the first word is "hw.initialOrientation"
			if [ "$first_word" = "hw.initialOrientation" ] && [[ "$line" =~ 'portrait' ]]; then
				printf "\033[1;33mIt's highly recommended that the emulator you choose is a tablet.\nUsing a phone emulator is experimental and may cause performance issues.\n\n\033[1;31mAre you sure you'd like to continue (not recommended)? \033[0m"
				read -r phoneWarning < /dev/tty
				clear
			fi
			
	    new_file+="\n$line"
	done < "$path"
	
	densityMultip=$((($emulatorWidthNum * $emulatorHeightNum) / $emulatorDensity))
	userSizeDisplay=$(($width * $height))
	newDensity=$(($userSizeDisplay / $densityMultip))
	
	new_file=$(echo "$new_file" | sed "/hw.lcd.density/ s/.*/hw.lcd.density=$newDensity/")
	echo "$new_file"
	
	printf "\n\n\033[0;32mYour recommended display resolution is: $windowSize!\n\033[1;33mWould you like to save these configurations? \033[0m"
	read save
	echo "Saving your new configuration \033[1;31m(this is irreversible)\033[0m..."
	sleep 2
	echo "$new_file" > $path
	echo "\n\n\033[0;32mYour configuration has been successfully to fit your screen! Please restart your emulator to apply these changes.\033[0m"
else
    echo "\033[1;31mAn error occurred when accessing the configuration file for this emulator!\nPlease ensure this emulator folder exists.\n\033[0;32m"
fi
