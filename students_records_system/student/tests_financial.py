
from django.test import TestCase, Client
from django.urls import reverse
from accounts.models import User
from university.models import University, Major, College, StudentEnrollment, FeePayment, StudentTransaction
from student.models import StudentProfile

class FinancialTests(TestCase):
    def setUp(self):
        # Create University
        self.uni_user = User.objects.create_user(username='uni', password='password', role=User.Role.UNIVERSITY)
        self.university = University.objects.create(user=self.uni_user, name="Test Uni")
        self.client.login(username='uni', password='password')

        # Create Major
        self.major = Major.objects.create(
            university=self.university,
            college=College.objects.create(university=self.university, name="IT"),
            name="CS",
            price_usd=150.00,
            min_gpa=80.00
        )

        # Create Student
        self.student_user = User.objects.create_user(username='student', password='password', role=User.Role.STUDENT)
        self.student_profile = StudentProfile.objects.create(
            user=self.student_user,
            national_id="1234567890",
            phone_number="0790000000"
        )
        
        # Create Enrollment
        self.enrollment = StudentEnrollment.objects.create(
            student=self.student_profile,
            major=self.major,
            status='ACTIVE'
        )

    def test_invoice_generation_creates_transaction(self):
        # Trigger invoice generation (via POST to student_academic_detail)
        # Note: We need to mock having courses registered, otherwise total_hours is 0
        from university.models import Course, StudentCourse
        course = Course.objects.create(
            major=self.major, name="Intro to CS", code="CS101", 
            credit_hours=3, year=1, semester=1
        )
        StudentCourse.objects.create(
            enrollment=self.enrollment, course=course, 
            year_taken=1, semester_taken=1, status='ENROLLED'
        )

        response = self.client.post(reverse('student_academic_detail', args=[self.enrollment.id]), {
            'action': 'generate_invoice'
        })
        
        # Check FeePayment created
        self.assertEqual(FeePayment.objects.count(), 1)
        fee = FeePayment.objects.first()
        expected_amount = 150.00 * 250.00 # price_usd * university.exchange_rate (default 250)
        self.assertEqual(fee.amount, expected_amount)
        
        # Check Transaction created
        self.assertEqual(StudentTransaction.objects.count(), 1)
        trans = StudentTransaction.objects.first()
        self.assertEqual(trans.transaction_type, 'CHARGE')
        self.assertEqual(trans.amount, expected_amount)
        self.assertEqual(trans.related_fee, fee)

    def test_add_payment_creates_transaction(self):
        url = reverse('add_student_payment', args=[self.enrollment.id])
        response = self.client.post(url, {
            'amount': '100.00',
            'note': 'Partial Payment'
        })
        
        self.assertEqual(StudentTransaction.objects.count(), 1)
        trans = StudentTransaction.objects.first()
        self.assertEqual(trans.transaction_type, 'PAYMENT')
        self.assertEqual(trans.amount, 100.00)
        self.assertIn('Partial Payment', trans.description)

    def test_balance_calculation(self):
        # 1. Add Charge (via direct model creation for speed)
        StudentTransaction.objects.create(
            university=self.university,
            student=self.student_profile,
            amount=150.00,
            transaction_type='CHARGE',
            description="Fee 1"
        )
        
        # 2. Add Payment
        StudentTransaction.objects.create(
            university=self.university,
            student=self.student_profile,
            amount=50.00,
            transaction_type='PAYMENT',
            description="Pay 1"
        )
        
        # Check student view context
        self.client.logout()
        self.client.login(username='student', password='password')
        response = self.client.get(reverse('my_fees'))
        
        self.assertEqual(response.context['current_balance'], 100.00)
        self.assertEqual(response.context['total_charges'], 150.00)
        self.assertEqual(response.context['total_payments'], 50.00)
        self.assertEqual(len(response.context['statement']), 2)

    def test_usd_fields_populated(self):
        # 1. Test Charge USD population
        url = reverse('student_academic_detail', args=[self.enrollment.id])
        from university.models import Course, StudentCourse
        course = Course.objects.create(
            major=self.major, name="Intro to CS", code="CS101", 
            credit_hours=3, year=1, semester=1
        )
        StudentCourse.objects.create(
            enrollment=self.enrollment, course=course, 
            year_taken=1, semester_taken=1, status='ENROLLED'
        )

        self.client.login(username='uni', password='password')
        self.client.post(url, {'action': 'generate_invoice'})
        
        trans = StudentTransaction.objects.filter(transaction_type='CHARGE').first()
        self.assertEqual(float(trans.amount_usd), 150.00)
        self.assertEqual(float(trans.exchange_rate), 250.00)
        
        # 2. Test Payment USD population
        url_pay = reverse('add_student_payment', args=[self.enrollment.id])
        self.client.post(url_pay, {
            'amount': '500.00',
            'note': 'Test Payment'
        })
        
        pay_trans = StudentTransaction.objects.filter(transaction_type='PAYMENT').first()
        self.assertEqual(float(pay_trans.amount_usd), 500.00 / 250.00)
        self.assertEqual(float(pay_trans.exchange_rate), 250.00)
