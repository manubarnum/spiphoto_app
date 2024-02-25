import 'package:flutter/material.dart';
import '../image_wp_info.dart';

Widget buildPageView(
    BuildContext context, List<ImageWpInfo> imageInfos, int initialIndex) {
  PageController pageController = PageController(
    initialPage: initialIndex,
    //viewportFraction: 1.0, // Ajustez la sensibilité du swipe ici
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
                /* onTap: () {
                  // Ne rien faire lors du tap sur l'image
                }, */
                onHorizontalDragUpdate: (details) {
                  // Ne permet le swipe que si l'utilisateur swipe depuis la bordure de l'écran
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
                    boundaryMargin: EdgeInsets.all(
                        20.0), // Ajustez la marge pour une réactivité accrue
                    minScale: 0.1,
                    maxScale: 3.0,
                    panEnabled: true, // Permet le déplacement
                    scaleEnabled: true, // Permet le zoom
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
              Navigator.pop(context); // Retourne à l'écran précédent
            },
          ),
        ),
      ],
    ),
  );
}
