import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'api_service.dart';

class ContextController extends ChangeNotifier {
  static final ContextController instance = ContextController._internal();
  ContextController._internal();

  static const String _contextPrefKey = 'concilia_active_context';

  String _activeContext = 'personal'; // 'personal' ou 'management'

  String get activeContext => _activeContext;
  bool get isPersonal => _activeContext == 'personal';
  bool get isManagement => _activeContext == 'management';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedContext = prefs.getString(_contextPrefKey);
    final user = ApiService.instance.currentUser;

    if (user != null && !user.hasManagementAccess) {
      _activeContext = 'personal';
    } else if (savedContext == 'management') {
      _activeContext = 'management';
    } else {
      _activeContext = 'personal';
    }
    notifyListeners();
  }

  Future<bool> switchContext(String newContext) async {
    if (newContext == _activeContext) return true;

    final user = ApiService.instance.currentUser;
    if (newContext == 'management' && (user == null || !user.hasManagementAccess)) {
      return false;
    }

    _activeContext = newContext;
    notifyListeners();

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_contextPrefKey, newContext);

    // Notifica backend sobre a alternância (assíncrono)
    try {
      await ApiService.instance.notifyContextSwitch(newContext);
    } catch (_) {}

    return true;
  }
}

