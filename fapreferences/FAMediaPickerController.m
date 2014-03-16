/**
	fapreferences/FAMediaPickerController.m
	
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

/*
	TODO:
	
	This picker controller retains itself to playlist/album selection.
	By doing so, I might have made some APIs inside it not dynamic.
	(even though it shouldn't be used by anything else)
	
	Anyways, if you have the time, please patch it in order to
	make code sustainable for future adding of features like
	Artist/other picking.
	
	Also, it might be a good idea to create a 'base'
	internal media picker controller and have playlist one,
	album one, idfk one as a subclass.
	
	asdfg; this gets only dirtier and dirtier...
*/

#import "FAMediaPickerController.h"
#import "FAMediaPickerInternal.h"
#import "MPMediaItemCollection+Playable.h"

#include <dlfcn.h>
@interface UIImage (FAImageNamedInBundle)
+ (UIImage *)imageNamed:(NSString *)name inBundle:(NSBundle *)bundle;
@end

static UIImage *MediaPlayerImage(NSString *name) {
	return [UIImage imageNamed:name inBundle:[NSBundle bundleWithIdentifier:@"com.apple.MediaPlayer"]];
}
static UIImage *MusicUIImage(NSString *name) {
	if (![NSBundle bundleWithIdentifier:@"com.apple.MusicUI"]) dlopen("/System/Library/PrivateFrameworks/MusicUI.framework/MusicUI", RTLD_LAZY);
	
	NSBundle *bundle = [NSBundle bundleWithIdentifier:@"com.apple.MusicUI"];
	return [UIImage imageNamed:name inBundle:bundle];
}

static UIImage *UIImageResize(UIImage *image, CGSize newSize) {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    
    UIGraphicsEndImageContext();
    return newImage;
}

@implementation FAInternalMediaPickerController
- (FAInternalMediaPickerController *)initWithType:(int)type controller:(FAMediaPickerController *)ctrl {
	if ((self = [super initWithStyle:UITableViewStylePlain])) {
		_placeholder = [UIImageResize(MediaPlayerImage(@"noartplaceholder.png"), CGSizeMake(55, 55)) retain];
		
		_type = type;
		_controller = ctrl;
		
		MPMediaQuery *query = _type==0 ? [MPMediaQuery albumsQuery] : [MPMediaQuery playlistsQuery];
		NSMutableArray *change = [NSMutableArray arrayWithArray:[query collections]];
		for (MPMediaItemCollection *collection in change) {
			if ([collection hasNoPlayableItems])
				[change removeObject:collection];
		}
		
		_collections = [change retain];
		
		[self setTitle:(_type==0 ? @"Albums" : @"Playlists")];
	}
	
	return self;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	UIBarButtonItem *cancelItem = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemCancel target:self action:@selector(didPressCancel)] autorelease];
	[[self navigationItem] setRightBarButtonItem:cancelItem];
}

- (NSString *)titleForCollection:(MPMediaItemCollection *)collection {
	MPMediaEntity *parse = _type==0 ? (MPMediaEntity *)[collection representativeItem] : (MPMediaEntity *)collection;
	NSString *property = _type==0 ? MPMediaItemPropertyAlbumTitle : MPMediaPlaylistPropertyName;
	NSString *ret = [parse valueForProperty:property];
	
	// TODO: add some additional checking so playlists with no title (possible?) won't be named 'Custom set'
	return ret ? ret : @"\u2603 Custom set";
}

- (NSString *)subtitleForCollection:(MPMediaItemCollection *)collection {
	return [[collection representativeItem] valueForProperty:MPMediaItemPropertyArtist];
}

- (UIImage *)placeholderImageForCollection:(MPMediaItemCollection *)collection {
    MPMediaItemArtwork *artwork = [[collection representativeItem] valueForProperty:MPMediaItemPropertyArtwork];
    
    UIImage *artworkImage = [artwork imageWithSize:CGSizeMake(55, 55)];
    if (artworkImage)
    	return artworkImage;
    
    return _placeholder;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
	return _type==0 ? 55.f : [super tableView:tableView heightForRowAtIndexPath:indexPath];
}

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView {
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return [_collections count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    static NSString *CellIdentifier = @"FAPlaylistTableViewCell";
    MPMediaItemCollection *collection = [_collections objectAtIndex:[indexPath row]];
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellIdentifier];
    if (cell == nil) {
        UITableViewCellStyle enm = _type==0 ? UITableViewCellStyleSubtitle : UITableViewCellStyleDefault;
        cell = [[[UITableViewCell alloc] initWithStyle:enm reuseIdentifier:CellIdentifier] autorelease];
    }
    
    [[cell textLabel] setText:[self titleForCollection:collection]];
    if (_type == 0) {
    	[[cell detailTextLabel] setText:[self subtitleForCollection:collection]];
    	[[cell imageView] setFrame:CGRectMake(0, 0, 55, 55)]; // FIXME: Is this too dirty?
		[[cell imageView] setImage:[self placeholderImageForCollection:collection]];
	}
    
    return cell;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
	id<FAMediaPickerControllerDelegate> _delegate = [_controller pickerDelegate];
	
	if (![_delegate respondsToSelector:@selector(didSelectCollection:atPicker:)]) {
		NSLog(@"[FolderAlbums] Internal error.");
		return;
	}
	
	[_delegate didSelectCollection:[_collections objectAtIndex:[indexPath row]] atPicker:_controller];
}

- (void)didPressCancel {
	id<FAMediaPickerControllerDelegate> _delegate = [_controller pickerDelegate];
	
	if (![_delegate respondsToSelector:@selector(didPressCancelButtonAtPicker:)]) {
		NSLog(@"[FolderAlbums] Internal error.");
		return;
	}
	
	[_delegate didPressCancelButtonAtPicker:_controller];
}

- (void)dealloc {
	[_collections release];
	[_placeholder release];
	[super dealloc];
}
@end

@implementation FAMediaPickerController
- (id<FAMediaPickerControllerDelegate>)pickerDelegate {
	return _pickerDelegate;
}

- (void)setPickerDelegate:(id<FAMediaPickerControllerDelegate>)delegate {
	_pickerDelegate = delegate;
}

- (void)viewDidLoad {
	FAInternalMediaPickerController *albums_ = [[[FAInternalMediaPickerController alloc] initWithType:0 controller:self] autorelease];
	UINavigationController *albums = [[[UINavigationController alloc] initWithRootViewController:albums_] autorelease];
	
	UIImage *albumsImage;
	if (kCFCoreFoundationVersionNumber >= 800)
		albumsImage = MusicUIImage(@"TabBarImage-Albums.png");
	else
		albumsImage = [UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/iPodUI.framework/BarAlbums.png"];
	[[albums tabBarItem] setImage:albumsImage];
	
	FAInternalMediaPickerController *playlists_ = [[[FAInternalMediaPickerController alloc] initWithType:1 controller:self] autorelease];
	UINavigationController *playlists = [[[UINavigationController alloc] initWithRootViewController:playlists_] autorelease];
	
	UIImage *playlistsImage;
	if (kCFCoreFoundationVersionNumber >= 800)
		playlistsImage = MusicUIImage(@"TabBarImage-Playlists.png");
	else
		playlistsImage = [UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/iPodUI.framework/BarPlaylists.png"];
	[[playlists tabBarItem] setImage:playlistsImage];
	
	NSArray *controllers = [NSArray arrayWithObjects:albums, playlists, nil];
	[self setViewControllers:controllers animated:YES];
}
@end
