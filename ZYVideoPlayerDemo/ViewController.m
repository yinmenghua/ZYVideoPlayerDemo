//
//  ViewController.m
//  ZYVideoPlayerDemo
//
//  Created by Box on 14/11/12.
//  Copyright (c) 2014年 Box. All rights reserved.
//

#import "ViewController.h"
#import "VideoView.h"

@interface ViewController (){
    UIImageView *_imageView;
    
    AVPlayerItem *_playerItem;
    AVPlayer *_player;
    
    VideoView *_videoView;
    
    UISlider *_playerSlider;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view, typically from a nib.
    
    CGRect rect = CGRectMake(10, 114, self.view.frame.size.width-20, 200);
    _imageView = [[UIImageView alloc] initWithFrame:rect];
    [self.view addSubview:_imageView];

    //[self generateImage];
    
    UIButton *playButton = [UIButton buttonWithType:UIButtonTypeRoundedRect];
    playButton.frame = CGRectMake(10, 64, 100, 44);
    playButton.backgroundColor = [UIColor lightGrayColor];
    [playButton setTitle:@"开始" forState:UIControlStateNormal];
    [playButton addTarget:self action:@selector(playMovie:) forControlEvents:UIControlEventTouchUpInside];
    [self.view addSubview:playButton];
    
    _videoView = [[VideoView alloc] initWithFrame:rect];
    [self.view addSubview:_videoView];
    
    
    _playerSlider = [[UISlider alloc] initWithFrame:CGRectMake(10, 420, 300, 5)];
    [_playerSlider addTarget:self action:@selector(playerProgressChange:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:_playerSlider];

}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

#pragma mark - PLAY Move

- (void)playMovie:(id)sender {
    
    int videoStyle = 1;
    
    if (videoStyle == 1) {
        // 本地视频
        NSString *path = [[NSBundle mainBundle] pathForResource:@"1407101" ofType:@"mp4"];
        NSURL *url = [NSURL fileURLWithPath:path];
        [self playMovieLocal:url];
    } else if (videoStyle == 2) {
        // 网络点播视频
        NSURL *url = [NSURL URLWithString:@"http://www.jxvdy.com/file/upload/201309/18/18-10-03-19-3.mp4"];
        [self playMovieRemote:url];
        
    } else if (videoStyle == 3) {
        //http://apptrailers.itunes.apple.com/apple-assets-us-std-000001/PurpleVideo7/v4/ff/9b/d4/ff9bd4a2-2762-baac-1237-df7a81f2dbdb/P37356270_default.m3u8
        // 网络流媒体直播视频
//        NSURL *url = [NSURL URLWithString:@"http://live.3gv.ifeng.com/live/hongkong.m3u8"];
        NSURL *url = [NSURL URLWithString:@"http://apptrailers.itunes.apple.com/apple-assets-us-std-000001/PurpleVideo7/v4/ff/9b/d4/ff9bd4a2-2762-baac-1237-df7a81f2dbdb/P37356270_default.m3u8"];
        
        [self playMovieMediaStream:url];
    }

}



#pragma mark - 播放本地视频(本地播放)

- (void)playMovieLocal:(NSURL *)url {

//    static NSString *ItemStatusContext = (NSString *)&ItemStatusContext;
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSString *tracksKey = @"tracks";
    NSArray *keyArray = [NSArray arrayWithObjects:tracksKey, nil];
    [asset loadValuesAsynchronouslyForKeys:keyArray completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
            if (status == AVKeyValueStatusLoaded) {
                _playerItem = [AVPlayerItem playerItemWithAsset:asset];
                [_playerItem addObserver:self forKeyPath:@"status" options:0 context:nil];
                //                [playerItem addObserver:self forKeyPath:@"asset.naturalSize" options:0 context:&ItemStatusContext];
                
                [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:0 context:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
                _player = [AVPlayer playerWithPlayerItem:_playerItem];
                
                // 把player的图像通过硬件放在view上
                [_videoView setPlayer:_player];
            } else {
                NSLog(@"Error status is %ld", status);
            }
            
        });
    }];

}

#pragma mark - 播放网页视频(点播)

- (void)playMovieRemote:(NSURL *)url {
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    NSString *tracksKey = @"tracks";
    NSArray *keyArray = [NSArray arrayWithObjects:tracksKey, nil];
    NSLog(@"load url is %@", url);
    [asset loadValuesAsynchronouslyForKeys:keyArray completionHandler:^{
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
            NSLog(@"status is %ld", status);
            if (status == AVKeyValueStatusLoaded) {
                _playerItem = [AVPlayerItem playerItemWithAsset:asset];
                [_playerItem addObserver:self forKeyPath:@"status" options:0 context:nil];
                [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playItemDidReachEnd:) name:AVPlayerItemDidPlayToEndTimeNotification object:_playerItem];
                _player = [AVPlayer playerWithPlayerItem:_playerItem];
                [_videoView setPlayer:_player];
            } else {
                NSLog(@"Error status is %@", error.localizedDescription);
            }
            
        });
    }];
    
    
}

#pragma mark - 播放本地视频(直播间)

- (void)playMovieMediaStream:(NSURL *)url {
    
    AVURLAsset *asset = [AVURLAsset URLAssetWithURL:url options:nil];
    
    // 支持播放 播放声音，图像（不负责显示）
    // AVURLAsset 不用NSURL原因是播放audio/video ipod, movie
    // ipod, movie如果用url
    // AVURLAsset可以ipod播放系统自带的 本地，点播 直播
    // AVPlayer *p = [AVPlayer alloc] initWithURL:<#(NSURL *)#>
    
    NSString *tracksKey = @"tracks";
    // 缓存关键字keypath, 可以缓存到视频的tracks, 可以取得系统的
    // 信息 有1路视频 有2路音频
    // loadValuesAsynchronouslyForKeys
    NSArray *keyArray = [NSArray arrayWithObjects:tracksKey, nil];
    // loadValuesAsynchronouslyForKeys:completionHandler:函数本身只是设置
    // 告诉系统后台启动下载如果完成来调用blocks里面的方法
    
    [asset loadValuesAsynchronouslyForKeys:keyArray completionHandler:^{
        // 完成有2种情况 成功 失败
        dispatch_async(dispatch_get_main_queue(), ^{
            NSError *error = nil;
            AVKeyValueStatus status = [asset statusOfValueForKey:tracksKey error:&error];
            NSLog(@"status is %ld", status);
            if (status == AVKeyValueStatusLoaded) {
                _playerItem = [AVPlayerItem playerItemWithAsset:asset];
                [_playerItem addObserver:self forKeyPath:@"status" options:0 context:nil];
                [_playerItem addObserver:self forKeyPath:@"playbackBufferEmpty" options:0 context:nil];
                
                [[NSNotificationCenter defaultCenter]
                 addObserver:self
                 selector:@selector(playItemDidReachEnd:)
                 name:AVPlayerItemDidPlayToEndTimeNotification
                 object:_playerItem];
                // 观察playerItem播放视频结束
                
                _player = [AVPlayer playerWithPlayerItem:_playerItem];
                [_videoView setPlayer:_player];
            } else {
                NSLog(@"Error status is %ld", status);
            }
            
        });
    }];

    
    
}

#pragma mark - SLIDER Progress

- (void) playerProgressChange:(UISlider *)sender {
    float v = sender.value;
    CMTime time = [[_player currentItem] duration];
    NSLog(@"cmtime duration is %f", time.value/time.timescale/60.0f);
    CMTime newTime = CMTimeMultiplyByFloat64(time, v);
    [_player pause];
    [_player seekToTime:newTime completionHandler:^(BOOL finished) {
        NSLog(@"finish is %d", finished);
        [_player play];
    }];
    
}

#pragma mark -KVO

- (void) observeValueForKeyPath:(NSString *)keyPath
                       ofObject:(id)object
                         change:(NSDictionary *)change
                        context:(void *)context {
    NSLog(@"statut is keypath is %@", keyPath);
    if ([keyPath isEqualToString:@"status"]) {
        [_player play];
        // 开发播放
        CMTime time = [[_player currentItem] duration];
        // CMTime  Core Media
        // 取得系统的总时间
        // [player currentItem] 当前的播放一项 playerItem
        float seconds = time.value*1.0f/time.timescale;
        NSLog(@"time is %lld, %d time: %f",
              time.value, time.timescale, seconds/60);
        //        [self performSelector:@selector(seekPlayer:) withObject:player afterDelay:1];
        
        
        NSLog(@"timedMetadata is %@", _player.currentItem.asset.commonMetadata);
        NSLog(@"tracks is %@", _player.currentItem.tracks);
        
        
        CMTime periodicTimeIntervale = CMTimeMake(1, 1);
        // 1/1 = 1s
        
        __weak AVPlayer *tempVideo = _player;
        __weak UISlider *slider = _playerSlider;
        [_player addPeriodicTimeObserverForInterval:periodicTimeIntervale queue:dispatch_get_main_queue() usingBlock:^(CMTime time) {
            CMTime duration = [[tempVideo currentItem] duration];
            CMTime currTime = [[tempVideo currentItem] currentTime];
            float v = CMTimeGetSeconds(currTime)/CMTimeGetSeconds(duration);
            NSLog(@"v is %f", v);
            NSLog(@"loadedTimeRanges is %@", [[tempVideo currentItem] loadedTimeRanges]);
            NSLog(@"seekTimeRanges is %@", [[tempVideo currentItem] seekableTimeRanges]);
            
            // loadedTimeRanges AVURLAsset现在缓存的长度 CMTimeRange
            // seekableTimeRanges 可以拖动的范围 只是对点播和本地文件有效
            // seekableTimeRanges其实就是文件总时间
            
            [slider setValue:v];
        }];
    } else if ([keyPath isEqualToString:@"playbackBufferEmpty"]) {
        // 对于流媒体认为播放结束
    }
}


#pragma mark - playItemDidReachEnd

- (void) playItemDidReachEnd:(NSNotification *)notification {
    NSLog(@"reach end");
    [_player seekToTime:kCMTimeZero];
    //    [player seekToTime:time toleranceBefore:kCMTimeZero toleranceAfter:kCMTimeZero];
    [_player seekToTime:kCMTimeZero completionHandler:^(BOOL finished) {
        NSLog(@"定位完成");
    }];
    // 异步定位 不用代码 原因 面向对象
    // request startAsync];
    // requestFinish
    
    // 精确定位时间
    // 定位不太精准
}



@end
