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

@end


@implementation YOAuth2ViewController

@synthesize token = _token;
@synthesize delegate = _delegate;

- (instancetype)initWithDelegate:(id<YOAuth2Delegate>)authDelegate {
    self = [super init];
    if (self) {
        _delegate = authDelegate;
    }
    return self;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    self.webView = [[WKWebView alloc] initWithFrame:self.view.bounds configuration:[WKWebViewConfiguration new]];
    self.webView.navigationDelegate = self;
    self.webView.translatesAutoresizingMaskIntoConstraints = YES;
    self.webView.autoresizingMask = UIViewAutoresizingFlexibleHeight | UIViewAutoresizingFlexibleWidth;
    
    [self.view addSubview:self.webView];
    
    NSURL *url = [NSURL URLWithString:self.authURI];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];
    
    [self.webView loadRequest:request];
    
    
}

- (void)viewDidAppear:(BOOL)animated {
    [super viewDidAppear:animated];
    self.appeared = YES;
    [self handleResult];
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
