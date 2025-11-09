package com.example.bookswap

import io.flutter.app.FlutterApplication
import android.content.Context
import androidx.multidex.MultiDex

class MyApplication : FlutterApplication() {
    override fun attachBaseContext(base: Context) {
        super.attachBaseContext(base)
        MultiDex.install(this)
    }
}