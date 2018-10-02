//
//  ZJHomeViewController.m
//  ZJFFmpegDemo
//
//  Created by 邓志坚 on 2018/9/28.
//  Copyright © 2018 邓志坚. All rights reserved.
//

#import "ZJHomeViewController.h"
#import "ZJFFmpegTestViewController.h"
#import "ZJFFmpegAudioDecodingViewController.h"
#import "ZJFFmpegVideoEncodeViewController.h"

static NSString *CellID = @"cell";
@interface ZJHomeViewController ()<UITableViewDelegate,UITableViewDataSource>

@property (nonatomic, strong) UITableView *mainTable;
@property (nonatomic, strong) NSArray *titleArray;

@end

@implementation ZJHomeViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    [self.view addSubview:self.mainTable];
    [self.mainTable mas_makeConstraints:^(MASConstraintMaker *make) {
        make.edges.mas_equalTo(0);
    }];
    
    self.titleArray = @[@"FFmpeg 测试",@"FFmpeg 音频解码",@"FFmpeg 视频编码"];
}

-(UITableView *)mainTable{
    if (!_mainTable) {
        _mainTable = [[UITableView alloc]init];
        _mainTable.backgroundColor = [UIColor whiteColor];
//        _mainTable.separatorStyle = UITableViewCellSeparatorStyleNone;
        _mainTable.delegate = self;
        _mainTable.dataSource = self;
        [_mainTable registerClass:[UITableViewCell class] forCellReuseIdentifier:CellID];
        _mainTable.tableFooterView = [[UIView alloc]init];
    }
    return _mainTable;
}

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section{
    return self.titleArray.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath{
    
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:CellID forIndexPath:indexPath];
    cell.textLabel.text = self.titleArray[indexPath.row];
    return cell;
}

-(void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath{
    
    switch (indexPath.row) {
            case 0:
        {
            ZJFFmpegTestViewController *ffmpeg = [[ZJFFmpegTestViewController alloc]init];
            [self.navigationController pushViewController:ffmpeg animated:YES];
        }
            break;
            case 1:
        {
            ZJFFmpegAudioDecodingViewController *audioDecoding = [[ZJFFmpegAudioDecodingViewController alloc]init];
            [self.navigationController pushViewController:audioDecoding animated:YES];
        }
            break;
            case 2:
        {
            ZJFFmpegVideoEncodeViewController *audioEncode = [[ZJFFmpegVideoEncodeViewController alloc]init];
            [self.navigationController pushViewController:audioEncode animated:YES];
        }
            
        default:
            break;
    }
    
}

@end
