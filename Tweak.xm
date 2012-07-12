/*
	Dev-related TODOs:
	(user related ones are in a note inside Notes.app on my iPhone)
	
	- libpsicons
	
	-- better FAFolder
	-- work on category for MPMediaCollection to make playlist vs. album easier
	-- work out copied functions
	-- FAMediaPickerController sucks.
	--- increase scrolling performance.
*/

// I used to be a good developer.
// Then I started using goto.

// FAPreferences was an accidental name.

/*%%%%%%%%%%%
%% Imports
%%%%%%%%%%%*/

#import "FolderAlbums.h"
#import "FAFolderCell.h"
#import "FAPreferencesHandler.h"
#import "FANotificationHandler.h"
#import "UIImage+Resize.h"
#import "FACalloutView.h"

/*%%%%%%%%%%%
%% Macros
%%%%%%%%%%%*/

#define SBLocalizedString(key) \
	[[NSBundle mainBundle] localizedStringForKey:key value:@"None" table:@"SpringBoard"]

/*%%%%%%%%%%%
%% Declarations
%%%%%%%%%%%*/

static NSUInteger idx = 0;

static char _mediaCollectionKey;
static char _keyNameKey;

static UIView *g_content = nil;
static BOOL fromVolume = NO;

static NSTimer *seekTimer = nil;
static BOOL wasSeeking = NO;

static CGRect groupFrame;

/*%%%%%%%%%%%
%% Functions
%%%%%%%%%%%*/

void _FADrawLineAtPath(UIView *view, CGPathRef path) {
	CAShapeLayer *shape = [CAShapeLayer layer];
	[shape setLineWidth:1.f];
	[shape setLineCap:kCALineCapRound];
	[shape setStrokeColor:[UIColorFromHexWithAlpha(0xFFFFFF, 0.37) CGColor]];
	[shape setPath:path];
	
	[[view layer] addSublayer:shape];
}

/*%%%%%%%%%%%
%% Subclasses
%%%%%%%%%%%*/

%subclass FAFolder : SBFolder
- (Class)folderViewClass {
	return %c(FAFolderView);
}

- (NSArray *)allIcons {
	NSMutableArray *ret = [NSMutableArray array];
	SBIcon *empty = [[[%c(SBIcon) alloc] init] autorelease];
	
	for (int i=0; i<11; i++)
		[ret addObject:empty];
		
	return ret;
}

%new(@@:)
- (MPMediaItemCollection *)mediaCollection {
	return objc_getAssociatedObject(self, &_mediaCollectionKey);
}

%new(v@:@)
- (void)setMediaCollection:(MPMediaItemCollection *)mediaCollection {
	objc_setAssociatedObject(self, &_mediaCollectionKey, mediaCollection, OBJC_ASSOCIATION_RETAIN);
}

%new(@@:)
- (NSString *)keyName {
	return objc_getAssociatedObject(self, &_keyNameKey);
}

%new(v@:@)
- (void)setKeyName:(NSString *)keyName {
	objc_setAssociatedObject(self, &_keyNameKey, keyName, OBJC_ASSOCIATION_RETAIN);
}

- (void)dealloc {
	%orig;
	objc_removeAssociatedObjects(self);
}
%end

// TODO: Check exactly how SBNewsstandFolderView handles this
%subclass FAFolderView : SBFolderView
%new(@@:)
- (FAFolder *)folder {
	return MSHookIvar<FAFolder *>(self, "_folder");
}

- (void)textFieldDidEndEditing:(id)textField {
	%orig;
	
	if ([[textField text] isEqualToString:@""])
		[textField setText:[(FAFolder *)[self folder] keyName]];
	
	NSDictionary *update = [NSDictionary dictionaryWithObject:[textField text] forKey:@"fakeTitle"];
	[[FAPreferencesHandler sharedInstance] optimizedUpdateKey:[(FAFolder *)[self folder] keyName] withDictionary:update];
	
	UILabel *&groupLabel = MSHookIvar<UILabel *>(self, "_label");
	[groupLabel setFrame:groupFrame];
}

- (void)setIconListView:(UIView *)view {
	idx = 0;
	
	SBFolder *folder = [self folder];
	MPMediaItemCollection *collection = [(FAFolder *)folder mediaCollection];
	
	UILabel *&groupLabel = MSHookIvar<UILabel *>(self, "_label");
	[groupLabel setFrame:(CGRect){{groupLabel.frame.origin.x-7, groupLabel.frame.origin.y}, {230, 20}}];
	groupFrame = [groupLabel frame];
	[groupLabel setFont:[[groupLabel font] fontWithSize:20.f]];
	[groupLabel setTextAlignment:UITextAlignmentLeft];
	[groupLabel setAdjustsFontSizeToFitWidth:YES];
	[groupLabel setMinimumFontSize:16.f];
	
	CGRect subtitleLabel = CGRectMake(groupLabel.frame.origin.x, groupLabel.frame.origin.y+23, 241, 16);
	if ([[groupLabel font] pointSize] < 20.f) {
		[groupLabel setFrame:(CGRect){{groupLabel.frame.origin.x, groupLabel.frame.origin.y+3}, {groupLabel.frame.size.width, [[groupLabel font] pointSize]}}];
		subtitleLabel.origin.y -= (subtitleLabel.origin.y-[[groupLabel font] pointSize]);
	}
	
	UITextField *&textField = MSHookIvar<UITextField *>(self, "_textField");
	[textField setPlaceholder:[(FAFolder *)[self folder] keyName]];
	[textField setFrame:(CGRect){{groupLabel.bounds.origin.x+5, groupLabel.bounds.origin.y+3}, {groupLabel.bounds.size.width, textField.frame.size.height-2}}];
	
	if (![collection isKindOfClass:[MPMediaPlaylist class]]) {
		UILabel *artistLabel = [[[UILabel alloc] initWithFrame:subtitleLabel] autorelease];
		[artistLabel setBackgroundColor:[UIColor clearColor]];
		[artistLabel setFont:[[groupLabel font] fontWithSize:16.f]];
		[artistLabel setAdjustsFontSizeToFitWidth:YES];
		[artistLabel setMinimumFontSize:12.f];
		[artistLabel setTextColor:[UIColor whiteColor]];
		[artistLabel setText:[[collection representativeItem] valueForProperty:MPMediaItemPropertyArtist]];
		
		if ([[artistLabel font] pointSize] < 16.f) {
			[artistLabel setFrame:(CGRect){artistLabel.frame.origin, {artistLabel.frame.size.width, [[artistLabel font] pointSize]}}];
		}
		
		[self addSubview:artistLabel];
	}
	
	else
		subtitleLabel.origin.y -= 20;
	
	UIView *controllerContent = [[[UIView alloc] initWithFrame:CGRectMake(255, groupLabel.bounds.origin.y+5, 60, 25)] autorelease];
	UIImage *musicImage = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/music.png"] resizedImage:CGSizeMake(25, 25) interpolationQuality:kCGInterpolationHigh];
	UIImage *speakerImage = [[UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/speaker.png"] resizedImage:CGSizeMake(22, 22) interpolationQuality:kCGInterpolationHigh];
	
	UIButton *musicButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[musicButton setFrame:CGRectMake(0, 0, 25, 25)];
	[musicButton setImage:musicImage forState:UIControlStateNormal];
	[musicButton addTarget:self action:@selector(showControlsCallout) forControlEvents:UIControlEventTouchUpInside];
	
	UIButton *speakerButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[speakerButton setFrame:CGRectMake(35, 0, 25, 25)];
	[speakerButton setImage:speakerImage forState:UIControlStateNormal];
	[speakerButton addTarget:self action:@selector(showVolumeCallout:) forControlEvents:UIControlEventTouchUpInside];
	
	[controllerContent addSubview:musicButton];
	[controllerContent addSubview:speakerButton];
	[self addSubview:controllerContent];
	
	CGFloat hei = subtitleLabel.origin.y+25;
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, hei);
	CGPathAddLineToPoint(path, NULL, 320, hei);
	_FADrawLineAtPath(self, path);
	CGPathRelease(path);
	
	CGRect tableFrame = CGRectMake(0, subtitleLabel.origin.y+25, 320, self.bounds.size.height-(subtitleLabel.origin.y+25));
	UITableView *dataTable = [[[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain] autorelease];
	[dataTable setDelegate:self];
	[dataTable setDataSource:self];
	[dataTable setBackgroundColor:[UIColor clearColor]];
	[dataTable setSeparatorColor:UIColorFromHexWithAlpha(0xFFFFFF, 0.37)];
	[self addSubview:dataTable];
	
	UISwipeGestureRecognizer *rig = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextItem:)] autorelease];
	[rig setDirection:UISwipeGestureRecognizerDirectionRight];
	UISwipeGestureRecognizer *lef = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextItem:)] autorelease];
	[lef setDirection:UISwipeGestureRecognizerDirectionLeft];
	
	[dataTable addGestureRecognizer:rig];
	[dataTable addGestureRecognizer:lef];
}

%new(v@:)
- (void)showControlsCallout {
	CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.player"];
	
	MPMusicPlaybackState state;
	NSData *nowPlayingData = [[center sendMessageAndReceiveReplyName:@"NowPlayingItem" userInfo:nil] objectForKey:@"Item"];
	if (nowPlayingData)
		state = [[[center sendMessageAndReceiveReplyName:@"PlaybackState" userInfo:nil] objectForKey:@"State"] integerValue];
	else
		state = MPMusicPlaybackStateStopped;
	
	UIView *content = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 130, 35)] autorelease];
	
	UIImage *play = [UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/play.png"];
	UIImage *pause = [UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/pause.png"];
	UIImage *backward = [UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/backward.png"];
	UIImage *forward = [UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/forward.png"];
	
	UIButton *backwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[backwardButton setFrame:CGRectMake(10, 2.5, 30, 30)];
	[backwardButton setImage:backward forState:UIControlStateNormal];
	[backwardButton addTarget:self action:@selector(pressedBackwardButton) forControlEvents:UIControlEventTouchDown];
	[backwardButton addTarget:self action:@selector(releasedBackwardButton) forControlEvents:UIControlEventTouchUpInside];
	[backwardButton addTarget:self action:@selector(releasedBackwardButton) forControlEvents:UIControlEventTouchUpOutside];
	
	UIButton *playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[playPauseButton setFrame:CGRectMake(50, 2.5, 30, 30)];
	[playPauseButton setImage:(state == MPMusicPlaybackStatePlaying ? pause : play) forState:UIControlStateNormal];
	[playPauseButton addTarget:self action:@selector(clickedPlayButton:) forControlEvents:UIControlEventTouchUpInside];
	
	UIButton *forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[forwardButton setFrame:CGRectMake(90, 2.5, 30, 30)];
	[forwardButton setImage:forward forState:UIControlStateNormal];
	[forwardButton addTarget:self action:@selector(pressedForwardButton) forControlEvents:UIControlEventTouchDown];
	[forwardButton addTarget:self action:@selector(releasedForwardButton) forControlEvents:UIControlEventTouchUpInside];
	[forwardButton addTarget:self action:@selector(releasedForwardButton) forControlEvents:UIControlEventTouchUpOutside];
	
	[content addSubview:backwardButton];
	[content addSubview:playPauseButton];
	[content addSubview:forwardButton];
	
	FACalloutView *alert = [[[FACalloutView alloc] init] autorelease];
	[alert placeQuitButtonInView:self];
	
	[alert setCenteredView:content animated:YES];
	[alert setAnchorPoint:CGPointMake(267.5, 25) boundaryRect:[[UIScreen mainScreen] applicationFrame] animate:YES];
	[self addSubview:alert];
}

%new(v@:@)
- (void)clickedPlayButton:(UIButton *)button {
	CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.player"];
	
	MPMusicPlaybackState state;
	NSData *nowPlayingData = [[center sendMessageAndReceiveReplyName:@"NowPlayingItem" userInfo:nil] objectForKey:@"Item"];
	if (nowPlayingData)
		state = [[[center sendMessageAndReceiveReplyName:@"PlaybackState" userInfo:nil] objectForKey:@"State"] integerValue];
	else {
		state = MPMusicPlaybackStateStopped;
		NSData *queue = [NSKeyedArchiver archivedDataWithRootObject:[(FAFolder *)[self folder] mediaCollection]];
		[center sendMessageName:@"SetQuery" userInfo:[NSDictionary dictionaryWithObject:queue forKey:@"Collection"]];
	}
	
	if (state == MPMusicPlaybackStatePlaying) {
		[button setImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/play.png"] forState:UIControlStateNormal];
		[center sendMessageName:@"Pause" userInfo:nil];
	}
	
	else {
		[button setImage:[UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/pause.png"] forState:UIControlStateNormal];
		[center sendMessageName:@"Play" userInfo:nil];
	}
}

%new(v@:)
- (void)pressedForwardButton {
	seekTimer = [NSTimer scheduledTimerWithTimeInterval:.5f target:self selector:@selector(_seekForward) userInfo:nil repeats:NO];
}

%new(v@:)
- (void)pressedBackwardButton {
	seekTimer = [NSTimer scheduledTimerWithTimeInterval:.5f target:self selector:@selector(_seekBackward) userInfo:nil repeats:NO];
}

%new(v@:)
- (void)_seekForward {
	CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.player"];
	[center sendMessageName:@"SeekForward" userInfo:nil];
	
	wasSeeking = YES;
}

%new(v@:)
- (void)_seekBackward {
	CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.player"];
	[center sendMessageName:@"SeekBackward" userInfo:nil];
	
	wasSeeking = YES;
}

%new(v@:)
- (void)releasedForwardButton {
	CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.player"];
	
	if (wasSeeking) {
		[center sendMessageName:@"EndSeeking" userInfo:nil];
		wasSeeking = NO;
		
		return;
	}
	
	[seekTimer invalidate];
	[center sendMessageName:@"NextItem" userInfo:nil];
}

%new(v@:)
- (void)releasedBackwardButton {
	CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.player"];
	
	if (wasSeeking) {
		[center sendMessageName:@"EndSeeking" userInfo:nil];
		wasSeeking = NO;
		
		return;
	}
	
	[seekTimer invalidate];
	
	if ([[[center sendMessageAndReceiveReplyName:@"PlaybackTime" userInfo:nil] objectForKey:@"Interval"] integerValue] > 1)
		[center sendMessageName:@"SeekBeginning" userInfo:nil];
	else
		[center sendMessageName:@"PreviousItem" userInfo:nil];
}

%new(v@:@)
- (void)showVolumeCallout:(UIButton *)btn {
	FACalloutView *alert = [[[FACalloutView alloc] init] autorelease];
	[alert placeQuitButtonInView:self];
	[alert setFADelegate:self];
	
	fromVolume = YES;
	g_content = [btn superview];
	[UIView animateWithDuration:0.2f animations:^{
		CGRect fr = [g_content frame];
		fr.origin.x -= 20;
		[g_content setFrame:fr];
	}];
	
	MPVolumeView *slider = [[[MPVolumeView alloc] initWithFrame:CGRectMake(0, 0, 200.0, 20)] autorelease];
	[alert setCenteredView:slider animated:YES];
	[alert setAnchorPoint:CGPointMake(287.5, 25) boundaryRect:[[UIScreen mainScreen] applicationFrame] animate:YES];
	[self addSubview:alert];
}

%new(v@:@)
- (void)calloutViewDidExit:(FACalloutView *)callout {
	if (fromVolume) {
		[UIView animateWithDuration:0.2f animations:^{
			CGRect fr = [g_content frame];
			fr.origin.x += 20;
			[g_content setFrame:fr];
		}];
	}
	
	fromVolume = NO;
}

// I do hope this doesn't leak.
// Also, yay for vim!
%new(@@:)
- (NSArray *)itemKeys {
	NSArray *_itemKeys = !([[(FAFolder *)[self folder] mediaCollection] isKindOfClass:[MPMediaPlaylist class]]) ?
		[NSArray arrayWithObjects:MPMediaItemPropertyPlaybackDuration, MPMediaItemPropertyPlayCount, nil] :
		[NSArray arrayWithObjects:MPMediaItemPropertyPlaybackDuration, MPMediaItemPropertyPlayCount, MPMediaItemPropertyArtist, MPMediaItemPropertyAlbumTitle, nil];
	
	return _itemKeys;
}

%new(v@:@)
- (void)nextItem:(UIGestureRecognizer *)rec {
	NSArray *_itemKeys = [self itemKeys];
	
	idx++;
	idx = idx>=[_itemKeys count] ? 0 : idx;
	
	for (FAFolderCell *cell in [(UITableView *)[rec view] visibleCells])
		[cell setDetailProperty:[_itemKeys objectAtIndex:idx] change:YES];
}

%new(f@:@@)
- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return 38.f;
}

%new(i@:@@)
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
	return [[[(FAFolder *)[self folder] mediaCollection] items] count];
}

%new(i@:@)
- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

%new(@@:@@)
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	static NSString *CellIdentifier = @"FAFolderCellIdentifier";
	
	NSArray *items = [[(FAFolder *)[self folder] mediaCollection] items];
	MPMediaItem *item = [items objectAtIndex:[indexPath row]];
	
	FAFolderCell *cell = (FAFolderCell *)[tableView dequeueReusableCellWithIdentifier:CellIdentifier];
	if (!cell)
		cell = [[[FAFolderCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:CellIdentifier] autorelease];
	
	[cell setDetailProperty:[[self itemKeys] objectAtIndex:idx] change:NO];
	[cell setMediaItem:item];
	
	return cell;
}

%new(v@:@@)
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	NSData *queue, *itemData;
	
	CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.player"];
	NSArray *items = [[(FAFolder *)[self folder] mediaCollection] items];
	
	MPMediaItem *cellItem = [items objectAtIndex:[indexPath row]];
	NSData *nowPlayingData = [[center sendMessageAndReceiveReplyName:@"NowPlayingItem" userInfo:nil] objectForKey:@"Item"];
	
	if (nowPlayingData) {
		MPMediaItem *nowPlayingItem = [NSKeyedUnarchiver unarchiveObjectWithData:nowPlayingData];
		MPMusicPlaybackState state = [[[center sendMessageAndReceiveReplyName:@"PlaybackState" userInfo:nil] objectForKey:@"State"] integerValue];
	
		NSNumber *nowPlayingPersistent = [nowPlayingItem valueForProperty:MPMediaItemPropertyPersistentID];
		NSNumber *cellItemPersistent = [cellItem valueForProperty:MPMediaItemPropertyPersistentID];
	
		if ([nowPlayingPersistent compare:cellItemPersistent] == NSOrderedSame) {
			if (state == MPMusicPlaybackStatePlaying) {
				[center sendMessageName:@"Pause" userInfo:nil];
				goto end;
			}
		
			else if (state == MPMusicPlaybackStatePaused) {
				goto play;
			}
		}
	}
	
	queue = [NSKeyedArchiver archivedDataWithRootObject:[(FAFolder *)[self folder] mediaCollection]];
	[center sendMessageName:@"SetQuery" userInfo:[NSDictionary dictionaryWithObject:queue forKey:@"Collection"]];
	
	itemData = [NSKeyedArchiver archivedDataWithRootObject:cellItem];
	[center sendMessageName:@"SetNowPlaying" userInfo:[NSDictionary dictionaryWithObject:itemData forKey:@"Item"]];
	
	play:
	[center sendMessageName:@"Play" userInfo:nil];
	
	end:
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
}
%end

/*%%%%%%%%%%%
%% Hooks
%%%%%%%%%%%*/

// Add folders
%hook SBIconListModel
%new(I@:)
- (NSUInteger)index {
	NSUInteger ret = [[[%c(SBIconController) sharedInstance] rootIconLists] indexOfObjectPassingTest:^(id obj, NSUInteger idx, BOOL *stop){
		return ([[obj model] isEqual:self]);
	}];
	
	return ret;
}

%new(v@:@@Ic)
- (void)addAlbumFolderForTitle:(NSString *)title plusKeyName:(NSString *)keyName andMediaCollection:(MPMediaItemCollection *)collection atIndex:(NSUInteger)index insert:(BOOL)insert {
	FAFolder *folder = [[[%c(FAFolder) alloc] init] autorelease];
	[folder setDisplayName:title];
	[folder setKeyName:keyName];
	[folder setMediaCollection:collection];
	
	SBFolderIcon *icon = [[[%c(SBFolderIcon) alloc] initWithFolder:folder] autorelease];
	[icon setDelegate:[%c(SBIconController) sharedInstance]];
	
	NSUInteger modelIndex = [self index];
	NSUInteger iconIndex = [self firstFreeSlotIndex];
	
	if (!insert) {
		NSMutableDictionary *dict = [NSMutableDictionary dictionary];
		[dict setObject:[NSNumber numberWithInteger:(NSInteger)modelIndex] forKey:@"listIndex"];
		[dict setObject:[NSNumber numberWithInteger:(NSInteger)iconIndex] forKey:@"iconIndex"];
		
		[[FAPreferencesHandler sharedInstance] optimizedUpdateKey:title withDictionary:dict];
		
		// NOTE: Upon calling -addIcon:, the icon gets placed into some weird place.
		// This is fixed by calling -insertIcon:atIndex:, yet we might be doing
		// something which probably breaks it. It should be fixed.
		[self insertIcon:icon atIndex:&iconIndex];
	}
	
	else
		[self insertIcon:icon atIndex:&index];
	
	[[%c(SBIconController) sharedInstance] updateCurrentIconListIndexAndVisibility];
}
%end

%hook SBFolderIconView
- (BOOL)canReceiveGrabbedIcon:(id)icon {
	if ([[self folder] isKindOfClass:%c(FAFolder)])
		return NO;
	
	if ([icon isKindOfClass:%c(SBFolderIcon)])
		if ([[icon folder] isKindOfClass:%c(FAFolder)])
			return NO;
	
	return %orig;
}
%end

%hook SBFolderIcon
- (UIImage *)getIconImage:(int)flag {
	if ([[self folder] isKindOfClass:%c(FAFolder)]) {
		MPMediaItemCollection *collection = [(FAFolder *)[self folder] mediaCollection];
		
		if (![collection isKindOfClass:[MPMediaPlaylist class]]) {
			MPMediaItem *_item = [collection representativeItem];
			MPMediaItemArtwork *artwork = [_item valueForProperty:MPMediaItemPropertyArtwork];
			
			// NOTE: The size passed to -imageWithSize: does not matter at all.
			// NOTE: This function does not exist.
			UIImage *artworkImage = FAMakeThisImageBeLikeAnIcon([artwork imageWithSize:CGSizeMake(42, 42)]);
			
			if (artworkImage)
				return artworkImage;
		}
		
		return [[UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/folder.png"] resizedImage:CGSizeMake(42, 42) interpolationQuality:kCGInterpolationHigh];
	}
	
	return %orig;
}
%end

/*%hook SBFolderIcon
- (UIImage *)gridImageWithSkipping:(BOOL)skipping {
	if ([[self folder] isKindOfClass:%c(FAFolder)]) {
		MPMediaItemCollection *collection = [(FAFolder *)[self folder] mediaCollection];
		
		if (![collection isKindOfClass:[MPMediaPlaylist class]]) {
			MPMediaItem *_item = [collection representativeItem];
			MPMediaItemArtwork *artwork = [_item valueForProperty:MPMediaItemPropertyArtwork];
			UIImage *artworkImage = [[artwork imageWithSize:CGSizeMake(42, 42)] resizedImage:CGSizeMake(42, 42) interpolationQuality:kCGInterpolationHigh];
			
			if (artworkImage)
				return artworkImage;
		}
		
		return [[UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/folder.png"] resizedImage:CGSizeMake(42, 42) interpolationQuality:kCGInterpolationHigh];
	}
	
	return %orig;
}
%end*/

// Thanks DHowett! (stolen from cydelete)
%hook SBFolderIcon
- (BOOL)allowsUninstall {
	if ([[self folder] isKindOfClass:%c(FAFolder)])
		return YES;
	
	return %orig;
}

- (NSString *)uninstallAlertTitle {
	if ([[self folder] isKindOfClass:%c(FAFolder)])
		return [NSString stringWithFormat:SBLocalizedString(@"UNINSTALL_ICON_TITLE"), [self displayName]];
	
	return %orig;
}

- (NSString *)uninstallAlertBody {
	if ([[self folder] isKindOfClass:%c(FAFolder)])
		return [NSString stringWithFormat:@"Are you sure you want to delete the \"%@\" folder? Your music data will be preserved.", [self displayName]];
	
	return %orig;
}

- (void)completeUninstall {
	%orig;
	
	if ([[self folder] isKindOfClass:%c(FAFolder)]) {
		// FIXME: Use FAPreferencesHandler instead of FANotificationHandler
		[[FANotificationHandler sharedInstance] removeKeyWithMessageName:nil userInfo:[NSDictionary dictionaryWithObject:[(FAFolder *)[self folder] keyName] forKey:@"Key"]];
	}
}
%end

%hook SBIconController
%new(@@:)
- (NSMutableArray *)rootIconLists {
	return MSHookIvar<NSMutableArray *>(self, "_rootIconLists");
}

%new(@@:)
- (SBIconListModel *)firstAvailableModel {
	NSArray *rootIconLists = [self rootIconLists];
	for (SBIconListView *view in rootIconLists) {
		SBIconListModel *model = [view model];
		if (![model isFull])
			return model;
	}
	
	SBFolder *rootFolder = MSHookIvar<SBFolder *>(self, "_rootFolder");
	// TODO: This method returns id. Maybe it returns the SBIconList[View|Model] object?
	[self addEmptyListViewForFolder:rootFolder];
	return [(SBIconListView *)[rootIconLists lastObject] model];
}

%new(v@:)
- (void)commitAlbumFolders {
	FAPreferencesHandler *handler = [FAPreferencesHandler sharedInstance];
	
	NSArray *keys = [handler allKeys];
	for (NSDictionary *d in keys) {
		BOOL insert = YES;
		
		NSString *title = [d objectForKey:@"keyTitle"];
		NSString *fake = [d objectForKey:@"fakeTitle"];
		NSInteger list = [[d objectForKey:@"listIndex"] integerValue];
		NSInteger icon = [[d objectForKey:@"iconIndex"] integerValue];
		MPMediaItemCollection *collection = [NSKeyedUnarchiver unarchiveObjectWithData:[d objectForKey:@"mediaCollection"]];
		
		SBIconListModel *model;
		
		if (list != -1 || icon != -1) {
			model = [[self rootIconListAtIndex:list] model];
			if (!model || [model isFull])
				goto newmodel;
		}
		
		else {
			newmodel:
			insert = NO;
			model = [self firstAvailableModel];
		}
		
		[model addAlbumFolderForTitle:(fake&&![fake isEqualToString:@""] ? fake : title) plusKeyName:title andMediaCollection:collection atIndex:icon insert:insert];
	}
}
%end

// Save layout
%hook SBIconModel
%new(v@:)
- (void)saveAlbumFolders {
	FAPreferencesHandler *handler = [FAPreferencesHandler sharedInstance];
	
	NSArray *rootIconLists = [[%c(SBIconController) sharedInstance] rootIconLists];
	for (SBIconListView *iconListView in rootIconLists) {
		SBIconListModel *model = [iconListView model];
		NSArray *icons = [model icons];
		
		for (SBIcon *icon in icons) {
			if ([icon isKindOfClass:%c(SBFolderIcon)]) {
				FAFolder *folder = (FAFolder *)[(SBFolderIcon *)icon folder];
				
				if ([folder isKindOfClass:%c(FAFolder)]) {
					NSString *iconDisplayName = [folder keyName];
					if (![handler keyExists:iconDisplayName])
						continue;
					
					NSInteger listIndex = [model index];
					NSInteger iconIndex = [model indexForIcon:icon];
					
					NSMutableDictionary *iconData = [NSMutableDictionary dictionary];
					[iconData setObject:[NSNumber numberWithInteger:listIndex] forKey:@"listIndex"];
					[iconData setObject:[NSNumber numberWithInteger:iconIndex] forKey:@"iconIndex"];
					[iconData setObject:[NSKeyedArchiver archivedDataWithRootObject:[folder mediaCollection]] forKey:@"mediaCollection"];
					
					[handler optimizedUpdateKey:iconDisplayName withDictionary:iconData];
				}
			}
		}
	}
}

- (void)saveIconState {
	%orig;
	[self saveAlbumFolders];
}

- (void)relayout {
	%orig;
	[[%c(SBIconController) sharedInstance] commitAlbumFolders];
}
%end

%ctor {
	// FIXME: Do we need IconSupport?
	dlopen("/Library/MobileSubstrate/DynamicLibraries/IconSupport.dylib", RTLD_NOW);
	[[objc_getClass("ISIconSupport") sharedInstance] addExtension:@"am.theiostre.foldalbum"];
	
	// Init hooks
	%init;
	
	// Setup messaging center
	FANotificationHandler *handler = [FANotificationHandler sharedInstance];
	
	CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.server"];
	[messagingCenter registerForMessageName:@"Relayout" target:handler selector:@selector(relayout)];
	[messagingCenter registerForMessageName:@"UpdateKey" target:handler selector:@selector(updateKeyWithMessageName:userInfo:)];
	[messagingCenter registerForMessageName:@"OptimizedUpdateKey" target:handler selector:@selector(optimizedUpdateKeyWithMessageName:userInfo:)];
	[messagingCenter registerForMessageName:@"RemoveKey" target:handler selector:@selector(removeKeyWithMessageName:userInfo:)];
	[messagingCenter registerForMessageName:@"KeyExists" target:handler selector:@selector(keyExistsWithMessageName:userInfo:)];
	[messagingCenter registerForMessageName:@"ObjectForKey" target:handler selector:@selector(objectForKeyWithMessageName:userInfo:)];
	[messagingCenter registerForMessageName:@"AllKeys" target:handler selector:@selector(allKeys)];
	[messagingCenter runServerOnCurrentThread];
}