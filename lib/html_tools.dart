library html_tools;

import 'dart:html';
import 'dart:async';
import 'effects.dart';

const uriPolicyAll = const _UriPolicyAll();

interpolate(String tmpl, Map kv) {
  var from = new RegExp(r'\$\{([^}]*)\}');
  return tmpl.replaceAllMapped(from, (x) => findValue(kv, x.group(1)));
}

findValue(Map kv, String k) {
  if (kv.containsKey(k)) return kv[k];
  var ks = k.split(".");
  return ks.fold(kv, (v, k) => v[k]);
}

class _UriPolicyAll implements UriPolicy{
  const _UriPolicyAll();
  bool allowsUri(String uri) => true;
}

class MicroTemplate {
  var _tmpl = null;
  var _tmplParent = null;

  /// eg : tmpl = querySelector("script.ach")
  MicroTemplate(Element tmpl) {
    _tmplParent = tmpl.parent;
    //_tmplAchievements = _tmplAchievementsParent.innerHtml;
    _tmpl = (tmpl.tagName.toLowerCase() == "script") ? tmpl.text : tmpl.outerHtml;
    _tmplParent.setInnerHtml('');
  }

  apply(Iterable<Map> items, [uriPolicy = uriPolicyAll]) {
    _tmplParent.setInnerHtml(
      items.fold("", (acc, item) => acc + (interpolate(_tmpl, item))),
      validator: new NodeValidator(uriPolicy: uriPolicy)
    );
  }
}

String findBaseUrl() {
  String location = window.location.pathname;
  int slashIndex = location.lastIndexOf('/');
  if (slashIndex < 0) {
    return '/';
  } else {
    return location.substring(0, slashIndex);
  }
}

Iterable<Future<Element>> loadDataSvgs(){
  return document.querySelectorAll("[data-svg-src]").map((el){
    var src = el.dataset["svgSrc"];
    return HttpRequest.request(src, responseType : 'document').then((httpRequest){
      var doc = httpRequest.responseXml;
      var child = doc.documentElement.clone(true);
      // to fill parent el and keep original ratio of the image
      child.attributes.remove("width");
      child.attributes.remove("height");
      child.style.width = "100%";
      child.style.height = "100%";
      el.append(child);
      return child;
    });
  }).toList(growable: false); // to list is called to force execution of the map function (the function map() is lazy in Dart)
}

/**
 * [UiDropdown] aligns closely with the model provided by the
 * [dropdown functionality](http://twitter.github.com/bootstrap/javascript.html#dropdowns)
 * in Bootstrap.
 *
 * [UiDropdown] content is inferred from all child elements that have
 * class `dropdown-menu`. Bootstrap defines a CSS selector for `.dropdown-menu`
 * with an initial display of `none`.
 *
 * [UiDropdown] listens for `click` events and toggles visibility of content if the
 * click target has attribute `data-toggle="dropdown"`.
 *
 * Bootstrap also defines a CSS selector which sets `display: block;` for elements
 * matching `.open > .dropdown-menu`. When [XDropdown] opens, the class `open` is
 * added to the inner element wrapping all content. Causing child elements with
 * class `dropdown-menu` to become visible.
 */
class UiDropdown {
  static final ShowHideEffect _effect = new ScaleEffect(orientation: Orientation.VERTICAL, yOffset : VerticalAlignment.TOP);
  static const int _duration = 100;

  static void bind(Element e) {
    e.querySelectorAll("[is=x-dropdown]").forEach((el){
      el.querySelector(".dropdown-toggle").onClick.listen(_onClick);
      el.onKeyDown.listen(_onKeyDown);
      _apply(el, ShowHideAction.HIDE);
    });
  }

  static void _onKeyDown(KeyboardEvent evt) {
    final Element target = evt.target;
    if(!evt.defaultPrevented && evt.keyCode == KeyCode.ESC) {
      _apply(target, ShowHideAction.HIDE);
      evt.preventDefault();
    }
  }

  static void _onClick(MouseEvent evt) {
    final Element target = evt.currentTarget;
    if(!evt.defaultPrevented && target != null) {
      _apply(target.parent, ShowHideAction.TOGGLE);
      evt.preventDefault();
      target.focus();
    }
  }

  static void _apply(e, ShowHideAction action) {
    final headerElement = e.querySelector('[is=x-dropdown] > .dropdown');
    if(headerElement != null) {
      switch(action) {
        case ShowHideAction.HIDE:
          headerElement.classes.remove('open');
          break;
        case ShowHideAction.SHOW:
          headerElement.classes.add('open');
          break;
        case ShowHideAction.TOGGLE:
          headerElement.classes.remove('open');
          break;
      }
    }
    final contentDiv = e.querySelector('[is=x-dropdown] > .dropdown-menu');
    if(contentDiv != null) {
      ShowHide.begin(action, contentDiv, effect: _effect);
    }
  }
}