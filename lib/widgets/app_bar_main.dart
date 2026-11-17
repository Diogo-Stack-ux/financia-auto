import 'package:material_ui/material_ui.dart';

import '../color/app_colors.dart';

class AppBarMain extends StatelessWidget implements PreferredSizeWidget {
  const AppBarMain({super.key, required this.title, this.onProfile});
  final String title;
  final VoidCallback? onProfile;
  @override
  Size get preferredSize => const Size.fromHeight(76);
  @override
  Widget build(BuildContext context) => AppBar(
    toolbarHeight: 76,
    backgroundColor: Colors.white.withValues(alpha: .65),
    surfaceTintColor: Colors.transparent,
    title: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.blue,
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(
            Icons.directions_car_rounded,
            color: Colors.white,
            size: 23,
          ),
        ),
        const SizedBox(width: 12),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'financia auto',
              style: Theme.of(context).textTheme.titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            Text(
              title,
              style: const TextStyle(fontSize: 11, color: AppColors.muted),
            ),
          ],
        ),
      ],
    ),
    actions: [
      if (onProfile != null)
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: IconButton.filledTonal(
            onPressed: onProfile,
            tooltip: 'Meu perfil',
            icon: const Icon(Icons.person_outline_rounded),
          ),
        ),
    ],
  );
}
