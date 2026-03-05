import 'package:flutter/material.dart';
import 'package:spiphoto_app/service/acces_wordpress.dart';
import 'package:spiphoto_app/service/image_wp_info.dart';

class MyList extends StatefulWidget {
  const MyList({Key? key}) : super(key: key);

  @override
  _MyListState createState() => _MyListState();
}

class _MyListState extends State<MyList> {
  late Future<List<Album>> futureAlbums;

  // Cache : évite de recalculer extractImagesFromHtml() à chaque rebuild
  final Map<int, Future<List<ImageWpInfo>>> _imageCache = {};

  @override
  void initState() {
    super.initState();
    futureAlbums = fetchAlbums();
  }

  // Retourne le Future depuis le cache, ou le crée s'il n'existe pas encore
  Future<List<ImageWpInfo>> _getImagesForAlbum(Album album) {
    return _imageCache.putIfAbsent(
      album.id,
      () => extractImagesFromHtml(album.content['rendered']),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: FutureBuilder<List<Album>>(
        future: futureAlbums,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CircularProgressIndicator();
          } else if (snapshot.hasError) {
            return Text('Erreur: ${snapshot.error}');
          } else if (snapshot.hasData) {
            final List<Album> albums = snapshot.data!;

            if (albums.isEmpty) {
              return const Text('Aucun album disponible.');
            }

            return ListView.builder(
              itemCount: albums.length,
              itemBuilder: (context, index) {
                return FutureBuilder<List<ImageWpInfo>>(
                  future: _getImagesForAlbum(albums[index]), // 👈 cache ici
                  builder: (context, imageSnapshot) {
                    // Image de couverture (optionnelle)
                    final String? imageUrl = (imageSnapshot.hasData &&
                            imageSnapshot.data!.isNotEmpty)
                        ? imageSnapshot.data!.first.portraitUrl
                        : null;

                    // Un seul widget Card, avec ou sans image 👇
                    return _AlbumCard(
                      album: albums[index],
                      imageUrl: imageUrl,
                    );
                  },
                );
              },
            );
          }
          return const Text('Aucune donnée disponible.');
        },
      ),
    );
  }
}

// Widget extrait pour éviter la duplication de code
class _AlbumCard extends StatelessWidget {
  final Album album;
  final String? imageUrl;

  const _AlbumCard({required this.album, this.imageUrl});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      margin: const EdgeInsets.symmetric(
        vertical: 10.0,
        horizontal: 20.0,
      ),
      child: ListTile(
        leading: imageUrl != null
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8.0),
                child: Image.network(
                  imageUrl!,
                  width: 50.0,
                  height: 50.0,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Icon(
                    Icons.broken_image,
                    color: Colors.grey[400],
                  ),
                ),
              )
            : null,
        title: Text(
          album.title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.bold,
            shadows: const [
              Shadow(
                offset: Offset(1.0, 1.0),
                blurRadius: 2.0,
                color: Colors.black26,
              ),
            ],
          ),
        ),
        onTap: () {
          Navigator.pushNamed(
            context,
            '/album_details_screen',
            arguments: album,
          );
        },
      ),
    );
  }
}
