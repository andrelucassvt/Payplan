import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdmobBannerWidget extends StatefulWidget {
  const AdmobBannerWidget({
    required this.bannerId,
    super.key,
  });
  final String bannerId;

  @override
  State<AdmobBannerWidget> createState() => _AdmobBannerWidgetState();
}

class _AdmobBannerWidgetState extends State<AdmobBannerWidget> {
  BannerAd? _bannerAd;
  bool _isLoaded = false;

  void loadAd() {
    _bannerAd = BannerAd(
      adUnitId: widget.bannerId,
      request: const AdRequest(),
      size: AdSize.banner,
      listener: BannerAdListener(
        onAdLoaded: (ad) {
          debugPrint('$ad loaded.');
          setState(() {
            _isLoaded = true;
          });
        },
        onAdFailedToLoad: (ad, error) {
          debugPrint('BannerAd failed to load: $error');
          ad.dispose();
        },
        onAdOpened: (Ad ad) {},
        onAdClosed: (Ad ad) {},
        onAdImpression: (Ad ad) {},
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
    return SizedBox();
    if (_bannerAd != null && _isLoaded) {
      return Padding(
        padding: const EdgeInsets.only(
          top: 5,
          bottom: 10,
        ),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: SafeArea(
            child: SizedBox(
              width: _bannerAd!.size.width.toDouble(),
              height: _bannerAd!.size.height.toDouble(),
              child: AdWidget(
                ad: _bannerAd!,
              ),
            ),
          ),
        ),
      );
    }
    return Container();
  }
}
