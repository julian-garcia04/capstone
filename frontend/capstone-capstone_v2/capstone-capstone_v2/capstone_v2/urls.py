#from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    # We are not using the admin panel
    # path('admin/', admin.site.urls), 

    # Include all the URLs from our 'core' app, prefixed with 'api/'
    path('api/', include('core.urls')),

    # Add login/logout for the browsable API
    path('api-auth/', include('rest_framework.urls')),
]
