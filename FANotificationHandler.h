@interface FANotificationHandler : NSObject
+ (id)sharedInstance;
- (void)addNewAlbumIconWithMessageName:(NSString *)message userInfo:(NSDictionary *)dict;
- (void)updateKeyWithMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo;
- (void)optimizedUpdateKeyWithMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo;
- (void)removeKeyWithMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo;
- (NSDictionary *)keyExistsWithMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo;
- (NSDictionary *)objectForKeyWithMessageName:(NSString *)message userInfo:(NSDictionary *)userInfo;
@end