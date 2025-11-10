import 'package:flutter/material.dart';

/// A horizontal scrolling container for cards with iOS-like page snapping
///
/// Features:
/// - Smooth horizontal scrolling
/// - Page snap behavior with peek effect
/// - Responsive card sizing
/// - Optional page indicators
class HorizontalCardScroller extends StatefulWidget {
  final List<Widget> cards;
  final double cardHeight;
  final bool showPageIndicator;
  final EdgeInsets? padding;

  const HorizontalCardScroller({
    super.key,
    required this.cards,
    required this.cardHeight,
    this.showPageIndicator = true,
    this.padding,
  });

  @override
  State<HorizontalCardScroller> createState() =>
      _HorizontalCardScrollerState();
}

class _HorizontalCardScrollerState extends State<HorizontalCardScroller> {
  late PageController _pageController;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    // Initialize with viewportFraction to show peek of next card
    _pageController = PageController(
      viewportFraction: 0.85,
      initialPage: 0,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Horizontal scrolling cards
        SizedBox(
          height: widget.cardHeight,
          child: PageView.builder(
            controller: _pageController,
            physics: const BouncingScrollPhysics(),
            onPageChanged: (index) {
              setState(() => _currentPage = index);
            },
            itemCount: widget.cards.length,
            itemBuilder: (context, index) {
              return AnimatedBuilder(
                animation: _pageController,
                builder: (context, child) {
                  double value = 1.0;
                  if (_pageController.position.haveDimensions) {
                    value = (_pageController.page ?? 0) - index;
                    value = (1 - (value.abs() * 0.15)).clamp(0.85, 1.0);
                  }

                  return Center(
                    child: SizedBox(
                      height: Curves.easeOut.transform(value) *
                          widget.cardHeight,
                      child: child,
                    ),
                  );
                },
                child: widget.cards[index],
              );
            },
          ),
        ),

        // Page indicators
        if (widget.showPageIndicator && widget.cards.length > 1) ...[
          const SizedBox(height: 16),
          _buildPageIndicators(),
        ],
      ],
    );
  }

  Widget _buildPageIndicators() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        widget.cards.length,
        (index) => AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: _currentPage == index ? 24 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: _currentPage == index
                ? Theme.of(context).primaryColor
                : Colors.grey.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ),
    );
  }
}

/// Alternative: Free-form horizontal scrolling (no snap behavior)
class HorizontalCardList extends StatelessWidget {
  final List<Widget> cards;
  final double cardHeight;
  final EdgeInsets? padding;

  const HorizontalCardList({
    super.key,
    required this.cards,
    required this.cardHeight,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: cardHeight,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
        itemCount: cards.length,
        itemBuilder: (context, index) => cards[index],
      ),
    );
  }
}
