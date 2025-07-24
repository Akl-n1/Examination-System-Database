# Examination-System-Database
The database is designed to manage a comprehensive online examination system for an educational institution
------------------

#
System requirements: 
 System should provide question pool, so instructor can pick an exam from it. 
 Questions type may be Multiple choice, True & false or text questions. 
 For multiple choice and true & false questions system should store correct answer and check 
student answer and store his result. 
 For text question system should store best accepted answer and use text functions and regular 
expression to check student answer and display result to the instructor show him valid answers 
and not valid answers to review them and enter the marks manually (Bonus). 
 System should store courses information (Course name, description, Max degree, Min Degree), 
instructors’ information, and students’ information, each instructor can teach one or more course, 
and each course may be teacher by one instructor in each class (Instructor may be changed for 
other class in other year). 
 Training manager can add and edit: Branches, tracks in each department, and add new intake. 
 Training manager can add students, and define their personal data, intake, branch, and track. 
 Training manager, Instructors, Students should have a login account to access the system. 
 Instructor can make Exam (For his coLurse only) by selecting number of questions of each type, 
the system selects the questions random, or he can select them manually from question pool. 
And he must put a degree for each question on the exam, and total degrees must not exceed the 
course Max Degree (One course may has more than one exam). 
 For each exam, we should know type (exam or corrective), intake, branch, track, course, start 
time, End time, total time and allowance options. 
 System should store each exam which defined by year, Course, instructor. 
 Instructor can select students that can do specific exam, and define Exam date, start time and end 
time. Students can see the exam and do it only on the specified time. 
 System should store students answer for the exam and calculate the correct answers, and 
calculate final result for the student in this course. 
 Insert test data in all tables and test your system.
