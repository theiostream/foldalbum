/**
	Tweak.xm
	
	FoldMusic
  	version 1.6.0, February 25th, 2014
	(exactly one year and one day ago I was working on Version 1.4.0! ;o)
  
  Copyright (C) 2012-2014 Daniel Ferreira
  			  Ariel Aouizerate
  			  BACON CODING COMPANY, LLC
  					 
  Special thanks:
  	David Murray "Cykey" (for being a friend and contributing to the project in tiny but awesome ways)
  	The Doctor "The Doctor" (for saving the universe)
  	Dustin Howett "DHowett" (for being a friend, creating theos, logos, nic, and giving awesome code tips)
  	Max Shavrick "Maximus" (for being a friend, designing most of the UI, and giving awesome code tips)

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
  q@theiostream.com
**/

/*%%%%%%%%%%%
%% Imports
%%%%%%%%%%%*/

#import "FolderAlbums.h"
#import "FAFolderCell.h"
#import "FAPreferencesHandler.h"
#import "FANotificationHandler.h"
#import "FACalloutView.h"

/*%%%%%%%%%%%
%% Macros
%%%%%%%%%%%*/

#define pxtopt(px) ( px * 72 / 96 )
#define pttopx(pt) ( pt * 96 / 72 )

@interface UIDevice (FolderAlbums_iPad)
- (BOOL)isWildcat;
@end

@interface UIImage (FolderAlbums_BundleImg)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end

#define isiPad() (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
#define isPhone5() ( fabs( ( double )[ [ UIScreen mainScreen ] bounds ].size.height - ( double )568 ) < DBL_EPSILON )

// From CyDelete: DHowett is awesome.
#define SBLocalizedString(key) \
	[[NSBundle mainBundle] localizedStringForKey:key value:@"None" table:@"SpringBoard"]

#define ASS(name) objc_getAssociatedObject(self, name)
#define SETASS(name, obj, pol) objc_setAssociatedObject(self, name, obj, pol)

/*%%%%%%%%%%%
%% Declarations
%%%%%%%%%%%*/

// Associated object keys for FAFolder
static char _mediaCollectionKey;
static char _keyNameKey;

// Associated object keys for FAFolderView
static char _labelKey;
static char _dataTableKey;
static char _controlsViewKey;
static char _musicButtonKey;
static char _nowPlayingImageKey;
static char _playButtonKey;
static char _artistLabel;
static char _songLabel;
static char _albumLabel;
static char _trackLabelKey;
static char _repeatButton;
static char _shuffleButton;
static char _sliderKey;
static char _wrapperKey;
static char _subtitleLabelKey;
static char _backButtonKey;
static char _forwardButtonKey;
static char _extraViewKey;

// FAFloatyFolderView keys
static char _floatyFolderKey;
static char _floatyControlsViewKey;
static char _floatyDataTableKey;
static char _floatyArtistLabel;
static char _mainViewKey;

// Other globals
static char _iconImageViewKey;
static CGRect groupFrame;

static NSUInteger idx = 0;

// === Make these associated objects?
static NSTimer *seekTimer = nil;
static BOOL wasSeeking = NO;

static NSTimer *progTimer = nil;
static BOOL draggingSlider = NO;
// ===

/*%%%%%%%%%%%
%% Functions
%%%%%%%%%%%*/

// This resizes my image right.
// (To Trevor Harmon) I do not care if it doesn't handle image orientations, at least
//					  it doesn't completely blur the stupid image when resizing.
static UIImage *UIImageResize(UIImage *image, CGSize newSize) {
	if (!image) return nil;
	
	UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
	[image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
	UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
	UIGraphicsEndImageContext();
	return newImage;
}

/*static BOOL FANotStopped() {
	//NSLog(@"returnin fanotstopped %@", [[%c(SBMediaController) sharedInstance] nowPlayingApplication]);
	
	SBApplication *nowPlaying = [[%c(SBMediaController) sharedInstance] nowPlayingApplication];
	if (nowPlaying != nil)
		if ([[nowPlaying displayIdentifier] isEqualToString:@"com.apple.mobileipod"])
			return YES;
	
	return NO;
}*/

static MPMusicRepeatMode FAGetRepeatMode() {
	NSString *repMode = [[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.mobileipod.plist"] objectForKey:@"MusicRepeatSetting"];
	if (!repMode) return MPMusicRepeatModeNone;
	
	return (
		[repMode isEqualToString:@"All"] ? MPMusicRepeatModeAll :
		[repMode isEqualToString:@"One"] ? MPMusicRepeatModeOne :
		MPMusicRepeatModeNone);
}

static MPMusicShuffleMode FAGetShuffleMode() {
	NSString *shuMode = [[NSDictionary dictionaryWithContentsOfFile:@"/var/mobile/Library/Preferences/com.apple.mobileipod.plist"] objectForKey:@"MusicShuffleSetting"];
	if (!shuMode) return MPMusicShuffleModeOff;
	
	return (
		[shuMode isEqualToString:@"Off"] ? MPMusicShuffleModeOff :
		MPMusicShuffleModeSongs);
}

static UIImage *MediaPlayerImage(NSString *name) {
	return [UIImage imageNamed:name inBundle:[NSBundle bundleWithIdentifier:@"com.apple.MediaPlayer"]];
}

static inline UIImage *PlayOrPauseImage(BOOL play) {
	if (kCFCoreFoundationVersionNumber >= 800) {
		if (play) return [UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/MediaPlayerUI.framework/SystemMediaControl-Play-StarkNowPlaying.png"];
		return [UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/MediaPlayerUI.framework/SystemMediaControl-Pause-StarkNowPlaying.png"];
	}
	
	const char *imagestr = play ? "play.png" : "pause.png";
	return [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Frameworks/MediaPlayer.framework/%s.png", imagestr]];
}

static inline BOOL FAIsPlaying(MPMusicPlaybackState state) {
	/*//if (kCFCoreFoundationVersionNumber >= 800) return [[%c(AVAudioSession) sharedInstance] isOtherAudioPlaying]; // -playbackState is broken on iOS 7.
	BOOL ret = state != MPMusicPlaybackStateStopped && state != MPMusicPlaybackStatePaused && state != MPMusicPlaybackStateInterrupted;
	if (kCFCoreFoundationVersionNumber < 800) return ret;

	return ret ?: [[%c(SBMediaController) sharedInstance] isPlaying];*/

	if (kCFCoreFoundationVersionNumber >= 800) return [[%c(SBMediaController) sharedInstance] isPlaying];
	return state != MPMusicPlaybackStateStopped && state != MPMusicPlaybackStatePaused && state != MPMusicPlaybackStateInterrupted;
}

/*%%%%%%%%%%%
%% Subclasses
%%%%%%%%%%%*/

/* FAFolderIcon / FAFolder {{{ */

// thanks dhowett
%subclass FAFolderIcon : SBFolderIcon
- (BOOL)allowsUninstall {
	return YES;
}

- (NSString *)uninstallAlertTitle {
	return [NSString stringWithFormat:SBLocalizedString(@"UNINSTALL_ICON_TITLE"), [self displayName]];
}

- (NSString *)uninstallAlertBody {
	return [NSString stringWithFormat:@"Are you sure you want to delete the \"%@\" folder? Your music data will be preserved.", [self displayName]];
}

- (void)completeUninstall {
	%orig;
	
	// FIXME: Use FAPreferencesHandler instead of FANotificationHandler
	[[FANotificationHandler sharedInstance] removeKeyWithMessageName:nil userInfo:[NSDictionary dictionaryWithObject:[(FAFolder *)[self folder] keyName] forKey:@"Key"]];
}
%end

%subclass FAFolder : SBFolder
- (Class)folderViewClass {
	return %c(FAFolderView);
}

// This is somehow wrong.
- (NSArray *)allIcons {
	NSMutableArray *ret = [NSMutableArray array];
	SBIcon *empty = [[[%c(SBIcon) alloc] init] autorelease];
	
	int iconsTarget = isiPad() ? 19 : isPhone5() ? 15 : 11;
	for (int i=0; i<iconsTarget; i++)
		[ret addObject:empty];
		
	return ret;
}

- (void)setIsOpen:(BOOL)open {
	%log;
	if (!open) {
		if (progTimer && [progTimer isValid]) {
			NSLog(@"[fm] Invalidating prog timer");
			[progTimer invalidate];
			progTimer = nil;
		}
	}
		
	%orig;
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
	%log;
	%orig;
	objc_removeAssociatedObjects(self); // Please tell me this removes all associated object leaks.
}
%end

/* }}} */

/* Common Folder View {{{ */
%subclass FACommonFolderView : SBFolderView
%new(v@:)
- (void)initializeControlViewWithSuperview:(UIView *)controlsView haveExtraView:(BOOL)haveExtraView {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *nowPlayingItem = [music nowPlayingItem];
	
	NSString *placeholderSong = @"Not Playing";
	UIImage *placeholderArtwork = UIImageResize(MediaPlayerImage(@"noartplaceholder.png"), CGSizeMake(130, 130));
	
	MPMusicPlaybackState state;
	UIImage *artworkImage = nil;
	NSString *album=nil, *song=nil, *artist=nil;
	NSInteger cur, tot;
	NSTimeInterval dur;
	MPMusicRepeatMode repeatMode;
	MPMusicShuffleMode shuffleMode;
	float pla;
	
	if (nowPlayingItem) {
		state = [music playbackState];
		
		MPMediaItemArtwork *artwork = [nowPlayingItem valueForProperty:MPMediaItemPropertyArtwork];
		UIImage *artworkImg = UIImageResize([artwork imageWithSize:CGSizeMake(130, 130)], CGSizeMake(130, 130));
		if (artworkImg) { artworkImage = artworkImg; }
		else		{ artworkImage = placeholderArtwork; }
		
		song = [nowPlayingItem valueForProperty:MPMediaItemPropertyTitle];
		if (!song) song = @"N/A"; // What the actual fuck.
		album = [nowPlayingItem valueForProperty:MPMediaItemPropertyAlbumTitle];
		artist = [nowPlayingItem valueForProperty:MPMediaItemPropertyArtist];
		
		cur = [music indexOfNowPlayingItem]+1;
		tot = [[[music queueAsQuery] items] count];
		dur = [[nowPlayingItem valueForProperty:MPMediaItemPropertyPlaybackDuration] floatValue];
		pla = [music currentPlaybackTime];
		
		repeatMode = [music repeatMode] == MPMusicRepeatModeDefault ? FAGetRepeatMode() : [music repeatMode];
		shuffleMode = [music shuffleMode] == MPMusicShuffleModeDefault ? FAGetShuffleMode() : [music shuffleMode];
	}
	else {
		artworkImage = placeholderArtwork;
		state = MPMusicPlaybackStateStopped;
		song = placeholderSong;
		
		cur = -1;
		tot = -1;
		dur = 0;
		pla = 0.f;
		
		repeatMode = FAGetRepeatMode();
		shuffleMode = FAGetShuffleMode();
	}
	
	UIImageView *artworkView = [[[UIImageView alloc] initWithFrame:CGRectZero] autorelease];
	[artworkView setImage:artworkImage];
	objc_setAssociatedObject(self, &_nowPlayingImageKey, artworkView, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:artworkView];
	
	// TODO: Frame correctly! :(
	
	UILabel *artistLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[artistLabel setText:artist];
	[artistLabel setFont:[UIFont fontWithName:kCFCoreFoundationVersionNumber>=800 ? @"HelveticaNeue-Light" : @".HelveticaNeueUI-Bold" size:kCFCoreFoundationVersionNumber>=800 ? 14.f : 12.f]];
	[artistLabel setTextAlignment:UITextAlignmentCenter];
	[artistLabel setTextColor:[UIColor whiteColor]];
	[artistLabel setBackgroundColor:[UIColor clearColor]];
	if (kCFCoreFoundationVersionNumber < 800) {
		[artistLabel setShadowColor:[UIColor blackColor]];
		[artistLabel setShadowOffset:CGSizeMake(0, 1)];
	}
	[artistLabel setHidden:(artist == nil)];
	
	objc_setAssociatedObject(self, &_artistLabel, artistLabel, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:artistLabel];
	
	UILabel *songLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[songLabel setText:song];
	[songLabel setFont:[UIFont fontWithName:kCFCoreFoundationVersionNumber>=800 ? @"HelveticaNeue-Light" : @".HelveticaNeueUI-Bold" size:kCFCoreFoundationVersionNumber>=800 ? 14.f : 12.f]];
	[songLabel setTextAlignment:UITextAlignmentCenter];
	[songLabel setTextColor:[UIColor whiteColor]];
	[songLabel setBackgroundColor:[UIColor clearColor]];
	if (kCFCoreFoundationVersionNumber < 800) {
		[songLabel setShadowColor:[UIColor blackColor]];
		[songLabel setShadowOffset:CGSizeMake(0, 1)];
	}
	
	objc_setAssociatedObject(self, &_songLabel, songLabel, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:songLabel];
		
	UILabel *albumLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[albumLabel setText:album];
	[albumLabel setFont:[UIFont fontWithName:kCFCoreFoundationVersionNumber>=800 ? @"HelveticaNeue-Light" : @".HelveticaNeueUI-Bold" size:kCFCoreFoundationVersionNumber>=800 ? 14.f : 12.f]];
	[albumLabel setTextAlignment:UITextAlignmentCenter];
	[albumLabel setTextColor:[UIColor whiteColor]];
	[albumLabel setBackgroundColor:[UIColor clearColor]];
	if (kCFCoreFoundationVersionNumber < 800) {
		[albumLabel setShadowColor:[UIColor blackColor]];
		[albumLabel setShadowOffset:CGSizeMake(0, 1)];
	}
	[albumLabel setHidden:(album == nil)];
	
	objc_setAssociatedObject(self, &_albumLabel, albumLabel, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:albumLabel];
	
	UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
	NSString *backImageName = kCFCoreFoundationVersionNumber >= 800 ? @"/System/Library/PrivateFrameworks/MediaPlayerUI.framework/SystemMediaControl-Rewind-StarkNowPlaying.png" : @"/System/Library/Frameworks/MediaPlayer.framework/prevtrack.png";
	[backButton setImage:[UIImage imageWithContentsOfFile:backImageName] forState:UIControlStateNormal];
	[backButton addTarget:self action:@selector(pressedBackwardButton) forControlEvents:UIControlEventTouchDown];
	[backButton addTarget:self action:@selector(releasedBackwardButton) forControlEvents:UIControlEventTouchUpInside];
	[backButton addTarget:self action:@selector(releasedBackwardButton) forControlEvents:UIControlEventTouchDragOutside];
	SETASS(&_backButtonKey, backButton, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:backButton];
	
	NSString *playImageName = kCFCoreFoundationVersionNumber >= 800 ? @"/System/Library/PrivateFrameworks/MediaPlayerUI.framework/SystemMediaControl-Play-StarkNowPlaying.png" : @"/System/Library/Frameworks/MediaPlayer.framework/play.png";
	NSString *pauseImageName = kCFCoreFoundationVersionNumber >= 800 ? @"/System/Library/PrivateFrameworks/MediaPlayerUI.framework/SystemMediaControl-Pause-StarkNowPlaying.png" : @"/System/Library/Frameworks/MediaPlayer.framework/pause.png";
	UIImage *play = [UIImage imageWithContentsOfFile:playImageName];
	UIImage *pause = [UIImage imageWithContentsOfFile:pauseImageName];
	UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[playButton setImage:(FAIsPlaying(state) ? pause : play) forState:UIControlStateNormal];
	[playButton addTarget:self action:@selector(clickedPlayButton:) forControlEvents:UIControlEventTouchUpInside];
	objc_setAssociatedObject(self, &_playButtonKey, playButton, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:playButton];
	
	UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
	NSString *nextImageName = kCFCoreFoundationVersionNumber >= 800 ? @"/System/Library/PrivateFrameworks/MediaPlayerUI.framework/SystemMediaControl-Forward-StarkNowPlaying.png" : @"/System/Library/Frameworks/MediaPlayer.framework/nexttrack.png";
	[nextButton setImage:[UIImage imageWithContentsOfFile:nextImageName] forState:UIControlStateNormal];
	[nextButton addTarget:self action:@selector(pressedForwardButton) forControlEvents:UIControlEventTouchDown];
	[nextButton addTarget:self action:@selector(releasedForwardButton) forControlEvents:UIControlEventTouchUpInside];
	[nextButton addTarget:self action:@selector(releasedForwardButton) forControlEvents:UIControlEventTouchDragOutside];
	SETASS(&_forwardButtonKey, nextButton, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:nextButton];
	
	UIView *extraView = haveExtraView ? [[[UIView alloc] initWithFrame:CGRectZero] autorelease] : controlsView;
	
	NSString *trackText;
	if (cur > -1 && tot > -1)
		trackText = [NSString stringWithFormat:@"Track %i of %i", cur, tot];
	else
		trackText = @"Track -- of --";
	
	UILabel *trackLabel = [[[UILabel alloc] initWithFrame:CGRectZero] autorelease];
	[trackLabel setText:trackText];
	[trackLabel setFont:[UIFont fontWithName:kCFCoreFoundationVersionNumber>=800 ? @"HelveticaNeue-Light" : @".HelveticaNeueUI-Bold" size:12.f]];
	[trackLabel setTextAlignment:UITextAlignmentCenter];
	[trackLabel setTextColor:[UIColor whiteColor]];
	[trackLabel setBackgroundColor:[UIColor clearColor]];
	if (kCFCoreFoundationVersionNumber < 800) {	
		[trackLabel setShadowColor:[UIColor blackColor]];
		[trackLabel setShadowOffset:CGSizeMake(0, 1)];
	}
	
	objc_setAssociatedObject(self, &_trackLabelKey, trackLabel, OBJC_ASSOCIATION_RETAIN);
	[extraView addSubview:trackLabel];
	
	MPDetailSlider *slider;
	if (kCFCoreFoundationVersionNumber >= 800)
		slider = [[[MPDetailSlider alloc] initWithFrame:CGRectZero style:8] autorelease];
	else
		slider = [[[MPDetailSlider alloc] initWithFrame:CGRectZero] autorelease];
	[slider setAllowsDetailScrubbing:YES];
	[slider setDuration:dur];
	[slider setValue:pla animated:NO];
	[slider setDelegate:self];
	[self initializeProgTimer];

	objc_setAssociatedObject(self, &_sliderKey, slider, OBJC_ASSOCIATION_RETAIN);
	[extraView addSubview:slider];
	
	NSString *repeatImageName = (
		repeatMode == MPMusicRepeatModeAll ? @"repeat_on.png" :
		repeatMode == MPMusicRepeatModeOne ? @"repeat_on_1.png" :
		@"repeat_off.png");
	UIImage *repeatImage = MediaPlayerImage(repeatImageName);
	UIButton *repeatButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[repeatButton setImage:repeatImage forState:UIControlStateNormal];
	[repeatButton addTarget:self action:@selector(pressedRepeatButton) forControlEvents:UIControlEventTouchUpInside];
	objc_setAssociatedObject(self, &_repeatButton, repeatButton, OBJC_ASSOCIATION_RETAIN);
	[extraView addSubview:repeatButton];
	
	NSString *shuffleImageName = (
		shuffleMode != MPMusicShuffleModeOff ? @"shuffle_on.png" :
		@"shuffle_off.png");
	UIImage *shuffleImage = MediaPlayerImage(shuffleImageName);
	UIButton *shuffleButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[shuffleButton setImage:shuffleImage forState:UIControlStateNormal];
	[shuffleButton addTarget:self action:@selector(pressedShuffleButton) forControlEvents:UIControlEventTouchUpInside];
	objc_setAssociatedObject(self, &_shuffleButton, shuffleButton, OBJC_ASSOCIATION_RETAIN);
	[extraView addSubview:shuffleButton];
	
	if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0) [controlsView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
	if (haveExtraView) {
		[controlsView addSubview:extraView];
		objc_setAssociatedObject(self, &_extraViewKey, extraView, OBJC_ASSOCIATION_RETAIN);
	}
}

%new(@@:)
- (NSArray *)itemKeys {
	NSArray *_itemKeys = !([[(FAFolder *)[self folder] mediaCollection] isKindOfClass:[MPMediaPlaylist class]]) ?
		[NSArray arrayWithObjects:MPMediaItemPropertyPlaybackDuration, MPMediaItemPropertyPlayCount, nil] :
		[NSArray arrayWithObjects:MPMediaItemPropertyPlaybackDuration, MPMediaItemPropertyPlayCount, MPMediaItemPropertyArtist, MPMediaItemPropertyAlbumTitle, nil];
	
	return _itemKeys;
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
	
	MPMediaItemCollection *collection = [(FAFolder *)[self folder] mediaCollection];
	NSArray *items = [collection items];
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
	MPMediaItemCollection *collection = [(FAFolder *)[self folder] mediaCollection];
	
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *nowPlayingItem = [music nowPlayingItem];
	
	NSArray *items = [collection items];
	MPMediaItem *cellItem = [items objectAtIndex:[indexPath row]];
	
	if (nowPlayingItem) {
		MPMusicPlaybackState state = [music playbackState];
	
		NSNumber *nowPlayingPersistent = [nowPlayingItem valueForProperty:MPMediaItemPropertyPersistentID];
		NSNumber *cellItemPersistent = [cellItem valueForProperty:MPMediaItemPropertyPersistentID];
	
		if ([nowPlayingPersistent compare:cellItemPersistent] == NSOrderedSame) {
			if (FAIsPlaying(state)) {
				[music pause];
				goto end;
			}
			
			// FIXME: Can we trust the state here?
			else if (state == MPMusicPlaybackStatePaused) {
				goto play;
			}
		}
	}
	
	collection = [(FAFolder *)[self folder] mediaCollection];
	[music setQueueWithItemCollection:collection];
	
	[music setNowPlayingItem:cellItem];
	
	play:
	[music play];
	
	end:
	[tableView deselectRowAtIndexPath:indexPath animated:YES];
	//[self receivedTrackChanged];
}

%new(v@:@)
- (void)nextItem:(UIGestureRecognizer *)rec {
	NSArray *_itemKeys = [self itemKeys];
	
	idx++;
	idx = idx>=[_itemKeys count] ? 0 : idx;
	
	NSArray *visibleCells = [(UITableView *)[rec view] visibleCells];
	NSUInteger count = [visibleCells count];
	for (NSUInteger i=0; i<count; i++)
		[[visibleCells objectAtIndex:i] setDetailProperty:[_itemKeys objectAtIndex:idx] change:YES];
}

%new(v@:)
- (void)initializeProgTimer {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMusicPlaybackState state;
	if ([music nowPlayingItem]) {
		state = [music playbackState];
	}
	else {
		state = MPMusicPlaybackStateStopped;
	}
	
	if (FAIsPlaying(state)) {
		NSLog(@"State %i", state);
		if (progTimer == nil)
			progTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
		else if (![progTimer isValid])
			progTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
	}
	else {
		if (progTimer) {
			if ([progTimer isValid]) [progTimer invalidate];
			progTimer = nil;
		}
	}
	
	/*if (!progTimer || ![progTimer isValid]) progTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
	if (!(state != MPMusicPlaybackStateStopped || state != MPMusicPlaybackStatePaused || state != MPMusicPlaybackStateInterrupted)) {
		draggingSlider = YES;
	}*/
}

%new(v@:)
- (void)receivedTrackChanged {
	%log;
	NSLog(@"[TRACK] IS PLAYING: %d", FAIsPlaying(0));
	
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *item = [music nowPlayingItem];
	
	UIImage *artworkImage;
	NSString *artist, *album, *song;
	NSInteger cur, tot;
	NSTimeInterval dur;
	float pla;
	
	if (item) {
		MPMediaItemArtwork *artwork = [item valueForProperty:MPMediaItemPropertyArtwork];
		UIImage *artworkImg = UIImageResize([artwork imageWithSize:CGSizeMake(130, 130)], CGSizeMake(130, 130));
		if (artworkImg) artworkImage = artworkImg;
		else artworkImage = UIImageResize(MediaPlayerImage(@"noartplaceholder.png"), CGSizeMake(130, 130));
		
		artist = [item valueForProperty:MPMediaItemPropertyArtist];
		album = [item valueForProperty:MPMediaItemPropertyAlbumTitle];
		song = [item valueForProperty:MPMediaItemPropertyTitle];
		if (!song) song = @"N/A";
		
		cur = [music indexOfNowPlayingItem]+1;
		tot = [[[music queueAsQuery] items] count];
		dur = [[item valueForProperty:MPMediaItemPropertyPlaybackDuration] floatValue];
		pla = [music currentPlaybackTime]; // 0.f always. But who knows?!
	}
	else {
		artworkImage = UIImageResize(MediaPlayerImage(@"noartplaceholder.png"), CGSizeMake(130, 130));
		
		artist = nil;
		album = nil;
		song = @"Not Playing";
		
		cur = -1;
		tot = -1;
		dur = 0;
		pla = 0.f;
	}
	
	[objc_getAssociatedObject(self, &_nowPlayingImageKey) setImage:artworkImage];
	
	UILabel *artistLabel = objc_getAssociatedObject(self, &_artistLabel);
	[artistLabel setHidden:(artist == nil)];
	[artistLabel setText:artist];
	
	UILabel *albumLabel = objc_getAssociatedObject(self, &_albumLabel);
	[albumLabel setHidden:(album == nil)];
	[albumLabel setText:album];
	
	[objc_getAssociatedObject(self, &_songLabel) setText:song];
	
	NSString *trackText;
	UILabel *trackLabel = objc_getAssociatedObject(self, &_trackLabelKey);
	if (cur > -1 && tot > -1)
		trackText = [NSString stringWithFormat:@"Track %i of %i", cur, tot];
	else
		trackText = @"Track -- of --";
	[trackLabel setText:trackText];
	
	MPDetailSlider *slider = objc_getAssociatedObject(self, &_sliderKey);
	[slider setDuration:dur];
	[slider setValue:pla animated:NO];

	//[self receivedStateChanged];
}

%new(v@:)
- (void)receivedStateChanged {
	%log;
	NSLog(@"[STATE] IS PLAYING: %d", FAIsPlaying(0));

	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMusicPlaybackState state = [music playbackState];
	NSLog(@"[STATE] STATE IS %d", state);

	BOOL isPlaying = FAIsPlaying(state);
	NSLog(@"STATE: SETTING %@ IMAGE", !isPlaying ? @"Play" : @"Pause");
	[objc_getAssociatedObject(self, &_playButtonKey) setImage:PlayOrPauseImage(!isPlaying) forState:UIControlStateNormal];
	
	//if (!progTimer || ![progTimer isValid]) progTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
	//if (!(state != MPMusicPlaybackStateStopped || state != MPMusicPlaybackStatePaused || state != MPMusicPlaybackStateInterrupted)) {
	//	draggingSlider = YES;
	//}
	
	if (FAIsPlaying(state)) {
		NSLog(@"STATE: INITIALIZE TIMER.");
		if (progTimer == nil)
			progTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
		else if (![progTimer isValid])
			progTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
	}
	else {
		if (progTimer) {
			if ([progTimer isValid]) [progTimer invalidate];
			progTimer = nil;
		}
	}
}

%new(v@:)
- (void)updateSlider {
	%log;
	
	if (draggingSlider)
		return;
	
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *item = [music nowPlayingItem];
	
	if (item) {
		NSTimeInterval tim = [music currentPlaybackTime];
		[objc_getAssociatedObject(self, &_sliderKey) setValue:(float)tim animated:YES];
	}
}

%new(v@:@f)
- (void)detailSlider:(UISlider *)slider didChangeValue:(float)value {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	[music setCurrentPlaybackTime:value];
}

%new(v@:@)
- (void)detailSliderTrackingDidBegin:(UISlider *)slider {
	draggingSlider = YES;
}

%new(v@:@)
- (void)detailSliderTrackingDidEnd:(UISlider *)slider {
	draggingSlider = NO;
	
	if (progTimer != nil) {
		if ([progTimer isValid]) {
			[progTimer invalidate];
			progTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
		}
	}
}

%new(v@:@)
- (void)detailSliderTrackingDidCancel:(UISlider *)slider {
	draggingSlider = NO;
	
	if (progTimer != nil) {
		if ([progTimer isValid]) {
			[progTimer invalidate];
			progTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
		}
	}
}

%new(v@:@)
- (void)clickedPlayButton:(UIButton *)button {
	%log;
	NSLog(@"[CLICKED] IS PLAYING: %d", FAIsPlaying(0));

	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *item = [music nowPlayingItem];
	MPMusicPlaybackState state = [music playbackState];
	
	if (!item) {
		MPMediaItemCollection *collection = [(FAFolder *)[self folder] mediaCollection];
		[music setQueueWithItemCollection:collection];
	}
	
	//UIButton *controlsButton = objc_getAssociatedObject(self, &_playButtonKey);
	if (FAIsPlaying(state)) {
		//if (![button isEqual:controlsButton]) [button setImage:PlayOrPauseImage(NO) forState:UIControlStateNormal];
		[music pause];
		//[[%c(SBMediaController) sharedInstance] pause];
	}
	
	else {
		//if (![button isEqual:controlsButton]) [button setImage:PlayOrPauseImage(YES) forState:UIControlStateNormal];
		[music play];
		//[[%c(SBMediaController) sharedInstance] play];
	}
	
	//[self receivedTrackChanged];
}

%new(v@:)
- (void)pressedForwardButton {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *item = [music nowPlayingItem];
	if (!item)
		return;
	
	seekTimer = [NSTimer scheduledTimerWithTimeInterval:.5f target:self selector:@selector(_seekForward) userInfo:nil repeats:NO];
}

%new(v@:)
- (void)pressedBackwardButton {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *item = [music nowPlayingItem];
	if (!item)
		return;
	
	seekTimer = [NSTimer scheduledTimerWithTimeInterval:.5f target:self selector:@selector(_seekBackward) userInfo:nil repeats:NO];
}

%new(v@:)
- (void)_seekForward {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	[music beginSeekingForward];
	
	wasSeeking = YES;
}

%new(v@:)
- (void)_seekBackward {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	[music beginSeekingBackward];
	
	wasSeeking = YES;
}

%new(v@:)
- (void)releasedForwardButton {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *item = [music nowPlayingItem];
	
	if (!item) return;
	
	if (wasSeeking) {
		[music endSeeking];
		wasSeeking = NO;
		
		return;
	}
	
	[seekTimer invalidate];
	[music skipToNextItem];
	
	//[self receivedTrackChanged];
}

%new(v@:)
- (void)releasedBackwardButton {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *item = [music nowPlayingItem];
	
	if (!item) return;
	
	if (wasSeeking) {
		[music endSeeking];
		wasSeeking = NO;
		
		return;
	}
	
	[seekTimer invalidate];
	
	if ([music currentPlaybackTime] > 2) {
		[objc_getAssociatedObject(self, &_sliderKey) setValue:0.f animated:NO];
		[music skipToBeginning];
	}
	else
		[music skipToPreviousItem];
	
	//[self receivedTrackChanged];
}

%new(v@:)
- (void)pressedRepeatButton {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
		
	MPMusicRepeatMode repeatMode = [music repeatMode] == MPMusicRepeatModeDefault ? FAGetRepeatMode() : [music repeatMode];
	
	MPMusicRepeatMode newMode = (
		repeatMode == MPMusicRepeatModeNone ? MPMusicRepeatModeAll :
		repeatMode == MPMusicRepeatModeAll ? MPMusicRepeatModeOne :
		MPMusicRepeatModeNone);
	[music setRepeatMode:newMode];
	
	NSString *imageTitle = (
		newMode == MPMusicRepeatModeAll ? @"repeat_on.png" :
		newMode == MPMusicRepeatModeOne ? @"repeat_on_1.png" :
		@"repeat_off.png");
	
	UIImage *repeatImage = MediaPlayerImage(imageTitle);
	[objc_getAssociatedObject(self, &_repeatButton) setImage:repeatImage forState:UIControlStateNormal];
}

%new(v@:)
- (void)pressedShuffleButton {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *item = [music nowPlayingItem];
	
	MPMusicShuffleMode shuffleMode = [music shuffleMode] == MPMusicShuffleModeDefault ? FAGetShuffleMode() : [music shuffleMode];
	
	MPMusicShuffleMode newMode = (
		shuffleMode == MPMusicShuffleModeOff ? MPMusicShuffleModeSongs :
		MPMusicShuffleModeOff);
	[music setShuffleMode:newMode];
	
	NSString *imageTitle = (
		newMode == MPMusicShuffleModeSongs ? @"shuffle_on.png" :
		@"shuffle_off.png");
	
	UIImage *shuffleImage = MediaPlayerImage(imageTitle);
	[objc_getAssociatedObject(self, &_shuffleButton) setImage:shuffleImage forState:UIControlStateNormal];
	
	NSInteger cur, tot;
	if (item) {
		cur = [music indexOfNowPlayingItem]+1;
		tot = [[[music queueAsQuery] items] count];
	}
	else {
		cur = -1;
		tot = -1;
	}
	
	NSString *trackText;
	UILabel *trackLabel = objc_getAssociatedObject(self, &_trackLabelKey);
	if (cur > -1 && tot > -1)
		trackText = [NSString stringWithFormat:@"Track %i of %i", cur, tot];
	else
		trackText = @"Track -- of --";
	[trackLabel setText:trackText];
}
%end
/* }}} */

/* FAFloatyFolderView {{{ */ 

%group FAFolderView7x
%hook SBFolderController
- (Class)_contentViewClass {
	return [[self folder] isKindOfClass:%c(FAFolder)] ? %c(FAFloatyFolderView) : %orig;
}
%end

%subclass FAFloatyFolderView : FACommonFolderView 
%new
- (Class)detailSliderClass {
	//return %c(MusicThinDetailSlider);
	return %c(MPDetailSlider);
}

%new(@@:)
- (FAFolder *)folder {
	return objc_getAssociatedObject(self, &_floatyFolderKey);
}

- (id)initWithFolder:(FAFolder *)folder orientation:(int)orientation {
	if ((self = %orig)) {
		objc_setAssociatedObject(self, &_floatyFolderKey, folder, OBJC_ASSOCIATION_RETAIN);
		objc_setAssociatedObject(self, &_floatyDataTableKey, nil, OBJC_ASSOCIATION_ASSIGN);
		
		[[UIApplication sharedApplication] launchMusicPlayerSuspended];
		[[MPMusicPlayerController iPodMusicPlayer] beginGeneratingPlaybackNotifications];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedStateChanged) name:@"SBMediaNowPlayingChangedNotification" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedTrackChanged) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];
		
		UIView *scrollClipView = MSHookIvar<UIView *>(self, "_scrollClipView");
		[[scrollClipView subviews] makeObjectsPerformSelector:@selector(removeFromSuperview)];
		
		[self createFolderAlbumsInView:scrollClipView];
	}

	return self;
}

- (void)_layoutSubviews {
	%log;
	%orig;
	
	[self setupArtistLabel];
	[self setupFolderAlbumsInView:MSHookIvar<UIView *>(self, "_scrollClipView")];
}

- (void)fadeContentForMinificationFraction:(float)arg1 {
	%orig;
	
	[objc_getAssociatedObject(self, &_mainViewKey) setAlpha:1 - arg1];
	[objc_getAssociatedObject(self, &_floatyArtistLabel) setAlpha:1 - arg1];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	NSString *key = [(FAFolder *)[self folder] keyName];
	NSString *res = [[textField text] isEqualToString:@""] ? key : [textField text];
	
	NSDictionary *update = [NSDictionary dictionaryWithObject:res forKey:@"fakeTitle"];
	[[FAPreferencesHandler sharedInstance] optimizedUpdateKey:key withDictionary:update];
	
	[[self folder] setDisplayName:res];
	%orig;
}

%new(v@:@)
- (void)createFolderAlbumsInView:(UIView *)view {
	%log;

	UILabel *artistLabel = [[UILabel alloc] initWithFrame:CGRectZero];

	NSString *titleFontLabel = [[MSHookIvar<UITextField *>(self, "_titleTextField") font] fontName];
	[artistLabel setFont:[UIFont fontWithName:titleFontLabel size:roundf(pxtopt(28.f))]];
	[artistLabel setTextAlignment:NSTextAlignmentCenter];
	[artistLabel setBackgroundColor:[UIColor clearColor]];
	
	[self addSubview:artistLabel];
	objc_setAssociatedObject(self, &_floatyArtistLabel, artistLabel, OBJC_ASSOCIATION_RETAIN);
	[artistLabel release];
	
	UIView *mainView = [[UIView alloc] initWithFrame:CGRectZero];
	
	UITableView *dataTable = [[UITableView alloc] initWithFrame:CGRectZero style:UITableViewStylePlain];	
	[dataTable setDelegate:self];
	[dataTable setDataSource:self];
	[dataTable setBackgroundColor:[UIColor clearColor]];
	[dataTable setSeparatorColor:[UIColor whiteColor]];
	
	[[dataTable layer] setBorderWidth:.8f];
	[[dataTable layer] setBorderColor:[[UIColor whiteColor] CGColor]];
	[[dataTable layer] setMasksToBounds:YES];
	[[dataTable layer] setCornerRadius:isiPad() ? 38.f : 28.f];
	
	UISwipeGestureRecognizer *rig = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextItem:)];
	[rig setDirection:UISwipeGestureRecognizerDirectionRight];
	UISwipeGestureRecognizer *lef = [[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextItem:)];
	[lef setDirection:UISwipeGestureRecognizerDirectionLeft];
	[dataTable addGestureRecognizer:rig];
	[dataTable addGestureRecognizer:lef];
	[rig release];
	[lef release];
	
	[mainView addSubview:dataTable];
	objc_setAssociatedObject(self, &_floatyDataTableKey, dataTable, OBJC_ASSOCIATION_RETAIN);
	[dataTable release];
	
	UIScrollView *controlsView = [[UIScrollView alloc] initWithFrame:CGRectZero];
	[[controlsView layer] setBorderWidth:.8f];
	[[controlsView layer] setBorderColor:[[UIColor whiteColor] CGColor]];
	[[controlsView layer] setMasksToBounds:YES];
	[[controlsView layer] setCornerRadius:isiPad() ? 38.f : 28.f];
	[controlsView setPagingEnabled:YES];
	
	[self initializeControlViewWithSuperview:controlsView haveExtraView:NO];

	[mainView addSubview:controlsView];
	objc_setAssociatedObject(self, &_floatyControlsViewKey, controlsView, OBJC_ASSOCIATION_RETAIN);
	[controlsView release];

	[view addSubview:mainView];
	objc_setAssociatedObject(self, &_mainViewKey, mainView, OBJC_ASSOCIATION_RETAIN);
	[mainView release];
}

%new(v@:)
- (void)setupArtistLabel {
	if ([[[self folder] mediaCollection] isKindOfClass:[MPMediaPlaylist class]])
		return;
	
	UITextField *titleField = MSHookIvar<UITextField *>(self, "_titleTextField");
	[titleField setFrame:(CGRect){{titleField.frame.origin.x, titleField.frame.origin.y - 25.f}, titleField.frame.size}];
	
	UILabel *artistLabel = objc_getAssociatedObject(self, &_floatyArtistLabel);
	[artistLabel setTextColor:[MSHookIvar<UITextField *>(self, "_titleTextField") textColor]];
	[artistLabel setFrame:CGRectMake(0.f, [titleField frame].origin.y+[titleField frame].size.height - 4.f, [[UIScreen mainScreen] bounds].size.width, 28.f)];
	[artistLabel setText:[[[[self folder] mediaCollection] representativeItem] valueForProperty:MPMediaItemPropertyArtist]];	
}

%new(v@:@)
- (void)setupFolderAlbumsInView:(UIView *)view {
	UIView *bg = MSHookIvar<UIView *>(self, "_backgroundView");
	[bg setFrame:CGRectMake(bg.frame.origin.x-3.f, bg.frame.origin.y, bg.frame.size.width+6.f, bg.frame.size.height)];
	[view setFrame:CGRectMake(view.frame.origin.x-3.f, view.frame.origin.y, view.frame.size.width+6.f, view.frame.size.height)];
	
	[objc_getAssociatedObject(self, &_mainViewKey) setFrame:[view bounds]];
	
	CGRect tableFrame = CGRectMake(8.f, isiPad() ? 12.f : 8.f, [view bounds].size.width-16.f, [view bounds].size.height/4*3-24.f);
	[objc_getAssociatedObject(self, &_floatyDataTableKey) setFrame:tableFrame];
	
	UIScrollView *controlsView = ASS(&_floatyControlsViewKey);
	[controlsView setFrame:CGRectMake(tableFrame.origin.x, tableFrame.origin.y+tableFrame.size.height+8.f, tableFrame.size.width, [view bounds].size.height/4 - (isiPad() ? 4.f : 0.f))];
	[controlsView setContentSize:CGSizeMake(tableFrame.size.width*2, [controlsView frame].size.height)];
	
	CGRect artworkFrame = CGRectMake(15.f, 5.f, [controlsView frame].size.height-10.f, [controlsView frame].size.height-10.f);
	[ASS(&_nowPlayingImageKey) setFrame:artworkFrame];
	
	CGRect firstFrame = CGRectMake(artworkFrame.origin.x + artworkFrame.size.width + 5.f, artworkFrame.origin.y + (isiPad() ? 24.f : 3.f), [controlsView frame].size.width-(artworkFrame.origin.x + artworkFrame.size.width + 5.f), pttopx(14.f));
	[ASS(&_artistLabel) setFrame:firstFrame];
	firstFrame.origin.y += firstFrame.size.height;
	[ASS(&_songLabel) setFrame:firstFrame];
	firstFrame.origin.y += firstFrame.size.height;
	[ASS(&_albumLabel) setFrame:firstFrame]; 

	CGFloat originX = [controlsView frame].size.width;
	CGFloat halfWidth = [controlsView frame].size.width/2;
	CGFloat baseY = isiPad() ? 28.f : 8.f;
	[ASS(&_backButtonKey) setFrame:CGRectMake(originX + halfWidth/3-15, baseY, 30, 27)];
	[ASS(&_playButtonKey) setFrame:CGRectMake(originX + halfWidth/3*2-11, baseY, 23, 26)];
	[ASS(&_forwardButtonKey) setFrame:CGRectMake(originX + halfWidth-15, baseY, 30, 27)];
	
	[ASS(&_repeatButton) setFrame:CGRectMake(originX*2 - halfWidth/3, baseY+3, 25, 21)];
	[ASS(&_shuffleButton) setFrame:CGRectMake(originX*2 - halfWidth/3 - 25, baseY+3, 25, 21)];
	
	[ASS(&_sliderKey) setFrame:CGRectMake(originX, baseY+27, [controlsView frame].size.width, 34.f)];
	[ASS(&_trackLabelKey) setFrame:CGRectMake(originX, baseY+49, [controlsView frame].size.width, pttopx(12.f))];
}

- (void)dealloc {
	NSLog(@"CALLED DEALLOC UPON FOLDER CLOSE IOS7");

	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[MPMusicPlayerController iPodMusicPlayer] endGeneratingPlaybackNotifications];
	
	draggingSlider = NO;
	
	objc_removeAssociatedObjects(self);
	
	%orig;
}
%end
%end

/* }}} */

/* FAFolderView {{{ */
// TODO: Check exactly how SBNewsstandFolderView handles all this shit! :P
// Meanwhile we seem to be fine...
%group FAFolderView5x6x
%hook SBIconController
- (void)willAnimateRotationToInterfaceOrientation:(int)orientation duration:(double)duration {
	%log;
	%orig;
	
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0) {
		SBFolderView *folderView = MSHookIvar<SBFolderView *>(self, "_folderView");
		if ([folderView isKindOfClass:%c(FAFolderView)]) {
			[(FAFolderView *)folderView rotateToOrientation:orientation];
		}
	}
}
%end

%subclass FAFolderView : FACommonFolderView
%new
- (Class)detailSliderClass {
	return %c(MPDetailSlider);
}

- (void)setRows:(NSUInteger)rows notchInfo:(SBNotchInfo)info orientation:(int)orientation {
	NSLog(@"ac3xx: %d %d %d -- %i", kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0, isiPad(), isPhone5(), (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 ? (isiPad() ? 20 : (isPhone5() ? 20 : 16)) : rows));
	%orig(kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 ? (isiPad() ? 20 : (isPhone5() ? 24 : 16)) : rows, info, orientation);
}

%new(@@:)
- (FAFolder *)folder {
	return MSHookIvar<FAFolder *>(self, "_folder");
}

%new(@@:)
- (UILabel *)groupLabel {
	return objc_getAssociatedObject(self, &_labelKey);
}

- (id)initWithFrame:(CGRect)frame {
	%log;
	
	if ((self = %orig)) {
		// Thanks to @nosdrew for this line which removes foldalbumd and fixes the most
		// annoying bug ever!
		[[UIApplication sharedApplication] launchMusicPlayerSuspended];
		
		[[MPMusicPlayerController iPodMusicPlayer] beginGeneratingPlaybackNotifications];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedStateChanged) name:MPMusicPlayerControllerPlaybackStateDidChangeNotification object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(receivedTrackChanged) name:MPMusicPlayerControllerNowPlayingItemDidChangeNotification object:nil];
	}
	
	return self;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
	UILabel *groupLabel = [self groupLabel];
	NSString *key = [(FAFolder *)[self folder] keyName];
	NSString *res = [[textField text] isEqualToString:@""] ? key : [textField text];
	
	NSDictionary *update = [NSDictionary dictionaryWithObject:res forKey:@"fakeTitle"];
	[[FAPreferencesHandler sharedInstance] optimizedUpdateKey:key withDictionary:update];
	
	// This is needed in case we get @"" from the text field.
	[[self folder] setDisplayName:res];
	
	//NSLog(@"[FoldMusic] res is %@", res);
	[groupLabel setText:res];
	//[groupLabel setFrame:groupFrame];
	
	%orig;
}

- (void)setIsEditing:(BOOL)editing animated:(BOOL)animated {
	%orig;
	
	UILabel *groupLabel = [self groupLabel];
	[groupLabel setHidden:editing];
}

%new(v@:i)
- (void)rotateToOrientation:(int)orientation {
	%log;
	
	if (isiPad()) {
		CGFloat width = UIInterfaceOrientationIsPortrait(orientation) ? 768 : 1024;
		CGFloat height = 546;
		CGRect subtitleLabelFrame = [objc_getAssociatedObject(self, &_subtitleLabelKey) frame];
		
		UIView *wrapper = objc_getAssociatedObject(self, &_wrapperKey);
		UIView *table = objc_getAssociatedObject(self, &_dataTableKey);
		UIView *control = objc_getAssociatedObject(self, &_controlsViewKey);
		
		CGSize size = (CGSize){UIInterfaceOrientationIsPortrait(orientation) ? 728 : 984, height-(subtitleLabelFrame.origin.y+25)};
		
		BOOL isLeft = table.frame.origin.x < 0;
		CGPoint tableOrigin = CGPointMake(isLeft ? -size.width : 20, table.frame.origin.y);
		CGPoint controlOrigin = CGPointMake(isLeft ? 20 : tableOrigin.x+size.width+20.f, control.frame.origin.y);
		
		[table setFrame:(CGRect){tableOrigin, size}];
		[control setFrame:(CGRect){controlOrigin, size}];
		[wrapper setFrame:(CGRect){wrapper.frame.origin, {width, height}}];
	}
}

- (void)setIconListView:(UIView *)view {
	CGFloat width = kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 ? (isiPad() ? (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 768 : 1024) : 320) : self.frame.size.width;
	CGFloat height = kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0 ? isiPad() ? 546 : isPhone5() ? 357 : 299 : self.frame.size.height;
	NSLog(@"ac3xx: height=%f", height);
	idx = 0;
	
	UIView *wrapper = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, width, height)] autorelease];
	
	SBFolder *folder = [self folder];
	MPMediaItemCollection *collection = [(FAFolder *)folder mediaCollection];
	
	UILabel *&groupLabel_ = MSHookIvar<UILabel *>(self, "_label");
	[groupLabel_ setHidden:YES];
	// TODO: Find somewhere to release this unused label.
	
	CGRect grFr = [groupLabel_ frame];
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0) {
		if (![collection isKindOfClass:[MPMediaPlaylist class]]) grFr.origin.y += 8.f;
		if (!isiPad()) grFr.origin.x = 20.f;
	}
	else if ([collection isKindOfClass:[MPMediaPlaylist class]]) grFr.origin.y += grFr.size.height/2 - 8;
	
	SBFolderTitleLabel *groupLabel = [[[%c(SBFolderTitleLabel) alloc] initWithFrame:grFr] autorelease];
	[groupLabel setFont:[groupLabel_ font]];
	[groupLabel setBackgroundColor:[UIColor clearColor]];
	[groupLabel setTextColor:[groupLabel_ textColor]];
	[groupLabel setText:[groupLabel_ text]];
	[groupLabel setFont:[[groupLabel font] fontWithSize:20.f]];
	[groupLabel setTextAlignment:UITextAlignmentLeft];
	[groupLabel setAdjustsFontSizeToFitWidth:YES];
	[groupLabel setMinimumFontSize:16.f];
	
	if (MSHookIvar<BOOL>(self, "_isEditing"))
		[groupLabel setHidden:YES];
	
	NSLog(@"%@", NSStringFromCGRect(groupLabel.frame));
	CGRect groupRect = isiPad() ?
		(CGRect){{20, groupLabel.frame.origin.y}, {648, 22}} :
		(CGRect){{groupLabel.frame.origin.x-7, groupLabel.frame.origin.y}, {230, 20}};
	
	[groupLabel setFrame:groupRect];
	groupFrame = [groupLabel frame];
	
	CGPoint subtitlePoint = CGPointMake(groupLabel.frame.origin.x, groupLabel.frame.origin.y+23);
	CGSize subtitleSize = isiPad() ?
		CGSizeMake(668, 16) :
		CGSizeMake(230, 16);
	
	CGRect subtitleLabel = (CGRect){subtitlePoint, subtitleSize};
	
	if ([[groupLabel font] pointSize] < 20.f) {
		[groupLabel setFrame:(CGRect){{groupLabel.frame.origin.x, groupLabel.frame.origin.y}, {groupLabel.frame.size.width, [[groupLabel font] pointSize]}}];
		subtitleLabel.origin.y -= (subtitleLabel.origin.y-[[groupLabel font] pointSize]);
	}
	
	[wrapper addSubview:groupLabel];
	objc_setAssociatedObject(self, &_labelKey, groupLabel, OBJC_ASSOCIATION_RETAIN);
	
	UITextField *&textField = MSHookIvar<UITextField *>(self, "_textField");
	[textField setPlaceholder:[(FAFolder *)[self folder] keyName]];
	[textField setFrame:(CGRect){{groupLabel.bounds.origin.x+5, groupLabel.bounds.origin.y+3}, {groupLabel.bounds.size.width, textField.frame.size.height-2}}];
	
	if (![collection isKindOfClass:[MPMediaPlaylist class]]) {
		SBFolderTitleLabel *artistLabel = [[[%c(SBFolderTitleLabel) alloc] initWithFrame:subtitleLabel] autorelease];
		[artistLabel setBackgroundColor:[UIColor clearColor]];
		[artistLabel setFont:[[groupLabel font] fontWithSize:16.f]];
		[artistLabel setAdjustsFontSizeToFitWidth:YES];
		[artistLabel setMinimumFontSize:12.f];
		[artistLabel setTextColor:[UIColor whiteColor]];
		[artistLabel setText:[[collection representativeItem] valueForProperty:MPMediaItemPropertyArtist]];
		
		if ([[artistLabel font] pointSize] < 16.f) {
			[artistLabel setFrame:(CGRect){artistLabel.frame.origin, {artistLabel.frame.size.width, [[artistLabel font] pointSize]}}];
		}
		
		objc_setAssociatedObject(self, &_subtitleLabelKey, artistLabel, OBJC_ASSOCIATION_RETAIN);
		[wrapper addSubview:artistLabel];
	}
	
	UIView *controllerContent = [[[UIView alloc] initWithFrame:CGRectMake((isiPad() ? 683 : 255), (groupLabel.bounds.origin.y+5), 60, 55)] autorelease];
	UIImage *musicImage = [UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/music.png"];
	UIImage *arrowImage = UIImageResize([UIImage imageWithContentsOfFile:@"/Library/Application Support/FoldAlbum/arrow.png"], CGSizeMake(20, 16));
	
	UIButton *musicButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[musicButton setFrame:CGRectMake(0, 0, 25, 25)];
	[musicButton setImage:musicImage forState:UIControlStateNormal];
	[musicButton addTarget:self action:@selector(showControlsCallout) forControlEvents:UIControlEventTouchUpInside];
	objc_setAssociatedObject(self, &_musicButtonKey, musicButton, OBJC_ASSOCIATION_RETAIN);
	
	UIButton *arrowButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[arrowButton setFrame:CGRectMake(35, 0, 25, 25)];
	[arrowButton setImage:arrowImage forState:UIControlStateNormal];
	[arrowButton addTarget:self action:@selector(gotoControls:) forControlEvents:UIControlEventTouchUpInside];
	
	[controllerContent addSubview:musicButton];
	[controllerContent addSubview:arrowButton];
	[wrapper addSubview:controllerContent];
	
	CGRect tableFrame = CGRectMake((isiPad() ? 20 : -1), subtitleLabel.origin.y+25, (isiPad() ? UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 728 : 984 : 322), height-(subtitleLabel.origin.y+25));
	NSLog(@"tableFrame: %@", NSStringFromCGRect(tableFrame));
	UITableView *dataTable = [[[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain] autorelease];
	NSLog(@"table frame: %@", NSStringFromCGRect([dataTable frame]));
	
	[dataTable setDelegate:self];
	[dataTable setDataSource:self];
	[dataTable setBackgroundColor:[UIColor clearColor]];
	[dataTable setSeparatorColor:UIColorFromHexWithAlpha(0xFFFFFF, 0.37)];
	if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0) [dataTable setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	
	[[dataTable layer] setBorderWidth:.8f];
	[[dataTable layer] setBorderColor:[UIColorFromHexWithAlpha(0xFFFFFF, 0.37) CGColor]];
	
	UISwipeGestureRecognizer *rig = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextItem:)] autorelease];
	[rig setDirection:UISwipeGestureRecognizerDirectionRight];
	UISwipeGestureRecognizer *lef = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextItem:)] autorelease];
	[lef setDirection:UISwipeGestureRecognizerDirectionLeft];
	
	[dataTable addGestureRecognizer:rig];
	[dataTable addGestureRecognizer:lef];
	
	objc_setAssociatedObject(self, &_dataTableKey, dataTable, OBJC_ASSOCIATION_RETAIN);
	[wrapper addSubview:dataTable];
	
	//%%%%%%%%%
	// Controls View
	//%%%%%%%%%
	
	UIView *controlsView = [[[UIView alloc] initWithFrame:(CGRect){{isiPad() ? tableFrame.origin.x+tableFrame.size.width+20.f : tableFrame.origin.x+tableFrame.size.width, tableFrame.origin.y}, tableFrame.size}] autorelease];
	[[controlsView layer] setBorderWidth:.8f];
	[[controlsView layer] setBorderColor:[UIColorFromHexWithAlpha(0xFFFFFF, 0.37) CGColor]];

	[self initializeControlViewWithSuperview:controlsView haveExtraView:YES];
	
	CGRect artworkFrame = CGRectMake(15, 15, 130, 130);
	[ASS(&_nowPlayingImageKey) setFrame:artworkFrame];
	
	CGRect firstFrame = CGRectMake(150, 25, 320-(artworkFrame.origin.x+artworkFrame.size.width+8), 12);
	[ASS(&_artistLabel) setFrame:firstFrame];
	firstFrame.origin.y += 14;
	[ASS(&_songLabel) setFrame:firstFrame];
	firstFrame.origin.y += 14;
	[ASS(&_albumLabel) setFrame:firstFrame]; 

	[ASS(&_backButtonKey) setFrame:CGRectMake(165, firstFrame.origin.y+27, 30, 27)];
	[ASS(&_playButtonKey) setFrame:CGRectMake(220, firstFrame.origin.y+27, 30, 27)];
	[ASS(&_forwardButtonKey) setFrame:CGRectMake(275, firstFrame.origin.y+27, 30, 27)];
	
	MPVolumeView *volumeView = [[[MPVolumeView alloc] initWithFrame:CGRectMake(165, firstFrame.origin.y+65, 140, 20)] autorelease];
	[controlsView addSubview:volumeView];
	
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 0, 155);
	CGPathAddLineToPoint(path, NULL, 320, 155);
	CAShapeLayer *shape = [CAShapeLayer layer];
	[shape setLineWidth:1.f];
	[shape setLineCap:kCALineCapRound];
	[shape setStrokeColor:[UIColorFromHexWithAlpha(0xFFFFFF, 0.37) CGColor]];
	[shape setPath:path];
	CGPathRelease(path);
	[[controlsView layer] addSublayer:shape];
	
	[ASS(&_extraViewKey) setFrame:CGRectMake(0, 155, 320, height-155)];
	[ASS(&_trackLabelKey) setFrame:CGRectMake(0, 20, 320, 12)];
	
	[ASS(&_sliderKey) setFrame:CGRectMake(0, 30, 320, [MPDetailSlider defaultHeight])];
	
	[ASS(&_repeatButton) setFrame:CGRectMake(15, 50, 25, 21)];
	[ASS(&_shuffleButton) setFrame:CGRectMake(285, 50, 25, 21)];
	
	objc_setAssociatedObject(self, &_controlsViewKey, controlsView, OBJC_ASSOCIATION_RETAIN);
	[wrapper addSubview:controlsView];
	
	objc_setAssociatedObject(self, &_wrapperKey, wrapper, OBJC_ASSOCIATION_RETAIN);
	[self addSubview:wrapper];
}

%new(v@:)
- (void)showControlsCallout {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMusicPlaybackState state = [music playbackState];
	
	UIView *content = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 130, 35)] autorelease];
	
	UIImage *play = PlayOrPauseImage(YES);
	UIImage *pause = PlayOrPauseImage(YES);
	UIImage *backward = [UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/prevtrack.png"];
	UIImage *forward = [UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/nexttrack.png"];
	
	UIButton *backwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[backwardButton setFrame:CGRectMake(10, 2.5, 30, 30)];
	[backwardButton setImage:backward forState:UIControlStateNormal];
	[backwardButton addTarget:self action:@selector(pressedBackwardButton) forControlEvents:UIControlEventTouchDown];
	[backwardButton addTarget:self action:@selector(releasedBackwardButton) forControlEvents:UIControlEventTouchUpInside];
	[backwardButton addTarget:self action:@selector(releasedBackwardButton) forControlEvents:UIControlEventTouchDragOutside];
	
	UIButton *playPauseButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[playPauseButton setFrame:CGRectMake(50, 2.5, 30, 30)];
	[playPauseButton setImage:(state == MPMusicPlaybackStatePlaying ? pause : play) forState:UIControlStateNormal];
	[playPauseButton addTarget:self action:@selector(clickedPlayButton:) forControlEvents:UIControlEventTouchUpInside];
	
	UIButton *forwardButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[forwardButton setFrame:CGRectMake(90, 2.5, 30, 30)];
	[forwardButton setImage:forward forState:UIControlStateNormal];
	[forwardButton addTarget:self action:@selector(pressedForwardButton) forControlEvents:UIControlEventTouchDown];
	[forwardButton addTarget:self action:@selector(releasedForwardButton) forControlEvents:UIControlEventTouchUpInside];
	[forwardButton addTarget:self action:@selector(releasedForwardButton) forControlEvents:UIControlEventTouchDragOutside];
	
	[content addSubview:backwardButton];
	[content addSubview:playPauseButton];
	[content addSubview:forwardButton];
	
	FACalloutView *alert = [[[FACalloutView alloc] init] autorelease];
	[alert placeQuitButtonInView:self];
	
	[alert setCenteredView:content animated:YES];
	[alert setAnchorPoint:CGPointMake((isiPad() ? 695.5 : 267.5), 25) boundaryRect:[[UIScreen mainScreen] applicationFrame] animate:YES];
	[self addSubview:alert];
}

%new(v@:@)
- (void)gotoControls:(UIButton *)btn {
	UITableView *table = objc_getAssociatedObject(self, &_dataTableKey);
	CGRect tableFrame = [table frame];

	UIView *controlsView = objc_getAssociatedObject(self, &_controlsViewKey);
	CGRect controlFrame = [controlsView frame];

	NSLog(@"%@ %@", table, controlsView);

	__block BOOL hideTable;
	[UIView animateWithDuration:.2f animations:^{
		if (tableFrame.origin.x >= (isiPad() ? 20 : -1)) {
			[table setFrame:(CGRect){{-table.frame.size.width, table.frame.origin.y}, table.frame.size}];
			[controlsView setFrame:tableFrame];

			if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0) {
				[table setAutoresizingMask:UIViewAutoresizingFlexibleRightMargin];
				[controlsView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
			}

			hideTable = YES;
		}

		else {
			[controlsView setFrame:(CGRect){{isiPad() ? controlsView.frame.origin.x+controlsView.frame.size.width+20.f : controlsView.frame.origin.x+controlsView.frame.size.width, controlsView.frame.origin.y}, controlsView.frame.size}];
			[table setFrame:controlFrame];

			if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0) {
				[table setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
				[controlsView setAutoresizingMask:UIViewAutoresizingFlexibleLeftMargin];
			}

			hideTable = NO;
		}
	}];

	[btn setTransform:CGAffineTransformMakeRotation(hideTable ? M_PI : 0.f)];
}

- (void)dealloc {
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[MPMusicPlayerController iPodMusicPlayer] endGeneratingPlaybackNotifications];
	
	draggingSlider = NO;
	
	objc_removeAssociatedObjects(self);
	
	%orig;
}
%end
%end
/* }}} */

/* Hooks {{{ */

/*%hook SBIconController
- (void)closeFolderAnimated:(BOOL)animated toSwitcher:(BOOL)switcher {
	%log;
	NSLog(@"Open Folder: %@", [self openFolder]);
	if (progTimer && [progTimer isValid]) {
		NSLog(@"[fm] Invalidating prog timer");
		[progTimer invalidate];
		progTimer = nil;
	}
		
	%orig;
}

- (void)setOpenFolder:(SBFolder *)folder {
	%log;
	NSLog(@"Open Folder: %@", [self openFolder]);
	if (progTimer && [progTimer isValid]) {
		NSLog(@"[fm] Invalidating prog timer");
		[progTimer invalidate];
		progTimer = nil;
	}
		
	%orig;
}
%end*/

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
	
	FAFolderIcon *icon = [[[%c(FAFolderIcon) alloc] initWithFolder:folder] autorelease];
	if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0) [icon setDelegate:[%c(SBIconController) sharedInstance]];
	
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
		if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0)
			[self insertIcon:icon atIndex:&iconIndex];
		else
			[[[[%c(SBIconController) sharedInstance] rootIconLists] objectAtIndex:[self index]] insertIcon:icon atIndex:iconIndex moveNow:YES];
	}
	
	else {
		if (kCFCoreFoundationVersionNumber < kCFCoreFoundationVersionNumber_iOS_6_0)
			[self insertIcon:icon atIndex:&index];
		else
			[[[[%c(SBIconController) sharedInstance] rootIconLists] objectAtIndex:[self index]] insertIcon:icon atIndex:index moveNow:YES];
	}
	
	[[%c(SBIconController) sharedInstance] updateCurrentIconListIndexAndVisibility];
	NSLog(@"[fm] omg!");
}
%end

%group FMIconImageHooks5x6x
%hook SBFolderIconView
- (BOOL)canReceiveGrabbedIcon:(id)icon {
	if ([[self icon] isKindOfClass:%c(FAFolderIcon)])
		return NO;
	
	if ([icon isKindOfClass:%c(FAFolderIcon)])
		return NO;
	
	return %orig;
}

- (void)iconImageDidUpdate:(SBIcon *)icon {
	%orig;
	
	if ([icon isKindOfClass:%c(FAFolderIcon)]) {
		CGFloat fr = isiPad() ? 67.7 : 52.7;
		UIImageView *imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(3.2, 2.2, fr, fr)] autorelease];
		[[imageView layer] setCornerRadius:8.f];
		[[imageView layer] setMasksToBounds:YES];
		
		UIImage *targetImage = nil;
		MPMediaItemCollection *collection = [(FAFolder *)[self folder] mediaCollection];
				
		if (![collection isKindOfClass:[MPMediaPlaylist class]]) {
			MPMediaItem *_item = [[collection items] objectAtIndex:0];
			MPMediaItemArtwork *artwork = [_item valueForProperty:MPMediaItemPropertyArtwork];
			
			UIImage *artworkImage = [artwork imageWithSize:[imageView frame].size];
			if (artworkImage) {
				targetImage = UIImageResize(artworkImage, [imageView frame].size);
			}
		}
		
		targetImage = targetImage ? targetImage : UIImageResize([UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/iPodUI.framework/CoverFlowPlaceHolder44.png"], [imageView frame].size);
		
		[imageView setImage:targetImage];
		
		objc_setAssociatedObject(self, &_iconImageViewKey, nil, OBJC_ASSOCIATION_ASSIGN);
		objc_setAssociatedObject(self, &_iconImageViewKey, imageView, OBJC_ASSOCIATION_RETAIN);
		[[[self subviews] objectAtIndex:0] addSubview:imageView];
	}
	
	else {
		UIImageView *imageView = objc_getAssociatedObject(self, &_iconImageViewKey);
		if (imageView != nil && [[[[self subviews] objectAtIndex:0] subviews] containsObject:imageView]) {
			[imageView removeFromSuperview];
			objc_setAssociatedObject(self, &_iconImageViewKey, nil, OBJC_ASSOCIATION_ASSIGN);
		}
	}
}
%end
%end

%group FMIconImageHooks7x
%hook SBFolderIconImageView
// URGENT FIXME: Make the logic of this less cumbersome, please.
- (void)setIcon:(SBFolderIcon *)icon animated:(BOOL)animated {
	%log;
	%orig;
	
	NSLog(@"ICON FOLDER IS %@", [icon folder]);

	// If we find the imageview, should we return; or reset it?
	// idk how caching works and this doesn't make scrolling slow, so let's keep it.
	if ([self viewWithTag:88])
		[[self viewWithTag:88] removeFromSuperview];

	if ([[icon folder] isKindOfClass:%c(FAFolder)]) {
		UIView *background = MSHookIvar<UIView *>(self, "_backgroundView");
		UIView *grid = MSHookIvar<UIView *>(self, "_pageGridContainer");
		if ([grid superview]) [grid removeFromSuperview];
		
		UIImage *targetImage = nil;
		MPMediaItemCollection *collection = [(FAFolder *)[icon folder] mediaCollection];
				
		UIImage *artworkImage = nil;
		for (MPMediaItem *_item in [collection items]) {
			MPMediaItemArtwork *artwork = [_item valueForProperty:MPMediaItemPropertyArtwork];
			if (artwork != nil) {
				artworkImage = [artwork imageWithSize:[background frame].size];
				if (artworkImage != nil) break;
			}
		}
		
		if (artworkImage) {
			//targetImage = UIImageResize(artworkImage, [background frame].size);
			targetImage = artworkImage;
		}
		// FIXME: Make it not blank if there's no resource.
		
		if (targetImage) {
			UIImageView *imageView = [[[UIImageView alloc] initWithFrame:[background frame]] autorelease];
			[[imageView layer] setCornerRadius:[[background layer] cornerRadius]];
			[[imageView layer] setMasksToBounds:YES];
			[imageView setImage:targetImage];
			[imageView setTag:88];
			[self addSubview:imageView];
			
			if ([background superview]) [background removeFromSuperview];
		}
		else {
			if (![background superview]) [self addSubview:background];
		}
	}
}

- (void)setFloatyFolderCrossfadeFraction:(float)arg1 {
	%orig;
	
	if ([[[self _folderIcon] folder] isKindOfClass:%c(FAFolder)])
		[[self viewWithTag:88] setAlpha:1 - arg1];
}
%end
%end

/*%hook SBFolderIcon
- (UIImage *)gridImageWithSkipping:(BOOL)skipping {
	if ([[self folder] isKindOfClass:%c(FAFolder)]) {
		UIImage *targetImage;
		MPMediaItemCollection *collection = [(FAFolder *)[self folder] mediaCollection];
		
		CGFloat fr = isiPad() ? 60 : 50;
		CGSize iconSize = CGSizeMake(fr, fr);
		
		if (![collection isKindOfClass:[MPMediaPlaylist class]]) {
			MPMediaItem *_item = [collection representativeItem];
			MPMediaItemArtwork *artwork = [_item valueForProperty:MPMediaItemPropertyArtwork];
			
			UIImage *artworkImage = [artwork imageWithSize:iconSize];
			if (artworkImage) {
				targetImage = UIImageResize(artworkImage, iconSize);
				goto got_it;
			}
		}
		
		targetImage = (UIImageResize([UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/iPodUI.framework/CoverFlowPlaceHolder44.png"], iconSize));
		
		got_it:
		return targetImage;
	}

	return %orig;
}
%end*/

%hook SBIconController
%new(@@:)
- (NSArray *)rootIconLists {
	if (kCFCoreFoundationVersionNumber >= 800)
		return [[[self _rootFolderController] contentView] iconListViews];

	return MSHookIvar<NSMutableArray *>(self, "_rootIconLists");
}

%new(@@:)
- (SBIconListModel *)firstAvailableModel {
	NSArray *rootIconLists = [self rootIconLists];
	NSUInteger count = [rootIconLists count];
	for (NSUInteger i=0; i<count; i++) {
		SBIconListView *view = [rootIconLists objectAtIndex:i];
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
	NSUInteger count = [keys count];
	for (NSUInteger i=0; i<count; i++) {
		NSDictionary *d = [keys objectAtIndex:i];
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
	NSUInteger count = [rootIconLists count];
	for (NSUInteger i=0; i<count; i++) {
		SBIconListView *iconListView = [rootIconLists objectAtIndex:i];
		SBIconListModel *model = [iconListView model];
		
		NSArray *icons = [model icons];
		NSUInteger iconsCount = [icons count];
		//NSLog(@"[!] Icons Count: %i", iconsCount);
		for (NSUInteger j=0; j<iconsCount; j++) {
			//NSLog(@"[!] Icon Index %i", j);
			SBIcon *icon = [icons objectAtIndex:j];
			if ([icon isKindOfClass:%c(FAFolderIcon)]) {
				FAFolder *folder = (FAFolder *)[(FAFolderIcon *)icon folder];
				
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

- (void)saveIconState {
	%orig;
	[self saveAlbumFolders];
}

%group FMSBIconModel5x
- (void)relayout {
	%orig;
	[[%c(SBIconController) sharedInstance] commitAlbumFolders];
}
%end

%group FMSBIconModel6x
- (void)layout {
	%orig;
	[[%c(SBIconController) sharedInstance] commitAlbumFolders];
}
%end
%end

/*%group FMUIImage6x
%hook UIImage
%new({CGRect={CGPoint=ff}{CGSize=ff}}@:I@I)
+ (CGRect)rectAtIndex:(unsigned)index forImage:(id)image maxCount:(unsigned)count { return CGRectZero; }

%new(I@:)
- (NSUInteger)numberOfRows { return 0; }

%new(I@:)
- (NSUInteger)numberOfColumns { return 0; }

%new(I@:)
- (NSUInteger)numberOfCells { return 0; }
%end
%end*/

/* }}} */

%ctor {
	dlopen("/Library/MobileSubstrate/DynamicLibraries/IconSupport.dylib", RTLD_NOW);
	[[objc_getClass("ISIconSupport") sharedInstance] addExtension:@"am.theiostre.foldalbum"];

	//dlopen("/System/Library/PrivateFrameworks/MusicUI.framework/MusicUI", RTLD_LAZY);
	
	// Init SBIconModel layouting hooks.
	if (kCFCoreFoundationVersionNumber >= kCFCoreFoundationVersionNumber_iOS_6_0) {
		%init(FMSBIconModel6x);
	}
	else {
		%init(FMSBIconModel5x);
	}
	
	// Init Icon Image Hooks
	if (kCFCoreFoundationVersionNumber >= 800)
		%init(FMIconImageHooks7x);
	else 
		%init(FMIconImageHooks5x6x);
	
	// Init global hooks and subclasses, and have a dynamic superclass for FACommonFolderView.
	Class commonSuperclass = kCFCoreFoundationVersionNumber >= 800 ? objc_getClass("SBFloatyFolderView") : objc_getClass("SBFolderView");
	%init(SBFolderView = commonSuperclass);
	
	// Init FAFolderView/FAFloatyFolderView depending on the iOS version.
	// This also solves Logos dependency ordering issues (issue #86)
	if (kCFCoreFoundationVersionNumber >= 800) %init(FAFolderView7x);
	else %init(FAFolderView5x6x);
	
	// TODO: FANotificationHandler should setup notification crap by itself, not through Tweak.xm
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
