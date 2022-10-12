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
        double? height,
        ThumbnailPageCallback? onPageClicked,
        required int currentPage,
        Widget? loadingIndicator,
      }) {
    return PdfThumbnail._(
      key: key,
      path: path,
      backgroundColor: backgroundColor ?? Colors.black,
      height: height ?? 200,
      onPageClicked: onPageClicked,
      currentPage: currentPage,
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
  });

  /// File path
  final String? path;

  /// Background color
  final Color? backgroundColor;

  /// Decoration for current page
  final BoxDecoration? currentPageDecoration;

  /// Height
  final double height;

  /// Callback to run when a page is clicked
  final ThumbnailPageCallback? onPageClicked;

  /// Current page, index + 1
  final int currentPage;

  /// Loading indicator
  final Widget? loadingIndicator;

  @override
  State<PdfThumbnail> createState() => _PdfThumbnailState();
}

class _PdfThumbnailState extends State<PdfThumbnail> {
  ScrollController scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    getThumbnails(widget.path!, 10);
    // trigger getThumbnail() to get more image when user is about to scroll to the end of the list (at 75%)
    scrollController.addListener(() {
      if (scrollController.position.pixels >=
          (scrollController.position.maxScrollExtent * .75)) {
        getThumbnails(widget.path!, 10);
      }
    });
  }

  final images = <int, Uint8List>{};
  int currentPage = 1;
  int endPage = 1;
  bool loading = false;
  List<Widget> list = [];

  Future<void> getThumbnails(String filePath, int length) async {
    if (!loading) {
      loading = true;
      try {
        final document = await PdfDocument.openFile(filePath);
        final totalPage = document.pagesCount;
        if (currentPage <= (totalPage - length)) {
          endPage = currentPage + length + 1;
        } else if ((currentPage < totalPage) &&
            (currentPage + length > totalPage)) {
          endPage = totalPage + 1;
        }
        for (; currentPage <= endPage; currentPage++) {
          final page = await document.getPage(currentPage);
          final pageImage = await page.render(
            width: page.width,
            height: page.height,
            quality: 10,
          );
          images[currentPage] = pageImage!.bytes;
          final outPageNumber = currentPage - 1;
          final isCurrentPage = outPageNumber + 1 == widget.currentPage;

          list.add(
            GestureDetector(
              onTap: () => widget.onPageClicked!(outPageNumber),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Stack(
                  children: [
                    Container(
                      color: Colors.white,
                      height: 200,
                      width: 124,
                    ),
                    DecoratedBox(
                      decoration: isCurrentPage
                          ? widget.currentPageDecoration!
                          : const BoxDecoration(
                        color: Colors.white,
                      ),
                      child: Image.memory(images[currentPage]!),
                    ),
                    Positioned(
                      bottom: 5,
                      left: 5,
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Colors.black45,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 3, horizontal: 8,),
                          child: Text(
                            currentPage.toString(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
          await page.close();
        }
      } catch (e) {
        if (kDebugMode) {
          print(e);
        }
      }
      setState(() {
        list = list;
      });
      loading = false;
    }
  }

  //late Future<Map<int, Uint8List>> imagesFuture;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      color: widget.backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: list.isEmpty
            ? widget.loadingIndicator!
            : ListView(
          controller: scrollController,
          scrollDirection: Axis.horizontal,
          children: list.toList(growable: true),
        ),
      ),
    );
  }
}
