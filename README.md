# 🎓 Examination System Database

This database is designed to manage a comprehensive **online examination system** for an educational institution. It supports user authentication, course and track management, exam creation, question handling, and student evaluations.

---

## ⚙️ System Requirements

- ✅ **Question Pool**:  
  The system must maintain a pool of questions so that instructors can select questions for exams.

- ✅ **Question Types**:  
  - Multiple Choice  
  - True/False  
  - Text (Descriptive) Questions  

- ✅ **Answer Validation**:
  - For **Multiple Choice** and **True/False**, the system stores the correct answer and auto-checks student responses to calculate results.
  - For **Text Questions**, the system stores a "best accepted answer" and uses **text functions** and **regular expressions** to auto-check student answers. The system should:
    - Highlight valid and invalid responses.
    - Allow instructors to review and manually adjust scores if needed (Bonus).

- ✅ **Course Management**:
  - Store Course Information: `Course Name`, `Description`, `Max Degree`, `Min Degree`.
  - Each **instructor** can teach one or more courses.
  - Each **course** may be taught by a different instructor per class/year.

- ✅ **Training Manager Capabilities**:
  - Add and edit:
    - Branches
    - Tracks within departments
    - Intakes (student batches)
  - Add students and define:
    - Personal details
    - Intake, Branch, and Track

- ✅ **User Roles and Authentication**:
  - Training Manager
  - Instructors
  - Students  
  All must have login accounts to access the system.

- ✅ **Exam Creation**:
  - Instructors can create exams **only for their assigned courses**.
  - They can:
    - Select number of questions of each type (manual or random).
    - Assign degrees per question (Total must not exceed the course's Max Degree).
  - A course may have multiple exams.

- ✅ **Exam Details**:
  Each exam must include:
  - Type: `Exam` or `Corrective`
  - Intake, Branch, Track
  - Course
  - Start Time, End Time
  - Total Time and Allowance Options

- ✅ **Exam Assignments**:
  - System must store exam metadata: year, course, instructor.
  - Instructors can select students to take a specific exam and set the schedule.
  - Students can only see and attempt the exam at the specified time.

- ✅ **Student Performance**:
  - The system stores each student's answers.
  - Automatically calculates scores for auto-gradable questions.
  - Final result per student per course is stored.

---

## 🧪 Testing
Ensure you:
- Insert **test data** in all tables.
- Fully **test the system functionality**, including exam creation, student answering, and result calculation.

---

✅ *This structured schema and system logic ensure modularity, scalability, and role-based control for real-world training institutions.*

