import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// Requests the consent message configured in AdMob's Privacy & messaging UI.
/// Ads are initialized only after UMP says requests are permitted.
Future<void> initializeAdsWithConsent() async {
  final completed = Completer<void>();
  final parameters = ConsentRequestParameters();

  ConsentInformation.instance.requestConsentInfoUpdate(
    parameters,
    () async {
      ConsentForm.loadAndShowConsentFormIfRequired((_) async {
        if (await ConsentInformation.instance.canRequestAds()) {
          await MobileAds.instance.initialize();
        }
        if (!completed.isCompleted) completed.complete();
      });
    },
    (_) {
      // A previous consent decision may still allow requests while offline.
      ConsentInformation.instance.canRequestAds().then((canRequest) async {
        if (canRequest) await MobileAds.instance.initialize();
        if (!completed.isCompleted) completed.complete();
      });
    },
  );

  // Never keep the care tracker on its launch screen because the consent SDK
  // or network is unavailable. No ad is requested unless consent completes.
  await completed.future.timeout(
    const Duration(seconds: 8),
    onTimeout: () {},
  );
}
