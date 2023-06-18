import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebViewScreen extends StatefulWidget {
  final String url;

  const WebViewScreen(this.url, {super.key});

  @override
  // ignore: library_private_types_in_public_api
  _WebViewScreenState createState() => _WebViewScreenState();
}

class _WebViewScreenState extends State<WebViewScreen> {
  final _key = GlobalKey<WebViewContainerState>();

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        body: WebViewContainer(key: _key, url: widget.url),
      ),
    );
  }
}

class WebViewContainer extends StatefulWidget {
  final String url;

  const WebViewContainer({Key? key, required this.url}) : super(key: key);

  @override
  WebViewContainerState createState() => WebViewContainerState();
}

class WebViewContainerState extends State<WebViewContainer> {
  bool isLoading = true;
  late InAppWebViewController inAppWebViewController;
  double _progress = 0;

  @override
  Widget build(BuildContext context) {
    return Stack(children: [
      InAppWebView(
        initialUrlRequest: URLRequest(url: Uri.parse(widget.url)),
        onWebViewCreated: (InAppWebViewController controller) {
          inAppWebViewController = controller;
        },
        onProgressChanged: (InAppWebViewController controller, int progress) {
          setState(() {
            _progress = progress / 100;
          });
        },
      ),
      _progress < 1
          // ignore: avoid_unnecessary_containers
          ? Container(
              child: LinearProgressIndicator(
                value: _progress,
              ),
            )
          : const SizedBox(),
    ]);
  }
}
