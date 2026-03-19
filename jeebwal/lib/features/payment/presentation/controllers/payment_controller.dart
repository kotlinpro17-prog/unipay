import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../routes/app_routes.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/entities/payment_transaction.dart';
import '../../domain/repositories/payment_repository.dart';
import '../../domain/usecases/get_payment_history_usecase.dart';
import '../../domain/usecases/get_payment_methods_usecase.dart';
import '../../domain/usecases/process_payment_usecase.dart';
import '../../../../core/error/failures.dart';

class PaymentController extends GetxController {
  final GetPaymentMethodsUseCase getPaymentMethodsUseCase;
  final ProcessPaymentUseCase processPaymentUseCase;
  final GetPaymentHistoryUseCase getPaymentHistoryUseCase;

  PaymentController({
    required this.getPaymentMethodsUseCase,
    required this.processPaymentUseCase,
    required this.getPaymentHistoryUseCase,
  });

  // Data
  final paymentMethods = <PaymentMethod>[].obs;
  final paymentHistory = <PaymentTransaction>[].obs;
  final selectedMethod = Rxn<PaymentMethod>();
  final lastTransaction = Rxn<PaymentTransaction>();
  final walletToken = RxnString();
  final walletPhone = RxnString();
  final walletBalance = 0.0.obs;
  final studentEnrollment = Rxn<dynamic>();

  // Controllers
  final amountController = TextEditingController();
  final walletNumberController = TextEditingController();
  final pinController = TextEditingController();

  final isLoading = false.obs;
  final amount = 0.0.obs;
  final selectedUniversityWallet = Rxn<Map<String, dynamic>>();

  @override
  void onInit() {
    super.onInit();
    _fetchPaymentMethods();
    _fetchPaymentHistory();

    // Check if we came with arguments
    if (Get.arguments != null) {
      if (Get.arguments is Map) {
        updateFromArguments(Map<String, dynamic>.from(Get.arguments));
      } else if (Get.arguments is PaymentMethod) {
        selectedMethod.value = Get.arguments;
      }
    }
  }

  void updateFromArguments(Map<String, dynamic> args) {
    try {
      print('DEBUG: PaymentController - Updating from arguments: ${args.keys}');

      if (args['token'] != null) {
        walletToken.value = args['token'].toString();
        // Fetch balance when we get a token
        fetchWalletBalance();
      }
      if (args['phone'] != null) {
        walletPhone.value = args['phone'].toString();
      }
      if (args['wallet'] != null && args['wallet'] is PaymentMethod) {
        selectedMethod.value = args['wallet'];
      }

      final dynamic sData = args['studentData'];
      if (sData != null) {
        // Use very safe access without explicit Map cast if possible
        try {
          final dynamic raw = sData['raw_student'];
          if (raw != null) {
            studentEnrollment.value = raw;
            print('DEBUG: PaymentController - Set studentEnrollment from raw');
          }

          final dynamic fees = sData['fees'];
          if (fees != null) {
            final String feeStr = fees.toString();
            final numericPart = feeStr.split(' ')[0].replaceAll(',', '');
            amountController.text = numericPart;
            amount.value = double.tryParse(numericPart) ?? 0.0;
            print('DEBUG: PaymentController - Set amount to: ${amount.value}');
          }
        } catch (innerError) {
          print('DEBUG: Error parsing studentData: $innerError');
        }
      }
    } catch (e, stack) {
      print('DEBUG: PaymentController - Error in updateFromArguments: $e');
      print(stack);
    }
  }

  Future<void> fetchWalletBalance() async {
    if (walletToken.value == null) return;

    final result = await (Get.find<PaymentRepository>()).getWalletBalance(
      walletToken.value!,
    );
    result.fold((failure) => print('DEBUG: Failed to fetch wallet balance'), (
      data,
    ) {
      if (data.containsKey('balance')) {
        walletBalance.value =
            double.tryParse(data['balance'].toString()) ?? 0.0;
        print('DEBUG: Wallet balance updated: ${walletBalance.value}');
      }
    });
  }

  Future<void> _fetchPaymentMethods() async {
    isLoading.value = true;
    final result = await getPaymentMethodsUseCase(NoParams());
    isLoading.value = false;
    result.fold(
      (failure) => Get.snackbar('Error', 'Failed to fetch payment methods'),
      (methods) => paymentMethods.value = methods,
    );
  }

  Future<void> _fetchPaymentHistory() async {
    final result = await getPaymentHistoryUseCase(NoParams());
    result.fold(
      (failure) => Get.snackbar('Error', 'Failed to fetch history'),
      (history) => paymentHistory.value = history,
    );
  }

  void selectMethod(PaymentMethod method) {
    selectedMethod.value = method;
    Get.toNamed(AppRoutes.walletLogin, arguments: method);
  }

  void setAmount(double val) {
    amount.value = val;
    amountController.text = val.toStringAsFixed(0);
  }

  Future<void> findStudent(String universityId) async {
    print(
      'DEBUG: PaymentController - Searching for student with ID: $universityId',
    );
    isLoading.value = true;
    final result = await (Get.find<PaymentRepository>()).getStudentDetails(
      universityId,
    );
    isLoading.value = false;

    result.fold(
      (failure) {
        print('DEBUG: PaymentController - Student search failed: $failure');
        Get.snackbar('تنبيه', 'لم يتم العثور على الطالب في هذا النظام الجامعي');
      },
      (enrollment) {
        print(
          'DEBUG: PaymentController - Student found: ${enrollment.studentName}',
        );
        studentEnrollment.value = enrollment;
        Get.toNamed(AppRoutes.paymentConfirmation);
      },
    );
  }

  Future<void> processUniversityPayment() async {
    if (studentEnrollment.value == null) {
      Get.snackbar('تنبيه', 'لم يتم تحديد بيانات الطالب');
      return;
    }

    if (amountController.text.isEmpty ||
        (double.tryParse(amountController.text) ?? 0) <= 0) {
      Get.snackbar('تنبيه', 'يرجى إدخال مبلغ صحيح');
      return;
    }

    if (selectedUniversityWallet.value == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار محفظة الجامعة المراد الدفع إليها');
      return;
    }

    isLoading.value = true;

    // Determine the identifier and description
    final isNewStudent = studentEnrollment.value!.status == 'PENDING_PAYMENT';
    final identifier = studentEnrollment.value!.payableId;
    final description = isNewStudent
        ? 'سداد رسوم تسجيل - معرف: $identifier'
        : 'سداد رسوم دراسية - رقم أكاديمي: $identifier';

    final result = await (Get.find<PaymentRepository>()).payUniversity(
      studentUniversityId: identifier,
      amount: double.tryParse(amountController.text) ?? 0.0,
      universityId: studentEnrollment.value!.universityDbId,
      description: description,
      token: walletToken.value, // Pass the wallet token
      universityWalletAcc: selectedUniversityWallet.value!['account_number'],
    );
    isLoading.value = false;

    result.fold(
      (failure) {
        // Try to show the actual error message if possible
        String errorMsg = 'فشلت عملية السداد، تأكد من وجود رصيد كافٍ في المحفظة';
        if (failure is ServerFailure) {
          final serverFailure = failure as ServerFailure;
          if (serverFailure.message != null) {
            errorMsg = serverFailure.message!;
          }
        }
        
        Get.snackbar(
          'خطأ',
          errorMsg,
          backgroundColor: Colors.red.withOpacity(0.9),
          colorText: Colors.white,
        );
      },
      (response) {
        // Merge enriched local data with backend response correctly
        final Map<String, dynamic> args = {
          ...response, // Spread response first
          'transaction_id':
              (response['student_system_response']?['ref_number']?.toString()) ??
              (response['ref_number']?.toString()) ??
              response['transaction_id'] ??
              'UNIV-${DateTime.now().millisecondsSinceEpoch}',
          'student_system_response': {
            ...(response['student_system_response'] is Map ? response['student_system_response'] : {}),
            'academic_id': response['academic_id'] ?? 
                          (response['student_system_response']?['academic_id']) ?? 
                          identifier,
            'student_name': studentEnrollment.value!.studentName,
            'university_name': studentEnrollment.value!.universityName,
            'amount': double.tryParse(amountController.text) ?? 0.0,
            'provider': selectedUniversityWallet.value?['provider_name'] ?? 'N/A',
            'wallet_acc': selectedUniversityWallet.value?['account_number'] ?? 'N/A',
            'status': response['status'] ?? 
                     (response['student_system_response']?['status']) ?? 
                     'مكتمل',
          },
        };
        Get.offNamed(AppRoutes.receipt, arguments: args);
      },
    );
  }

  Future<void> processPayment() async {
    if (selectedMethod.value == null) return;

    isLoading.value = true;
    final result = await processPaymentUseCase(
      ProcessPaymentParams(
        amount: double.tryParse(amountController.text) ?? 0.0,
        methodId: selectedMethod.value!.id,
        walletNumber: walletNumberController.text,
        pin: pinController.text,
      ),
    );
    isLoading.value = false;

    result.fold((failure) => Get.snackbar('Error', 'Payment failed'), (
      transaction,
    ) {
      lastTransaction.value = transaction;
      Get.offNamed(
        AppRoutes.receipt,
        arguments: {
          'transaction_id': transaction.transactionId,
          'student_system_response': {
            'academic_id': 'N/A',
            'status': 'Regular Payment',
          },
        },
      );
    });
  }

  void proceedToReview() {
    if (studentEnrollment.value != null) {
      if (selectedUniversityWallet.value == null) {
        Get.snackbar('تنبيه', 'يرجى اختيار محفظة الجامعة أولاً');
        return;
      }
      if (amountController.text.isEmpty ||
          (double.tryParse(amountController.text) ?? 0) <= 0) {
        Get.snackbar('تنبيه', 'يرجى إدخال مبلغ صحيح');
        return;
      }
      // Sync the observable amount for the review page
      amount.value = double.tryParse(amountController.text) ?? 0.0;
      Get.toNamed(AppRoutes.paymentReview);
    } else {
      processPayment(); // Legacy flow
    }
  }

  Future<void> confirmPayment() async {
    if (studentEnrollment.value != null) {
      await processUniversityPayment();
    } else {
      await processPayment();
    }
  }
}
