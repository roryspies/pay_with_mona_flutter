import 'package:pay_with_mona/src/core/events/models/transaction_task_model.dart';

abstract class TransactionState {
  const TransactionState();
}

class TransactionStateIdle extends TransactionState {
  const TransactionStateIdle();
}

class TransactionStateInitiated extends TransactionState {
  const TransactionStateInitiated({this.transactionID});
  final String? transactionID;
}

class TransactionStateCompleted extends TransactionState {
  const TransactionStateCompleted({this.transactionID});
  final String? transactionID;
}

class TransactionStateFailed extends TransactionState {
  const TransactionStateFailed({this.reason});
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
