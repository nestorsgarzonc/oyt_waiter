import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:on_your_table_waiter/core/router/router.dart';
import 'package:oyt_front_core/push_notifications/push_notif_provider.dart';
import 'package:oyt_front_core/theme/theme.dart';

class MyApp extends ConsumerStatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {

  @override
  void initState() {
    ref.read(pushNotificationsProvider).setupInteractedMessage();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final routerProv = ref.read(routerProvider);
    return MaterialApp.router(
      scaffoldMessengerKey: ref.read(pushNotificationsProvider).messengerKey,
      title: 'OYT - Waiter',
      routerConfig: routerProv.goRouter,
      debugShowCheckedModeBanner: false,
      theme: ref.watch(themeProvider),
    );
  }
}
