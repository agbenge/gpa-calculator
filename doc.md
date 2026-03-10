# GPA Calculator App Documentation

## How to Use the App

The GPA Calculator is designed to be a straightforward tool for students to track their academic performance. Here is how to use its core features:

1.  **Dashboard Overview**: When you open the application, you're presented with your Cumulative GPA (CGPA) and your current Class of Degree.
2.  **Toggle Grading Scale**: In the dashboard, you can toggle between a **5.0 scale** and a **4.0 scale** depending on your institution's standard. The Class of Degree calculations will adjust automatically based on your selection.
3.  **Manage Semesters**:
    *   **Add**: Click the floating action button (`+`) or the "Add Semester" button to create a new semester (e.g., "Year 1 - First Semester").
    *   **Delete**: You can remove a semester and all its associated courses if you made a mistake.
4.  **Manage Courses**:
    *   Tap on any semester to view its details.
    *   **Add Course**: Tap the `+` icon to add a new course. You will need to provide the **Course Code/Name**, **Units** (credit hours), and the **Grade** achieved (A, B, C, D, E, F).
    *   **Edit/Delete**: Courses can be modified or deleted directly from the semester view.
5.  **Calculate GPA**: As you add or update courses, the app automatically calculates your Semester GPA and updates your overall Cumulative GPA (CGPA) on the main dashboard.

## Scope of the Application

The current scope of the GPA Calculator application includes:

*   **Offline Data Persistence**: All inputted semesters, courses, and settings are saved locally on the device so you don't lose your data when you close the app.
*   **Dual Grading Systems**: Built-in support for both 4.0 and 5.0 grading systems.
*   **Real-time Calculation**: Instant computation of Semester GPA, Cumulative GPA, Total Registered Units, and Total Passed Units.
*   **Degree Classification**: Automatic mapping of CGPA to degree classifications (e.g., First Class, Second Class Upper, etc.) based on standard academic boundaries.

### Out of Scope (Currently)

*   Cloud syncing or multi-device backup.
*   Institution-specific custom grading scales (e.g., fractional grades like A-, B+).
*   Exporting transcripts as PDFs or images.

## App Privacy

The GPA Calculator is built with your privacy in mind.

*   **100% On-Device Storage (Currently)**: All data you enter into the application (semesters, courses, grades, settings) is stored purely locally on your personal device using internal secure storage mechanisms.
*   **No Mandatory Cloud Servers**: We do not maintain unified databases pulling your personal academic data. The application does not require internet access for its core calculations.
*   **Future Cloud/Drive Sync (Planned)**: We are planning an optional feature to allow users to securely backup and sync their data using their personal cloud accounts (like Google Drive). This will be strictly **opt-in**, and your data will remain exclusively under your control in your own storage account.
*   **No User Tracking**: We do not collect analytics, location data, or any other personal telemetry.
*   **Data Control**: You have absolute control over your information. Deleting courses or semesters removes them permanently from your storage. Uninstalling the app entirely clears all locally stored data.
