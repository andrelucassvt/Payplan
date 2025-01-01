import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobNativeBanner extends StatefulWidget {
  const AdmobNativeBanner({
    required this.bannerId,
    this.mainBackgroundColor,
    this.textColor,
    super.key,
  });
  final String bannerId;
  final Color? mainBackgroundColor;
  final Color? textColor;

  @override
  State<AdmobNativeBanner> createState() => _AdmobNativeBannerState();
}

class _AdmobNativeBannerState extends State<AdmobNativeBanner> {
  NativeAd? nativeAd;
  bool _nativeAdIsLoaded = false;

  void loadAd() {
    nativeAd = NativeAd(
      adUnitId: widget.bannerId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          debugPrint('$NativeAd loaded.');
          setState(() {
            _nativeAdIsLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('$NativeAd failed to load: $error');
          ad.dispose();
        },
      ),
      request: const AdRequest(),
      nativeTemplateStyle: NativeTemplateStyle(
        templateType: TemplateType.small,
        mainBackgroundColor: Platform.isAndroid
            ? null
            : widget.mainBackgroundColor ?? Colors.purple,
        cornerRadius: 10.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: widget.textColor ?? Colors.white,
          backgroundColor: Platform.isAndroid
              ? widget.mainBackgroundColor
              : Colors.white.withOpacity(.6),
          style: NativeTemplateFontStyle.monospace,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: widget.textColor ?? Colors.white,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: widget.textColor ?? Colors.white,
          // backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: widget.textColor ?? Colors.white,
          style: NativeTemplateFontStyle.normal,
          size: 16.0,
        ),
      ),
    )..load();
  }

  @override
  void initState() {
    super.initState();
    loadAd();
  }

  @override
  Widget build(BuildContext context) {
    if (nativeAd != null && _nativeAdIsLoaded) {
      return Padding(
        padding: const EdgeInsets.only(
          bottom: 10,
        ),
        child: SizedBox(
          height: MediaQuery.of(context).size.width * (91 / 355),
          width: MediaQuery.of(context).size.width,
          child: AdWidget(
            ad: nativeAd!,
          ),
        ),
      );
    }
    return SizedBox.shrink();
  }
}
