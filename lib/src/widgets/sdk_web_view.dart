import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// A full-screen WebView page that you can push via Navigator.
/// When the user taps the Close button (or presses Android back),
/// it pops the route, returning to your app.
///
/// Usage:
/// ```dart
/// Navigator.push(
///   context,
///   MaterialPageRoute(
///     builder: (_) => PaymentWebViewPage(initialUrl: url),
///   ),
/// );
/// ```
///
///
///

class SDKWebView extends StatefulWidget {
  final String initialUrl;
  const SDKWebView({
    super.key,
    required this.initialUrl,
  });

  @override
  State<SDKWebView> createState() => _SDKWebViewState();
}

class _SDKWebViewState extends State<SDKWebView> {
  late final WebViewController _controller;
  bool _canGoBack = false;

  @override
  void initState() {
    super.initState();
    // Initialize the controller; on Android it uses Hybrid Composition
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) => setState(() {}),
          onPageFinished: (_) async {
            final canGoBack = await _controller.canGoBack();
            setState(() => _canGoBack = canGoBack);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.initialUrl));
  }

  Future<bool> _onWillPop() async {
    // If the WebView can go back, navigate back in-page first
    if (_canGoBack) {
      _controller.goBack();
      return false;
    }
    // Otherwise, pop this route
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Payment'),
          leading: IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ),
        body: WebViewWidget(controller: _controller),
      ),
    );
  }
}
