/**
	FAFolderCell.m
	
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

// UI by Maximus. (@0_Maximus_0). He's also an awesome developer.

#import "FAFolderCell.h"

@interface UIDevice (blah_fuck)
- (BOOL)isWildcat;
@end

#define isiPad() ([UIDevice instancesRespondToSelector:@selector(isWildcat)] && [[UIDevice currentDevice] isWildcat])

// FIXME: I repeat this function declaration here and at FAMediaPickerController.
static UIImage *UIImageResize(UIImage *image, CGSize newSize) {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();    
    
    UIGraphicsEndImageContext();
    return newImage;
}

void FADrawLineAtPath(UIView *view, CGPathRef path) {
	CAShapeLayer *shape = [CAShapeLayer layer];
	[shape setLineWidth:1.f];
	[shape setLineCap:kCALineCapRound];
	[shape setStrokeColor:[UIColorFromHexWithAlpha(0xFFFFFF, 0.37) CGColor]];
	[shape setPath:path];
	
	[[view layer] addSublayer:shape];
	[(FAFolderCell *)view setShapeLayer:shape];
}

@implementation FAFolderCell
+ (UIFont *)labelFont {
	return [UIFont fontWithName:@"Helvetica" size:18];
}

+ (UIFont *)smallLabelFont {
	return [UIFont fontWithName:@"Helvetica" size:14];
}

+ (UILabel *)_makeLabelWithRect:(CGRect)rect {
	UILabel *lbl = [[[UILabel alloc] initWithFrame:rect] autorelease];
	[lbl setFont:[FAFolderCell labelFont]];
	[lbl setBackgroundColor:[UIColor clearColor]];
	[lbl setTextColor:[UIColor whiteColor]];
	
	CALayer *layer = [lbl layer];
	[layer setShadowColor:[[UIColor blackColor] CGColor]];
	[layer setShadowOpacity:.5f];
	[layer setShadowOffset:CGSizeMake(0, 1)];
	[layer setShouldRasterize:YES];
	
	return lbl;
}

+ (CGFloat)_widthForProperty:(NSString *)property {
	if ([property isEqualToString:MPMediaItemPropertyPlaybackDuration] || [property isEqualToString:MPMediaItemPropertyPlayCount])
		// FIXME: Why the fuck?
		return isiPad() ? 105.f : 65.f;
	else
		return isiPad() ? 240.f : 120.f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		idx = 0;
		_property = [MPMediaItemPropertyPlaybackDuration retain];
		_placeholder = [UIImageResize([UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/iPodUI.framework/CoverFlowPlaceHolder44.png"], CGSizeMake(32, 32)) retain];
		//_state = MPMusicPlaybackStateStopped;
		
		_label = [FAFolderCell _makeLabelWithRect:CGRectMake(47, 8, 0, 20)];
		[[self contentView] addSubview:_label];
		
		CGFloat wd = [FAFolderCell _widthForProperty:_property];
		_infoLabel = [FAFolderCell _makeLabelWithRect:CGRectMake((isiPad() ? (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 768 : 1024) : 320)-wd+10, 8, 0, 20)];
		[[self contentView] addSubview:_infoLabel];
		
		__imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(10, 2.5, 32, 32)] autorelease];
    	[[__imageView layer] setBorderWidth:.5f];
    	[[__imageView layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    	[[self contentView] addSubview:__imageView];
		
		UIImage *ind_ = [UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/iPodUI.framework/NowPlayingListItemIcon.png"];
    	_speaker = [[[UIImageView alloc] initWithFrame:CGRectMake((_label.frame.size.width-50)+1, _label.frame.origin.y, 28, 24)] autorelease];
    	[_speaker setImage:ind_];
    	[_speaker setHidden:YES];
    	[self addSubview:_speaker];
		
		CGFloat wid = (isiPad() ? (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 768 : 1024) : 320)-wd;
		CGMutablePathRef path = CGPathCreateMutable();
		CGPathMoveToPoint(path, NULL, wid, [self bounds].origin.y);
		CGPathAddLineToPoint(path, NULL, wid, [self bounds].origin.y+38.f);
		FADrawLineAtPath(self, path);
		
		_path = CGPathCreateCopy(path);
		CGPathRelease(path);
	}
	
	return self;
}

- (UIImage *)placeholderImage {
    MPMediaItemArtwork *artwork = [_item valueForProperty:MPMediaItemPropertyArtwork];
    UIImage *artworkImage = [artwork imageWithSize:CGSizeMake(32, 32)];
    
    if (artworkImage)
    	return artworkImage;
    
    return _placeholder;
}

- (void)setShapeLayer:(CAShapeLayer *)shape {
	_shape = shape;
}

- (void)layoutSubviews {
	[super layoutSubviews];
    
    UIImage *artwork = [self placeholderImage];
	[__imageView setImage:artwork];
    
    [_label setText:[_item valueForProperty:MPMediaItemPropertyTitle]];
    [_infoLabel setText:[self valueForProperty]];
    
    CGFloat wd = [FAFolderCell _widthForProperty:_property];
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, (isiPad() ? (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 768 : 1024) : 320)-wd, [self bounds].origin.y);
	CGPathAddLineToPoint(path, NULL, (isiPad() ? (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 768 : 1024) : 320)-wd, [self bounds].origin.y+38.f);
    
    [_shape setPath:path];
    
    [_label setFrame:(CGRect){_label.frame.origin, {(isiPad() ? (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 768 : 1024) : 320)-(wd+50), _label.frame.size.height}}];
    [_label setFont:(wd==65.f||isiPad() ? [FAFolderCell labelFont] : [FAFolderCell smallLabelFont])];
    [_infoLabel setFrame:CGRectMake((isiPad() ? (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 768 : 1024) : 320)-wd+10, 8, wd-15, 20)];
}

- (void)_changeDetailAnimated {
	CGFloat wd = [FAFolderCell _widthForProperty:_property];
			
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, (isiPad() ? (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 768 : 1024) : 320)-wd, [self bounds].origin.y);
	CGPathAddLineToPoint(path, NULL, (isiPad() ? (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 768 : 1024) : 320)-wd, [self bounds].origin.y+38.f);
	
	[_shape setPath:path];
	
	_path = CGPathCreateCopy(path);
	CGPathRelease(path);
	
	[UIView animateWithDuration:.1f animations:^{
		[_label setFrame:(CGRect){_label.frame.origin, {(isiPad() ? (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 768 : 1024) : 320)-(wd+50), _label.frame.size.height}}];
		[_label setFont:(wd==65.f||isiPad() ? [FAFolderCell labelFont] : [FAFolderCell smallLabelFont])];
		
		[_infoLabel setAlpha:0.f];
		[_infoLabel setFrame:CGRectMake((isiPad() ? (UIInterfaceOrientationIsPortrait([[UIApplication sharedApplication] statusBarOrientation]) ? 768 : 1024) : 320)-wd+10, 8, wd-15, 20)];
		[_infoLabel setText:[self valueForProperty]];
		[_infoLabel setAlpha:1.f];
	}];
}

- (void)setShowsSpeaker:(BOOL)speaker {
	[_speaker setHidden:!speaker];
}

- (NSString *)valueForProperty {
	id value = [_item valueForProperty:_property];
	
	// Handle the duration special case
	if ([_property isEqualToString:MPMediaItemPropertyPlaybackDuration]) {
		int tsec = (int)round([value doubleValue]);
		int min = tsec/60;
		int sec = tsec-min*60;
		char* zero = sec<10 ? "0" : ""; // FIXME: This seems wrong.
		
		return [NSString stringWithFormat:@"%i:%s%i", min, zero, sec];
	}
	
	if ([value isKindOfClass:[NSNumber class]])
		return [value stringValue];
	else if ([value isKindOfClass:[NSString class]]) {
		if (value)
			return value;
	}
		
	return @"N/A";
}

- (void)setDetailProperty:(NSString *)property change:(BOOL)change {
	_property = [property retain];
	
	if (change) [self _changeDetailAnimated];
	else		[self setNeedsDisplay];
}

- (void)setMediaItem:(MPMediaItem *)item {
	_item = [item retain];
	[self setNeedsDisplay];
}

- (void)dealloc {
	CGPathRelease(_path);
	[_item release];
	[_property release];
	[_placeholder release];
	
	[super dealloc];
}
@end