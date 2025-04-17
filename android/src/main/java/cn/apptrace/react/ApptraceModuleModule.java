package cn.apptrace.react;

import android.app.Activity;
import android.content.Context;
import android.content.Intent;
import android.text.TextUtils;
import android.util.Log;

import androidx.annotation.NonNull;

import com.facebook.react.bridge.ActivityEventListener;
import com.facebook.react.bridge.Arguments;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.Callback;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.modules.core.DeviceEventManagerModule;
import com.queyuan.apptracesdk.AppData;
import com.queyuan.apptracesdk.Configuration;
import com.queyuan.apptracesdk.AppTrace;
import com.queyuan.apptracesdk.listener.AppInstallListener;
import com.queyuan.apptracesdk.listener.AppWakeUpListener;

public class ApptraceModuleModule extends ReactContextBaseJavaModule {
    private static final String TAG = "ApptraceBridge";
    private static final String KEY_CODE = "code";
    private static final String KEY_MSG = "msg";
    private static final String KEY_PARAMSDATA = "paramsData";

    private static final String MODULE_NAME = "ApptraceModule";

    private boolean hasInit = false;
    private boolean hasRegisterWakeUp = false;
    private AppData cacheWakeUpData = null;
    private final ReactApplicationContext reactContext;
    private Intent wakeUpCacheIntent = null;

    public ApptraceModuleModule(ReactApplicationContext reactContext) {
        super(reactContext);
        this.reactContext = reactContext;

        reactContext.addActivityEventListener(new ActivityEventListener() {
            @Override
            public void onActivityResult(Activity activity, int requestCode, int resultCode, Intent data) {

            }

            @Override
            public void onNewIntent(Intent intent) {
                _getWakeUp(intent, null);
            }
        });
    }

    @NonNull
    @Override
    public String getName() {
        return MODULE_NAME;
    }

    @ReactMethod
    public void initSDK(boolean enableClipboard) {
        if (reactContext == null || hasInit) {
            return;
        }
        hasInit = true;

        Configuration configuration = new Configuration();
        configuration.setEnableClipboard(enableClipboard);

        Context applicationContext = reactContext.getApplicationContext();

        AppTrace.init(applicationContext, configuration);

        if (wakeUpCacheIntent != null) {
            _getWakeUp(wakeUpCacheIntent, null);

            wakeUpCacheIntent = null;
        }
    }

    @ReactMethod
    public void registerWakeUp(final Callback callback) {
        if (!hasInit) {
            Log.e(TAG, "Apptrace not init!");
            return;
        }

        hasRegisterWakeUp = true;

        if (cacheWakeUpData != null) {
            AppData appData = cacheWakeUpData;
            WritableMap result = _parseToResult(
                    200,
                    "Success",
                    appData.getParams());

            _dispatchEventToScript(callback, result);
            cacheWakeUpData = null;
            return;
        }

        Activity curActivity = getCurrentActivity();
        if (curActivity == null) {
            return;
        }
        Intent intent = curActivity.getIntent();
        _getWakeUp(intent, callback);
    }

    private void _getWakeUp(Intent intent, final Callback callback) {
        if (intent == null) {
            Log.e(TAG, "intent is null!");

            return;
        }

        if (!hasInit) {
            wakeUpCacheIntent = intent;

            Log.e(TAG, "Apptrace not init!");

            return;
        }

        AppTrace.getWakeUp(intent, new AppWakeUpListener() {
            @Override
            public void onWakeUpFinish(AppData appData) {
                if (appData == null) {
                    return;
                }

                if (hasRegisterWakeUp) {
                    WritableMap result = _parseToResult(
                            200,
                            "Success",
                            appData.getParams());
                    _dispatchEventToScript(callback, result);

                    cacheWakeUpData = null;
                } else {
                    cacheWakeUpData = appData;
                }
            }
        });
    }

    @ReactMethod
    public void getInstall(final Callback callback) {
        Log.e(TAG, "Apptrace getInstallTrace did call");

        if (!hasInit) {
            Log.e(TAG, "Apptrace not init!");
            return;
        }

        AppTrace.getInstall(new AppInstallListener() {
            @Override
            public void onInstallFinish(AppData appData) {
                Log.i(TAG, "onInstallFinish");

                if (appData == null) {
                    WritableMap result = _parseToResult(
                            -1,
                            "Extract data fail.",
                            "");
                    _dispatchEventToScript(callback, result);

                    return;
                }
                WritableMap result = _parseToResult(
                        200,
                        "Success",
                        appData.getParams());
                _dispatchEventToScript(callback, result);
            }

            @Override
            public void onError(int code, String message) {
                Log.e(TAG, "onError");

                WritableMap result = _parseToResult(
                        code,
                        message,
                        "");
                _dispatchEventToScript(callback, result);
            }
        });
    }

    private void _dispatchEventToScript(Callback callback, WritableMap ret) {
        if (callback == null) {
            try {
                getReactApplicationContext()
                        .getJSModule(DeviceEventManagerModule.RCTDeviceEventEmitter.class)
                        .emit("ApptraceWakeUpEvent", ret);
            } catch (Throwable e) {
                Log.e("ApptraceModule", "getJSModule error: " + e.getMessage());
            }
        } else {
            callback.invoke(ret);
        }
    }

    private static WritableMap _parseToResult(int code, String msg, String paramsData) {
        WritableMap result = Arguments.createMap();
        result.putInt(KEY_CODE, code);
        result.putString(KEY_MSG, msg);
        result.putString(KEY_PARAMSDATA, _defaultValue(paramsData));
        return result;
    }

    private static String _defaultValue(String str) {
        if (TextUtils.isEmpty(str)) {
            return "";
        }

        return str;
    }
}
