//
//  HCPlayingViewController.m
//  LittleFrog
//
//  Created by huangcong on 16/4/24.
//  Copyright © 2016年 HuangCong. All rights reserved.
//

#import "HCPlayingViewController.h"
#import "HCMusicModel.h"
#import "HCLrcView.h"
#import "HCPlayMusicTool.h"
#import "HCLrcTool.h"
#import "HCMusicIndicator.h"
#import <AVFoundation/AVFoundation.h>
#import <MediaPlayer/MediaPlayer.h>
typedef NS_ENUM(NSInteger){
    CicyleMode = 0,
    RandomMode,
    singleModel
}playMode;
@interface HCPlayingViewController()<UIScrollViewDelegate>
@property (nonatomic ,weak) UIImageView *backgroundImageView;
@property (nonatomic ,weak) UIImageView *musicImageView;
@property (nonatomic ,weak) UISlider *progressSlider;
@property (nonatomic ,strong) NSTimer *progressTimer;

@property (nonatomic ,weak) HCLrcView *lrcScrollView;

@property (nonatomic ,weak) UIView *buttonsView;
@property (nonatomic ,weak) UILabel *currentTimeLabel;
@property (nonatomic ,weak) UILabel *totalTimeLabel;

@property (nonatomic ,weak) UILabel *songNameLabel;
@property (nonatomic ,weak) UILabel *authorNameLabel;
@property (nonatomic ,weak) UIButton *likeButton;
@property (nonatomic ,weak) UIButton *previousButton;
@property (nonatomic ,weak) UIButton *nextButton;
@property (nonatomic ,weak) UIButton *playOrPauseButton;
@property (nonatomic ,weak) UIButton *backMenuButton;
@property (nonatomic ,weak) UIButton *shareButton;
@property (nonatomic ,weak) UIButton *randomButton;
@property (nonatomic ,weak) UIButton *singleCicyleButton;
@property (nonatomic ,weak) UIButton *moreChoiceButton;

@property (nonatomic ,strong) HCLrcView *lrcView;
@property (nonatomic, strong) CADisplayLink *lrcTimer;

@property (nonatomic ,strong) AVPlayerItem *playingItem;

@property (nonatomic ,copy) NSMutableArray *songIdArrayM;
@property (nonatomic ,assign) NSInteger playingIndex;

@property (nonatomic ,assign) playMode playMode;
@end
@implementation HCPlayingViewController
static HCMusicIndicator *_indicator;
static void *PlayingModelKVOKey = &PlayingModelKVOKey;
static void *IndicatorStateKVOKey = &IndicatorStateKVOKey;
+ (instancetype)sharePlayingVC
{
    static HCPlayingViewController *_playingVC = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        _playingVC = [[HCPlayingViewController alloc] init];
    });
    return _playingVC;
}
#pragma mark - getId
- (void)setSongIdArray:(NSMutableArray *)array currentIndex:(NSInteger)index
{
    self.songIdArrayM = array;
    self.playingIndex = index;
    [self loadSongDetail];
    [self setUpKVO];
    
    if (!self.view) {
        [self setUpView];
        [self setUpLrcView];
        [self setUpSlider];
        [self setUpLabelInButtonsView];
        [self setUpButtonInButtonsView];
        [self settingView];
        [self addProgressTimer];
        [self addLrcTimer];
    }
}
#pragma mark - viewLoadAndLayout
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpView];
    [self setUpLrcView];
    [self setUpSlider];
    [self setUpLabelInButtonsView];
    [self setUpButtonInButtonsView];
    [self settingView];
    [self addProgressTimer];
    [self addLrcTimer];
}
- (void)setUpView
{
    self.backgroundImageView = [HCCreatTool imageViewWithView:self.view];
    self.backgroundImageView.frame = self.view.frame;
    [HCBlurViewTool blurView:self.backgroundImageView style:UIBarStyleDefault];
    
    self.musicImageView = [HCCreatTool imageViewWithView:self.view];
    
    self.buttonsView = [HCCreatTool viewWithView:self.view];
}
- (void)setUpLrcView
{
    HCLrcView *scrollView = [[HCLrcView alloc] init];
    scrollView.bounces = NO;
    scrollView.showsVerticalScrollIndicator = NO;
    scrollView.showsHorizontalScrollIndicator = NO;
    scrollView.delegate = self;
    scrollView.scrollEnabled = YES;
    [self.view addSubview:scrollView];
    self.lrcScrollView = scrollView;
    self.lrcScrollView.contentSize = CGSizeMake(HCScreenWidth * 2 , 0);
}
- (void)setUpSlider
{
    UISlider *slider = [[UISlider alloc] init];
    [slider setMinimumTrackTintColor:HCMainColor];
    [slider setMaximumTrackTintColor:HCTextColor];
    [slider setThumbImage:[UIImage imageNamed:@"slider"] forState:UIControlStateNormal];
    [slider addTarget:self action:@selector(sliderValueChanged:) forControlEvents:UIControlEventValueChanged];
    [self.view addSubview:slider];
    self.progressSlider = slider;
}
- (void)setUpLabelInButtonsView
{
    self.currentTimeLabel = [HCCreatTool labelWithView:self.buttonsView size:CGSizeMake(40, 20)];
    self.currentTimeLabel.font = HCMiddleFont;
    
    self.totalTimeLabel = [HCCreatTool labelWithView:self.buttonsView size:CGSizeMake(40, 20)];
    self.totalTimeLabel.font = HCMiddleFont;
    
    self.songNameLabel =  [HCCreatTool labelWithView:self.buttonsView size:CGSizeMake(HCScreenWidth - HCHorizontalSpacing, 40)];
    self.songNameLabel.font = HCTitleFont;
    self.songNameLabel.textAlignment = NSTextAlignmentCenter;
    
    self.authorNameLabel = [HCCreatTool labelWithView:self.buttonsView size:CGSizeMake(HCScreenWidth - 2 * HCHorizontalSpacing, 20)];
    self.authorNameLabel.font = HCBigFont;
    self.authorNameLabel.textAlignment = NSTextAlignmentCenter;
}
- (void)setUpButtonInButtonsView
{
    self.likeButton = [HCCreatTool buttonWithView:self.buttonsView image:[UIImage imageNamed:@"icon_ios_heart"] state:UIControlStateNormal size:CGSizeMake(30, 30)];
    [self.likeButton addTarget:self action:@selector(clickLikeButton) forControlEvents:UIControlEventTouchUpInside];
    [self.likeButton setImage:[UIImage imageNamed:@"icon_ios_heart_filled"] forState:UIControlStateSelected];
    
    self.previousButton = [HCCreatTool buttonWithView:self.buttonsView image:[UIImage imageNamed:@"icon_ios_music_backward"] state:UIControlStateNormal size:CGSizeMake(35, 35)];
    [self.previousButton addTarget:self action:@selector(clickPreviousButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.playOrPauseButton = [HCCreatTool buttonWithView:self.buttonsView image:[UIImage imageNamed:@"icon_ios_music_play"] state:UIControlStateNormal size:CGSizeMake(35, 35)];
    [self.playOrPauseButton setImage:[UIImage imageNamed:@"icon_ios_music_pause"] forState:UIControlStateSelected];
    [self.playOrPauseButton addTarget:self action:@selector(clickPlayOrPauseButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.nextButton = [HCCreatTool buttonWithView:self.buttonsView image:[UIImage imageNamed:@"icon_ios_music_forward"] state:UIControlStateNormal size:CGSizeMake(35, 35)];
    [self.nextButton addTarget:self action:@selector(clickNextButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.backMenuButton = [HCCreatTool buttonWithView:self.buttonsView image:[UIImage imageNamed:@"icon_ios_down"] state:UIControlStateNormal size:CGSizeMake(30, 30)];
    [self.backMenuButton addTarget:self action:@selector(clickBackMenuButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.shareButton = [HCCreatTool buttonWithView:self.buttonsView image:[UIImage imageNamed:@"icon_ios_export"] state:UIControlStateNormal size:CGSizeMake(30, 30)];
    [self.shareButton addTarget:self action:@selector(clickShareButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.randomButton = [HCCreatTool buttonWithView:self.buttonsView image:[UIImage imageNamed:@"icon_ios_shuffle copy"] state:UIControlStateNormal size:CGSizeMake(30, 30)];
    [self.randomButton setImage:[UIImage imageNamed:@"icon_ios_shuffle _ selected"] forState:UIControlStateSelected];
    [self.randomButton addTarget:self action:@selector(clickRandomButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.singleCicyleButton = [HCCreatTool buttonWithView:self.buttonsView image:[UIImage imageNamed:@"icon_ios_replay"] state:UIControlStateNormal size:CGSizeMake(30, 30)];
    [self.singleCicyleButton setImage:[UIImage imageNamed:@"icon_ios_replay _ selected"] forState:UIControlStateSelected];
    [self.singleCicyleButton addTarget:self action:@selector(clickSingleCicyleButton) forControlEvents:UIControlEventTouchUpInside];
    
    self.moreChoiceButton = [HCCreatTool buttonWithView:self.buttonsView image:[UIImage imageNamed:@"icon_ios_more_filled"] state:UIControlStateNormal size:CGSizeMake(30, 30)];
    [self.moreChoiceButton addTarget:self action:@selector(clickMoreChoiceButton) forControlEvents:UIControlEventTouchUpInside];
}
- (void)viewDidLayoutSubviews
{
    [self layoutViews];
    [self layoutLabelAndButtons];
}
- (void)layoutViews
{
    [self.musicImageView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.top.equalTo(self.view.mas_top);
        make.width.equalTo(self.view.mas_width);
        make.height.equalTo(self.view.mas_width);
    }];
    
    [self.lrcScrollView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.top.equalTo(self.view.mas_top);
        make.width.equalTo(self.view.mas_width);
        make.height.equalTo(self.view.mas_width);
        
    }];
    
    [self.progressSlider mas_makeConstraints:^(MASConstraintMaker *make) {
        make.left.equalTo(self.view.mas_left);
        make.top.equalTo(self.musicImageView.mas_bottom);
        make.right.equalTo(self.view.mas_right);
        make.height.mas_equalTo(5);
    }];
    
    [self.buttonsView mas_makeConstraints:^(MASConstraintMaker *make) {
        make.top.equalTo(self.progressSlider.mas_bottom);
        make.left.equalTo(self.view.mas_left);
        make.right.equalTo(self.view.mas_right);
        make.bottom.equalTo(self.view.mas_bottom);
    }];
}
- (void)layoutLabelAndButtons
{
    [self.songNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.currentTimeLabel.mas_bottom).offset(HCCommonSpacing);
    }];
    
    [self.authorNameLabel mas_makeConstraints:^(MASConstraintMaker *make) {
        make.centerX.equalTo(self.view.mas_centerX);
        make.top.equalTo(self.songNameLabel.mas_bottom).offset(HCVerticalSpacing);
    }];

    [self.buttonsView distributeViewsHorizontallyWith:@[self.currentTimeLabel,self.totalTimeLabel] margin:HCCommonSpacing];
    [self.buttonsView distributeViewsVerticallyWith:@[self.currentTimeLabel,self.likeButton,self.shareButton] margin:HCCommonSpacing];
    [self.buttonsView distributeViewsHorizontallyWith:@[self.likeButton,self.previousButton,self.playOrPauseButton,self.nextButton,self.backMenuButton] margin:HCHorizontalSpacing];
    [self.buttonsView distributeViewsHorizontallyWith:@[self.shareButton,self.randomButton,self.singleCicyleButton,self.moreChoiceButton] margin:HCHorizontalSpacing];

}

#pragma mark - settingView
- (void)settingView
{
    [self.backgroundImageView sd_setImageWithURL:[NSURL URLWithString:self.currentMusic.songPicRadio] placeholderImage:[UIImage imageNamed:@"lyric-sharing-background-7"]];
    [self.musicImageView sd_setImageWithURL:[NSURL URLWithString:self.currentMusic.songPicRadio] placeholderImage:[UIImage imageNamed:@"lyric-sharing-background-5"]];
    self.songNameLabel.text = self.currentMusic.songName;
    self.authorNameLabel.text = [NSString stringWithFormat:@"%@   %@",self.currentMusic.artistName,self.currentMusic.albumName];
    [HCLrcTool lrcToolDownloadWithUrl:self.currentMusic.lrcLink setUpLrcView:self.lrcScrollView];
    self.playOrPauseButton.selected = YES;
}
#pragma mark - KVO
- (void)setUpKVO
{
    [self addObserver:self forKeyPath:@"currentMusic" options:NSKeyValueObservingOptionNew context:PlayingModelKVOKey];
    [_indicator addObserver:self forKeyPath:@"state" options:NSKeyValueObservingOptionNew context:IndicatorStateKVOKey];
}
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSString *,id> *)change context:(void *)context
{
    if (context == PlayingModelKVOKey) {
        HCLog(@"changeIs%@",[change objectForKey:@"new"]);
        HCMusicModel *new = [change objectForKey:@"new"];
        self.playingItem = [HCPlayMusicTool playMusicWithLink:new.showLink];
        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(playItemAction:) name:AVPlayerItemDidPlayToEndTimeNotification object:self.playingItem];
    }
    else if(context == IndicatorStateKVOKey){
        HCLog(@"state");
        [self refreshIndicatorViewState];
    }
}
#pragma mark - musicEnd
- (void)playItemAction:(AVPlayerItem *)item
{
    [self clickNextButton];
}
#pragma mark - timer - lrc
- (void)addProgressTimer
{
    self.progressTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(updateProgressTimer) userInfo:nil repeats:YES];
    [[NSRunLoop mainRunLoop] addTimer:self.progressTimer forMode:NSRunLoopCommonModes];
}
- (void)removeProgressTimer
{
    [self.progressTimer invalidate];
    self.progressTimer = nil;
}
- (void)addLrcTimer
{
    self.lrcTimer = [CADisplayLink displayLinkWithTarget:self selector:@selector(updateLrcTimer)];
    [self.lrcTimer addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSRunLoopCommonModes];
}
- (void)updateLrcTimer
{
    self.lrcScrollView.currentTime = CMTimeGetSeconds(self.playingItem.currentTime);
}
- (void)removeLrcTimer
{
    [self.lrcTimer invalidate];
    self.lrcTimer = nil;
}
#pragma mark - slider
- (void)updateProgressTimer
{
    self.currentTimeLabel.text = [self setUpTimeStringWithTime:CMTimeGetSeconds(self.playingItem.currentTime)];
    self.totalTimeLabel.text = [self setUpTimeStringWithTime:CMTimeGetSeconds(self.playingItem.duration)];
    HCLog(@"%f",CMTimeGetSeconds(self.playingItem.duration));
    self.progressSlider.value = CMTimeGetSeconds(self.playingItem.currentTime);
    //防止过快的切换歌曲导致duration == nan而崩溃
    if (isnan(CMTimeGetSeconds(self.playingItem.duration))) {
        self.progressSlider.maximumValue = CMTimeGetSeconds(self.playingItem.currentTime) + 1;
    }
    else{
        self.progressSlider.maximumValue = CMTimeGetSeconds(self.playingItem.duration);
    }
}

- (void)sliderValueChanged:(UISlider *)slider
{
    if (!_playingItem) {
        return;
    }
    self.currentTimeLabel.text = [self setUpTimeStringWithTime:slider.value];
    CMTime dragCMtime = CMTimeMake(slider.value, 1);
    [HCPlayMusicTool setUpCurrentPlayingTime:dragCMtime link:self.currentMusic.songLink];
}
//时间转字符串
- (NSString *)setUpTimeStringWithTime:(NSTimeInterval)time
{
    int minute = time / 60;
    int second = (int)time % 60;
    return [NSString stringWithFormat:@"%02d:%02d",minute,second];
}
#pragma mark - clickButtons
- (void)clickLikeButton
{
    HCLog(@"like");
    self.likeButton.selected = !self.likeButton.selected;
    [HCPromptTool promptModeText:(self.likeButton.selected ? @"已添加到喜欢" : @"取消喜欢") afterDelay:1];
}
- (void)clickPreviousButton
{
    HCLog(@"PreviousMusic");
    [self changeMusic:-1];
}

- (void)clickIndicator
{
    [self clickPlayOrPauseButton];
}
- (void)clickPlayOrPauseButton
{
    HCLog(@"PlayorPause");
    if (self.playOrPauseButton.selected) {
        [HCPlayMusicTool pauseMusicWithLink:self.currentMusic.songLink];
    }
    else{
        [HCPlayMusicTool playMusicWithLink:self.currentMusic.songLink];
    }
    self.playOrPauseButton.selected = !self.playOrPauseButton.selected;
    [self refreshIndicatorViewState];
}
- (void)clickNextButton
{
    HCLog(@"NextMusic");
    [self changeMusic:1];
}
- (void)clickBackMenuButton
{
    HCLog(@"BackMenu");
    [self dismissViewControllerAnimated:YES completion:^{
        [self refreshIndicatorViewState];
    }];
}
- (void)clickShareButton
{
    HCLog(@"share");
    [HCPromptTool promptModeText:@"抱歉，暂时没有分享渠道" afterDelay:1];
}
- (void)clickRandomButton
{
    HCLog(@"Random");
    self.randomButton.selected = !self.randomButton.selected;
    self.singleCicyleButton.selected = NO;
    [HCPromptTool promptModeText:(self.randomButton.selected ? @"随机播放" : @"取消随机")afterDelay:1];
    self.playMode = self.randomButton.selected ? RandomMode : CicyleMode;
}
- (void)clickSingleCicyleButton
{
    HCLog(@"Cicyle");
    self.singleCicyleButton.selected = !self.singleCicyleButton.selected;
    self.randomButton.selected = NO;
    [HCPromptTool promptModeText:(self.singleCicyleButton.selected ? @"单曲循环" : @"取消单曲循环")afterDelay:1];
    self.playMode = self.singleCicyleButton.selected ? singleModel : CicyleMode;
}
- (void)clickMoreChoiceButton
{
    HCLog(@"MoreChoice");
    [HCPromptTool promptModeText:@"功能完善中" afterDelay:1];
}
- (void)changeMusic:(NSInteger)variable
{
    [self removeProgressTimer];
    [self removeLrcTimer];
    [HCPlayMusicTool stopMusicWithLink:self.currentMusic.songLink];
    switch (self.playMode) {
        case CicyleMode:
            [self cicyleMusic:variable];
            break;
        case RandomMode:
            [self randomMusic];
            break;
        case singleModel:
            break;
    }
    [self loadSongDetail];
    [self addProgressTimer];
    [self addLrcTimer];
}
- (void)cicyleMusic:(NSInteger)variable
{
    if (self.playingIndex == self.songIdArrayM.count - 1) {
        self.playingIndex = 0;
    }
    else if(self.playingIndex == 0){
        self.playingIndex = self.songIdArrayM.count - 1;
    }
    else{
        self.playingIndex = variable + self.playingIndex;
    }
}
- (void)randomMusic
{
    self.playingIndex = arc4random() % self.songIdArrayM.count;
}
#pragma mark - delegate:refreshCellIndicator
- (void)refreshIndicatorViewState
{
    if ([self.delegate respondsToSelector:@selector(updateIndicatorViewOfVisisbleCells)]) {
        [self.delegate updateIndicatorViewOfVisisbleCells];
        }
}
#pragma mark UIScrollViewDelegate
- (void)scrollViewDidScroll:(UIScrollView *)scrollView
{
    //修改透明度
    CGFloat  scale = scrollView.contentOffset.x / scrollView.frame.size.width;
    self.musicImageView.alpha = 1.0- scale;
}
#pragma mark - loadSongDetail
- (void)loadSongDetail
{
    [HCNetWorkTool netWorkToolGetWithUrl:HCMusic parameters:@{@"songIds":self.songIdArrayM[self.playingIndex]} response:^(id response) {
        NSMutableArray *arrayM = response[@"data"][@"songList"];
        HCLog(@"success");
        self.currentMusic = [HCMusicModel mj_objectWithKeyValues:arrayM.firstObject];
        [self settingView];
    }];
}

#pragma mark - 设置锁屏信息／后台
- (void)setUpLockInfo
{
    //1.获取当前播放中心
    MPNowPlayingInfoCenter  *center = [MPNowPlayingInfoCenter defaultCenter];
    
    NSMutableDictionary *infos = [NSMutableDictionary dictionary];
    
    infos[MPMediaItemPropertyTitle] = self.currentMusic.songName;
    infos[MPMediaItemPropertyArtist] = self.currentMusic.artistName;
    
    infos[MPMediaItemPropertyArtwork] =  [[MPMediaItemArtwork alloc]initWithImage:[UIImage imageNamed: self.currentMusic.songPicBig]];
    
    infos[MPMediaItemPropertyPlaybackDuration] = @(CMTimeGetSeconds(self.playingItem.duration));
    infos[MPNowPlayingInfoPropertyElapsedPlaybackTime] = @(CMTimeGetSeconds(self.playingItem.duration));
    [center  setNowPlayingInfo:infos];
    
    //设置远程操控
    [[UIApplication sharedApplication]beginReceivingRemoteControlEvents];
    [self becomeFirstResponder];
    
}

//成为第一响应者
- (BOOL)canBecomeFirstResponder
{
    return YES;
    
}
- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
            [self clickPlayOrPauseButton];
            break;
        case UIEventSubtypeRemoteControlPause:
            [self clickPlayOrPauseButton];
            break;
        case UIEventSubtypeRemoteControlStop:
            [HCPlayMusicTool stopMusicWithLink:self.currentMusic.songLink];
            break;
        case UIEventSubtypeRemoteControlNextTrack:
            [self clickNextButton];
            break;
            break;
        case UIEventSubtypeRemoteControlPreviousTrack:
            [self clickPreviousButton];
            break;
        default:
            break;
    }
}
@end
