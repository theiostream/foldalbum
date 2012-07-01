#import <UIKit2/UICalloutView.h>

@protocol FACalloutViewDelegate;

@interface FACalloutView : UICalloutView {
	id<FACalloutViewDelegate> _faDelegate;
}

- (void)setCenteredView:(UIView *)view animated:(BOOL)animated;
- (void)placeQuitButtonInView:(UIView *)view;
- (id<FACalloutViewDelegate>)FADelegate;
- (void)setFADelegate:(id<FACalloutViewDelegate>)delegate;
@end

@protocol FACalloutViewDelegate <UICalloutViewDelegate>
@optional
- (void)calloutViewDidExit:(FACalloutView *)callout;
@end