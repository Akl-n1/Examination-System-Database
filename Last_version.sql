-- =========================================================
-- Create ExamSystem database with optimized file structure
-- =========================================================
CREATE DATABASE ExamSystem
ON PRIMARY (
    -- Primary data file configuration
    NAME = 'ExamSystem_Primary',
    FILENAME = 'D:\ExamSystem\ExamSystem_Primary.mdf',
    SIZE = 10MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 10MB
),
FILEGROUP DataFiles (
    -- Secondary data file for enhanced I/O distribution
    NAME = 'ExamSystem_Data',
    FILENAME = 'D:\ExamSystem\ExamSystem_Data.ndf',
    SIZE = 100MB,
    MAXSIZE = UNLIMITED,
    FILEGROWTH = 50MB
)
LOG ON (
    -- Log file with controlled growth limits
    NAME = 'ExamSystem_Log',
    FILENAME = 'D:\ExamSystem\ExamSystem_Log.ldf',
    SIZE = 100MB,
    MAXSIZE = 2GB,
    FILEGROWTH = 50MB
);

-- Switch to the newly created database
USE ExamSystem;

-- =====================================================
-- DATABASE SCHEMA DEFINITION
-- =====================================================

CREATE TABLE Role (
	RoleID    INT           PRIMARY KEY IDENTITY(1,1), -- Holds unique ID for each role
	RoleName  NVARCHAR(30)  NOT NULL UNIQUE            -- Holds role name like "Admin" or "Student"
);

-- Purpose: Educational institution branches
CREATE TABLE Branch (
	BranchID    INT           PRIMARY KEY IDENTITY(1,1), -- Holds unique ID for each branch
	BranchName  NVARCHAR(70)  NOT NULL UNIQUE            -- Holds branch name like "Zagazig"
);

-- Purpose: Store all available courses
CREATE TABLE Course (
	CourseID      INT            PRIMARY KEY IDENTITY(1,1),       -- Holds unique ID for each course
	CourseName    NVARCHAR(100)  NOT NULL,                        -- Holds course name like "C++"
	Description   NVARCHAR(MAX)  DEFAULT 'No Description',        -- Holds course description
    MaxDegree     INT            NOT NULL CHECK (MaxDegree > 0),  -- Holds highest possible grade
    MinDegree     INT            NOT NULL CHECK (MinDegree >= 0), -- Holds lowest possible grade
	
	-- Make sure minimum grade is not higher than maximum grade
	CONSTRAINT CK_Course_Degrees CHECK (MinDegree <= MaxDegree)
);

-- Purpose: Store login information for all users
CREATE TABLE [User] (
	UserID        INT            PRIMARY KEY IDENTITY(1,1),  -- Holds unique ID for each user
	UserName      NVARCHAR(100)  NOT NULL UNIQUE,            -- Holds username for login
	PasswordHash  NVARCHAR(MAX)  NOT NULL,                   -- Holds encrypted password
	CreatedDate   DATETIME       NOT NULL DEFAULT GETDATE(), -- Holds when account was created
	RoleID        INT            NOT NULL                    -- Holds which role this user has
);

-- =====================================================
-- ORGANIZATIONAL HIERARCHY TABLES
-- =====================================================

-- Purpose: Store different class groups (like Fall 2024, Spring 2025)
CREATE TABLE Intake (
    IntakeID    INT            PRIMARY KEY IDENTITY(1,1),  -- Holds unique ID for each intake
    IntakeName  NVARCHAR(100)  NOT NULL,                   -- Holds intake name like "Fall 2024"
    BranchID    INT            NOT NULL,                   -- Holds which branch this intake belongs to

	-- Prevent duplicate intake names within same branch
	CONSTRAINT UQ_Intake_Branch UNIQUE(IntakeName, BranchID)
);

-- Purpose: Store study tracks within each intake (like Web Development, Data Science)
CREATE TABLE Track (
    TrackID    INT            PRIMARY KEY IDENTITY(1,1),  -- Holds unique ID for each track
    TrackName  NVARCHAR(100)  NOT NULL,                   -- Holds track name like "Web Development"
    IntakeID   INT            NOT NULL,                    -- Holds which intake this track belongs to

	-- Prevent duplicate track names within same intake
	CONSTRAINT UQ_Track_Intake UNIQUE (TrackName, IntakeID)
);

-- =====================================================
-- QUESTION SYSTEM TABLES
-- =====================================================

-- Purpose: Master question repository with type validation
CREATE TABLE Question (
    QuestionID    INT            PRIMARY KEY IDENTITY(1,1),  -- Holds unique ID for each question
    QuestionText  NVARCHAR(MAX)  NOT NULL,                   -- Holds the actual question text
    QuestionType  NVARCHAR(10)   NOT NULL CHECK (QuestionType IN ('MCQ', 'TF', 'Text')), -- Holds question type: Multiple Choice, True/False, or Text
    CourseID      INT            NOT NULL                    -- Holds which course this question belongs to
);

-- Purpose: Store answer choices for multiple choice questions
CREATE TABLE QuestionChoice (
    ChoiceID    INT            PRIMARY KEY IDENTITY(1,1),  -- Holds unique ID for each choice
    ChoiceText  NVARCHAR(MAX)  NOT NULL,                   -- Holds the choice text like "A) Paris"
    IsCorrect   BIT            NOT NULL DEFAULT 0,         -- Holds if this choice is correct (1) or wrong (0)
    QuestionID  INT            NOT NULL                    -- Holds which question this choice belongs to
);

-- Purpose: Store correct answers for True/False questions
CREATE TABLE QuestionTrueFalse (
	-- One-to-one relationship with Question
    QuestionID     INT  PRIMARY KEY, -- Holds question ID (PK and FK at the same time)
    CorrectAnswer  BIT  NOT NULL     -- Holds correct answer: True (1) or False (0)
);

-- Purpose: Store best answers for text questions
CREATE TABLE QuestionText (
	-- One-to-one relationship with Question
    QuestionID          INT            PRIMARY KEY, -- Holds question ID (PK and FK at the same time)
    BestAcceptedAnswer  NVARCHAR(MAX)  NOT NULL     -- Holds the best answer for grading reference
);

-- =====================================================
-- PEOPLE TABLES
-- =====================================================

-- Purpose: Store instructor information
CREATE TABLE Instructor (
    InstructorID  INT            PRIMARY KEY IDENTITY(1,1), -- Holds unique ID for each instructor
    FirstName     NVARCHAR(50)   NOT NULL,                  -- Holds instructor's first name
    LastName      NVARCHAR(50)   NOT NULL,                  -- Holds instructor's last name
    Phone         NVARCHAR(20)   NULL,                      -- Holds instructor's phone number
    Email         NVARCHAR(255)  NOT NULL UNIQUE,           -- Holds instructor's email address
	Salary        INT            DEFAULT 0,                 -- Holds instructor's salary
    Gender        NVARCHAR(10)   NOT NULL CHECK (Gender IN ('Male', 'Female')), -- Holds instructor's gender
    DateOfBirth   DATE           NOT NULL CHECK (DateOfBirth <= GETDATE()), -- Holds instructor's birth date
    UserID        INT            NOT NULL UNIQUE,           -- Holds link to login account
    BranchID      INT            NOT NULL                   -- Holds which branch this instructor works at
);

-- Purpose: Store student information
CREATE TABLE Student (
    StudentID    INT            PRIMARY KEY IDENTITY(1,1), -- Holds unique ID for each student
    FirstName    NVARCHAR(50)   NOT NULL,                  -- Holds student's first name
    LastName     NVARCHAR(50)   NOT NULL,                  -- Holds student's last name
    Phone        NVARCHAR(20)   NULL,                      -- Holds student's phone number
    Email        NVARCHAR(255)  NOT NULL UNIQUE,           -- Holds student's email address
    Gender       NVARCHAR(10)   NOT NULL CHECK (Gender IN ('Male', 'Female')), -- Holds student's gender
    DateOfBirth  DATE           NOT NULL CHECK (DateOfBirth <= GETDATE()), -- Holds student's birth date
    UserID       INT            NOT NULL UNIQUE,           -- Holds link to login account
    TrackID      INT            NOT NULL                   -- Holds which track this student is enrolled in
);

-- =====================================================
-- EXAM SYSTEM TABLES
-- =====================================================

-- Purpose: Store exam details and scheduling
CREATE TABLE Exam (
    ExamID            INT            PRIMARY KEY IDENTITY(1,1), -- Holds unique ID for each exam
    ExamType          NVARCHAR(20)   NOT NULL CHECK (ExamType IN ('Exam', 'Corrective')), -- Holds exam type
    StartTime         DATETIME       NOT NULL,                  -- Holds when exam starts
    EndTime           DATETIME       NOT NULL,                  -- Holds when exam ends
    TotalTime         INT            NOT NULL,                  -- Holds exam duration
    CourseID		  INT			 NOT NULL,                  -- Holds which course this exam is for
    InstructorID	  INT			 NOT NULL,                  -- Holds which instructor created this exam
    TrackID			  INT			 NOT NULL,                  -- Holds which track takes this exam

	-- Make sure start time is before end time
	CONSTRAINT CK_Exam_Times CHECK (StartTime < EndTime)
);

-- =====================================================
-- CONNECTION TABLES (Who teaches what, who studies what)
-- =====================================================

-- Purpose: Track which instructor teaches which course in which year and class
CREATE TABLE InstructorCourse (
	Class         NVARCHAR(50) NOT NULL, -- Holds class name like "A"
	[Year]        INT          NOT NULL, -- Holds academic year like 2024
    InstructorID  INT          NOT NULL, -- Holds which instructor
    CourseID      INT          NOT NULL, -- Holds which course

	-- Composite primary key ensures unique teaching assignments
    PRIMARY KEY (InstructorID, CourseID, [Year], Class)
);

-- Purpose: Track which student is enrolled in which course
CREATE TABLE StudentCourse (
    StudentID  INT NOT NULL, -- Holds which student
    CourseID   INT NOT NULL, -- Holds which course

    PRIMARY KEY (StudentID, CourseID)
);

-- Purpose: Track which questions are in which exam and their points
CREATE TABLE ExamQuestion (
    Degree      INT NOT NULL CHECK (Degree > 0), -- Holds how many points this question is worth
    ExamID      INT NOT NULL,                    -- Holds which exam
    QuestionID  INT NOT NULL,                    -- Holds which question

    PRIMARY KEY (ExamID, QuestionID),
	-- Question Degree validation
    CONSTRAINT CK_ExamQuestion_Degree_Positive CHECK (Degree > 0)
);

-- Purpose: Store student answers and scores for each question in each exam
CREATE TABLE StudentQuestionExam (
    StudentAnswer  NVARCHAR(MAX),               -- Holds what the student answered
    Score          INT CHECK (Score >= 0),      -- Holds points earned for this question
    StudentID      INT NOT NULL,                -- Holds which student
    QuestionID     INT NOT NULL,                -- Holds which question
    ExamID         INT NOT NULL,                -- Holds which exam

    PRIMARY KEY (StudentID, QuestionID, ExamID),
	-- Exam Score validation
    CONSTRAINT CK_StudentQuestionExam_Score_NonNegative CHECK (Score >= 0)
);
GO

-- =====================================================
-- TABLE RELATIONSHIPS (Foreign Keys)
-- =====================================================

-- Connect users to their roles
ALTER TABLE [User]              ADD CONSTRAINT FK_User_Role                   FOREIGN KEY (RoleID)       REFERENCES Role(RoleID) ON DELETE NO ACTION ON UPDATE CASCADE;

-- Connect instructors to their login accounts and branches
ALTER TABLE Instructor          ADD CONSTRAINT FK_Instructor_User             FOREIGN KEY (UserID)       REFERENCES [User](UserID) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Instructor          ADD CONSTRAINT FK_Instructor_Branch           FOREIGN KEY (BranchID)     REFERENCES Branch(BranchID) ON DELETE NO ACTION ON UPDATE CASCADE;

-- Connect students to their login accounts and tracks
ALTER TABLE Student             ADD CONSTRAINT FK_Student_User                FOREIGN KEY (UserID)       REFERENCES [User](UserID) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE Student             ADD CONSTRAINT FK_Student_Track               FOREIGN KEY (TrackID)      REFERENCES Track(TrackID) ON DELETE NO ACTION ON UPDATE CASCADE; 

-- Connect intakes to branches and tracks to intakes
ALTER TABLE Track               ADD CONSTRAINT FK_Track_Intake                FOREIGN KEY (IntakeID)     REFERENCES Intake(IntakeID) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE Intake              ADD CONSTRAINT FK_Intake_Branch               FOREIGN KEY (BranchID)     REFERENCES Branch(BranchID) ON DELETE NO ACTION ON UPDATE CASCADE;

-- Connect questions and their answers to courses
ALTER TABLE Question            ADD CONSTRAINT FK_Question_Course             FOREIGN KEY (CourseID)     REFERENCES Course(CourseID) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE QuestionChoice      ADD CONSTRAINT FK_QuestionChoice_Question     FOREIGN KEY (QuestionID)   REFERENCES Question(QuestionID) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE QuestionTrueFalse   ADD CONSTRAINT FK_QuestionTrueFalse_Question  FOREIGN KEY (QuestionID)   REFERENCES Question(QuestionID) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE QuestionText        ADD CONSTRAINT FK_QuestionText_Question       FOREIGN KEY (QuestionID)   REFERENCES Question(QuestionID) ON DELETE CASCADE ON UPDATE CASCADE;

-- Connect exams to courses, instructors, and locations
ALTER TABLE Exam                ADD CONSTRAINT FK_Exam_Course                 FOREIGN KEY (CourseID)     REFERENCES Course(CourseID) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE Exam                ADD CONSTRAINT FK_Exam_Instructor             FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE Exam                ADD CONSTRAINT FK_Exam_Track                  FOREIGN KEY (TrackID)      REFERENCES Track(TrackID);

-- Connect teaching assignments
ALTER TABLE InstructorCourse    ADD CONSTRAINT FK_InstructorCourse_Instructor FOREIGN KEY (InstructorID) REFERENCES Instructor(InstructorID) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE InstructorCourse    ADD CONSTRAINT FK_InstructorCourse_Course     FOREIGN KEY (CourseID)     REFERENCES Course(CourseID) ON DELETE CASCADE ON UPDATE CASCADE;

-- Connect student enrollments
ALTER TABLE StudentCourse       ADD CONSTRAINT FK_StudentCourse_Student       FOREIGN KEY (StudentID)    REFERENCES Student(StudentID) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE StudentCourse       ADD CONSTRAINT FK_StudentCourse_Course        FOREIGN KEY (CourseID)     REFERENCES Course(CourseID) ON DELETE CASCADE ON UPDATE CASCADE;

-- Connect exam questions
ALTER TABLE ExamQuestion        ADD CONSTRAINT FK_ExamQuestion_Exam           FOREIGN KEY (ExamID)       REFERENCES Exam(ExamID) ON DELETE CASCADE ON UPDATE CASCADE;
ALTER TABLE ExamQuestion        ADD CONSTRAINT FK_ExamQuestion_Question       FOREIGN KEY (QuestionID)   REFERENCES Question(QuestionID);

-- Connect student answers and scores
ALTER TABLE StudentQuestionExam ADD CONSTRAINT FK_SQE_Student                 FOREIGN KEY (StudentID)    REFERENCES Student(StudentID) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE StudentQuestionExam ADD CONSTRAINT FK_SQE_Question                FOREIGN KEY (QuestionID)   REFERENCES Question(QuestionID) ON DELETE NO ACTION ON UPDATE CASCADE;
ALTER TABLE StudentQuestionExam ADD CONSTRAINT FK_SQE_Exam                    FOREIGN KEY (ExamID)       REFERENCES Exam(ExamID);
GO

-- =====================================================
-- SAMPLE DATA FOR TESTING
-- =====================================================

INSERT INTO Role (RoleName) VALUES 
('Admin'),            -- Role 1
('Training Manager'), -- Role 2
('Instructor'),       -- Role 3
('Student');          -- Role 4

INSERT INTO Branch (BranchName) VALUES 
('Smart Village'), -- Branch 1
('Alexandria'),    -- Branch 2
('Mansoura');      -- Branch 3

-- Available courses
INSERT INTO Course (CourseName, Description, MaxDegree, MinDegree) VALUES
('SQL Server Development',   'A Comprehensive Course On SQL Server From Basics To Advanced Topics.',           100, 50), -- Course 1 - SQL
('C# Programming',           'Learn C# And.NET Framework To Build Powerful Applications.',                     100, 50), -- Course 2 - C#
('Web Development (MERN)',   'Master The MERN Stack (MongoDB, Express, React, Node.js).',                      100, 50), -- Course 3 - MERN
('Python for Data Analysis', 'Explore Data Analysis Techniques Using Python Libraries Like Pandas and NumPy.', 100, 50), -- Course 4 - Python
('Java Fundamentals',        'Learn The Basics of Java Programming Including OOP and File Handling.',          100, 50), -- Course 5 - Java
('Front-End Development',    'Build Responsive Web Interfaces Using HTML, CSS, JavaScript, and Bootstrap.',    100, 50); -- Course 6 - Front-End

-- =====================================================
-- 2. USER ACCOUNTS
-- =====================================================

INSERT INTO [User] (UserName, PasswordHash, RoleID) VALUES
-- Admin account
('SystemAdmin', 'hashed_password_0',  1), -- Admin   = UserID = 1
-- Manager account
('Manager.Ali', 'hashed_password_1',  2), -- Manager = UserID = 2
-- Instructor accounts
('Inst.Fatema', 'hashed_password_2',  3), -- Fatema  = UserID = 3
('Inst.Sara',   'hashed_password_3',  3), -- Sara    = UserID = 4
('Inst.Amr',    'hashed_password_4',  3), -- Amr     = UserID = 5
('Inst.Akram',  'hashed_password_5',  3), -- Akram   = UserID = 6
-- Student accounts
('Std.Mohamed', 'hashed_password_6',  4), -- Mohamed = UserID = 7
('Std.Hassan',  'hashed_password_7',  4), -- Hassan  = UserID = 8
('Std.Yara',    'hashed_password_8',  4), -- Yara    = UserID = 9
('Std.Omar',    'hashed_password_9',  4), -- Omar    = UserID = 10
('Std.Nour',    'hashed_password_10', 4), -- Nour    = UserID = 11
('Std.Khaled',  'hashed_password_11', 4), -- Khaled  = UserID = 12
('Std.Lina',    'hashed_password_12', 4); -- Lina    = UserID = 13


-- =====================================================
-- 3. ORGANIZATIONAL STRUCTURE
-- =====================================================

-- Academic intakes per branch
INSERT INTO Intake (IntakeName, BranchID) VALUES 
('2024', 1), -- Intake 1 For Branch 1 (Smart Village)
('2026', 2), -- Intake 2 For Branch 2 (Alexandria)
('2028', 1), -- Intake 3 For Branch 1 (Smart Village)
('2025', 3), -- Intake 4 For Branch 3 (Mansoura)
('2029', 2), -- Intake 5 For Branch 2 (Alexandria)
('2027', 3); -- Intake 6 For Branch 3 (Mansoura)


-- Study tracks within intakes
INSERT INTO Track (TrackName, IntakeID) VALUES
('.NET Development',      1),  -- Track 1 for Intake 1 (2024, Smart Village)
('MERN Stack',            1),  -- Track 2 for Intake 1 (2024, Smart Village)
('Java Enterprise',       2),  -- Track 3 for Intake 2 (2026, Alexandria)
('Data Science',          3),  -- Track 4 for Intake 3 (2028, Smart Village)
('Front-End Development', 4),  -- Track 5 for Intake 4 (2025, Mansoura)
('Python Backend',        5);  -- Track 6 for Intake 5 (2029, Alexandria)

-- =====================================================
-- 4. QUESTION BANK
-- =====================================================

INSERT INTO Question (QuestionText, QuestionType, CourseID) VALUES
('What Does SQL Stand For?',                                           'MCQ',   1), -- QID 1,  MCQ    Course SQL
('Which Command Is Used To Create A Table?',                           'MCQ',   1), -- QID 2,  MCQ    Course SQL
('Primary Key Can Contain Null Values.',                               'TF',    1), -- QID 3,  TF     Course SQL
('What Is C#?',                                                        'Text',  2), -- QID 4,  TEXT   Course C#
('Is C# A Statically-Typed Language?',                                 'TF',    2), -- QID 5,  TF     Course C#
('What Does MERN Stand For?',                                          'MCQ',   3), -- QID 6,  MCQ    Course MERN
('What Is The Core Component Of React?',                               'MCQ',   3), -- QID 7,  MCQ    Course MERN
('Explain The Concept Of Virtual DOM.',                                'Text',  3), -- QID 8,  TEXT   Course MERN
('What Is The Main Use Of Pandas Library?',                            'MCQ',   4), -- QID 9,  MCQ    Course Python
('Java Was Developed By Microsoft.',                                   'TF',    5), -- QID 10, TF     Course Java
('What Does CSS Stand For?',                                           'MCQ',   6), -- QID 11, MCQ    Course Front-End
('Explain The Difference Between `let` And `const` In JavaScript.',    'Text',  6), -- QID 12, TEXT   Course Front-End
('What Is The Difference Between DELETE And TRUNCATE?',                'Text',  1), -- QID 13, TEXT,  Course SQL
('The `JOIN` Clause Is Used To Combine Rows From Two Or More Tables.', 'TF',    1), -- QID 14, TF,    Course SQL
('What Is The Common Language Runtime (CLR)?',                         'MCQ',   2), -- QID 15, MCQ,   Course C#
('In C#, Can A Class Inherit From Multiple Classes?',                  'TF',    2), -- QID 16, TF,    Course C#
('What Is Express.js Used For In The MERN Stack?',                     'MCQ',   3), -- QID 17, MCQ,   Course MERN
('Which Keyword Is Used To Define A Function In Python?',              'MCQ',   4), -- QID 18, MCQ,   Course Python
('Explain What A Python Dictionary Is.',                               'Text',  4), -- QID 19, TEXT,  Course Python
('What Is The JVM?',                                                   'Text',  5), -- QID 20, TEXT,  Course Java
('Java Supports Multiple Inheritance.',                                'TF',    5), -- QID 21, TF,    Course Java
('What Is Bootstrap?',                                                 'MCQ',   6), -- QID 22, MCQ,   Course Front-End
('`<div>` Is An Inline Element In HTML.',                              'TF',    6); -- QID 23, TF,    Course Front-End


-- =====================================================
-- 5. QUESTION ANSWERS
-- =====================================================

-- Multiple choice answers
INSERT INTO QuestionChoice (QuestionID, ChoiceText, IsCorrect) VALUES
-- What Does SQL Stand For?
(1,  'Strong Question Language',          0), (1, 'Structured Query Language',      1), (1, 'Structured Question Language',     0),
-- Command Is Used To Create A Table?
(2,  'CREATE TABLE',                      1), (2, 'NEW TABLE',                      0), (2, 'ADD TABLE',                        0),
-- What Does MERN Stand For?
(6,  'MongoDB, Express, React, Node.js',  1), (6, 'MySQL, Express, React, Node.js', 0), (6, 'MongoDB, Ember, React, Node.js',   0),
-- What Is The Core Component Of React?
(7,  'State',                             0), (7, 'Props',                          0), (7, 'Components',                       1),
-- What Is The Main Use Of Pandas Library?
(9,  'Web Development',                   0), (9, 'Data Manipulation And Analysis', 1), (9, 'Game Development',                 0),
-- What Does CSS Stand For?
(11, 'Creative Style Sheets',             0), (11, 'Cascading Style Sheets',        1), (11, 'Computer Style Sheets',           0),
-- What Is The Common Language Runtime (CLR)?
(15, 'A C# Compiler',                     0), (15, 'A UI Design Tool',              0), (15, 'An Environment That Manages The Execution Of .NET Programs', 1),
-- What Is Express.js Used For In The MERN Stack?
(17, 'Database Management',               0), (17, 'Front-End UI Components',       0), (17, 'Building The Back-End API',       1),
-- Which Keyword Is Used To Define A Function In Python?
(18, 'function',                          0), (18, 'def',                           1), (18, 'fun',                             0),
-- What Is Bootstrap?
(22, 'A JS Library For 3D Graphics',      0), (22, 'A Front-End Framework For Building Responsive Websites', 1), (22, 'A Back-End Database', 0);



-- True/False answers
INSERT INTO QuestionTrueFalse (QuestionID, CorrectAnswer) VALUES
(3,  0), -- Primary Key Can Contain Null Values?                ---> False
(5,  1), -- Is C# A Statically-Typed Language?                  ---> True
(10, 0), -- Java Was Developed By Microsoft?                    ---> False
(14, 1), -- The `JOIN` Clause Is Used To Combine Rows...        ---> True
(16, 0), -- In C#, Can A Class Inherit From Multiple Classes?   ---> False
(21, 0), -- Java Supports Multiple Inheritance.                 ---> False
(23, 0); -- `<div>` Is An Inline Element In HTML.               ---> False


-- Text question model answers
INSERT INTO QuestionText (QuestionID, BestAcceptedAnswer) VALUES
(4,  'C# Is A Modern, Object-Oriented, And Type-Safe Programming Language.'),
(8,  'The Virtual DOM (VDOM) Is A Programming Concept Where A Virtual Representation Of A UI Is Kept In Memory And Synced With The Real DOM.'),
(12, '`let` Allows Reassignment Of Variables, While `const` Declares A Constant Variable That Cannot Be Reassigned.'),
(13, 'DELETE is a DML command that removes rows one by one and can be rolled back. TRUNCATE is a DDL command that deallocates all pages of a table and cannot be rolled back.'),
(19, 'A dictionary in Python is an unordered collection of data values, used to store data values like a map, which, unlike other Data Types that hold only a single value as an element, Dictionary holds key:value pair.'),
(20, 'The Java Virtual Machine (JVM) is an abstract machine that enables a computer to run a Java program.');


-- =====================================================
-- 6. INSTRUCTOR PROFILES
-- =====================================================

INSERT INTO Instructor (FirstName, LastName, Phone, Email, Salary, Gender, DateOfBirth, UserID, BranchID) VALUES
('Fatema', 'Zahran', '+201012345678', 'fatema.z@example.com', 25000, 'Female', '1985-05-20', 3, 1), -- Instructor 1 (Fatema) - User 3 - Works in Branch 1 (Smart Village)
('Sara',   'Adel',   '+201255566677', 'sara.a@example.com',   30000, 'Female', '1990-02-10', 4, 1), -- Instructor 2 (Sara)   - User 4 - Works in Branch 1 (Smart Village)
('Amr',    'Diab',   '+201098765432', 'amr.d@example.com',    40000, 'Male',   '1982-11-15', 5, 2), -- Instructor 3 (Amr)    - User 5 - Works in Branch 2 (Alexandria)
('Akram',  'Ahmed',  '+201165231546', 'akram.a@example.com',  35000, 'Male',   '1989-11-15', 6, 3); -- Instructor 4 (Akram)  - User 6 - Works in Branch 3 (Mansoura)


-- =====================================================
-- 7. STUDENT PROFILES
-- =====================================================

INSERT INTO Student (FirstName, LastName, Phone, Email, Gender, DateOfBirth, UserID, TrackID) VALUES
('Mohamed', 'Ali',     '+201065487795', 'mohamed.a@example.com', 'Male',   '2002-08-25', 7,  1), -- Student 1 (Mohamed) - User 7  - Enrolled in Track 1 (.NET Development)
('Hassan',  'Mahmoud', '+201563251484', 'hassan.m@example.com',  'Male',   '2003-01-30', 8,  2), -- Student 2 (Hassan)  - User 8  - Enrolled in Track 2 (MERN Stack)
('Yara',    'Ahmed',   '+201254357889', 'yara.a@example.com',    'Female', '2002-12-12', 9,  3), -- Student 3 (Yara)    - User 9  - Enrolled in Track 3 (Java Enterprise)
('Omar',    'Sherif',  '+201023456754', 'omar.s@example.com',    'Male',   '2003-03-03', 10, 1), -- Student 4 (Omar)    - User 10 - Enrolled in Track 1 (.NET Development)
('Nour',    'Tarek',   '+201125267842', 'nour.t@example.com',    'Female', '2002-07-19', 11, 4), -- Student 5 (Nour)    - User 11 - Enrolled in Track 4 (Data Scienc)
('Khaled',  'Ibrahim', '+201521534567', 'khaled.i@example.com',  'Male',   '2003-05-22', 12, 2), -- Student 6 (Khaled)  - User 12 - Enrolled in Track 2 (MERN Stack)
('Lina',    'Kamal',   '+201265432122', 'lina.k@example.com',    'Female', '2002-10-01', 13, 5); -- Student 7 (Lina)    - User 13 - Enrolled in Track 5 (Front-End Development)


-- =====================================================
-- 8. EXAMS
-- =====================================================

INSERT INTO Exam (ExamType, StartTime, EndTime, TotalTime, CourseID, InstructorID, TrackID) VALUES
('Exam',       '2024-08-01 09:00:00', '2024-08-01 11:00:00', 120, 1, 1, 1),  -- ExamID 1  - SQL Exam,       Instructor Fatema for .NET  track in Smart Village
('Corrective', '2024-08-15 09:00:00', '2024-08-15 11:00:00', 120, 1, 1, 1),  -- ExamID 2  - Corrective SQL, Instructor Fatema for .NET  track in Smart Village
('Exam',       '2024-09-01 10:00:00', '2024-09-01 12:00:00', 120, 3, 2, 2),  -- ExamID 3  - MERN Exam,      Instructor Sara   for MERN  track in Smart Village
('Exam',       '2026-03-10 10:00:00', '2026-03-10 11:30:00', 90,  5, 3, 3),  -- ExamID 4  - Java Exam,      Instructor Amr    for Java  track in Alexandria
('Exam',       '2028-05-20 13:00:00', '2028-05-20 15:00:00', 120, 4, 1, 4),  -- ExamID 5, - Python Exam,    Instructor Fatema for Data Science track in Smart Village
('Exam',	   '2025-04-15 09:00:00', '2025-04-15 10:30:00', 90,  6, 4, 5),  -- ExamID 6, - Front-End Exam  Instructor Akram for Front-End  track in Mansoura
('Corrective', '2025-10-15 09:00:00', '2025-10-15 10:30:00', 90,  6, 4, 5);  -- ExamID 7, - Corrective Front-End, Instructor Akram for Front-End track in Mansoura


-- =====================================================
-- 9. TEACHING ASSIGNMENTS
-- =====================================================

-- Assign instructors to courses
INSERT INTO InstructorCourse (InstructorID, CourseID, [Year], Class) VALUES
(1, 1, 2024, 'A'), (1, 2, 2024, 'A'), -- Instructor 1 (Fatema) -> SQL   | C#
(2, 3, 2024, 'B'), (2, 6, 2024, 'B'), -- Instructor 2 (Sara)   -> MERN  | Front-End
(3, 5, 2024, 'C'), (3, 4, 2024, 'C'), -- Instructor 3 (Amr)    -> Java  | Python
(4, 3, 2024, 'D');					  -- Instructor 4 (Akram)  -> MERN


-- Enroll students in courses
INSERT INTO StudentCourse (StudentID, CourseID) VALUES
(1, 1), (1, 2), (1, 3), -- Student 1 (Mohamed) - SQL  | C#        | MERN        -> 3 Courses
(2, 3), (2, 6), (2, 4), -- Student 2 (Hassan)  - MERN | Front-End | Python      -> 3 Courses
(3, 5), (3, 3),         -- Student 3 (Yara)    - Java | MERN                    -> 2 Courses
(4, 1), (4, 2),			-- Student 4 (Omar)    - SQL  | C#                      -> 2 Courses
(5, 4),			        -- Student 5 (Nour)    - Python                         -> 1 Course
(6, 2),	(6, 5), (6, 6), -- Student 6 (Khaled)  - C#   | Java      | Front-End   -> 3 Courses
(7, 1), (7, 4);			-- Student 7 (Lina)    - SQL  | Python                  -> 2 Courses


-- =====================================================
-- 10. ASSIGN QUESTIONS TO EXAM WITH POINTS
-- =====================================================

INSERT INTO ExamQuestion (ExamID, QuestionID, Degree) VALUES
-- Exam 1: SQL
(1, 1, 10), (1, 2, 15), (1, 3, 5),
-- Exam 2 (Corrective SQL)
(2, 13, 20), (2, 14, 10),
-- Exam 3: MERN
(3, 6, 10), (3, 7, 10), (3, 8, 20),
-- Exam 4: Java
(4, 10, 10), (4, 20, 20), (4, 21, 10),
-- Exam 5: Python for Data Analysis
(5, 9, 15), (5, 18, 10), (5, 19, 15),
-- Exam 6: Front-End Development
(6, 11, 25), (6, 22, 15),
-- Exam 7 (Corrective Front-End)
(7, 11, 10), (7, 12, 25), (7, 23, 5);


-- =====================================================
-- 11. STUDENT EXAM RESULTS 
-- =====================================================
INSERT INTO StudentQuestionExam (StudentID, ExamID, QuestionID, StudentAnswer, Score) VALUES
-- Scenario 1: .NET Track Students (Mohamed & Omar) in SQL Exam (Exam 1)
(1, 1, 1, 'Structured Query Language', 10),  -- Student 1 (Mohamed) - Correct Answer
(1, 1, 2, 'CREATE TABLE', 15),               -- Student 1 (Mohamed) - Correct Answer
(1, 1, 3, '1', 0),                           -- Student 1 (Mohamed) - Incorrect Answer (Chose True)
(4, 1, 1, 'Strong Question Language', 0),    -- Student 4 (Omar)    - Incorrect Answer
(4, 1, 2, 'NEW TABLE', 0),                   -- Student 4 (Omar)    - Incorrect Answer

-- Scenario 2: Omar failed Exam 1 and takes the Corrective SQL Exam (Exam 2)
(4, 2, 13, 'DELETE removes rows one by one, TRUNCATE is faster and removes all rows.', 18), -- Student 4 (Omar) - Good text answer
(4, 2, 14, '1', 10),                         -- Student 4 (Omar) - Correct TF answer

-- Scenario 3: MERN Track Students (Hassan & Khaled) in MERN Exam (Exam 3)
(2, 3, 6, 'MongoDB, Express, React, Node.js', 10),             -- Student 2 (Hassan) - Correct Answer
(2, 3, 8, 'It is a copy of the real DOM kept in memory.', 17), -- Student 2 (Hassan) - Good text answer
(6, 3, 6, 'MySQL, Express, React, Node.js', 0),                -- Student 6 (Khaled) - Incorrect Answer
(6, 3, 7, 'Components', 10),                                   -- Student 6 (Khaled) - Correct Answer

-- Scenario 4: Java Track Student (Yara) in Java Exam (Exam 4)
(3, 4, 10, '0', 10),                         -- Student 3 (Yara) - Correct TF Answer
(3, 4, 20, 'The Java Virtual Machine.', 18), -- Student 3 (Yara) - Good text answer
(3, 4, 21, '1', 0),                          -- Student 3 (Yara) - Incorrect TF Answer

-- Scenario 5: Data Science Track Student (Nour) in Python Exam (Exam 5)
(5, 5, 9, 'Data Manipulation And Analysis', 15), -- Student 5 (Nour) - Correct Answer
(5, 5, 18, 'def', 10),                           -- Student 5 (Nour) - Correct Answer

-- Scenario 6: Front-End Track Student (Lina) takes the Regular Front-End Exam (Exam 6)
(7, 6, 11, 'Creative Style Sheets', 0),                                   -- Student 7 (Lina  - Incorrect Answer
(7, 6, 22, 'A Front-End Framework For Building Responsive Websites', 15), -- Student 7 (Lina) - Correct Answer

-- Scenario 7: Lina also takes the Corrective Front-End Exam (Exam 7)
(7, 7, 11, 'Cascading Style Sheets', 10),                  -- Student 7 (Lina) - Correct Answer
(7, 7, 12, 'let can be reassigned but const cannot.', 22), -- Student 7 (Lina) - Good text answer
(7, 7, 23, '0', 5);                                        -- Student 7 (Lina) - Correct TF Answer
GO

-- =====================================================
-- INDEX
-- =====================================================

-- 1. Index For: Foreign Keys
CREATE NONCLUSTERED INDEX IX_User_RoleID                ON [User](RoleID);
CREATE NONCLUSTERED INDEX IX_Intake_BranchID            ON Intake(BranchID);
CREATE NONCLUSTERED INDEX IX_Track_IntakeID             ON Track(IntakeID);
CREATE NONCLUSTERED INDEX IX_Instructor_BranchID        ON Instructor(BranchID);
CREATE NONCLUSTERED INDEX IX_Student_TrackID            ON Student(TrackID);
CREATE NONCLUSTERED INDEX IX_Question_CourseID          ON Question(CourseID);
CREATE NONCLUSTERED INDEX IX_QuestionChoice_QuestionID  ON QuestionChoice(QuestionID);
CREATE NONCLUSTERED INDEX IX_Exam_CourseID              ON Exam(CourseID);
CREATE NONCLUSTERED INDEX IX_Exam_InstructorID          ON Exam(InstructorID);
CREATE NONCLUSTERED INDEX IX_Exam_TrackID               ON Exam(TrackID);
CREATE NONCLUSTERED INDEX IX_InstructorCourse_CourseID  ON InstructorCourse(CourseID);
CREATE NONCLUSTERED INDEX IX_StudentCourse_CourseID     ON StudentCourse(CourseID);
CREATE NONCLUSTERED INDEX IX_ExamQuestion_QuestionID    ON ExamQuestion(QuestionID);
CREATE NONCLUSTERED INDEX IX_SQE_ExamID                 ON StudentQuestionExam(ExamID);
CREATE NONCLUSTERED INDEX IX_SQE_QuestionID             ON StudentQuestionExam(QuestionID);

-- 2. Index For: WHERE, JOIN, ORDER BY
CREATE NONCLUSTERED INDEX IX_Student_Name               ON Student(FirstName, LastName);
CREATE NONCLUSTERED INDEX IX_Instructor_Name            ON Instructor(FirstName, LastName);
GO

-- =====================================================
-- VIEWS
-- =====================================================

CREATE OR ALTER VIEW VW_StudentData AS
	SELECT 
		U.UserName,
		S.StudentID,
		S.FirstName,
		S.LastName,
		S.Email,
		S.Phone,
		S.Gender,
		S.DateOfBirth,
		C.CourseName,
		T.TrackName,
		I.IntakeName,
		B.BranchName
	FROM 
		Student S 
		JOIN [User] U ON U.UserID = S.UserID
		JOIN Track  T ON T.TrackID = S.TrackID
		JOIN Intake I ON I.IntakeID = T.IntakeID
		JOIN Branch B ON B.BranchID = I.BranchID
		JOIN StudentCourse SC ON SC.StudentID = S.StudentID
		JOIN Course C ON SC.CourseID = C.CourseID
	WHERE
		U.UserName = USER_NAME()

		OR IS_MEMBER('TrainingManagerRole') = 1
		OR IS_MEMBER('InstructorRole') = 1
		OR IS_MEMBER('db_owner') = 1;
GO

CREATE OR ALTER VIEW VW_InstructorData AS
	SELECT
		I.InstructorID,
		U.UserName,
		I.FirstName + ' ' + I.LastName AS InstructorName,
		I.Email,
		I.Phone,
		I.Gender,
		I.DateOfBirth,
		I.Salary,
		B.BranchName,
		IC.Class,
		IC.[Year],
		C.CourseName
	FROM 
		Instructor I 
		JOIN [User] U ON U.UserID = I.UserID
		JOIN Branch B ON B.BranchID = I.BranchID
		JOIN InstructorCourse IC ON IC.InstructorID = I.InstructorID
		JOIN Course C ON C.CourseID = IC.CourseID
	WHERE
		U.UserName = USER_NAME()

		OR IS_MEMBER('TrainingManagerRole') = 1
		OR IS_MEMBER('db_owner') = 1;
GO

CREATE OR ALTER VIEW VW_CourseQuestionPool AS
	SELECT
		C.CourseName,
		Q.QuestionID,
		Q.QuestionText,
		Q.QuestionType
	FROM
		Question AS Q
		JOIN Course AS C ON Q.CourseID = C.CourseID
	WHERE
		IS_MEMBER('TrainingManagerRole') = 1
		OR IS_MEMBER('db_owner') = 1;
	-- ORDER BY Q.QuestionType, C.CourseName
GO

CREATE OR ALTER VIEW VW_ExamReport AS
	SELECT
		E.ExamID,
		E.ExamType,
		E.StartTime,
		E.EndTime,
		E.TotalTime,
		CASE 
			WHEN GETDATE() BETWEEN E.StartTime AND E.EndTime THEN 'In-Progress'
			WHEN GETDATE() < E.StartTime THEN 'Upcoming'
			WHEN GETDATE() > E.EndTime THEN 'Done'
		END AS [Status],
		C.CourseName,
		C.MinDegree AS CourseMinDegree,
		C.MaxDegree AS CourseMaxDegree,
		INS.FirstName + ' ' + INS.LastName AS InstructorName,
		T.TrackName,
		I.IntakeName,
		B.BranchName
	FROM 
		Exam E
		JOIN Course C ON E.CourseID = C.CourseID
		JOIN Instructor INS ON E.InstructorID = INS.InstructorID
		JOIN Track T ON E.TrackID = T.TrackID
		JOIN Intake I ON T.IntakeID = I.IntakeID
		JOIN Branch B ON I.BranchID = B.BranchID;
GO

CREATE OR ALTER VIEW VW_AvailableExams AS
	SELECT
		E.ExamID,
		E.ExamType,
		C.CourseName,
		INS.FirstName + ' ' + INS.LastName AS InstructorName,
		E.StartTime,
		E.EndTime,
		E.TotalTime,
		CASE
			WHEN GETDATE() BETWEEN E.StartTime AND E.EndTime THEN 'In-Progress'
			WHEN GETDATE() < E.StartTime THEN 'Upcoming'
		END AS [Status]
	FROM
		Exam E
		JOIN Course C ON E.CourseID = C.CourseID
		JOIN Instructor INS ON E.InstructorID = INS.InstructorID
		JOIN Student S ON E.TrackID = S.TrackID
		JOIN [User] U ON S.UserID = U.UserID
		JOIN StudentCourse SC ON S.StudentID = SC.StudentID AND E.CourseID = SC.CourseID
	WHERE
		E.EndTime >= GETDATE()
		AND U.UserName = USER_NAME();
GO

CREATE OR ALTER VIEW VW_BranchReport AS
	SELECT
		B.BranchName,
		I.IntakeName,
		T.TrackName,
		COUNT(S.StudentID) AS "NumberOfStudents"
	FROM
		Track T
		LEFT JOIN Student AS S ON t.TrackID = S.TrackID
		JOIN Intake AS I ON T.IntakeID = I.IntakeID
		JOIN Branch AS B ON I.BranchID = B.BranchID
	GROUP BY
		B.BranchName,
		I.IntakeName,
		T.TrackName;
GO

CREATE OR ALTER VIEW VW_StudentExamResults AS
	SELECT
		S.StudentID,
		S.FirstName + ' ' + S.LastName AS StudentName,
		E.ExamID,
		E.ExamType,
		C.CourseName,
		SUM(SQE.Score) AS StudentScore,
		(SELECT SUM(Degree) FROM ExamQuestion WHERE ExamID = E.ExamID) AS TotalExamDegree,
		CASE
			WHEN SUM(SQE.Score) >= (SELECT SUM(Degree) FROM ExamQuestion WHERE ExamID = E.ExamID) / 2 THEN 'Passed'
			WHEN SUM(SQE.Score) <  (SELECT SUM(Degree) FROM ExamQuestion WHERE ExamID = E.ExamID) / 2 THEN 'Failed'
		END AS [Status]
	FROM
		StudentQuestionExam SQE
		JOIN Student S ON SQE.StudentID = S.StudentID
		JOIN [User] U ON S.UserID = U.UserID 
		JOIN Exam E ON SQE.ExamID = E.ExamID
		JOIN Course C ON E.CourseID = C.CourseID
	WHERE
		-- نفس الفلتر السحري تاني
		U.UserName = USER_NAME()
		OR IS_MEMBER('TrainingManagerRole') = 1
		OR IS_MEMBER('InstructorRole') = 1
		OR IS_MEMBER('db_owner') = 1
	GROUP BY
		S.StudentID,
		S.FirstName,
		S.LastName,
		E.ExamID,
		E.ExamType,
		C.CourseName,
		U.UserName;
GO

CREATE OR ALTER VIEW VW_CourseDetails AS
	SELECT
		C.CourseID,
		C.CourseName,
		C.Description,
		C.MaxDegree,
		C.MinDegree,
		I.FirstName + ' ' + I.LastName AS InstructorName,
		(SELECT COUNT(StudentID) FROM StudentCourse WHERE CourseID = C.CourseID) AS EnrolledStudents
	FROM
		Course C
		JOIN InstructorCourse IC ON C.CourseID = IC.CourseID
		JOIN Instructor I ON IC.InstructorID = I.InstructorID;
GO

CREATE OR ALTER VIEW VW_QuestionWithAnswers AS
	SELECT
		Q.QuestionID,
		Q.QuestionText,
		Q.QuestionType,
		QC.ChoiceID,
		QC.ChoiceText,
		QC.IsCorrect,
		QTF.CorrectAnswer AS TrueFalseAnswer,
		QT.BestAcceptedAnswer AS ModelTextAnswer
	FROM
		Question Q
		LEFT JOIN QuestionChoice QC     ON Q.QuestionID = QC.QuestionID
		LEFT JOIN QuestionTrueFalse QTF ON Q.QuestionID = QTF.QuestionID
		LEFT JOIN QuestionText QT       ON Q.QuestionID = QT.QuestionID
GO

CREATE OR ALTER VIEW VW_StudentCourseCount AS
	SELECT 
		s.StudentID,
		CONCAT(s.FirstName, ' ', s.LastName) AS StudentName,
		COUNT(sc.CourseID) AS CourseCount
	FROM StudentCourse sc
	JOIN Student s ON sc.StudentID = s.StudentID
	GROUP BY s.StudentID, s.FirstName, s.LastName;
GO

CREATE OR ALTER VIEW VW_StudentAnswersDetails AS
	SELECT 
		sqe.StudentID,
		CONCAT(s.FirstName, ' ', s.LastName) AS StudentName,
		sqe.ExamID,
		sqe.QuestionID,
		q.QuestionText,
		sqe.StudentAnswer,
		sqe.Score
	FROM StudentQuestionExam sqe
	JOIN Student s ON sqe.StudentID = s.StudentID
	JOIN Question q ON sqe.QuestionID = q.QuestionID;
GO

CREATE OR ALTER VIEW VW_StudentExamCount AS
	SELECT 
		s.StudentID,
		CONCAT(s.FirstName, ' ', s.LastName) AS StudentName,
		COUNT(DISTINCT sqe.ExamID) AS ExamsCount
	FROM StudentQuestionExam sqe
	RIGHT JOIN Student s ON sqe.StudentID = s.StudentID
	GROUP BY s.StudentID, s.FirstName, s.LastName;
GO

CREATE OR ALTER VIEW VW_UnusedQuestions
AS
	SELECT 
		q.QuestionID,
		q.QuestionText,
		q.QuestionType,
		c.CourseName,
		CASE 
			WHEN q.QuestionType = 'MCQ' THEN 
				(SELECT COUNT(*) FROM QuestionChoice qc WHERE qc.QuestionID = q.QuestionID)
			ELSE NULL
		END AS NumberOfChoices
	FROM Question q
	JOIN Course c ON q.CourseID = c.CourseID
	LEFT JOIN ExamQuestion eq ON q.QuestionID = eq.QuestionID
	WHERE eq.QuestionID IS NULL
GO

CREATE OR ALTER VIEW VW_QuestionsReport
AS
SELECT 
    q.QuestionID,
    q.QuestionText,
    q.QuestionType,
    c.CourseName,
    c.CourseID,

    -- Exam Usage Status
    CASE 
        WHEN COUNT(eq.ExamID) > 0 THEN 'Used in Exams'
        ELSE 'Not Used in Exams'
    END AS ExamStatus,

    COUNT(DISTINCT eq.ExamID) AS TimesUsedInExams,

    STRING_AGG(
        'Exam ' + CAST(e.ExamID AS NVARCHAR) + ' (' + e.ExamType + ')',
        ', '
    ) AS ExamDetails,

    -- Number of choices for MCQ
    CASE 
        WHEN q.QuestionType = 'MCQ' THEN 
            (SELECT COUNT(*) FROM QuestionChoice qc WHERE qc.QuestionID = q.QuestionID)
        ELSE NULL
    END AS NumberOfChoices,

    -- True/False Correct Answer
    CASE 
        WHEN q.QuestionType = 'True/False' THEN 
            (SELECT CASE WHEN qtf.CorrectAnswer = 1 THEN 'True' ELSE 'False' END 
             FROM QuestionTrueFalse qtf WHERE qtf.QuestionID = q.QuestionID)
        ELSE NULL
    END AS CorrectAnswer,

    -- Best Text Answer Preview
    CASE 
        WHEN q.QuestionType = 'Text' THEN 
            (SELECT LEFT(qt.BestAcceptedAnswer, 50) + '...' 
             FROM QuestionText qt WHERE qt.QuestionID = q.QuestionID)
        ELSE NULL
    END AS BestAnswerPreview,

    -- Most used by instructor
    (
        SELECT TOP 1 i.FirstName + ' ' + i.LastName
        FROM ExamQuestion eq2 
        JOIN Exam e2 ON eq2.ExamID = e2.ExamID 
        JOIN Instructor i ON e2.InstructorID = i.InstructorID 
        WHERE eq2.QuestionID = q.QuestionID 
        GROUP BY i.InstructorID, i.FirstName, i.LastName 
        ORDER BY COUNT(*) DESC
    ) AS MostUsedByInstructor,

    -- Average Degree
    AVG(CAST(eq.Degree AS FLOAT)) AS AverageDegree,

    -- Difficulty Level
    CASE 
        WHEN AVG(CAST(sqe.Score AS FLOAT)) >= 0.8 THEN 'Easy'
        WHEN AVG(CAST(sqe.Score AS FLOAT)) >= 0.5 THEN 'Medium'
        WHEN AVG(CAST(sqe.Score AS FLOAT)) > 0 THEN 'Hard'
        ELSE 'Not Attempted'
    END AS DifficultyLevel,

    COUNT(DISTINCT sqe.StudentID) AS StudentsAttempted

FROM Question q
LEFT JOIN Course c ON q.CourseID = c.CourseID
LEFT JOIN ExamQuestion eq ON q.QuestionID = eq.QuestionID
LEFT JOIN Exam e ON eq.ExamID = e.ExamID
LEFT JOIN StudentQuestionExam sqe ON q.QuestionID = sqe.QuestionID

GROUP BY 
    q.QuestionID, q.QuestionText, q.QuestionType,
    c.CourseName, c.CourseID
GO

-- =====================================================
-- Stored Procedures
-- =====================================================

CREATE OR ALTER PROC SP_AddNewUser
    @UserName  NVARCHAR(100),
    @Password  NVARCHAR(MAX),
    @RoleName  NVARCHAR(50),
    @NewUserID INT OUTPUT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

        DECLARE @RoleID INT;
        SELECT @RoleID = RoleID FROM Role WHERE RoleName = @RoleName;

        IF @RoleID IS NULL
            THROW 78501, 'There is no Role with the provided name', 1;

        IF EXISTS (SELECT 1 FROM [User] WHERE UserName = @UserName)
            THROW 78502, 'Username already exists', 1;

        INSERT INTO [User] (UserName, PasswordHash, RoleID)
        VALUES (@UserName, @Password, @RoleID);

        SET @NewUserID = SCOPE_IDENTITY();
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROC SP_AddNewStudent
	@UserName  NVARCHAR(100),
	@Password  NVARCHAR(MAX),
	@FirstName NVARCHAR(50),
	@LastName  NVARCHAR(50),
	@Phone     NVARCHAR(20),
	@Email     NVARCHAR(255),
	@Gender    NVARCHAR(10),
	@DOB       DATE,
	@TrackID   INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
	BEGIN TRY
        IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
            THROW 50060, 'You are not authorized to preform This action.', 1;

		IF EXISTS (SELECT 1 FROM Student WHERE Email = @Email)
			THROW 50004, 'Email Already Exists', 1;

        DECLARE @NewUserID INT;
        EXEC SP_AddNewUser 
            @UserName = @UserName,
            @Password = @Password,
            @RoleName = 'Student',
            @NewUserID = @NewUserID OUTPUT;

        INSERT INTO Student (FirstName, LastName, Phone, Email, Gender, DateOfBirth, TrackID, UserID)
        VALUES (@FirstName, @LastName, @Phone, @Email, @Gender, @DOB, @TrackID, @NewUserID);

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		THROW;
	END CATCH
END
GO

CREATE OR ALTER PROC SP_AddNewInstructor
	@UserName  NVARCHAR(100),
	@Password  NVARCHAR(MAX),
	@FirstName NVARCHAR(50),
	@LastName  NVARCHAR(50),
	@Phone     NVARCHAR(20),
	@Email     NVARCHAR(255),
	@Gender    NVARCHAR(10),
	@Salary    INT,
	@DOB       DATE,
	@BranchID  INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
	BEGIN TRY
        IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
            THROW 50060, 'You are not authorized to preform This action.', 1;
		IF EXISTS (SELECT 1 FROM Instructor WHERE Email = @Email)
			THROW 50002, 'Email Already Exists', 1;

        DECLARE @NewUserID INT;
        EXEC SP_AddNewUser 
            @UserName = @UserName,
            @Password = @Password,
            @RoleName = 'Instructor',
            @NewUserID = @NewUserID OUTPUT;

        INSERT INTO Instructor (FirstName, LastName, Phone, Email, Gender, Salary, DateOfBirth, BranchID, UserID)
        VALUES (@FirstName, @LastName, @Phone, @Email, @Gender, @Salary, @DOB, @BranchID, @NewUserID);

        COMMIT;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROC SP_AddNewBranch
	@BranchName NVARCHAR(70)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
	BEGIN TRY
	    IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
            THROW 50060, 'You are not authorized to preform This action.', 1;
		IF EXISTS (SELECT 1 FROM Branch WHERE BranchName = @BranchName)
			THROW 50005, 'Branch Already Exists', 1;

		INSERT INTO Branch (BranchName)
		VALUES (@BranchName)

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		THROW;
	END CATCH
END
GO

CREATE OR ALTER PROC SP_AddNewIntake
	@IntakeName NVARCHAR(100),
	@BranchID INT
AS
BEGIN
	BEGIN TRANSACTION;
	BEGIN TRY
        IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
            THROW 50060, 'You are not authorized to preform This action.', 1;
		IF EXISTS (SELECT 1 FROM Intake WHERE IntakeName = @IntakeName AND BranchID = @BranchID)
			THROW 50006, 'There is an Intake in this Branch Already', 1;

		INSERT INTO Intake (IntakeName, BranchID)
		VALUES (@IntakeName, @BranchID)

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		THROW;
	END CATCH
END
GO

CREATE OR ALTER PROC SP_AddNewTrack
	@TrackName NVARCHAR(100),
	@IntakeID INT
AS
BEGIN
	BEGIN TRANSACTION;
	BEGIN TRY
        IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
            THROW 50060, 'You are not authorized to preform This action.', 1;
		IF EXISTS (SELECT 1 FROM Track WHERE TrackName = @TrackName AND IntakeID = @IntakeID)
			THROW 50007, 'There is a Track For this Intake Already', 1;

		INSERT INTO Track (TrackName, IntakeID)
		VALUES (@TrackName, @IntakeID)

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		THROW;
	END CATCH
END
GO

CREATE OR ALTER PROC SP_AddNewCourse
	@CourseName  NVARCHAR(100),
	@Description NVARCHAR(MAX) = NULL,
	@MaxDegree   INT,
	@MinDegree   INT
AS
BEGIN
	BEGIN TRANSACTION;
	BEGIN TRY
        IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
            THROW 50060, 'You are not authorized to preform This action.', 1;
		IF (@MaxDegree <= 0)
			THROW 50008, 'MaxDegree must be greater than 0', 1;
		IF (@MinDegree < 0)
			THROW 50009, 'MinDegree must be greater than or equal to 0', 1;
		IF (@MinDegree > @MaxDegree)
			THROW 50010, 'MinDegree must be less than or equal to MaxDegree', 1;

		IF @Description IS NULL
			BEGIN
				INSERT INTO Course (CourseName, MaxDegree, MinDegree)
				VALUES (@CourseName, @MaxDegree, @MinDegree)
			END
		ELSE
			BEGIN
				INSERT INTO Course (CourseName, Description, MaxDegree, MinDegree)
				VALUES (@CourseName, @Description, @MaxDegree, @MinDegree)
			END

		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION;

		THROW;
	END CATCH
END
GO

CREATE OR ALTER PROC SP_DeleteInstructor
	@InstructorID INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
	BEGIN TRY
        IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
            THROW 50060, 'You are not authorized to preform This action.', 1;
		IF NOT EXISTS(SELECT 1 FROM Instructor WHERE InstructorID = @InstructorID)
			THROW 50011, 'Couldn''t find Instructor with This ID', 1;

		DELETE FROM StudentQuestionExam WHERE ExamID IN (SELECT ExamID FROM Exam WHERE InstructorID = @InstructorID);
		DELETE FROM ExamQuestion WHERE ExamID IN (SELECT ExamID FROM Exam WHERE InstructorID = @InstructorID);
		DELETE FROM Exam WHERE InstructorID = @InstructorID;
		DELETE FROM InstructorCourse WHERE InstructorID = @InstructorID;
		DELETE FROM Instructor WHERE InstructorID = @InstructorID;
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
		THROW
	END CATCH
END
GO

CREATE OR ALTER PROC SP_DeleteStudent
	@StudentID INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
	BEGIN TRY
	    IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
            THROW 50060, 'You are not authorized to preform This action.', 1;
		IF NOT EXISTS(SELECT 1 FROM Student WHERE StudentID = @StudentID)
			THROW 50012, 'Couldn''t find Student with This ID', 1;

		DELETE FROM StudentCourse WHERE StudentID = @StudentID;
		DELETE FROM StudentQuestionExam WHERE StudentID = @StudentID;
		DELETE FROM Student WHERE StudentID = @StudentID;
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
		THROW
	END CATCH
END
GO

CREATE OR ALTER PROC SP_DeleteCourse
	@CourseID INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
	BEGIN TRY
	    IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
            THROW 50060, 'You are not authorized to preform This action.', 1;
		IF NOT EXISTS(SELECT 1 FROM Course WHERE CourseID = @CourseID)
			THROW 50014, 'Couldn''t find Course with This ID', 1;


		DELETE FROM ExamQuestion WHERE ExamID IN (SELECT ExamID FROM EXAM WHERE CourseID = @CourseID)
		DELETE FROM StudentQuestionExam WHERE ExamID IN (SELECT ExamID FROM EXAM WHERE CourseID = @CourseID)
		DELETE FROM QuestionChoice WHERE QuestionID IN (SELECT QuestionID FROM Question WHERE CourseID = @CourseID)
		DELETE FROM QuestionText WHERE QuestionID IN (SELECT QuestionID FROM Question WHERE CourseID = @CourseID)
		DELETE FROM QuestionTrueFalse WHERE QuestionID IN (SELECT QuestionID FROM Question WHERE CourseID = @CourseID)
		DELETE FROM Exam WHERE CourseID = @CourseID;
		DELETE FROM StudentCourse WHERE CourseID = @CourseID;
		DELETE FROM Question WHERE CourseID = @CourseID;
		DELETE FROM InstructorCourse WHERE CourseID = @CourseID;
		DELETE FROM Course WHERE CourseID = @CourseID;
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
		THROW
	END CATCH
END
GO

CREATE OR ALTER PROC SP_DeleteTrack
	@TrackID INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRANSACTION;
	BEGIN TRY
	    IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
            THROW 50060, 'You are not authorized to preform This action.', 1;
		IF NOT EXISTS(SELECT 1 FROM Track WHERE TrackID = @TrackID)
			THROW 50015, 'Couldn''t find Track with This ID', 1;

		DELETE FROM ExamQuestion WHERE ExamID IN(SELECT ExamID FROM Exam WHERE TrackID = @TrackID)
		DELETE FROM StudentCourse WHERE StudentID IN(SELECT StudentID FROM Student WHERE TrackID = @TrackID)
		DELETE FROM StudentQuestionExam WHERE StudentID IN(SELECT StudentID FROM Student WHERE TrackID = @TrackID)
		DELETE FROM EXAM WHERE TrackID = @TrackID;
		DELETE FROM Student WHERE TrackID = @TrackID;
		DELETE FROM Track WHERE TrackID = @TrackID;
		COMMIT TRANSACTION
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRANSACTION
		THROW
	END CATCH
END
GO

CREATE OR ALTER PROC SP_DeleteBranch
    @BranchID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
	    IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
			THROW 50060, 'You are not authorized to preform This action.', 1;
        IF NOT EXISTS (SELECT 1 FROM Branch WHERE BranchID = @BranchID)
            THROW 50013, 'Couldn''t find Branch with This ID', 1;

        DELETE EQ FROM ExamQuestion EQ
        JOIN Exam E ON E.ExamID = EQ.ExamID
        JOIN Track T ON T.TrackID = E.TrackID
        JOIN Intake I ON I.IntakeID = T.IntakeID
        WHERE I.BranchID = @BranchID;

        DELETE SC FROM StudentCourse SC
        JOIN Student S ON SC.StudentID = S.StudentID
        JOIN Track T ON T.TrackID = S.TrackID
        JOIN Intake I ON I.IntakeID = T.IntakeID
        WHERE I.BranchID = @BranchID;

        DELETE SQE FROM StudentQuestionExam SQE
		JOIN Student S ON S.StudentID = SQE.StudentID
		JOIN Track T ON T.TrackID = S.TrackID
		JOIN Intake I ON I.IntakeID = T.IntakeID
		WHERE I.BranchID = @BranchID
		
        DELETE S FROM Student S
        JOIN Track T ON T.TrackID = S.TrackID
        JOIN Intake I ON I.IntakeID = T.IntakeID
        WHERE I.BranchID = @BranchID;

		DELETE E FROM Exam E
        JOIN Track T ON T.TrackID = E.TrackID
        JOIN Intake I ON I.IntakeID = T.IntakeID
        WHERE I.BranchID = @BranchID;

        DELETE FROM InstructorCourse WHERE InstructorID IN (SELECT InstructorID FROM Instructor WHERE BranchID = @BranchID);
        DELETE FROM Track WHERE IntakeID IN (SELECT IntakeID FROM Intake WHERE BranchID = @BranchID);
        DELETE FROM Instructor WHERE BranchID = @BranchID;
        DELETE FROM Intake WHERE BranchID = @BranchID;
        DELETE FROM Branch WHERE BranchID = @BranchID;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 
            ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROC SP_DeleteIntake
    @IntakeID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
            THROW 50060, 'You are not authorized to preform This action.', 1;

        IF NOT EXISTS(SELECT 1 FROM Intake WHERE IntakeID = @IntakeID)
            THROW 50016, 'Couldn''t find Intake with This ID', 1;

        DELETE FROM ExamQuestion WHERE ExamID IN(SELECT ExamID FROM Exam WHERE TrackID IN(SELECT TrackID FROM Track WHERE IntakeID = @IntakeID))
        DELETE FROM StudentCourse WHERE StudentID IN(SELECT StudentID FROM Student WHERE TrackID IN(SELECT TrackID FROM Track WHERE IntakeID = @IntakeID))
        DELETE FROM StudentQuestionExam WHERE StudentID IN(SELECT StudentID FROM Student WHERE TrackID IN(SELECT TrackID FROM Track WHERE IntakeID = @IntakeID))
        DELETE FROM Exam WHERE TrackID IN(SELECT TrackID FROM Track WHERE IntakeID = @IntakeID)
        DELETE FROM Student WHERE TrackID IN(SELECT TrackID FROM Track WHERE IntakeID = @IntakeID)
        DELETE FROM Track WHERE IntakeID = @IntakeID;
        DELETE FROM Intake WHERE IntakeID = @IntakeID;
        COMMIT TRANSACTION
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0
            ROLLBACK TRANSACTION
        THROW
    END CATCH
END
GO

CREATE OR ALTER PROC SP_DeleteUser
	@UserID INT
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRAN;
	BEGIN TRY
	    IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
			THROW 50060, 'You are not authorized to preform This action.', 1;
		IF NOT EXISTS(SELECT 1 FROM [User] WHERE UserID = @UserID)
			THROW 60032, 'Couldn''t find User With this ID', 1

		DELETE EQ FROM ExamQuestion EQ 
		JOIN Exam E ON E.ExamID = EQ.ExamID
		JOIN Instructor I ON I.InstructorID = E.InstructorID
		WHERE UserID = @UserID
		DELETE SQE FROM StudentQuestionExam SQE 
		JOIN Exam E ON E.ExamID = SQE.ExamID
		JOIN Instructor I ON I.InstructorID = E.InstructorID
		WHERE UserID = @UserID
		DELETE E  FROM Exam E JOIN Instructor I ON E.InstructorID = I.InstructorID WHERE UserID = @UserID
		DELETE IC FROM InstructorCourse IC JOIN Instructor I ON IC.InstructorID = I.InstructorID WHERE UserID = @UserID
		DELETE SC FROM StudentCourse SC JOIN Student S ON SC.StudentID = S.StudentID WHERE UserID = @UserID
		DELETE FROM Student WHERE UserID = @UserID
		DELETE FROM Instructor WHERE UserID = @UserID
		DELETE FROM [User] WHERE UserID = @UserID
		COMMIT TRAN
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		THROW
	END CATCH
END
GO

CREATE OR ALTER PROC SP_EditBranch
	@BranchID   INT,
	@BranchName NVARCHAR(70)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRAN;
	BEGIN TRY
	    IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
			THROW 50060, 'You are not authorized to preform This action.', 1;
		IF EXISTS (SELECT 1 FROM Branch WHERE BranchID = @BranchID)
		BEGIN
			IF EXISTS (SELECT 1 FROM Branch WHERE BranchID = @BranchID AND BranchName = @BranchName)
				THROW 60003, 'You are putting the same Branch Name', 1;

			UPDATE Branch SET BranchName = @BranchName WHERE BranchID = @BranchID
		END
		ELSE
			THROW 60004, 'Branch not found', 1;

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0
			ROLLBACK TRAN
		THROW
	END CATCH
END
GO

CREATE OR ALTER PROC SP_EditIntake
    @IntakeID     INT,
    @IntakeName   NVARCHAR(100) = NULL,
    @BranchID     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;
    BEGIN TRY
	    IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
			THROW 50060, 'You are not authorized to preform This action.', 1;
        IF NOT EXISTS (SELECT 1 FROM Intake WHERE IntakeID = @IntakeID)
            THROW 60010, 'Intake not found', 1;
		
        IF @BranchID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Branch WHERE BranchID = @BranchID)
            THROW 60012, 'Invalid Branch ID', 1;

		-- Check for duplicate intake name in same branch
		IF EXISTS (
			SELECT 1 FROM Intake 
			WHERE IntakeName = @IntakeName 
			  AND BranchID = COALESCE(@BranchID, (SELECT BranchID FROM Intake WHERE IntakeID = @IntakeID))
			  AND IntakeID != @IntakeID
		)
			THROW 60013, 'Intake name already exists in this branch', 1;

		
		UPDATE Intake
		SET
			IntakeName = COALESCE(@IntakeName, IntakeName),
			BranchID = COALESCE(@BranchID, BranchID)
		WHERE IntakeID = @IntakeID;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROC SP_EditTrack
    @TrackID     INT,
    @TrackName   NVARCHAR(100) = NULL,
    @IntakeID    INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;
    BEGIN TRY
	    IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
			THROW 50060, 'You are not authorized to preform This action.', 1;
        IF NOT EXISTS (SELECT 1 FROM Track WHERE TrackID = @TrackID)
            THROW 60010, 'Track not found', 1;

        IF @TrackName IS NOT NULL AND EXISTS (
            SELECT 1
            FROM Track
            WHERE TrackName = @TrackName
              AND IntakeID = COALESCE(@IntakeID, (SELECT IntakeID FROM Track WHERE TrackID = @TrackID))
              AND TrackID != @TrackID
        )
            THROW 60013, 'Track name already exists in this Intake', 1;

        IF @IntakeID IS NOT NULL AND NOT EXISTS (SELECT 1 FROM Intake WHERE IntakeID = @IntakeID)
            THROW 60012, 'Invalid Intake ID', 1;

        UPDATE Track
        SET
            TrackName = COALESCE(@TrackName, TrackName),
            IntakeID = COALESCE(@IntakeID, IntakeID)
        WHERE TrackID = @TrackID;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROC SP_EditCourse
	@CourseID    INT,
	@CourseName  NVARCHAR(100) = NULL,
	@Description NVARCHAR(MAX) = NULL,
	@MaxDegree   INT = NULL,
	@MinDegree   INT = NULL
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRAN;
	BEGIN TRY
	    IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
			THROW 50060, 'You are not authorized to preform This action.', 1;
		IF NOT EXISTS(SELECT 1 FROM Course WHERE CourseID = @CourseID)
            THROW 60016, 'Course not found', 1;

		IF @MaxDegree IS NOT NULL AND @MaxDegree <= 0
            THROW 60017, 'The MaxDegree must be greater than zero', 1;

        IF @MinDegree IS NOT NULL AND @MinDegree < 0
            THROW 60018, 'The MinDegree cannot be negative', 1;

        IF @MinDegree IS NOT NULL AND @MaxDegree IS NOT NULL AND @MinDegree > @MaxDegree
            THROW 60019, 'The MinDegree cannot be greater than the MaxDegree', 1;

		UPDATE Course
		SET
			CourseName  = COALESCE(@CourseName, CourseName),
			Description = COALESCE(@Description, Description),
			MaxDegree   = COALESCE(@MaxDegree, MaxDegree),
			MinDegree   = COALESCE(@MinDegree, MinDegree)
		WHERE CourseID  = @CourseID

		COMMIT TRAN;
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		THROW
	END CATCH

END
GO

CREATE OR ALTER PROC SP_EditInstructor
    @InstructorID INT,
    @FirstName    NVARCHAR(50) = NULL,
    @LastName     NVARCHAR(50) = NULL,
    @Phone        NVARCHAR(20) = NULL,
    @Email        NVARCHAR(255) = NULL,
    @Gender       NVARCHAR(10) = NULL,
    @DateOfBirth  DATE = NULL,
    @BranchID     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;
    BEGIN TRY
		IF IS_MEMBER('InstructorRole') = 0 
			THROW 50060, 'You are not authorized to preform This action.', 1;
        -- Check if instructor exists
        IF NOT EXISTS(SELECT 1 FROM Instructor WHERE InstructorID = @InstructorID)
            THROW 60018, 'Instructor not found', 1;

        -- Check if email already exists for another instructor
        IF @Email IS NOT NULL AND EXISTS(
            SELECT 1 FROM Instructor 
            WHERE Email = @Email AND InstructorID != @InstructorID
        )
            THROW 60023, 'Email already exists for another instructor', 1;

        -- Validate Gender
        IF @Gender IS NOT NULL AND @Gender NOT IN ('Male', 'Female')
            THROW 60024, 'Gender must be Male or Female', 1;

        -- Validate DateOfBirth
        IF @DateOfBirth IS NOT NULL AND @DateOfBirth > GETDATE()
            THROW 60025, 'DateOfBirth cannot be in the future', 1;

        -- Validate BranchID
        IF @BranchID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM Branch WHERE BranchID = @BranchID)
            THROW 60027, 'Branch not found', 1;

        UPDATE Instructor
        SET
            FirstName   = COALESCE(@FirstName, FirstName),
            LastName    = COALESCE(@LastName, LastName),
            Phone       = COALESCE(@Phone, Phone),
            Email       = COALESCE(@Email, Email),
            Gender      = COALESCE(@Gender, Gender),
            DateOfBirth = COALESCE(@DateOfBirth, DateOfBirth),
            BranchID    = COALESCE(@BranchID, BranchID)
        WHERE InstructorID = @InstructorID;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROC SP_EditStudent
    @StudentID   INT,
    @FirstName   NVARCHAR(50) = NULL,
    @LastName    NVARCHAR(50) = NULL,
    @Phone       NVARCHAR(20) = NULL,
    @Email       NVARCHAR(255) = NULL,
    @Gender      NVARCHAR(10) = NULL,
    @DateOfBirth DATE = NULL,
    @TrackID     INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;
    BEGIN TRY

	    IF IS_MEMBER('StudentRole') = 0
			THROW 50060, 'You are not authorized to preform This action.', 1;
        -- Check if student exists
        IF NOT EXISTS(SELECT 1 FROM Student WHERE StudentID = @StudentID)
            THROW 60018, 'Student not found', 1;

        -- Validate Gender
        IF @Gender IS NOT NULL AND @Gender NOT IN ('Male', 'Female')
            THROW 60019, 'Gender must be Male or Female', 1;

        -- Validate DateOfBirth
        IF @DateOfBirth IS NOT NULL AND @DateOfBirth > GETDATE()
            THROW 60020, 'Date of Birth cannot be in the future', 1;

        -- Validate Email uniqueness
        IF @Email IS NOT NULL AND EXISTS(SELECT 1 FROM Student WHERE Email = @Email AND StudentID != @StudentID)
            THROW 60021, 'Email already exists for another student', 1;

        -- Validate TrackID
        IF @TrackID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM Track WHERE TrackID = @TrackID)
            THROW 60022, 'Track not found', 1;

        UPDATE Student
        SET
            FirstName   = COALESCE(@FirstName, FirstName),
            LastName    = COALESCE(@LastName, LastName),
            Phone       = COALESCE(@Phone, Phone),
            Email       = COALESCE(@Email, Email),
            Gender      = COALESCE(@Gender, Gender),
            DateOfBirth = COALESCE(@DateOfBirth, DateOfBirth),
            TrackID     = COALESCE(@TrackID, TrackID)
        WHERE StudentID = @StudentID;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROC SP_EditUser
    @UserID       INT,
    @UserName     NVARCHAR(100) = NULL,
    @PasswordHash NVARCHAR(MAX) = NULL,
    @RoleID       INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRAN;
    BEGIN TRY
	    DECLARE @CurrentUserID INT;
		SELECT @CurrentUserID = UserID FROM dbo.[User] WHERE UserName = USER_NAME();

		IF NOT EXISTS (SELECT 1 FROM [User] WHERE UserID = @CurrentUserID)
			THROW 50041, 'You are not authorized to perform this action.', 1;

        -- Check if user exists
        IF NOT EXISTS(SELECT 1 FROM [User] WHERE UserID = @UserID)
            THROW 60020, 'User not found', 1;

        -- Validate RoleID
        IF @RoleID IS NOT NULL AND NOT EXISTS(SELECT 1 FROM Role WHERE RoleID = @RoleID)
            THROW 60021, 'Invalid Role ID', 1;

        -- Check username uniqueness
        IF @UserName IS NOT NULL AND EXISTS(SELECT 1 FROM [User] WHERE UserName = @UserName AND UserID != @UserID)
            THROW 60022, 'Username already exists', 1;

        -- Update user
        UPDATE [User]
        SET
            UserName     = COALESCE(@UserName, UserName),
            PasswordHash = COALESCE(@PasswordHash, PasswordHash),
            RoleID       = COALESCE(@RoleID, RoleID)
        WHERE UserID = @UserID;

        COMMIT TRAN;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRAN;
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROC SP_Login
	@UserName NVARCHAR(100),
	@Password NVARCHAR(MAX)
AS
BEGIN
	SET NOCOUNT ON;
	BEGIN TRAN;
	BEGIN TRY

		IF EXISTS(SELECT 1 FROM [User] WHERE UserName = @UserName)
		BEGIN
			IF EXISTS(SELECT 1 FROM [User] WHERE UserName = @UserName AND PasswordHash = @Password)
			BEGIN
                DECLARE @RoleName NVARCHAR(30);
                DECLARE @FirstName NVARCHAR(100);
                DECLARE @UserID INT;

                SELECT 
                    @RoleName = R.RoleName,
                    @UserID = U.UserID
                FROM [User] U
                JOIN Role R ON U.RoleID = R.RoleID
                WHERE U.UserName = @UserName;

                IF @RoleName = 'Student'
                BEGIN
                    SELECT @FirstName = S.FirstName
                    FROM Student S
                    WHERE S.UserID = @UserID;
                END
                ELSE IF @RoleName = 'Instructor'
                BEGIN
                    SELECT @FirstName = I.FirstName
                    FROM Instructor I
                    WHERE I.UserID = @UserID;
                END
      
                PRINT @RoleName + ' - ' + @FirstName + ' WELCOME TO Exam System';

                COMMIT TRAN;
            END
			ELSE 
				THROW 52202, 'Wrong Password', 1
		END
		ELSE 
			THROW 52201, 'Sorry, Couldn'' Find Your Login Data', 1
	END TRY
	BEGIN CATCH
		IF @@TRANCOUNT > 0 ROLLBACK TRAN
		THROW
	END CATCH
END
GO

CREATE OR ALTER PROC SP_EnrollStudentInCourse
    @StudentID INT,
    @CourseID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
				THROW 50060, 'You are not authorized to preform This action.', 1;
        IF NOT EXISTS (SELECT 1 FROM Student WHERE StudentID = @StudentID)
            THROW 50001, 'Student does not exist.', 1;

        IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID)
            THROW 50002, 'Course does not exist.', 1;

        IF EXISTS (SELECT 1 FROM StudentCourse WHERE StudentID = @StudentID AND CourseID = @CourseID)
            THROW 50003, 'Student is already enrolled in this course.', 1;

        INSERT INTO StudentCourse (StudentID, CourseID) VALUES (@StudentID, @CourseID);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROC SP_AssignInstructorToCourse
    @InstructorID INT,
    @CourseID INT,
    @Class NVARCHAR(50),
    @Year INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		IF IS_MEMBER('TrainingManagerRole') = 0 AND IS_MEMBER('db_owner') = 0
				THROW 50060, 'You are not authorized to preform This action.', 1;

        IF NOT EXISTS (SELECT 1 FROM Instructor WHERE InstructorID = @InstructorID)
            THROW 50004, 'Instructor does not exist.', 1;

        IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID)
            THROW 50005, 'Course does not exist.', 1;

        IF EXISTS (SELECT 1 FROM InstructorCourse WHERE InstructorID = @InstructorID AND CourseID = @CourseID AND Class = @Class AND [Year] = @Year)
            THROW 50006, 'This instructor is already assigned to this course, class, and year.', 1;

        INSERT INTO InstructorCourse (InstructorID, CourseID, Class, [Year]) 
        VALUES (@InstructorID, @CourseID, @Class, @Year);
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROC SP_SubmitStudentAnswer
    @StudentID INT,
    @ExamID INT,
    @QuestionID INT,
    @StudentAnswer NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		DECLARE @CurrentUserID INT;
		SELECT @CurrentUserID = UserID FROM [User] WHERE UserName = USER_NAME();

		IF NOT EXISTS (SELECT 1 FROM Student WHERE StudentID = @StudentID AND UserID = @CurrentUserID)
            THROW 50035, 'You are not authorized to perform this action for this student.', 1;

        -- Did this student answer this question on this exam before?
        IF EXISTS (SELECT 1 FROM StudentQuestionExam 
                   WHERE StudentID = @StudentID 
                     AND ExamID = @ExamID 
                     AND QuestionID = @QuestionID)
        BEGIN
            -- If Yes, UPDATE his old answer
            UPDATE StudentQuestionExam
            SET StudentAnswer = @StudentAnswer
            WHERE 
                StudentID = @StudentID 
                AND ExamID = @ExamID 
                AND QuestionID = @QuestionID;
        END
		
        ELSE
        BEGIN
            -- If No, INSERT to a new row with his answer
            INSERT INTO StudentQuestionExam (StudentID, ExamID, QuestionID, StudentAnswer, Score)
            VALUES (@StudentID, @ExamID, @QuestionID, @StudentAnswer, NULL); -- The score is NULL until it is corrected
        END
    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROC SP_StudentEnterExam
    @StudentID INT,
    @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY

	    DECLARE @CurrentUserID INT;
        SELECT @CurrentUserID = UserID FROM [User] WHERE UserName = USER_NAME();

        IF NOT EXISTS (SELECT 1 FROM Student WHERE StudentID = @StudentID AND UserID = @CurrentUserID)
            THROW 50034, 'You are not authorized to perform this action for this student.', 1;

        -- 1. Get exam details and student's track in one go
        DECLARE @ExamTrackID INT;
		DECLARE @ExamStartTime DATETIME;
		DECLARE @ExamEndTime DATETIME;
        DECLARE @StudentTrackID INT;

        SELECT @StudentTrackID = TrackID FROM Student WHERE StudentID = @StudentID;
        
        SELECT 
            @ExamTrackID = TrackID, 
            @ExamStartTime = StartTime, 
            @ExamEndTime = EndTime 
        FROM Exam 
        WHERE ExamID = @ExamID;

        -- Check if student or exam exist
        IF @StudentTrackID IS NULL
            THROW 50030, 'Student not found.', 1;
        IF @ExamTrackID IS NULL
            THROW 50031, 'Exam not found.', 1;

        -- Check if the student is in the correct track for this exam
        IF @StudentTrackID!= @ExamTrackID
            THROW 50032, 'You are not enrolled in the track for this exam.', 1;

        -- Check if the exam is currently active
        IF GETDATE() NOT BETWEEN @ExamStartTime AND @ExamEndTime
            THROW 50033, 'This exam is not active at the current time.', 1;

        -- Let them in!
        SELECT 
            q.QuestionID,
            q.QuestionText,
            q.QuestionType,
            eq.Degree
        FROM 
            ExamQuestion eq
            JOIN Question q ON eq.QuestionID = q.QuestionID
        WHERE 
            eq.ExamID = @ExamID;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE OR ALTER PROC SP_GetStudentExamGrade
    @StudentID INT,
    @ExamID INT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		DECLARE @CurrentUserID INT;
		SELECT @CurrentUserID = UserID FROM [User] WHERE UserName = USER_NAME();

		IF NOT EXISTS (SELECT 1 FROM Student WHERE StudentID = @StudentID AND UserID = @CurrentUserID)
			THROW 50041, 'You are not authorized to perform this action for this student.', 1;

        -- Check if the student actually took this exam
        IF NOT EXISTS (SELECT 1 FROM StudentQuestionExam WHERE StudentID = @StudentID AND ExamID = @ExamID)
            THROW 50040, 'No results found for this student in the specified exam.', 1;

        SELECT 
            StudentName,
            CourseName,
            StudentScore,
            TotalExamDegree
        FROM 
            VW_StudentExamResults
        WHERE 
            StudentID = @StudentID AND ExamID = @ExamID;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END;
GO

CREATE TYPE ExamQuestionListType AS TABLE (
    QuestionID INT NOT NULL,
    Degree INT NOT NULL
);
GO

CREATE OR ALTER PROC SP_InstructorCreateExam
    @InstructorID INT,
    @CourseID INT,
    @TrackID INT,
    @ExamType NVARCHAR(20),
    @StartTime DATETIME,
    @EndTime DATETIME,
    @TotalTime INT,
    @Questions ExamQuestionListType READONLY -- This is our list of questions and degrees
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
		DECLARE @CurrentUserID INT;
		SELECT @CurrentUserID = UserID FROM [User] WHERE UserName = USER_NAME();

		IF NOT EXISTS (SELECT 1 FROM Instructor WHERE InstructorID = @InstructorID AND UserID = @CurrentUserID)
			THROW 50050, 'You are not authorized to create exams for this instructor account.', 1;
		
        -- 1. Check if the instructor actually teaches this course
        IF NOT EXISTS (SELECT 1 FROM InstructorCourse WHERE InstructorID = @InstructorID AND CourseID = @CourseID)
            THROW 50020, 'You are not assigned to teach this course.', 1;

        -- 2. Check if start time is before end time
        IF @StartTime >= @EndTime
            THROW 50022, 'Start time must be before end time.', 1;
			
		IF @StartTime > GETDATE()
            THROW 50022, 'Cannot Create Exam Before Today.', 1;

        -- 3. Check if all provided questions actually belong to this course
        IF EXISTS (
            SELECT 1 FROM @Questions q_input
            LEFT JOIN Question q_db ON q_input.QuestionID = q_db.QuestionID
            WHERE q_db.CourseID!= @CourseID OR q_db.QuestionID IS NULL
        )
            THROW 50023, 'One or more selected questions do not belong to this course.', 1;

        DECLARE @NewExamID INT;

        -- 1. Create the main Exam record
        INSERT INTO Exam (ExamType, StartTime, EndTime, TotalTime, CourseID, InstructorID, TrackID)
        VALUES (@ExamType, @StartTime, @EndTime, @TotalTime, @CourseID, @InstructorID, @TrackID);
        
        SET @NewExamID = SCOPE_IDENTITY(); -- Get the ID of the exam we just created

        -- 2. Add the questions and their degrees to the exam
        INSERT INTO ExamQuestion (ExamID, QuestionID, Degree)
        SELECT @NewExamID, QuestionID, Degree FROM @Questions;

        COMMIT TRANSACTION;

        -- Return the ID of the new exam so the application knows it was successful
        SELECT @NewExamID AS NewExamID;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION; -- If anything goes wrong, undo everything
        THROW;
    END CATCH
END;

--  Test

--BEGIN TRAN
--DECLARE @ExamQuestions AS ExamQuestionListType;
--INSERT INTO @ExamQuestions (QuestionID, Degree)
--VALUES 
--    (1, 5),
--    (2, 10),
--    (3, 7);

--	EXEC usp_InstructorCreateExam
--    @InstructorID = 1,
--    @CourseID     = 1,
--    @TrackID      = 3,
--    @ExamType     = 'Exam',
--    @StartTime    = '2025-07-30 10:00:00',
--    @EndTime      = '2025-07-30 12:00:00',
--    @TotalTime    = 120,
--    @Questions    = @ExamQuestions;


-- SELECT * FROM ExamQuestion WHERE ExamID = 9;
-- ROLLBACK
GO

CREATE OR ALTER PROC SP_AddMCQQuestion
    @QuestionText NVARCHAR(MAX),
    @CourseID INT,
    @CorrectAnswer NCHAR(1),
    @ChoiceA NVARCHAR(255),
    @ChoiceB NVARCHAR(255),
    @ChoiceC NVARCHAR(255),
    @ChoiceD NVARCHAR(255)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
		DECLARE @CurrentUserID INT, @CurrentInstructorID INT;
		SELECT @CurrentUserID = UserID FROM [User] WHERE UserName = USER_NAME();
		SELECT @CurrentInstructorID = InstructorID FROM Instructor WHERE UserID = @CurrentUserID;

		IF NOT EXISTS (SELECT 1 FROM InstructorCourse WHERE InstructorID = @CurrentInstructorID AND CourseID = @CourseID)
			THROW 50051, 'You are not authorized to add questions to this course.', 1;

        IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID)
            THROW 70001, 'Course not found', 1;

        -- Validate correct answer is A, B, C, or D
        IF @CorrectAnswer NOT IN ('A', 'B', 'C', 'D')
            THROW 70002, 'Correct answer must be A, B, C, or D', 1;

        DECLARE @NewQuestionID INT;

        -- Insert main question
        INSERT INTO Question (QuestionText, QuestionType, CourseID)
        VALUES (@QuestionText, 'MCQ', @CourseID);

        SET @NewQuestionID = SCOPE_IDENTITY();

        -- Insert choices
        INSERT INTO QuestionChoice (QuestionID, ChoiceText, IsCorrect)
        VALUES 
            (@NewQuestionID, @ChoiceA, CASE WHEN @CorrectAnswer = 'A' THEN 1 ELSE 0 END), 
			(@NewQuestionID, @ChoiceB, CASE WHEN @CorrectAnswer = 'B' THEN 1 ELSE 0 END),
            (@NewQuestionID, @ChoiceC, CASE WHEN @CorrectAnswer = 'C' THEN 1 ELSE 0 END);

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- Add True/False Question
CREATE OR ALTER PROC SP_AddTrueFalseQuestion
    @QuestionText NVARCHAR(MAX),
    @CourseID INT,
    @CorrectAnswer BIT
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
		DECLARE @CurrentUserID INT, @CurrentInstructorID INT;
		SELECT @CurrentUserID = UserID FROM [User] WHERE UserName = USER_NAME();
		SELECT @CurrentInstructorID = InstructorID FROM Instructor WHERE UserID = @CurrentUserID;

		IF NOT EXISTS (SELECT 1 FROM InstructorCourse WHERE InstructorID = @CurrentInstructorID AND CourseID = @CourseID)
			THROW 50051, 'You are not authorized to add questions to this course.', 1;

        -- Validate course exists
        IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID)
            THROW 70003, 'Course not found', 1;

        DECLARE @NewQuestionID INT;

        -- Insert main question
        INSERT INTO Question (QuestionText, QuestionType, CourseID)
        VALUES (@QuestionText, 'TF', @CourseID);

        SET @NewQuestionID = SCOPE_IDENTITY();

        -- Insert true/false answer
        INSERT INTO QuestionTrueFalse (QuestionID, CorrectAnswer)
        VALUES (@NewQuestionID, @CorrectAnswer);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- Add Text Question
CREATE OR ALTER PROC SP_AddTextQuestion
    @QuestionText NVARCHAR(MAX),
    @CourseID INT,
    @BestAnswer NVARCHAR(MAX)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
		DECLARE @CurrentUserID INT, @CurrentInstructorID INT;
		SELECT @CurrentUserID = UserID FROM [User] WHERE UserName = USER_NAME();
		SELECT @CurrentInstructorID = InstructorID FROM Instructor WHERE UserID = @CurrentUserID;

		IF NOT EXISTS (SELECT 1 FROM InstructorCourse WHERE InstructorID = @CurrentInstructorID AND CourseID = @CourseID)
			THROW 50051, 'You are not authorized to add questions to this course.', 1;

        -- Validate course exists
        IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID)
            THROW 70004, 'Course not found', 1;

        DECLARE @NewQuestionID INT;

        -- Insert main question
        INSERT INTO Question (QuestionText, QuestionType, CourseID)
        VALUES (@QuestionText, 'Text', @CourseID);

        SET @NewQuestionID = SCOPE_IDENTITY();

        -- Insert text answer details
        INSERT INTO QuestionText (QuestionID, BestAcceptedAnswer)
        VALUES (@NewQuestionID, @BestAnswer);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- Get Ungraded Text Answers for Manual Review
CREATE OR ALTER PROC SP_GetUnGradedTextAnswers
    @ExamID INT = NULL,
    @InstructorID INT = NULL
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
		DECLARE @CurrentUserID INT, @CurrentInstructorID INT;
		SELECT @CurrentUserID = UserID FROM dbo.[User] WHERE UserName = USER_NAME();
		SELECT @CurrentInstructorID = InstructorID FROM dbo.Instructor WHERE UserID = @CurrentUserID;

		IF @InstructorID IS NOT NULL AND @InstructorID!= @CurrentInstructorID
			THROW 50052, 'You can only view answers for your own exams.', 1;

        SELECT 
            sqe.StudentID,
            s.FirstName + ' ' + s.LastName AS StudentName,
            sqe.ExamID,
            e.ExamType,
            c.CourseName,
            sqe.QuestionID,
            q.QuestionText,
            sqe.StudentAnswer,
            qt.BestAcceptedAnswer AS ModelAnswer,
            eq.Degree AS MaxDegree,
            sqe.Score AS CurrentScore
        FROM StudentQuestionExam sqe
        INNER JOIN Student s ON sqe.StudentID = s.StudentID
        INNER JOIN Exam e ON sqe.ExamID = e.ExamID
        INNER JOIN Course c ON e.CourseID = c.CourseID
        INNER JOIN Question q ON sqe.QuestionID = q.QuestionID
        INNER JOIN QuestionText qt ON q.QuestionID = qt.QuestionID
        INNER JOIN ExamQuestion eq ON sqe.ExamID = eq.ExamID AND sqe.QuestionID = eq.QuestionID
        WHERE q.QuestionType = 'Text'
          AND sqe.Score IS NULL -- Not graded yet
          AND sqe.StudentAnswer IS NOT NULL -- Student provided an answer
          AND (@ExamID IS NULL OR sqe.ExamID = @ExamID)
		  AND e.InstructorID = @CurrentInstructorID
        ORDER BY sqe.ExamID, sqe.StudentID, sqe.QuestionID;

    END TRY
    BEGIN CATCH
        THROW;
    END CATCH
END
GO

CREATE OR ALTER PROC SP_GradeTextAnswer
    @StudentID INT,
    @ExamID INT,
    @QuestionID INT,
    @Score DECIMAL(5,2)
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
		DECLARE @CurrentUserID INT, @CurrentInstructorID INT;
		SELECT @CurrentUserID = UserID FROM dbo.[User] WHERE UserName = USER_NAME();
		SELECT @CurrentInstructorID = InstructorID FROM dbo.Instructor WHERE UserID = @CurrentUserID;

		IF NOT EXISTS (SELECT 1 FROM dbo.Exam WHERE ExamID = @ExamID AND InstructorID = @CurrentInstructorID)
			THROW 50053, 'You are not authorized to grade answers for this exam.', 1;


        DECLARE @MaxDegree DECIMAL(5,2);
        
        -- Get max degree for this question in this exam
        SELECT @MaxDegree = Degree 
        FROM ExamQuestion 
        WHERE ExamID = @ExamID AND QuestionID = @QuestionID;

        -- Validate score doesn't exceed max degree
        IF @Score > @MaxDegree
            THROW 70008, 'Score cannot exceed maximum degree for this question', 1;

        IF @Score < 0
            THROW 70009, 'Score cannot be negative', 1;

        -- Update the score
        UPDATE StudentQuestionExam
        SET 
            Score = @Score
        WHERE StudentID = @StudentID 
          AND ExamID = @ExamID 
          AND QuestionID = @QuestionID;

        IF @@ROWCOUNT = 0
            THROW 70010, 'Student answer not found for grading', 1;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO

-- Get Random Questions from Question Pool
CREATE OR ALTER PROC SP_GetRandomQuestions
    @CourseID INT,
    @MCQCount INT = 0,
    @TFCount INT = 0,
    @TextCount INT = 0
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Course WHERE CourseID = @CourseID)
            THROW 80001, 'Course not found', 1;

        DECLARE @AvailableMCQ INT, @AvailableTF INT, @AvailableText INT;
        
        SELECT @AvailableMCQ = COUNT(*) FROM Question WHERE CourseID = @CourseID AND QuestionType = 'MCQ';
        SELECT @AvailableTF = COUNT(*) FROM Question WHERE CourseID = @CourseID AND QuestionType = 'TF';
        SELECT @AvailableText = COUNT(*) FROM Question WHERE CourseID = @CourseID AND QuestionType = 'Text';

        IF @MCQCount > @AvailableMCQ
            THROW 80002, 'Not enough MCQ questions available in the question pool', 1;
        IF @TFCount > @AvailableTF
            THROW 80003, 'Not enough True/False questions available in the question pool', 1;
        IF @TextCount > @AvailableText
            THROW 80004, 'Not enough Text questions available in the question pool', 1;

        -- Create temp table to store selected questions
        CREATE TABLE #SelectedQuestions (
            QuestionID INT,
            QuestionText NVARCHAR(MAX),
            QuestionType NVARCHAR(20),
            CourseID INT
        );

        -- Get random MCQ questions
        IF @MCQCount > 0
        BEGIN
            INSERT INTO #SelectedQuestions (QuestionID, QuestionText, QuestionType, CourseID)
            SELECT TOP (@MCQCount) QuestionID, QuestionText, QuestionType, CourseID
            FROM Question 
            WHERE CourseID = @CourseID AND QuestionType = 'MCQ'
            ORDER BY NEWID();
        END

        -- Get random True/False questions
        IF @TFCount > 0
        BEGIN
            INSERT INTO #SelectedQuestions (QuestionID, QuestionText, QuestionType, CourseID)
            SELECT TOP (@TFCount) QuestionID, QuestionText, QuestionType, CourseID
            FROM Question 
            WHERE CourseID = @CourseID AND QuestionType = 'TF'
            ORDER BY NEWID();
        END

        -- Get random Text questions
        IF @TextCount > 0
        BEGIN
            INSERT INTO #SelectedQuestions (QuestionID, QuestionText, QuestionType, CourseID)
            SELECT TOP (@TextCount) QuestionID, QuestionText, QuestionType, CourseID
            FROM Question 
            WHERE CourseID = @CourseID AND QuestionType = 'Text'
            ORDER BY NEWID();
        END

        -- Return selected questions
        SELECT 
            sq.QuestionID,
            sq.QuestionText,
            sq.QuestionType,
            sq.CourseID,
            -- Include choices for MCQ
            CASE 
                WHEN sq.QuestionType = 'MCQ' THEN 
                    (SELECT STRING_AGG(CONCAT(
                        CASE ROW_NUMBER() OVER (ORDER BY qc.ChoiceID)
                            WHEN 1 THEN 'A) '
                            WHEN 2 THEN 'B) '
                            WHEN 3 THEN 'C) '
                            WHEN 4 THEN 'D) '
                        END, qc.ChoiceText), ' | ')
                     FROM QuestionChoice qc 
                     WHERE qc.QuestionID = sq.QuestionID)
                ELSE NULL
            END AS Choices,
            -- Include correct answer info (for instructor reference only)
            CASE 
                WHEN sq.QuestionType = 'MCQ' THEN 
                    (SELECT 
                        CASE ROW_NUMBER() OVER (ORDER BY qc.ChoiceID)
                            WHEN 1 THEN 'A'
                            WHEN 2 THEN 'B'
                            WHEN 3 THEN 'C'
                            WHEN 4 THEN 'D'
                        END
                     FROM QuestionChoice qc 
                     WHERE qc.QuestionID = sq.QuestionID AND qc.IsCorrect = 1)
                WHEN sq.QuestionType = 'TF' THEN 
                    (SELECT CASE WHEN qtf.CorrectAnswer = 1 THEN 'True' ELSE 'False' END
                     FROM QuestionTrueFalse qtf 
                     WHERE qtf.QuestionID = sq.QuestionID)
                ELSE 'Manual Grading Required'
            END AS CorrectAnswer
        FROM #SelectedQuestions sq
        ORDER BY sq.QuestionType, sq.QuestionID;

        DROP TABLE #SelectedQuestions;

    END TRY
    BEGIN CATCH
        IF OBJECT_ID('tempdb..#SelectedQuestions') IS NOT NULL
            DROP TABLE #SelectedQuestions;
        THROW;
    END CATCH
END
GO

-- Auto Grade Exam (MCQ and True/False only)
CREATE OR ALTER PROC SP_AutoGradeExam
    @ExamID INT,
    @StudentID INT = NULL -- If NULL, grade for all students who took the exam
AS
BEGIN
    SET NOCOUNT ON;
    BEGIN TRANSACTION;
    BEGIN TRY
        IF NOT EXISTS (SELECT 1 FROM Exam WHERE ExamID = @ExamID)
            THROW 80007, 'Exam not found', 1;

        DECLARE @GradedCount INT = 0;

        -- Grade MCQ Questions
        UPDATE sqe
        SET Score = CASE 
            WHEN sqe.StudentAnswer = (
                SELECT 
                    CASE ROW_NUMBER() OVER (ORDER BY qc.ChoiceID)
                        WHEN 1 THEN 'A'
                        WHEN 2 THEN 'B'
                        WHEN 3 THEN 'C'
                        WHEN 4 THEN 'D'
                    END
                FROM QuestionChoice qc 
                WHERE qc.QuestionID = sqe.QuestionID AND qc.IsCorrect = 1
            ) THEN eq.Degree
            ELSE 0
        END
        FROM StudentQuestionExam sqe
        INNER JOIN Question q ON sqe.QuestionID = q.QuestionID
        INNER JOIN ExamQuestion eq ON sqe.ExamID = eq.ExamID AND sqe.QuestionID = eq.QuestionID
        WHERE sqe.ExamID = @ExamID
          AND q.QuestionType = 'MCQ'
          AND sqe.StudentAnswer IS NOT NULL
          AND sqe.Score IS NULL -- Only grade ungraded answers
          AND (@StudentID IS NULL OR sqe.StudentID = @StudentID);

        SET @GradedCount = @GradedCount + @@ROWCOUNT;

        -- Grade True/False Questions
        UPDATE sqe
        SET Score = CASE 
            WHEN (
                (sqe.StudentAnswer = 'True' AND qtf.CorrectAnswer = 1) OR
                (sqe.StudentAnswer = 'False' AND qtf.CorrectAnswer = 0)
            ) THEN eq.Degree
            ELSE 0
        END
        FROM StudentQuestionExam sqe
        INNER JOIN Question q ON sqe.QuestionID = q.QuestionID
        INNER JOIN QuestionTrueFalse qtf ON q.QuestionID = qtf.QuestionID
        INNER JOIN ExamQuestion eq ON sqe.ExamID = eq.ExamID AND sqe.QuestionID = eq.QuestionID
        WHERE sqe.ExamID = @ExamID
          AND q.QuestionType = 'TF'
          AND sqe.StudentAnswer IS NOT NULL
          AND sqe.Score IS NULL -- Only grade ungraded answers
          AND (@StudentID IS NULL OR sqe.StudentID = @StudentID);

        SET @GradedCount = @GradedCount + @@ROWCOUNT;

        COMMIT TRANSACTION;

        -- Return grading summary
        SELECT 
            @ExamID AS ExamID,
            @GradedCount AS TotalGradedAnswers,
            (SELECT COUNT(*) 
             FROM StudentQuestionExam sqe
             INNER JOIN Question q ON sqe.QuestionID = q.QuestionID
             WHERE sqe.ExamID = @ExamID 
               AND q.QuestionType = 'Text'
               AND sqe.Score IS NULL
               AND sqe.StudentAnswer IS NOT NULL
               AND (@StudentID IS NULL OR sqe.StudentID = @StudentID)
            ) AS PendingTextAnswers,
            CASE 
                WHEN @StudentID IS NULL THEN 'All students graded'
                ELSE 'Student ID ' + CAST(@StudentID AS NVARCHAR(10)) + ' graded'
            END AS GradingScope;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        THROW;
    END CATCH
END
GO


-- =================================================================
-- Create Database Roles
-- =================================================================

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'StudentRole' AND type = 'R')
    CREATE ROLE StudentRole;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'InstructorRole' AND type = 'R')
    CREATE ROLE InstructorRole;
GO

IF NOT EXISTS (SELECT 1 FROM sys.database_principals WHERE name = 'TrainingManagerRole' AND type = 'R')
    CREATE ROLE TrainingManagerRole;
GO

IF NOT EXISTS(SELECT 1 FROM sys.database_principals WHERE name = 'Admin' AND type = 'R')
	CREATE ROLE Admin
GO


-- =================================================================
-- Grant Permissions to Roles
-- =================================================================

-- --- Student Permissions
GRANT EXECUTE ON SP_StudentEnterExam    TO StudentRole;
GRANT EXECUTE ON SP_SubmitStudentAnswer TO StudentRole;
GRANT EXECUTE ON SP_GetStudentExamGrade TO StudentRole;
GRANT SELECT  ON VW_AvailableExams      TO StudentRole;
GRANT SELECT  ON VW_StudentData         TO StudentRole;
GRANT SELECT  ON VW_StudentExamResults  TO StudentRole;
GO

-- --- Instructor Permissions
GRANT EXECUTE ON SP_InstructorCreateExam   TO InstructorRole;
GRANT EXECUTE ON SP_AddMCQQuestion         TO InstructorRole;
GRANT EXECUTE ON SP_AddTrueFalseQuestion   TO InstructorRole;
GRANT EXECUTE ON SP_AddTextQuestion        TO InstructorRole;
GRANT EXECUTE ON SP_GetRandomQuestions     TO InstructorRole;
GRANT EXECUTE ON SP_GetUnGradedTextAnswers TO InstructorRole;
GRANT EXECUTE ON SP_GradeTextAnswer        TO InstructorRole;
GRANT SELECT  ON VW_InstructorData         TO InstructorRole;
GRANT SELECT  ON VW_CourseQuestionPool     TO InstructorRole;
GRANT SELECT  ON VW_StudentExamResults     TO InstructorRole;
GRANT SELECT  ON VW_QuestionWithAnswers    TO InstructorRole;
GRANT SELECT  ON VW_QuestionsReport        TO InstructorRole;
GO

-- --- Training Manager Permissions
GRANT EXECUTE ON SP_AddNewStudent    TO TrainingManagerRole;
GRANT EXECUTE ON SP_AddNewInstructor TO TrainingManagerRole;
GRANT EXECUTE ON SP_AddNewBranch     TO TrainingManagerRole;
GRANT EXECUTE ON SP_AddNewIntake     TO TrainingManagerRole;
GRANT EXECUTE ON SP_AddNewTrack      TO TrainingManagerRole;
GRANT EXECUTE ON SP_AddNewCourse     TO TrainingManagerRole;
GRANT EXECUTE ON SP_DeleteInstructor TO TrainingManagerRole;
GRANT EXECUTE ON SP_DeleteStudent    TO TrainingManagerRole;
GRANT EXECUTE ON SP_DeleteCourse     TO TrainingManagerRole;
GRANT EXECUTE ON SP_DeleteTrack      TO TrainingManagerRole;
GRANT EXECUTE ON SP_DeleteIntake     TO TrainingManagerRole;
GRANT EXECUTE ON SP_DeleteBranch     TO TrainingManagerRole;
GRANT EXECUTE ON SP_EditBranch       TO TrainingManagerRole;
GRANT EXECUTE ON SP_EditIntake       TO TrainingManagerRole;
GRANT EXECUTE ON SP_EditTrack        TO TrainingManagerRole;
GRANT EXECUTE ON SP_EditCourse       TO TrainingManagerRole;
GRANT EXECUTE ON SP_EditInstructor   TO TrainingManagerRole;
GRANT EXECUTE ON SP_EditStudent      TO TrainingManagerRole;
GRANT SELECT  ON VW_BranchReport       TO TrainingManagerRole;
GRANT SELECT  ON VW_StudentData        TO TrainingManagerRole;
GRANT SELECT  ON VW_InstructorData     TO TrainingManagerRole;
GRANT SELECT  ON VW_CourseDetails      TO TrainingManagerRole;
GRANT SELECT  ON VW_StudentExamResults TO TrainingManagerRole;
GO


-- =================================================================
-- DENY Direct Table Access 
-- =================================================================
DENY SELECT, INSERT, UPDATE, DELETE TO StudentRole;
DENY SELECT, INSERT, UPDATE, DELETE TO InstructorRole;
DENY SELECT, INSERT, UPDATE, DELETE TO TrainingManagerRole;
GO
