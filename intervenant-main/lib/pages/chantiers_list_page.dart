import 'package:flutter/material.dart';

import 'package:intervenant/models/probleme_voirie.dart';
import 'package:intervenant/services/probleme_service.dart';

class ChantiersListPage extends StatefulWidget {
  const ChantiersListPage({super.key});

  @override
  State<ChantiersListPage> createState() => _ChantiersListPageState();
}

class _ChantiersListPageState extends State<ChantiersListPage> {
  late Future<List<ProblemeVoirie>> futureProblemes;

  @override
  void initState() {
    super.initState();
    futureProblemes = ProblemeService.getProblemes();
  }

  Color statusColor(String status) {
    final String s = status.toLowerCase();
    if (s.contains('cours')) return Colors.orange;
    if (s.contains('termin')) return Colors.green;
    return Colors.red;
  }

  String labelType(String type) {
    switch (type.toLowerCase()) {
      case 'crack':
        return 'Fissure';
      case 'pothole':
        return 'Nid-de-poule';
      default:
        return type;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mes chantiers')),
      body: FutureBuilder<List<ProblemeVoirie>>(
        future: futureProblemes,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }

          final List<ProblemeVoirie> problemes = snapshot.data ?? const [];
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: problemes.length,
            itemBuilder: (context, index) {
              final ProblemeVoirie p = problemes[index];
              final Color badgeColor = statusColor(p.status);

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            backgroundColor: Colors.orange.shade100,
                            child: Text('${index + 1}'),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              labelType(p.problemType),
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: badgeColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(30),
                            ),
                            child: Text(
                              p.status,
                              style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Icon(Icons.location_on, color: Colors.red),
                          const SizedBox(width: 6),
                          Expanded(child: Text(p.address)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(child: _miniCard('Score', p.riskScore.toStringAsFixed(0))),
                          const SizedBox(width: 8),
                          Expanded(child: _miniCard('IA', '${(p.confidence * 100).toStringAsFixed(0)}%')),
                          const SizedBox(width: 8),
                          Expanded(child: _miniCard('Equipe', p.equipe)),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade100,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Gravité : ${p.severity}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                          onPressed: () {},
                          icon: const Icon(Icons.visibility),
                          label: const Text('Voir détails'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _miniCard(String title, String value) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(title, style: const TextStyle(fontSize: 12)),
        ],
      ),
    );
  }
}
