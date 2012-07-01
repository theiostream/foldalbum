//  Created by Jamin Guy
//  Copyright (c) 2011 Jamin Guy. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>

@interface MPMediaItem (FAPreferences)
- (BOOL)existsInLibrary;
- (BOOL)assetHasBeenDeleted;
@end

@interface MPMediaItemCollection (FAPreferences)
- (BOOL)hasNoPlayableItems;
@end