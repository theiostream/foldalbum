/**
	FAFolderCell.h
	
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