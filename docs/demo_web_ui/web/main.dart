import 'dart:js_interop';

import 'package:demo_web_ui/ptid_dropdown.dart';
import 'package:demo_web_ui/settings.dart';
import 'package:web/web.dart' as web;

void main() {
  const rootUrl = String.fromEnvironment('RUST_SERVER');
  print('RUST_SERVER: $rootUrl');
  var settings = Settings.defaultSettings();
  final isoDropdown = web.document.querySelector('#iso-dropdown')!;
  final isoButton =
      web.document.querySelector('#iso-button') as web.HTMLButtonElement;
  final isoValue = web.document.querySelector('#iso-value')!;
  final isoMenu = web.document.querySelector('#iso-menu')!;
  final locationSearch =
      web.document.querySelector('#location-search') as web.HTMLInputElement;
  final locationDropdown = web.document.querySelector('#location-dropdown')!;
  final locationResults = web.document.querySelector('#location-results')!;
  final status = web.document.querySelector('#location-status')!;

  var selectedIso = settings.iso;
  var locations = <String>[];
  var request = 0;
  var activeLocation = -1;

  void showIsos(bool show) {
    isoDropdown.classList.toggle('is-active', show);
    isoButton.setAttribute('aria-expanded', '$show');
  }

  void focusIso(int index) {
    final options = isoMenu.querySelectorAll('[role="option"]');
    for (var i = 0; i < options.length; i++) {
      final option = options.item(i) as web.HTMLElement;
      option.classList.toggle('is-active', i == index);
      if (i == index) option.focus();
    }
  }

  void showLocations(bool show) {
    locationDropdown.classList.toggle('is-active', show);
    locationSearch.setAttribute('aria-expanded', '$show');
    if (!show) {
      activeLocation = -1;
      locationSearch.removeAttribute('aria-activedescendant');
    }
  }

  void selectLocation(String location) {
    locationSearch.value = location;
    locationSearch.focus();
    showLocations(false);
  }

  void renderLocations() {
    locationResults.textContent = '';
    activeLocation = -1;
    locationSearch.removeAttribute('aria-activedescendant');
    final query = locationSearch.value.trim().toLowerCase();
    final matches = locations.where(
      (location) => location.toLowerCase().contains(query),
    );
    var count = 0;
    for (final location in matches) {
      final item =
          web.document.createElement('button') as web.HTMLButtonElement;
      item.type = 'button';
      item.tabIndex = -1;
      item.id = 'location-option-${count++}';
      item.className = 'dropdown-item';
      item.setAttribute('role', 'option');
      item.setAttribute('aria-selected', 'false');
      item.textContent = location;
      item.addEventListener(
        'click',
        ((web.Event event) {
          selectLocation(location);
        }).toJS,
      );
      locationResults.append(item);
    }
    if (count == 0) {
      final message = web.document.createElement('div');
      message.className = 'dropdown-item has-text-grey';
      message.textContent = 'No matching locations';
      locationResults.append(message);
    }
  }

  Future<void> selectIso(String iso) async {
    final currentRequest = ++request;
    selectedIso = iso;
    isoValue.textContent = iso;
    final options = isoMenu.querySelectorAll('[role="option"]');
    for (var i = 0; i < options.length; i++) {
      final option = options.item(i) as web.HTMLElement;
      option.setAttribute('aria-selected', '${option.textContent == iso}');
    }
    showLocations(false);
    locationSearch.disabled = true;
    locationSearch.value = '';
    locationResults.textContent = '';
    locations = [];

    if (iso != 'ISONE' && iso != 'NYISO') {
      status.textContent = 'Locations for $iso are not available yet.';
      return;
    }
    if (rootUrl.isEmpty) {
      status.textContent = 'Set RUST_SERVER before starting the demo.';
      return;
    }

    status.textContent = 'Loading locations...';
    try {
      final result = await getPtids(iso: iso, rootUrl: rootUrl);
      if (currentRequest != request) return;
      locations = result;
      locationSearch.disabled = locations.isEmpty;
      if (iso == settings.iso && locations.contains(settings.location)) {
        locationSearch.value = settings.location;
      }
      status.textContent = locations.isEmpty ? 'No locations available.' : '';
      renderLocations();
    } catch (error, stackTrace) {
      if (currentRequest != request) return;
      status.textContent = 'Unable to load locations: $error';
      print('Unable to load locations: $error\n$stackTrace');
    }
  }

  for (final iso in Settings.allIsos) {
    final option =
        web.document.createElement('button') as web.HTMLButtonElement;
    option.type = 'button';
    option.tabIndex = -1;
    option.className = 'dropdown-item';
    option.setAttribute('role', 'option');
    option.setAttribute('aria-selected', '${iso == selectedIso}');
    option.textContent = iso;
    option.addEventListener(
      'click',
      ((web.Event event) {
        showIsos(false);
        isoButton.focus();
        if (iso != selectedIso) selectIso(iso);
      }).toJS,
    );
    isoMenu.append(option);
  }
  isoButton.addEventListener(
    'click',
    ((web.Event event) {
      final show = !isoDropdown.classList.contains('is-active');
      showIsos(show);
      if (show) focusIso(Settings.allIsos.indexOf(selectedIso));
    }).toJS,
  );
  isoButton.addEventListener(
    'keydown',
    ((web.Event event) {
      final key = (event as web.KeyboardEvent).key;
      if (key == 'ArrowDown' || key == 'ArrowUp') {
        event.preventDefault();
        showIsos(true);
        focusIso(Settings.allIsos.indexOf(selectedIso));
      }
    }).toJS,
  );
  isoMenu.addEventListener(
    'keydown',
    ((web.Event event) {
      final key = (event as web.KeyboardEvent).key;
      if (key == 'Escape') {
        event.preventDefault();
        showIsos(false);
        isoButton.focus();
        return;
      }
      if (key != 'ArrowDown' && key != 'ArrowUp' &&
          key != 'Home' && key != 'End') return;
      event.preventDefault();
      final current = Settings.allIsos.indexOf(
        (web.document.activeElement as web.HTMLElement).textContent!,
      );
      final index = switch (key) {
        'Home' => 0,
        'End' => Settings.allIsos.length - 1,
        'ArrowDown' => (current + 1).clamp(0, Settings.allIsos.length - 1),
        _ => (current - 1).clamp(0, Settings.allIsos.length - 1),
      };
      focusIso(index);
    }).toJS,
  );
  isoDropdown.addEventListener(
    'focusout',
    ((web.Event event) {
      final next = (event as web.FocusEvent).relatedTarget;
      if (!isoDropdown.contains(next as web.Node?)) showIsos(false);
    }).toJS,
  );
  locationSearch.addEventListener(
    'input',
    ((web.Event event) {
      renderLocations();
      showLocations(true);
    }).toJS,
  );
  locationSearch.addEventListener(
    'focus',
    ((web.Event event) {
      renderLocations();
      showLocations(true);
    }).toJS,
  );
  locationSearch.addEventListener(
    'click',
    ((web.Event event) {
      if (!locationDropdown.classList.contains('is-active')) {
        renderLocations();
        showLocations(true);
      }
    }).toJS,
  );
  locationSearch.addEventListener(
    'keydown',
    ((web.Event event) {
      final key = (event as web.KeyboardEvent).key;
      if (key == 'Escape' && locationDropdown.classList.contains('is-active')) {
        event.preventDefault();
        showLocations(false);
        return;
      }
      if (key == 'Enter' && activeLocation >= 0) {
        event.preventDefault();
        final item = locationResults.querySelector('#location-option-$activeLocation')!;
        selectLocation(item.textContent!);
        return;
      }
      if (key != 'ArrowDown' && key != 'ArrowUp') return;
      if (!locationDropdown.classList.contains('is-active')) {
        renderLocations();
        showLocations(true);
      }
      final items = locationResults.querySelectorAll('[role="option"]');
      if (items.length == 0) return;
      event.preventDefault();
      if (activeLocation >= 0) {
        final previous = items.item(activeLocation) as web.HTMLElement;
        previous.classList.remove('is-active');
        previous.setAttribute('aria-selected', 'false');
      }
      activeLocation = key == 'ArrowDown'
          ? (activeLocation + 1).clamp(0, items.length - 1)
          : (activeLocation < 0 ? items.length - 1 : activeLocation - 1)
                .clamp(0, items.length - 1);
      final item = items.item(activeLocation) as web.HTMLElement;
      item.classList.add('is-active');
      item.setAttribute('aria-selected', 'true');
      locationSearch.setAttribute('aria-activedescendant', item.id);
      item.scrollIntoView(web.ScrollIntoViewOptions(block: 'nearest'));
    }).toJS,
  );
  web.document.addEventListener(
    'click',
    ((web.Event event) {
      if (!isoDropdown.contains(event.target as web.Node?)) {
        showIsos(false);
      }
      if (!locationDropdown.contains(event.target as web.Node?)) {
        showLocations(false);
      }
    }).toJS,
  );
  selectIso(selectedIso);
}
