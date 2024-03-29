import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:oyt_front_core/constants/socket_constants.dart';
import 'package:oyt_front_core/external/socket_handler.dart';
import 'package:oyt_front_core/failure/failure.dart';
import 'package:oyt_front_core/logger/logger.dart';
import 'package:on_your_table_waiter/core/router/router.dart';
import 'package:oyt_front_core/validators/text_form_validator.dart';
import 'package:oyt_front_core/wrappers/state_wrapper.dart';
import 'package:oyt_front_auth/models/connect_socket.dart';
import 'package:on_your_table_waiter/features/auth/provider/auth_provider.dart';
import 'package:oyt_front_table/models/change_table_status.dart';
import 'package:oyt_front_table/models/customer_requests_response.dart';
import 'package:oyt_front_table/models/tables_socket_response.dart';
import 'package:oyt_front_table/models/users_table.dart';
import 'package:on_your_table_waiter/features/table/provider/table_state.dart';
import 'package:on_your_table_waiter/features/home/index_menu_screen.dart';
import 'package:oyt_front_widgets/widgets/snackbar/custom_snackbar.dart';

final tableProvider = StateNotifierProvider<TableProvider, TableState>((ref) {
  return TableProvider.fromRead(ref);
});

class TableProvider extends StateNotifier<TableState> {
  TableProvider(this.socketIOHandler, {required this.ref}) : super(TableState.initial());

  factory TableProvider.fromRead(Ref ref) {
    final socketIo = ref.read(socketProvider);
    return TableProvider(socketIo, ref: ref);
  }

  final Ref ref;
  final SocketIOHandler socketIOHandler;

  Future<void> onReadTableCode(String code) async {
    final validationError = TextFormValidator.tableCodeValidator(code);
    if (validationError != null) {
      CustomSnackbar.showSnackBar(ref.read(routerProvider).context, validationError);
      return;
    }
    GoRouter.of(ref.read(routerProvider).context).go('${IndexHomeScreen.route}?tableId=$code');
  }

  void startListeningSocket() {
    listenTables();
    joinToRestaurant();
    listenCustomerRequests();
  }

  void listenCustomerRequests() {
    socketIOHandler.onMap(SocketConstants.customerRequests, (data) {
      final res = CustomerRequestsResponse.fromMap(data);
      state = state.copyWith(customerRequests: StateAsync.success(res));
    });
  }

  Future<void> listenTables() async {
    socketIOHandler.onMap(SocketConstants.listenTables, (data) {
      state = state.copyWith(
        tables: StateAsync.success(TablesSocketResponse.fromList(data['tables'])),
      );
    });
  }

  Future<void> joinToRestaurant() async {
    final restaurantId = ref.read(authProvider).checkWaiterResponse.data?.restaurantId;
    socketIOHandler.emitMap(SocketConstants.joinToRestaurant, {
      'token': ref.read(authProvider).authModel.data?.bearerToken ?? '',
      'restaurantId': restaurantId,
    });
  }

  Future<void> changeStatus(TableStatus status, TableResponse table) async {
    socketIOHandler.emitMap(
      SocketConstants.changeTableStatus,
      ChangeTableStatus(
        tableId: table.id,
        token: ref.read(authProvider).authModel.data?.bearerToken ?? '',
        status: status,
      ).toMap(),
    );
  }

  void joinToTable(TableResponse table) {
    state = state.copyWith(tableUsers: StateAsync.loading());
    socketIOHandler.on(SocketConstants.listOfOrders, (data) {
      if (data['table'] == null || data['table'] is! Map || (data['table'] as Map).isEmpty) {
        state = state.copyWith(
          tableUsers: StateAsync.error(const Failure('No hay usuarios en la mesa')),
        );
        return;
      }
      final tableUsers = UsersTable.fromMap(data);
      Logger.log('################# START listenListOfOrders #################');
      Logger.log(tableUsers.toString());
      Logger.log('################# END listenListOfOrders #################');
      state = state.copyWith(tableUsers: StateAsync.success(tableUsers));
    });
    socketIOHandler.emitMap(SocketConstants.watchTable, {
      'token': ref.read(authProvider).authModel.data?.bearerToken ?? '',
      'tableId': table.id,
    });
  }

  Future<void> stopCallingWaiter(String tableId) async {
    socketIOHandler.emitMap(
      SocketConstants.stopCallWaiter,
      ConnectSocket(
        tableId: tableId,
        token: ref.read(authProvider).authModel.data?.bearerToken ?? '',
      ).toMap(),
    );
  }

  void leaveTable(TableResponse table) {
    state = state.copyWith(tableUsers: StateAsync.initial());
    socketIOHandler.emitMap(SocketConstants.leaveTable, {'tableId': table.id});
  }
}
