import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobNativeBanner extends StatefulWidget {
  const AdmobNativeBanner({
    required this.adUnitId,
    this.mainBackgroundColor,
    this.textColor,
    super.key,
  });

  final String adUnitId;
  final Color? mainBackgroundColor;
  final Color? textColor;

  @override
  State<AdmobNativeBanner> createState() => _AdmobNativeBannerState();
}

class _AdmobNativeBannerState extends State<AdmobNativeBanner> {
  NativeAd? _nativeAd;
  bool _isLoaded = false;

  @override
  void initState() {
    super.initState();
    _loadAd();
  }

  void _loadAd() {
    _nativeAd = NativeAd(
      adUnitId: widget.adUnitId,
      listener: NativeAdListener(
        onAdLoaded: (ad) {
          if (mounted) setState(() => _isLoaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          log('AdmobNativeBanner: failed to load — $error');
          ad.dispose();
          _nativeAd = null;
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
              : Colors.white.withValues(alpha: 0.6),
          style: NativeTemplateFontStyle.monospace,
          size: 16.0,
        ),
        primaryTextStyle: NativeTemplateTextStyle(
          textColor: widget.textColor ?? Colors.white,
          size: 16.0,
        ),
        secondaryTextStyle: NativeTemplateTextStyle(
          textColor: widget.textColor ?? Colors.white,
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
  void dispose() {
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isLoaded || _nativeAd == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: SizedBox(
        height: MediaQuery.of(context).size.width * (91 / 355),
        width: MediaQuery.of(context).size.width,
        child: AdWidget(ad: _nativeAd!),
      ),
    );
  }
}
