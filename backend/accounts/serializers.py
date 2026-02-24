# accounts/serializers.py
from rest_framework import serializers
from .models import CustomUser
from django.contrib.auth import authenticate
from django.core.exceptions import ObjectDoesNotExist

class RegisterSerializer(serializers.ModelSerializer):
    class Meta:
        model = CustomUser
        fields = ['email', 'password', 'full_name']
        extra_kwargs = {'password': {'write_only': True}}

    def create(self, validated_data):
        return CustomUser.objects.create_user(
            email=validated_data['email'],
            password=validated_data['password'],
            full_name=validated_data['full_name']
        )

class LoginSerializer(serializers.Serializer):
    email = serializers.EmailField()
    password = serializers.CharField(write_only=True)

    def validate(self, data):
        """
        Custom validation for user login using email and password.
        """
        email = data['email']
        password = data['password']

        # Try to get the user based on email
        try:
            user = CustomUser.objects.get(email=email)
        except ObjectDoesNotExist:
            raise serializers.ValidationError("Invalid credentials. User not found.")

        # Check if the provided password matches the stored password
        if not user.check_password(password):
            raise serializers.ValidationError("Invalid credentials. Incorrect password.")
        
        # Return the user object if authentication is successful
        return {'user': user}
