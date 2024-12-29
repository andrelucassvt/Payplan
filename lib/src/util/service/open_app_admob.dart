import 'dart:io' show Platform;

import 'package:google_mobile_ads/google_mobile_ads.dart';

class AppOpenAdManager {
  String adUnitId = Platform.isAndroid
      ? 'ca-app-pub-3652623512305285/5018170803'
      : 'ca-app-pub-3652623512305285/1467067906';

  AppOpenAd? _appOpenAd;

  void loadAd() {
    AppOpenAd.load(
      adUnitId: adUnitId,
      request: AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          Future.delayed(Duration(seconds: 5), () {
            _appOpenAd!.show();
          });
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
        },
      ),
    );
  }

  bool get isAdAvailable {
    return _appOpenAd != null;
  }
}
