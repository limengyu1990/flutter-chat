
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutterchat/core/i10n/i10n.dart';
import 'package:flutterchat/core/services/localstorage_service.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../locator.dart';

class AuthWebView extends StatelessWidget {
  final String authType;
  final String session;
  final Function onAuthDone;

  const AuthWebView(this.authType, this.session, this.onAuthDone);

  @override
  Widget build(BuildContext context) {
    final localStorage = locator<LocalStorageService>();

    final url =
        '/_matrix/client/r0/auth/$authType/fallback/web?session=$session' +
            localStorage.user.homeServer;
    if (kIsWeb) launch(url);
    return Scaffold(
      appBar: AppBar(
        title: Text(L10n.of(context).authentication),
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            Navigator.of(context).pop();
            onAuthDone();
          },
        ),
      ),
      body: Column(
        children: <Widget>[
          LinearProgressIndicator(),
          Expanded(
            child: kIsWeb
                ? Center(child: Icon(Icons.link))
                : WebView(
              initialUrl: url,
              javascriptMode: JavascriptMode.unrestricted,
            ),
          ),
        ],
      ),
    );
  }
}
