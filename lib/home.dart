import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'package:html/dom.dart' as dom;
import 'package:webview_windows/webview_windows.dart';

final navigatorKey = GlobalKey<NavigatorState>();

class ExampleBrowser extends StatefulWidget {
  const ExampleBrowser({super.key});

  @override
  State<ExampleBrowser> createState() => _ExampleBrowser();
}

class _ExampleBrowser extends State<ExampleBrowser> {
  final _controller = WebviewController();
  final _textController = TextEditingController();
  bool _isWebviewSuspended = false;
  bool initController = false;

  @override
  void initState() {
    initPlatformState();
    super.initState();
  }

  Future<void> initPlatformState() async {
    try {
      await _controller.initialize();
      initController = true;
      _controller.url.listen((url) async {
        final response = await http.get(Uri.parse(url));
        dom.Document html = dom.Document.html(response.body);
        var bb = html
            .querySelectorAll("div.dd > ul > li > a.btn")
            .map((element) => element.innerHtml.trim())
            .toList();
        var cc = html
            .querySelectorAll("div.dd > ul > li > a.btn")
            .map((element) => element.attributes)
            .toList();
        print('_ExampleBrowser.initPlatformState innerHtml : $bb');
        print('_ExampleBrowser.initPlatformState attributes : $cc');
        _textController.text = url;
        _controller.addScriptToExecuteOnDocumentCreated(js).then((value) {
          print('_ExampleBrowser.initPlatformState id : $value');
          _controller.executeScript("console.log('화면 갱신 확인')");
          _controller.executeScript("alert('화면 갱신 확인')");
        });
      });

      await _controller.setBackgroundColor(Colors.transparent);
      await _controller.setPopupWindowPolicy(WebviewPopupWindowPolicy.deny);
      await _controller.loadUrl('https://flutter.dev');
      if (!mounted) return;
      setState(() {});

      _controller.webMessage.listen((event) {
        print('webMessage event : $event');
      });
    } on PlatformException catch (e) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        showDialog(
            context: context,
            builder: (_) => AlertDialog(
                  title: const Text('Error'),
                  content: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Code: ${e.code}'),
                      Text('Message: ${e.message}'),
                    ],
                  ),
                  actions: [
                    TextButton(
                      child: const Text('Continue'),
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                    )
                  ],
                ));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        tooltip: _isWebviewSuspended ? 'Resume webview' : 'Suspend webview',
        onPressed: () async {
          if (_isWebviewSuspended) {
            await _controller.resume();
          } else {
            await _controller.suspend();
          }
          setState(() {
            _isWebviewSuspended = !_isWebviewSuspended;
          });
        },
        child: Icon(_isWebviewSuspended ? Icons.play_arrow : Icons.pause),
      ),
      appBar: AppBar(
          title: StreamBuilder<String>(
        stream: _controller.title,
        builder: (context, snapshot) {
          return Text(
              snapshot.hasData ? snapshot.data! : 'WebView (Windows) Example');
        },
      )),
      body: Center(
        child: initController ? _webView() : const Text("초기화중"),
      ),
    );
  }


  Widget _webView() {
    if (!_controller.value.isInitialized) {
      return const Text(
        'Not Initialized',
        style: TextStyle(
          fontSize: 24.0,
          fontWeight: FontWeight.w900,
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Card(
            elevation: 0,
            child: Row(children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'URL',
                    contentPadding: EdgeInsets.all(10.0),
                  ),
                  textAlignVertical: TextAlignVertical.center,
                  controller: _textController,
                  onSubmitted: (val) {
                    _controller.loadUrl(val);
                  },
                ),
              ),

              /// 새로고침
              IconButton(
                icon: const Icon(Icons.refresh),
                splashRadius: 20,
                onPressed: () {
                  _controller.reload();
                },
              ),

              /// open devtools
              IconButton(
                icon: const Icon(Icons.developer_mode),
                tooltip: 'Open DevTools',
                splashRadius: 20,
                onPressed: () {
                  _controller.openDevTools();
                },
              ),

              /// open devtools
              ElevatedButton(
                  onPressed: () {
                    _controller.executeScript("JavaScriptChannel.postMessage('aaaa')");
                    _controller
                        .postWebMessage(json.encode({"cursorChanged": "test"}))
                        .then((value) {
                      print('postWebMessage value :');
                    });
                  },
                  child: const Text("이벤트 테스트"))
            ]),
          ),
          Expanded(
              child: Card(
                  color: Colors.transparent,
                  elevation: 0,
                  clipBehavior: Clip.antiAliasWithSaveLayer,
                  child: Stack(
                    children: [
                      Webview(
                        _controller,
                        permissionRequested: _onPermissionRequested,
                      ),
                      StreamBuilder<LoadingState>(
                          stream: _controller.loadingState,
                          builder: (context, snapshot) {
                            if (snapshot.hasData &&
                                snapshot.data == LoadingState.loading) {
                              return const LinearProgressIndicator();
                            } else {
                              return const SizedBox();
                            }
                          }),
                    ],
                  ))),
        ],
      ),
    );
  }

  Future<WebviewPermissionDecision> _onPermissionRequested(
      String url, WebviewPermissionKind kind, bool isUserInitiated) async {
    final decision = await showDialog<WebviewPermissionDecision>(
      context: navigatorKey.currentContext!,
      builder: (BuildContext context) => AlertDialog(
        title: const Text('WebView permission requested'),
        content: Text('WebView has requested permission \'$kind\''),
        actions: <Widget>[
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.deny),
            child: const Text('Deny'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, WebviewPermissionDecision.allow),
            child: const Text('Allow'),
          ),
        ],
      ),
    );

    return decision ?? WebviewPermissionDecision.none;
  }

  String js = '''
document.addEventListener("DOMSubtreeModified", onDetection);

function onDetection() {
  console.log('detectiosn');
  document.removeEventListener("DOMSubtreeModified", onDetection);
}
''';
}
