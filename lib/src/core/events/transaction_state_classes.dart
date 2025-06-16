import 'package:pay_with_mona/src/core/events/models/transaction_task_model.dart';

sealed class TransactionState {
  const TransactionState();
}

/// All states that carry a transactionID and amount can extend this.
abstract class TransactionStateWithInfo extends TransactionState {
  final String? transactionID;
  final String? friendlyID;
  final num? amount;
  const TransactionStateWithInfo({
    this.transactionID,
    this.friendlyID,
    this.amount,
  });
}

class TransactionStateIdle extends TransactionState {
  const TransactionStateIdle();
}

class TransactionStateInitiated extends TransactionStateWithInfo {
  const TransactionStateInitiated({
    super.transactionID,
    super.friendlyID,
    super.amount,
  });
}

class TransactionStateCompleted extends TransactionStateWithInfo {
  const TransactionStateCompleted({
    super.transactionID,
    super.friendlyID,
    super.amount,
  });
}

class TransactionStateFailed extends TransactionStateWithInfo {
  const TransactionStateFailed({
    this.reason,
    super.transactionID,
    super.friendlyID,
    super.amount,
  });

  final String? reason;
}

class TransactionStateRequestOTPTask extends TransactionState {
  final TransactionTaskModel task;
  const TransactionStateRequestOTPTask({required this.task});
}

class TransactionStateRequestPINTask extends TransactionState {
  final TransactionTaskModel task;
  const TransactionStateRequestPINTask({required this.task});
}

class TransactionStateNavToResult extends TransactionStateWithInfo {
  const TransactionStateNavToResult({
    super.transactionID,
    super.friendlyID,
    super.amount,
    //this.currentTransactionState,
  });

  //final TransactionStateNavToResultEnum? currentTransactionState;
}

//enum TransactionStateNavToResultEnum { completed, initiated, failed }
