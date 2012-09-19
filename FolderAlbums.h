/**
	FolderAlbums.h
	
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

#import <MediaPlayer/MediaPlayer.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "FACalloutView.h"

@interface SBApplication : NSObject
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (SBApplication *)applicationWithDisplayIdentifier:(NSString *)displayIdentifier;
@end

@interface SBMediaController : NSObject
+ (BOOL)applicationCanBeConsideredNowPlaying:(SBApplication *)playing;
@end

@interface SBFolderTitleLabel : UILabel
@end

@interface ISIconSupport : NSObject
+ (id)sharedInstance;
- (BOOL)addExtension:(NSString *)extension;
@end

@interface SBFolder : NSObject
- (NSString *)displayName;
- (void)setDisplayName:(NSString *)displayName;
@end

@interface FAFolder : SBFolder
- (MPMediaItemCollection *)mediaCollection;
- (void)setMediaCollection:(MPMediaItemCollection *)mediaCollection;
- (NSString *)keyName;
- (void)setKeyName:(NSString *)key;
@end

@interface SBFolderView : UIView
@end

@interface FAFolderView : SBFolderView <UITableViewDelegate, UITableViewDataSource, FACalloutViewDelegate>
- (FAFolder *)folder;
- (UILabel *)groupLabel;
- (NSArray *)itemKeys;
@end

@interface SBIcon : NSObject
- (id)delegate;
- (void)setDelegate:(id)delegate;
@end

@interface SBFolderIcon : SBIcon
- (SBFolderIcon *)initWithFolder:(SBFolder *)folder;
- (SBFolder *)folder;
- (NSString *)displayName;
@end

@interface SBIconView : UIView
- (void)setShowsCloseBox:(BOOL)box;
@end

@interface SBFolderIconView : SBIconView
- (BOOL)canReceiveGrabbedIcon:(id)icon;
- (SBFolder *)folder;
@end

@interface SBIconViewMap
+ (id)homescreenMap;
- (SBIconView *)mappedIconViewForIcon:(SBIcon *)icon;
@end

@interface SBIconListModel : NSObject
+ (NSUInteger)maxIcons;
- (void)addAlbumFolderForTitle:(NSString *)title plusKeyName:(NSString *)keyName andMediaCollection:(MPMediaItemCollection *)query atIndex:(NSUInteger)index insert:(BOOL)force;
- (NSArray *)icons;
- (void)addIcon:(SBIcon *)icon;
- (void)insertIcon:(SBIcon *)icon atIndex:(NSUInteger *)index;
- (BOOL)isFull;
- (NSUInteger)index;
- (NSUInteger)firstFreeSlotIndex;
- (NSUInteger)indexForIcon:(SBIcon *)icon;
@end

@interface SBIconListView : UIView
- (SBIconListModel *)model;
- (void)layoutIconsNow;
@end

@interface SBIconController : NSObject
+ (SBIconController *)sharedInstance;
- (void)addNewAlbumIconWithUnusedMessageName:(NSString *)messageName userInfo:(NSDictionary *)userInfo;
- (void)commitAlbumFolders;
- (SBIconListView *)currentRootIconList;
- (SBIconListView *)rootIconListAtIndex:(NSUInteger)index;
- (SBIconListModel *)firstAvailableModel;
- (NSArray *)rootIconLists;
- (void)updateCurrentIconListIndexAndVisibility;
- (void)scrollToIconListAtIndex:(int)index animate:(BOOL)animate;
- (id)addEmptyListViewForFolder:(id)folder;
@end

@interface SBIconModel : NSObject
+ (SBIconModel *)sharedInstance;
- (void)saveIconState;
- (void)saveAlbumFolders;
- (void)noteIconStateChangedExternally;
- (void)relayout;
- (void)setVisibilityOfIconsWithVisibleTags:(NSSet *)arg1 hiddenTags:(NSSet *)arg2;
@end

@interface MPDetailSlider : UISlider
+ (CGFloat)defaultHeight;
- (void)setAllowsDetailScrubbing:(BOOL)allows;
- (void)setDuration:(NSTimeInterval)duration;
- (void)setDelegate:(id)delegate;
@end

@interface UIApplication (FASpringBoard)
- (void)launchMusicPlayerSuspended;
@end

@interface MPMusicPlayerController (FAMusicPlayerControllerPrivate)
- (MPMediaQuery *)queueAsQuery;
@end