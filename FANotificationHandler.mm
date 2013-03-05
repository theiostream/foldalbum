/**
	FANotificationHandler.mm
	
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

#import "FolderAlbums.h"
#import "FAPreferencesHandler.h"
#import "FANotificationHandler.h"
#include <substrate.h>

static void StopPlayback() {
	CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.player"];
	[center sendMessageName:@"Stop" userInfo:nil];
}

static FANotificationHandler *sharedInstance_ = nil;
@implementation FANotificationHandler
+ (id)sharedInstance {
	if (!sharedInstance_)
		sharedInstance_ = [[FANotificationHandler alloc] init];
	
	return sharedInstance_;
}

- (void)addNewAlbumIconWithMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo {
	MPMediaItemCollection *collection = [NSKeyedUnarchiver unarchiveObjectWithData:[userInfo objectForKey:@"MediaCollection"]];
	NSString *title = [userInfo objectForKey:@"Title"];
	
	SBIconListModel *availableModel = [[objc_getClass("SBIconController") sharedInstance] firstAvailableModel];
	[availableModel addAlbumFolderForTitle:title plusKeyName:title andMediaCollection:collection atIndex:0 insert:NO];
}

- (void)updateKeyWithMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo {
	StopPlayback();
	
	NSString *key = [userInfo objectForKey:@"Key"];
	NSDictionary *dict = [userInfo objectForKey:@"Dictionary"];
	
	[[FAPreferencesHandler sharedInstance] updateKey:key withDictionary:dict];
}

- (void)optimizedUpdateKeyWithMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo {
	StopPlayback();
	
	NSString *key = [userInfo objectForKey:@"Key"];
	NSDictionary *dict = [userInfo objectForKey:@"Dictionary"];
	
	[[FAPreferencesHandler sharedInstance] optimizedUpdateKey:key withDictionary:dict];
}

- (void)removeKeyWithMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo {
	StopPlayback();
	
	NSString *key = [userInfo objectForKey:@"Key"];
	[[FAPreferencesHandler sharedInstance] deleteKey:key];
}

- (NSDictionary *)keyExistsWithMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo {
	NSString *key = [userInfo objectForKey:@"Key"];
	NSNumber *ret = [NSNumber numberWithBool:[[FAPreferencesHandler sharedInstance] keyExists:key]];
	
	return [NSDictionary dictionaryWithObject:ret forKey:@"Result"];
}

- (NSDictionary *)objectForKeyWithMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo {
	NSString *key = [userInfo objectForKey:@"Key"];
	id ret = [[FAPreferencesHandler sharedInstance] objectForKey:key];
	
	return [NSDictionary dictionaryWithObject:ret forKey:@"Result"];
}

- (NSDictionary *)allKeys {
	NSArray *allKeys = [[FAPreferencesHandler sharedInstance] allKeys];
	return [NSDictionary dictionaryWithObject:allKeys forKey:@"Result"];
}

// FIXME: When relayouting, there seems to be an odd bug.
// Maybe check out how Apple *fully* does its relayouting.
// Thanks BigBoss! (stolen from libhide)
- (void)relayout {
	SBIconModel *iconModel = kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 ? MSHookIvar<SBIconModel *>([objc_getClass("SBIconController") sharedInstance], "_iconModel") : [objc_getClass("SBIconModel") sharedInstance];
	
	NSSet *_visibleIconTags = MSHookIvar<NSSet *>(iconModel, "_visibleIconTags");
	NSSet *_hiddenIconTags  = MSHookIvar<NSSet *>(iconModel, "_hiddenIconTags");
	
	if (_visibleIconTags && _hiddenIconTags) {
		[iconModel setVisibilityOfIconsWithVisibleTags:_visibleIconTags hiddenTags:_hiddenIconTags];
		
		if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0)
			[iconModel layout];
		else
			[iconModel relayout];
	}
}
@end