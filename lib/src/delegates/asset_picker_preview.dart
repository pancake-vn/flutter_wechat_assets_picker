import 'dart:async';

import 'package:extended_image/extended_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_phosphor_icons/flutter_phosphor_icons.dart';
import 'package:wechat_assets_picker/wechat_assets_picker.dart';

class AssetPickerPreview extends StatefulWidget {
  const AssetPickerPreview({
    super.key,
    required this.asset,
    required this.index,
    required this.selected,
    required this.isSingleAssetMode,
    required this.onTap,
  });

  final AssetEntity asset;
  final int index;
  final bool selected;
  final bool isSingleAssetMode;
  final VoidCallback onTap;

  @override
  State<AssetPickerPreview> createState() => _AssetPickerPreviewState();
}

class _AssetPickerPreviewState extends State<AssetPickerPreview>
    with SingleTickerProviderStateMixin {
  Timer? _pressTimer;
  bool _pressed = false;
  OverlayEntry? _overlayEntry;

  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
      reverseDuration: const Duration(milliseconds: 180),
    );

    _opacity = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );

    _scale = Tween<double>(begin: 0.95, end: 1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
        reverseCurve: Curves.easeInCubic,
      ),
    );
  }

  void _showPreview() {
    if (_pressed || widget.asset.type != AssetType.image) return;

    _pressed = true;
    HapticFeedback.lightImpact();

    final overlay = Overlay.of(context, rootOverlay: true);

    _overlayEntry = OverlayEntry(
      builder: (_) {
        return Positioned.fill(
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _opacity,
              child: Container(
                color: Colors.black54,
                alignment: Alignment.center,
                child: ScaleTransition(
                  scale: _scale,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.8,
                      ),
                      child: ExtendedImage(
                        image: AssetEntityImageProvider(
                          widget.asset,
                          isOriginal: true,
                        ),
                        fit: BoxFit.contain,
                        loadStateChanged: (state) =>
                            switch (state.extendedImageLoadState) {
                          LoadState.loading => const SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.cyanAccent,
                                ),
                              ),
                            ),
                          LoadState.completed => state.completedWidget,
                          LoadState.failed =>
                            const Icon(PhosphorIcons.warning_circle),
                        },
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );

    overlay.insert(_overlayEntry!);
    _controller.forward(from: 0);
  }

  Future<void> _hidePreview() async {
    _pressTimer?.cancel();
    _pressTimer = null;

    if (!_pressed) return;
    _pressed = false;

    await _controller.reverse();
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onTapDown() {
    _pressTimer = Timer(
      const Duration(milliseconds: 120),
      _showPreview,
    );
  }

  void _onTapUp() {
    _pressTimer?.cancel();

    if (_pressed) {
      _hidePreview();
    } else {
      widget.onTap();
    }
  }

  void _onTapCancel() {
    _pressTimer?.cancel();
    _hidePreview();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: (_) => _onTapDown(),
      onTapUp: (_) => _onTapUp(),
      onTapCancel: _onTapCancel,
      child: Container(
        color: widget.selected
            ? const Color(0xffFFFFFF).withOpacity(0.5)
            : Colors.transparent,
        child: widget.selected && !widget.isSingleAssetMode
            ? Center(
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    color: const Color(0xFF05AABD),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '${widget.index + 1}',
                    style: const TextStyle(
                      color: Color(0xffFFFFFF),
                      fontWeight: FontWeight.w500,
                      fontSize: 17,
                    ),
                  ),
                ),
              )
            : const SizedBox.shrink(),
      ),
    );
  }

  @override
  void dispose() {
    _pressTimer?.cancel();
    _controller.dispose();
    _overlayEntry?.remove();
    super.dispose();
  }
}
