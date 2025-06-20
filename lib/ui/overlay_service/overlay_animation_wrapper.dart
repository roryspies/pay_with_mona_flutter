// ignore_for_file: deprecated_member_use

import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/ui/overlay_service/overlay_service.dart';

class OverlayAnimationWrapper extends StatefulWidget {
  const OverlayAnimationWrapper({
    required this.child,
    required this.onClose,
    super.key,
    this.isDismissible = true,
  });

  final Widget child;
  final VoidCallback onClose;
  final bool isDismissible;

  @override
  State<OverlayAnimationWrapper> createState() =>
      _OverlayAnimationWrapperState();
}

class _OverlayAnimationWrapperState extends State<OverlayAnimationWrapper>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _blurAnimation;
  late final Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(
        milliseconds: 150,
      ),
    );

    _blurAnimation = Tween<double>(
      begin: 0.0,
      end: 2.0,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _slideAnimation = Tween<Offset>(
      begin: const Offset(
        0,
        0.1,
      ),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    // Assign the close logic to the service's callback
    overlayService.closeCallback = _animateClose;

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _animateClose() {
    _controller.reverse().whenComplete(() {
      // Call the original onClose callback passed from the show method
      widget.onClose();
      // Actually remove the overlay from the tree
      overlayService.removeOverlay();
    });
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      // Handle Android back button
      onWillPop: () async {
        if (widget.isDismissible) {
          _animateClose();
        }
        return false; // Prevent default back navigation
      },

      ///
      child: GestureDetector(
        onTap: widget.isDismissible ? _animateClose : null,
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return BackdropFilter(
              filter: ImageFilter.blur(
                sigmaX: _blurAnimation.value,
                sigmaY: _blurAnimation.value,
              ),
              child: Container(
                color: MonaColors.textHeading.withOpacity(0.2),
                child: child,
              ),
            );
          },
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              child: GestureDetector(
                onTap: () {},
                child: SlideTransition(
                  position: _slideAnimation,
                  child: FadeTransition(
                    opacity: _controller,
                    child: widget.child,
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
