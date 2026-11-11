import 'package:flutter/material.dart';

import 'app.dart';
import 'core/data/session_storage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SavedSession? session;
  try {
    session = await SessionStorage().load();
  } catch (_) {
    session = null;
  }
  runApp(NormaApp(initialSession: session));
}
