import 'package:material_ui/material_ui.dart';

import '../services/ads_service.dart';
import '../services/app_state.dart';
import '../services/notification_service.dart';
import '../widgets/app_bar_main.dart';
import '../widgets/glass_card.dart';
import 'history_page.dart';
import 'profile_page.dart';
import 'simulator_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    required this.state,
    required this.ads,
    required this.notifications,
  });
  final AppState state;
  final AdsService ads;
  final NotificationService notifications;
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _index = 0;
  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBarMain(
      title: [
        'Planeje seu próximo passo',
        'Histórico de simulações',
        'Meu perfil',
      ][_index],
      onProfile: () => setState(() => _index = 2),
    ),
    body: AppBackground(
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 1080),
          child: IndexedStack(
            index: _index,
            children: [
              SimulatorPage(state: widget.state, ads: widget.ads),
              HistoryPage(
                state: widget.state,
                onSimulate: () => setState(() => _index = 0),
              ),
              ProfilePage(
                state: widget.state,
                notifications: widget.notifications,
                ads: widget.ads,
              ),
            ],
          ),
        ),
      ),
    ),
    bottomNavigationBar: NavigationBar(
      selectedIndex: _index,
      onDestinationSelected: (value) => setState(() => _index = value),
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.directions_car_outlined),
          selectedIcon: Icon(Icons.directions_car_rounded),
          label: 'Simular',
        ),
        NavigationDestination(
          icon: Icon(Icons.history_rounded),
          label: 'Histórico',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline_rounded),
          selectedIcon: Icon(Icons.person_rounded),
          label: 'Perfil',
        ),
      ],
    ),
  );
}
