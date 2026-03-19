
from django.test import TestCase, Client
from django.urls import reverse
from accounts.models import User
from university.models import University, Major, StudentEnrollment, FeePayment, StudentTransaction, Course
from student.models import StudentProfile, Application

class AcceptanceFeeTest(TestCase):
    def setUp(self):
        # Create University
        self.uni_user = User.objects.create_user(username='uni2', password='password', role=User.Role.UNIVERSITY)
        self.university = University.objects.create(user=self.uni_user, name="Test Uni 2")
        self.client.login(username='uni2', password='password')

        # Create Major
        self.major = Major.objects.create(
            university=self.university,
            name="Medicine",
            price_per_hour=100.00,
            min_gpa=95.00
        )
        
        # Create Course for Year 1 Semester 1 (so sync_courses picks it up)
        self.course = Course.objects.create(
            major=self.major,
            name="Anatomy 101",
            code="MED101",
            credit_hours=4,
            year=1,
            semester=1
        )

        # Create Student
        self.student_user = User.objects.create_user(username='student2', password='password', role=User.Role.STUDENT)
        self.student_profile = StudentProfile.objects.create(
            user=self.student_user,
            national_id="9876543210",
            phone_number="0788888888",
            high_school_score=98.00
        )
        
        # Create Application
        self.application = Application.objects.create(
            student=self.student_profile,
            major=self.major,
            status='PENDING'
        )

    def test_acceptance_generates_fees(self):
        # Trigger acceptance
        url = reverse('update_application_status', args=[self.application.id, 'ACCEPTED'])
        response = self.client.get(url) # The view uses GET for status updates based on the code provided (redirects)
        
        # Reload application
        self.application.refresh_from_db()
        self.assertEqual(self.application.status, 'ACCEPTED')
        
        # Check Enrollment created
        self.assertTrue(StudentEnrollment.objects.filter(student=self.student_profile, major=self.major).exists())
        
        # Check Fee Generated
        # Expected fee: 4 hours * 100 JD = 400 JD
        self.assertEqual(FeePayment.objects.filter(student=self.student_profile).count(), 1)
        fee = FeePayment.objects.first()
        self.assertEqual(fee.amount, 400.00)
        self.assertIn("رسوم دراسية", fee.description)
        
        # Check Transaction Created
        self.assertEqual(StudentTransaction.objects.filter(student=self.student_profile).count(), 1)
        trans = StudentTransaction.objects.first()
        self.assertEqual(trans.transaction_type, 'CHARGE')
        self.assertEqual(trans.amount, 400.00)
