//
//  WebHistroyListViewController.h
//  WKWebView_demo
//
//  Created by bet001 on 2018/8/25.
//  Copyright © 2018年 GrandSu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebHistroyListViewController : UITableViewController <UITableViewDelegate, UITableViewDataSource>
@property (nonatomic, strong) NSMutableArray *historyListMuArray;

@end
