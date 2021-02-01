package com.localytics.react.android;

import android.location.Location;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.RCTNativeAppEventEmitter;

import com.localytics.androidx.CircularRegion;
import com.localytics.androidx.LocationListener;
import com.localytics.androidx.Region;

import java.util.List;
import java.util.Map;

public class LLLocationListener implements LocationListener {

  private final RCTNativeAppEventEmitter eventEmitter;

  public LLLocationListener(ReactContext reactContext) {
    eventEmitter = reactContext.getJSModule(RCTNativeAppEventEmitter.class);
  }

  @Override
  public void localyticsDidUpdateLocation(Location location) {
    WritableMap params = Arguments.createMap();
    params.putMap("location", LLLocalyticsModule.toWritableMap(location));
    eventEmitter.emit("localyticsDidUpdateLocation", params);
  }

  @Override
  public void localyticsDidTriggerRegions(List<Region> regions, Region.Event event) {
    WritableMap params = Arguments.createMap();
    params.putArray("regions", LLLocalyticsModule.toRegionsWritableArray(regions));
    switch (event) {
      case ENTER:
        params.putString("event", "enter");
        break;
      case EXIT:
        params.putString("event", "exit");
        break;
    }
    eventEmitter.emit("localyticsDidTriggerRegions", params);
  }

  @Override
  public void localyticsDidUpdateMonitoredGeofences(List<CircularRegion> added, List<CircularRegion> removed) {
    WritableMap params = Arguments.createMap();
    params.putArray("added", LLLocalyticsModule.toCircularRegionsWritableArray(added));
    params.putArray("removed", LLLocalyticsModule.toCircularRegionsWritableArray(removed));
    eventEmitter.emit("localyticsDidUpdateMonitoredGeofences", params);
  }
}
