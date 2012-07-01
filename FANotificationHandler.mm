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
	[availableModel addAlbumFolderForTitle:title andMediaCollection:collection atIndex:0 insert:NO];
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

// Thanks BigBoss! (stolen from libhide)
- (void)relayout {
	SBIconModel *iconModel = [objc_getClass("SBIconModel") sharedInstance];
	
	NSSet *_visibleIconTags = MSHookIvar<NSSet *>(iconModel, "_visibleIconTags");
	NSSet *_hiddenIconTags  = MSHookIvar<NSSet *>(iconModel, "_hiddenIconTags");
	
	if (_visibleIconTags && _hiddenIconTags) {
		[iconModel setVisibilityOfIconsWithVisibleTags:_visibleIconTags hiddenTags:_hiddenIconTags];
		[iconModel relayout];
	}
}
@end