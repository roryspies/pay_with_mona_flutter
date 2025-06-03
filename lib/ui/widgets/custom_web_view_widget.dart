// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:pay_with_mona/src/utils/mona_colors.dart';
import 'package:pay_with_mona/src/widgets/flowing_progress_bar.dart';
import 'package:pay_with_mona/ui/utils/extensions.dart';
import 'package:pay_with_mona/ui/utils/size_config.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class CustomWebView extends StatefulWidget {
  final String initialUrl;
  final String? title;
  final bool showAppBar;
  final bool showNavigationControls;
  final bool showRefreshButton;
  final bool enableJavaScript;
  final bool enableDomStorage;
  final bool enableZoom;
  final Color? primaryColor;
  final Function(String)? onUrlChanged;
  final Function(String)? onPageStarted;
  final Function(String)? onPageFinished;
  final Function(WebResourceError)? onWebResourceError;
  final Set<String>? allowedDomains;
  final Map<String, String>? customHeaders;

  const CustomWebView({
    super.key,
    required this.initialUrl,
    this.title,
    this.showAppBar = true,
    this.showNavigationControls = true,
    this.showRefreshButton = true,
    this.enableJavaScript = true,
    this.enableDomStorage = true,
    this.enableZoom = true,
    this.primaryColor,
    this.onUrlChanged,
    this.onPageStarted,
    this.onPageFinished,
    this.onWebResourceError,
    this.allowedDomains,
    this.customHeaders,
  });

  @override
  State<CustomWebView> createState() => _CustomWebViewState();
}

class _CustomWebViewState extends State<CustomWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;
  bool _hasError = false;
  String _currentUrl = '';
  double _loadingProgress = 0.0;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.initialUrl;
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(widget.enableJavaScript
          ? JavaScriptMode.unrestricted
          : JavaScriptMode.disabled)
      ..setBackgroundColor(Colors.white)
      ..enableZoom(widget.enableZoom)
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            setState(() {
              _loadingProgress = progress / 100.0;
            });
          },
          onPageStarted: (String url) {
            "Custom Web View ::: onPageStarted ::: $url".log();
            setState(() {
              _isLoading = true;
              _hasError = false;
              _currentUrl = url;
            });
            widget.onPageStarted?.call(url);
          },
          onPageFinished: (String url) {
            "Custom Web View ::: onPageFinished ::: $url".log();
            setState(() {
              _isLoading = false;
              _currentUrl = url;
            });
            widget.onPageFinished?.call(url);
          },
          onWebResourceError: (WebResourceError error) {
            "Custom Web View ::: onWebResourceError ::: ${error.description}"
                .log();

            setState(() {
              _isLoading = false;
              _hasError = true;
            });
            widget.onWebResourceError?.call(error);
          },
          onNavigationRequest: (NavigationRequest request) {
            "Custom Web View ::: onNavigationRequest ::: ${request.url}".log();
            /* // Check if domain is allowed
            if (widget.allowedDomains != null) {
              final uri = Uri.parse(request.url);
              final domain = uri.host;
              if (!widget.allowedDomains!
                  .any((allowed) => domain.contains(allowed))) {
                _launchExternalUrl(request.url);
                return NavigationDecision.prevent;
              }
            }

            // Handle external links
            if (request.url.startsWith('tel:') ||
                request.url.startsWith('mailto:') ||
                request.url.startsWith('sms:')) {
              _launchExternalUrl(request.url);
              return NavigationDecision.prevent;
            } */

            widget.onUrlChanged?.call(request.url);
            return NavigationDecision.navigate;
          },
        ),
      );

    // Load initial URL with custom headers if provided
    if (widget.customHeaders != null) {
      _controller.loadRequest(
        Uri.parse(widget.initialUrl),
        headers: widget.customHeaders!,
      );
    } else {
      _controller.loadRequest(Uri.parse(widget.initialUrl));
    }
  }

/* 
  Future<void> _launchExternalUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
 */
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: context.screenHeight * 0.8,
      width: double.infinity,
      child: Column(
        children: [
          /// ***
          AnimatedSwitcher(
            duration: Duration(milliseconds: 500),
            child: switch (_isLoading) {
              true => FlowingProgressBar(
                  baseColor: MonaColors.successColour.withOpacity(0.2),
                  flowColor: MonaColors.successColour,
                ),
              false => SizedBox.shrink(),
            },
          ),

          Expanded(
            child: AnimatedSwitcher(
              duration: Duration(
                milliseconds: 500,
              ),
              child: switch (_hasError) {
                true => _buildErrorWidget(),
                false => WebViewWidget(
                    controller: _controller,
                  ),
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.error_outline,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            'Failed to load page',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Check your internet connection and try again',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _controller.reload(),
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
            style: ElevatedButton.styleFrom(
              backgroundColor:
                  widget.primaryColor ?? Theme.of(context).primaryColor,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
