package com.localytics.react.android;

import android.content.Intent;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.RCTNativeAppEventEmitter;

import com.localytics.androidx.CallToActionListenerV2;
import com.localytics.androidx.Campaign;

public class LLCallToActionListener implements CallToActionListenerV2 {

  private final RCTNativeAppEventEmitter eventEmitter;

  public LLCallToActionListener(ReactContext reactContext) {
    eventEmitter = reactContext.getJSModule(RCTNativeAppEventEmitter.class);
  }

  @Override
  public boolean localyticsShouldDeeplink(String url, Campaign campaign) {
    WritableMap params = Arguments.createMap();
    params.putString("url", url);
    params.putMap("campaign", LLLocalyticsModule.toWritableMap(campaign));
    eventEmitter.emit("localyticsShouldDeeplink", params);
    return true;
  }
 
  @Override
  public void localyticsDidOptOut(boolean optOut, Campaign campaign) {
    WritableMap params = Arguments.createMap();
    params.putBoolean("optedOut", optOut);
    params.putMap("campaign", LLLocalyticsModule.toWritableMap(campaign));
    eventEmitter.emit("localyticsDidOptOut", params);
  }
 
  @Override
  public void localyticsDidPrivacyOptOut(boolean optOut, Campaign campaign) {
    WritableMap params = Arguments.createMap();
    params.putBoolean("privacyOptedOut", optOut);
    params.putMap("campaign", LLLocalyticsModule.toWritableMap(campaign));
    eventEmitter.emit("localyticsDidPrivacyOptOut", params);
  }
 
  @Override
  public boolean localyticsShouldPromptForLocationPermissions(Campaign campaign) {
    WritableMap params = Arguments.createMap();
    params.putMap("campaign", LLLocalyticsModule.toWritableMap(campaign));
    eventEmitter.emit("localyticsShouldPromptForLocationPermissions", params);
    return true;
  }

   @Override
    public boolean localyticsShouldDeeplinkToSettings(Intent intent, Campaign campaign) {
      WritableMap params = Arguments.createMap();
      params.putMap("campaign", LLLocalyticsModule.toWritableMap(campaign));
      eventEmitter.emit("localyticsShouldDeeplinkToSettings", params);
      return true;
    }

}
