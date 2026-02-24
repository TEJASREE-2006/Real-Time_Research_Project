from django.test import TestCase
from django.urls import reverse
from rest_framework import status

class UserTests(TestCase):

    def test_signup(self):
        data = {
            'username': 'testuser',  # Assuming 'username' field is required based on your model
            'email': 'testuser@example.com',
            'password': 'testpass123'
        }
        response = self.client.post(reverse('register'), data, format='json')  # Use 'register' instead of 'signup'
        self.assertEqual(response.status_code, status.HTTP_201_CREATED)
        self.assertEqual(response.data['status'], 'success')  # Assert success response

    def test_login(self):
        # First, sign up the user
        self.client.post(reverse('register'), {
            'username': 'testuser',
            'email': 'testuser@example.com',
            'password': 'testpass123'
        }, format='json')

        # Now, test login
        data = {'email': 'testuser@example.com', 'password': 'testpass123'}
        response = self.client.post(reverse('login'), data, format='json')  # Use 'login' instead of 'signup'
        self.assertEqual(response.status_code, status.HTTP_200_OK)
        self.assertEqual(response.data['status'], 'success')  # Assert success response
