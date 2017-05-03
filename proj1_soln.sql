
--
-- MyMyUNSW Solutions

-- Q1: students who have taken more than 55 courses
create or replace view Q1(unswid, name)
as
select p.unswid,p.name
from   People p
		join Course_enrolments e on (p.id=e.student)
group  by p.unswid,p.name
having count(e.course) > 55
;



-- Q2: get details of the current Heads of Schools
create or replace view Q2(name, school, starting)
as
select p.name, u.longname, a.starting
from   people p
         join affiliations a on (a.staff=p.id)
         join staff_roles r on (a.role = r.id)
         join orgunits u on (a.orgunit = u.id)
         join orgunit_types t on (u.utype = t.id)
where  r.name = 'Head of School'
         and (a.ending is null or a.ending > now()::date)
         and t.name = 'School' 
		 and a.isPrimary
;



-- Q3 UOC/ETFS ratio
create or replace view Q3(ratio,nsubjects)
as
select cast(uoc/eftsload as numeric(4,1)), count(uoc/eftsload)
from subjects
where eftsload != 0 or eftsload != null 
group by cast(uoc/eftsload as numeric(4,1))
;



-- Q4: convenor for the most courses
create or replace view has_convened(unswid, name, ncourses)
as
select p.unswid, p.name, count(c.course)
from   People p
		join Course_staff c on (p.id=c.staff)
		join Staff_roles r on (c.role=r.id)
where  r.name = 'Course Convenor'
group  by p.unswid, p.name
;

create or replace view Q4(name, ncourses)
as
select name, ncourses
from   has_convened
where  ncourses = (select max(ncourses) from has_convened)
;



-- Q5: program enrolments from 05s2
create or replace view all_program_enrolments
 as
select p.unswid, t.year, t.term, pr.id, pr.code, u.longname as unit
from   People p
		join Program_enrolments e on (p.id=e.student)
		join Programs pr on (pr.id=e.program)
		join Semesters t on (t.id=e.semester)
		join OrgUnits u on (pr.offeredby=u.id)
;

create or replace view all_stream_enrolments
as
select p.unswid, t.year, t.term, st.code, u.longname as unit
from   People p
		join Program_enrolments pe on (p.id=pe.student)
		join Stream_enrolments se on (pe.id=se.partof)
		join Streams st on (se.stream=st.id)
		join Semesters t on (t.id=pe.semester)
		join OrgUnits u on (st.offeredby=u.id)
;

create or replace view Q5a(id)
as
select unswid
from   all_program_enrolments
where  code = '3978' and year = 2005 and term = 'S2'
;

create or replace view Q5b(id)
as
select unswid
from   all_stream_enrolments
where  code='SENGA1' and year=2005 and term='S2';
;

create or replace view Q5c(id)
as
select unswid
from   all_program_enrolments
where  unit='School of Computer Science and Engineering' and year=2005 and term='S2';
;



-- Q6: term names
-- Testing case: 
-- 1. select * from q6(123);
-- 2. select * from q6(166);
create or replace function
	Q6(integer) returns text
as
$$
select substr(year::text,3,2)||lower(term) 
from   Semesters
where  id = $1
$$ language sql;



-- Q7: percentage of international students, S1 and S2, starting from 2005
/*
create or replace view Q7_EnrolmentInfo(student, stype, semester)
as
select distinct pe.student, s.stype, pe.semester
from   program_enrolments pe
         join Students s on (pe.student = s.id)
;


create or replace view Q7_SemesterStats(semester, nlocals, nintls, ntotal)
as
select semester
         sum(case when stype='local' then 1 else 0 end),
         sum(case when stype='intl' then 1 else 0 end),
         count(distinct student)
from   Q7_EnrolmentInfo
group  by semester
;


create or replace view Q7(semester, percent)
as
select Q6(semester), (nintls::float / ntotal::float)::numeric(4,2)
from   Q7_SemesterStats ss
         join Semesters s on (ss.semester = s.id)
where  s.term like 'S_' and
         s.starting between '2005-01-01' and '2019-12-31'
;
*/


create or replace view Q7_EnrolmentInfo(student, stype, term, year)
as
select distinct pe.student, stu.stype, s.term, s.year
from   program_enrolments pe, Students stu, Semesters s
where pe.student = stu.id 
and pe.semester = s.id
;


create or replace view Q7_SemesterStats(semester, nlocals, nintls, ntotal)
as
select substr(year::text,3,2)||lower(term),
         sum(case when stype='local' then 1 else 0 end),
         sum(case when stype='intl' then 1 else 0 end),
         count(distinct student)
from   Q7_EnrolmentInfo
group  by term, year
having term like 'S_' and year >= 2005
;


create or replace view Q7(semester, percent)
as
select semester, (nintls::float / ntotal::float)::numeric(4,2)
from   Q7_SemesterStats
;



-- Q8: subjects with > 25 course offerings and no staff recorded
create or replace view Q8(subject, nOfferings)
as
select s.code||' '||s.name, count(c.id)
from   Courses c
         left outer join Course_staff cs on (cs.course=c.id)
         join Subjects s on (c.subject = s.id)
group  by s.code,s.name
having count(cs.staff) = 0 and count(c.id) > 25
;


-- Q9: divide find a good research assistant
create or replace view Q9_StudentSub(unswid, sname, subject)
as
select p.unswid, p.name, s.code
from course_enrolments ce, courses c, subjects s, people p
where 
s.code similar to 'COMP34%'
and c.subject = s.id
and c.id = ce.course
and p.id = ce.student
;


create or replace view Q9(unswid, name)
as
select distinct a.unswid, a.sname
from Q9_StudentSub a
where not exists
(
	(select b.code from subjects b where b.code similar to 'COMP34%')
	except
	(select c.subject from Q9_StudentSub c
	where c.unswid = a.unswid)
)
;



-- Q10: find all students who had been enrolled in all popular subjects
create or replace view Q10_CourseInfo(code,year,term)
as
select sub.code, sem.year, sem.term
from   Subjects sub, Courses c, Semesters sem
where  sub.id = c.subject
and c.semester = sem.id
--and sem.longname not like '%Asia%'
;

create or replace view Q10_MajorSemesters(year, term)
as
select distinct Semesters.year, Semesters.term
from   Courses, Semesters
where Courses.semester = Semesters.id
and  (Semesters.year between 2002 and 2013) 
and Semesters.term like 'S%'
;


create or replace view Q10_GoodSubjects(code)
as
select distinct c.code
from   Q10_CourseInfo c
where  c.code like 'COMP9%'
	and not exists(
		(select year,term from Q10_MajorSemesters)
		except
		(select year,term from Q10_CourseInfo where code = c.code)
		)
;


create or replace view Q10_StudentSubInfo(unswid, name, code, grade)
as
select  distinct p.unswid, p.name, s.code, ce.grade
from Course_enrolments ce, People p, Subjects s, Courses c
where ce.student = p.id
and ce.course = c.id
and c.subject = s.id
and ce.grade in ('HD','DN')
and s.code like 'COMP9%'
;



create or replace view Q10(unswid, name)
as
select distinct stu.unswid, stu.name
from   Q10_StudentSubInfo stu, Q10_GoodSubjects sub
where
		not exists(
		(select code from Q10_GoodSubjects)
		except
		(select code from Q10_StudentSubInfo where unswid = stu.unswid)
		)
;





