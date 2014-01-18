Scrollvetica 1.0
================

https://github.com/correia/Scrollvetica

What is it?
-----------

If you spend part of your time living in the future, with default Magic
Mouse and Magic Trackpad settings, you may find it difficult to switch
between the future and the present and maintain any sort of input device
sanity.

Scrollvetica is a simple hack which inverts all scrolling events on Snow
Leopard such that the effective scroll direction is in the direction of
finger movement.

Why?
----

Existing accessibility based solutions didn't work in the set of
applications I use daily.

Features
--------

- Inverts all scroll events in both the horizontal and vertical directions.
- Helvetica(*)

Known Issues
------------

Since this hack literally inverts all scroll events, scroll events which are
used for things other than scrolling will now likely be backwards.

Known examples of things which work incorrectly now:

- The volume slider in iTunes
- The volume slider in the volume menu extra
- Using scroll events to move the selection in the application switcher
	
I have no plans to "fix" this class of "bug".

Installation
------------

The latest binary release can be download from the “Releases” page:

    https://github.com/correia/Scrollvetica/releases

After downloading the latest reease, extract the archive (Safari will do this automatically.) Copy Scrollvetica to your Applications folder, and launch it.

Uninstall
---------

Click on the Scrollvetica item in the menu bar and deselect “Launch
Automatically at Log In”.

Click on the Scrollvetica item in the menu bar and select “Quit
Scrollvetica”.
  
Drag the Scrollvetica application to the Trash.

---
[*] Not really.
