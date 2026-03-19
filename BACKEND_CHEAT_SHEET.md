# Capstone V2 - Backend Cheat Sheet

This guide explains the core development workflow, the purpose of our key files, and how they all interact.

---

## 1. Core Development Workflow

These are the most common tasks you'll perform.

### A. Running the Local Server

This command starts the development server so you can access the API.

1.  **Activate the virtual environment:**
    ```shell
    .\.venv\Scripts\activate
    ```
2.  **Run the server:**
    ```shell
    python manage.py runserver
    ```
3.  The API is now available at `http://127.0.0.1:8000/`.

### B. Changing the Database (The Model Workflow)

When you need to add or change a database field (e.g., adding a `nickname` to the `Athlete` model):

1.  **Edit `core/models.py`**: Make your changes to the model class.
2.  **Create a migration file**: This command scans your models and creates the instructions for the database change.
    ```shell
    python manage.py makemigrations
    ```
3.  **Apply the migration**: This command runs the instructions to update the database structure.
    ```shell
    python manage.py migrate
    ```

### C. Testing the API with the API Sandbox

The easiest way to test is with the built-in **API Sandbox** (also called the Browsable API).

1.  **Run the server** (see step A).
2.  **Log in**: Go to `http://127.0.0.1:8000/api-auth/login/` to authenticate.
3.  **Explore**: Navigate to any endpoint (e.g., `/api/athlete/me/`) to view data and use the HTML forms to `POST` or `PUT` new data.

---

## 2. Project File Map

This is a map of the important files in our backend project.

| File | Purpose |
| :--- | :--- |
| **`manage.py`** | Your command-line tool for running Django commands (`runserver`, `migrate`, etc.). |
| **`capstone_v2/settings.py`** | The main configuration file. Contains database settings, installed apps, and middleware. |
| **`capstone_v2/urls.py`** | The **main URL router**. It's the first place Django looks to match an incoming URL. |
| **`core/urls.py`** | The **app-specific URL router**. It handles all URLs prefixed with `/api/`. |
| **`core/models.py`** | **Defines our database structure.** Each class here is a database table. |
| **`core/views.py`** | **Contains the logic for each API endpoint.** A view handles a request and returns a response. |
| **`core/serializers.py`** | **Converts our database models to JSON.** It's the translator between Python objects and the JSON data sent to the frontend. |
| **`requirements.txt`** | The "shopping list" of all Python packages needed for this project. |
| **`.gitignore`** | Tells Git which files and folders (like `.venv/`) to ignore. |

---

## 3. The Logic Behind an API Request

THIS IS THE MOST IMPORTANT CONCEPT. The timeline of a request from the browser to the database and back.

**Example Request:** A `GET` request to `/api/athlete/me/` Getting the data for the logged in athlete to see (height, weight, grad year, tests[]).

1.  **Request Arrives**: A request from a browser or client hits Django.
2.  **Main Router (`capstone_v2/urls.py`)**: Django checks this file first.
    - It finds `path('api/', include('core.urls'))`.
    - It passes the rest of the URL (`athlete/me/`) to the `core` app's URL file.
3.  **App Router (`core/urls.py`)**: This file scans its list.
    - It finds a match: `path('athlete/me/', AthleteProfileView.as_view(), ...)`.
    - It knows it must call the **`AthleteProfileView`**.
4.  **View Logic (`core/views.py`)**: The `get` method inside the `AthleteProfileView` class is executed.
    - The view needs data. It uses the model to talk to the database: `Athlete.objects.get_or_create(...)`.
5.  **Model & Database (`core/models.py`)**: The `Athlete` model fetches the correct data from the `core_athlete` table.
    - The database returns a Python object (`athlete`) back to the view.
6.  **Serializer (`core/serializers.py`)**: The view now needs to format this data for the response.
    - It passes the `athlete` object to the **`AthleteSerializer`**.
    - The serializer converts the Python object into a clean JSON format.
7.  **Response Sent**: The view sends the final JSON response back to the client.

---

## 4. Useful Terminal Commands

#### Project & Server
- `python manage.py runserver`: Starts the development server.
- `python manage.py test`: Runs all automated tests.

#### Database Migrations
- `python manage.py makemigrations`: Creates new migration files based on model changes.
- `python manage.py migrate`: Applies migrations to the database.

#### Database & Data
- `python manage.py shell`: Opens an interactive Python shell for your project.
- `python manage.py dbshell`: Opens a direct command-line interface to the database.
- `python manage.py createsuperuser`: Creates an admin account for the `/admin/` interface.
- `python manage.py loaddata <fixture_name>`: Loads initial data from a fixture file.
