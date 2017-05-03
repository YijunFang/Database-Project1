--3311 proj1
--Yijun Fang
--z5061743


---Q1
create or replace view Q1(unswid, name)
as
	select p.unswid,p.name
	from People p 
	where  p.id in (select ce.student
					from course_enrolments ce
					group by ce.student
					having count(ce.course)>55)
	order by p.unswid
;

-- Q2: get details of the current Heads of Schools
create or replace view Q2(name, school, starting)
as
	select distinct p.name, o.longname,a.starting
	from People p , OrgUnits o,  Affiliations a, 
		Staff_roles s,OrgUnit_types t
	where 
		--join 5 tables
		a.staff = p.id 
		and a.orgUnit = o.id 
		and a.role =s.id 
		and o.utype = t.id 
		
		--filter condition
		and s.name like 'Head%of%School%'
		and a.ending is null 
		and a.isPrimary ='t'
		and t.name like 'School'
;



-- Q3 UOC/ETFS ratio
create or replace view Q3(ratio,nsubjects)
as
	select distinct cast(uoc/eftsload as numeric(4,1)) as ratio, count(id)
	from Subjects
	where eftsload is not null and eftsload != 0 
	group by ratio
	order by ratio
;



-- Q4: convenor for the most courses
create or replace view maxcourse(name,sumcourses)
as
	select p.name,count (course)
	from Staff_roles sr, Course_staff cs, People p
	where cs.staff = p.id --who in the course_staff
		and cs.role = sr.id --the role id
		and sr.name like '%Course Convenor%'
	group by p.name
	order by count (course) desc
;

create or replace view Q4(name, ncourses)
as
	select m.name,m.sumcourses
	from maxcourse m
	where m.sumcourses =
		(select max(m.sumcourses)
		 from maxcourse m)
;



-- Q5: program enrolments from 05S2
create or replace view Q5a(id)
as
	select peo.unswid
	from Program_enrolments e, Programs prog, 
		 Semesters sem,People peo
	where e.program = prog.id
		and e.student = peo.id
		and e.semester = sem.id
		
		and prog.code = '3978'
		and sem.term = 'S2'
		and sem.year = '2005'
;

create or replace view Q5b(id)
as
	select peo.unswid
	from Program_enrolments pe, Stream_enrolments se, Streams s, 
		 Semesters sem,People peo
	where pe.id = se.partof
		and se.stream = s.id
		and pe.student = peo.id
		and pe.semester = sem.id
		
		and s.code = 'SENGA1'
		and sem.term = 'S2'
		and sem.year = '2005'
;

create or replace view Q5c(id)
as
	select peo.unswid
	from Programs prog, OrgUnits o, 
		Program_enrolments pe, Semesters sem,People peo
	where prog.offeredBy = o.id
		and prog.id = pe.program 
		and pe.student = peo.id		
		and pe.semester = sem.id
		
		and o.longname = 'School of Computer Science and Engineering'
		and sem.term = 'S2'
		and sem.year = '2005'

	order by peo.id
;



-- Q6: semester names
-- Testing case in check.sql: SELECT * FROM Q6(123);
create or replace function
	Q6(integer) returns text
as
$$
		select substring(cast(year as text),3)||lower(term)
		from Semesters
		where Semesters.id = $1;
$$ language sql;



-- Q7: percentage of international students, S1 and S2, starting from 2005

--find the number of international sudent(in float)
--in s1 and s2 after 2005
create or replace view intl_num(semester,interStu)
as
	select sem.id, cast(count(stu.stype) as float)
	from Program_enrolments pe, Students stu, Semesters sem
	where pe.student = stu.id
		and pe.semester = sem.id
		and sem.term in ('S1','S2')
		and sem.year >= '2005'
		and stu.stype = 'intl'
	group by sem.id
	order by sem.id
;

--find the total number of student (in float)
--in s1 and s2 after 2005
create or replace view total_num(semester, totStu)
as
	select sem.id, cast(count(stu.id) as float)
	from Program_enrolments pe, Students stu, Semesters sem
	where pe.student = stu.id
		and pe.semester = sem.id
		and sem.term in ('S1','S2')
		and sem.year >= '2005'
	group by sem.id
	order by sem.id
;

--find the percentage
create or replace view Q7(semester,percent)
as
	select distinct Q6(i.semester),cast(i.interStu/t.totStu as numeric(4,2))as percent
	from total_num t, intl_num i
	where t.semester = i.semester
	order by Q6(i.semester)
;

-- Q8: subjects with > 25 course offerings and no staff recorded

--1.select Subjects.id that none of its coureses appear in the Course_staff
create or replace view noStaff(SubjectID)
as
	select Subjects.id
	from Subjects, Courses 
	where
		Subjects.id = Courses.subject
		except (select s.id 
				from Course_staff cs ,Courses c, Subjects s
				where s.id = c.subject and c.id = cs.course)
;

--2.select Subjects.id that course offered more than 25 times
create or replace view Q8(subject, nOfferings)
as
	select s.code||' '||s.name , count(c.id)
	from noStaff n, Courses c, Subjects s
	where c.subject = n.SubjectID and s.id = n.SubjectID
	group by s.code||' '||s.name
	having count(c.id) >25
;


-- Q9: find a good research assistant

--1.Find a list of all comp34% subject
create or replace view Comp34Subject(SubjectID)
as
	select Subjects.id 
	from Subjects
	where Subjects.code like 'COMP34__'
	group by Subjects.id
;

--find all students studied comp34 courses and not failed
create or replace view StuComp34(StudentID, SubjectID)
as
	select ce.student, s.id
	from Course_enrolments ce left join  Courses c on (ce.course = c.id)
		left join Subjects s on (c.subject = s.id)
	where s.code like 'COMP34%'
		and ce.mark is not null
;

--remove students who did less courses than total comp34__ courses
create or replace view CompareNum(StudentID,SubjectSum)
as
	select distinct i.StudentID, count(i.SubjectID)
	from  StuComp34 i
	group by i.StudentID
	having count(i.SubjectID) = (select count(*) from Comp34Subject)
;

--pass in student id and return null if all comp34 courses are done
create or replace function
	Check34Subject(integer) returns integer
as
$$
		select c.SubjectID 
		from Comp34Subject c
		except
			select s.SubjectID
			from Comp34Subject c,StuComp34 s
			where s.SubjectID = c.SubjectID 
				and s.StudentID = $1
$$ language sql;

--finally find students' name with student id
create or replace view Q9(unswid, name)
as
	select p.unswid, p.name
	from CompareNum c left join People p on (p.id = c.StudentID)
	where Check34Subject(c.StudentID) is null
;


-- Q10: find all students who had been enrolled in all popular subjects

--1. find all the semesters between list by name
create or replace view Required_Sem(SemesterName)
as
	select distinct Q6(id)
	from Semesters 
	where year between '2002' and '2013' 
		and term in ('S1','S2')
	group by Q6(id)
	order by Q6(id)
;

--2. Filter once: find all subject like 'comp9%', held in this period
create or replace view Comp9_Sem(SubjectID, SemesterName)
as
	select Subjects.id, Q6(Semesters.id)
	from Courses left join Subjects on (Courses.subject = Subjects.id)
		left join Semesters on (Courses.semester = Semesters.id)

	where Subjects.code like 'COMP9%'
		and Semesters.year between '2002' and '2013' 
		and Semesters.term in ('S1','S2')
	order by Subjects.id

;

--3. Filter twice: find subject that held equal or more than required times
create or replace view PopularComp9(SubjectID, sum)
as
	select distinct SubjectID, count(SemesterName)
	from Comp9_Sem
	group by SubjectID
	having count(SemesterName) >= (select count(*) from Required_Sem)
;

--pass in semester names and return null if all semesters are the same
create or replace function
	Check9Semester(integer) returns char
as
$$
		select Required_Sem.SemesterName
		from Required_Sem
		except
			select p.SemesterName
			from Comp9_Sem p, Required_Sem s
			where p.SubjectID = $1 
				and s.SemesterName = p.SemesterName
				
$$ language sql;


--4. Double check if the semesters are correct return set of popular comp9 courses
create or replace view SelectedSubjects(SubjectID)
as
	select distinct PopularComp9.SubjectID 
	from PopularComp9
	where Check9Semester(PopularComp9.SubjectID) is null
;


--5. Filter students who have done any of the popular comp9 courses and has good performance
create or replace view StuComp9(unswid, name, SubjectID)
as
	select p.unswid, p.name, s.SubjectID

	from SelectedSubjects s left join Courses c on (c.subject = s.SubjectID)
		left join Course_enrolments ce on (ce.course=c.id)
		left join People p on(ce.student = p.id)
		 
	where ce.grade in ('HD','DN')  

	order by p.id
;

--Filter students that have done all the popular comp9 courses
create or replace view Q10(unswid, name)
as
	select distinct StuComp9.unswid, StuComp9.name
	from StuComp9 
	group by StuComp9.unswid, StuComp9.name
	having count(StuComp9.SubjectID) = (select count(*) from SelectedSubjects)
;

