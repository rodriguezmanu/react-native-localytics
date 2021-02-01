package com.localytics.react.android;

import android.app.Activity;
import android.location.Location;
import android.net.Uri;
import android.os.Build;
import android.os.HandlerThread;
import android.os.Handler;
import android.text.TextUtils;
import android.util.Log;
import android.util.LongSparseArray;
import android.view.View;

import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.Dynamic;
import com.facebook.react.bridge.ReadableArray;
import com.facebook.react.bridge.ReadableMap;
import com.facebook.react.bridge.ReadableMapKeySetIterator;
import com.facebook.react.bridge.ReadableType;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;

import com.facebook.react.uimanager.annotations.ReactProp;
import com.localytics.androidx.CircularRegion;
import com.localytics.androidx.Customer;
import com.localytics.androidx.Campaign;
import com.localytics.androidx.InAppCampaign;
import com.localytics.androidx.InboxCampaign;
import com.localytics.androidx.InboxRefreshListener;
import com.localytics.androidx.Localytics;
import com.localytics.androidx.PlacesCampaign;
import com.localytics.androidx.PushCampaign;
import com.localytics.androidx.Region;

import java.lang.Runnable;
import java.util.ArrayList;
import java.util.HashMap;
import java.util.List;
import java.util.Map;
import java.io.File;  // Import the File class

public class LLLocalyticsModule extends ReactContextBaseJavaModule {

  private final ReactApplicationContext reactContext;
  private final Handler resolveHandler;
  public Handler localyticsHandler;

  private LongSparseArray<InboxCampaign> inboxCampaignCache = new LongSparseArray<>();
  private final LongSparseArray<InAppCampaign> inAppCampaignCache = new LongSparseArray<>();
  private final LongSparseArray<PushCampaign> pushCampaignCache = new LongSparseArray<>();
  private final LongSparseArray<PlacesCampaign> placesCampaignCache = new LongSparseArray<>();

  private LLAnalyticsListener analyticsListener;
  private LLLocationListener locationListener;
  private LLCallToActionListener ctaListener;
  private LLMessagingListener messagingListener;

  private static final String E_INVALID_ARGUMENT = "E_INVALID_ARGUMENT";

  public LLLocalyticsModule(ReactApplicationContext reactContext) {
    super(reactContext);
    this.reactContext = reactContext;
    HandlerThread resolutionThread = new HandlerThread("LLLocalyticsModule-Resolution-Handler", android.os.Process.THREAD_PRIORITY_BACKGROUND);
    resolutionThread.start();
    resolveHandler = new Handler(resolutionThread.getLooper());
    HandlerThread localyticsThread = new HandlerThread("LLLocalyticsModule-Background-Handler", android.os.Process.THREAD_PRIORITY_BACKGROUND);
    localyticsThread.start();
    localyticsHandler = new Handler(localyticsThread.getLooper());
  }

  public Activity getActivity() {
    return super.getCurrentActivity();
  }

  @Override
  public String getName() {
    return "LLLocalytics";
  }

  /************************************
   * Integration
   ************************************/

  @ReactMethod
  public void upload() {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.upload();
      }
    });
  }

  @ReactMethod
  public void openSession() {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.openSession();
      }
    });
  }

  @ReactMethod
  public void closeSession() {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.closeSession();
      }
    });

  }

  @ReactMethod
  public void pauseDataUploading(final Boolean paused) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.pauseDataUploading(paused);
      }
    });
  }

  /************************************
   * Analytics
   ************************************/

  @ReactMethod
  public void setOptedOut(final Boolean optedOut) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setOptedOut(optedOut);
      }
    });
  }

  @ReactMethod
  public void isOptedOut(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.isOptedOut());
          }
        });
      }
    });

  }

  @ReactMethod
  public void setPrivacyOptedOut(final Boolean optedOut) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setPrivacyOptedOut(optedOut);
      }
    });
  }

  @ReactMethod
  public void isPrivacyOptedOut(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.isPrivacyOptedOut());
          }
        });
      }
    });
  }

  @ReactMethod
  public void tagEvent(final ReadableMap params) {
    final String name = getString(params, "name");
    if (TextUtils.isEmpty(name)) {
      logNullParameterError("tagEvent", "name", name);
      return;
    }
    final int clv = getInt(params, "customerValueIncrease");
    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));

    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagEvent(name, attributes, clv);
      }
    });
  }

  @ReactMethod
  public void tagPurchased(final ReadableMap params) {
    final String itemName = getString(params, "itemName");
    final String itemId = getString(params, "itemId");
    final String itemType = getString(params, "itemType");
    final Long itemPrice = getLong(params, "itemPrice");

    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagPurchased(itemName, itemId, itemType, itemPrice, attributes);
      }
    });
  }

  @ReactMethod
  public void tagAddedToCart(final ReadableMap params) {
    final String itemName = getString(params, "itemName");
    final String itemId = getString(params, "itemId");
    final String itemType = getString(params, "itemType");
    final Long itemPrice = getLong(params, "itemPrice");

    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagAddedToCart(itemName, itemId, itemType, itemPrice, attributes);
      }
    });
  }

  @ReactMethod
  public void tagStartedCheckout(final ReadableMap params) {
    final Long totalPrice = getLong(params, "totalPrice");
    final Long itemCount = getLong(params, "itemCount");

    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagStartedCheckout(totalPrice, itemCount, attributes);
      }
    });
  }

  @ReactMethod
  public void tagCompletedCheckout(final ReadableMap params) {
    final Long totalPrice = getLong(params, "totalPrice");
    final Long itemCount = getLong(params, "itemCount");

    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagCompletedCheckout(totalPrice, itemCount, attributes);
      }
    });
  }

  @ReactMethod
  public void tagContentViewed(final ReadableMap params) {
    final String contentName = getString(params, "contentName");
    final String contentId = getString(params, "contentId");
    final String contentType = getString(params, "contentType");
    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagContentViewed(contentName, contentId, contentType, attributes);      }
    });
  }

  @ReactMethod
  public void tagSearched(final ReadableMap params) {
    final String queryText = getString(params, "queryText");
    final String contentType = getString(params, "contentType");
    final Long resultCount = getLong(params, "resultCount");

    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagSearched(queryText, contentType, resultCount, attributes);      }
    });
  }

  @ReactMethod
  public void tagShared(final ReadableMap params) {
    final String contentName = getString(params, "contentName");
    final String contentId = getString(params, "contentId");
    final String contentType = getString(params, "contentType");
    final String methodName = getString(params, "methodName");
    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagShared(contentName, contentId, contentType, methodName, attributes);      }
    });
  }

  @ReactMethod
  public void tagContentRated(final ReadableMap params) {
    final String contentName = getString(params, "contentName");
    final String contentId = getString(params, "contentId");
    final String contentType = getString(params, "contentType");
    final Long rating = getLong(params, "rating");

    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagContentRated(contentName, contentId, contentType, rating, attributes);
      }
    });

  }

  @ReactMethod
  public void tagCustomerRegistered(final ReadableMap params) {
    final Customer customer = params.hasKey("customer") ? toCustomer(params.getMap("customer")) : null;

    final String methodName = getString(params, "methodName");
    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagCustomerRegistered(customer, methodName, attributes);
      }
    });
  }

  @ReactMethod
  public void tagCustomerLoggedIn(final ReadableMap params) {
    final Customer customer = params.hasKey("customer") ? toCustomer(params.getMap("customer")) : null;
    final String methodName = getString(params, "methodName");
    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagCustomerLoggedIn(customer, methodName, attributes);
      }
    });
  }

  @ReactMethod
  public void tagCustomerLoggedOut(final ReadableMap attributes) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagCustomerLoggedOut(toStringMap(attributes));
      }
    });

  }

  @ReactMethod
  public void tagInvited(final ReadableMap params) {
    final String methodName = getString(params, "methodName");
    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagInvited(methodName, attributes);
      }
    });

  }

  @ReactMethod
  public void tagInboxImpression(final ReadableMap params) {
    final String action = getString(params, "action");
    final long campaignId = getLong(params, "campaignId");
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        InboxCampaign campaign = inboxCampaignCache.get(campaignId);
        if (campaign != null) {
          if ("click".equalsIgnoreCase(action)) {
            Localytics.tagInboxImpression(campaign, Localytics.ImpressionType.CLICK);
          } else if ("dismiss".equalsIgnoreCase(action)) {
            Localytics.tagInboxImpression(campaign, Localytics.ImpressionType.DISMISS);
          } else if (!TextUtils.isEmpty(action)) {
            Localytics.tagInboxImpression(campaign, action);
          } else {
            logNullParameterError("tagInboxImpression", "action", action);
          }
        } else {
          logInvalidParameterError("tagInboxImpression", "campaignId", "Unable to find campaign by id", Long.toString(campaignId));
        }
      }
    });
  }

  @ReactMethod
  public void inboxListItemTapped(final ReadableMap params) {
    final long campaignId = getLong(params, "campaignId");
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        InboxCampaign campaign = inboxCampaignCache.get(campaignId);
        if (campaign != null) {
          Localytics.inboxListItemTapped(campaign);
        } else {
          logInvalidParameterError("inboxListItemTapped", "campaignId", "Unable to find campaign by id", Long.toString(campaignId));
        }
      }
    });
  }

  @ReactMethod
  public void tagPushToInboxImpression(final ReadableMap params) {
    final long campaignId = getLong(params, "campaignId");
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        InboxCampaign campaign = inboxCampaignCache.get(campaignId);
        if (campaign != null) {
          Localytics.tagPushToInboxImpression(campaign);
        } else {
          logInvalidParameterError("tagPushToInboxImpression", "campaignId", "Unable to find campaign by id", Long.toString(campaignId));
        }
      }
    });
  }

  @ReactMethod
  public void tagInAppImpression(final ReadableMap params) {
    final long campaignId = getLong(params, "campaignId");
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        InAppCampaign campaign = inAppCampaignCache.get(campaignId);
        if (campaign != null) {
          String action = getString(params, "action");
          if ("click".equalsIgnoreCase(action)) {
            Localytics.tagInAppImpression(campaign, Localytics.ImpressionType.CLICK);
          } else if ("dismiss".equalsIgnoreCase(action)) {
            Localytics.tagInAppImpression(campaign, Localytics.ImpressionType.DISMISS);
          } else if (!TextUtils.isEmpty((action))) {
            Localytics.tagInAppImpression(campaign, action);
          } else {
            logNullParameterError("tagInAppImpression", "action", action);
          }
        } else {
          logInvalidParameterError("tagInAppImpression", "campaignId", "Unable to find campaign by id", Long.toString(campaignId));
        }
      }
    });
  }

  @ReactMethod
  public void tagPlacesPushReceived(final long campaignId) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        PlacesCampaign campaign = placesCampaignCache.get(campaignId);
        if (campaign != null) {
          Localytics.tagPlacesPushReceived(campaign);
        } else {
          logInvalidParameterError("tagPlacesPushReceived", "campaignId", "Unable to find campaign by id", Long.toString(campaignId));
        }
      }
    });
  }

  @ReactMethod
  public void tagPlacesPushOpened(final ReadableMap params) {
    final long campaignId = getLong(params, "campaignId");
    final String action = getString(params, "action");
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        PlacesCampaign campaign = placesCampaignCache.get(campaignId);
        if (campaign != null) {
          Localytics.tagPlacesPushOpened(campaign, action);
        } else {
          logInvalidParameterError("tagPlacesPushOpened", "campaignId", "Unable to find campaign by id", Long.toString(campaignId));
        }
      }
    });
  }

  @ReactMethod
  public void tagScreen(final String screen) {
    if (TextUtils.isEmpty(screen)) {
      logInvalidParameterError("tagScreen", "screen", "Parameter screen can not be empty", screen);
      return;
    }
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.tagScreen(screen);
      }
    });
  }

  @ReactMethod
  public void setCustomDimension(final ReadableMap params) {
    final int dimension = getCustomDimensionIndex(params, "dimension");
    final String value = getString(params, "value");
    if (0 <= dimension && dimension <= 19) {
      localyticsHandler.post(new Runnable() {
        @Override
        public void run() {
          Localytics.setCustomDimension(dimension, value);
        }
      });
    } else {
      logInvalidParameterError("setCustomDimension", "dimension", "Custom dimension index must be between 0 and 19", Integer.toString(dimension));
    }

  }

  @ReactMethod
  public void getCustomDimension(final int dimension, final Promise promise) {
    if (0 <= dimension && dimension <= 19) {
      localyticsHandler.post(new Runnable() {
        @Override
        public void run() {
          resolveHandler.post(new Runnable() {
            @Override
            public void run() {
              promise.resolve(Localytics.getCustomDimension(dimension));
            }
          });
        }
      });
    } else {
      logInvalidParameterError("getCustomDimension", "dimension", "Custom dimension index must be between 0 and 19", Integer.toString(dimension));
    }
  }

  @ReactMethod
  public void setAnalyticsEventsEnabled(final Boolean enabled) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        if (enabled) {
          if (analyticsListener == null) {
            analyticsListener = new LLAnalyticsListener(reactContext);
          }
          Localytics.setAnalyticsListener(analyticsListener);
        } else {
          Localytics.setAnalyticsListener(null);
        }
      }
    });
  }

  /************************************
   * Profiles
   ************************************/

  @ReactMethod
  public void setProfileAttribute(final ReadableMap params) {
    final String name = getString(params, "name");
    final Dynamic value = getDynamic(params, "value");
    final String scope = getString(params, "scope");
    if (!TextUtils.isEmpty(name) && value != null) {
      localyticsHandler.post(new Runnable() {
        @Override
        public void run() {
          switch(value.getType()) {
            case String:
              // Dates will be passed in as "YYYY-MM-DD"
              Localytics.setProfileAttribute(name, value.asString(), toScope(scope));
              break;
            case Number:
              Localytics.setProfileAttribute(name, (long) value.asInt(), toScope(scope));
              break;
            case Array:
              ReadableArray array = value.asArray();
              if (array.size() > 0) {
                for (int i = 0; i < array.size(); i++) { // for-each loop not available with ReadableArray
                  ReadableType type = array.getType(i);
                  if (!ReadableType.Number.equals(type)) { // default to String
                    Localytics.setProfileAttribute(name, toStringArray(array), toScope(scope));
                    return;
                  }
                }
                Localytics.setProfileAttribute(name, toLongArray(array), toScope(scope));
              } else {
                logNullParameterError("setProfileAttribute", "value", array.toString());
              }
              break;
          }
        }
      });
    } else {
      logNullParameterError("setProfileAttribute", "name, value", String.format("name: %s, value: %s", name, value));
    }
   }

  @ReactMethod
  public void addProfileAttributesToSet(final ReadableMap params) {
    final String name = getString(params, "name");
    final ReadableArray values = getReadableArray(params, "values");
    final String scope = getString(params, "scope");
    if (!TextUtils.isEmpty(name) && values != null) {
      localyticsHandler.post(new Runnable() {
        @Override
        public void run() {
          if (values.size() > 0) {
            for (int i = 0; i < values.size(); i++) { // for-each loop not available with ReadableArray
              ReadableType type = values.getType(i);
              if (!ReadableType.Number.equals(type)) { // default to String
                Localytics.setProfileAttribute(name, toStringArray(values), toScope(scope));
                return;
              }
            }
            Localytics.setProfileAttribute(name, toLongArray(values), toScope(scope));
          } else {
            logNullParameterError("addProfileAttributesToSet", "values", values.toString());
          }
        }
      });
    } else {
      logNullParameterError("addProfileAttributesToSet", "name, values", String.format("name: %s, values: %s", name, values));
    }
  }

  @ReactMethod
  public void removeProfileAttributesFromSet(final ReadableMap params) {
    final String name = getString(params, "name");
    final ReadableArray values = getReadableArray(params, "values");
    final String scope = getString(params, "scope");
    if (!TextUtils.isEmpty(name) && values != null) {
      localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
          if (values.size() > 0) {
            for (int i = 0; i < values.size(); i++) { // for-each loop not available with ReadableArray
              ReadableType type = values.getType(i);
              if (!ReadableType.Number.equals(type)) { // default to String
                Localytics.removeProfileAttributesFromSet(name, toStringArray(values), toScope(scope));
                return;
              }
            }
            Localytics.removeProfileAttributesFromSet(name, toLongArray(values), toScope(scope));
          } else {
            logNullParameterError("removeProfileAttributesFromSet", "values", values.toString());
          }
        }
      });
    } else {
      logNullParameterError("removeProfileAttributesFromSet", "name, values", String.format("name: %s, values: %s", name, values));
    }
  }

  @ReactMethod
  public void incrementProfileAttribute(final ReadableMap params) {
    final String name = getString(params, "name");
    final int value = getInt(params, "value");
    final String scope = getString(params, "scope");
    if (!TextUtils.isEmpty(name)) {
      if (value != 0) {
          localyticsHandler.post(new Runnable() {
            @Override
            public void run() {
              Localytics.incrementProfileAttribute(name, value, toScope(scope));
            }
          });
      } else {
        logInvalidParameterError("incrementProfileAttribute", "value", "Attempting to increment by 0", Integer.toString(value));
      }
    } else {
      logNullParameterError("incrementProfileAttribute", "name", name);
    }
  }

  @ReactMethod
  public void decrementProfileAttribute(final ReadableMap params) {
    final String name = getString(params, "name");
    final int value = getInt(params, "value");
    final String scope = getString(params, "scope");
    if (!TextUtils.isEmpty(name)) {
      if (value != 0) {
        localyticsHandler.post(new Runnable() {
          @Override
          public void run() {
            Localytics.decrementProfileAttribute(name, value, toScope(scope));
          }
        });
      } else {
        logInvalidParameterError("decrementProfileAttribute", "value", "Attempting to decrement by 0", Integer.toString(value));
      }
    } else {
      logNullParameterError("decrementProfileAttribute", "name", name);
    }
  }

  @ReactMethod
  public void deleteProfileAttribute(final ReadableMap params) {
    final String name = getString(params, "name");
    final String scope = getString(params, "scope");
    if (!TextUtils.isEmpty(name)) {
      localyticsHandler.post(new Runnable() {
        @Override
        public void run() {
          Localytics.deleteProfileAttribute(name, toScope(scope));
        }
      });
    } else {
      logNullParameterError("deleteProfileAttribute", "name", name);
    }
  }

  @ReactMethod
  public void setCustomerEmail(final String email) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setCustomerEmail(email);
      }
    });
  }

  @ReactMethod
  public void setCustomerFirstName(final String firstName) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setCustomerFirstName(firstName);
      }
    });
  }

  @ReactMethod
  public void setCustomerLastName(final String lastName) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setCustomerLastName(lastName);
      }
    });
  }

  @ReactMethod
  public void setCustomerFullName(final String fullName) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setCustomerFullName(fullName);
      }
    });
  }

  /************************************
   * Messaging
   ************************************/

  @ReactMethod
  public void triggerInAppMessage(final ReadableMap params) {
    final String triggerName = getString(params, "triggerName");
    final Map<String, String> attributes = toStringMap(getReadableMap(params, "attributes"));
    if (!TextUtils.isEmpty(triggerName)) {
      localyticsHandler.post(new Runnable() {
        @Override
        public void run() {
          if (attributes != null) {
            Localytics.triggerInAppMessage(triggerName, attributes);
          } else {
            Localytics.triggerInAppMessage(triggerName);
          }
        }
      });
    } else {
      logNullParameterError("triggerInAppMessage", "triggerName", triggerName);
    }
  }

  @ReactMethod
  public void triggerInAppMessagesForSessionStart() {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.triggerInAppMessagesForSessionStart();
      }
    });

  }

  @ReactMethod
  public void dismissCurrentInAppMessage() {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.dismissCurrentInAppMessage();
      }
    });
  }

  @ReactMethod
  public void forceInAppMessage(final ReadableMap params) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        String campaignId = getString(params, "campaignId");
        String creativeId = getString(params, "creativeId");
        String localFilePath = getString(params, "localFilePath");
        if (!TextUtils.isEmpty(localFilePath)) {
          Localytics.forceInAppMessage(new File(localFilePath));
        } else if (!TextUtils.isEmpty(campaignId) && !TextUtils.isEmpty(creativeId)) {
          Localytics.forceInAppMessage(campaignId, creativeId);
        }

      }
    });
  }

  @ReactMethod
  public void setInAppMessageDismissButtonLocation(final String location) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setInAppMessageDismissButtonLocation(toDismissButtonLocation(location));
      }
    });
  }

  @ReactMethod
  public void getInAppMessageDismissButtonLocation(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        final Localytics.InAppMessageDismissButtonLocation location = Localytics.getInAppMessageDismissButtonLocation();
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            if (Localytics.InAppMessageDismissButtonLocation.RIGHT.equals(location)) {
              promise.resolve("right");
            } else {
              promise.resolve("left");
            }
          }
        });
      }
    });

  }

  @ReactMethod
  public void setInAppMessageDismissButtonHidden(final Boolean hidden) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setInAppMessageDismissButtonVisibility(hidden ? View.GONE : View.VISIBLE);
      }
    });
  }

  @ReactMethod
  public void setInAppMessageConfiguration(final ReadableMap config) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        getMessagingListener(true).setInAppConfigurationMap(config);
      }
    });
  }

  @ReactMethod
  public void appendAdidToInAppUrls(final Boolean append) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.appendAdidToInAppUrls(append);
      }
    });

  }

  @ReactMethod void isAdidAppendedToInAppUrls(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.isAdidAppendedToInAppUrls());
          }
        });
      }
    });
  }

  @ReactMethod
  public void registerPush() {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.registerPush();
      }
    });

  }

  @ReactMethod
  public void setPushRegistrationId(final String registrationId) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setPushRegistrationId(registrationId);
      }
    });
  }

  @ReactMethod
  public void getPushRegistrationId(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.getPushRegistrationId());
          }
        });
      }
    });
  }

  @ReactMethod
  public void setNotificationsDisabled(final Boolean disabled) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setNotificationsDisabled(disabled);
      }
    });
  }

  @ReactMethod
  public void areNotificationsDisabled(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.areNotificationsDisabled());
          }
        });
      }
    });
  }

  @ReactMethod
  public void setPushMessageConfiguration(final ReadableMap config) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        // Enable messaging events first
        getMessagingListener(true).setPushConfigurationMap(config);
      }
    });
  }

  @ReactMethod
  public void getDisplayableInboxCampaigns(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            List<InboxCampaign> campaigns = Localytics.getDisplayableInboxCampaigns();

            // Cache campaigns
            for (InboxCampaign campaign : campaigns) {
              inboxCampaignCache.put(campaign.getCampaignId(), campaign);
            }

            promise.resolve(toInboxCampaignsWritableArray(campaigns));
          }
        });
      }
    });
  }

  @ReactMethod
  public void getAllInboxCampaigns(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            List<InboxCampaign> campaigns = Localytics.getAllInboxCampaigns();
            LongSparseArray<InboxCampaign> cache = new LongSparseArray<>();

            // Cache campaigns
            for (InboxCampaign campaign : campaigns) {
              cache.put(campaign.getCampaignId(), campaign);
            }

            //Set new inbox cache
            inboxCampaignCache = cache;
            promise.resolve(toInboxCampaignsWritableArray(campaigns));
          }
        });
      }
    });
  }

  @ReactMethod
  public void refreshInboxCampaigns(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.refreshInboxCampaigns(new InboxRefreshListener() {
          @Override
          public void localyticsRefreshedInboxCampaigns(List<InboxCampaign> campaigns) {
            // Cache campaigns
            for (InboxCampaign campaign : campaigns) {
              inboxCampaignCache.put(campaign.getCampaignId(), campaign);
            }

            promise.resolve(toInboxCampaignsWritableArray(campaigns));
          }
        });
      }
    });
  }

  @ReactMethod
  public void refreshAllInboxCampaigns(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.refreshAllInboxCampaigns(new InboxRefreshListener() {
          @Override
          public void localyticsRefreshedInboxCampaigns(List<InboxCampaign> campaigns) {
            LongSparseArray<InboxCampaign> cache = new LongSparseArray<>();

            // Cache campaigns
            for (InboxCampaign campaign : campaigns) {
              cache.put(campaign.getCampaignId(), campaign);
            }

            //Set new inbox cache
            inboxCampaignCache = cache;
            promise.resolve(toInboxCampaignsWritableArray(campaigns));
          }
        });
      }
    });
  }

  @ReactMethod
  public void setInboxCampaignRead(final ReadableMap params) {
    final long campaignId = getLong(params, "campaignId");
    final boolean read = getBoolean(params, "read");
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        InboxCampaign campaign = inboxCampaignCache.get(campaignId);
        if (campaign != null) {
          Localytics.setInboxCampaignRead(campaign, read);
        } else {
          logInvalidParameterError("setInboxCampaignRead", "campaignId", "Unable to find campaign by id", Long.toString(campaignId));
        }
      }
    });
  }

  @ReactMethod
  public void deleteInboxCampaign(final Integer campaignId) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        InboxCampaign campaign = inboxCampaignCache.get(campaignId);
        if (campaign != null) {
          Localytics.deleteInboxCampaign(campaign);
        } else {
          logInvalidParameterError("deleteInboxCampaign", "campaignId", "Unable to find campaign by id", Long.toString(campaignId));
        }
      }
    });
  }

  @ReactMethod
  public void getInboxCampaignsUnreadCount(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.getInboxCampaignsUnreadCount());
          }
        });
      }
    });
  }

  @ReactMethod
  public void appendAdidToInboxUrls(final Boolean append) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.appendAdidToInboxUrls(append);
      }
    });
  }

  @ReactMethod void isAdidAppendedToInboxUrls(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.isAdidAppendedToInboxUrls());
          }
        });
      }
    });
  }

  @ReactMethod
  public void triggerPlacesNotification(final ReadableMap params) {
    final long campaignId = getLong(params, "campaignId");
    final String regionId = getString(params, "regionId");
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        if (TextUtils.isEmpty(regionId)) {
          PlacesCampaign campaign = placesCampaignCache.get(campaignId);
          if (campaign != null) {
            Localytics.triggerPlacesNotification(campaign);
          } else {
            logInvalidParameterError("triggerPlacesNotification", "campaignId", "Unable to find campaign by id", Long.toString(campaignId));
          }
        } else {
          Localytics.triggerPlacesNotification(campaignId, regionId);
        }
      }
    });
  }

  @ReactMethod
  public void setPlacesMessageConfiguration(final ReadableMap config) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        getMessagingListener(true).setPlacesConfigurationMap(config);
      }
    });
  }

  @ReactMethod
  public void setMessagingEventsEnabled(final Boolean enabled) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        if (enabled) {
          if (messagingListener == null) {
            messagingListener = new LLMessagingListener(reactContext, inAppCampaignCache, pushCampaignCache, placesCampaignCache);
          }
          Localytics.setMessagingListener(messagingListener);
        } else {
          Localytics.setMessagingListener(null);
        }
      }
    });
  }

  private LLMessagingListener getMessagingListener(final Boolean eventsEnabled) {
    if (messagingListener == null) {
      messagingListener = new LLMessagingListener(reactContext, inAppCampaignCache, pushCampaignCache, placesCampaignCache);
    }
    if (eventsEnabled) {
      Localytics.setMessagingListener(messagingListener);
    } else {
      Localytics.setMessagingListener(null);
    }

    return messagingListener;
  }

  /************************************
   * Location
   ************************************/

  @ReactMethod
  public void setLocationMonitoringEnabled(final Boolean enabled) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setLocationMonitoringEnabled(enabled, false);
      }
    });
  }

  @ReactMethod
  public void persistLocationMonitoring(final Boolean persist) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setLocationMonitoringEnabled(true, persist);
      }
    });
  }

  @ReactMethod
  public void getGeofencesToMonitor(final ReadableMap params, final Promise promise) {
    final Double latitude = getLatitude(params, "latitude");
    final Double longitude = getLongitude(params, "longitude");
    if (latitude != null && longitude != null) {
      localyticsHandler.post(new Runnable() {
        @Override
        public void run() {
          resolveHandler.post(new Runnable() {
            @Override
            public void run() {
              List<CircularRegion> regions = Localytics.getGeofencesToMonitor(latitude, longitude);
              promise.resolve(toCircularRegionsWritableArray(regions));
            }
          });
        }
      });
    } else {
      logInvalidParameterError("getGeofencesToMonitor", "latitude, longitude", "Invalid coordinates provided", String.format("latitude: %s, longitude: %s", latitude, longitude));
    }
  }

  @ReactMethod
  public void triggerRegion(final ReadableMap params) {
    final ReadableMap region = getReadableMap(params, "region");
    final String event = getString(params, "event");

    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        if (params.hasKey("location")) {
          ReadableMap locationMap = getReadableMap(params, "location");
          Location location = toLocation(locationMap);
          if (location != null) {
            Localytics.triggerRegion(toRegion(region), toEvent(event), location);
            return;
          } else {
            logInvalidParameterError("triggerRegion (with location)", "location", "Invalid location was provided. triggerRegion was called with a null location", locationMap.toString());
          }
        }
        Localytics.triggerRegion(toRegion(region), toEvent(event), null);
      }
    });
  }

  @ReactMethod
  public void triggerRegions(final ReadableMap params) {
    final ReadableArray regions = getReadableArray(params, "regions");
    final String event = getString(params, "event");

    if (params.hasKey("location")) {
      final ReadableMap locationMap = getReadableMap(params, "location");
      final Location location = toLocation(locationMap);
      localyticsHandler.post(new Runnable() {
        @Override
        public void run() {
          if (location != null) {
            Localytics.triggerRegions(toRegions(regions), toEvent(event), location);
          } else {
            logInvalidParameterError("triggerRegions (with location)", "location", "Invalid location was provided. triggerRegions was called with a null location", locationMap.toString());
          }
        }
      });
    } else {
      Localytics.triggerRegions(toRegions(regions), toEvent(event), null);
    }
  }

  @ReactMethod
  public void setLocationEventsEnabled(final Boolean enabled) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        if (enabled) {
          if (locationListener == null) {
            locationListener = new LLLocationListener(reactContext);
          }
          Localytics.setLocationListener(locationListener);
        } else {
          Localytics.setLocationListener(null);
        }
      }
    });
  }

  @ReactMethod
  public void setCallToActionEventsEnabled(final Boolean enabled) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        if (enabled) {
          if (ctaListener == null) {
            ctaListener = new LLCallToActionListener(reactContext);
          }
          Localytics.setCallToActionListener(ctaListener);
        } else {
          Localytics.setCallToActionListener(null);
        }
      }
    });
  }

  // These methods match iOS, and are no-ops
  @ReactMethod
  public void requestAdvertisingIdentifierPrompt() {}

  @ReactMethod
  public void getAdvertisingIdentifierStatus(final Promise promise) {
    promise.resolve(1);
  }

  /************************************
   * User Information
   ************************************/

  @ReactMethod
  public void setIdentifier(final ReadableMap params) {
    final String identifier = getString(params, "identifier");
    if (!TextUtils.isEmpty(identifier)) {
      final String value = getString(params, "value");
      localyticsHandler.post(new Runnable() {
        @Override
        public void run() {
          Localytics.setIdentifier(identifier, value);
        }
      });
    }
  }

  @ReactMethod
  public void getIdentifier(final String identifier, final Promise promise) {
    // Check the validity of the argument and reject it
    if (TextUtils.isEmpty(identifier)) {
      resolveHandler.post(new Runnable() {
        @Override
        public void run() {
          promise.reject(E_INVALID_ARGUMENT, "getIdentifier: null or empty identifier provided");
        }
      });
      return;
    }
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        if (!TextUtils.isEmpty(identifier)) {
          resolveHandler.post(new Runnable() {
            @Override
            public void run() {
              promise.resolve(Localytics.getIdentifier(identifier));
            }
          });
        }
      }
    });
  }

  @ReactMethod
  public void setCustomerId(final String customerId) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setCustomerId(customerId);
      }
    });
  }

  @ReactMethod
  public void setCustomerIdWithPrivacyOptedOut(final String customerId, final Boolean optedOut) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setCustomerIdWithPrivacyOptedOut(customerId, optedOut);
      }
    });
  }

  @ReactMethod
  public void getCustomerId(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.getCustomerId());
          }
        });
      }
    });
  }

  @ReactMethod
  public void setLocation(final ReadableMap locationMap) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setLocation(toLocation(locationMap));
      }
    });
  }

  /************************************
   * Developer Options
   ************************************/

  @ReactMethod
  public void setOptions(final ReadableMap optionsMap) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        ReadableMapKeySetIterator iterator = optionsMap.keySetIterator();
        while (iterator.hasNextKey()) {
          String key = iterator.nextKey();
          switch(optionsMap.getType(key)) {
            case String:
              Localytics.setOption(key, optionsMap.getString(key));
              break;
            case Number:
              Localytics.setOption(key, optionsMap.getInt(key));
              break;
            case Boolean:
              Localytics.setOption(key, optionsMap.getBoolean(key));
              break;
          }
        }
      }
    });
  }

  @ReactMethod
  public void setLoggingEnabled(final Boolean enabled) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setLoggingEnabled(enabled);
      }
    });
  }

  @ReactMethod
  public void isLoggingEnabled(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.isLoggingEnabled());
          }
        });
      }
    });
  }

  @ReactMethod
  public void enableLiveDeviceLogging() {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.enableLiveDeviceLogging();
      }
    });
  }

  @ReactMethod
  public void redirectLogsToDisk(final ReadableMap params) {
    final Boolean external = getBoolean(params, "external");
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.redirectLogsToDisk(external, reactContext);
      }
    });
  }

  @ReactMethod
  public void setTestModeEnabled(final Boolean enabled) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        Localytics.setTestModeEnabled(enabled);
      }
    });
  }

  @ReactMethod
  public void isTestModeEnabled(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.isTestModeEnabled());
          }
        });      }
    });
  }

  @ReactMethod
  public void getInstallId(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.getInstallId());
          }
        });
      }
    });
  }

  @ReactMethod
  public void getAppKey(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.getAppKey());
          }
        });
      }
    });
  }

  @ReactMethod
  public void getLibraryVersion(final Promise promise) {
    localyticsHandler.post(new Runnable() {
      @Override
      public void run() {
        resolveHandler.post(new Runnable() {
          @Override
          public void run() {
            promise.resolve(Localytics.getLibraryVersion());
          }
        });
      }
    });
  }

  /************************************
   * React Native Helpers
   ************************************/

  private void logNullParameterError(String operation, String failingParameters, String providedParameterValues) {
    logInvalidParameterError(operation, failingParameters, "invalid null value(s)", providedParameterValues);
  }

  private void logInvalidParameterError(String operation, String failingParameters, String invalidReason, String providedParameterValues) {
    Log.w("Localytics React Native", String.format("Localytics failed to complete operation: %s. Parameter(s): %s were invalid for reason: %s. The provided parameter values were: %s.", operation, failingParameters, invalidReason, providedParameterValues));
  }


  /************************************
   * ReadableMap Getters
   ************************************/

  static String getString(ReadableMap readableMap, String key) {
    return readableMap.hasKey(key) ? readableMap.getString(key) : null;
  }

  static Integer getInt(ReadableMap readableMap, String key) {
    return readableMap.hasKey(key) ? readableMap.getInt(key) : 0;
  }

  static Integer getCustomDimensionIndex(ReadableMap readableMap, String key) {
    return readableMap.hasKey(key) ? readableMap.getInt(key) : -1;
  }

  static Double getLatitude(ReadableMap readableMap, String key) {
    if (readableMap.hasKey(key)) {
      Double latitude = readableMap.getDouble(key);
      if (-90 <= latitude && latitude <= 90) {
        return latitude;
      }
    }

    return null;
  }

  static Double getLongitude(ReadableMap readableMap, String key) {
    if (readableMap.hasKey(key)) {
      Double longitude = readableMap.getDouble(key);
      if (-180 <= longitude && longitude <= 180) {
        return longitude;
      }
    }

    return null;
  }

  static Long getLong(ReadableMap readableMap, String key) {
    return readableMap.hasKey(key) ? (long) readableMap.getDouble(key) : 0;
  }

  static Double getDouble(ReadableMap readableMap, String key) {
    return readableMap.hasKey(key) ? readableMap.getDouble(key) : 0.0;
  }

  static Float getFloat(ReadableMap readableMap, String key) {
    return readableMap.hasKey(key) ? (float) readableMap.getDouble(key) : 0.0f;
  }

  static Boolean getBoolean(ReadableMap readableMap, String key) {
    return readableMap.hasKey(key) ? readableMap.getBoolean(key) : true;
  }

  static Dynamic getDynamic(ReadableMap readableMap, String key) {
    return readableMap.hasKey(key) ? readableMap.getDynamic(key) : null;
  }

  static ReadableMap getReadableMap(ReadableMap readableMap, String key) {
    return readableMap.hasKey(key) ? readableMap.getMap(key) : null;
  }

  static ReadableArray getReadableArray(ReadableMap readableMap, String key) {
    return readableMap.hasKey(key) ? readableMap.getArray(key) : null;
  }

  /************************************
   * Conversions
   ************************************/

  static Map<String, String> toStringMap(ReadableMap readableMap) {
    if (readableMap == null) {
      return null;
    }

    ReadableMapKeySetIterator iterator = readableMap.keySetIterator();
    if (!iterator.hasNextKey()) {
      return null;
    }

    Map<String, String> result = new HashMap<>();
    while (iterator.hasNextKey()) {
      String key = iterator.nextKey();
      ReadableType type = readableMap.getType(key);
      switch (type) {
        case Number:
          // Can be int or double
          double tmp = readableMap.getDouble(key);
          if (tmp == (int) tmp) {
            result.put(key, Integer.toString((int) tmp));
          } else {
            result.put(key, Double.toString(tmp));
          };
          break;
        case String:
          result.put(key, readableMap.getString(key));
          break;
      }
    }

    return result;
  }

  static Long toLong(Integer integer) {
    if (integer == null) {
      return null;
    }

    return Long.valueOf(integer.longValue());
  }

  static Customer toCustomer(ReadableMap readableMap) {
    if (readableMap == null) {
      return null;
    }

    return new Customer.Builder()
        .setCustomerId(getString(readableMap, "customerId"))
        .setFirstName(getString(readableMap, "firstName"))
        .setLastName(getString(readableMap, "lastName"))
        .setFullName(getString(readableMap, "fullName"))
        .setEmailAddress(getString(readableMap, "emailAddress"))
        .build();
  }

  static Localytics.ProfileScope toScope(String scope) {
    if ("org".equalsIgnoreCase(scope)) {
      return Localytics.ProfileScope.ORGANIZATION;
    } else {
      return Localytics.ProfileScope.APPLICATION;
    }
  }

  static Localytics.InAppMessageDismissButtonLocation toDismissButtonLocation(String location) {
    if ("right".equalsIgnoreCase(location)) {
      return Localytics.InAppMessageDismissButtonLocation.RIGHT;
    } else {
      return Localytics.InAppMessageDismissButtonLocation.LEFT;
    }
  }

  static String[] toStringArray(ReadableArray readableArray) {
    int size = readableArray.size();
    String[] array = new String[size];
    for (int i = 0; i < size; i++) {
      array[i] = readableArray.getString(i);
    }

    return array;
  }

  static long[] toLongArray(ReadableArray readableArray) {
    int size = readableArray.size();
    long[] array = new long[size];
    for (int i = 0; i < size; i++) {
      array[i] = (long) readableArray.getInt(i);
    }

    return array;
  }

  static WritableArray toCircularRegionsWritableArray(List<CircularRegion> regions) {
    WritableArray writableArray = Arguments.createArray();
    for (CircularRegion region : regions) {
      writableArray.pushMap(toWritableMap(region));
    }

    return writableArray;
  }

  static WritableArray toRegionsWritableArray(List<Region> regions) {
    WritableArray writableArray = Arguments.createArray();
    for (Region region : regions) {
      if (region instanceof CircularRegion) {
        writableArray.pushMap(toWritableMap((CircularRegion) region));
      }
    }

    return writableArray;
  }

  static WritableMap toWritableMap(CircularRegion region) {
    WritableMap writableMap = Arguments.createMap();
    writableMap.putString("uniqueId", region.getUniqueId());
    writableMap.putDouble("latitude", region.getLatitude());
    writableMap.putDouble("longitude", region.getLongitude());
    writableMap.putString("name", region.getName());
    writableMap.putString("type", region.getType());
    writableMap.putMap("attributes", toWritableMap(region.getAttributes()));
    writableMap.putString("originLocation", region.getOriginLocation().toString());
    writableMap.putInt("radius", region.getRadius());

    return writableMap;
  }

  static WritableMap toWritableMap(Map<String, String> map) {
    WritableMap writableMap = Arguments.createMap();
    if (map != null) {
      for (Map.Entry<String, String> entry : map.entrySet()) {
        writableMap.putString(entry.getKey(), entry.getValue());
      }
    }

    return writableMap;
  }

  static List<Region> toRegions(ReadableArray readableArray) {
    int size = readableArray.size();
    List<Region> regions = new ArrayList<>();
    for (int i = 0; i < size; i++) {
      regions.add(toRegion(readableArray.getMap(i)));
    }

    return regions;
  }

  static Region toRegion(ReadableMap readableMap) {
    return new CircularRegion.Builder()
        .setUniqueId(getString(readableMap, "uniqueId"))
        .build();
  }

  static Location toLocation(ReadableMap readableMap) {
    Location location = new Location("react-native");

    Double latitude = getLatitude(readableMap, "latitude");
    if (latitude != null) {
      location.setLatitude(latitude);
    } else {
      return null;
    }

    Double longitude = getLongitude(readableMap, "longitude");
    if (longitude != null) {
      location.setLongitude(longitude);
    } else {
      return null;
    }

    location.setAltitude(getDouble(readableMap, "altitude"));
    location.setTime(getLong(readableMap, "time"));
    location.setAccuracy(getFloat(readableMap, "horizontalAccuracy"));
    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
      location.setVerticalAccuracyMeters(getFloat(readableMap, "verticalAccuracy"));
    }
    location.setSpeed(getFloat(readableMap, "speed"));
    location.setBearing(getFloat(readableMap, "direction"));
    return location;
  }

  static Region.Event toEvent(String event) {
    if ("enter".equalsIgnoreCase(event)) {
      return Region.Event.ENTER;
    } else {
      return Region.Event.EXIT;
    }
  }

  static WritableArray toInboxCampaignsWritableArray(List<InboxCampaign> campaigns) {
    WritableArray writableArray = Arguments.createArray();
    for (InboxCampaign campaign : campaigns) {
      writableArray.pushMap(toWritableMap(campaign));
    }

    return writableArray;
  }

  static WritableMap toWritableMap(InboxCampaign campaign) {
    WritableMap writableMap = Arguments.createMap();

    // Campaign
    writableMap.putInt("campaignId", (int) campaign.getCampaignId());
    writableMap.putString("name", campaign.getName());
    writableMap.putMap("attributes", toWritableMap(campaign.getAttributes()));

    // WebViewCampaign
    Uri creativeFilePath = campaign.getCreativeFilePath();
    writableMap.putString("creativeFilePath", creativeFilePath != null ? creativeFilePath.toString() : "");

    // InboxCampaign
    writableMap.putBoolean("read", campaign.isRead());
    writableMap.putString("title", campaign.getTitle());
    writableMap.putInt("sortOrder", (int) campaign.getSortOrder());
    writableMap.putInt("receivedDate", (int) (campaign.getReceivedDate().getTime() / 1000));
    writableMap.putString("summary", campaign.getSummary());
    writableMap.putBoolean("hasThumbnail", campaign.hasThumbnail());
    Uri thumbnailUri = campaign.getThumbnailUri();
    writableMap.putString("thumbnailUrl", thumbnailUri != null ? thumbnailUri.toString() : "");
    writableMap.putBoolean("hasCreative", campaign.hasCreative());
    writableMap.putBoolean("visible", campaign.isVisible());
    writableMap.putBoolean("pushToInboxCampaign", campaign.isPushToInboxCampaign());
    writableMap.putString("deeplinkUrl", campaign.getDeepLinkUrl());
    writableMap.putBoolean("deleted", campaign.isDeleted());

    return writableMap;
  }

  static WritableMap toWritableMap(android.location.Location location) {
    WritableMap writableMap = Arguments.createMap();
    writableMap.putDouble("latitude", location.getLatitude());
    writableMap.putDouble("longitude", location.getLongitude());
    writableMap.putDouble("altitude", location.getAltitude());
    writableMap.putInt("time", (int) (location.getTime() / 1000));
    writableMap.putDouble("accuracy", location.getAccuracy());

    return writableMap;
  }

  static WritableMap toWritableMap(Campaign campaign) {
    if (campaign instanceof PlacesCampaign) {
      return toWritableMap((PlacesCampaign) campaign);
    } else if (campaign instanceof InboxCampaign) {
      return toWritableMap((InboxCampaign) campaign);
    } else if (campaign instanceof InAppCampaign) {
      return toWritableMap((InAppCampaign) campaign);
    } else if (campaign instanceof PushCampaign) {
      return toWritableMap((PushCampaign) campaign);
    }
    return null; //should never happen.
  }

  static WritableMap toWritableMap(InAppCampaign campaign) {
    WritableMap writableMap = Arguments.createMap();

    // Campaign
    writableMap.putInt("campaignId", (int) campaign.getCampaignId());
    writableMap.putString("name", campaign.getName());
    writableMap.putMap("attributes", toWritableMap(campaign.getAttributes()));

    // WebViewCampaign
    Uri creativeFilePath = campaign.getCreativeFilePath();
    writableMap.putString("creativeFilePath", creativeFilePath != null ? creativeFilePath.toString() : "");

    // InAppCampaign
    if (!Double.isNaN(campaign.getAspectRatio())) {
      writableMap.putDouble("aspectRatio", campaign.getAspectRatio());
    }
    writableMap.putInt("bannerOffsetDps", campaign.getOffset());
    writableMap.putDouble("backgroundAlpha", campaign.getBackgroundAlpha());
    writableMap.putString("displayLocation", campaign.getDisplayLocation());
    writableMap.putBoolean("dismissButtonHidden", campaign.isDismissButtonHidden());
    if (Localytics.InAppMessageDismissButtonLocation.RIGHT.equals(campaign.getDismissButtonLocation())) {
      writableMap.putString("dismissButtonLocation", "right");
    } else {
      writableMap.putString("dismissButtonLocation", "left");
    }
    writableMap.putString("eventName", campaign.getEventName());
    writableMap.putMap("eventAttributes", toWritableMap(campaign.getEventAttributes()));

    return writableMap;
  }

  static WritableMap toWritableMap(PushCampaign campaign) {
    WritableMap writableMap = Arguments.createMap();

    // Campaign
    writableMap.putInt("campaignId", (int) campaign.getCampaignId());
    writableMap.putString("name", campaign.getName());
    writableMap.putMap("attributes", toWritableMap(campaign.getAttributes()));

    // PushCampaign
    writableMap.putString("title", campaign.getTitle());
    writableMap.putInt("creativeId", (int) campaign.getCreativeId());
    writableMap.putString("creativeType", campaign.getCreativeType());
    writableMap.putString("message", campaign.getMessage());
    writableMap.putString("soundFilename", campaign.getSoundFilename());
    writableMap.putString("attachmentUrl", campaign.getAttachmentUrl());

    return writableMap;
  }

  static WritableMap toWritableMap(PlacesCampaign campaign) {
    WritableMap writableMap = Arguments.createMap();

    // Campaign
    writableMap.putInt("campaignId", (int) campaign.getCampaignId());
    writableMap.putString("name", campaign.getName());
    writableMap.putMap("attributes", toWritableMap(campaign.getAttributes()));

    // PlacesCampaign
    writableMap.putString("title", campaign.getTitle());
    writableMap.putInt("creativeId", (int) campaign.getCreativeId());
    writableMap.putString("creativeType", campaign.getCreativeType());
    writableMap.putString("message", campaign.getMessage());
    writableMap.putString("soundFilename", campaign.getSoundFilename());
    writableMap.putString("attachmentUrl", campaign.getAttachmentUrl());
    writableMap.putMap("region", toWritableMap((CircularRegion) campaign.getRegion()));
    if (Region.Event.ENTER.equals(campaign.getTriggerEvent())) {
      writableMap.putString("triggerEvent", "enter");
    } else {
      writableMap.putString("triggerEvent", "exit");
    }

    return writableMap;
  }

  static List<String> toStringList(ReadableArray array) {
    List<String> result = new ArrayList<>();
    for (int i = 0; i < array.size(); i++) {
      result.add(array.getString(i));
    }

    return result;
  }

  InboxCampaign getInboxCampaignFromCache(int campaignId) {
    return inboxCampaignCache.get(campaignId);
  }
}
