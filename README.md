# fielddata-lite-iOS-app
Traveling Salesman iOS App for the WGU Bachelor's Capstone. Working Title: FERN (Field Expedition Routing and Navigation)

## iOS App and XCode Settings
The Apple Developer account that was used to develop this app was part of a group that is only used for internal organization applications. As a result, this app is not currently available on the App Store. It can, however, be run in a simulator with Xcode on MacOS or on a device attached to a MacOS machine. If run on a device, you may need to be a part of and set the project’s signing & Capabilities to an Apple Development Group, and enable Developer Mode under the device’s Privacy and Security setting.

When using XCode 14.2’s simulator, be sure **Allow Location Simulation** is checked and a **Default Location** is selected under **Product** -> **Scheme** -> **Edit Scheme** -> **Options** tab.
1. Clone the repo to a non-iCloud folder.
2. Open XCode and open the project in the folder that the repo was cloned to.
3. Select **iPad Pro (12.9-inch) (6th generation)** as the device.
4. If you are using your own backend, the URL of the server will first need to be added/updated in the project’s **Info.plist** file, under the **Includes Subdomains** key, and the **htmlRoot** variable under the **HTMLRootModel** class in the **Models.swift** file.
5. Click the **Play** button.


## New Project Setup
Only necessary when starting from scratch.
### Set iOS App Security Settings
	1. Xcode
		a. Click the Project name in the Project Navigator.
		b. Info tab.
		c. Mouse over an item and click +.
		d. Add "App Transport Security Settings" (Dictionary).
		e. Click its >.
		f. Click its +. 
		g. Add "Allow Arbitrary Loads" (Boolean (YES)).
	2. While in the Info tab:
		a. Hover over App Transport Security Settings.
		b. Click +.
		c. Add "Exception Domains" (Dictionary).
		d. Click its >.
		e. Click its +.
		f. Type in the root address.
		g. Click its +.
		h. Add "Includes Subdomains" (Boolean (YES)).
		i. Click the root address' +.
		j. Add "Allow Insecure HTTP Loads" (Boolean (YES)).
	3. Under "Application Scene Manifest"
		a. Click its >.
		b. Add "Scene Configuration" (Dictionary).
	4. Clean the project 
    	a. Menu Bar > Product > Clean Build Folder.

### Set App Request Permissions
In the info file:
	1. Add a key "Privacy - Location When In Usage Description". Include a String message to display to the user.

