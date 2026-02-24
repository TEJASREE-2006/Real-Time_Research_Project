# accounts/urls.py
from django.urls import path
from . import views
from .views import text_to_speech_view
from .views import fetch_unsplash_images
from .views import generate_video

urlpatterns = [
    path('register/', views.register_user, name='register'),
    path('login/', views.login_user, name='login'),
#    path('generate-script/', views.generate_script, name='generate_script'),
    path('text_to_speech_view/', text_to_speech_view, name='text_to_speech_view'),
    path('fetch_unsplash_images/', fetch_unsplash_images, name='fetch_unsplash_images'),
    path('generate_video/', generate_video, name='generate_video')
]