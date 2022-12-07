<p align="left " >
  <img src="http://i.imgur.com/76RElTT.png" alt="Popcorn Time" title="Popcorn Time">
</p>

## Popcorn Time for tvOS | iOS | macOS

[![Platform](https://img.shields.io/badge/platform-iOS%20%7C%20tvOS%20%7C%20macOS-lightgrey.svg?style=flat)](https://github.com/PopcornTimeTV)
[![License](https://img.shields.io/badge/license-GPL_v3-373737.svg?style=flat)](https://github.com/PopcornTimeTV/PopcornTimeTV/blob/master/LICENSE.md)

PopcornTimeTV is an Apple TV, iPhone, iPad and Mac application to torrent movies and tv shows for streaming.

## Compile yourself?

Build instructions:

``` bash
$ git clone https://github.com/alextud/PopcornTimeTV.git
$ cd PopcornTimeTV/
$ open PopcornTime.xcodeproj
```

IN XCODE:

```
Select PopcornTime (tvOS) as target and set your Apple TV 4K as the build output (you may have to first connect your xcode to your Apple TV 4K to have it be available as output) (and I set my deployment target as 15.0)
Go into General tab and change the bundle identifier to com.[your_own_indentifier].PopcornTime
Go into Signing & Capabilities tab and set automatically manage signing, and select your team so there are no errors
switch to TopShelf target (from tvOS)
Go into General tab and change the bundle identifier to com.[your_own_indentifier].PopcornTime.TopShelf
GO TO APPLE DEVELOPER WEBSITE and log in
Go to Certificates, Identifiers & Profiles
In Devices tab, make sure your Apple TV is registered
In Profiles tab, make sure you have a profile created for your Apple TV, and download it
GO BACK TO XCODE
Still in TopShelf target, switch to Signing & Capabilities tab
Select the profile you just downloaded as the Provisioning profile (automatic signing should be unchecked)
Click on the build button, and after some time the app should appear on your Apple TV 4K
```

Here were some of the gotchas:

It was tricky to wirelessly connect to my Apple TV, the key was to go into Settings > Remotes and Devices > Remote App and Devices on the Apple TV first, that allowed Xcode to find it
There was a lot of trial and error creating the device and profile up on developer.apple.com (you will need the UUID of your Apple TV, which you can get from Xcode when you have connected to it)


To change VLCKit version, edit VLCKit/get-vlc-frameworks.sh file

## License

If you distribute a copy or make a fork of the project, you have to credit this project as source.

This program is free software: you can redistribute it and/or modify it under the terms of the GNU General Public License as published by the Free Software Foundation, either version 3 of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with this program.  If not, see http://www.gnu.org/licenses/.

Note: some dependencies are external libraries, which might be covered by a different license compatible with the GPLv3. They are mentioned in [NOTICE.md](https://github.com/PopcornTimeTV/PopcornTimeTV/blob/master/NOTICE.md).


**This project and the distribution of this project is not illegal, nor does it violate _any_ DMCA laws. The use of this project, however, may be illegal in your area. Check your local laws and regulations regarding the use of torrents to watch potentially copyrighted content. The maintainers of this project do not condone the use of this project for anything illegal, in any state, region, country, or planet. _Please use at your own risk_.**

***


Copyright (c) 2017 Popcorn Time Foundation - Released under the [GPL V3 license](https://github.com/PopcornTimeTV/PopcornTimeTV/LICENSE.md).
