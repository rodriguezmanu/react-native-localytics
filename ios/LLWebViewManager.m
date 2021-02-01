#import "LLWebViewManager.h"
#import <WebKit/WebKit.h>
#import "LLWebView.h"
@import Localytics;

@interface LLWebViewManager() <LLCampaignUpdated>

@property (nonatomic, strong) LLMarketingWebViewHandler *webViewHandler;

@end

@implementation LLWebViewManager

RCT_EXPORT_MODULE()

- (UIView *)view {
    _webViewHandler = [Localytics marketingWebViewHandler];
    LLWebView *webView = [[LLWebView alloc] initWithMarketingHandler:self.webViewHandler andCampaignUpdatedBlock:self];
    webView.translatesAutoresizingMaskIntoConstraints = NO;
    webView.navigationDelegate = self.webViewHandler;
    webView.UIDelegate = self.webViewHandler;
    self.webViewHandler.webView = webView;
    return webView;
}

- (void)campaignUpdated {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(dismiss)
                                                 name:UIApplicationWillResignActiveNotification
                                               object:nil];
}

RCT_EXPORT_VIEW_PROPERTY(campaign, NSInteger)

RCT_EXPORT_METHOD(dismiss) {
    [self.webViewHandler tagMarketingDismissAction];
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UIApplicationWillResignActiveNotification object:nil];
}

@end
