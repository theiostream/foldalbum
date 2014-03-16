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

#ifndef kCFCoreFoundationVersionNumber_iOS_6_0
#define kCFCoreFoundationVersionNumber_iOS_6_0 793.00
#endif

#import <MediaPlayer/MediaPlayer.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#import "FACalloutView.h"

typedef struct {
	int direction;
	CGRect rect;
} SBNotchInfo;

typedef struct {
    UIImage *image;
} MPMediaItemArtworkInternal;

@interface AVAudioSession : NSObject
+ (id)sharedInstance;
- (BOOL)isOtherAudioPlaying;
@end

@interface SBApplication : NSObject
@end

@interface SBApplicationController : NSObject
+ (id)sharedInstance;
- (SBApplication *)applicationWithDisplayIdentifier:(NSString *)displayIdentifier;
@end

@interface SBMediaController : NSObject
+ (BOOL)applicationCanBeConsideredNowPlaying:(SBApplication *)playing;
- (BOOL)isPlaying;
@end

@interface SBFolderTitleLabel : UILabel
@end

@interface ISIconSupport : NSObject
+ (id)sharedInstance;
- (BOOL)addExtension:(NSString *)extension;
@end

@interface SBFolder : NSObject
- (Class)listModelClass;
- (NSString *)displayName;
- (void)setDisplayName:(NSString *)displayName;
@end

@interface FAFolder : SBFolder
- (MPMediaItemCollection *)mediaCollection;
- (void)setMediaCollection:(MPMediaItemCollection *)mediaCollection;
- (NSString *)keyName;
- (void)setKeyName:(NSString *)key;
@end

@interface SBFolderBackgroundView : UIView
+ (CGFloat)cornerRadiusToInsetContent;
@end

@interface SBFolderView : UIView
- (NSArray *)iconListViews;
@end

@interface FACommonFolderView : SBFolderView <UITableViewDelegate, UITableViewDataSource>
- (NSArray *)itemKeys;
- (void)rotateToOrientation:(int)orientation;
- (FAFolder *)folder;
- (void)initializeProgTimer;
- (void)initializeControlViewWithSuperview:(UIView *)superview haveExtraView:(BOOL)extra;
- (Class)detailSliderClass;
@end

@interface FAFolderView : FACommonFolderView <FACalloutViewDelegate>
- (UILabel *)groupLabel;
@end

@interface FAFloatyFolderView : FACommonFolderView <UITableViewDelegate, UITableViewDataSource>
- (void)setupArtistLabel;
- (void)setupFolderAlbumsInView:(UIView *)view;
- (void)createFolderAlbumsInView:(UIView *)view;
@end

@interface SBIcon : NSObject
- (id)delegate;
- (void)setDelegate:(id)delegate;
@end

@interface SBFolderIcon : SBIcon
- (SBFolderIcon *)initWithFolder:(SBFolder *)folder;
- (SBFolder *)folder;
- (NSString *)displayName;
- (void)updateLabel;
@end

@interface SBIconView : UIView
- (void)setShowsCloseBox:(BOOL)box;
@end

@interface SBFolderIconView : SBIconView
- (BOOL)canReceiveGrabbedIcon:(id)icon;
- (SBFolder *)folder;
- (SBIcon *)icon;
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
- (void)insertIcon:(SBIcon *)icon atIndex:(NSUInteger)index moveNow:(BOOL)moveNow;
@end

@interface SBRootFolderController : NSObject
- (SBFolderView *)contentView;
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
- (SBRootFolderController *)_rootFolderController;
@end

@interface SBIconModel : NSObject
+ (SBIconModel *)sharedInstance;
- (void)saveIconState;
- (void)saveAlbumFolders;
- (void)noteIconStateChangedExternally;
- (void)layout;
- (void)relayout;
- (void)setVisibilityOfIconsWithVisibleTags:(NSSet *)arg1 hiddenTags:(NSSet *)arg2;
@end

@interface MPDetailSlider : UISlider
+ (CGFloat)defaultHeight;
- (id)initWithFrame:(CGRect)frame style:(int)style;
- (void)setAllowsDetailScrubbing:(BOOL)allows;
- (void)setDuration:(NSTimeInterval)duration;
- (void)setDelegate:(id)delegate;
@end

@interface SBIconGridImage : UIImage
@end

@interface UIApplication (FASpringBoard)
- (void)launchMusicPlayerSuspended;
@end

@interface MPMusicPlayerController (FAMusicPlayerControllerPrivate)
- (MPMediaQuery *)queueAsQuery;
@end

@interface FAFolderIcon : SBFolderIcon
@end

@interface SBFolderIconImageView : UIImageView
- (SBFolderIcon *)_folderIcon;
@end
