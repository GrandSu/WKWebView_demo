//
//  webHistroyListViewController.m
//  WKWebView_demo
//
//  Created by bet001 on 2018/8/25.
//  Copyright © 2018年 GrandSu. All rights reserved.
//

#import "WebHistroyListViewController.h"

@interface WebHistroyListViewController ()

@end

@implementation WebHistroyListViewController

/** 更新用户数据库中的浏览记录 */
- (void)updateWebHistoryListInUserDefaults {
    NSUserDefaults *user = [NSUserDefaults standardUserDefaults];
    NSArray *historyList = [NSArray arrayWithArray:self.historyListMuArray];
    [user setObject:historyList forKey:HISTORYLIST_WEB];
}

/** 每次加载时都同步更新一下数据库浏览历史 */
- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self updateWebHistoryListInUserDefaults];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // Uncomment the following line to preserve selection between presentations.
    self.clearsSelectionOnViewWillAppear = NO;
    
    self.tableView.delegate = self;
    self.tableView.dataSource = self;
    self.tableView.showsVerticalScrollIndicator = NO;
    self.tableView.showsHorizontalScrollIndicator = NO;
    
    UIView * view = [[UIView alloc] init];
    self.tableView.tableFooterView = view;

    self.automaticallyAdjustsScrollViewInsets = NO;

    self.navigationItem.title = @"历史记录";
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"清除" style:UIBarButtonItemStylePlain target:self action:@selector(navigationBarButtonClick:)];
}

/** 导航栏按键点击时间 */
- (void)navigationBarButtonClick:(UIBarButtonItem *)button {
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"是否清除所有的历史记录" preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:nil]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        [self.historyListMuArray removeAllObjects];
        [self updateWebHistoryListInUserDefaults];
        [self.tableView reloadData];
    }]];
    [self.navigationController presentViewController:alertController animated:YES completion:nil];
}

#pragma mark - UITableViewDataSource
/** 行数 */
- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.historyListMuArray.count;
}

/** 单元格设置 */
- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    static NSString *cellIdentifier = @"HISTORYLIST";
    UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:cellIdentifier];
    if (cell == nil) {
        cell = [[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:cellIdentifier];
        
        cell.selectionStyle = UITableViewCellSelectionStyleNone;
        cell.backgroundColor = [UIColor clearColor];
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
    }
    
    NSDictionary *dic = [self.historyListMuArray objectAtIndex:indexPath.row];
    NSString *titleString = [dic valueForKey:@"title"];
    NSString *URLString = [dic valueForKey:@"URL"];
    if (titleString.length) {
        cell.textLabel.text = [dic valueForKey:@"title"];
    } else {
        cell.textLabel.text = @"无标题网页";
    }
    
    if (URLString.length) {
        cell.detailTextLabel.text = [dic valueForKey:@"URL"];
    } else {
        cell.detailTextLabel.text = @"未知网络";
    }
    
    
    return cell;
}

#pragma mark - UITableViewDelegate
/** 选中单元格 */
- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath {
    UITableViewCell *cell = [tableView cellForRowAtIndexPath:indexPath];
    
    // 有网络地址的请求该网络地址
    if (![cell.detailTextLabel.text isEqualToString:@"未知网络"]) {
        WebViewController *webVC = [self.navigationController.viewControllers objectAtIndex:self.navigationController.viewControllers.count - 2];
        [webVC.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:cell.detailTextLabel.text]]];
        [self.navigationController popViewControllerAnimated:YES];
    }
    
    // 历史记录没有存储该网络地址的返回警告
    else {
        UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"警告" message:@"数据错误，无法加载" preferredStyle:UIAlertControllerStyleAlert];
        [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:nil]];
        [self.navigationController presentViewController:alertController animated:YES completion:nil];
    }
}

/** 单元格编辑方式 */
- (UITableViewCellEditingStyle)tableView:(UITableView *)tableView editingStyleForRowAtIndexPath:(NSIndexPath *)indexPath{
    return UITableViewCellEditingStyleDelete;
}

/** 返回左滑编辑按键文字 */
- (nullable NSString *)tableView:(UITableView *)tableView titleForDeleteConfirmationButtonForRowAtIndexPath:(NSIndexPath *)indexPath {
    return @"删除";
}

/** 单元格编辑模式 */
- (void)tableView:(UITableView *)tableView commitEditingStyle:(UITableViewCellEditingStyle)editingStyle forRowAtIndexPath:(NSIndexPath *)indexPath {

    if (editingStyle == UITableViewCellEditingStyleDelete) {
        [self.historyListMuArray removeObjectAtIndex:indexPath.row];
        [tableView deleteRowsAtIndexPaths:@[indexPath] withRowAnimation:UITableViewRowAnimationNone];
        [self updateWebHistoryListInUserDefaults];
    }
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}


@end
