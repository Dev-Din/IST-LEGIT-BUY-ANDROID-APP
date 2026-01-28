import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kDebugMode;

/// Widget that filters out the Firebase emulator warning banner overlay
/// 
/// The Firebase SDK automatically adds a warning banner when emulators are connected.
/// This widget removes that banner by adding its own overlay entry that covers it.
class EmulatorBannerFilter extends StatefulWidget {
  final Widget child;

  const EmulatorBannerFilter({
    super.key,
    required this.child,
  });

  @override
  State<EmulatorBannerFilter> createState() => _EmulatorBannerFilterState();
}

class _EmulatorBannerFilterState extends State<EmulatorBannerFilter> {
  OverlayEntry? _overlayEntry;

  @override
  void initState() {
    super.initState();
    if (kDebugMode) {
      // Add overlay entry after the frame is built to ensure it's on top
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _addBannerCover();
        // Periodically re-add to ensure it stays on top
        _schedulePeriodicCheck();
      });
    }
  }

  void _schedulePeriodicCheck() {
    if (!kDebugMode || !mounted) return;
    
    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      // Re-add overlay periodically to ensure it stays on top
      // This handles cases where Firebase re-adds its banner
      _removeBannerCover();
      _addBannerCover();
      _schedulePeriodicCheck();
    });
  }

  void _addBannerCover() {
    if (!mounted) return;

    final overlay = Overlay.maybeOf(context);
    if (overlay == null) return;

    // Remove existing overlay entry if any
    _removeBannerCover();

    // Create a new overlay entry that covers the banner
    // Using opaque: true and a larger height to ensure complete coverage
    _overlayEntry = OverlayEntry(
      builder: (context) {
        final scaffoldBgColor = Theme.of(context).scaffoldBackgroundColor;
        return Positioned(
          bottom: 0,
          left: 0,
          right: 0,
          child: IgnorePointer(
            ignoring: true, // Don't intercept pointer events
            child: Container(
              height: 120, // Increased height to ensure full coverage
              decoration: BoxDecoration(
                color: scaffoldBgColor,
                // Add shadow to ensure it covers any banner underneath
                boxShadow: [
                  BoxShadow(
                    color: scaffoldBgColor,
                    blurRadius: 0,
                    spreadRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: const SizedBox.shrink(),
            ),
          ),
        );
      },
      opaque: true, // Make it opaque to ensure it covers the banner
    );

    // Insert with a small delay to ensure it's added after Firebase's banner
    Future.delayed(const Duration(milliseconds: 100), () {
      if (!mounted) return;
      final overlay = Overlay.maybeOf(context);
      if (overlay != null && _overlayEntry != null) {
        overlay.insert(_overlayEntry!);
      }
    });
  }

  void _removeBannerCover() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  @override
  void dispose() {
    _removeBannerCover();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Re-add overlay if it was removed (e.g., after hot reload)
    if (kDebugMode && _overlayEntry == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _addBannerCover();
        }
      });
    }

    return widget.child;
  }
}
