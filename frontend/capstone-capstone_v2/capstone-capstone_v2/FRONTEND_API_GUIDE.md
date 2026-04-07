# Starting XI - Frontend API Integration

**Base API URL:** `http://127.0.0.1:8000/api/`
**Authentication:** This API uses session cookies. After a successful Login, ensure your HTTP client (e.g., `axios` or `fetch`) is configured to send credentials/cookies with every subsequent request (e.g., `axios.defaults.withCredentials = true`).

---

### 1. The Authentication Pages (Login / Sign Up)

**A. Create Account Page**
*   **Endpoint:** `POST /register/`
*   **Purpose:** Creates a new user account and their linked empty Athlete profile.
*   **Request Body:**
    ```json
    {
        "username": "new_player",
        "password": "secure_password"
    }
    ```
*   **Response:** `201 Created`

**B. Login Page**
*   **Endpoint:** `POST /login/`
*   **Purpose:** Authenticates the user and sets the session cookie in the browser.
*   **Request Body:**
    ```json
    {
        "username": "new_player",
        "password": "secure_password"
    }
    ```
*   **Response:** `200 OK` (Browser automatically saves the session cookie).

---

### 2. The Athlete Dashboard / Profile Page

**A. View Profile (On Page Load)**
*   **Endpoint:** `GET /athlete/me/`
*   **Purpose:** Fetches the logged-in user's physical attributes (height, weight, grad year) and a list of all their historical test submissions.
*   **Response:** `200 OK` with JSON object containing profile data and a nested array of `tests`.

**B. Edit Profile Form (Save Button)**
*   **Endpoint:** `PUT /athlete/me/`
*   **Purpose:** Updates the athlete's basic physical attributes.
*   **Important Note:** This is *only* for profile info, not test scores.
*   **Request Body (Send only what changed):**
    ```json
    {
        "grad_year": 2026,
        "height_in": 72,
        "weight_lb": 185
    }
    ```

---

### 3. The Data Entry Page (Log a Workout)

**A. Submit New Test Results (Performance Metrics)**
*   **Endpoint:** `POST /athlete/tests/`
*   **Purpose:** Saves a new set of athletic performance scores to the database, timestamped to today. This creates a new entry in their historical record.
*   **Important Note:** This endpoint is *only* for the 22 physical tests (sprints, jumps, etc.). It does **not** accept changes to height, weight, or grad year.
*   **Request Body:** Send any combination of the available test fields.
    ```json
    {
        "sprint_40yd": 4.65,
        "vertical_jump": 32.5,
        "agility_t": 9.1
    }
    ```
    *(Note: See the README for the exact spelling of all 22 available test fields).*

**B. UI Tip: Handling Height/Weight Updates During a Workout Log**
If your UI design allows a user to update their weight at the exact same time they log a new sprint time, the frontend must make **two separate API calls**:
1.  **Call 1:** `PUT /athlete/me/` with `{"weight_lb": 185}` to update the profile.
2.  **Call 2:** `POST /athlete/tests/` with `{"sprint_40yd": 4.65}` to save the test scores.

---

### 4. The Fit Evaluation Page (The "Starting XI" Report)

**A. Generate Fit Report**
*   **Endpoint:** `GET /athlete/fit/`
*   **Purpose:** Runs the custom evaluation engine. It takes the athlete's **most recent** test and compares it against all division benchmarks.
*   **Response:** `200 OK`. Returns a detailed JSON report containing:
    *   `division_alignment`: A percentage score for each division (e.g., D1: 75%, D2: 88%).
    *   `recommended_division`: The highest division where they scored >= 80%.
    *   `strengths`: An array of text strings highlighting tests they passed.
    *   `weaknesses`: An array of text strings highlighting tests they failed.

---

### 5. The Progress & History Page (Charts / Graphs)

**A. Fetch Longitudinal Data**
*   **Endpoint:** `GET /athlete/readiness-history/`
*   **Purpose:** Returns an array of historical data specifically formatted for building a line chart. Shows how their Division 1 readiness percentage has changed over time.
*   **Response:** `200 OK`. Returns an array of objects:
    ```json
    [
        {
            "test_date": "2025-10-15",
            "readiness_score_percent": 45.5,
            "passed_benchmarks": 5,
            "total_benchmarks_measured": 11
        },
        {
            "test_date": "2025-11-20",
            "readiness_score_percent": 54.5,
            "passed_benchmarks": 6,
            "total_benchmarks_measured": 11
        }
    ]
    ```

---

### 6. Reference / Admin Data

**A. View All Benchmarks**
*   **Endpoint:** `GET /benchmarks/`
*   **Purpose:** Returns the master list of all passing standards for every division and every test. Useful if the frontend wants to build a giant reference table for users to look at.