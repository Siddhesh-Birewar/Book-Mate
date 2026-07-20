import 'dart:typed_data';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:pdfx/pdfx.dart';
import '../models/book.dart';
import '../providers/theme_provider.dart';
import '../utils/color_inversion.dart';

/// The PDF reader screen with page-flip animation and dark mode color inversion.
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
  late PageController _pageController;
  late AnimationController _overlayFadeController;
  late Animation<double> _overlayFadeAnimation;

  bool _showOverlay = true;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
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
      final doc = await PdfDocument.openFile(widget.book.path);
      if (!mounted) return;
      setState(() {
        _document = doc;
        _totalPages = doc.pagesCount;
        _isLoading = false;
      });
      // Pre-render first 3 pages
      for (int i = 0; i < math.min(3, _totalPages); i++) {
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

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
    // Pre-render surrounding pages
    for (int i = math.max(0, page - 1);
        i < math.min(_totalPages, page + 3);
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
    _pageController.dispose();
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
      backgroundColor: isDark ? const Color(0xFF0A0A14) : const Color(0xFFF5F3FA),
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
              color: isDark
                  ? const Color(0xFF9B85FF)
                  : const Color(0xFF6B4EFF),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Opening ${widget.book.name}…',
            style: TextStyle(
              fontSize: 16,
              color: isDark
                  ? const Color(0xFF8A8198)
                  : const Color(0xFF6E6B7B),
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
                color: isDark
                    ? const Color(0xFFE8E4F0)
                    : const Color(0xFF1A1A2E),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Unknown error',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: isDark
                    ? const Color(0xFF8A8198)
                    : const Color(0xFF6E6B7B),
              ),
            ),
            const SizedBox(height: 24),
            TextButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Go Back'),
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

        // Bottom overlay: page indicator + controls
        FadeTransition(
          opacity: _overlayFadeAnimation,
          child: _buildBottomBar(isDark),
        ),
      ],
    );
  }

  Widget _buildPageView(bool isDark, bool shouldInvert) {
    Widget pageView = PageView.builder(
      controller: _pageController,
      itemCount: _totalPages,
      onPageChanged: _onPageChanged,
      physics: const BouncingScrollPhysics(),
      itemBuilder: (context, index) {
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
      return Center(
        child: SizedBox(
          width: 32,
          height: 32,
          child: CircularProgressIndicator(
            strokeWidth: 2.5,
            color: isDark
                ? const Color(0xFF9B85FF)
                : const Color(0xFF6B4EFF),
          ),
        ),
      );
    }

    return InteractiveViewer(
      minScale: 1.0,
      maxScale: 4.0,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 16),
          child: Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.15),
                  blurRadius: 24,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Image.memory(
                bytes,
                fit: BoxFit.contain,
                gaplessPlayback: true,
              ),
            ),
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
              (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
              (isDark ? Colors.black : Colors.white).withValues(alpha: 0.0),
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
                    color: isDark
                        ? const Color(0xFF9B85FF)
                        : const Color(0xFF6B4EFF),
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
                      color: isDark
                          ? const Color(0xFFE8E4F0)
                          : const Color(0xFF1A1A2E),
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
                      color: isDark
                          ? const Color(0xFF9B85FF)
                          : const Color(0xFF6B4EFF),
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
  // Bottom Bar Overlay
  // ──────────────────────────────────────────────

  Widget _buildBottomBar(bool isDark) {
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
                (isDark ? Colors.black : Colors.white).withValues(alpha: 0.9),
                (isDark ? Colors.black : Colors.white).withValues(alpha: 0.0),
              ],
            ),
          ),
          child: SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Page slider
                  if (_totalPages > 1)
                    SliderTheme(
                      data: SliderThemeData(
                        activeTrackColor: isDark
                            ? const Color(0xFF9B85FF)
                            : const Color(0xFF6B4EFF),
                        inactiveTrackColor: isDark
                            ? const Color(0xFF2A2A3E)
                            : const Color(0xFFE0DCEF),
                        thumbColor: isDark
                            ? const Color(0xFF9B85FF)
                            : const Color(0xFF6B4EFF),
                        overlayColor: const Color(0xFF6B4EFF)
                            .withValues(alpha: 0.15),
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
                          _pageController.jumpToPage(page);
                        },
                      ),
                    ),
                  const SizedBox(height: 4),

                  // Page counter
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF1A1A2E)
                          : Colors.white,
                      borderRadius: BorderRadius.circular(20),
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
                        color: isDark
                            ? const Color(0xFFCCC4E0)
                            : const Color(0xFF4A4660),
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
