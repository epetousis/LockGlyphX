# LockGlyphX
The evolution of LockGlyph. For iOS 10.  
Supports all existing LockGlyph themes.

## Beta
Join the beta by adding http://sticktron.github.com/repo to Cydia.  
Please use the issue tracker to report bugs or post suggestions.

## Localization
Please help us translate LockGlyphX into your language.  
Details: https://gist.github.com/Sticktron/03ed485c6f7f0d1ed6d442720af87821



### Notes
There were some API changes in iOS 10.2. States changed, as well as usage of PKFingerprintGlyphView vs PKSubglyphView.

#### new PKGlyphView states (iOS 10.2)
0 - Default (fingerprint)  
1 - Fingerprint scanning (animated)  
2 - ? (blank)  
3 - Loading circle (animated)  
4 - Empty circle  
5 - Move phone to reader (animated)  
6 - Custom image in circle  
7 - Success checkmark  

#### old PKGlyphView states (iOS < 10.2)
0 - Default (fingerprint)  
1 - Fingerprint scanning (animated)  
2 - Loading circle (animated)  
3 - Empty circle  
4 - Move phone to reader (animated)  
5 - Custom image (in circle ?)  
6 - Success checkmark  
