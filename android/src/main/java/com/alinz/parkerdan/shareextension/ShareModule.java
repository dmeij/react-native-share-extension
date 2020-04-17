package com.alinz.parkerdan.shareextension;

import com.facebook.react.bridge.ReactContextBaseJavaModule;
import com.facebook.react.bridge.ReactApplicationContext;
import com.facebook.react.bridge.Promise;
import com.facebook.react.bridge.ReactMethod;
import com.facebook.react.bridge.WritableMap;

import android.app.Activity;
import android.content.Intent;
import android.net.Uri;

import org.json.JSONArray;
import org.json.JSONObject;

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
      try
      {
          promise.resolve(processIntent());
      }
      catch (Exception e){}
  }

    public WritableMap processIntent() throws Exception
    {
        JSONObject map              = new JSONObject();
        JSONArray data              = new JSONArray();
        String type                 = "";
        String action               = "";
        Activity currentActivity    = getCurrentActivity();

        if (currentActivity != null)
        {
            Intent intent   = currentActivity.getIntent();
            action          = intent.getAction();
            type            = intent.getType();

            if(type == null)
                type = "";

            if(Intent.ACTION_SEND.equals(action))
            {
                if("text/plain".equals(type))
                    data.put(intent.getStringExtra(Intent.EXTRA_TEXT));
                else if("video/*".equals(type) || "video/mpeg".equals(type) || "video/3gp".equals(type) || "video/mp4".equals(type) || "image/*".equals(type) || "image/jpeg".equals(type) || "image/png".equals(type) || "image/jpg".equals(type))
                {
                    Uri uri = (Uri) intent.getParcelableExtra(Intent.EXTRA_STREAM);
                    data.put("file://" + RealPathUtil.getRealPathFromURI(currentActivity, uri));
                }
            }
            else if(Intent.ACTION_SEND_MULTIPLE.equals(action))
            {
                if("*/*".equals(type) || "video/*".equals(type) || "video/mpeg".equals(type) || "video/3gp".equals(type) || "video/mp4".equals(type) || "image/*".equals(type) || "image/jpeg".equals(type) || "image/png".equals(type) || "image/jpg".equals(type))
                {
                    ArrayList items = intent.getParcelableArrayListExtra(Intent.EXTRA_STREAM);

                    for (int i = 0; i < items.size(); i++)
                        data.put("file://" + RealPathUtil.getRealPathFromURI(currentActivity, (Uri)items.get(i)));
                }
            }
        }

        map.put("type", type);
        map.put("value", data);

        return jsonConvert.jsonToReact(map);
    }
}
