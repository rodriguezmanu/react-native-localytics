#import <WebKit/WebKit.h>
@import Localytics;
#import "LLWebViewManager.h"

NS_ASSUME_NONNULL_BEGIN

@interface LLWebView : WKWebView

-(instancetype)initWithMarketingHandler:(LLMarketingWebViewHandler *)webViewHandler
                andCampaignUpdatedBlock:(id<LLCampaignUpdated>)block;

@end

NS_ASSUME_NONNULL_END
