# Capstone V2 - Backend Cheat Sheet

Welcome to the Django backend! This guide explains the basic workflow, the purpose of our key files, and how they all interact.

---

## 1. The Core Workflow

These are the most common tasks you'll perform during development.

### A. Running the Development Server

This command starts the local server so you can access the API.

1.  Activate the virtual environment: `.\.venv\Scripts\activate`
2.  Run the server: `python manage.py runserver`
3.  You can now access the API at `http://127.0.0.1:8000/`.

### B. Changing the Database (Models)

When you need to add or change a field in the database (e.g., adding a `nickname` to the `Athlete` model):

1.  **Edit `core/models.py`**: Make your changes to the model class.
2.  **Create a migration file**: This command creates the instructions for the database change.
    ```bash
    python manage.py makemigrations
    ```
3.  **Apply the migration**: This command runs the instructions to update the database.
    ```bash
    python manage.py migrate
    ```

### C. Testing the API

The easiest way to test is with the built-in **API Sandbox** (also called the Browsable API).

1.  Run the server.
2.  Go to the login page to authenticate: `http://127.0.0.1:8000/api-auth/login/`
3.  Navigate to any endpoint (e.g., `http://127.0.0.1:8000/api/athlete/me/`) to view data and use the HTML forms to `POST` or `PUT` new data.

---

## 2. Key Files & Their Roles

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

## 3. How It All Connects: The Life of an API Request

This is the most important concept. Here’s the journey of a request from the browser to the database and back.

**Example Request:** `GET /api/athlete/me/`

1.  **Browser -> Django**: A request arrives at the server.
2.  **Main URL Router (`capstone_v2/urls.py`)**: Django checks this file first. It finds `path('api/', include('core.urls'))` and passes the rest of the URL (`athlete/me/`) to the `core` app's URL file.
3.  **App URL Router (`core/urls.py`)**: This file finds a match for `path('athlete/me/', ...)` and sees that it needs to call the **`AthleteProfileView`**.
4.  **The View (`core/views.py`)**: The `get` method inside the `AthleteProfileView` class is executed.
5.  **View -> Model (`core/models.py`)**: The view needs data, so it uses the **Model** to talk to the database: `Athlete.objects.get_or_create(user=request.user)`.
6.  **Model -> Database**: The `Athlete` model gets the correct data from the `core_athlete` table.
7.  **Database -> View**: The database returns the data as a Python object (`athlete`).
8.  **View -> Serializer (`core/serializers.py`)**: The view now needs to format this data. It passes the `athlete` object to the **`AthleteSerializer`**.
9.  **Serializer -> JSON**: The `AthleteSerializer` converts the Python object into JSON format.
10. **View -> Browser**: The view sends the final JSON response back to the browser.

---

## 4. Useful Terminal Commands

- `python manage.py runserver`: Starts the development server.
- `python manage.py makemigrations`: Creates database change instructions.
- `python manage.py migrate`: Applies those changes to the database.
- `python manage.py shell`: Opens an interactive Python shell for your project.
- `python manage.py createsuperuser`: Creates an admin account.
- `python manage.py test`: Runs all automated tests.
