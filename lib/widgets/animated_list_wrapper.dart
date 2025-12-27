import 'package:flutter/material.dart';
import 'package:flutter_staggered_animations/flutter_staggered_animations.dart';

/// Wrapper untuk staggered list animations
class AnimatedListWrapper extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final Axis scrollDirection;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AnimatedListWrapper({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    this.scrollDirection = Axis.vertical,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: ListView.builder(
        scrollDirection: scrollDirection,
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredList(
            position: index,
            duration: const Duration(milliseconds: 375),
            child: SlideAnimation(
              verticalOffset: 50.0,
              child: FadeInAnimation(child: itemBuilder(context, index)),
            ),
          );
        },
      ),
    );
  }
}

/// Wrapper untuk staggered grid animations
class AnimatedGridWrapper extends StatelessWidget {
  final int itemCount;
  final IndexedWidgetBuilder itemBuilder;
  final int crossAxisCount;
  final double mainAxisSpacing;
  final double crossAxisSpacing;
  final EdgeInsetsGeometry? padding;
  final ScrollPhysics? physics;
  final bool shrinkWrap;

  const AnimatedGridWrapper({
    super.key,
    required this.itemCount,
    required this.itemBuilder,
    required this.crossAxisCount,
    this.mainAxisSpacing = 8.0,
    this.crossAxisSpacing = 8.0,
    this.padding,
    this.physics,
    this.shrinkWrap = false,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationLimiter(
      child: GridView.builder(
        padding: padding,
        physics: physics,
        shrinkWrap: shrinkWrap,
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: mainAxisSpacing,
          crossAxisSpacing: crossAxisSpacing,
        ),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          return AnimationConfiguration.staggeredGrid(
            position: index,
            duration: const Duration(milliseconds: 375),
            columnCount: crossAxisCount,
            child: ScaleAnimation(
              child: FadeInAnimation(child: itemBuilder(context, index)),
            ),
          );
        },
      ),
    );
  }
}

/// Custom animation untuk fade in dari bottom
class FadeInFromBottom extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FadeInFromBottom({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.synchronized(
      duration: duration,
      child: SlideAnimation(
        verticalOffset: 50.0,
        delay: delay,
        child: FadeInAnimation(delay: delay, child: child),
      ),
    );
  }
}

/// Custom animation untuk scale in
class ScaleInAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const ScaleInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.synchronized(
      duration: duration,
      child: ScaleAnimation(
        delay: delay,
        child: FadeInAnimation(delay: delay, child: child),
      ),
    );
  }
}

/// Custom animation untuk flip in
class FlipInAnimation extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Duration delay;

  const FlipInAnimation({
    super.key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.delay = Duration.zero,
  });

  @override
  Widget build(BuildContext context) {
    return AnimationConfiguration.synchronized(
      duration: duration,
      child: FlipAnimation(
        delay: delay,
        child: FadeInAnimation(delay: delay, child: child),
      ),
    );
  }
}
