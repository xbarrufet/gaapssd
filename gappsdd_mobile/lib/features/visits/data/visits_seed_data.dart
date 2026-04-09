import 'package:sqflite/sqflite.dart';

class VisitsSeedDataLoader {
  const VisitsSeedDataLoader._();

  static Future<void> loadForAppStartup(Database db) async {
    if (await _isTableEmpty(db, 'client_profile')) {
      await db.insert('client_profile', {
        'id': 'client-profile-main',
        'app_title': 'GAPP Garden',
        'client_name': 'Casa Rural Puig',
        'gardener_name': 'Xavier Barrufet',
        'gardener_role': 'Lead Gardener',
        'gardener_avatar_url':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuBi8eJ6x5C8RS8VrQo1y-WZ2J9RagVqSJKeJPLNv2cdtltHfVxyVoZTA-GDif6vDDzOt-O0zK8fCcYVow_El-L3npzRl1PcWOUvCOZvdl-xH_Rs8f8UzsRejYgXpfCoEWlNNJmEV89uQNgQdkq3Do1vtTRvAyeHZflvzvfiyO-vO5bmLsPnFv3cLJ2gtz3R0G8NCjiQxfBIoDD1XGdtm5Oe9O5vE0gO_4immaPioJdYjbunqf-viXk7fZLs6qJDA1o1rYEiY0mww_Bu',
        'hero_image_url':
            'https://lh3.googleusercontent.com/aida-public/AB6AXuAmFTSSW8e_0TjF79LBTTT4gkFYD0NtRdSqhMcyNbkyVCIryaNjBCrvm72BlmEFmXUjiDI9UzvDejqlrslDI1Maa5uBCTTA_1sNtBzwISUs3LmC_QZ-xib8DtI3WvsmJef7oIfFTN7YSXYS8oA-m3jTHnam5YQO_0DPpUfTxUFqq0935I4GIUOQ7L-_aRlxV3RWArG20M_LnaGUDF1Ffj6VDY3-dML118_1YfkoFv1IaGbJGRHFeb8Yh9Dpij2E36LnXWgKGHHwdyY6',
      });
    }

    if (await _isTableEmpty(db, 'assigned_gardens')) {
      const gardens = [
        {
          'id': 'garden-villa-hortensia',
          'garden_name': 'Villa Hortensia',
          'address': '122 Calle de las Rosas, Madrid',
          'urgency': 'urgent',
          'last_visit_label': 'Last Visit',
          'last_visit_age': '24 days ago',
          'evidence': 'verified',
          'primary_action_label': 'Última Visita',
        },
        {
          'id': 'garden-can-roca',
          'garden_name': 'Can Roca',
          'address': 'Av. Diagonal 450, Barcelona',
          'urgency': 'upcoming',
          'last_visit_label': 'Last Visit',
          'last_visit_age': '12 days ago',
          'evidence': 'manual',
          'primary_action_label': 'Última Visita',
        },
        {
          'id': 'garden-mas-de-mar',
          'garden_name': 'Mas de Mar',
          'address': 'Cami de Ronda s/n, Costa Brava',
          'urgency': 'maintained',
          'last_visit_label': 'Last Visit',
          'last_visit_age': '3 days ago',
          'evidence': 'verified',
          'primary_action_label': 'Última Visita',
        },
        {
          'id': 'garden-el-olivar',
          'garden_name': 'El Olivar',
          'address': 'Plaza Mayor, 12, Segovia',
          'urgency': 'maintained',
          'last_visit_label': 'Last Visit',
          'last_visit_age': 'Yesterday',
          'evidence': 'manual',
          'primary_action_label': 'Última Visita',
        },
      ];

      for (final garden in gardens) {
        await db.insert('assigned_gardens', garden);
      }
    }

    if (await _isTableEmpty(db, 'visits')) {
      await db.insert('visits', {
        'id': 'visit-2026-04-08',
        'garden_id': 'garden-villa-hortensia',
        'title': 'Pruning and Clearing',
        'description':
            'Pruned the ornamental shrubs along the main walkway and cleared seasonal debris from the perennial beds.',
        'is_verified': 1,
        'initiation_method': 'QR_SCAN',
        'started_at': DateTime(2026, 4, 8, 9, 12).toUtc().toIso8601String(),
        'ended_at': DateTime(2026, 4, 8, 10, 49).toUtc().toIso8601String(),
        'public_comment': 'Poda completada y limpieza de zona de paso.',
      });

      await db.insert('visits', {
        'id': 'visit-2026-04-02',
        'garden_id': 'garden-can-roca',
        'title': 'Lawn Mowing',
        'description':
            'Standard lawn maintenance completed. Edges trimmed and fertilization applied to the north sector.',
        'is_verified': 1,
        'initiation_method': 'MANUAL',
        'started_at': DateTime(2026, 4, 2, 8, 30).toUtc().toIso8601String(),
        'ended_at': DateTime(2026, 4, 2, 10, 15).toUtc().toIso8601String(),
        'public_comment': 'Mantenimiento general del cesped y bordes.',
      });

      await db.insert('visits', {
        'id': 'visit-2026-03-26',
        'garden_id': 'garden-mas-de-mar',
        'title': 'Irrigation Check',
        'description':
            'Verified all sprinkler heads for proper coverage. Replaced one damaged valve in zone 3.',
        'is_verified': 0,
        'initiation_method': 'MANUAL',
        'started_at': DateTime(2026, 3, 26, 11, 4).toUtc().toIso8601String(),
        'ended_at': DateTime(2026, 3, 26, 12, 2).toUtc().toIso8601String(),
        'public_comment': 'Revision de riego y sustitucion de valvula.',
      });
    }

    final appStateRows = await db.query(
      'app_state',
      where: 'key = ?',
      whereArgs: ['current_visit_id'],
      limit: 1,
    );

    if (appStateRows.isEmpty) {
      await db.insert('app_state', {'key': 'current_visit_id', 'value': null});
    }
  }

  static Future<bool> _isTableEmpty(Database db, String tableName) async {
    final result = await db.rawQuery('SELECT COUNT(*) AS total FROM $tableName');
    final total = Sqflite.firstIntValue(result) ?? 0;
    return total == 0;
  }
}
