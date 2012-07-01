#import <MediaPlayer/MediaPlayer.h>

@class FAMediaPickerController;
@protocol FAMediaPickerControllerDelegate <NSObject>
@required
- (void)didPressCancelButtonAtPicker:(FAMediaPickerController *)picker;
- (void)didSelectCollection:(MPMediaItemCollection *)collection atPicker:(FAMediaPickerController *)picker;
@end

@interface FAMediaPickerController : UITabBarController {
	id<FAMediaPickerControllerDelegate> _pickerDelegate;
}

- (id<FAMediaPickerControllerDelegate>)pickerDelegate;
- (void)setPickerDelegate:(id<FAMediaPickerControllerDelegate>)delegate;
@end