import '../../domain/entities/payment_transaction.dart';

class PaymentTransactionModel extends PaymentTransaction {
  const PaymentTransactionModel({
    required super.transactionId,
    required super.amount,
    required super.date,
    required super.status,
    required super.methodId,
  });

  factory PaymentTransactionModel.fromJson(Map<String, dynamic> json) {
    return PaymentTransactionModel(
      transactionId: json['transactionId'],
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date']),
      status: json['status'],
      methodId: json['methodId'],
    );
  }
}
