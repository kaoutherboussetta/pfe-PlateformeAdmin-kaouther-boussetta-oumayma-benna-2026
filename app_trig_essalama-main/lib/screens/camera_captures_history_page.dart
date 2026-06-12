import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../services/camera_capture_service.dart';
import '../services/api_client.dart';

class CameraCapturesHistoryPage extends StatefulWidget {
  const CameraCapturesHistoryPage({super.key});

  @override
  State<CameraCapturesHistoryPage> createState() => _CameraCapturesHistoryPageState();
}

class _CameraCapturesHistoryPageState extends State<CameraCapturesHistoryPage> {
  late Future<List<CameraCaptureItem>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<CameraCaptureItem>> _load() {
    final service = CameraCaptureService(context.read<ApiClient>());
    return service.fetchMyCaptures(limit: 100);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Historique des captures')),
      body: FutureBuilder<List<CameraCaptureItem>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(
                  'Erreur: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final items = snapshot.data ?? const <CameraCaptureItem>[];
          if (items.isEmpty) {
            return const Center(child: Text('Aucune capture enregistrée.'));
          }

          return RefreshIndicator(
            onRefresh: () async {
              final next = await _load();
              if (!mounted) return;
              setState(() {
                _future = Future.value(next);
              });
            },
            child: ListView.separated(
              padding: const EdgeInsets.all(12),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final item = items[index];
                final bytes = item.decodeImageBytes();
                return Card(
                  clipBehavior: Clip.antiAlias,
                  elevation: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      AspectRatio(
                        aspectRatio: 4 / 3,
                        child: bytes == null
                            ? const Center(child: Text('Image invalide'))
                            : Image.memory(
                                bytes,
                                fit: BoxFit.cover,
                                cacheWidth: 900,
                                filterQuality: FilterQuality.medium,
                                errorBuilder: (_, __, ___) =>
                                    const Center(child: Text('Erreur affichage image')),
                              ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Lat: ${item.latitude.toStringAsFixed(6)} | Lng: ${item.longitude.toStringAsFixed(6)}',
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Date: ${item.createdAt.toLocal()}',
                              style: const TextStyle(color: Colors.black54, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
