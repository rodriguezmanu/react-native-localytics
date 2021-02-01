package com.localytics.react.android;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.RCTNativeAppEventEmitter;

import com.localytics.androidx.AnalyticsListener;

import java.util.Map;

public class LLAnalyticsListener implements AnalyticsListener {

  private final RCTNativeAppEventEmitter eventEmitter;

  public LLAnalyticsListener(ReactContext reactContext) {
    eventEmitter = reactContext.getJSModule(RCTNativeAppEventEmitter.class);
  }

  @Override
  public void localyticsSessionWillOpen(boolean isFirst, boolean isUpgrade, boolean isResume) {
    WritableMap params = Arguments.createMap();
    params.putBoolean("isFirst", isFirst);
    params.putBoolean("isUpgrade", isUpgrade);
    params.putBoolean("isResume", isResume);
    eventEmitter.emit("localyticsSessionWillOpen", params);
  }

  @Override
  public void localyticsSessionDidOpen(boolean isFirst, boolean isUpgrade, boolean isResume) {
    WritableMap params = Arguments.createMap();
    params.putBoolean("isFirst", isFirst);
    params.putBoolean("isUpgrade", isUpgrade);
    params.putBoolean("isResume", isResume);
    eventEmitter.emit("localyticsSessionDidOpen", params);
  }

  @Override
  public void localyticsSessionWillClose() {
    eventEmitter.emit("localyticsSessionWillClose", null);
  }

  @Override
  public void localyticsDidTagEvent(String eventName, Map<String, String> attributes, long customerValueIncrease) {
    WritableMap params = Arguments.createMap();
    params.putString("name", eventName);
    params.putMap("attributes", LLLocalyticsModule.toWritableMap(attributes));
    params.putInt("customerValueIncrease", (int) customerValueIncrease);
    eventEmitter.emit("localyticsDidTagEvent", params);
  }
}
