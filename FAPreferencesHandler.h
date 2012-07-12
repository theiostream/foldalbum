#define FALayoutPath "/var/mobile/Library/Preferences/am.theiostre.foldalbum.plist"

@interface FAPreferencesHandler : NSObject {
	NSMutableArray *_cache;
}

+ (id)sharedInstance;
- (BOOL)keyExists:(NSString *)key;
- (NSArray *)allKeys;
- (id)objectForKey:(NSString *)key;
- (void)updateKey:(NSString *)key withDictionary:(NSDictionary *)dict;
- (void)optimizedUpdateKey:(NSString *)key withDictionary:(NSDictionary *)dict;
- (void)deleteKey:(NSString *)key;
- (void)_writeCacheToFile;
@end