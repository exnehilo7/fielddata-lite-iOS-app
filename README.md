# FERN
FERN (Field Expedition Routing and Navigation) is an application designed to solve the Traveling Salesman problem for field data scientists. The Application has two major components: The application itself and a PostgreSQL database backend on a Linux server with Apache and PHP. The database and the PHP files can be viewed at https://github.com/exnehilo7/fielddata-lite.

Apple Map performance declines if there are more than 100 displayed annotations. Later versions of the application will hopefully use clustering to allow for more annotations. Until then, the number of items in a saved route are limited.

The app can use a device's default GPS or an Arrow Gold GPS. Other 3rd party GPS can be used with an appropriate library.

Note: This application was initially built for a school project. From start to present, many features have been added and many have been removed. A smooth and polished user experience has a ways to go.


## iOS App and XCode Behaviors

The Apple Developer account that was used to develop this app was part of a group that is only used for internal organization applications. As a result, this app is not currently available on the App Store. It can, however, be run on a device attached to a MacOS machine. Note that you may need to be a part of an Apple Development Group, set the project’s Signing & Capabilities accordingly, and enable Developer Mode under the device’s Privacy and Security setting.


In the Debug area you may see this message:
> Publishing changes from within view updates is not allowed, this will cause undefined behavior.

It appears that this message is a bug: https://developer.apple.com/forums/thread/717478. Memory usage remained steady when tested with a device.


Because the toolkit for the Arrow Gold GPS was not originally compiled with the required ARM for a simulated device, XCode will not be able to run the app in its virtual devices.


## New Project Setup
Only necessary when starting from scratch:

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

