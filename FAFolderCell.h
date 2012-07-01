#import <MediaPlayer/MPMusicPlayerController.h>
#import <QuartzCore/QuartzCore.h>

// A Macro created on IRC by Maximus!
// I don't get shifts nor other bitwise operations.
#define UIColorFromHexWithAlpha(rgbValue,a) \
	[UIColor colorWithRed:((float)((rgbValue & 0xFF0000) >> 16))/255.0 \
		green:((float)((rgbValue & 0xFF00) >> 8))/255.0 \
		blue:((float)(rgbValue & 0xFF))/255.0 \
		alpha:a]

@interface FAFolderCell : UITableViewCell {
	MPMediaItem *_item;
	UIImage *_placeholder;
	
	UILabel *_label;
	UILabel *_infoLabel;
	UIImageView *__imageView;
	UIImageView *_speaker;
	
	NSUInteger idx;
	NSString *_property;
	
	CGPathRef _path;
	CAShapeLayer *_shape;
}

- (void)setMediaItem:(MPMediaItem *)item;
- (void)setDetailProperty:(NSString *)property change:(BOOL)change;
- (NSString *)valueForProperty;
- (void)setShapeLayer:(CAShapeLayer *)shape;
- (void)setShowsSpeaker:(BOOL)speaker;
@end