#import <MediaPlayer/MediaPlayer.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

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
@end

@interface SBFolderView : UIView <UITableViewDelegate, UITableViewDataSource>
- (BOOL)isAlbumFolder;
- (SBFolder *)folder;
- (NSArray *)itemKeys;
@end

@interface SBIcon : NSObject
- (id)delegate;
- (void)setDelegate:(id)delegate;
@end

@interface SBFolderIcon : SBIcon
- (SBFolderIcon *)initWithFolder:(SBFolder *)folder;
- (SBFolder *)folder;
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
- (void)addAlbumFolderForTitle:(NSString *)title andMediaCollection:(MPMediaItemCollection *)query atIndex:(NSUInteger)index insert:(BOOL)force;
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
@end

@interface SBIconModel : NSObject
+ (SBIconModel *)sharedInstance;
- (void)saveIconState;
- (void)saveAlbumFolders;
- (void)noteIconStateChangedExternally;
- (void)relayout;
- (void)setVisibilityOfIconsWithVisibleTags:(NSSet *)arg1 hiddenTags:(NSSet *)arg2;
@end