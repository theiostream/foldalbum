#import "FAPreferencesHandler.h"

static NSDictionary *FALayoutDict() {
	return [NSDictionary dictionaryWithContentsOfFile:@FALayoutPath];
}

static FAPreferencesHandler *sharedInstance_ = nil;
@implementation FAPreferencesHandler
+ (id)sharedInstance {
	if (!sharedInstance_)
		sharedInstance_ = [[FAPreferencesHandler alloc] init];
	
	return sharedInstance_;
}

- (id)init {
	if ((self = [super init])) {
		_cache = [[NSMutableDictionary dictionaryWithDictionary:[FALayoutDict() objectForKey:@"FAFolderCache"]] retain];
	}
	
	return self;
}

- (void)dealloc {
	[_cache release];
	[super dealloc];
}

- (BOOL)keyExists:(NSString *)key {
	return ([_cache objectForKey:key] != nil);
}

- (NSArray *)allKeys {
	return [_cache allKeys];
}

- (id)objectForKey:(NSString *)key {
	if (![self keyExists:key])
		return nil;
	
	return [_cache objectForKey:key];
}

- (void)updateKey:(NSString *)key withDictionary:(NSDictionary *)dict {
	[_cache setObject:dict forKey:key];
	[self _writeCacheToFile];
}

- (void)optimizedUpdateKey:(NSString *)key withDictionary:(NSDictionary *)dict {
	NSDictionary *_tgt = [self objectForKey:key];
	if (!_tgt)
		return;
	
	NSMutableDictionary *tgt = [NSMutableDictionary dictionaryWithDictionary:_tgt];
	
	NSArray *keys = [dict allKeys];
	for (NSString *k in keys)
		[tgt setObject:[dict objectForKey:k] forKey:k];
		
	[self updateKey:key withDictionary:tgt];
}

- (void)deleteKey:(NSString *)key {
	[_cache removeObjectForKey:key];
	[self _writeCacheToFile];
}

- (void)_writeCacheToFile {
	NSMutableDictionary *_dict = [NSMutableDictionary dictionaryWithDictionary:FALayoutDict()];
	
	[_dict setObject:_cache forKey:@"FAFolderCache"];
	[_dict writeToFile:@FALayoutPath atomically:YES];
}
@end