from django.contrib.auth.models import AbstractUser
from django.db import models

class User(AbstractUser):
    class Role(models.TextChoices):
        ADMIN = "ADMIN", "Admin"
        STUDENT = "STUDENT", "Student"
        UNIVERSITY = "UNIVERSITY", "University"

    # Make username unique and the primary identification field
    username = models.CharField(max_length=150, unique=True)
    # email is also unique to ensure no duplicate emails for students
    email = models.EmailField(unique=True)
    
    role = models.CharField(max_length=50, choices=Role.choices, default=Role.STUDENT)

    USERNAME_FIELD = 'username'
    REQUIRED_FIELDS = ['email']

    def __str__(self):
        return f"{self.username} ({self.email})"
