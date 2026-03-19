import 'package:get/get.dart';
import 'app_routes.dart';
import '../features/auth/presentation/pages/splash_page.dart';
import '../features/auth/presentation/pages/welcome_page.dart';
import '../features/auth/presentation/pages/login_screen.dart';
import '../features/auth/presentation/pages/signup_screen.dart';
import '../features/auth/presentation/pages/forgot_password_page.dart';
import '../features/home/presentation/pages/home_page.dart';
import '../features/universities/presentation/pages/universities_list_page.dart';
import '../features/universities/presentation/pages/student_info_page.dart';
import '../features/universities/presentation/pages/fees_page.dart';
import '../features/payment/presentation/pages/wallets_list_page.dart';
import '../features/payment/presentation/pages/wallet_login_page.dart';
import '../features/payment/presentation/pages/payment_amount_page.dart';
import '../features/payment/presentation/pages/payment_confirmation_page.dart';
import '../features/payment/presentation/pages/receipt_page.dart';
import '../features/notifications/presentation/pages/notifications_page.dart';
import '../features/profile/presentation/pages/profile_page.dart';
import '../features/payment/presentation/pages/payment_review_page.dart';
import '../features/profile/presentation/pages/edit_profile_view.dart';
import '../features/profile/presentation/bindings/edit_profile_binding.dart';
import '../features/profile/presentation/pages/settings_page.dart';
import '../features/universities/presentation/bindings/student_binding.dart';
import '../features/auth/presentation/bindings/auth_binding.dart';

class AppPages {
  static const initial = AppRoutes.splash;

  static final routes = [
    GetPage(name: AppRoutes.splash, page: () => const SplashPage()),
    GetPage(name: AppRoutes.welcome, page: () => const WelcomePage()),
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.register,
      page: () => const SignUpScreen(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.signup,
      page: () => const SignUpScreen(),
      binding: AuthBinding(),
    ),

    GetPage(
      name: AppRoutes.forgotPassword,
      page: () => const ForgotPasswordPage(),
    ),
    GetPage(name: AppRoutes.dashboard, page: () => const HomePage()),
    GetPage(
      name: AppRoutes.universitySelection,
      page: () => const UniversitiesListPage(),
    ),
    GetPage(
      name: AppRoutes.studentInfo,
      page: () => const StudentInfoPage(),
      binding: StudentBinding(),
    ),
    GetPage(name: AppRoutes.fees, page: () => const FeesPage()),
    GetPage(name: AppRoutes.wallets, page: () => const WalletsListPage()),
    GetPage(name: AppRoutes.walletLogin, page: () => const WalletLoginPage()),
    GetPage(
      name: AppRoutes.paymentAmount,
      page: () => const PaymentAmountPage(),
    ),
    GetPage(
      name: AppRoutes.paymentConfirmation,
      page: () => const PaymentConfirmationPage(),
    ),
    GetPage(
      name: AppRoutes.paymentReview,
      page: () => const PaymentReviewPage(),
    ),
    GetPage(name: AppRoutes.receipt, page: () => const ReceiptPage()),
    GetPage(
      name: AppRoutes.notifications,
      page: () => const NotificationsPage(),
    ),
    GetPage(
      name: AppRoutes.editProfile,
      page: () => const EditProfileView(),
      binding: EditProfileBinding(),
    ),
    GetPage(name: AppRoutes.profile, page: () => const ProfilePage()),
    GetPage(name: AppRoutes.settings, page: () => const SettingsPage()),
  ];
}
