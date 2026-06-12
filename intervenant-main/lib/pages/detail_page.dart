import 'package:flutter/material.dart';
import 'package:intervenant/models/intervention_assignment.dart';

class DetailPage extends StatelessWidget {
  const DetailPage({required this.assignment, super.key});

  final InterventionAssignment assignment;

  Widget _line(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(child: Text(value.isEmpty ? '-' : value)),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Detail chantier')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            assignment.title.isEmpty ? 'Intervention' : assignment.title,
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 14),
          _line('ID', assignment.id),
          _line('Probleme', assignment.problemId),
          _line('Equipe', assignment.team),
          _line('Type', assignment.type),
          _line('Adresse', assignment.address),
          _line('Statut', assignment.status),
          _line('Priorite', assignment.priority),
          _line('Severite', assignment.severity),
          _line('Confiance', assignment.confidence.toString()),
          _line('Risque', assignment.riskScore.toString()),
          _line('Cout estime', assignment.estimatedCost),
          _line('Detecte le', assignment.detectedAt),
          _line('Mis a jour', assignment.updatedAt),
          const SizedBox(height: 6),
          Text(
            assignment.description.isEmpty ? 'Aucune description' : assignment.description,
          ),
        ],
      ),
    );
  }
}
