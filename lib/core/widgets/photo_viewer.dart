import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../l10n/generated/app_localizations.dart';
import '../theme/design_tokens.dart';

/// Penampil foto layar penuh dengan zoom/pan bawaan Flutter.
///
/// Cubit atau ketuk dua kali untuk memperbesar; ketuk dua kali lagi untuk
/// kembali. Tidak memakai paket tambahan dan tidak mengunduh apa pun — bytes
/// foto sudah ada di memori dari `thumbnailProvider`.
class PhotoViewerScreen extends StatefulWidget {
  const PhotoViewerScreen({
    required this.imageBytes,
    required this.heroTag,
    required this.semanticsLabel,
    super.key,
  }) : assert(imageBytes.length > 0);

  final Uint8List imageBytes;
  final Object heroTag;
  final String semanticsLabel;

  /// Membuka penampil sebagai rute sementara di atas layar saat ini.
  static Future<void> open(
    BuildContext context, {
    required Uint8List imageBytes,
    required Object heroTag,
    required String semanticsLabel,
  }) async {
    await Navigator.of(context).push<void>(
      PageRouteBuilder<void>(
        transitionDuration: DesignTokens.animationMedium,
        reverseTransitionDuration: DesignTokens.animationFast,
        pageBuilder: (context, animation, secondaryAnimation) =>
            PhotoViewerScreen(
              imageBytes: imageBytes,
              heroTag: heroTag,
              semanticsLabel: semanticsLabel,
            ),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(
            opacity: CurvedAnimation(
              parent: animation,
              curve: DesignTokens.motionCurve,
            ),
            child: child,
          );
        },
      ),
    );
  }

  @override
  State<PhotoViewerScreen> createState() => _PhotoViewerScreenState();
}

class _PhotoViewerScreenState extends State<PhotoViewerScreen>
    with SingleTickerProviderStateMixin {
  static const double _zoomScale = 2.5;
  static const double _zoomThreshold = 1.01;

  final TransformationController _transformation = TransformationController();
  late final AnimationController _animationController;
  Animation<Matrix4>? _matrixAnimation;
  Offset? _doubleTapPosition;
  bool _isZoomed = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: DesignTokens.animationMedium,
    )..addListener(_tickAnimation);
    _transformation.addListener(_handleTransform);
  }

  void _tickAnimation() {
    final animation = _matrixAnimation;
    if (animation != null) _transformation.value = animation.value;
  }

  void _handleTransform() {
    final zoomed = _transformation.value.getMaxScaleOnAxis() > _zoomThreshold;
    if (zoomed == _isZoomed) return;
    setState(() => _isZoomed = zoomed);
  }

  void _animateTo(Matrix4 target) {
    _animationController.stop();
    _matrixAnimation = Matrix4Tween(begin: _transformation.value, end: target)
        .animate(
          CurvedAnimation(
            parent: _animationController,
            curve: DesignTokens.motionCurve,
          ),
        );
    _animationController
      ..reset()
      ..forward();
  }

  void _toggleZoom() {
    if (_isZoomed) {
      _animateTo(Matrix4.identity());
      return;
    }
    final size = context.size;
    final focal =
        _doubleTapPosition ??
        (size == null ? Offset.zero : Offset(size.width / 2, size.height / 2));
    final target = Matrix4.identity()
      ..translate(focal.dx * (1 - _zoomScale), focal.dy * (1 - _zoomScale))
      ..scale(_zoomScale);
    _animateTo(target);
  }

  void _reset() => _animateTo(Matrix4.identity());

  @override
  void dispose() {
    _animationController
      ..removeListener(_tickAnimation)
      ..dispose();
    _transformation
      ..removeListener(_handleTransform)
      ..dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      // Latar penampil gelap: ikon status bar harus terang.
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: colorScheme.scrim,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Positioned.fill(
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onDoubleTapDown: (details) =>
                    _doubleTapPosition = details.localPosition,
                onDoubleTap: _toggleZoom,
                child: InteractiveViewer(
                  transformationController: _transformation,
                  minScale: 1,
                  maxScale: 5,
                  onInteractionStart: (_) => _animationController.stop(),
                  child: Center(
                    child: Hero(
                      tag: widget.heroTag,
                      child: Image.memory(
                        widget.imageBytes,
                        fit: BoxFit.contain,
                        gaplessPlayback: true,
                        filterQuality: FilterQuality.medium,
                        semanticLabel: widget.semanticsLabel,
                        errorBuilder: (context, _, _) => Icon(
                          Icons.broken_image_outlined,
                          size: 64,
                          color: colorScheme.onInverseSurface,
                          semanticLabel: widget.semanticsLabel,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(DesignTokens.spaceSm),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _ViewerButton(
                      icon: Icons.close_rounded,
                      tooltip: l10n.photoViewerClose,
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                    const Spacer(),
                    if (_isZoomed)
                      _ViewerButton(
                        icon: Icons.zoom_out_map_rounded,
                        tooltip: l10n.photoViewerReset,
                        onPressed: _reset,
                      ),
                  ],
                ),
              ),
            ),
            Positioned(
              left: DesignTokens.spacePage,
              right: DesignTokens.spacePage,
              bottom: DesignTokens.spacePage,
              child: SafeArea(
                top: false,
                child: IgnorePointer(
                  child: Center(
                    child: AnimatedSlide(
                      offset: _isZoomed ? const Offset(0, 0.25) : Offset.zero,
                      duration: DesignTokens.animationFast,
                      curve: DesignTokens.motionCurve,
                      child: AnimatedOpacity(
                        opacity: _isZoomed ? 0 : 1,
                        duration: DesignTokens.animationFast,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: DesignTokens.spaceMd,
                            vertical: DesignTokens.spaceSm,
                          ),
                          decoration: ShapeDecoration(
                            color: colorScheme.surface.withValues(alpha: 0.92),
                            shape: const StadiumBorder(),
                          ),
                          child: Text(
                            l10n.photoViewerHint,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(color: colorScheme.onSurface),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Tombol melayang di sudut foto untuk membuka penampil layar penuh.
class PhotoZoomButton extends StatelessWidget {
  const PhotoZoomButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;
    return Semantics(
      button: true,
      label: l10n.photoViewerZoom,
      child: Tooltip(
        message: l10n.photoViewerZoom,
        child: SizedBox(
          width: DesignTokens.minTouchTarget,
          height: DesignTokens.minTouchTarget,
          child: Material(
            color: Colors.transparent,
            child: InkResponse(
              onTap: onPressed,
              radius: DesignTokens.minTouchTarget / 2,
              child: Center(
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: colorScheme.scrim.withValues(alpha: 0.45),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.zoom_in_rounded,
                    size: 20,
                    color: colorScheme.surface,
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewerButton extends StatelessWidget {
  const _ViewerButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      icon: Icon(icon),
      style: IconButton.styleFrom(
        backgroundColor: colorScheme.surface.withValues(alpha: 0.92),
        foregroundColor: colorScheme.onSurface,
        minimumSize: const Size.square(DesignTokens.minTouchTarget),
      ),
    );
  }
}
