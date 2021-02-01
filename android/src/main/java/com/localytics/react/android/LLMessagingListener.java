package com.localytics.react.android;

import androidx.core.app.NotificationCompat;

import android.app.Notification;
import android.net.Uri;
import android.util.LongSparseArray;
import android.view.View;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactContext;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;

import com.localytics.androidx.InAppCampaign;
import com.localytics.androidx.InAppConfiguration;
import com.localytics.androidx.MessagingListenerV2;
import com.localytics.androidx.PlacesCampaign;
import com.localytics.androidx.PushCampaign;

import java.util.List;

public class LLMessagingListener implements MessagingListenerV2 {

  private final DeviceEventManagerModule.RCTDeviceEventEmitter eventEmitter;
  private final LongSparseArray<InAppCampaign> inAppCampaignCache;
  private final LongSparseArray<PushCampaign> pushCampaignCache;
  private final LongSparseArray<PlacesCampaign> placesCampaignCache;

  private ReadableMap inAppConfig;
  private ReadableMap pushConfig;
  private ReadableMap placesConfig;

  public LLMessagingListener(ReactContext reactContext, LongSparseArray<InAppCampaign> inAppCampaignCache,
                             LongSparseArray<PushCampaign> pushCampaignCache, LongSparseArray<PlacesCampaign> placesCampaignCache) {
    eventEmitter = reactContext.getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class);
    this.inAppCampaignCache = inAppCampaignCache;
    this.pushCampaignCache = pushCampaignCache;
    this.placesCampaignCache = placesCampaignCache;
  }

  public void setInAppConfigurationMap(ReadableMap readableMap) {
    inAppConfig = readableMap;
  }

  public void setPushConfigurationMap(ReadableMap readableMap) {
    pushConfig = readableMap;
  }

  public void setPlacesConfigurationMap(ReadableMap readableMap) {
    placesConfig = readableMap;
  }

  @Override
  public boolean localyticsShouldShowInAppMessage(InAppCampaign campaign) {
    // Cache campaign
    inAppCampaignCache.put(campaign.getCampaignId(), campaign);

    boolean shouldShow = true;
    WritableMap params = Arguments.createMap();
    params.putMap("campaign", LLLocalyticsModule.toWritableMap(campaign));
    if (inAppConfig != null) {

      // Global Suppression
      if (inAppConfig.hasKey("shouldShow")) {
        shouldShow = inAppConfig.getBoolean("shouldShow");
      }

      // DIY In-App. This callback will suppress the in-app and emit an event
      // for manually handling
      if (inAppConfig.hasKey("diy") && inAppConfig.getBoolean("diy")) {
        eventEmitter.emit("localyticsDiyInAppMessage", params);

        return false;
      }
    }

    params.putBoolean("shouldShow", shouldShow);
    eventEmitter.emit("localyticsShouldShowInAppMessage", params);

    return shouldShow;
  }

  @Override
  public InAppConfiguration localyticsWillDisplayInAppMessage(InAppCampaign campaign, InAppConfiguration configuration) {
    if (inAppConfig != null) {
      if (inAppConfig.hasKey("aspectRatio")) {
        configuration.setAspectRatio((float) inAppConfig.getDouble("aspectRatio"));
      }
      if (inAppConfig.hasKey("backgroundAlpha")) {
        configuration.setBackgroundAlpha((float) inAppConfig.getDouble("backgroundAlpha"));
      }
      if (inAppConfig.hasKey("bannerOffsetDps")) {
        configuration.setBannerOffsetDps(inAppConfig.getInt("bannerOffsetDps"));
      }
      if (inAppConfig.hasKey("dismissButtonLocation")) {
        String location = inAppConfig.getString("dismissButtonLocation");
        configuration.setDismissButtonLocation(LLLocalyticsModule.toDismissButtonLocation(location));
      }
      if (inAppConfig.hasKey("dismissButtonHidden")) {
        boolean hidden = inAppConfig.getBoolean("dismissButtonHidden");
        configuration.setDismissButtonVisibility(hidden ? View.GONE : View.VISIBLE);
      }
      if (inAppConfig.hasKey("videoConversionPercentage")) {
        configuration.setVideoConversionPercentage((float) inAppConfig.getDouble("videoConversionPercentage"));
      }
    }

    WritableMap params = Arguments.createMap();
    params.putMap("campaign", LLLocalyticsModule.toWritableMap(campaign));
    eventEmitter.emit("localyticsWillDisplayInAppMessage", params);

    return configuration;
  }

  @Override
  public void localyticsDidDisplayInAppMessage() {
    eventEmitter.emit("localyticsDidDisplayInAppMessage", Arguments.createMap());
  }

  @Override
  public void localyticsWillDismissInAppMessage() {
    eventEmitter.emit("localyticsWillDismissInAppMessage", Arguments.createMap());
  }

  @Override
  public void localyticsDidDismissInAppMessage() {
    eventEmitter.emit("localyticsDidDismissInAppMessage", Arguments.createMap());
  }

  @Override
  public boolean localyticsShouldDelaySessionStartInAppMessages() {
    boolean shouldDelay = false;
    if (inAppConfig != null && inAppConfig.hasKey("delaySessionStart")) {
      shouldDelay = inAppConfig.getBoolean("delaySessionStart");
    }

    WritableMap params = Arguments.createMap();
    params.putBoolean("shouldDelay", shouldDelay);
    eventEmitter.emit("localyticsShouldDelaySessionStartInAppMessages", params);

    return shouldDelay;
  }

  @Override
  public boolean localyticsShouldShowPushNotification(PushCampaign campaign) {
    // Cache campaign
    pushCampaignCache.put(campaign.getCampaignId(), campaign);

    boolean shouldShow = true;
    WritableMap params = Arguments.createMap();
    params.putMap("campaign", LLLocalyticsModule.toWritableMap(campaign));

    if (pushConfig != null) {

      // Global Suppression
      if (pushConfig.hasKey("shouldShow")) {
        shouldShow = pushConfig.getBoolean("shouldShow");
      }

      // DIY Push. This callback will suppress the push and emit an event
      // for manually handling
      if (pushConfig.hasKey("diy") && pushConfig.getBoolean("diy")) {
        eventEmitter.emit("localyticsDiyPushNotification", params);

        return false;
      }
    }

    params.putBoolean("shouldShow", shouldShow);
    eventEmitter.emit("localyticsShouldShowPushNotification", params);

    return shouldShow;
  }

  @Override
  public NotificationCompat.Builder localyticsWillShowPushNotification(NotificationCompat.Builder builder, PushCampaign campaign) {
    if (pushConfig != null) {
      updateNotification(builder, pushConfig);
    }

    WritableMap params = Arguments.createMap();
    params.putMap("campaign", LLLocalyticsModule.toWritableMap(campaign));
    eventEmitter.emit("localyticsWillShowPushNotification", params);

    return builder;
  }

  @Override
  public boolean localyticsShouldShowPlacesPushNotification(PlacesCampaign campaign) {
    // Cache campaign
    placesCampaignCache.put(campaign.getCampaignId(), campaign);

    boolean shouldShow = true;
    WritableMap params = Arguments.createMap();
    params.putMap("campaign", LLLocalyticsModule.toWritableMap(campaign));

    if (placesConfig != null) {

      // Global Suppression
      if (placesConfig.hasKey("shouldShow")) {
        shouldShow = placesConfig.getBoolean("shouldShow");
      }

      // DIY Places. This callback will suppress the places push and emit an event
      // for manually handling
      if (placesConfig.hasKey("diy") && placesConfig.getBoolean("diy")) {
        eventEmitter.emit("localyticsDiyPlacesPushNotification", params);

        return false;
      }
    }

    params.putBoolean("shouldShow", shouldShow);
    eventEmitter.emit("localyticsShouldShowPlacesPushNotification", params);

    return shouldShow;
  }

  @Override
  public NotificationCompat.Builder localyticsWillShowPlacesPushNotification(NotificationCompat.Builder builder, PlacesCampaign campaign) {
    if (placesConfig != null) {
      updateNotification(builder, placesConfig);
    }

    WritableMap params = Arguments.createMap();
    params.putMap("campaign", LLLocalyticsModule.toWritableMap(campaign));
    eventEmitter.emit("localyticsWillShowPlacesPushNotification", params);

    return builder;
  }

  private NotificationCompat.Builder updateNotification(NotificationCompat.Builder builder, ReadableMap config) {
    if (config.hasKey("category")) {
      builder.setCategory(config.getString("category"));
    }
    if (config.hasKey("color")) {
      builder.setColor(config.getInt("color"));
    }
    if (config.hasKey("contentInfo")) {
      builder.setContentInfo(config.getString("contentInfo"));
    }
    if (config.hasKey("contentTitle")) {
      builder.setContentTitle(config.getString("contentTitle"));
    }
    if (config.hasKey("defaults")) {
      ReadableArray defaultsArray = config.getArray("defaults");
      List<String> defaultsList = LLLocalyticsModule.toStringList(defaultsArray);
      if (defaultsList.contains("all")) {
        builder.setDefaults(Notification.DEFAULT_ALL);
      } else {
        int defaults = 0;
        if (defaultsList.contains("lights")) {
          defaults |= Notification.DEFAULT_LIGHTS;
        }
        if (defaultsList.contains("sound")) {
          defaults |= Notification.DEFAULT_SOUND;
        }
        if (defaultsList.contains("vibrate")) {
          defaults |= Notification.DEFAULT_VIBRATE;
        }
        builder.setDefaults(defaults);
      }
    }
    if (config.hasKey("priority")) {
      builder.setPriority(config.getInt("priority"));
    }
    if (config.hasKey("sound")) {
      builder.setSound(Uri.parse(config.getString("sound")));
    }
    if (config.hasKey("vibrate")) {
      ReadableArray vibrateArray = config.getArray("vibrate");
      int size = vibrateArray.size();
      long[] vibrate = new long[size];
      for (int i = 0; i < size; i++) {
        vibrate[i] = (long) vibrateArray.getInt(i);
      }
      builder.setVibrate(vibrate);
    }

    return builder;
  }
}
