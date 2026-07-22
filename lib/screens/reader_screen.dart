import 'dart:io';
import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfx/pdfx.dart';
import 'package:turnable_page/turnable_page.dart';
import '../models/book.dart';
import '../providers/theme_provider.dart';
import '../providers/bookshelf_provider.dart';
import '../utils/color_inversion.dart';

/// The PDF reader screen with page-flip animation, dark mode color inversion,
/// and an ergonomic reading HUD.
///
/// Architecture (per TRD §2.2):
/// - **PDF Controller**: Opens the document via `pdfx` and renders pages
/// - **PDF Renderer**: Renders individual pages as images
/// - **Filter Layer**: Wraps rendered pages in [ColorFiltered] for dark mode
/// - **Interaction Layer**: Gesture-driven page turning with curl animation
class ReaderScreen extends StatefulWidget {
  final Book book;
  const ReaderScreen({super.key, required this.book});

  @override
  State<ReaderScreen> createState() => _ReaderScreenState();
}

class _ReaderScreenState extends State<ReaderScreen>
    with TickerProviderStateMixin {
  PdfDocument? _document;
  int _totalPages = 0;
  int _currentPage = 0;
  bool _isLoading = true;
  String? _errorMessage;

  // Page image cache: page index → rendered bytes
  final Map<int, Uint8List> _pageCache = {};

  // Page flip animation
  late PageFlipController _flipController;
  late AnimationController _overlayFadeController;
  late Animation<double> _overlayFadeAnimation;

  bool _showOverlay = true;

  // ─── OLED Theme Colors ───
  static const _oledBlack = Color(0xFF0A0A0A);
  static const _surfaceDark = Color(0xFF141414);
  static const _textPrimary = Color(0xFFE5E0D8);
  static const _textSecondary = Color(0xFF8A8178);
  static const _accentGold = Color(0xFFD4AF37);
  static const _accentGoldDim = Color(0xFF9A7F28);

  @override
  void initState() {
    super.initState();
    _currentPage = widget.book.lastReadPage;
    _flipController = PageFlipController();
    _overlayFadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
      value: 1.0,
    );
    _overlayFadeAnimation = CurvedAnimation(
      parent: _overlayFadeController,
      curve: Curves.easeInOut,
    );
    _loadDocument();
  }

  Future<void> _loadDocument() async {
    try {
      final doc = await PdfDocument.openData(
        File(widget.book.localPath).readAsBytesSync(),
      );
      if (!mounted) return;
      setState(() {
        _document = doc;
        _totalPages = doc.pagesCount;
        _isLoading = false;
      });

      // Update total pages in persistent storage if needed
      if (widget.book.totalPages != _totalPages) {
        context
            .read<BookshelfProvider>()
            .updateTotalPages(widget.book.localPath, _totalPages);
      }

      // Pre-render pages around the starting position
      final start = math.max(0, _currentPage - 1);
      final end = math.min(_totalPages, _currentPage + 3);
      for (int i = start; i < end; i++) {
        _renderPage(i);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = 'Failed to open PDF: $e';
      });
    }
  }

  Future<void> _renderPage(int index) async {
    if (_pageCache.containsKey(index) || _document == null) return;
    try {
      final page = await _document!.getPage(index + 1); // 1-indexed
      final image = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: PdfPageImageFormat.png,
      );
      await page.close();
      if (mounted && image != null) {
        setState(() {
          _pageCache[index] = image.bytes;
        });
      }
    } catch (_) {
      // Silently handle page render errors
    }
  }

  void _onPageChanged(int leftPage, int rightPage) {
    setState(() => _currentPage = leftPage);

    // Save reading progress persistently
    context
        .read<BookshelfProvider>()
        .updateReadingProgress(widget.book.localPath, leftPage);

    // Pre-render surrounding pages
    for (int i = math.max(0, leftPage - 1);
        i < math.min(_totalPages, leftPage + 3);
        i++) {
      _renderPage(i);
    }
  }

  void _toggleOverlay() {
    setState(() => _showOverlay = !_showOverlay);
    if (_showOverlay) {
      _overlayFadeController.forward();
    } else {
      _overlayFadeController.reverse();
    }
  }

  @override
  void dispose() {
    // Save final reading position
    context
        .read<BookshelfProvider>()
        .updateReadingProgress(widget.book.localPath, _currentPage);
    _overlayFadeController.dispose();
    _document?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();
    final isDark = themeProvider.isDarkMode;
    final shouldInvert = themeProvider.invertColors;

    return Scaffold(
      backgroundColor: isDark ? _oledBlack : const Color(0xFFFAF8F5),
      body: _isLoading
          ? _buildLoadingState(isDark)
          : _errorMessage != null
              ? _buildErrorState(isDark)
              : _buildReader(isDark, shouldInvert),
    );
  }

  // ──────────────────────────────────────────────
  // Loading State
  // ──────────────────────────────────────────────

  Widget _buildLoadingState(bool isDark) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 48,
            height: 48,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: isDark ? _accentGold : _accentGoldDim,
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Opening ${widget.book.name}…',
            style: TextStyle(
              fontSize: 16,
              color: isDark ? _textSecondary : const Color(0xFF6E6860),
            ),
          ),
        ],
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Error State
  // ──────────────────────────────────────────────

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: Colors.redAccent.shade200,
            ),
            const SizedBox(height: 16),
            Text(
              'Unable to open PDF',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: isDark ? _textPrimary : const Color(0xFF1A1A1A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark ? _textSecondary : const Color(0xFF6E6860),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: Icon(Icons.arrow_back_rounded,
                  color: isDark ? _accentGold : _accentGoldDim),
              label: Text('Go Back',
                  style: TextStyle(
                      color: isDark ? _accentGold : _accentGoldDim)),
            ),
          ],
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Main Reader
  // ──────────────────────────────────────────────

  Widget _buildReader(bool isDark, bool shouldInvert) {
    return Stack(
      children: [
        // PDF Page View with color inversion
        GestureDetector(
          onTap: _toggleOverlay,
          child: _buildPageView(isDark, shouldInvert),
        ),

        // Top overlay: back button + title
        FadeTransition(
          opacity: _overlayFadeAnimation,
          child: _buildTopBar(isDark),
        ),

        // Bottom overlay: ergonomic reading HUD
        FadeTransition(
          opacity: _overlayFadeAnimation,
          child: _buildBottomHUD(isDark),
        ),
      ],
    );
  }

  Widget _buildPageView(bool isDark, bool shouldInvert) {
    Widget pageView = TurnablePage(
      controller: _flipController,
      pageCount: _totalPages,
      onPageChanged: _onPageChanged,
      pageViewMode: PageViewMode.single,
      autoResponseSize: true,
      settings: FlipSettings(
        startPageIndex: widget.book.lastReadPage,
        flippingTime: 600,
        swipeDistance: 60.0,
        drawShadow: true,
        maxShadowOpacity: isDark ? 0.7 : 0.4,
        usePortrait: true,
        mobileScrollSupport: true,
        showPageCorners: true,
        enableEasing: true,
        enableInertia: true,
      ),
      builder: (context, index, constraints) {
        return _buildPage(index, isDark);
      },
    );

    // Apply ColorFiltered inversion for dark mode (TRD §2.3)
    if (shouldInvert) {
      pageView = ColorFiltered(
        colorFilter: invertColorFilter,
        child: pageView,
      );
    }

    return pageView;
  }

  Widget _buildPage(int index, bool isDark) {
    final bytes = _pageCache[index];

    if (bytes == null) {
      // Page not yet rendered — show loading placeholder
      _renderPage(index);
      return Container(
        color: isDark ? _oledBlack : Colors.white,
        child: Center(
          child: SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              color: isDark ? _accentGold : _accentGoldDim,
            ),
          ),
        ),
      );
    }

    return Container(
      color: isDark ? _oledBlack : Colors.white,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
            gaplessPlayback: true,
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Top Bar Overlay
  // ──────────────────────────────────────────────

  Widget _buildTopBar(bool isDark) {
    return IgnorePointer(
      ignoring: !_showOverlay,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              (isDark ? _oledBlack : Colors.white).withValues(alpha: 0.95),
              (isDark ? _oledBlack : Colors.white).withValues(alpha: 0.0),
            ],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: [
                // Back button
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    color: isDark ? _accentGold : _accentGoldDim,
                  ),
                ),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    widget.book.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                      color: isDark ? _textPrimary : const Color(0xFF1A1A1A),
                    ),
                  ),
                ),
                // Color inversion toggle
                Consumer<ThemeProvider>(
                  builder: (_, tp, child) => IconButton(
                    onPressed: tp.toggleInvertColors,
                    icon: Icon(
                      tp.invertColors
                          ? Icons.invert_colors_rounded
                          : Icons.invert_colors_off_rounded,
                      color: isDark ? _accentGold : _accentGoldDim,
                    ),
                    tooltip: tp.invertColors
                        ? 'Disable color inversion'
                        : 'Enable color inversion',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ──────────────────────────────────────────────
  // Bottom HUD — Ergonomic Reading Progress Bar
  // ──────────────────────────────────────────────

  Widget _buildBottomHUD(bool isDark) {
    final pagesLeft = _totalPages - _currentPage - 1;
    final progressPercent =
        _totalPages > 0 ? ((_currentPage + 1) / _totalPages * 100) : 0.0;
    final progressFraction =
        _totalPages > 0 ? (_currentPage + 1) / _totalPages : 0.0;

    return IgnorePointer(
      ignoring: !_showOverlay,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.bottomCenter,
              end: Alignment.topCenter,
              colors: [
                (isDark ? _oledBlack : Colors.white).withValues(alpha: 0.95),
                (isDark ? _oledBlack : Colors.white).withValues(alpha: 0.0),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // ── Reading stats row ──
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          '$pagesLeft page${pagesLeft == 1 ? '' : 's'} left',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? _textSecondary
                                : const Color(0xFF8A8178),
                          ),
                        ),
                        Text(
                          '${progressPercent.toStringAsFixed(0)}%',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? _accentGold : _accentGoldDim,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),

                  // ── Animated progress bar ──
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: progressFraction),
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeInOut,
                      builder: (context, value, _) {
                        return LinearProgressIndicator(
                          value: value,
                          minHeight: 4,
                          backgroundColor: isDark
                              ? const Color(0xFF1E1E1E)
                              : const Color(0xFFE8E4DC),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            isDark ? _accentGold : _accentGoldDim,
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 12),

                  // ── Page slider ──
                  if (_totalPages > 1)
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor:
                            isDark ? _accentGold : _accentGoldDim,
                        inactiveTrackColor: isDark
                            ? const Color(0xFF1E1E1E)
                            : const Color(0xFFE8E4DC),
                        thumbColor: isDark ? _accentGold : _accentGoldDim,
                        overlayColor: _accentGold.withValues(alpha: 0.15),
                        trackHeight: 3,
                        thumbShape: const RoundSliderThumbShape(
                          enabledThumbRadius: 7,
                        ),
                      ),
                      child: Slider(
                        value: _currentPage.toDouble(),
                        min: 0,
                        max: (_totalPages - 1).toDouble(),
                        onChanged: (value) {
                          final page = value.round();
                          _flipController.goToPage(page);
                        },
                      ),
                    ),
                  const SizedBox(height: 4),

                  // ── Page counter pill ──
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark ? _surfaceDark : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isDark
                            ? _accentGold.withValues(alpha: 0.2)
                            : _accentGoldDim.withValues(alpha: 0.2),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.08),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'Page ${_currentPage + 1} of $_totalPages',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? _textPrimary : const Color(0xFF3A3630),
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
