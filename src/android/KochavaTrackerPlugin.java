package com.kochava.tracker;

//
//  KochavaTracker (Cordova)
//
//  Copyright (c) 2013 - 2021 Kochava, Inc. All rights reserved.
//

import android.content.Context;
import android.util.Log;

import com.kochava.core.json.internal.JsonArray;
import com.kochava.core.json.internal.JsonArrayApi;
import com.kochava.core.json.internal.JsonObjectApi;
import com.kochava.core.util.internal.ObjectUtil;
import com.kochava.core.util.internal.TextUtil;
import com.kochava.tracker.Tracker;
import com.kochava.tracker.attribution.InstallAttributionApi;
import com.kochava.tracker.attribution.RetrievedInstallAttributionListener;
import com.kochava.tracker.deeplinks.DeeplinkApi;
import com.kochava.tracker.deeplinks.ProcessedDeeplinkListener;
import com.kochava.tracker.engagement.Engagement;
import com.kochava.tracker.events.Event;
import com.kochava.tracker.events.EventApi;
import com.kochava.tracker.events.Events;
import com.kochava.tracker.log.LogLevel;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaInterface;
import org.apache.cordova.CordovaPlugin;
import org.apache.cordova.CordovaWebView;
import org.json.JSONArray;

/**
 * Kochava Tracker Plugin
 */
public final class KochavaTrackerPlugin extends CordovaPlugin {
    private static final String LOGTAG = "Kochava/Tracker";
    private Context context;

    /**
     * Initialize the Plugin.
     * @param cordova Cordova interface interface.
     * @param webView Cordova webview interface.
     */
    @Override
    public final void initialize(final CordovaInterface cordova, final CordovaWebView webView) {
        super.initialize(cordova, webView);
        if(context == null && cordova != null && cordova.getActivity() != null) {
            context = cordova.getActivity().getApplicationContext();
        }
    }

    /**
     * Performs an action within the sdk as defined by the action parameter.
     *
     * @param action to perform.
     * @param argsRaw is a list of arguments to pass to the specific action.
     * @param callbackContext to pass to results of the action.
     * @return True if completed and false if unable to complete.
     */
    @Override
    public final boolean execute(final String action, final JSONArray argsRaw, final CallbackContext callbackContext) {
        if(TextUtil.isNullOrBlank(action) || argsRaw == null) {
            return false;
        }
        final JsonArrayApi args = JsonArray.buildWithJSONArray(argsRaw);

        // void executeAdvancedInstruction(string name, string value)
        if (action.equals("executeAdvancedInstruction") && args.length() == 2) {
            final String name = args.getString(0, "");
            final String value = args.getString(1, "");
            Tracker.getInstance().executeAdvancedInstruction(name, value);
            return true;
        }

        // void setLogLevel(LogLevel logLevel)
        if (action.equals("setLogLevel") && args.length() == 1) {
            final LogLevel logLevel = LogLevel.fromString(args.getString(0, ""));
            Tracker.getInstance().setLogLevel(logLevel);
            return true;
        }

        // void setSleep(bool sleep)
        if (action.equals("setSleep") && args.length() == 1) {
            final boolean sleep = args.getBoolean(0, false);
            Tracker.getInstance().setSleep(sleep);
            return true;
        }

        // void setAppLimitAdTracking(bool appLimitAdTracking)
        if (action.equals("setAppLimitAdTracking") && args.length() == 1) {
            final boolean appLimitAdTracking = args.getBoolean(0, false);
            Tracker.getInstance().setAppLimitAdTracking(appLimitAdTracking);
            return true;
        }

        // void registerCustomDeviceIdentifier(string name, string value)
        if (action.equals("registerCustomDeviceIdentifier") && args.length() == 2) {
            final String name = args.getString(0, "");
            final String value = args.getString(1, "");
            Tracker.getInstance().registerCustomDeviceIdentifier(name, value);
            return true;
        }

        // void registerIdentityLink(string name, string value)
        if (action.equals("registerIdentityLink") && args.length() == 2) {
            final String name = args.getString(0, "");
            final String value = args.getString(1, "");
            Tracker.getInstance().registerIdentityLink(name, value);
            return true;
        }

        // void enableAndroidInstantApps(string instantAppGuid)
        if (action.equals("enableAndroidInstantApps") && args.length() == 1) {
            final String instantAppGuid = args.getString(0, "");
            Tracker.getInstance().enableInstantApps(instantAppGuid);
            return true;
        }

        // void enableIosAppClips(string identifier)
        if (action.equals("enableIosAppClips") && args.length() == 1) {
            Log.w(LOGTAG, "enableIosAppClips API is not available on this platform.");
            return true;
        }

        // void enableIosAtt()
        if (action.equals("enableIosAtt") && args.length() == 1) {
            Log.w(LOGTAG, "enableIosAtt API is not available on this platform.");
            return true;
        }

        // void setIosAttAuthorizationWaitTime(double waitTime)
        if (action.equals("setIosAttAuthorizationWaitTime") && args.length() == 1) {
            Log.w(LOGTAG, "setIosAttAuthorizationWaitTime API is not available on this platform.");
            return true;
        }

        // void setIosAttAuthorizationAutoRequest(bool autoRequest)
        if (action.equals("setIosAttAuthorizationAutoRequest") && args.length() == 1) {
            Log.w(LOGTAG, "setIosAttAuthorizationAutoRequest API is not available on this platform.");
            return true;
        }

        // void registerPrivacyProfile(string name, string[] keys)
        if(action.equals("registerPrivacyProfile") && args.length() == 2) {
            final String name = args.getString(0, "");
            final String[] keys = ObjectUtil.jsonArrayToStringArray(args.getJsonArray(1, true));
            Tracker.getInstance().registerPrivacyProfile(name, keys);
            return true;
        }

        // void setPrivacyProfileEnabled(string name, bool enabled)
        if(action.equals("setPrivacyProfileEnabled") && args.length() == 2) {
            final String name = args.getString(0, "");
            final boolean enabled = args.getBoolean(1, false);
            Tracker.getInstance().setPrivacyProfileEnabled(name, enabled);
            return true;
        }

        // bool getStarted()
        if(action.equals("getStarted") && args.length() == 0 && callbackContext != null) {
            callbackContext.success(Boolean.toString(Tracker.getInstance().isStarted()));
            return true;
        }

        // void start(string androidAppGuid, string iosAppGuid, string partnerName)
        if (action.equals("start") && args.length() == 3) {
            final String androidAppGuid = args.getString(0, "");
            // arg 1 is iosAppGuid
            final String partnerName = args.getString(2, "");
            if(!TextUtil.isNullOrBlank(androidAppGuid)) {
                Tracker.getInstance().startWithAppGuid(context, androidAppGuid);
            } else if(!TextUtil.isNullOrBlank(partnerName)) {
                Tracker.getInstance().startWithPartnerName(context, partnerName);
            } else {
                Log.e(LOGTAG, "No App Guid or Partner Name was registered.");
            }
            return true;
        }

        // void shutdown(bool deleteData)
        if (action.equals("shutdown") && args.length() == 1) {
            final boolean deleteData = args.getBoolean(0, false);
            Tracker.getInstance().shutdown(context, deleteData);
            return true;
        }

        // string getDeviceId()
        if(action.equals("getDeviceId") && args.length() == 0 && callbackContext != null) {
            callbackContext.success(Tracker.getInstance().getDeviceId());
            return true;
        }

        // InstallAttribution getInstallAttribution()
        if(action.equals("getInstallAttribution") && args.length() == 0 && callbackContext != null) {
            callbackContext.success(Tracker.getInstance().getInstallAttribution().toJson());
            return true;
        }

        // void retrieveInstallAttribution(Callback<InstallAttribution> callback)
        if(action.equals("retrieveInstallAttribution") && args.length() == 0 && callbackContext != null) {
            Tracker.getInstance().retrieveInstallAttribution(new RetrievedInstallAttributionListener() {
                @Override
                public final void onRetrievedInstallAttribution(final InstallAttributionApi installAttribution) {
                    callbackContext.success(installAttribution.toJson());
                }
            });
            return true;
        }

        // void processDeeplink(string path, Callback<Deeplink> callback)
        if(action.equals("processDeeplink") && args.length() == 1 && callbackContext != null) {
            final String path = args.getString(0, "");
            Tracker.getInstance().processDeeplink(path, new ProcessedDeeplinkListener() {
                @Override
                public final void onProcessedDeeplink(final DeeplinkApi deeplink) {
                    callbackContext.success(deeplink.toJson());
                }
            });
            return true;
        }

        // void processDeeplinkWithOverrideTimeout(string path, double timeout, Callback<Deeplink> callback)
        if(action.equals("processDeeplinkWithOverrideTimeout") && args.length() == 2 && callbackContext != null) {
            final String path = args.getString(0, "");
            final double timeout = args.getDouble(1, 10.0);
            Tracker.getInstance().processDeeplink(path, timeout, new ProcessedDeeplinkListener() {
                @Override
                public final void onProcessedDeeplink(final DeeplinkApi deeplink) {
                    callbackContext.success(deeplink.toJson());
                }
            });
            return true;
        }

        // void registerPushToken(string token)
        if (action.equals("registerPushToken") && args.length() == 1) {
            final String token = args.getString(0, "");
            Engagement.getInstance().registerPushToken(token);
            return true;
        }

        // void setPushEnabled(bool enabled)
        if (action.equals("setPushEnabled") && args.length() == 1) {
            final boolean enabled = args.getBoolean(0, false);
            Engagement.getInstance().setPushEnabled(enabled);
            return true;
        }

        // void sendEvent(string name)
        if (action.equals("sendEvent") && args.length() == 1) {
            final String name = args.getString(0, "");
            Events.getInstance().send(name);
            return true;
        }

        // void sendEventWithString(string name, string data)
        if (action.equals("sendEventWithString") && args.length() == 2) {
            final String name = args.getString(0, "");
            final String data = args.getString(1, "");
            Events.getInstance().sendWithString(name, data);
            return true;
        }

        // void sendEventWithDictionary(string name, object data)
        if (action.equals("sendEventWithDictionary") && args.length() == 2) {
            final String name = args.getString(0, "");
            final JsonObjectApi data = args.getJsonObject(1, true);
            Events.getInstance().sendWithDictionary(name, data.toJSONObject());
            return true;
        }

        // void sendEventWithEvent(Event event)
        if (action.equals("sendEventWithEvent") && args.length() == 1) {
            final JsonObjectApi eventInfo = args.getJsonObject(0, true);
            final String eventName = eventInfo.getString("name", "");
            final JsonObjectApi eventData = eventInfo.getJsonObject("data", true);
            final String androidGooglePlayReceiptData = eventInfo.getString("androidGooglePlayReceiptData", "");
            final String androidGooglePlayReceiptSignature = eventInfo.getString("androidGooglePlayReceiptSignature", "");
            final EventApi event = Event.buildWithEventName(eventName);
            event.mergeCustomDictionary(eventData.toJSONObject());
            if(!TextUtil.isNullOrBlank(androidGooglePlayReceiptData) && !TextUtil.isNullOrBlank(androidGooglePlayReceiptSignature)) {
                event.setGooglePlayReceipt(androidGooglePlayReceiptData, androidGooglePlayReceiptSignature);
            }
            event.send();
            return true;
        }

        Log.i(LOGTAG, "Invalid Action");
        return false;
    }
}
