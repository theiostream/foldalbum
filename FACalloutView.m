/**
	FACalloutView.m
	
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

// Based on UISettings-Core7's USCalloutView
// by qwertyoruiop+Maximus

#import "FACalloutView.h"

@implementation FACalloutView
- (void)placeQuitButtonInView:(UIView *)view {
	UIButton *busyView = [UIButton buttonWithType:UIButtonTypeCustom];
	[busyView setFrame:[view bounds]];
	[busyView setBackgroundColor:[UIColor clearColor]];
	[busyView addTarget:self action:@selector(removeFromSelf:) forControlEvents:UIControlEventTouchDown];
	[view addSubview:busyView];
}

- (void)removeFromSelf:(UIButton *)sender {
	[self retain];
	[self fadeOutWithDuration:.05f];
	
	[sender removeFromSuperview];
	
	if ([self FADelegate] && [[self FADelegate] respondsToSelector:@selector(calloutViewDidExit:)])
		[[self FADelegate] calloutViewDidExit:self];
	
	[self release];
}

- (void)setCenteredView:(UIView *)view animated:(BOOL)animated {
	UIView *sliderContainer = [[[UIView alloc] initWithFrame:CGRectMake(0, 0, view.frame.size.width, view.frame.size.height)] autorelease];
    
    CGRect fr = [view frame];
	fr.origin.x += 5;
	fr.origin.y = 0;
	[view setFrame:fr];
    
	[sliderContainer addSubview:view];
	[self setLeftView:sliderContainer animated:animated];
}

- (id<FACalloutViewDelegate>)FADelegate {
	return _delegate;
}

- (void)setFADelegate:(id<FACalloutViewDelegate>)delegate {
	_delegate = delegate;
}
@end