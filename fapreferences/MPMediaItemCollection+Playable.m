//  Created by Jamin Guy
//  Copyright (c) 2011 Jamin Guy. All rights reserved.
//

#import "MPMediaItemCollection+Playable.h"

@implementation MPMediaItem (FAPreferences)
- (NSURL *)assetURL {
	return [self valueForProperty:MPMediaItemPropertyAssetURL];
}

- (BOOL)assetHasBeenDeleted {
	if (![self assetURL])
		return NO;
		
	NSString *urlString = [[self assetURL] absoluteString];
	BOOL assetURLPointsNowhere = ([urlString rangeOfString:@"ipod-library://item/item.(null)"].location != NSNotFound);
	return assetURLPointsNowhere;
}

- (BOOL)existsInLibrary {
	MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:[self valueForProperty:MPMediaItemPropertyPersistentID] forProperty:MPMediaItemPropertyPersistentID];
	MPMediaQuery *query = [[[MPMediaQuery alloc] init] autorelease];
	[query addFilterPredicate:predicate];
	
	return ([[query items] count] != 0);
}
@end

@implementation MPMediaItemCollection (FAPreferences)
- (BOOL)hasNoPlayableItems {
	for (MPMediaItem *mediaItem in [self items]) {
		if (![mediaItem existsInLibrary] && [mediaItem assetHasBeenDeleted])
			return YES;
	}
	
	return NO;
}
@end