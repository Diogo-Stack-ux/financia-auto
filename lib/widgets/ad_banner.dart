import 'package:material_ui/material_ui.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../color/app_colors.dart';
import '../services/ads_service.dart';

class AdBanner extends StatefulWidget {
  const AdBanner({super.key, required this.ads});
  final AdsService ads;
  @override
  State<AdBanner> createState() => _AdBannerState();
}

class _AdBannerState extends State<AdBanner> {
  BannerAd? _banner;
  bool _loaded = false;
  @override
  void initState() {
    super.initState();
    widget.ads.addListener(_refresh);
    _refresh();
  }

  void _refresh() {
    if (!widget.ads.ready) {
      _banner?.dispose();
      _banner = null;
      if (mounted) setState(() => _loaded = false);
      return;
    }
    if (_banner != null) return;
    _banner = BannerAd(
      adUnitId: widget.ads.bannerId,
      size: AdSize.banner,
      request: const AdRequest(nonPersonalizedAds: true),
      listener: BannerAdListener(
        onAdLoaded: (_) {
          if (mounted) setState(() => _loaded = true);
        },
        onAdFailedToLoad: (ad, error) {
          ad.dispose();
          _banner = null;
        },
      ),
    )..load();
  }

  @override
  void dispose() {
    widget.ads.removeListener(_refresh);
    _banner?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_loaded || _banner == null) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Column(
        children: [
          const Text(
            'PUBLICIDADE · ANÚNCIO DE TESTE',
            style: TextStyle(fontSize: 9, color: AppColors.muted),
          ),
          const SizedBox(height: 6),
          SizedBox(width: 320, height: 50, child: AdWidget(ad: _banner!)),
        ],
      ),
    );
  }
}
