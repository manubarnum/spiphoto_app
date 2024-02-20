import 'package:flutter/material.dart';
import '../image_wp_info.dart';

Widget buildPageView(
    BuildContext context, List<ImageWpInfo> imageInfos, int initialIndex) {
  PageController pageController = PageController(initialPage: initialIndex);

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
                onTap: () {
                  Navigator.pop(context); // Retourne à l'écran précédent
                },
                child: Container(
                  margin: EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.black,
                      width: 3.0,
                    ),
                    borderRadius: BorderRadius.circular(10.0),
                  ),
                  child: Image.network(
                    imageInfos[index].landscapeUrl,
                    fit: BoxFit.contain,
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
