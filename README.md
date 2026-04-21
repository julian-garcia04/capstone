# Capstone V2 - Athlete Performance Tracker

Starting XI is a full-stack sports science platform designed to track athlete measurables and provide real-time NCAA division fit analytics.

## System Architecture
The platform is built using a modern decoupled architecture:

- Backend: Django REST Framework (Python) providing a robust API for data persistence.

- Frontend: React + Vite + Tailwind CSS for a high-performance, responsive athlete dashboard.

- Analytics: R Shiny Performance Radar for complex data visualizations and benchmark comparisons.
## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing.

### Prerequisites

*   Python 3.10+
* Node.js (for the React frontend)
* R (with libraries: shiny, jsonlite, plotly, dplyr, tidyr)

### Setup & Installation

1.  **Clone the repository and switch to the cleanup branch:**
    ```bash
    git clone https://github.com/julian-garcia04/capstone_v2.git
    cd capstone_v2
    git checkout feature/dashboard-cleanup
    ```

2.  **Backend Setup (Django):**
**Create and activate a virtual environment::**
    ```bash
     python -m venv .venv
     source .venv/bin/activate # On Windows use: .\.venv\Scripts\activate
     ```
    
3. **Install requirements and initialize database:**
    ```bash
    pip install -r requirements.txt
    python manage.py migrate
    python manage.py loaddata core/fixtures/initial_benchmarks.json
    ```
4. **Start the server**
    ```bash
    python manage.py runserver #(Runs on port 8000)
    ```
   
5. **Frontend Setup (React) Navigate to the frontend directory and install dependencies:**
    ```bash
    cd frontend/Frontend
    npm install
    ```
   
6. **Run the React development server:**
    ```bash
    npm run dev #(Runs on port 8080)
    ```
   
7. **R Shiny Setup- Run athleteApp.R in R Studio **
    ```bash
    # Run this inside RStudio or your R terminal
    shiny::runApp('analytics/athleteApp.R', port = 6746)
    ```

# Critical Setup Workarounds
CSRF Bouncer Fix:
If you get a "CSRF cookie not set" error when signing in, navigate to http://127.0.0.1:8000/admin first. Loading the Django Admin page forces the session to initialize and drop the necessary security token.


