/**
	Tweak.xm
	
	FoldMusic
  	version 1.3.0, July 15th, 2012

  Copyright (C) 2012 Daniel Ferreira
  				     Colégio Visconde de Porto Seguro
  					 
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
  matoe@matoe.co.cc
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

@interface UIDevice (FolderAlbums_iPad)
- (BOOL)isWildcat;
@end

// From IconSupport; I am on a BIG hurry sorry world.
#define isiPad() ([UIDevice instancesRespondToSelector:@selector(isWildcat)] && [[UIDevice currentDevice] isWildcat])

// From CyDelete: DHowett is awesome.
#define SBLocalizedString(key) \
	[[NSBundle mainBundle] localizedStringForKey:key value:@"None" table:@"SpringBoard"]

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

// Other globals
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
	
	int iconsTarget = isiPad() ? 15 : 11;
	for (int i=0; i<iconsTarget; i++)
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
	%log;
	%orig;
	objc_removeAssociatedObjects(self); // Please tell me this removes all associated object leaks.
}
%end

// TODO: Check exactly how SBNewsstandFolderView handles this
%subclass FAFolderView : SBFolderView
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

- (void)setIconListView:(UIView *)view {
	idx = 0;
	
	SBFolder *folder = [self folder];
	MPMediaItemCollection *collection = [(FAFolder *)folder mediaCollection];
	
	UILabel *&groupLabel_ = MSHookIvar<UILabel *>(self, "_label");
	[groupLabel_ setHidden:YES];
	// TODO: Find somewhere to release this unused label.
	
	CGRect grFr = [groupLabel_ frame];
	if ([collection isKindOfClass:[MPMediaPlaylist class]]) grFr.origin.y += grFr.size.height/2-8;
	
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
	
	CGRect groupRect = isiPad() ?
		(CGRect){{20, groupLabel.frame.origin.y}, {648, 22}} :
		(CGRect){{groupLabel.frame.origin.x-7, groupLabel.frame.origin.y}, {230, 20}};
	
	[groupLabel setFrame:groupRect];
	groupFrame = [groupLabel frame];
	
	CGPoint subtitlePoint = CGPointMake(groupLabel.frame.origin.x, groupLabel_.frame.origin.y+23);
	CGSize subtitleSize = isiPad() ?
		CGSizeMake(668, 16) :
		CGSizeMake(230, 16);
	
	CGRect subtitleLabel = (CGRect){subtitlePoint, subtitleSize};
	
	if ([[groupLabel font] pointSize] < 20.f) {
		[groupLabel setFrame:(CGRect){{groupLabel.frame.origin.x, groupLabel.frame.origin.y}, {groupLabel.frame.size.width, [[groupLabel font] pointSize]}}];
		subtitleLabel.origin.y -= (subtitleLabel.origin.y-[[groupLabel font] pointSize]);
	}
	
	[self addSubview:groupLabel];
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
		
		[self addSubview:artistLabel];
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
	[self addSubview:controllerContent];
	
	CGRect tableFrame = CGRectMake((isiPad() ? 20 : -1), subtitleLabel.origin.y+25, (isiPad() ? UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 728 : 984 : 322), self.bounds.size.height-(subtitleLabel.origin.y+25));
	UITableView *dataTable = [[[UITableView alloc] initWithFrame:tableFrame style:UITableViewStylePlain] autorelease];
	[dataTable setDelegate:self];
	[dataTable setDataSource:self];
	[dataTable setBackgroundColor:[UIColor clearColor]];
	[dataTable setSeparatorColor:UIColorFromHexWithAlpha(0xFFFFFF, 0.37)];
	[dataTable setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
	
	[[dataTable layer] setBorderWidth:.8f];
	[[dataTable layer] setBorderColor:[UIColorFromHexWithAlpha(0xFFFFFF, 0.37) CGColor]];
	
	UISwipeGestureRecognizer *rig = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextItem:)] autorelease];
	[rig setDirection:UISwipeGestureRecognizerDirectionRight];
	UISwipeGestureRecognizer *lef = [[[UISwipeGestureRecognizer alloc] initWithTarget:self action:@selector(nextItem:)] autorelease];
	[lef setDirection:UISwipeGestureRecognizerDirectionLeft];
	
	[dataTable addGestureRecognizer:rig];
	[dataTable addGestureRecognizer:lef];
	
	objc_setAssociatedObject(self, &_dataTableKey, dataTable, OBJC_ASSOCIATION_RETAIN);
	[self addSubview:dataTable];
	
	//%%%%%%%%%
	// Controls View
	//%%%%%%%%%
	
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *nowPlayingItem = [music nowPlayingItem];
	
	NSString *placeholderSong = @"Not Playing";
	UIImage *placeholderArtwork = UIImageResize([UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/noartplaceholder.png"], CGSizeMake(130, 130));
	
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
		else			{ artworkImage = placeholderArtwork; }
		
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
	
	UIView *controlsView = [[[UIView alloc] initWithFrame:(CGRect){{tableFrame.origin.x+tableFrame.size.width, tableFrame.origin.y}, tableFrame.size}] autorelease];
	[[controlsView layer] setBorderWidth:.8f];
	[[controlsView layer] setBorderColor:[UIColorFromHexWithAlpha(0xFFFFFF, 0.37) CGColor]];
	
	CGRect artworkFrame = CGRectMake(15, 15, 130, 130);
	CGRect firstFrame = CGRectMake(150, 25, 320-(artworkFrame.origin.x+artworkFrame.size.width+8), 12);
	
	UIImageView *artworkView = [[[UIImageView alloc] initWithFrame:artworkFrame] autorelease];
	[artworkView setImage:artworkImage];
	objc_setAssociatedObject(self, &_nowPlayingImageKey, artworkView, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:artworkView];
	
	// TODO: Frame correctly! :(
	
	UILabel *artistLabel = [[[UILabel alloc] initWithFrame:firstFrame] autorelease];
	[artistLabel setText:artist];
	[artistLabel setFont:[UIFont fontWithName:@".HelveticaNeueUI-Bold" size:12.f]];
	[artistLabel setTextAlignment:UITextAlignmentCenter];
	[artistLabel setTextColor:[UIColor whiteColor]];
	[artistLabel setBackgroundColor:[UIColor clearColor]];
	[artistLabel setShadowColor:[UIColor blackColor]];
	[artistLabel setShadowOffset:CGSizeMake(0, 1)];
	[artistLabel setHidden:(artist == nil)];
	
	objc_setAssociatedObject(self, &_artistLabel, artistLabel, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:artistLabel];
	
	firstFrame.origin.y += 14;
	
	UILabel *songLabel = [[[UILabel alloc] initWithFrame:firstFrame] autorelease];
	[songLabel setText:song];
	[songLabel setFont:[UIFont fontWithName:@".HelveticaNeueUI-Bold" size:12.f]];
	[songLabel setTextAlignment:UITextAlignmentCenter];
	[songLabel setTextColor:[UIColor whiteColor]];
	[songLabel setBackgroundColor:[UIColor clearColor]];
	[songLabel setShadowColor:[UIColor blackColor]];
	[songLabel setShadowOffset:CGSizeMake(0, 1)];
	
	objc_setAssociatedObject(self, &_songLabel, songLabel, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:songLabel];
	
	firstFrame.origin.y += 14;
	
	UILabel *albumLabel = [[[UILabel alloc] initWithFrame:firstFrame] autorelease];
	[albumLabel setText:album];
	[albumLabel setFont:[UIFont fontWithName:@".HelveticaNeueUI-Bold" size:12.f]];
	[albumLabel setTextAlignment:UITextAlignmentCenter];
	[albumLabel setTextColor:[UIColor whiteColor]];
	[albumLabel setBackgroundColor:[UIColor clearColor]];
	[albumLabel setShadowColor:[UIColor blackColor]];
	[albumLabel setShadowOffset:CGSizeMake(0, 1)];
	[albumLabel setHidden:(album == nil)];
	
	objc_setAssociatedObject(self, &_albumLabel, albumLabel, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:albumLabel];
	
	UIButton *backButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[backButton setFrame:CGRectMake(165, firstFrame.origin.y+27, 30, 27)];
	[backButton setImage:[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/prevtrack.png"] forState:UIControlStateNormal];
	[backButton addTarget:self action:@selector(pressedBackwardButton) forControlEvents:UIControlEventTouchDown];
	[backButton addTarget:self action:@selector(releasedBackwardButton) forControlEvents:UIControlEventTouchUpInside];
	[backButton addTarget:self action:@selector(releasedBackwardButton) forControlEvents:UIControlEventTouchDragOutside];
	[controlsView addSubview:backButton];
	
	UIImage *play = [UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/play.png"];
	UIImage *pause = [UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/pause.png"];
	UIButton *playButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[playButton setFrame:CGRectMake(220, firstFrame.origin.y+27, 30, 27)];
	[playButton setImage:(state == MPMusicPlaybackStatePlaying ? pause : play) forState:UIControlStateNormal];
	[playButton addTarget:self action:@selector(clickedPlayButton:) forControlEvents:UIControlEventTouchUpInside];
	objc_setAssociatedObject(self, &_playButtonKey, playButton, OBJC_ASSOCIATION_RETAIN);
	[controlsView addSubview:playButton];
	
	UIButton *nextButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[nextButton setFrame:CGRectMake(275, firstFrame.origin.y+27, 30, 27)];
	[nextButton setImage:[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/nexttrack.png"] forState:UIControlStateNormal];
	[nextButton addTarget:self action:@selector(pressedForwardButton) forControlEvents:UIControlEventTouchDown];
	[nextButton addTarget:self action:@selector(releasedForwardButton) forControlEvents:UIControlEventTouchUpInside];
	[nextButton addTarget:self action:@selector(releasedForwardButton) forControlEvents:UIControlEventTouchDragOutside];
	[controlsView addSubview:nextButton];
	
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
	
	UIView *extraView = [[[UIView alloc] initWithFrame:CGRectMake(0, 155, 320, self.frame.size.height-155)] autorelease];
	
	NSString *trackText;
	if (cur > -1 && tot > -1)
		trackText = [NSString stringWithFormat:@"Track %i of %i", cur, tot];
	else
		trackText = @"Track -- of --";
	
	UILabel *trackLabel = [[[UILabel alloc] initWithFrame:CGRectMake(0, 20, 320, 12)] autorelease];
	[trackLabel setText:trackText];
	[trackLabel setFont:[UIFont fontWithName:@".HelveticaNeueUI-Bold" size:12.f]];
	[trackLabel setTextAlignment:UITextAlignmentCenter];
	[trackLabel setTextColor:[UIColor whiteColor]];
	[trackLabel setBackgroundColor:[UIColor clearColor]];
	[trackLabel setShadowColor:[UIColor blackColor]];
	[trackLabel setShadowOffset:CGSizeMake(0, 1)];
	
	objc_setAssociatedObject(self, &_trackLabelKey, trackLabel, OBJC_ASSOCIATION_RETAIN);
	[extraView addSubview:trackLabel];
	
	MPDetailSlider *slider = [[[MPDetailSlider alloc] initWithFrame:CGRectMake(0, 30, 320, [MPDetailSlider defaultHeight])] autorelease];
	[slider setAllowsDetailScrubbing:YES];
	[slider setDuration:dur];
	[slider setValue:pla animated:NO];
	[slider setDelegate:self];
	
	if (state != MPMusicPlaybackStateStopped || state != MPMusicPlaybackStatePaused || state != MPMusicPlaybackStateInterrupted) {
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
	
	objc_setAssociatedObject(self, &_sliderKey, slider, OBJC_ASSOCIATION_RETAIN);
	[extraView addSubview:slider];
	
	NSString *repeatImageName = (
		repeatMode == MPMusicRepeatModeAll ? @"repeat_on.png" :
		repeatMode == MPMusicRepeatModeOne ? @"repeat_on_1.png" :
		@"repeat_off.png");
	UIImage *repeatImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Frameworks/MediaPlayer.framework/%@", repeatImageName]];
	UIButton *repeatButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[repeatButton setFrame:CGRectMake(15, 50, 25, 21)];
	[repeatButton setImage:repeatImage forState:UIControlStateNormal];
	[repeatButton addTarget:self action:@selector(pressedRepeatButton) forControlEvents:UIControlEventTouchUpInside];
	objc_setAssociatedObject(self, &_repeatButton, repeatButton, OBJC_ASSOCIATION_RETAIN);
	[extraView addSubview:repeatButton];
	
	NSString *shuffleImageName = (
		shuffleMode != MPMusicShuffleModeOff ? @"shuffle_on.png" :
		@"shuffle_off.png");
	UIImage *shuffleImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Frameworks/MediaPlayer.framework/%@", shuffleImageName]];
	UIButton *shuffleButton = [UIButton buttonWithType:UIButtonTypeCustom];
	[shuffleButton setFrame:CGRectMake(285, 50, 25, 21)];
	[shuffleButton setImage:shuffleImage forState:UIControlStateNormal];
	[shuffleButton addTarget:self action:@selector(pressedShuffleButton) forControlEvents:UIControlEventTouchUpInside];
	objc_setAssociatedObject(self, &_shuffleButton, shuffleButton, OBJC_ASSOCIATION_RETAIN);
	[extraView addSubview:shuffleButton];
	
	[controlsView addSubview:extraView];
	
	objc_setAssociatedObject(self, &_controlsViewKey, controlsView, OBJC_ASSOCIATION_RETAIN);
	[self addSubview:controlsView];
}

%new(v@:)
- (void)showControlsCallout {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMusicPlaybackState state = [music playbackState];
	
	UIView *content = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, 130, 35)] autorelease];
	
	UIImage *play = [UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/play.png"];
	UIImage *pause = [UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/pause.png"];
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

%new(v@:)
- (void)receivedTrackChanged {
	%log;
	
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
		else artworkImage = UIImageResize([UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/noartplaceholder.png"], CGSizeMake(130, 130));
		
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
		artworkImage = UIImageResize([UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/noartplaceholder.png"], CGSizeMake(130, 130));
		
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
}

%new(v@:)
- (void)receivedStateChanged {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMusicPlaybackState state = [music playbackState];
	
	const char *playImage = state==MPMusicPlaybackStatePlaying || state==MPMusicPlaybackStateSeekingForward || state==MPMusicPlaybackStateSeekingBackward ? "pause.png" : "play.png";
	[objc_getAssociatedObject(self, &_playButtonKey) setImage:[UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Frameworks/MediaPlayer.framework/%s", playImage]] forState:UIControlStateNormal];
	
	/*if (!progTimer || ![progTimer isValid]) progTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
	if (!(state != MPMusicPlaybackStateStopped || state != MPMusicPlaybackStatePaused || state != MPMusicPlaybackStateInterrupted)) {
		draggingSlider = YES;
	}*/
	
	if (state != MPMusicPlaybackStateStopped || state != MPMusicPlaybackStatePaused || state != MPMusicPlaybackStateInterrupted) {
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
	
	if (progTimer != nil) {
		if ([progTimer isValid]) {
			[progTimer invalidate];
			progTimer = [NSTimer scheduledTimerWithTimeInterval:1.f target:self selector:@selector(updateSlider) userInfo:nil repeats:YES];
		}
	}
}

%new(v@:@)
- (void)detailSliderTrackingDidBegin:(UISlider *)slider {
	draggingSlider = YES;
}

%new(v@:@)
- (void)detailSliderTrackingDidEnd:(UISlider *)slider {
	draggingSlider = NO;
}

%new(v@:@)
- (void)detailSliderTrackingDidCancel:(UISlider *)slider {
	draggingSlider = NO;
}

%new(v@:@)
- (void)clickedPlayButton:(UIButton *)button {
	MPMusicPlayerController *music = [MPMusicPlayerController iPodMusicPlayer];
	MPMediaItem *item = [music nowPlayingItem];
	MPMusicPlaybackState state = [music playbackState];
	
	if (!item) {
		MPMediaItemCollection *collection = [(FAFolder *)[self folder] mediaCollection];
		[music setQueueWithItemCollection:collection];
	}
	
	UIButton *controlsButton = objc_getAssociatedObject(self, &_playButtonKey);
	if (state == MPMusicPlaybackStatePlaying) {
		if (![button isEqual:controlsButton]) [button setImage:[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/play.png"] forState:UIControlStateNormal];
		[music pause];
	}
	
	else {
		if (![button isEqual:controlsButton]) [button setImage:[UIImage imageWithContentsOfFile:@"/System/Library/Frameworks/MediaPlayer.framework/pause.png"] forState:UIControlStateNormal];
		[music play];
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
	
	const char *imageTitle = (
		newMode == MPMusicRepeatModeAll ? "repeat_on.png" :
		newMode == MPMusicRepeatModeOne ? "repeat_on_1.png" :
		"repeat_off.png");
	
	UIImage *repeatImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Frameworks/MediaPlayer.framework/%s", imageTitle]];
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
	
	const char *imageTitle = (
		newMode == MPMusicShuffleModeSongs ? "shuffle_on.png" :
		"shuffle_off.png");
	
	UIImage *shuffleImage = [UIImage imageWithContentsOfFile:[NSString stringWithFormat:@"/System/Library/Frameworks/MediaPlayer.framework/%s", imageTitle]];
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

%new(v@:@)
- (void)gotoControls:(UIButton *)btn {
	UITableView *table = objc_getAssociatedObject(self, &_dataTableKey);
	CGRect tableFrame = [table frame];
	
	UIView *controlsView = objc_getAssociatedObject(self, &_controlsViewKey);
	CGRect controlFrame = [controlsView frame];
	
	__block BOOL hideTable;
	[UIView animateWithDuration:.2f animations:^{
		if (tableFrame.origin.x >= (isiPad() ? 20 : -1)) {
			[table setFrame:(CGRect){{-table.frame.size.width, table.frame.origin.y}, table.frame.size}];
			[controlsView setFrame:tableFrame];
			
			hideTable = YES;
		}
		
		else {
			[controlsView setFrame:(CGRect){{controlsView.frame.origin.x+controlsView.frame.size.width, controlsView.frame.origin.y}, controlsView.frame.size}];
			[table setFrame:controlFrame];
			
			hideTable = NO;
		}
	}];
	
	[btn setTransform:CGAffineTransformMakeRotation(hideTable ? M_PI : 0.f)];
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
	
	NSArray *visibleCells = [(UITableView *)[rec view] visibleCells];
	NSUInteger count = [visibleCells count];
	for (NSUInteger i=0; i<count; i++)
		[[visibleCells objectAtIndex:i] setDetailProperty:[_itemKeys objectAtIndex:idx] change:YES];
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
			if (state == MPMusicPlaybackStatePlaying) {
				[music pause];
				goto end;
			}
		
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

- (void)dealloc {
	%log;
	NSLog(@"DEALLOC WHAT HCHDBCHJWEBCHJEWBCEGHUW");
	NSLog(@"[FoldMusic] Deallocating Music Folder %@", [(FAFolder *)[self folder] keyName]);
	
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[[MPMusicPlayerController iPodMusicPlayer] endGeneratingPlaybackNotifications];
	
	draggingSlider = NO;
	
	objc_removeAssociatedObjects(self);
	
	%orig;
}

- (void)release {
	%log;
	%orig;
}
%end

/*%%%%%%%%%%%
%% Hooks
%%%%%%%%%%%*/

%hook SBIconController
- (void)closeFolderAnimated:(BOOL)animated toSwitcher:(BOOL)switcher {
	%log;
	if (progTimer && [progTimer isValid]) {
		NSLog(@"[fm] Invalidating prog timer");
		[progTimer invalidate];
		progTimer = nil;
	}
		
	%orig;
}
%end

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

- (void)iconImageDidUpdate:(SBIcon *)icon {
	%orig;
	
	UIImageView *imageView = MSHookIvar<UIImageView *>(self, "_iconImageView");
	
	CGRect fr = [imageView frame];
	fr.origin.y -= 1;
	fr.origin.x -= 1;
	fr.size.height += 3;
	fr.size.width += 3;
	[imageView setFrame:fr];
	
	[[imageView layer] setCornerRadius:8.f];
	[[imageView layer] setMasksToBounds:YES];
}
%end

%hook SBFolderIcon
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
		
		targetImage = UIImageResize([UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/iPodUI.framework/CoverFlowPlaceHolder44.png"], iconSize);
		
		got_it:
		return targetImage;
	}

	return %orig;
}
%end

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

/*// TODO: SBMediaIdkNotification
%hook SBMediaController
- (void)setNowPlayingInfo:(id)info {
	NSLog(@"[FoldMusic] Set Now Playing Info");
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FAChangedPlayingInfo" object:nil];
	%orig;
}
%end*/

%ctor {
	// FIXME: Do we need IconSupport?
	dlopen("/Library/MobileSubstrate/DynamicLibraries/IconSupport.dylib", RTLD_NOW);
	[[objc_getClass("ISIconSupport") sharedInstance] addExtension:@"am.theiostre.foldalbum"];
	
	// Init hooks
	%init;
	
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