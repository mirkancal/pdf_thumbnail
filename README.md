# Pdf Thumbnail

[![style: very good analysis][very_good_analysis_badge]][very_good_analysis_link]
[![Powered by Mason](https://img.shields.io/endpoint?url=https%3A%2F%2Ftinyurl.com%2Fmason-badge)](https://github.com/felangel/mason)
[![License: MIT][license_badge]][license_link]

Thumbnail viewer for pdfs

## Installation 💻

**❗ In order to start using Pdf Thumbnail you must have the [Flutter SDK][flutter_install_link] installed on your machine.**

Add `pdf_thumbnail` to your `pubspec.yaml`:

```yaml
dependencies:
  pdf_thumbnail:
```

Install it:

```sh
flutter packages get
```

## Example ✍️
```dart
 return Stack(
              children: [
                SizedBox(
                  height: MediaQuery.of(context).size.height,
                  width: MediaQuery.of(context).size.width,
                  child: PdfViewer(
                    filePath: snapshot.data!.path,
                  ),
                ),
                if (showThumbnail)
                  Positioned(
                    bottom: 0,
                    width: MediaQuery.of(context).size.width,
                    // Here's the thumbnail widget.
                    child: PdfThumbnail.fromFile(snapshot.data!.path),
                  ),
              ],
            );
```

There is a detailed example app in the repo, but I've deleted iOS and Android folders.
Simple go to example folder, and run `flutter create .` inside the folder to add missing native files for the example app.

Demo

<!-- ![screenshot] -->

![gif]

## Caching ⏲
I left caching part unopinionated to keep the package simple. Just create your own class from `ImageThumbnailCacher` and implement the `read/write` methods.
Holding images as Uint8List, so `Map<int, Uint8List>` is what's need to be written to and read from the cache. It maps page numbers to the images.

```dart
class ThumbnailCacher implements ImageThumbnailCacher {
  @override
  Future<PageToImage?> read(String id) async {
    return api.localStorage.readThumbnails(id);
  }

  @override
  Future<bool> write({required String id, required PageToImage map}) {
    return api.localStorage.writeThumbnails(id: id, map: map);
  }
}
```
I'm using Hive to cache.

## Roadmap 🗺️


- [X] Customization for colors, decoration etc.
- [X] onTap callback and page number.
- [X] Caching.
- [ ] Different layouts and scroll axises.
- [ ] Lazy loading.


[flutter_install_link]: https://docs.flutter.dev/get-started/install
[github_actions_link]: https://docs.github.com/en/actions/learn-github-actions
[license_badge]: https://img.shields.io/badge/license-MIT-blue.svg
[license_link]: https://opensource.org/licenses/MIT
[logo_black]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_black.png#gh-light-mode-only
[logo_white]: https://raw.githubusercontent.com/VGVentures/very_good_brand/main/styles/README/vgv_logo_white.png#gh-dark-mode-only
[mason_link]: https://github.com/felangel/mason
[very_good_analysis_badge]: https://img.shields.io/badge/style-very_good_analysis-B22C89.svg
[very_good_analysis_link]: https://pub.dev/packages/very_good_analysis
[very_good_cli_link]: https://pub.dev/packages/very_good_cli
[very_good_coverage_link]: https://github.com/marketplace/actions/very-good-coverage
[very_good_ventures_link]: https://verygood.ventures
[very_good_ventures_link_light]: https://verygood.ventures#gh-light-mode-only
[very_good_ventures_link_dark]: https://verygood.ventures#gh-dark-mode-only
[very_good_workflows_link]: https://github.com/VeryGoodOpenSource/very_good_workflows
[screenshot]: https://ucarecdn.com/53fdf6c0-a1ce-4513-af9e-ab9ec2f2b842/-/preview/1000x400/-/format/auto/-/quality/smart_retina/
[gif]: https://media.giphy.com/media/D58yM6RFV1AOxV8Y86/giphy.gif