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