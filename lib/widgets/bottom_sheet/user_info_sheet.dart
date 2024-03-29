import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:oyt_front_widgets/bottom_sheet/bottom_sheet_constants.dart';
import 'package:oyt_front_widgets/loading/loading_widget.dart';

import 'package:oyt_front_widgets/bottom_sheet/base_bottom_sheet.dart';
import 'package:on_your_table_waiter/features/auth/provider/auth_provider.dart';

class UserInfoSheet extends ConsumerWidget {
  const UserInfoSheet({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet(
      context: context,
      shape: BottomSheetConstants.shape,
      isScrollControlled: true,
      builder: (context) => const UserInfoSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.read(authProvider);
    return BaseBottomSheet(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: authState.authModel.on(
                  onData: (data) => Text(
                    '${data.user.firstName} ${data.user.lastName}',
                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  onError: (e) => Center(child: Text(e.message)),
                  onInitial: () => const LoadingWidget(),
                  onLoading: () => const LoadingWidget(),
                ),
              ),
              IconButton(onPressed: Navigator.of(context).pop, icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: () => onLogout(ref),
              child: const Text('Cerrar sesión'),
            ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  void onLogout(WidgetRef ref) => ref.read(authProvider.notifier).logout();
}
