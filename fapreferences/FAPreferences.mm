#import <Preferences/PSListController.h>
#import <Preferences/PSSpecifier.h>
#import <Preferences/PSTextFieldSpecifier.h>
#import <AppSupport/CPDistributedMessagingCenter.h>
#include <objc/runtime.h>

#import "FAMediaPickerController.h"

// %%%%%%%%%%%
// %%%%%%%%%%%

@interface FAFolderSetterController : PSListController <FAMediaPickerControllerDelegate> {
	NSString *_contentTitle;
}
@end

@interface FAPreferencesListController : PSListController
- (NSArray *)loadSpecifiers;
@end

// %%%%%%%%%%%
// %%%%%%%%%%%

@implementation FAFolderSetterController
- (NSArray *)_extraSpecifiersWithPlaceholder:(NSString *)placeholder {
	PSSpecifier *separator = [PSSpecifier emptyGroupSpecifier];
	PSTextFieldSpecifier *custom = [[PSTextFieldSpecifier preferenceSpecifierNamed:@"Custom title" target:self set:@selector(setCustom:forSpec:) get:@selector(customForSpec:) detail:nil cell:PSEditTextCell edit:nil] retain];
	[custom setPlaceholder:placeholder];
	PSSpecifier *dlt = [PSSpecifier preferenceSpecifierNamed:@"Delete folder" target:self set:NULL get:NULL detail:Nil cell:PSButtonCell edit:Nil];
	dlt->action = @selector(deleteFolder);
	
	return [NSArray arrayWithObjects:separator,custom,dlt,nil];
}

- (id)specifiers {
	NSString *content_ = [[self specifier] name];
	_contentTitle = [content_ isEqualToString:@"\u266B New"] ? @"\u266B" : content_;
	if (!_contentTitle) {
		[[self navigationController] popViewControllerAnimated:YES];
		return nil;
	}
	
	if (!_specifiers) {
		PSSpecifier *grp = [PSSpecifier emptyGroupSpecifier];
		PSSpecifier *detail = [PSSpecifier preferenceSpecifierNamed:@"Content" target:self set:NULL get:@selector(contentTitle) detail:objc_getClass("PSListItemsController") cell:PSLinkListCell edit:Nil];
		[grp setProperty:@"For custom folder content, create a playlist on iTunes or at the Music app." forKey:@"footerText"];
		detail->action = @selector(openPicker);
		
		NSMutableArray *specifiers_ = [NSMutableArray arrayWithObjects:grp, detail, nil];
		if (![_contentTitle isEqualToString:@"\u266B"])
			[specifiers_ addObjectsFromArray:[self _extraSpecifiersWithPlaceholder:_contentTitle]];
		
		_specifiers = [specifiers_ retain];
	}
	
	return _specifiers;
}

- (NSString *)contentTitle {
	return _contentTitle;
}

- (NSString *)customForSpec:(PSSpecifier *)spec {
	CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.server"];
	
	if (([[[messagingCenter sendMessageAndReceiveReplyName:@"KeyExists" userInfo:[NSDictionary dictionaryWithObject:_contentTitle forKey:@"Key"]] objectForKey:@"Result"] boolValue])) {
		NSDictionary *dict = [[messagingCenter sendMessageAndReceiveReplyName:@"ObjectForKey" userInfo:[NSDictionary dictionaryWithObject:_contentTitle forKey:@"Key"]] objectForKey:@"Result"];
		return [dict objectForKey:@"fakeTitle"];
	}
	
	return nil;
}

- (void)setCustom:(NSString *)custom forSpec:(PSSpecifier *)spec {
	CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.server"];
	
	if (([[[messagingCenter sendMessageAndReceiveReplyName:@"KeyExists" userInfo:[NSDictionary dictionaryWithObject:_contentTitle forKey:@"Key"]] objectForKey:@"Result"] boolValue])) {
		NSDictionary *dict = [NSDictionary dictionaryWithObject:custom forKey:@"fakeTitle"];
		[messagingCenter sendMessageName:@"OptimizedUpdateKey" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:_contentTitle,@"Key", dict,@"Dictionary", nil]];
	}
	
	[messagingCenter sendMessageName:@"Relayout" userInfo:nil];
}
	
- (void)deleteFolder {
	CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.server"];
	
	if (![_contentTitle isEqualToString:@"\u266B"])
		[messagingCenter sendMessageName:@"RemoveKey" userInfo:[NSDictionary dictionaryWithObject:_contentTitle forKey:@"Key"]];
	
	NSMutableArray *specs = [NSMutableArray arrayWithArray:[(PSListController *)[self parentController] specifiers]];
	[specs removeObject:[self specifier]];
	[(PSListController *)[self parentController] setSpecifiers:specs];
	
	[[self navigationController] popViewControllerAnimated:YES];
	[messagingCenter sendMessageName:@"Relayout" userInfo:nil];
}

- (void)openPicker {
	FAMediaPickerController *picker = [[[FAMediaPickerController alloc] init] autorelease];
	[picker setPickerDelegate:self];
	
	[self presentModalViewController:picker animated:YES];
}

- (void)didPressCancelButtonAtPicker:(FAMediaPickerController *)picker {
    [self dismissModalViewControllerAnimated:YES];
}

- (void)didSelectCollection:(MPMediaItemCollection *)collection atPicker:(FAMediaPickerController *)picker {
	[self dismissModalViewControllerAnimated:YES];
	
	CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.server"];
	
	NSData *collectionData = [NSKeyedArchiver archivedDataWithRootObject:collection];
	NSString *res = [collection isKindOfClass:[MPMediaPlaylist class]] ?
		[collection valueForProperty:MPMediaPlaylistPropertyName] :
		[[collection representativeItem] valueForProperty:MPMediaItemPropertyAlbumTitle];
	
	// TODO: Random identifier check
	if (([[[messagingCenter sendMessageAndReceiveReplyName:@"KeyExists" userInfo:[NSDictionary dictionaryWithObject:res forKey:@"Key"]] objectForKey:@"Result"] boolValue])) {
		UIAlertView *alertView = [[[UIAlertView alloc] initWithTitle:@"FoldAlbum" message:@"There is already a folder which selected this album/playlist. Ignoring choice." delegate:nil cancelButtonTitle:@"Dismiss" otherButtonTitles:nil] autorelease];
		[alertView show];
		return;
	}
	
	NSMutableDictionary *newIcon = [NSMutableDictionary dictionary];
	[newIcon setObject:[NSNumber numberWithInteger:-1] forKey:@"listIndex"];
	[newIcon setObject:[NSNumber numberWithInteger:-1] forKey:@"iconIndex"];
	[newIcon setObject:collectionData forKey:@"mediaCollection"];
	
	[messagingCenter sendMessageName:@"UpdateKey" userInfo:[NSDictionary dictionaryWithObjectsAndKeys:newIcon,@"Dictionary", res,@"Key", nil]];
	
	if (([[[messagingCenter sendMessageAndReceiveReplyName:@"KeyExists" userInfo:[NSDictionary dictionaryWithObject:_contentTitle forKey:@"Key"]] objectForKey:@"Result"] boolValue])) {
		[messagingCenter sendMessageName:@"RemoveKey" userInfo:[NSDictionary dictionaryWithObject:_contentTitle forKey:@"Key"]];
	}
	
	[messagingCenter sendMessageName:@"Relayout" userInfo:nil];
	
	if ([_contentTitle isEqualToString:@"\u266B"])
		[self addSpecifiersFromArray:[self _extraSpecifiersWithPlaceholder:res]];
	else {
		PSTextFieldSpecifier *custom = [self specifierAtIndex:3];
		[custom setPlaceholder:res];
		[self reloadSpecifier:custom animated:YES];
	}
	
	_contentTitle = res;
	
	[self reloadSpecifierAtIndex:0 animated:YES];
	[[self navigationItem] setTitle:_contentTitle];
	[[self specifier] setName:_contentTitle];
	[(PSListController *)[self parentController] reloadSpecifier:[self specifier] animated:YES];
}
@end

@implementation FAPreferencesListController
- (id)specifiers {
	if (!_specifiers) {
		_specifiers = [[self loadSpecifiers] retain];
	}
	
	return _specifiers;
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	UIBarButtonItem *add = [[[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(createEntry)] autorelease];
	[[self navigationItem] setRightBarButtonItem:add];
}

- (void)createEntry {
	PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:@"\u266B New" target:self set:NULL get:NULL detail:objc_getClass("FAFolderSetterController") cell:PSLinkCell edit:Nil];
	[self insertSpecifier:spec atIndex:[[self specifiers] count]-1 animated:YES];
}

- (NSArray *)loadSpecifiers {
	NSMutableArray *ret = [NSMutableArray array];
	
	// TODO: Don't load anything from that plist s_s
	NSArray *firstObjects = [self loadSpecifiersFromPlistName:@"FAPreferences" target:self];
	[ret addObjectsFromArray:firstObjects];
	
	CPDistributedMessagingCenter *messagingCenter = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.server"];
	NSArray *dicts = [[messagingCenter sendMessageAndReceiveReplyName:@"AllKeys" userInfo:nil] objectForKey:@"Result"];
	
	for (NSDictionary *dict in dicts) {
		PSSpecifier *spec = [PSSpecifier preferenceSpecifierNamed:[dict objectForKey:@"keyTitle"] target:self set:NULL get:NULL detail:[FAFolderSetterController class] cell:PSLinkCell edit:Nil];
		[ret addObject:spec];
	}
	
	PSSpecifier *about = [PSSpecifier emptyGroupSpecifier];
	[about setProperty:@"Idea by Ariel Aouizerate (@AAouiz), coded by theiostream (@ferreiradaniel2) in 2012." forKey:@"footerText"];
	[ret addObject:about];
	
	return ret;
}
@end
