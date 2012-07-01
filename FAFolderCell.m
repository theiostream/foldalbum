// UI by Maximus. (@0_Maximus_0). He's also an awesome developer.
// Plus, White Stripes.
// Plz no lag

#import "FAFolderCell.h"

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
		return 60.f;
	else
		return 120.f;
}

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
	if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier])) {
		idx = 0;
		_property = [MPMediaItemPropertyPlaybackDuration retain];
		_placeholder = [UIImageResize([UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/iPodUI.framework/CoverFlowPlaceHolder44@2x.png"], CGSizeMake(32, 32)) retain];
		//_state = MPMusicPlaybackStateStopped;
		
		_label = [FAFolderCell _makeLabelWithRect:CGRectMake(47, 8, 0, 20)];
		[[self contentView] addSubview:_label];
		
		CGFloat wd = [FAFolderCell _widthForProperty:_property];
		_infoLabel = [FAFolderCell _makeLabelWithRect:CGRectMake(320-wd+10, 8, 0, 20)];
		[[self contentView] addSubview:_infoLabel];
		
		__imageView = [[[UIImageView alloc] initWithFrame:CGRectMake(10, 2.5, 32, 32)] autorelease];
    	[[__imageView layer] setBorderWidth:.5f];
    	[[__imageView layer] setBorderColor:[[UIColor whiteColor] CGColor]];
    	[[self contentView] addSubview:__imageView];
		
		UIImage *ind_ = [UIImage imageWithContentsOfFile:@"/System/Library/PrivateFrameworks/iPodUI.framework/NowPlayingListItemIcon@2x.png"];
    	_speaker = [[[UIImageView alloc] initWithFrame:CGRectMake((_label.frame.size.width-50)+1, _label.frame.origin.y, 28, 24)] autorelease];
    	[_speaker setImage:ind_];
    	[_speaker setHidden:YES];
    	[self addSubview:_speaker];
		
		CGFloat wid = 260;
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
	CGPathMoveToPoint(path, NULL, 320-wd, [self bounds].origin.y);
	CGPathAddLineToPoint(path, NULL, 320-wd, [self bounds].origin.y+38.f);
    
    [_shape setPath:path];
    
    [_label setFrame:(CGRect){_label.frame.origin, {320-(wd+50), _label.frame.size.height}}];
    [_label setFont:(wd==60.f ? [FAFolderCell labelFont] : [FAFolderCell smallLabelFont])];
    [_infoLabel setFrame:CGRectMake(320-wd+10, 8, wd-15, 20)];
}

- (void)_changeDetailAnimated {
	CGFloat wd = [FAFolderCell _widthForProperty:_property];
			
	CGMutablePathRef path = CGPathCreateMutable();
	CGPathMoveToPoint(path, NULL, 320-wd, [self bounds].origin.y);
	CGPathAddLineToPoint(path, NULL, 320-wd, [self bounds].origin.y+38.f);
	
	[_shape setPath:path];
	
	_path = CGPathCreateCopy(path);
	CGPathRelease(path);
	
	[UIView animateWithDuration:.1f animations:^{
		[_label setFrame:(CGRect){_label.frame.origin, {320-(wd+50), _label.frame.size.height}}];
		[_label setFont:(wd==60.f ? [FAFolderCell labelFont] : [FAFolderCell smallLabelFont])];
		
		[_infoLabel setAlpha:0.f];
		[_infoLabel setFrame:CGRectMake(320-wd+10, 8, wd-15, 20)];
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