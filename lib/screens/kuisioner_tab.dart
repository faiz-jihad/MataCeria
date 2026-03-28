import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../widgets/custom_loading_indicator.dart';

class KuisionerTab extends StatefulWidget {
  const KuisionerTab({super.key});

  @override
  State<KuisionerTab> createState() => _KuisionerTabState();
}

class _KuisionerTabState extends State<KuisionerTab> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            // Update loading bar.
          },
          onPageStarted: (String url) {
            setState(() => _isLoading = true);
          },
          onPageFinished: (String url) {
            setState(() => _isLoading = false);
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('WEB_VIEW_ERROR: ${error.description}');
          },
        ),
      )
      ..loadRequest(
        Uri.parse(
          'https://docs.google.com/forms/d/e/1FAIpQLSfCZgxzNRaoZv5U6QIKx_xUoBk4ekO69EcjKIIiPxxdxCyqtg/viewform',
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Kuisioner MataCeria',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CustomLoadingIndicator()),
        ],
      ),
    );
  }
}
