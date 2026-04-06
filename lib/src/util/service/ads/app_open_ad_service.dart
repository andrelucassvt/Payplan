import 'dart:developer';

import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notes_app/src/util/service/ads/ad_config.dart';

class AppOpenAdService {
  AppOpenAdService._();

  static final instance = AppOpenAdService._();

  AppOpenAd? _appOpenAd;

  bool get isAdAvailable => _appOpenAd != null;

  void load() {
    AppOpenAd.load(
      adUnitId: AdConfig.appOpen,
      request: const AdRequest(),
      adLoadCallback: AppOpenAdLoadCallback(
        onAdLoaded: (ad) {
          _appOpenAd = ad;
          log('AppOpenAdService: ad loaded');
        },
        onAdFailedToLoad: (error) {
          _appOpenAd = null;
          log('AppOpenAdService: failed to load — $error');
        },
      ),
    );
  }

  void show() {
    if (_appOpenAd == null) {
      log('AppOpenAdService: ad not ready');
      return;
    }
    _appOpenAd!.show();
    _appOpenAd = null;
  }
}
