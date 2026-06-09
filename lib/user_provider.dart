
import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  bool _isAdmin = false;

  bool get isAdmin => _isAdmin;

  void login(bool isAdmin) {
    _isAdmin = isAdmin;
    notifyListeners();
  }
}
