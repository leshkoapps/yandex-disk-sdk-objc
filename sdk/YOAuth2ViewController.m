/* Лицензионное соглашение на использование набора средств разработки
 * «SDK Яндекс.Диска» доступно по адресу: http://legal.yandex.ru/sdk_agreement
 */


#import "YOAuth2ViewController.h"
#import "NSNotificationCenter+Additions.h"
#import "YDConstants.h"
#import <WebKit/WebKit.h>

@interface YOAuth2ViewController () <WKNavigationDelegate>

@property (nonatomic, assign) BOOL appeared;
@property (nonatomic, assign) BOOL done;
@property (nonatomic, strong) WKWebView *webView;
@property (nonatomic, strong) NSError *error;
@property (nonatomic, copy, readwrite) NSString *token;
@property (nonatomic, assign)YOAuth2ViewControllerOptions options;

@end


@implementation YOAuth2ViewController

@synthesize token = _token;
@synthesize delegate = _delegate;

- (instancetype)initWithDelegate:(id<YOAuth2Delegate>)authDelegate options:(YOAuth2ViewControllerOptions)options{
    self = [super init];
    if (self) {
        _options = options;
        _delegate = authDelegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];

    if((self.options & YOAuth2ViewControllerOptionsClearCookies) == YOAuth2ViewControllerOptionsClearCookies){
        [self clearLoginCookies];
    }
    
    WKWebViewConfiguration *theConfiguration = [[WKWebViewConfiguration alloc] init];
    @try{if (NSFoundationVersionNumber >= NSFoundationVersionNumber_iOS_9_0) {
        theConfiguration.websiteDataStore = [WKWebsiteDataStore nonPersistentDataStore];
    }} @catch(NSException *exc){}

    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds
                                      configuration:theConfiguration];
    self.webView.navigationDelegate = self;
    self.webView.translatesAutoresizingMaskIntoConstraints = YES;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:self.webView];
    
    NSURL *url = [NSURL URLWithString:self.authURI];
    NSMutableURLRequest *request = [NSMutableURLRequest requestWithURL:url];
    [request setAllowsCellularAccess:YES];
    [request setCachePolicy:NSURLRequestReloadIgnoringLocalCacheData];
    
    [self.webView loadRequest:request];
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.appeared = YES;
    [self handleResult];
}

#pragma mark - Clear Cookies

- (NSArray *)loginDomains{
    return @[@"oauth.yandex.ru",
             @".oauth.yandex.ru",
             @"oauth.yandex.com",
             @".oauth.yandex.com",
             @"webdav.yandex.ru",
             @".webdav.yandex.ru",
             @"webdav.yandex.com",
             @".webdav.yandex.com",
             @"passport.yandex.ru",
             @".passport.yandex.ru",
             @"passport.yandex.com",
             @".passport.yandex.com",
             @".yandex.ru",
             @"yandex.ru",
             @".yandex.com",
             @"yandex.com",
             @".mc.yandex.ru",
             @"mc.yandex.ru",
             @".mc.yandex.com",
             @"mc.yandex.com",
    ];
}

- (BOOL)isDomainValidForCookie:(NSHTTPCookie *)cookie domains:(NSArray<NSString *> *)domains{
    __block BOOL success = NO;
    [domains enumerateObjectsUsingBlock:^(NSString * _Nonnull obj, NSUInteger idx, BOOL * _Nonnull stop) {
        if([cookie.domain hasSuffix:obj]){
            success = YES;
            *stop = YES;
        }
    }];
    return success;
}

- (void)clearLoginCookies{
    for(NSHTTPCookie *cookie in [[NSHTTPCookieStorage sharedHTTPCookieStorage] cookies]) {
        if([self isDomainValidForCookie:cookie domains:self.loginDomains]){
             [[NSHTTPCookieStorage sharedHTTPCookieStorage] deleteCookie:cookie];
        }
    }
}

#pragma mark - WKWebViewDelegate methods

- (void)webView:(WKWebView *)webView didStartProvisionalNavigation:(null_unspecified WKNavigation *)navigation{
    [[NSNotificationCenter defaultCenter] postNotificationInMainQueueWithName:kYDSessionDidStartAuthRequestNotification
                                                                       object:self
                                                                     userInfo:nil];
}

- (void)webView:(WKWebView *)webView decidePolicyForNavigationAction:(WKNavigationAction *)navigationAction
decisionHandler:(void (^)(WKNavigationActionPolicy))decisionHandler {
    
    NSString *uri = navigationAction.request.URL.absoluteString;
    if ([uri hasPrefix:self.delegate.redirectURL]) { // did we get redirected to the redirect url?
        NSArray *split = [uri componentsSeparatedByString:@"#"];
        NSString *param = split[1];
        split = [param componentsSeparatedByString:@"&"];
        NSMutableDictionary *paraDict = [NSMutableDictionary dictionary];
        
        for (NSString *s in split) {
            NSArray *kv = [s componentsSeparatedByString:@"="];
            if (kv) {
                paraDict[kv[0]] = kv[1];
            }
        }
        
        if (paraDict[@"access_token"]) {
            self.token = paraDict[@"access_token"];
            self.done = YES;
        }
        else if (paraDict[@"error"]) {
            self.error = [NSError errorWithDomain:kYDSessionAuthenticationErrorDomain
                                             code:kYDSessionErrorUnknown
                                         userInfo:paraDict];
            self.done = YES;
        }
        [self handleResult];
    }
    decisionHandler(self.done ? WKNavigationActionPolicyCancel : WKNavigationActionPolicyAllow);
}

- (void)webView:(WKWebView *)webView didFailNavigation:(WKNavigation *)navigation withError:(NSError *)error {
    if (!self.done) {
        NSLog(@"%@", error.localizedDescription);
        [self handleError:error];
    }
}

- (void)webView:(WKWebView *)webView didFinishNavigation:(WKNavigation *)navigation {
    if (self.webView.scrollView.contentSize.width > self.webView.frame.size.width) {
        CGPoint offset = CGPointMake(self.webView.frame.size.width/4.0, self.webView.scrollView.contentOffset.y);
        [self.webView.scrollView setContentOffset:offset animated:YES];
    }
    [[NSNotificationCenter defaultCenter] postNotificationInMainQueueWithName:kYDSessionDidStopAuthRequestNotification
                                                                       object:self
                                                                     userInfo:nil];
}

- (NSString *)authURI {
    NSString *language = [[NSBundle mainBundle] preferredLocalizations].firstObject;
    if ([language isEqualToString:@"ru"]) {
        return [NSString stringWithFormat:@"https://oauth.yandex.ru/authorize?response_type=token&client_id=%@&display=popup", self.delegate.clientID];
        
    }
    return [NSString stringWithFormat:@"https://oauth.yandex.com/authorize?response_type=token&client_id=%@&display=popup", self.delegate.clientID];
}

- (void)handleResult {
    if (self.done && self.appeared) {
        if (self.token) {
            [self.delegate OAuthLoginSucceededWithToken:self.token];
            [[NSNotificationCenter defaultCenter] postNotificationInMainQueueWithName:kYDSessionDidAuthNotification
                                                                               object:self
                                                                             userInfo:@{@"token": self.token}];
        } else if (self.error) {
            [self handleError:self.error];
        }
    }
}

- (void)handleError:(NSError *)error {
    [self.delegate OAuthLoginFailedWithError:error];
    [[NSNotificationCenter defaultCenter] postNotificationInMainQueueWithName:kYDSessionDidFailWithAuthRequestNotification
                                                                       object:self
                                                                     userInfo:@{@"error": error}];
}

@end
