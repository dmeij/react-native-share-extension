package com.alinz.parkerdan.shareextension;

import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableArray;
import com.facebook.react.bridge.WritableMap;
import com.facebook.react.bridge.Arguments;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;

import android.graphics.Bitmap;
import android.util.Log;

import java.io.InputStream;
import java.util.ArrayList;


public class ShareModule extends ReactContextBaseJavaModule {


  public ShareModule(ReactApplicationContext reactContext) {
      super(reactContext);
  }

  @Override
  public String getName() {
      return "ReactNativeShareExtension";
  }

  @ReactMethod
  public void close() {
    getCurrentActivity().finish();
  }

  @ReactMethod
  public void data(Promise promise) {
      promise.resolve(processIntent());
  }

    public WritableMap processIntent()
    {
        WritableMap map             = Arguments.createMap();
        WritableArray data          = Arguments.createArray();
        String value                = "";
        String type                 = "";
        String action               = "";
        Activity currentActivity    = getCurrentActivity();

        if (currentActivity != null)
        {
            Intent intent   = currentActivity.getIntent();
            action          = intent.getAction();
            type            = intent.getType();

            Log.e("ReactNativeJS", type);

            if(type == null)
                type = "";

            if(Intent.ACTION_SEND.equals(action))
            {
                if("text/plain".equals(type))
                    data.pushString(intent.getStringExtra(Intent.EXTRA_TEXT));
                else if ("image/*".equals(type) || "image/jpeg".equals(type) || "image/png".equals(type) || "image/jpg".equals(type))
                {
                    Uri uri = (Uri) intent.getParcelableExtra(Intent.EXTRA_STREAM);
                    data.pushString("file://" + RealPathUtil.getRealPathFromURI(currentActivity, uri));
                }
            }
            else if(Intent.ACTION_SEND_MULTIPLE.equals(action))
            {
                if("*/*".equals(type) || "video/*".equals(type) || "video/mpeg".equals(type) || "video/3gp".equals(type) || "video/mp4".equals(type) || "image/*".equals(type) || "image/jpeg".equals(type) || "image/png".equals(type) || "image/jpg".equals(type))
                {
                    ArrayList items = intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM);

                    for (int i = 0; i < items.size(); i++)
                        data.pushString("file://" + RealPathUtil.getRealPathFromURI(currentActivity, (Uri)items.get(i)));
                }
            }
        }

        map.putString("type", type);
        map.putArray("data", data);

        return map;
    }
}
