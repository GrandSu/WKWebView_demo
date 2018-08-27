//
//  WebViewController.h
//  WKWebView_demo
//
//  Created by bet001 on 2018/8/24.
//  Copyright © 2018年 GrandSu. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface WebViewController : UIViewController<WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler>
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) UIProgressView *progressView;
@property (nonatomic, strong) UIToolbar *toolBar;
@property (nonatomic, strong) NSMutableArray *webHistoryListMuArray;

@end
