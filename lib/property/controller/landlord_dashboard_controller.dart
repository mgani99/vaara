import 'package:flutter/foundation.dart';
import 'package:my_app/property/service/ladlord_dashboard_service.dart';

sealed class LandlordDashboardState {
  const LandlordDashboardState();
}

class LandlordDashboardLoading extends LandlordDashboardState {
  const LandlordDashboardLoading();
}

class LandlordDashboardLoaded extends LandlordDashboardState {
  final Map<String, dynamic> data;
  const LandlordDashboardLoaded(this.data);
}

class LandlordDashboardError extends LandlordDashboardState {
  final String message;
  const LandlordDashboardError(this.message);
}

class LandlordDashboardController extends ChangeNotifier {
  final LandlordDashboardService service;

  LandlordDashboardState state = const LandlordDashboardLoading();

  LandlordDashboardController({required this.service});

  Future<void> load() async {
    state = const LandlordDashboardLoading();
    notifyListeners();

    try {
      final data = await service.loadDashboard();
      state = LandlordDashboardLoaded(data);
      notifyListeners();
    } catch (e) {
      state = LandlordDashboardError(e.toString());
      notifyListeners();
    }
  }
}
