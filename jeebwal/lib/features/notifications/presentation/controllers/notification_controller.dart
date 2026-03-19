import 'package:get/get.dart';

class NotificationController extends GetxController {
  final notifications = [
    {
      'title': 'Payment Success',
      'body': 'Your fee payment for Cairo University was successful!',
      'type': 'Success',
      'time': '2 mins ago',
      'is_read': false,
    },
    {
      'title': 'New Wallet Linked',
      'body': 'You have successfully linked your Vodafone Cash wallet.',
      'type': 'Info',
      'time': '1 hour ago',
      'is_read': true,
    },
    {
      'title': 'Payment Failed',
      'body':
          'The transaction for Alexandria University failed. Please try again.',
      'type': 'Error',
      'time': '1 day ago',
      'is_read': true,
    },
  ].obs;

  void markAsRead(int index) {
    notifications[index]['is_read'] = true;
    notifications.refresh();
  }

  void clearAll() {
    notifications.clear();
  }
}
