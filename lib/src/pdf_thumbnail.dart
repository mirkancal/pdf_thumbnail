// Copyright (c) 2022, Very Good Ventures
// https://verygood.ventures
//
// Use of this source code is governed by an MIT-style
// license that can be found in the LICENSE file or at
// https://opensource.org/licenses/MIT.

import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/src/widgets/container.dart';
import 'package:flutter/src/widgets/framework.dart';
import 'package:pdfx/pdfx.dart';

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
    double? height,
  }) {
    return PdfThumbnail._(
      key: key,
      path: path,
      backgroundColor: backgroundColor ?? Colors.black,
      height: height ?? 200,
    );
  }
  const PdfThumbnail._({
    super.key,
    this.path,
    this.backgroundColor,
    required this.height,
  });

  /// File path
  final String? path;

  /// Background color
  final Color? backgroundColor;

  /// Height
  final double height;

  @override
  State<PdfThumbnail> createState() => _PdfThumbnailState();
}

class _PdfThumbnailState extends State<PdfThumbnail> {
  @override
  void initState() {
    imagesFuture = _render();
    super.initState();
  }

  Future<Map<int, Uint8List>> _render() async {
    final images = <int, Uint8List>{};
    try {
      final document = await PdfDocument.openFile(widget.path!);
      for (var pageNumber = 1;
          pageNumber <= document.pagesCount;
          pageNumber++) {
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
    return images;
  }

  late Future<Map<int, Uint8List>> imagesFuture;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: widget.height,
      color: widget.backgroundColor,
      child: FutureBuilder<Map<int, Uint8List>>(
        future: imagesFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final images = snapshot.data!;
            return ListView.builder(
              padding: EdgeInsets.symmetric(vertical: widget.height * 0.1),
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              itemBuilder: (context, index) {
                final pageNumber = index + 1;
                final image = images[pageNumber];
                if (image == null) {
                  return const SizedBox();
                }
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      border: Border.all(
                        color: Colors.white,
                      ),
                      color: Colors.white,
                    ),
                    child: Image.memory(image),
                  ),
                );
              },
            );
          } else {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }
        },
      ),
    );
  }
}
