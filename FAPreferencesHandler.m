/**
	FAPreferencesHandler.m
	
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

// TODO: Improve the structure of the plist.
// It's very inneficient to keep iterating through arrays.

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
		/*if ([[NSFileManager defaultManager] fileExistsAtPath:@"/Library/Application Support/FoldAlbum/_oldplist.plist"]) {
			id cache = [[NSDictionary dictionaryWithContentsOfFile:@"/Library/Application Support/FoldAlbum/_oldplist.plist"] objectForKey:@"FAFolderCache"];
			if (cache && [cache isKindOfClass:[NSArray class]]) {
				_cache = [cache retain];
				return self;
			}
		}*/
		
		id cache = [FALayoutDict() objectForKey:@"FAFolderCache"];
		if (![cache isKindOfClass:[NSArray class]]) {
			NSLog(@"[FoldMusic] Failure. Deleting your plist.");
			[[NSFileManager defaultManager] removeItemAtPath:@FALayoutPath error:NULL];
			_cache = [[NSMutableArray array] retain];
		}
		else _cache = [[NSMutableArray arrayWithArray:cache] retain];
	}

	return self;
}

- (void)dealloc {
	[_cache release];
	[super dealloc];
}

- (BOOL)keyExists:(NSString *)key {
	NSUInteger count = [_cache count];
	for (NSUInteger i=0; i<count; i++) {
		if ([[[_cache objectAtIndex:i] objectForKey:@"keyTitle"] isEqualToString:key])
			return YES;
	}

	return NO;
}

- (NSArray *)allKeys {
	return _cache;
}

- (id)objectForKey:(NSString *)key {
	if (![self keyExists:key])
		return nil;
	
	NSUInteger count = [_cache count];
	for (NSUInteger i=0; i<count; i++) {
		if ([[[_cache objectAtIndex:i] objectForKey:@"keyTitle"] isEqualToString:key])
			return [_cache objectAtIndex:i];
	}

	return nil;
}

- (void)updateKey:(NSString *)key withDictionary:(NSDictionary *)dict {
	NSUInteger i;
	for (i=0; i<[_cache count]; i++) {
		if ([[[_cache objectAtIndex:i] objectForKey:@"keyTitle"] isEqualToString:key]) {
			[_cache replaceObjectAtIndex:i withObject:dict];
			goto write;
		}
	}

	NSMutableDictionary *d = [NSMutableDictionary dictionaryWithDictionary:dict];
	[d setObject:key forKey:@"keyTitle"];
	[_cache addObject:d];

	write:
	[self _writeCacheToFile];
}

- (void)optimizedUpdateKey:(NSString *)key withDictionary:(NSDictionary *)dict {
	NSArray *keys = [dict allKeys];
	NSUInteger count = [keys count];

	NSDictionary *_tgt = [self objectForKey:key];
	if (!_tgt) return;

	NSMutableDictionary *tgt = [NSMutableDictionary dictionaryWithDictionary:_tgt];
	for (NSUInteger i=0; i<count; i++)
		[tgt setObject:[dict objectForKey:[keys objectAtIndex:i]] forKey:[keys objectAtIndex:i]];

	[self updateKey:key withDictionary:tgt];
}

- (void)deleteKey:(NSString *)key {
	NSDictionary *obj;
	NSUInteger count = [_cache count];
	for (NSUInteger i=0; i<count; i++) {
		if ([[[_cache objectAtIndex:i] objectForKey:@"keyTitle"] isEqualToString:key]) {
			obj = [_cache objectAtIndex:i];
			break;
		}
	}
	
	[_cache removeObject:obj];
	[self _writeCacheToFile];
}

- (void)_writeCacheToFile {
	NSMutableDictionary *_dict = [NSMutableDictionary dictionaryWithDictionary:FALayoutDict()];

	[_dict setObject:_cache forKey:@"FAFolderCache"];
	[_dict writeToFile:@FALayoutPath atomically:YES];
}
@end