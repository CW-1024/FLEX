//
//  FLEXWebViewController.m
//  Flipboard
//
//  由 Ryan Olson 创建于 6/10/14.
//  版权所有 (c) 2020 FLEX Team. 保留所有权利。
//

#import "FLEXWebViewController.h"
#import "FLEXUtility.h"
#import <WebKit/WebKit.h>

@interface FLEXWebViewController () <WKNavigationDelegate>

@property (nonatomic) WKWebView *webView;
@property (nonatomic) NSString *originalText;

@end

@implementation FLEXWebViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        WKWebViewConfiguration *configuration = [WKWebViewConfiguration new];

        if (@available(iOS 10.0, *)) {
            configuration.dataDetectorTypes = WKDataDetectorTypeLink;
        }

        self.webView = [[WKWebView alloc] initWithFrame:CGRectZero configuration:configuration];
        self.webView.navigationDelegate = self;
    }
    return self;
}

- (id)initWithText:(NSString *)text {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        self.originalText = text;

        NSString *html = @"<head><style>:root{ color-scheme: light dark; }</style>"
            "<meta name='viewport' content='initial-scale=1.0'></head><body><pre>%@</pre></body>";

        // 当输入文本转义需要很长时间时显示的加载消息
        NSString *loadingMessage = [NSString stringWithFormat:html, @"加载中..."];
        [self.webView loadHTMLString:loadingMessage baseURL:nil];

        // 在后台线程中转义 HTML
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
            NSString *escapedText = [FLEXUtility stringByEscapingHTMLEntitiesInString:text];
            NSString *htmlString = [NSString stringWithFormat:html, escapedText];

            // 在主线程上更新 webview
            dispatch_async(dispatch_get_main_queue(), ^{
                [self.webView loadHTMLString:htmlString baseURL:nil];
            });
        });
    }

    return self;
}

- (id)initWithURL:(NSURL *)url {
    self = [self initWithNibName:nil bundle:nil];
    if (self) {
        NSURLRequest *request = [NSURLRequest requestWithURL:url];
        [self.webView loadRequest:request];
    }

    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    
    [self.view addSubview:self.webView];
    self.webView.frame = self.view.bounds;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight;
    
    if (self.originalText.length > 0) {
        self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]
            initWithTitle:@"复制" style:UIBarButtonItemStylePlain target:self action:@selector(copyButtonTapped:)
        ];
    }
}

- (void)copyButtonTapped:(id)sender {
    [UIPasteboard.generalPasteboard setString:self.originalText];
}


#pragma mark - WKWebView 代理

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
                                                     decisionHandler:(void (^)(WKNavigationActionPolicy))handler {
    WKNavigationActionPolicy policy = WKNavigationActionPolicyCancel;
    if (navigationAction.navigationType == WKNavigationTypeOther) {
        // 允许初始加载
        policy = WKNavigationActionPolicyAllow;
    } else {
        // 对于点击的链接，将另一个网页视图控制器推到导航栈上
        // 以便按返回按钮时可按预期工作。
        // 不允许当前网页视图处理导航。
        NSURLRequest *request = navigationAction.request;
        FLEXWebViewController *webVC = [[[self class] alloc] initWithURL:request.URL];
        webVC.title = request.URL.absoluteString;
        [self.navigationController pushViewController:webVC animated:YES];
    }

    handler(policy);
}


#pragma mark - 类辅助方法

+ (BOOL)supportsPathExtension:(NSString *)extension {
    BOOL supported = NO;
    NSSet<NSString *> *supportedExtensions = [self webViewSupportedPathExtensions];
    if ([supportedExtensions containsObject:extension.lowercaseString]) {
        supported = YES;
    }
    return supported;
}

+ (NSSet<NSString *> *)webViewSupportedPathExtensions {
    static NSSet<NSString *> *pathExtensions = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        // 请注意，这不是详尽的，但所有这些扩展名在网页视图中都应该能正常工作。
        // 参见 https://developer.apple.com/library/archive/documentation/AppleApplications/Reference/SafariWebContent/CreatingContentforSafarioniPhone/CreatingContentforSafarioniPhone.html#//apple_ref/doc/uid/TP40006482-SW7
        pathExtensions = [NSSet<NSString *> setWithArray:@[
            @"jpg", @"jpeg", @"png", @"gif", @"pdf", @"svg", @"tiff", @"3gp", @"3gpp", @"3g2",
            @"3gp2", @"aiff", @"aif", @"aifc", @"cdda", @"amr", @"mp3", @"swa", @"mp4", @"mpeg",
            @"mpg", @"mp3", @"wav", @"bwf", @"m4a", @"m4b", @"m4p", @"mov", @"qt", @"mqv", @"m4v"
        ]];
        
    });

    return pathExtensions;
}

@end
