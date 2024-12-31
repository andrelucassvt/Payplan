import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:notes_app/src/util/colors/app_colors.dart';

class AdmobNativeBanner extends StatefulWidget {
  const AdmobNativeBanner({
    required this.bannerId,
    this.mainBackgroundColor,
    super.key,
  });
  final String bannerId;
  final Color? mainBackgroundColor;

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
        mainBackgroundColor: widget.mainBackgroundColor ?? Colors.purple,
        cornerRadius: 10.0,
        callToActionTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          backgroundColor: AppColors.whiteOpacity,
          style: NativeTemplateFontStyle.monospace,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
          // backgroundColor: Colors.white,
          style: NativeTemplateFontStyle.bold,
          size: 16.0,
        ),
        tertiaryTextStyle: NativeTemplateTextStyle(
          textColor: Colors.white,
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
