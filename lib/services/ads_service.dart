import 'dart:async';

import 'package:app_tracking_transparency/app_tracking_transparency.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

class AdsService extends ChangeNotifier {
  bool ready = false;
  bool _initializing = false;
  bool _disposed = false;
  static bool get supported =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  Future<void> requestTracking() async {
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      final status = await AppTrackingTransparency.trackingAuthorizationStatus;
      if (status == TrackingStatus.notDetermined) {
        await AppTrackingTransparency.requestTrackingAuthorization();
      }
    }
  }

  Future<void> initialize() async {
    if (!supported || ready || _initializing) return;
    _initializing = true;
    final consentDone = Completer<void>();
    try {
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          try {
            await ConsentForm.loadAndShowConsentFormIfRequired((error) {
              if (!consentDone.isCompleted) consentDone.complete();
            });
          } catch (_) {
            if (!consentDone.isCompleted) consentDone.complete();
          }
        },
        (error) {
          if (!consentDone.isCompleted) consentDone.complete();
        },
      );
      await consentDone.future.timeout(const Duration(seconds: 30));
      if (_disposed) return;
      if (await ConsentInformation.instance.canRequestAds()) {
        await MobileAds.instance.initialize();
        if (!_disposed) {
          ready = true;
          notifyListeners();
        }
      }
    } catch (_) {
      /* Consent unavailable: leave ads disabled. */
    } finally {
      _initializing = false;
    }
  }

  Future<void> privacyOptions() async {
    if (!supported) return;
    final status = await ConsentInformation.instance
        .getPrivacyOptionsRequirementStatus();
    if (status == PrivacyOptionsRequirementStatus.required) {
      final done = Completer<void>();
      await ConsentForm.showPrivacyOptionsForm((error) {
        done.complete();
      });
      await done.future;
      ready = false;
      notifyListeners();
      await initialize();
    }
  }

  // Official Google test units; replace only when preparing production.
  String get bannerId => defaultTargetPlatform == TargetPlatform.iOS
      ? 'ca-app-pub-3940256099942544/2934735716'
      : 'ca-app-pub-3940256099942544/6300978111';

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
