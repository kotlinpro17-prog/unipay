from django.test import TestCase, Client
from django.urls import reverse
from accounts.models import User
from university.models import University, College, Major, Course
from student.models import StudentProfile

class StudyPlanTests(TestCase):
    def setUp(self):
        self.client = Client()
        # Create a university user
        self.uni_user = User.objects.create_user(username='uni_user', password='password', role=User.Role.UNIVERSITY)
        self.university = University.objects.create(user=self.uni_user, name="Test Uni")
        
        # Create a student user
        self.student_user = User.objects.create_user(username='student_user', password='password', role=User.Role.STUDENT)
        self.student_profile = StudentProfile.objects.create(user=self.student_user)
        
        # Create college and major
        self.college = College.objects.create(university=self.university, name="Test College")
        self.major = Major.objects.create(
            university=self.university,
            college=self.college,
            name="Test Major",
            capacity=100,
            price_per_hour=100,
            min_gpa=80,
            duration=4
        )
        
        # Create courses
        self.course1 = Course.objects.create(
            major=self.major,
            name="Course 1",
            code="C1",
            credit_hours=3,
            year=1,
            semester=1
        )
        self.course2 = Course.objects.create(
            major=self.major,
            name="Course 2",
            code="C2",
            credit_hours=3,
            year=1,
            semester=2
        )

    def test_major_study_plan_authenticated_student(self):
        self.client.login(username='student_user', password='password')
        response = self.client.get(reverse('major_study_plan', args=[self.major.id]))
        self.assertEqual(response.status_code, 200)
        self.assertTemplateUsed(response, 'student/study_plan.html')
        self.assertEqual(response.context['major'], self.major)
        
        # Verify grouped data
        study_plan = response.context['study_plan']
        self.assertEqual(len(study_plan), 1) # Year 1
        self.assertEqual(study_plan[0]['year'], 1)
        self.assertEqual(len(study_plan[0]['semesters']), 2) # Semester 1 and 2

    def test_major_study_plan_permission_denied_for_uni(self):
        self.client.login(username='uni_user', password='password')
        response = self.client.get(reverse('major_study_plan', args=[self.major.id]))
        self.assertEqual(response.status_code, 403)

    def test_major_study_plan_not_found(self):
        self.client.login(username='student_user', password='password')
        response = self.client.get(reverse('major_study_plan', args=[999]))
        self.assertEqual(response.status_code, 404)

    def test_empty_study_plan(self):
        self.client.login(username='student_user', password='password')
        empty_major = Major.objects.create(
            university=self.university,
            college=self.college,
            name="Empty Major",
            capacity=100,
            price_per_hour=100,
            min_gpa=80,
            duration=4
        )
        response = self.client.get(reverse('major_study_plan', args=[empty_major.id]))
        self.assertEqual(response.status_code, 200)
        self.assertEqual(len(response.context['study_plan']), 0)
        self.assertContains(response, "عذراً، الخطة الدراسية لهذا التخصص غير متوفرة حالياً")
