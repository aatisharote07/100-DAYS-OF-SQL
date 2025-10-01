SELECT Courses.course_id , Courses.instructor, Students.student_id
FROM Students
INNER JOIN Courses
ON Students.course_id = Courses.course_id;