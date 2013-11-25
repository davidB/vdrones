library html_tools;

import 'dart:html';
import 'effects.dart';


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