// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:pdfx/pdfx.dart';

/// Callback when the user taps on a thumbnail
typedef ThumbnailPageCallback = void Function(int page);

/// Function that returns page number widget
typedef CurrentPageWidget = Widget Function(int page, bool isCurrentPage);

/// {@template pdf_thumbnail}
/// Thumbnail viewer for pdfs
/// {@endtemplate}
class PdfThumbnail extends StatefulWidget {
  //@TODO
  // factory PdfThumbnail.fromAsset(String asset) {
  //   return PdfThumbnail._();
  // }

  /// Creates a [PdfThumbnail] from a file.
  factory PdfThumbnail.fromFile(
    String path, {
    Key? key,
    Color? backgroundColor,
    BoxDecoration? currentPageDecoration,
    CurrentPageWidget? currentPageWidget,
    double? height,
    ThumbnailPageCallback? onPageClicked,
    required int currentPage,
    Widget? loadingIndicator,
    ImageThumbnailCacher? cacher,
    bool? scrollToCurrentPage,
    Widget? closeButton,
  }) {
    return PdfThumbnail._(
      key: key,
      path: path,
      backgroundColor: backgroundColor ?? Colors.black,
      height: height ?? 200,
      onPageClicked: onPageClicked,
      currentPage: currentPage,
      currentPageWidget:
          currentPageWidget ?? (page, isCurrent) => const SizedBox(),
      currentPageDecoration: currentPageDecoration ??
          BoxDecoration(
            color: Colors.white,
            border: Border.all(
              color: Colors.blue,
              width: 4,
            ),
          ),
      loadingIndicator: loadingIndicator ??
          const Center(
            child: CircularProgressIndicator(),
          ),
      cacher: cacher,
      scrollToCurrentPage: scrollToCurrentPage ?? false,
      closeButton: closeButton,
    );
  }
  const PdfThumbnail._({
    super.key,
    this.path,
    this.backgroundColor,
    required this.height,
    this.onPageClicked,
    required this.currentPage,
    this.currentPageDecoration,
    this.loadingIndicator,
    this.currentPageWidget,
    this.cacher,
    this.scrollToCurrentPage = false,
    this.closeButton,
  });

  /// File path
  final String? path;

  /// Background color
  final Color? backgroundColor;

  /// Decoration for current page
  final BoxDecoration? currentPageDecoration;

  /// Simple function that returns widget that shows the page number.
  /// Widget will be in [Stack] so you can use [Positioned] or [Align]
  final CurrentPageWidget? currentPageWidget;

  /// Height
  final double height;

  /// Callback to run when a page is clicked
  final ThumbnailPageCallback? onPageClicked;

  /// Current page, index + 1
  final int currentPage;

  /// Loading indicator
  final Widget? loadingIndicator;

  /// Close button
  final Widget? closeButton;

  /// Interface to manage caching
  final ImageThumbnailCacher? cacher;

  /// Whether page browser will scroll to the current page or not,
  /// false by default
  final bool scrollToCurrentPage;

  @override
  State<PdfThumbnail> createState() => _PdfThumbnailState();
}

class _PdfThumbnailState extends State<PdfThumbnail> {
  late ScrollController controller;
  @override
  void initState() {
    controller = ScrollController();
    imagesFuture = _render(widget.path!, widget.cacher)
      ..then((value) async {
        if (widget.scrollToCurrentPage) {
          WidgetsBinding.instance.addPostFrameCallback((timestamp) {
            swipeToPage(widget.currentPage, value.length);
          });
        }
      });
    super.initState();
  }

  late Future<Map<int, Uint8List>> imagesFuture;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.closeButton != null) widget.closeButton!,
        Container(
          height: widget.height,
          color: widget.backgroundColor,
          child: FutureBuilder<Map<int, Uint8List>>(
            future: imagesFuture,
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final images = snapshot.data!;
                return ListView.builder(
                  controller: controller,
                  padding: EdgeInsets.symmetric(vertical: widget.height * 0.1),
                  scrollDirection: Axis.horizontal,
                  itemCount: images.length,
                  itemBuilder: (context, index) {
                    final pageNumber = index + 1;
                    final isCurrentPage = pageNumber == widget.currentPage;
                    final image = images[pageNumber];
                    if (image == null) {
                      return const SizedBox();
                    }
                    return GestureDetector(
                      onTap: () => widget.onPageClicked?.call(index),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Stack(
                          children: [
                            DecoratedBox(
                              key: Key('thumbnail_$pageNumber'),
                              decoration: isCurrentPage
                                  ? widget.currentPageDecoration!
                                  : const BoxDecoration(
                                      color: Colors.white,
                                    ),
                              child: Image.memory(image),
                            ),
                            widget.currentPageWidget!(
                                pageNumber, isCurrentPage),
                          ],
                        ),
                      ),
                    );
                  },
                );
              } else {
                return widget.loadingIndicator!;
              }
            },
          ),
        ),
      ],
    );
  }

  void swipeToPage(int page, int itemCount) {
    final contentSize = controller.position.viewportDimension +
        controller.position.maxScrollExtent;
    final index = page - 1;
    final target = contentSize * index / itemCount;
    controller.animateTo(
      target,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}

Future<Map<int, Uint8List>> _render(
  String filePath,
  ImageThumbnailCacher? cacher,
) async {
  final images = <int, Uint8List>{};
  try {
    if (cacher != null) {
      final cached = await cacher.read(filePath);
      if (cached != null && cached.isNotEmpty) {
        return cached;
      }
    }
    final document = await PdfDocument.openFile(filePath);
    for (var pageNumber = 1; pageNumber <= document.pagesCount; pageNumber++) {
      final page = await document.getPage(pageNumber);
      final pageImage = await page.render(
        width: page.width,
        height: page.height,
      );
      images[pageNumber] = pageImage!.bytes;
      await page.close();
    }
  } catch (e) {
    if (kDebugMode) {
      print(e);
    }
  }
  if (cacher != null) {
    await cacher.write(id: filePath, map: images);
  }
  return images;
}

/// Interface for caching thumbnails
abstract class ImageThumbnailCacher {
  /// Read from cache
  Future<PageToImage?> read(String id);

  /// Write to cache
  Future<bool> write({
    required String id,
    required PageToImage map,
  });
}

/// Page to image map
typedef PageToImage = Map<int, Uint8List>;
