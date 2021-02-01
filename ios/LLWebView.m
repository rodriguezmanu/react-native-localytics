#import "LLWebView.h"
#import "LocalyticsPlugin.h"

@interface LLWebView()

@property (nonatomic, strong, nonnull) LLMarketingWebViewHandler *webViewHandler;
@property (nonatomic, strong, nonnull) id<LLCampaignUpdated> updatedCallback;

@end

@interface LLMarketingWebViewHandler ()

//This prop exists in the SDK, so be sneaky and expose it.
@property (nonatomic, assign, nonnull) NSString *creativeFilePath;

@end

@implementation LLWebView

-(instancetype)initWithMarketingHandler:(LLMarketingWebViewHandler *)webViewHandler
                andCampaignUpdatedBlock:(id<LLCampaignUpdated>)callback {
    //this will be overridden by react - so this doesn't matter.
    CGRect frame = CGRectMake(0, 0, 100, 100);
    if (self = [super initWithFrame:frame configuration:[WKWebViewConfiguration new]]) {
        _webViewHandler = webViewHandler;
        _updatedCallback = callback;
    }
    return self;
}

- (void)setCampaign:(NSInteger)campaignId {
    LLInboxCampaign *campaign = [LocalyticsPlugin inboxCampaignFromCache:campaignId];
    if (campaign != nil) {
        //this should update the scripts
        [Localytics setupWebViewConfiguration:self.configuration withCampaign:campaign];
        
        self.webViewHandler.campaign = campaign;
        self.webViewHandler.creativeFilePath = campaign.creativeFilePath;
        [self.updatedCallback campaignUpdated];
        [self.webViewHandler loadCreative];
    }
}

@end
