# Examination System - README

## Overview
This project is a comprehensive examination system designed to manage students, instructors, courses, questions, and exams for a training center.

---

## Features

1. **Question Pool**  
   The system provides a question pool from which instructors can select questions to build exams.

2. **Question Types**  
   - Multiple Choice Questions (MCQ)  
   - True/False Questions  
   - Text Questions

3. **Answer Validation**
   - MCQ & True/False: The system stores the correct answer and automatically checks the student’s answer.
   - Text Questions: The system stores the best accepted answer and uses text functions and regular expressions to validate student responses. It also displays valid/invalid answers for manual review and grading (Bonus feature).

4. **Course Management**  
   Stores course information including:
   - Course name  
   - Description  
   - Max degree  
   - Min degree  
   Instructors can teach multiple courses, and each course is assigned to one instructor per class (may vary by year/class).

5. **Admin Features (Training Manager)**
   - Add/Edit branches, tracks, and intakes.
   - Add students and define their personal data, intake, branch, and track.

6. **User Accounts**  
   - Training Manager, Instructors, and Students must log in to access the system.

7. **Exam Creation by Instructor**
   - Instructors can create exams for their own courses by selecting questions randomly or manually.
   - Assign degrees to each question.
   - Total exam score must not exceed the course’s Max Degree.
   - One course can have multiple exams.

8. **Exam Details**
   - Each exam includes:
     - Type: Exam or Corrective  
     - Intake, Branch, Track, Course  
     - Start/End time  
     - Duration  
     - Allowance options

9. **Exam Storage**
   - Each exam is stored and linked with the Year, Course, and Instructor.

10. **Student Exam Assignment**
    - Instructors define which students can take which exams.
    - Students can access exams only at the specified time.

11. **Answer Submission and Grading**
    - The system stores student answers.
    - Automatically calculates correct answers and final results for the course.

12. **Test Data**
    - Insert appropriate test data into all tables to fully test the system.

---

## Note
Ensure all user roles have proper access control and validation mechanisms.
