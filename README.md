# fielddata-lite-iOS-app
Traveling Salesman iOS App for the WGU Bachelor's Capstone. Working Title: FERN (Field Expedition Route Navigation)


## Set iOS App Security Settings
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
