library ui2.selector_load_spec;

import 'dart:html' as html;

class LoadSpecSelector {
  html.Element wrapper, inner;

  html.InputElement _entityRadio, _assetIdRadio;


  LoadSpecSelector(this.wrapper) {
    inner = html.DivElement()
      ..className = 'd-block my-2';

    var _radioEntity = html.DivElement()
      ..className = 'custom-control custom-radio';
    _entityRadio = html.RadioButtonInputElement()
      ..name = '_loadspec_'
      ..id = 'entity'
      ..className = 'custom-control-input'
      ..checked = true
      ..required = true;


    _assetIdRadio = html.RadioButtonInputElement()
      ..name = '_loadspec_'
      ..id = 'assetId'
      ..className = 'custom-control-input'
      ..required = true;

    inner.children.addAll([_entityRadio, _assetIdRadio]);

    wrapper.children.add(inner);
  }

}