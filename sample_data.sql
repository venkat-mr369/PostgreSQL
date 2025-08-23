
```sql
-- 1. Table Definitions

CREATE TABLE emp (
    id INT PRIMARY KEY,
    name VARCHAR(50),
    designation VARCHAR(50)
);

CREATE TABLE dept (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE hobbies (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);

CREATE TABLE salary (
    id INT PRIMARY KEY,
    salary NUMERIC(10,2),
    dob DATE
);

CREATE TABLE entertainment (
    id INT PRIMARY KEY,
    name VARCHAR(50)
);

-- 2. Insert Data: 50 Rows Each

-- emp table
INSERT INTO emp (id, name, designation) VALUES (1, 'Amit Sharma', 'Manager');
INSERT INTO emp (id, name, designation) VALUES (2, 'Priya Singh', 'Developer');
INSERT INTO emp (id, name, designation) VALUES (3, 'Rahul Verma', 'Analyst');
INSERT INTO emp (id, name, designation) VALUES (4, 'Sneha Nair', 'Executive');
INSERT INTO emp (id, name, designation) VALUES (5, 'Rohit Gupta', 'Clerk');
INSERT INTO emp (id, name, designation) VALUES (6, 'Pooja Mehta', 'Manager');
INSERT INTO emp (id, name, designation) VALUES (7, 'Arjun Das', 'Developer');
INSERT INTO emp (id, name, designation) VALUES (8, 'Neha Kapoor', 'Analyst');
INSERT INTO emp (id, name, designation) VALUES (9, 'Vikram Pillai', 'Executive');
INSERT INTO emp (id, name, designation) VALUES (10, 'Kiran Rao', 'Clerk');
INSERT INTO emp (id, name, designation) VALUES (11, 'Deepak Yadav', 'Manager');
INSERT INTO emp (id, name, designation) VALUES (12, 'Anjali Reddy', 'Developer');
INSERT INTO emp (id, name, designation) VALUES (13, 'Sunil Menon', 'Analyst');
INSERT INTO emp (id, name, designation) VALUES (14, 'Komal Joshi', 'Executive');
INSERT INTO emp (id, name, designation) VALUES (15, 'Suresh Patil', 'Clerk');
INSERT INTO emp (id, name, designation) VALUES (16, 'Divya Sethi', 'Manager');
INSERT INTO emp (id, name, designation) VALUES (17, 'Rakesh Shetty', 'Developer');
INSERT INTO emp (id, name, designation) VALUES (18, 'Meera Jain', 'Analyst');
INSERT INTO emp (id, name, designation) VALUES (19, 'Santosh Singh', 'Executive');
INSERT INTO emp (id, name, designation) VALUES (20, 'Chirag Agarwal', 'Clerk');
INSERT INTO emp (id, name, designation) VALUES (21, 'Kavita Iyer', 'Manager');
INSERT INTO emp (id, name, designation) VALUES (22, 'Gaurav Bansal', 'Developer');
INSERT INTO emp (id, name, designation) VALUES (23, 'Rajesh Kulkarni', 'Analyst');
INSERT INTO emp (id, name, designation) VALUES (24, 'Tanya Mishra', 'Executive');
INSERT INTO emp (id, name, designation) VALUES (25, 'Ajay Choudhary', 'Clerk');
INSERT INTO emp (id, name, designation) VALUES (26, 'Sonia Kaur', 'Manager');
INSERT INTO emp (id, name, designation) VALUES (27, 'Tarun Bakshi', 'Developer');
INSERT INTO emp (id, name, designation) VALUES (28, 'Pallavi Pandey', 'Analyst');
INSERT INTO emp (id, name, designation) VALUES (29, 'Vinay Malhotra', 'Executive');
INSERT INTO emp (id, name, designation) VALUES (30, 'Preeti Desai', 'Clerk');
INSERT INTO emp (id, name, designation) VALUES (31, 'Siddharth Nanda', 'Manager');
INSERT INTO emp (id, name, designation) VALUES (32, 'Shalini Ghosh', 'Developer');
INSERT INTO emp (id, name, designation) VALUES (33, 'Aakash Khandelwal', 'Analyst');
INSERT INTO emp (id, name, designation) VALUES (34, 'Bhavna Seth', 'Executive');
INSERT INTO emp (id, name, designation) VALUES (35, 'Mohan Rao', 'Clerk');
INSERT INTO emp (id, name, designation) VALUES (36, 'Lakshmi Prasad', 'Manager');
INSERT INTO emp (id, name, designation) VALUES (37, 'Harish Dubey', 'Developer');
INSERT INTO emp (id, name, designation) VALUES (38, 'Pallavi Yadav', 'Analyst');
INSERT INTO emp (id, name, designation) VALUES (39, 'Ankit Jain', 'Executive');
INSERT INTO emp (id, name, designation) VALUES (40, 'Ayesha Shaikh', 'Clerk');
INSERT INTO emp (id, name, designation) VALUES (41, 'Jitendra Solanki', 'Manager');
INSERT INTO emp (id, name, designation) VALUES (42, 'Diksha Mahajan', 'Developer');
INSERT INTO emp (id, name, designation) VALUES (43, 'Vipin Sharma', 'Analyst');
INSERT INTO emp (id, name, designation) VALUES (44, 'Nisha Narayanan', 'Executive');
INSERT INTO emp (id, name, designation) VALUES (45, 'Farhan Ahmed', 'Clerk');
INSERT INTO emp (id, name, designation) VALUES (46, 'Manali Thakur', 'Manager');
INSERT INTO emp (id, name, designation) VALUES (47, 'Suraj Bhatt', 'Developer');
INSERT INTO emp (id, name, designation) VALUES (48, 'Usha Moorthy', 'Analyst');
INSERT INTO emp (id, name, designation) VALUES (49, 'Jayant Kapoor', 'Executive');
INSERT INTO emp (id, name, designation) VALUES (50, 'Priya Sehgal', 'Clerk');

-- dept table (with requested customizations)
INSERT INTO dept (id, name) VALUES (1, 'Finance');
INSERT INTO dept (id, name) VALUES (2, 'Finance');
INSERT INTO dept (id, name) VALUES (3, 'Information Tech');
INSERT INTO dept (id, name) VALUES (4, 'HR');
INSERT INTO dept (id, name) VALUES (5, 'Admin');
INSERT INTO dept (id, name) VALUES (6, 'IT');
INSERT INTO dept (id, name) VALUES (7, 'Sales');
INSERT INTO dept (id, name) VALUES (8, 'Operations');
INSERT INTO dept (id, name) VALUES (9, 'Procurement');
INSERT INTO dept (id, name) VALUES (10, 'Logistics');
INSERT INTO dept (id, name) VALUES (11, 'Finance');
INSERT INTO dept (id, name) VALUES (12, 'HR');
INSERT INTO dept (id, name) VALUES (13, 'Admin');
INSERT INTO dept (id, name) VALUES (14, 'IT');
INSERT INTO dept (id, name) VALUES (15, 'Sales');
INSERT INTO dept (id, name) VALUES (16, 'Support');
INSERT INTO dept (id, name) VALUES (17, 'Legal');
INSERT INTO dept (id, name) VALUES (18, 'Customer Care');
INSERT INTO dept (id, name) VALUES (19, 'Marketing');
INSERT INTO dept (id, name) VALUES (20, 'Finance');
INSERT INTO dept (id, name) VALUES (21, 'Design');
INSERT INTO dept (id, name) VALUES (22, 'HR');
INSERT INTO dept (id, name) VALUES (23, 'IT');
INSERT INTO dept (id, name) VALUES (24, 'Admin');
INSERT INTO dept (id, name) VALUES (25, 'Operations');
INSERT INTO dept (id, name) VALUES (26, 'Finance');
INSERT INTO dept (id, name) VALUES (27, 'Sales');
INSERT INTO dept (id, name) VALUES (28, 'IT');
INSERT INTO dept (id, name) VALUES (29, 'Support');
INSERT INTO dept (id, name) VALUES (30, 'Legal');
INSERT INTO dept (id, name) VALUES (31, 'Marketing');
INSERT INTO dept (id, name) VALUES (32, 'HR');
INSERT INTO dept (id, name) VALUES (33, 'Admin');
INSERT INTO dept (id, name) VALUES (34, 'Finance');
INSERT INTO dept (id, name) VALUES (35, 'IT');
INSERT INTO dept (id, name) VALUES (36, 'Sales');
INSERT INTO dept (id, name) VALUES (37, 'Design');
INSERT INTO dept (id, name) VALUES (38, 'Marketing');
INSERT INTO dept (id, name) VALUES (39, 'Operations');
INSERT INTO dept (id, name) VALUES (40, 'Logistics');
INSERT INTO dept (id, name) VALUES (41, 'Support');
INSERT INTO dept (id, name) VALUES (42, 'Legal');
INSERT INTO dept (id, name) VALUES (43, 'Customer Care');
INSERT INTO dept (id, name) VALUES (44, 'Finance');
INSERT INTO dept (id, name) VALUES (45, 'HR');
INSERT INTO dept (id, name) VALUES (46, 'IT');
INSERT INTO dept (id, name) VALUES (47, 'Admin');
INSERT INTO dept (id, name) VALUES (48, 'Sales');
INSERT INTO dept (id, name) VALUES (49, 'Support');
INSERT INTO dept (id, name) VALUES (50, 'Finance');

-- hobbies table
INSERT INTO hobbies (id, name) VALUES (1, 'Cricket');
INSERT INTO hobbies (id, name) VALUES (2, 'Badminton');
INSERT INTO hobbies (id, name) VALUES (3, 'Football');
INSERT INTO hobbies (id, name) VALUES (4, 'Music');
INSERT INTO hobbies (id, name) VALUES (5, 'Painting');
INSERT INTO hobbies (id, name) VALUES (6, 'Dancing');
INSERT INTO hobbies (id, name) VALUES (7, 'Gardening');
INSERT INTO hobbies (id, name) VALUES (8, 'Cooking');
INSERT INTO hobbies (id, name) VALUES (9, 'Swimming');
INSERT INTO hobbies (id, name) VALUES (10, 'Chess');
INSERT INTO hobbies (id, name) VALUES (11, 'Yoga');
INSERT INTO hobbies (id, name) VALUES (12, 'Reading');
INSERT INTO hobbies (id, name) VALUES (13, 'Cycling');
INSERT INTO hobbies (id, name) VALUES (14, 'Travelling');
INSERT INTO hobbies (id, name) VALUES (15, 'Photography');
INSERT INTO hobbies (id, name) VALUES (16, 'Writing');
INSERT INTO hobbies (id, name) VALUES (17, 'Singing');
INSERT INTO hobbies (id, name) VALUES (18, 'Basketball');
INSERT INTO hobbies (id, name) VALUES (19, 'Volleyball');
INSERT INTO hobbies (id, name) VALUES (20, 'Gymnastics');
INSERT INTO hobbies (id, name) VALUES (21, 'Running');
INSERT INTO hobbies (id, name) VALUES (22, 'Kabbadi');
INSERT INTO hobbies (id, name) VALUES (23, 'Hiking');
INSERT INTO hobbies (id, name) VALUES (24, 'Drama');
INSERT INTO hobbies (id, name) VALUES (25, 'Poetry');
INSERT INTO hobbies (id, name) VALUES (26, 'Magic Tricks');
INSERT INTO hobbies (id, name) VALUES (27, 'Table Tennis');
INSERT INTO hobbies (id, name) VALUES (28, 'Horse Riding');
INSERT INTO hobbies (id, name) VALUES (29, 'Skating');
INSERT INTO hobbies (id, name) VALUES (30, 'Sculpture');
INSERT INTO hobbies (id, name) VALUES (31, 'Bird Watching');
INSERT INTO hobbies (id, name) VALUES (32, 'Calligraphy');
INSERT INTO hobbies (id, name) VALUES (33, 'Fishing');
INSERT INTO hobbies (id, name) VALUES (34, 'Computer Games');
INSERT INTO hobbies (id, name) VALUES (35, 'Collecting Stamps');
INSERT INTO hobbies (id, name) VALUES (36, 'Pottery');
INSERT INTO hobbies (id, name) VALUES (37, 'Karate');
INSERT INTO hobbies (id, name) VALUES (38, 'Skating');
INSERT INTO hobbies (id, name) VALUES (39, 'Travel Blogging');
INSERT INTO hobbies (id, name) VALUES (40, 'Vlogging');
INSERT INTO hobbies (id, name) VALUES (41, 'Animal Rescue');
INSERT INTO hobbies (id, name) VALUES (42, 'Volunteering');
INSERT INTO hobbies (id, name) VALUES (43, 'Cooking');
INSERT INTO hobbies (id, name) VALUES (44, 'Storytelling');
INSERT INTO hobbies (id, name) VALUES (45, 'Acting');
INSERT INTO hobbies (id, name) VALUES (46, 'Doodling');
INSERT INTO hobbies (id, name) VALUES (47, 'Origami');
INSERT INTO hobbies (id, name) VALUES (48, 'Blogging');
INSERT INTO hobbies (id, name) VALUES (49, 'Making Podcasts');
INSERT INTO hobbies (id, name) VALUES (50, 'Nature Walks');

-- salary table (50 random examples, edit as required)
INSERT INTO salary (id, salary, dob) VALUES (1, 65000, '1992-01-15');
INSERT INTO salary (id, salary, dob) VALUES (2, 70000, '1988-06-22');
INSERT INTO salary (id, salary, dob) VALUES (3, 40000, '1990-12-01');
INSERT INTO salary (id, salary, dob) VALUES (4, 85000, '1985-03-18');
INSERT INTO salary (id, salary, dob) VALUES (5, 52000, '1991-04-07');
INSERT INTO salary (id, salary, dob) VALUES (6, 90000, '1989-07-30');
INSERT INTO salary (id, salary, dob) VALUES (7, 75000, '1995-11-10');
INSERT INTO salary (id, salary, dob) VALUES (8, 81000, '1994-09-03');
INSERT INTO salary (id, salary, dob) VALUES (9, 60000, '1996-05-28');
INSERT INTO salary (id, salary, dob) VALUES (10, 49000, '1982-02-11');
INSERT INTO salary (id, salary, dob) VALUES (11, 64000, '1987-08-16');
INSERT INTO salary (id, salary, dob) VALUES (12, 58000, '1993-01-22');
INSERT INTO salary (id, salary, dob) VALUES (13, 41000, '1990-07-09');
INSERT INTO salary (id, salary, dob) VALUES (14, 76500, '1984-05-14');
INSERT INTO salary (id, salary, dob) VALUES (15, 88500, '1997-03-03');
INSERT INTO salary (id, salary, dob) VALUES (16, 45600, '1997-12-29');
INSERT INTO salary (id, salary, dob) VALUES (17, 68200, '1996-09-19');
INSERT INTO salary (id, salary, dob) VALUES (18, 93500, '1991-10-24');
INSERT INTO salary (id, salary, dob) VALUES (19, 71000, '1998-04-01');
INSERT INTO salary (id, salary, dob) VALUES (20, 55500, '1986-07-02');
INSERT INTO salary (id, salary, dob) VALUES (21, 80500, '1992-08-21');
INSERT INTO salary (id, salary, dob) VALUES (22, 61700, '1983-06-12');
INSERT INTO salary (id, salary, dob) VALUES (23, 68900, '1994-11-25');
INSERT INTO salary (id, salary, dob) VALUES (24, 71000, '1993-01-29');
INSERT INTO salary (id, salary, dob) VALUES (25, 49000, '1981-05-28');
INSERT INTO salary (id, salary, dob) VALUES (26, 92700, '1988-10-14');
INSERT INTO salary (id, salary, dob) VALUES (27, 63000, '1990-03-13');
INSERT INTO salary (id, salary, dob) VALUES (28, 57500, '1992-11-15');
INSERT INTO salary (id, salary, dob) VALUES (29, 80300, '1995-09-02');
INSERT INTO salary (id, salary, dob) VALUES (30, 84500, '1987-12-19');
INSERT INTO salary (id, salary, dob) VALUES (31, 73000, '1989-08-06');
INSERT INTO salary (id, salary, dob) VALUES (32, 56400, '1996-04-13');
INSERT INTO salary (id, salary, dob) VALUES (33, 89000, '1993-10-15');
INSERT INTO salary (id, salary, dob) VALUES (34, 60500, '1980-01-10');
INSERT INTO salary (id, salary, dob) VALUES (35, 47500, '1992-07-20');
INSERT INTO salary (id, salary, dob) VALUES (36, 81300, '1989-11-23');
INSERT INTO salary (id, salary, dob) VALUES (37, 84100, '1981-02-18');
INSERT INTO salary (id, salary, dob) VALUES (38, 62200, '1990-03-29');
INSERT INTO salary (id, salary, dob) VALUES (39, 91700, '1996-03-22');
INSERT INTO salary (id, salary, dob) VALUES (40, 72000, '1988-11-02');
INSERT INTO salary (id, salary, dob) VALUES (41, 40800, '1994-06-25');
INSERT INTO salary (id, salary, dob) VALUES (42, 76800, '1985-09-16');
INSERT INTO salary (id, salary, dob) VALUES (43, 55100, '1987-06-30');
INSERT INTO salary (id, salary, dob) VALUES (44, 66000, '1992-10-08');
INSERT INTO salary (id, salary, dob) VALUES (45, 87000, '1991-04-29');
INSERT INTO salary (id, salary, dob) VALUES (46, 48500, '1995-01-20');
INSERT INTO salary (id, salary, dob) VALUES (47, 52800, '1991-06-15');
INSERT INTO salary (id, salary, dob) VALUES (48, 75100, '1985-11-14');
INSERT INTO salary (id, salary, dob) VALUES (49, 57600, '1994-09-07');
INSERT INTO salary (id, salary, dob) VALUES (50, 61300, '1986-04-23');

-- entertainment table
INSERT INTO entertainment (id, name) VALUES (1, 'Watching Movies');
INSERT INTO entertainment (id, name) VALUES (2, 'Listening Music');
INSERT INTO entertainment (id, name) VALUES (3, 'Playing Cricket');
INSERT INTO entertainment (id, name) VALUES (4, 'Watching TV');
INSERT INTO entertainment (id, name) VALUES (5, 'Going Shopping');
INSERT INTO entertainment (id, name) VALUES (6, 'Comedy Shows');
INSERT INTO entertainment (id, name) VALUES (7, 'Travel Shows');
INSERT INTO entertainment (id, name) VALUES (8, 'Adventure Sports');
INSERT INTO entertainment (id, name) VALUES (9, 'Gaming');
INSERT INTO entertainment (id, name) VALUES (10, 'Reality Shows');
INSERT INTO entertainment (id, name) VALUES (11, 'Classical Music');
INSERT INTO entertainment (id, name) VALUES (12, 'Dance Shows');
INSERT INTO entertainment (id, name) VALUES (13, 'Poetry');
INSERT INTO entertainment (id, name) VALUES (14, 'Theater');
INSERT INTO entertainment (id, name) VALUES (15, 'Painting');
INSERT INTO entertainment (id, name) VALUES (16, 'Scrabble');
INSERT INTO entertainment (id, name) VALUES (17, 'Karaoke');
INSERT INTO entertainment (id, name) VALUES (18, 'Festivals');
INSERT INTO entertainment (id, name) VALUES (19, 'Charity Events');
INSERT INTO entertainment (id, name) VALUES (20, 'Video Games');
INSERT INTO entertainment (id, name) VALUES (21, 'Puzzles');
INSERT INTO entertainment (id, name) VALUES (22, 'Street Food Tours');
INSERT INTO entertainment (id, name) VALUES (23, 'Short Films');
INSERT INTO entertainment (id, name) VALUES (24, 'Football Watching');
INSERT INTO entertainment (id, name) VALUES (25, 'Singing Shows');
INSERT INTO entertainment (id, name) VALUES (26, 'YouTube');
INSERT INTO entertainment (id, name) VALUES (27, 'Bike Rides');
INSERT INTO entertainment (id, name) VALUES (28, 'Drama');
INSERT INTO entertainment (id, name) VALUES (29, 'Handicrafts');
INSERT INTO entertainment (id, name) VALUES (30, 'Soap Operas');
INSERT INTO entertainment (id, name) VALUES (31, 'Standup Comedy');
INSERT INTO entertainment (id, name) VALUES (32, 'Magic Shows');
INSERT INTO entertainment (id, name) VALUES (33, 'Folk Music');
INSERT INTO entertainment (id, name) VALUES (34, 'Bhangra Performances');
INSERT INTO entertainment (id, name) VALUES (35, 'Indian Classical Dance');
INSERT INTO entertainment (id, name) VALUES (36, 'Table Tennis');
INSERT INTO entertainment (id, name) VALUES (37, 'Cooking Shows');
INSERT INTO entertainment (id, name) VALUES (38, 'Quiz Contests');
INSERT INTO entertainment (id, name) VALUES (39, 'Ghazals');
INSERT INTO entertainment (id, name) VALUES (40, 'Documentaries');
INSERT INTO entertainment (id, name) VALUES (41, 'Science Programs');
INSERT INTO entertainment (id, name) VALUES (42, 'Fashion Shows');
INSERT INTO entertainment (id, name) VALUES (43, 'Marathons');
INSERT INTO entertainment (id, name) VALUES (44, 'Art Exhibitions');
INSERT INTO entertainment (id, name) VALUES (45, 'Beach Volleyball');
INSERT INTO entertainment (id, name) VALUES (46, 'Live Music Gigs');
INSERT INTO entertainment (id, name) VALUES (47, 'Instrumental Performances');
INSERT INTO entertainment (id, name) VALUES (48, 'Open Mics');
INSERT INTO entertainment (id, name) VALUES (49, 'Interview Shows');
INSERT INTO entertainment (id, name) VALUES (50, 'Celebrity Interviews');
```
---- importing the data
```
psql -U postgres -d empdb -f insert_data.sql
```
