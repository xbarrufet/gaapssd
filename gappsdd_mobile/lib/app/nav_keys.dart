import 'package:flutter/material.dart';

/// Global navigator keys shared between the router and other services
/// (e.g. NotificationService) to avoid circular imports.
final rootNavigatorKey = GlobalKey<NavigatorState>();
final gardenerShellKey = GlobalKey<NavigatorState>();
final clientShellKey = GlobalKey<NavigatorState>();
