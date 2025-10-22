import 'dart:html';

class DisposableWindow {
  DivElement? inner, content;
  ButtonElement? close;

  /// A disposable window.
  DisposableWindow(this.content) {
    close = ButtonElement()
      ..setAttribute('type', 'button')
      ..setAttribute('class', 'btn btn-outline-light text-dark material-icons')
      ..setAttribute('style', 'float: right;')
      ..text = 'close';

    /// close the window
    close!.onClick.listen((event) {
      inner!.children.clear();
    });

    content!.onKeyDown.listen((event) {
      event.preventDefault();

      /// close the window if you press Esc while mouse is on the content
      if (event.key == 'Escape') {
        inner!.children.clear();
      }
    });

    inner = DivElement()
      ..children = [
        close!,
        BRElement(),
        BRElement(),
        content!..tabIndex = -1, // make it focusable
      ];
  }
}
