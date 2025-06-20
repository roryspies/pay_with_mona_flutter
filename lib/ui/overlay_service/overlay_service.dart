// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:pay_with_mona/ui/overlay_service/overlay_animation_wrapper.dart';

// Assume you have a global navigator key like this
// final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

final overlayService = OverlayService();

class OverlayService {
  factory OverlayService() => _instance;
  OverlayService._internal();
  static final OverlayService _instance = OverlayService._internal();

  OverlayEntry? _overlayEntry;
  // A callback to trigger the exit animation
  VoidCallback? closeCallback;

  /// Shows a modal with a blurred background.
  ///
  /// [modalContent] is the widget to be displayed inside the modal.
  /// [isDismissible] determines if the modal can be closed by tapping the background.
  /// [whenComplete] is a callback executed after the modal is fully dismissed.
  void show(
    BuildContext callingContext, {
    required Widget modalContent,
    bool isDismissible = true,
    VoidCallback? whenComplete,
  }) {
    // Prevent multiple overlays
    if (_overlayEntry != null) {
      hide();
    }

    // A context from the navigator key is more reliable
    final overlayState = Overlay.of(callingContext);

    // Create the overlay entry
    _overlayEntry = OverlayEntry(
      builder: (context) {
        return OverlayAnimationWrapper(
          onClose: () {
            hide(onClosed: whenComplete);
          },
          isDismissible: isDismissible,
          child: modalContent,
        );
      },
    );

    // This callback will be triggered by the wrapper to start the exit animation
    closeCallback = () {
      // This is handled internally by the wrapper now
    };

    overlayState.insert(_overlayEntry!);
  }

  /// Hides the currently showing modal.
  ///
  /// [onClosed] is an optional callback that runs after the modal is hidden.
  /// It overrides the original `whenComplete` from the `show` method.
  void hide({VoidCallback? onClosed}) {
    if (closeCallback != null) {
      closeCallback!();
      closeCallback = null; // Prevent multiple calls
    }
  }

  // Removes the entry from the tree. This is now an internal detail.
  void removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  /// Checks if the modal is currently visible on screen.
  bool get isShowing => _overlayEntry != null;
}
