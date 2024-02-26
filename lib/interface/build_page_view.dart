import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../image_wp_info.dart';

void setWallpaper(String imagePath) async {
  const platform = const MethodChannel('wallpaper_setter');
  try {
    await platform.invokeMethod('setWallpaper', {'path': imagePath});
  } on PlatformException catch (e) {
    print("Failed to set wallpaper: '${e.message}'.");
  }
}

Widget buildPageView(
    BuildContext context, List<ImageWpInfo> imageInfos, int initialIndex) {
  PageController pageController = PageController(
    initialPage: initialIndex,
  );

  return Scaffold(
    body: Stack(
      children: [
        Container(
          height: double.infinity,
          child: PageView.builder(
            controller: pageController,
            itemCount: imageInfos.length,
            itemBuilder: (context, index) {
              return GestureDetector(
                onLongPress: () {
                  setWallpaper(imageInfos[index].landscapeUrl); // Définit l'image comme fond d'écran lors d'un appui long
                },
                onHorizontalDragUpdate: (details) {
                  if (details.primaryDelta! < 0 &&
                      details.globalPosition.dx < 50) {
                    pageController.nextPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  } else if (details.primaryDelta! > 0 &&
                      details.globalPosition.dx >
                          MediaQuery.of(context).size.width - 50) {
                    pageController.previousPage(
                      duration: Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                    );
                  }
                },
                child: Container(
                  margin: EdgeInsets.all(16.0),
                  constraints: BoxConstraints(
                    minHeight: 100,
                    minWidth: 100,
                  ),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Color.fromARGB(255, 255, 255, 255),
                      width: 5.0,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: InteractiveViewer(
                    boundaryMargin: EdgeInsets.all(20.0),
                    minScale: 0.1,
                    maxScale: 3.0,
                    panEnabled: true,
                    scaleEnabled: true,
                    child: Image.network(
                      imageInfos[index].landscapeUrl,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        Positioned(
          top: 16.0,
          left: 16.0,
          child: IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
        ),
      ],
    ),
  );
}
