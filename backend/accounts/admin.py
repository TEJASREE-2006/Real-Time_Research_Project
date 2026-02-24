#accounts/admin.py
from django.contrib import admin
from django.contrib.auth.admin import UserAdmin
from .models import CustomUser  # Import your custom user model

class CustomUserAdmin(UserAdmin):
    model = CustomUser
    # Set the fields that should appear in the admin interface
    list_display = ('email', 'full_name', 'is_active', 'is_staff')
    # Set the fields to order by in the admin interface
    ordering = ('email',)
    # Specify which fields should appear in the form when adding/editing a user
    fieldsets = (
        (None, {'fields': ('email', 'password')}),
        ('Personal info', {'fields': ('full_name',)}),
        ('Permissions', {'fields': ('is_active', 'is_staff')}),
    )
    add_fieldsets = (
        (None, {
            'classes': ('wide',),
            'fields': ('email', 'password1', 'password2'),
        }),
    )

admin.site.register(CustomUser, CustomUserAdmin)
