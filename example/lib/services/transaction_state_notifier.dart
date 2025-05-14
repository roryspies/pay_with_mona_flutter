import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pay_with_mona/pay_with_mona_sdk.dart';

enum TransactionStatus {
  initiated('Processing'),
  successful('Success'),
  failed('Failed');

  const TransactionStatus(this.status);
  final String status;
}

class TransactionStatusState {
  final TransactionStatus transactionStatus;
  final String transactionID;
  final num amount;

  const TransactionStatusState({
    required this.transactionStatus,
    required this.transactionID,
    required this.amount,
  });

  TransactionStatusState copyWith({
    TransactionStatus? transactionStatus,
    String? transactionID,
    num? amount,
  }) {
    return TransactionStatusState(
      transactionStatus: transactionStatus ?? this.transactionStatus,
      transactionID: transactionID ?? this.transactionID,
      amount: amount ?? this.amount,
    );
  }

  @override
  String toString() =>
      'TransactionStatusState(transactionStatus: $transactionStatus, transactionID: $transactionID)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransactionStatusState &&
          runtimeType == other.runtimeType &&
          transactionStatus == other.transactionStatus &&
          transactionID == other.transactionID;

  @override
  int get hashCode => transactionStatus.hashCode ^ transactionID.hashCode;
}

final transactionStatusProvider =
    NotifierProvider<TransactionStatusNotifier, TransactionStatusState>(
  TransactionStatusNotifier.new,
);

class TransactionStatusNotifier extends Notifier<TransactionStatusState> {
  @override
  TransactionStatusState build() {
    return TransactionStatusState(
      transactionStatus: TransactionStatus.initiated,
      transactionID: "",
      amount: 0,
    );
  }

  void updateState({
    required TransactionState newState,
  }) {
    String? txId;
    num? amt;
    late TransactionStatus status;

    if (newState is TransactionStateWithInfo) {
      txId = newState.transactionID;
      amt = newState.amount;
    }

    if (newState is TransactionStateFailed) {
      status = TransactionStatus.failed;
    } else if (newState is TransactionStateCompleted) {
      status = TransactionStatus.successful;
    } else if (newState is TransactionStateInitiated) {
      status = TransactionStatus.initiated;
    } else {
      return;
    }

    state = state.copyWith(
      transactionStatus: status,
      transactionID: txId,
      amount: amt,
    );
  }
}
