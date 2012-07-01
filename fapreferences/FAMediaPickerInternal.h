@interface FAInternalMediaPickerController : UITableViewController {
	FAMediaPickerController *_controller;
	int _type;
	NSMutableArray *_collections;
	UIImage *_placeholder;
}

- (FAInternalMediaPickerController *)initWithType:(int)type controller:(FAMediaPickerController *)ctrl;
- (NSString *)titleForCollection:(MPMediaItemCollection *)collection;
- (NSString *)subtitleForCollection:(MPMediaItemCollection *)collection;
- (UIImage *)placeholderImageForCollection:(MPMediaItemCollection *)collection;

- (void)didPressCancel;
@end