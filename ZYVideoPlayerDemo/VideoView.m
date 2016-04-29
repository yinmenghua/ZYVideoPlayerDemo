//
//  VideoView.m
//  ZYVideoPlayerDemo
//
//  Created by Box on 14/11/12.
//  Copyright (c) 2014年 Box. All rights reserved.
//

#import "VideoView.h"

@implementation VideoView

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

// 每一个UIView都有一个CALayer
// UI UIView是表面现象(很好用)  CALayer是本质(不好用)
// 非常底层  自己做一个动画  做opengl游戏 做视频图像的展示
// CALayer Core Animation 计算机图形学  3d算法
// OpenGL  计算机图形学  如何做opengl类似的硬件(显卡)软件opengl实现
// CALayer,
+ (id) layerClass {
    // AVPlayerLayer 用来画opengl和视频的layer
    // CALayer做ui上东西
    //    AVPreviewLayer
    //    AVPlayer AVPlayerLayer
    //    CAEAGLLayer OpenGL
    //    CALayer UIView
    return [AVPlayerLayer class];
}

- (void)setPlayer:(AVPlayer *)player {
    AVPlayerLayer *playerLayer =
    (AVPlayerLayer *)[self layer];
    // 告诉playerLayer告诉播放器player把图像刷新到playerLayer上
    // 只要刷新到layer上就可以显示了
    // player自动能否硬解码 h264
    [playerLayer setPlayer:player];
}

@end
