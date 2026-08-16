import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

/// A small, non-disruptive AdMob banner. Release builds do not request an ad
/// until a production unit ID is provided with `--dart-define`.
class AdBanner extends StatefulWidget {
  const AdBanner({super.key});

  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  static const _productionId = String.fromEnvironment('ADMOB_BANNER_ID');
  static const _androidTestId = 'ca-app-pub-3940256099942544/6300978111';

  BannerAd? _ad;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadIfAllowed();
  }

  Future<void> _loadIfAllowed() async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) return;
    if (!await ConsentInformation.instance.canRequestAds()) return;
    final id = kReleaseMode ? _productionId : _androidTestId;
    if (id.isEmpty) return;
    _ad = BannerAd(
      adUnitId: id,
      size: AdSize.banner,
      request: const AdRequest(),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, _) {
          ad.dispose();
          _ad = null;
          if (mounted) setState(() => _loaded = false);
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    _ad?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ad = _ad;
    if (!_loaded || ad == null) return const SizedBox.shrink();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Divider(height: 1),
        const SizedBox(height: 6),
        SafeArea(
          top: false,
          child: Center(
            child: SizedBox(
              width: ad.size.width.toDouble(),
              height: ad.size.height.toDouble(),
              child: AdWidget(ad: ad),
            ),
          ),
        ),
      ],
    );
  }
}
