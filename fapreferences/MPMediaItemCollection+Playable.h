/**
	fapreferences/MPMediaItemCollection+Playable.h
	
	FoldMusic
  	version 1.2.0, July 15th, 2012

  Copyright (C) 2012 theiostream

  This software is provided 'as-is', without any express or implied
  warranty.  In no event will the authors be held liable for any damages
  arising from the use of this software.

  Permission is granted to anyone to use this software for any purpose,
  including commercial applications, and to alter it and redistribute it
  freely, subject to the following restrictions:

  1. The origin of this software must not be misrepresented; you must not
     claim that you wrote the original software. If you use this software
     in a product, an acknowledgment in the product documentation would be
     appreciated but is not required.
  2. Altered source versions must be plainly marked as such, and must not be
     misrepresented as being the original software.
  3. This notice may not be removed or altered from any source distribution.

  theiostream
  matoe@matoe.co.cc
**/

/**
RETRIEVED FROM THE 'JGMediaPickerController' PROJECT.
CONTAINS MODIFIED SOURCE CODE ORIGINALLY BY THE THIRD-PARTY:

//  Created by Jamin Guy
//  Copyright (c) 2011 Jamin Guy. All rights reserved.
**/

#import <MediaPlayer/MediaPlayer.h>

@interface MPMediaItem (FAPreferences)
- (BOOL)existsInLibrary;
- (BOOL)assetHasBeenDeleted;
@end

@interface MPMediaItemCollection (FAPreferences)
- (BOOL)hasNoPlayableItems;
@end