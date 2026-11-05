import 'package:flutter/foundation.dart';

import '../data/app_status_repository.dart';
import '../domain/app_status.dart';

enum HomeViewState { idle, loading, ready, failure }

class HomeViewModel extends ChangeNotifier {
  HomeViewModel({required this.repository});

  final AppStatusRepository repository;

  HomeViewState _state = HomeViewState.idle;
  AppStatus? _status;
  String? _errorMessage;

  HomeViewState get state => _state;
  AppStatus? get status => _status;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _state = HomeViewState.loading;
    _errorMessage = null;
    notifyListeners();

    try {
      _status = await repository.load();
      _state = HomeViewState.ready;
    } catch (_) {
      _errorMessage = 'Não foi possível carregar a configuração.';
      _state = HomeViewState.failure;
    }

    notifyListeners();
  }
}
