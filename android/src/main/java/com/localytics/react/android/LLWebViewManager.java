package com.localytics.react.android;

import android.annotation.SuppressLint;
import android.app.Activity;
import android.content.BroadcastReceiver;
import android.content.Context;
import android.content.Intent;
import android.content.IntentFilter;
import androidx.annotation.NonNull;
import androidx.annotation.Nullable;
import android.util.Log;
import android.webkit.WebResourceResponse;
import android.webkit.WebSettings;
import android.webkit.WebView;
import android.webkit.WebViewClient;

import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.uimanager.SimpleViewManager;
import com.facebook.react.uimanager.ThemedReactContext;
import com.facebook.react.uimanager.annotations.ReactProp;
import com.localytics.androidx.InboxCampaign;
import com.localytics.androidx.InboxMessageHandler;
import com.localytics.androidx.JavaScriptClient;
import com.localytics.androidx.Localytics;
import com.localytics.androidx.MarketingWebViewManager;

import java.util.concurrent.Callable;

public class LLWebViewManager extends SimpleViewManager<WebView> {

    private LLLocalyticsModule localyticsModule;
    private MarketingWebViewManager webViewManager;
    private JavaScriptClient javaScriptClient;
    // A receiver which listens for the home button
    private InnerReceiver homeButtonReceiver = new InnerReceiver();
    private Context reactContext;

    public LLWebViewManager(final LLLocalyticsModule localyticsModule) {
        this.localyticsModule = localyticsModule;
        webViewManager = Localytics.getInboxWebViewManager(new Callable<Activity>() {
            @Override
            public Activity call() {
                return localyticsModule.getActivity();
            }
        });
    }

    @Override
    public String getName() {
        return "LLWebView";
    }

    @SuppressLint("SetJavaScriptEnabled")
    @Override
    protected WebView createViewInstance(ThemedReactContext reactContext) {
        this.reactContext = reactContext;
        WebView webView = setupWebview(reactContext);
        homeButtonReceiver.attach(reactContext);
        return webView;
    }

    @Override
    public void receiveCommand(WebView root, int commandId, @Nullable ReadableArray args) {
        super.receiveCommand(root, commandId, args);
        if (commandId == 0) {
            tagWebViewDismiss();
        }
    }

    @ReactProp(name = "campaign")
    public void setCampaign(WebView view, int campaignId) {
        InboxCampaign campaign = localyticsModule.getInboxCampaignFromCache(campaignId);
        if (campaign != null) {
            webViewManager.reset();
            webViewManager.setCampaign(campaign);
            InboxMessageHandler inboxMessageHandler = new InboxMessageHandler(view);
            webViewManager.setMessageHandler(inboxMessageHandler);
            javaScriptClient = webViewManager.getJavaScriptClient();
            if (javaScriptClient != null) {
                view.addJavascriptInterface(javaScriptClient, "localytics");
                view.loadUrl(campaign.getCreativeFilePath().toString());
            }
        }
    }

    @NonNull
    private WebView setupWebview(ThemedReactContext reactContext) {
        WebView webView = new WebView(reactContext);
        LLWebViewClient webViewClient = new LLWebViewClient();
        webView.setWebViewClient(webViewClient);
        webView.setInitialScale(1);
        WebSettings settings = webView.getSettings();
        settings.setJavaScriptEnabled(true);
        settings.setUseWideViewPort(true); // Enable 'viewport' meta tag
        webViewManager.setContext(reactContext);
        return webView;
    }

    private void tagWebViewDismiss() {
        webViewManager.tagMarketingActionEventWithAction("X", "dismiss");
        homeButtonReceiver.detach(reactContext);
    }

    private class LLWebViewClient extends WebViewClient {

        @Override
        public boolean shouldOverrideUrlLoading(WebView view, String url) {
            return webViewManager.handleShouldOverrideUrlLoading(url);
        }

        @Nullable
        @Override
        public WebResourceResponse shouldInterceptRequest(WebView view, @NonNull String url) {
            boolean intercept = webViewManager.shouldInterceptRequest(url);
            return intercept ? new WebResourceResponse("text/plain", "UTF-8", null) :
                    super.shouldInterceptRequest(view, url);
        }
        @Override
        public void onPageFinished(@NonNull final WebView view, final String url) {
            // Prepare and load the javascript
            if (javaScriptClient != null) {
                String javascript = javaScriptClient.getJavaScriptBridge();
                view.loadUrl(javascript);
            } else {
                Log.e("Localytics", "Failed to load JS because JS client is null");
            }
        }

    }
    private class InnerReceiver extends BroadcastReceiver {

        private final String SYSTEM_DIALOG_REASON_KEY = "reason";
        private final String SYSTEM_DIALOG_REASON_RECENT_APPS = "recentapps";
        private final String SYSTEM_DIALOG_REASON_HOME_KEY = "homekey";
        private boolean isAttached = false;

        @Override
        public void onReceive(Context context, Intent intent) {
            String action = intent.getAction();
            if (Intent.ACTION_CLOSE_SYSTEM_DIALOGS.equals(action)) {
                String reason = intent.getStringExtra(SYSTEM_DIALOG_REASON_KEY);
                if (SYSTEM_DIALOG_REASON_HOME_KEY.equals(reason) ||
                        SYSTEM_DIALOG_REASON_RECENT_APPS.equals(reason)) {
                    tagWebViewDismiss();
                }
            }
        }

        void attach(ThemedReactContext reactContext) {
            reactContext.registerReceiver(this, new IntentFilter(Intent.ACTION_CLOSE_SYSTEM_DIALOGS));
            isAttached = true;
        }

        void detach(Context reactContext) {
            if (isAttached) {
                reactContext.unregisterReceiver(homeButtonReceiver);
            }
        }

    }
}
