A bare-bones Dart web app.

Uses [`package:web`](https://pub.dev/packages/web)
to interop with JS and the DOM.

## Running and building

If you don't have `webdev` installed, do `dart install webdev` first. 

```bash
cd docs/hq_water
webdev serve --auto=refresh web:9321
```

When you are done editing, to publish the report, do:
```bash
rm -r "/home/adrian/Software/Apps/public/docs/projects/hq_water"
cp -r "/home/adrian/Documents/repos/git/thumbert/elec-server/docs/hq_water/web" /home/adrian/Software/Apps/public/docs/projects/hq_water
```


To run the app,
activate and use [`package:webdev`](https://dart.dev/tools/webdev):

To learn how to interop with web APIs and other JS libraries,
check out https://dart.dev/interop/js-interop.
