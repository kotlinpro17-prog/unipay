import 'package:equatable/equatable.dart';

class PaymentTransaction extends Equatable {
  final String transactionId;
  final double amount;
  final DateTime date;
  final String status; // 'Success', 'Failed'
  final String methodId;

  const PaymentTransaction({
    required this.transactionId,
    required this.amount,
    required this.date,
    required this.status,
    required this.methodId,
  });

  @override
  List<Object?> get props => [transactionId, amount, date, status, methodId];
}
