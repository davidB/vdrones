library auth;

import 'dart:html';
import 'dart:async';
import 'package:google_oauth2_client/google_oauth2_browser.dart' as oauth;
import 'events.dart';
import 'cfg.dart' as cfg;

class SignEvent {
  bool logged = false;
  oauth.OAuth2 auth;
}

class UiSign {
  var bus;
  var autoLogin = false;
  final _selector = ".gplus_signin";
  var _im = true;

  final auth = new oauth.GoogleOAuth2(
      cfg.OAUTH2_CLIENT_ID,
      cfg.DATA_SCOPES,
      autoLogin: false
  );

  init() {
    querySelectorAll(_selector).map((Element e) => e.onClick.listen((_) => _toggleSign())).toList(growable: false);
    if (autoLogin) {
      auth.login(immediate: _im).then((_) => _displayAction());
      _displayWIP();
    }
    _displayAction();
  }

  _toggleSign() {
    if (auth.token == null || auth.token.expired) {
      auth.login(immediate: _im).then((_) => _displayAction());
      _displayWIP();
      _im = false;
    } else {
      _im = false;
      auth.logout();
      _displayAction();
    }
  }

  _displayAction() {
    bus.fire(eventAuth, new Auth()
      ..auth = auth
      ..logged = (auth.token != null)
    );
    var txt = (auth.token == null || auth.token.expired) ? "Sign in" : "Sign out";
    querySelectorAll(_selector + " .buttonText").forEach((e) {
      e.text = txt;
      e.parent.disabled = false;
    });
  }

  _displayWIP() {
    querySelectorAll(_selector + " .buttonText").forEach((e) {
      e.text = "...";
      e.parent.disabled = true;
    });
  }
}