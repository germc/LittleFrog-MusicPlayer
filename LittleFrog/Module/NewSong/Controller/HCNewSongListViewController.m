//
//  HCNewSongListViewController.m
//  LittleFrog
//
//  Created by huangcong on 16/4/27.
//  Copyright © 2016年 HuangCong. All rights reserved.
//

#import "HCNewSongListViewController.h"
#import "HCPublicTableView.h"
#import "HCPublicHeadView.h"
#import "HCPublicSonglistModel.h"
#import "HCPublicSongDetailModel.h"

@interface HCNewSongListViewController ()
@property (nonatomic ,weak) UIImageView *backGroundImageView;
@property (nonatomic ,weak) UIScrollView *scrollView;
@property (nonatomic ,strong) HCPublicTableView *tableView;
@property (nonatomic ,strong) HCPublicHeadView *headView;

@property (nonatomic ,strong) NSMutableArray *songListArrayM;
@property (nonatomic ,strong) NSMutableArray *songIdsArrayM;
@end
@implementation HCNewSongListViewController
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self setUpBackGroundView];
    [self setUpScrollView];
    self.songListArrayM = [NSMutableArray array];
    self.songIdsArrayM = [NSMutableArray array];
    [self loadSongList];
}

- (void)setUpBackGroundView
{
    self.backGroundImageView = [HCCreatTool imageViewWithView:self.view];
    self.backGroundImageView.frame = CGRectMake(-HCScreenWidth,-HCScreenHeight, 3 * HCScreenWidth, 3 * HCScreenHeight);
    [self.backGroundImageView sd_setImageWithURL:[NSURL URLWithString:self.pic]];
    [HCBlurViewTool blurView:self.backGroundImageView style:UIBarStyleDefault];
}
- (void)setUpScrollView
{
    self.scrollView = [HCCreatTool scrollViewWithView:self.view];
    self.scrollView.frame = self.view.frame;
    self.scrollView.showsVerticalScrollIndicator = NO;
    self.scrollView.contentSize = CGSizeMake(0, HCScreenHeight + HCScreenWidth * 0.5);
    
    self.headView = [[HCPublicHeadView alloc] initWithFullHead:arc4random() % 2];
    self.headView.frame = CGRectMake(0, 40, HCScreenWidth, HCScreenWidth * 0.5 + 60);
    [self.scrollView addSubview:self.headView];
    
    self.tableView = [[HCPublicTableView alloc] init];
    self.tableView.frame = CGRectMake(0, HCScreenWidth * 0.5 + 100, HCScreenWidth, HCScreenHeight);
    [self.scrollView addSubview:self.tableView];
}

#pragma mark - loadListData
- (void)loadSongList
{
   [HCNetWorkTool netWorkToolGetWithUrl:HCUrl parameters:HCParams(@"method":@"baidu.ting.album.getAlbumInfo",@"album_id":self.album_id) response:^(id response) {
       HCPublicSonglistModel *songList = [HCPublicSonglistModel mj_objectWithKeyValues:response[@"albumInfo"]];
       [self.headView setNewAlbum:songList];
       NSInteger i = 0;
       for (NSDictionary *dict in response[@"songlist"]) {
           HCPublicSongDetailModel *songDetail = [HCPublicSongDetailModel mj_objectWithKeyValues:dict];
           songDetail.num = ++i;
           [self.songListArrayM addObject:songDetail];
           [self.songIdsArrayM addObject:songDetail.song_id];
       }
       [self.tableView setSongList:self.songListArrayM songIds:self.songIdsArrayM];
   }];
}
@end
