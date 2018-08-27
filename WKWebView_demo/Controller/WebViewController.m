//
//  WebViewController.m
//  WKWebView_demo
//
//  Created by bet001 on 2018/8/24.
//  Copyright © 2018年 GrandSu. All rights reserved.
//

#import "WebViewController.h"

@interface WebViewController ()
@property (nonatomic, copy) NSString *previousStatus;
@property (nonatomic, copy) NSString *currentStatus;
@property (nonatomic, assign) NSString *isVPNOpen;

@end

@implementation WebViewController

/** 设置状态栏风格 */
- (UIStatusBarStyle)preferredStatusBarStyle {
    return UIStatusBarStyleLightContent;
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    
    // 更新历史浏览记录数组
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    self.webHistoryListMuArray = [NSMutableArray arrayWithArray:[userDefaults objectForKey:HISTORYLIST_WEB]];
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    // 设置加载链接，也就是需要加载的web 地址
    [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URL_default]]];
    
    [self setNavigationBarButtonItem];
    [self setToolBarButtonItem];
    
    [self.view addSubview:self.toolBar];
    [self.view addSubview:self.webView];
    [self.webView addSubview:self.progressView];
    
    // 添加avaScriptMessageHandler
    [self addJavaScriptMessage];
    [self addNotifition];
}

- (void)addNotifition {
    NSLog(@"调用了监听");
    
    // 设置监听者KVO，监听 WKWebView 对象的 URL、title 和 estimatedProgress 属性，就是当前网页的地址、标题 和 网页加载的进度
    [self.webView addObserver:self forKeyPath:@"URL" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"title" options:NSKeyValueObservingOptionNew context:nil];
    [self.webView addObserver:self forKeyPath:@"estimatedProgress" options:NSKeyValueObservingOptionNew context:nil];
    
    // 设置NSNotification通知，监控网络状态变化
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alerControllerWithNetStatus) name:kRealReachabilityChangedNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(alerControllerWithNetStatus) name:kRRVPNStatusChangedNotification object:nil];
}

#pragma mark - JavaScript的交互
/** web与JS交互的弹窗 */
- (void)alertControllerWithJavaScript {
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"web与JS交互的弹窗" message:nil preferredStyle:UIAlertControllerStyleActionSheet];
    
    __weak typeof(self) weakSelf = self;
    [alertController addAction:[UIAlertAction actionWithTitle:@"alert弹窗" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        // js alert 提示代码
        NSString * promptCode = @"alert('这是警告弹窗');";
        [weakSelf.webView evaluateJavaScript:promptCode completionHandler:nil];
        
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"confirm弹窗" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        NSString * promptCode = @"var confirmed = confirm('这是选择弹窗?');";
        [weakSelf.webView evaluateJavaScript:promptCode completionHandler:nil];
        
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"prompt输入框" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        
        // promptCode 为js代码
        /*
         var 是定义一个变量用的，这里就定义了str这个变量；
         = 是赋值符号，将后面prompt的值赋予变量str；
         prompt是一个内置函数，用它可以调出资料框，让用户输入相关信息，而这些输入的信息就代表了它当前的值；
         */
        NSString *promptCode = @"var person = prompt('这是输入弹窗','不要输入我');";
        [self.webView evaluateJavaScript:promptCode completionHandler:nil];
        
    }]];
    
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

/** 添加JavaScript注入 */
- (void)addJavaScriptMessage {
    
    //设置内容交互控制器 用于处理JavaScript与native交互
    WKUserContentController * userController = [[WKUserContentController alloc]init];
    //设置处理代理并且注册要被js调用的方法名称
    [userController addScriptMessageHandler:self name:@"name"];
    [userController removeAllUserScripts];
    //js注入，注入一个测试方法。
    NSString *javaScriptSource = @"function userFunc(){window.webkit.messageHandlers.name.postMessage( {\"name\":\"WKWEB\"})}";
    WKUserScript *userScript = [[WKUserScript alloc] initWithSource:javaScriptSource injectionTime:WKUserScriptInjectionTimeAtDocumentStart forMainFrameOnly:YES];// forMainFrameOnly:NO(全局窗口)，yes（只限主窗口）
    [userController addUserScript:userScript];
    self.webView.configuration.userContentController = userController;
    
}

#pragma mark - WKScriptMessageHandler
/** WKScriptMessageHandler代理，关于对JavaScript信息的处理 */
- (void)userContentController:(WKUserContentController *)userContentController didReceiveScriptMessage:(WKScriptMessage *)message {

    if ([message.name isEqualToString:@"name"]) {
        
        NSString *jsStr = [NSString stringWithFormat:@"name:%@", [message.body objectForKey:@"name"]];
        [self.webView evaluateJavaScript:jsStr completionHandler:^(id _Nullable result, NSError * _Nullable error) {
            NSLog(@"result:%@ --- error:%@", result, error);
        }];
        
    }
}

#pragma mark - 消息监听
/** KVO监听 */
- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary<NSKeyValueChangeKey,id> *)change context:(void *)context {
    static NSInteger listCount = 0;
    
    // 设置历史浏览记录
    if (self.webView.backForwardList.backList.count > listCount) {
        [self saveWebHistoryList];
    }
    if (listCount != self.webView.backForwardList.backList.count) {
        listCount = self.webView.backForwardList.backList.count;
    }
    
    // 判断是否是自定义webView
    if (object ==self.webView) {
        
        // 进度条
        if ([keyPath isEqualToString:@"estimatedProgress"]) {
            // 显示进度条
            [self.progressView setAlpha:1.0f];  //0.10000000000000001起
            
            // 跟踪进度
            BOOL animated = self.webView.estimatedProgress > self.progressView.progress;
            [self.progressView setProgress:self.webView.estimatedProgress animated:animated];
            
            // 打印进度条
            NSString *kk = @"%";
            NSLog(@"已加载：%.f%@", self.progressView.progress * 100, kk);
            
            // 完成加载后进度条动画
            if(self.webView.estimatedProgress >= 1.0f) {
                [UIView animateWithDuration:0.3f delay:0.3f options:UIViewAnimationOptionCurveEaseOut animations:^{
                    [self.progressView setAlpha:0.0f];
                    
                } completion:^(BOOL finished) {
                    [self.progressView setProgress:0.0f animated:NO];
                }];
            }
            
        }else if ([keyPath isEqualToString:@"title"] || [keyPath isEqualToString:@"URL"]) {
            // 设置显示标题
            [self setTitle:self.webView.title];
            
        }else {
            [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
        }
    }else {
        // 移除非法监听
        [super observeValueForKeyPath:keyPath ofObject:object change:change context:context];
    }
}

#pragma mark - 网络状态监听(RealReachability)
/** 网络状态弹窗 */
- (void)alerControllerWithNetStatus {
    
    if (self.previousStatus == nil) {
        self.previousStatus = self.currentStatus;
    }
    
    if ([GLobalRealReachability isVPNOn]) {
        self.isVPNOpen = @"已  开";
    } else {
        self.isVPNOpen = @"未  开";
    }
    
    NSString *statusString = [NSString stringWithFormat:@"之前网络类型：%@ \n当前网络类型：%@ \n是否开启VPN：%@", self.previousStatus, self.currentStatus, self.isVPNOpen];
    
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:nil message:statusString preferredStyle:UIAlertControllerStyleAlert];
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleDestructive handler:nil]];
    
    [self presentViewController:alertController animated:YES completion:nil];
}

/** 获取当前网络状态 */
- (NSString *)currentStatus {
    
    // 获取当前网络状态
    ReachabilityStatus status = [GLobalRealReachability currentReachabilityStatus];
    
    // 设置返回的网络状态 - 字符串
    NSString *statusString;
    switch (status) {
        case RealStatusUnknown:
            statusString = @"未知";
            break;
            
        case RealStatusNotReachable:
            statusString = @"无网络";
            break;
            
        case RealStatusViaWiFi:
            statusString = @"WI-FI";
            break;
            
        case RealStatusViaWWAN: {
            // 获取蜂窝移动网络类型
            WWANAccessType accessType = [GLobalRealReachability currentWWANtype];
            
            if (accessType == WWANType2G) {
                statusString = @"2G";
            }
            else if (accessType == WWANType3G) {
                statusString = @"3G";
            }
            else if (accessType == WWANType4G) {
                statusString = @"4G";
            }
            else {
                statusString = @"未知";
            }
            
            break;
        }
            
        default:
            statusString = @"🙅‍♂️";
            break;
    }
    
    return statusString;
}

#pragma mark - WKNavigationDelegate
/** 在发送请求之前，决定是否跳转 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    NSLog(@"发送请求前,决定是否跳转");
    
    // 如果跳转请求的页面框架为nil，则重新请求
    if (navigationAction.targetFrame == nil) {
        [webView loadRequest:navigationAction.request];
    }
    
    // ------  对scheme:相关的scheme处理 -------
    // 若遇到微信、支付宝、QQ等相关scheme，则跳转到本地App
    NSString *scheme = navigationAction.request.URL.scheme;
    
    // 判断scheme是否是 http或者https，并返回BOOL的值
    BOOL urlOpen = [scheme isEqualToString:@"https"] || [scheme isEqualToString:@"http"] || [scheme isEqualToString:@"about"];
    
    if (!urlOpen) {
        // 跳转相关客户端
        BOOL bSucc = [[UIApplication sharedApplication]openURL:navigationAction.request.URL];
        
        // 如果跳转失败，则弹窗提示用户
        if (!bSucc) {
            // 设置弹窗
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"温馨提示" message:@"未检测到该客户端，请您安装后重试。" preferredStyle:UIAlertControllerStyleAlert];
            // 确定按键不带点击事件
            [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDefault handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
        }
    }
    // 确认可以跳转，必须实现该方法，不实现会报错
    decisionHandler(WKNavigationActionPolicyAllow);
}

/** 在收到响应后，决定是否跳转 */
- (void)webView:(WKWebView *)webView decidePolicyForNavigationResponse:(WKNavigationResponse *)navigationResponse decisionHandler:(void (^)(WKNavigationResponsePolicy))decisionHandler {
    NSLog(@"在收到响应后，决定是否跳转");
    
    // 判断服务器是否处理了请求（处理404，403等情况）
    NSHTTPURLResponse *response = (NSHTTPURLResponse *)navigationResponse.response;
    if (response.statusCode == 200) {
        // statusCode:200 ->  服务器已成功处理了请求。-> 确认可以跳转
        decisionHandler (WKNavigationResponsePolicyAllow);
    }else {
        // 除了成功请求的，其他的 HTTPURLResponse 的状态码全部拒绝跳转（包括403、404）
        decisionHandler(WKNavigationResponsePolicyCancel);
    }
}

/** 页面开始加载内容时调用 */
- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"webView开始加载");
}

/** 收到服务器重定向之后调用（接收到服务器跳转请求）*/
- (void)webView:(WKWebView *)webView didReceiveServerRedirectForProvisionalNavigation:(WKNavigation *)navigation {
    NSLog(@"webView接收到服务器跳转请求");
}

/** 在开始加载数据时发生错误时调用 */
- (void)webView:(WKWebView *)webView didFailProvisionalNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"webView加载失败");
}

/** 响应的内容到达主页面的时候响应,刚准备开始渲染页面调用 */
- (void)webView:(WKWebView *)webView didCommitNavigation:(WKNavigation *)navigation {
    NSLog(@"webView内容开始返回");
}

/** 响应渲染完成后调用该方法 */
- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    NSLog(@"webView加载完成");
    
    // 自定义editMyLogo函数
    NSString *JavaScriptString = @"var script = document.createElement('script');"
    "script.type = 'text/javascript';"
    "script.text = \"function editMyLogo() { "
    "var logo = document.getElementById('logo');"
    "logo.innerHTML= logo.innerHTML + '简书';"
    "var imglist = logo.getElementsByTagName('IMG');"
    "for (i=0 ; i < imglist.length ; i++ ){"
    "imglist[i].src = 'http://mariafresa.net/data_gallery/closed-mouth-clip-art-clipart-panda-free-clipart-images-Tn7SLi-clipart_13401.jpeg';"
    "}"
    "}\";"
    "document.getElementsByTagName('head')[0].appendChild(script);";
    
    [webView evaluateJavaScript:JavaScriptString completionHandler:nil];
    
    // 执行editMyLogo函数
    [webView evaluateJavaScript:@"editMyLogo();" completionHandler:nil];
}

/** 当一个正在提交的页面在跳转过程中出现错误时调用这个方法 */
- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    NSLog(@"webView跳转失败");
    NSLog(@"Error:%@", error);
}

/** 当Web视图需要验证证书时调用 https 可以自签名 */
- (void)webView:(WKWebView *)webView didReceiveAuthenticationChallenge:(nonnull NSURLAuthenticationChallenge *)challenge completionHandler:(nonnull void (^)(NSURLSessionAuthChallengeDisposition, NSURLCredential * _Nullable))completionHandler {
    
    if (challenge.protectionSpace.authenticationMethod == NSURLAuthenticationMethodServerTrust) {
        // 如果没有错误的情况下，创建一个凭证，并使用证书
        if (challenge.previousFailureCount == 0) {
            //创建一个凭证，并使用证书
            NSURLCredential *credential = [[NSURLCredential alloc] initWithTrust:challenge.protectionSpace.serverTrust];
            completionHandler(NSURLSessionAuthChallengeUseCredential, credential);
        }else {
            //验证失败，取消本次验证
            completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
        }
    }else {
        //验证失败，取消本次验证
        completionHandler(NSURLSessionAuthChallengeCancelAuthenticationChallenge, nil);
    }
    
}

/** 在Web视图的Web内容进程终止时调用,该API仅支持 macosx(10.11)和ios(9.0)) 及以上的系统 */
- (void)webViewWebContentProcessDidTerminate:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0)) {
    
}

#pragma mark - WKUIDelegate
/** 创建新的webView（打开新窗口） */
- (nullable WKWebView *)webView:(WKWebView *)webView createWebViewWithConfiguration:(WKWebViewConfiguration *)configuration forNavigationAction:(WKNavigationAction *)navigationAction windowFeatures:(WKWindowFeatures *)windowFeatures {
    
    /** 创建新的wenview窗口有点浪费资源，直接在原有窗口进行加载即可 */
    WKFrameInfo *frameInfo = navigationAction.targetFrame;
    if (![frameInfo isMainFrame]) {
        [webView loadRequest:navigationAction.request];
    }
    NSLog(@"打开新窗口");
    return nil;
}

/** webView关闭时调用，该API仅支持 macosx(10.11)和ios(9.0)以上的系统 */
- (void)webViewDidClose:(WKWebView *)webView API_AVAILABLE(macosx(10.11), ios(9.0)) {
    NSLog(@"关闭webView");
}

/** 以下三个代理都是与界面弹出提示框相关，分别针对web界面的三种提示框（警告框、确认框、输入框）的代理，如果不实现网页的alert函数无效 */
/** 警告框【警告提示弹窗，一个按键，如果未实现此方法，则Web视图的行为就像用户选择了“确定”按钮一样】 */
- (void)webView:(WKWebView *)webView runJavaScriptAlertPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(void))completionHandler {
    
    // 初始化 alertController
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    // 添加 action 按键
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDefault handler:^(UIAlertAction * _Nonnull action) {
        completionHandler();
        NSLog(@"点击了警告弹窗的确定按键");
    }])];
    // 弹出一个新视图 可以带动画效果，完成后可以做相应的执行函数经常为nil
    [self presentViewController:alertController animated:YES completion:nil];
}

/** 选择框【选择提示弹窗，两个按键，如果未实现此方法，则Web视图的行为就像用户选择“取消”按钮一样】 */
- (void)webView:(WKWebView *)webView runJavaScriptConfirmPanelWithMessage:(NSString *)message initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(BOOL))completionHandler {
    
    // 初始化 alertController
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"提示" message:message?:@"" preferredStyle:UIAlertControllerStyleAlert];
    // 添加 action 按键
    [alertController addAction:([UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(NO);
        NSLog(@"点击了选择弹窗的取消按键");
    }])];
    [alertController addAction:([UIAlertAction actionWithTitle:@"确认" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(YES);
        NSLog(@"点击了选择弹窗的确定按键");
    }])];
    // 弹出一个新视图 可以带动画效果，完成后可以做相应的执行函数经常为nil
    [self presentViewController:alertController animated:YES completion:nil];
}

/** 输入框【文本输入弹窗，两个按键，如果未实现此方法，则Web视图的行为就像用户选择“取消”按钮一样】 */
- (void)webView:(WKWebView *)webView runJavaScriptTextInputPanelWithPrompt:(NSString *)prompt defaultText:(NSString *)defaultText initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSString * _Nullable))completionHandler {
    
    // 初始化 alertController
    UIAlertController *alertController = [UIAlertController alertControllerWithTitle:prompt message:nil preferredStyle:UIAlertControllerStyleAlert];
    // alertController 添加 TextField 输入框
    [alertController addTextFieldWithConfigurationHandler:^(UITextField * _Nonnull textField) {
        textField.text = defaultText;
    }];
    // 添加 action
    [alertController addAction:[UIAlertAction actionWithTitle:@"取消" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(nil);
        NSLog(@"点击了输入弹窗的取消按键");
    }]];
    [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:^(UIAlertAction * _Nonnull action) {
        completionHandler(alertController.textFields[0].text?:@"");
        NSLog(@"点击了输入弹窗的确定按键");
    }]];
    // 弹出一个新视图 可以带动画效果，完成后可以做相应的执行函数经常为nil
    [self presentViewController:alertController animated:YES completion:nil];
}

#if TARGET_OS_IPHONE
/** 允许您的应用确定给定元素是否应显示预览，只有在WebKit中具有默认预览的元素才会调用此方法，该方法仅限于链接。该API仅支持ios(10.0)及以上系统 */
- (BOOL)webView:(WKWebView *)webView shouldPreviewElement:(WKPreviewElementInfo *)elementInfo  API_AVAILABLE(ios(10.0)){
    return NO;
}

/** 显示预览的视图，该API仅支持 ios(10.0)以上的系统
 【返回ViewController将显示预览界面，defaultActions返回您想要的任何操作查看控制器，接着调用webView：commitPreviewingViewController。返回nil将关闭预览效果】 */
- (nullable UIViewController *)webView:(WKWebView *)webView previewingViewControllerForElement:(WKPreviewElementInfo *)elementInfo defaultActions:(NSArray<id <WKPreviewActionItem>> *)previewActions API_AVAILABLE(ios(10.0)) {
    return nil;
}

/*! @abstract 允许您的应用弹出到它创建的视图控制器。
 @param webView 调用委托方法的Web视图。
 @param previewingViewController 正在弹出的视图控制器。
 */
- (void)webView:(WKWebView *)webView commitPreviewingViewController:(UIViewController *)previewingViewController API_AVAILABLE(ios(10.0)) {
    
}

#endif // TARGET_OS_IPHONE

#if !TARGET_OS_IPHONE

/*! @abstract 显示文件上传面板，该API仅支持 macosx(10.12)及以上系统。
 @param webView 调用委托方法的Web视图。
 @param parameters 参数描述文件上载控件的参数。
 @param frame 有关文件上载控件启动此调用的帧的信息。
 @param 打开面板后调用的完成处理程序已被解除。如果用户选择“确定”，则传递选定的URL，否则为nil。
 
 如果未实现此方法，则Web视图的行为就像用户选择“取消”按钮一样。
 */
- (void)webView:(WKWebView *)webView runOpenPanelWithParameters:(WKOpenPanelParameters *)parameters initiatedByFrame:(WKFrameInfo *)frame completionHandler:(void (^)(NSArray<NSURL *> * _Nullable URLs))completionHandler API_AVAILABLE(macosx(10.12)) {
    
}
#endif

#pragma mark - 按键点击事件
- (void)buttonClick:(UIBarButtonItem *)button {
    
    switch (button.tag) {
        case 111: {
            // JavaScript注入弹窗
            [self alertControllerWithJavaScript];
            break;
        }
        case 222: {
            // 获取网络状态弹窗
            [self alerControllerWithNetStatus];
            break;
        }
        case 333: {
            // 浏览历史记录列表
            WebHistroyListViewController *webHistroyListVC = [[WebHistroyListViewController alloc] init];
            webHistroyListVC.historyListMuArray = [NSMutableArray arrayWithArray:self.webHistoryListMuArray];
            [self.navigationController pushViewController:webHistroyListVC animated:YES];
            break;
        }
        case 444: {
            // 加载主页
            [self.webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:URL_default]]];
            break;
        }
        default: {
            // 错误按键设置
            UIAlertController *alertController = [UIAlertController alertControllerWithTitle:@"警告" message:@"按键设置错误" preferredStyle:UIAlertControllerStyleAlert];
            [alertController addAction:[UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleDestructive handler:nil]];
            [self presentViewController:alertController animated:YES completion:nil];
            break;
        }
    }
}

/** 设置导航栏按键点击事件 */
- (void)navigationBarButtonClick:(UIBarButtonItem *)button {
    switch (button.tag) {
        case 110:
            if ([self.webView canGoBack]) {
                [self.webView goBack];
            }
            break;
            
        default:
            [self.webView reloadFromOrigin];
            break;
    }
}

/** 保存历史浏览记录到用户数据库，进行持久化存储 */
- (void)saveWebHistoryList {
    //获取NSUserDefaults对象
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    //存数据，不需要设置路劲，NSUserDefaults将数据保存在preferences目录下
    WKBackForwardListItem *listItem = [self.webView.backForwardList.backList lastObject];
    NSDictionary *webList = [NSDictionary dictionaryWithObjectsAndKeys:listItem.title, @"title", listItem.URL.absoluteString, @"URL", nil];
    [self.webHistoryListMuArray insertObject:webList atIndex:0];
    NSArray *arr = [NSArray arrayWithArray:self.webHistoryListMuArray];
    [userDefaults setObject:arr forKey:HISTORYLIST_WEB];
    
    //立刻保存（同步）数据（如果不写这句话，会在将来某个时间点自动将数据保存在preferences目录下）
    [userDefaults synchronize];
    NSLog(@"数据已保存");
}

#pragma mark - 控件加载
/** 设置导航栏按键 */
- (void)setNavigationBarButtonItem {
    // 返回按键
    self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"返回" style:UIBarButtonItemStylePlain target:nil action:nil];
    self.navigationController.navigationBar.tintColor = [UIColor redColor];
    // 左边后退按键
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"后退" style:UIBarButtonItemStylePlain target:self action:@selector(navigationBarButtonClick:)];
    
    // 右边刷新按键
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"刷新" style:UIBarButtonItemStylePlain target:self action:@selector(navigationBarButtonClick:)];
    
    self.navigationItem.leftBarButtonItem.tag = 110;
    self.navigationItem.rightBarButtonItem.tag = 120;
}

/** 设置工具栏按键 */
- (void)setToolBarButtonItem {
    
    // 创建工具栏按键，两个按键之间用空格隔开
    UIBarButtonItem *jsButton = [[UIBarButtonItem alloc] initWithTitle:@"JS交互" style:UIBarButtonItemStylePlain target:self action:@selector(buttonClick:)];
    
    UIBarButtonItem *networkButton = [[UIBarButtonItem alloc] initWithTitle:@"网络" style:UIBarButtonItemStylePlain target:self action:@selector(buttonClick:)];
    
    UIBarButtonItem *historyButton = [[UIBarButtonItem alloc] initWithTitle:@"历史" style:UIBarButtonItemStylePlain target:self action:@selector(buttonClick:)];
    
    UIBarButtonItem *mainButton = [[UIBarButtonItem alloc] initWithTitle:@"主页" style:UIBarButtonItemStylePlain target:self action:@selector(buttonClick:)];
    
    // 设置tag值
    jsButton.tag = 111;
    networkButton.tag = 222;
    historyButton.tag = 333;
    mainButton.tag = 444;
    
    // 设置空白位，并将按键设置到工具栏，两个按键之间用空白按键隔开
    UIBarButtonItem * spacer = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
    self.toolBar.items = @[jsButton,spacer,networkButton,spacer,historyButton,spacer,mainButton];
}


/** 工具栏 */
- (UIToolbar *)toolBar {
    if (!_toolBar) {
        // 初始化工具栏
        _toolBar = [[UIToolbar alloc] initWithFrame:FRAME_toolBar];
        _toolBar.barTintColor = [UIColor whiteColor];
        
        // 自动适配横屏
        [_toolBar setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [_toolBar setAutoresizesSubviews:YES];
    }
    return _toolBar;
}

- (WKWebView *)webView {
    if (!_webView) {
        
        // 初始化
        WKWebViewConfiguration *configuration = [[WKWebViewConfiguration alloc] init];
        
        // 设置偏好设置(WKPreferences)
        configuration.preferences = [[WKPreferences alloc] init];
        // 设置最小字体大小
        configuration.preferences.minimumFontSize = 8;
        // 是否支持 JavaScript
        configuration.preferences.javaScriptEnabled = YES;
        // 是否可以不通过用户交互打开窗口
        configuration.preferences.javaScriptCanOpenWindowsAutomatically = NO;
        
        //设置是否将网页内容全部加载到内存后再渲染
        configuration.suppressesIncrementalRendering = NO;
        //设置HTML5视频是否允许网页播放 设置为NO则会使用本地播放器
        configuration.allowsInlineMediaPlayback =  YES;
        //设置是否允许ariPlay播放
        configuration.allowsAirPlayForMediaPlayback = YES;
        //设置视频是否需要用户手动播放  设置为NO则会允许自动播放
        configuration.requiresUserActionForMediaPlayback = NO;
        //设置是否允许画中画技术 在特定设备上有效
        configuration.allowsPictureInPictureMediaPlayback = YES;
        
        /*  设置选择模式 是按字符选择 还是按模块选择
         typedef NS_ENUM(NSInteger, WKSelectionGranularity) {
         WKSelectionGranularityDynamic,     //按模块选择
         WKSelectionGranularityCharacter,      //按字符选择
         } NS_ENUM_AVAILABLE_IOS(8_0);
         */
        configuration.selectionGranularity = WKSelectionGranularityCharacter;
        //设置请求的User-Agent信息中应用程序名称 iOS9后可用
        configuration.applicationNameForUserAgent = @"WKWEB";
        
        
        _webView = [[WKWebView alloc] initWithFrame:FRAME_webView configuration:configuration];
        // 开启做滑动退回
        _webView.allowsBackForwardNavigationGestures = YES;
        // 使用代理
        _webView.navigationDelegate = self;
        _webView.UIDelegate = self;
        // 如果需要加入JS 交互需要使用的是WKUIdelegate
        [self.view addSubview:_webView];
        
        // 自动适配横屏
        [_webView setAutoresizingMask:UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight];
        [_webView setAutoresizesSubviews:YES];
    }
    return _webView;
}

/** 设置进度条 */
- (UIProgressView *)progressView {
    if (!_progressView) {
        // 初始化并设置展示风格（ UIProgressViewStyleBar 一般用于 toolbar ）
        _progressView = [[UIProgressView alloc] initWithProgressViewStyle:UIProgressViewStyleBar];
        _progressView.frame = FRAME_progressView;
        
        // 未加载进度颜色
        _progressView.trackTintColor = [UIColor clearColor];
        // 加载进度颜色
        _progressView.progressTintColor = [UIColor redColor];
    }
    return _progressView;
}

#pragma mark - 屏幕旋转监控
/** 屏幕方向改变 */
- (void)viewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
    [super viewWillTransitionToSize:size withTransitionCoordinator:coordinator];
    NSLog(@"屏幕方面变了");
}


#pragma mark - 移除监听
- (void)dealloc {
    NSLog(@"调用了清除监听着");
    // 移除 KVO
    [self.webView removeObserver:self forKeyPath:@"title"];
    [self.webView removeObserver:self forKeyPath:@"estimatedProgress"];
    // 移除网络监听
    [[NSNotificationCenter defaultCenter] removeObserver:self];
    // 移除 ScriptMessageHandler
    [self.webView.configuration.userContentController removeScriptMessageHandlerForName:@"name"];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
