# Capstone V2 - Athlete Performance Tracker

This Django-based application provides a RESTful API for tracking and analyzing athlete performance data. It allows users to register, log in, manage their physical attributes, and submit test results.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing.

### Prerequisites

*   Python 3.8+
*   `pip` (Python package installer)

### Setup & Installation

1.  **Clone the `capstone_v2` branch:**
    ```bash
    git clone -b capstone_v2 https://github.com/julian-garcia04/capstone_v2.git
    cd capstone_v2
    ```

2.  **Create and activate a virtual environment:**
    *   On Windows:
        ```bash
        python -m venv .venv
        .\.venv\Scripts\activate
        ```
    *   On macOS/Linux:
        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        ```

3.  **Install the required packages:**
    ```bash
    pip install -r requirements.txt
    ```

4.  **Run the database migrations:**
    This will create the `db.sqlite3` file and set up the necessary database tables, including the initial benchmark data.
    ```bash
    python manage.py migrate
    ```

5.  **Run the development server:**
    ```bash
    python manage.py runserver
    ```
    The server will start, and you can access the API at `http://127.0.0.1:8000/`.

## How to Use the API

The best way to explore the API is through the **Browsable API** provided by Django REST Framework.

### 1. Register a New User

*   **Endpoint:** `POST /api/register/`
*   **Method:** `POST`
*   **Body:**
    ```json
    {
        "username": "your_username",
        "password": "your_password"
    }
    ```
*   **Action:** Go to `http://127.0.0.1:8000/api/register/` in your browser, enter a username and password in the HTML form at the bottom, and click "POST".

### 2. Log In

To access protected endpoints, you need to log in and get a session cookie.

*   **Action:**
    1.  Go to the login page for the browsable API: `http://127.0.0.1:8000/api-auth/login/`
    2.  Enter the credentials you just registered.
    3.  You will be redirected and are now authenticated.

### 3. View and Update Your Profile

*   **Endpoint:** `GET /api/athlete/me/` or `PUT /api/athlete/me/`
*   **Action:**
    1.  After logging in, navigate to `http://127.0.0.1:8000/api/athlete/me/`.
    2.  You will see your athlete profile (it will be created automatically on first visit).
    3.  To update your `grad_year`, `height_in`, or `weight_lb`, scroll to the bottom and use the `PUT` form.
*   **Example `PUT` Body:**
    ```json
    {
        "grad_year": 2026,
        "height_in": 70,
        "weight_lb": 180
    }
    ```

### 4. Add a New Test Result

*   **Endpoint:** `POST /api/athlete/tests/`
*   **Action:**
    1.  Navigate to `http://127.0.0.1:8000/api/athlete/tests/`.
    2.  Use the `POST` form at the bottom to submit test results.
*   **Example `POST` Body:**
    ```json
    {
        "sprint_40yd": 4.5,
        "vertical_jump": 35,
        "agility_t": 8.2
    }
    ```
    After submitting, you can go back to `/api/athlete/me/` to see the new test listed in your profile.

### Available Test Fields

You can include any of the following fields when posting a new test:

```
sprint_40yd, sprint_30m, flying_sprint, accel_10m,
split_5m, split_10m, split_20m, agility_t,
shuttle_run, lateral_agility, illinois_agility,
beep_level, cooper_test, interval_run, vertical_jump,
broad_jump, medicine_ball_throw, push_ups, sit_ups,
plank, lunges, box_jump
```

### 5. View Fit-Engine Results