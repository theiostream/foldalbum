// TODO: Use scoped pools where needed.

#import <MediaPlayer/MediaPlayer.h>
#import <AppSupport/CPDistributedMessagingCenter.h>

@interface FADaemonNotificationHandler : NSObject {
	MPMusicPlayerController *iPod;
}

- (NSDictionary *)nowPlayingItem;
- (NSDictionary *)playbackState;
- (void)play;
- (void)pause;
- (void)setQuery:(NSString *)name userInfo:(NSDictionary *)dict;
@end

static FADaemonNotificationHandler *sharedInstance_ = nil;
@implementation FADaemonNotificationHandler
+ (id)sharedInstance {
	if (!sharedInstance_)
		sharedInstance_ = [[FADaemonNotificationHandler alloc] init];
	
	return sharedInstance_;
}

- (id)init {
	if ((self = [super init])) {
		iPod = [MPMusicPlayerController iPodMusicPlayer];
	}
	
	return self;
}

- (void)setQuery:(NSString *)name userInfo:(NSDictionary *)dict {
	MPMediaItemCollection *col = [NSKeyedUnarchiver unarchiveObjectWithData:[dict objectForKey:@"Collection"]];
	[iPod setQueueWithItemCollection:col];
}

- (NSDictionary *)nowPlayingItem {
	MPMediaItem *nowPlayingItem = [iPod nowPlayingItem];
	if (nowPlayingItem)
		return [NSDictionary dictionaryWithObject:[NSKeyedArchiver archivedDataWithRootObject:nowPlayingItem] forKey:@"Item"];
	
	return nil;
}

- (NSDictionary *)playbackState {
	MPMusicPlaybackState state = [iPod playbackState];
	return [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:state] forKey:@"State"];
}

- (void)play {
	[iPod play];
}

- (void)pause {
	[iPod pause];
}

- (void)stop {
	[iPod stop];
}

- (void)seekBackward {
	[iPod beginSeekingBackward];
}

- (void)seekForward {
	[iPod beginSeekingForward];
}

- (void)endSeek {
	[iPod endSeeking];
}

- (void)previousItem {
	[iPod skipToPreviousItem];
}

- (void)nextItem {
	[iPod skipToNextItem];
}

- (void)seekBeginning {
	[iPod skipToBeginning];
}

- (NSNumber *)playbackTime {
	NSInteger interval = (NSInteger)[iPod currentPlaybackTime];
	return [NSDictionary dictionaryWithObject:[NSNumber numberWithInteger:interval] forKey:@"Interval"];
}
@end

int main() {
	NSLog(@"Welcome to foldalbumd!");
	@autoreleasepool {	
		FADaemonNotificationHandler *hdl = [FADaemonNotificationHandler sharedInstance];
	
		CPDistributedMessagingCenter *center = [CPDistributedMessagingCenter centerNamed:@"am.theiostre.foldalbum.player"];
		[center registerForMessageName:@"SetQuery" target:hdl selector:@selector(setQuery:userInfo:)];
		[center registerForMessageName:@"NowPlayingItem" target:hdl selector:@selector(nowPlayingItem)];
		[center registerForMessageName:@"PlaybackState" target:hdl selector:@selector(playbackState)];
		[center registerForMessageName:@"Play" target:hdl selector:@selector(play)];
		[center registerForMessageName:@"Pause" target:hdl selector:@selector(pause)];
		[center registerForMessageName:@"Stop" target:hdl selector:@selector(stop)];
		[center registerForMessageName:@"SeekBackward" target:hdl selector:@selector(seekBackward)];
		[center registerForMessageName:@"SeekForward" target:hdl selector:@selector(seekForward)];
		[center registerForMessageName:@"EndSeeking" target:hdl selector:@selector(endSeek)];
		[center registerForMessageName:@"PreviousItem" target:hdl selector:@selector(previousItem)];
		[center registerForMessageName:@"NextItem" target:hdl selector:@selector(nextItem)];
		[center registerForMessageName:@"SeekBeginning" target:hdl selector:@selector(seekBeginning)];
		[center registerForMessageName:@"PlaybackTime" target:hdl selector:@selector(playbackTime)];
		[center runServerOnCurrentThread];
	
		CFRunLoopRun();
	}
	return 0;
}