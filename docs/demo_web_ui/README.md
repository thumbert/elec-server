# Experiments with Dart on the web

Uses [`package:web`](https://pub.dev/packages/web)
to interop with JS and the DOM, and [Bulma](https://bulma.io/) for styling.
Bulma does not require JavaScript.

## Running and building

If you don't have `webdev` installed, do `dart install webdev` first. 

```bash
cd docs/demo_web_ui
./serve.sh
```

When you are done editing, to publish the report, do:
```bash
rm -r "/home/adrian/Software/Apps/public/docs/projects/demo_web_ui"
cp -r "/home/adrian/Documents/repos/git/thumbert/elec-server/docs/demo_web_ui/web" /home/adrian/Software/Apps/public/docs/projects/demo_web_ui
```


To run the app,
activate and use [`package:webdev`](https://dart.dev/tools/webdev):

To learn how to interop with web APIs and other JS libraries,
check out https://dart.dev/interop/js-interop.
