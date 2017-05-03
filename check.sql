-- COMP3311 16s1 Project 1 Check
--
-- MyMyUNSW Check

create or replace function
	proj1_table_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='r';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	proj1_view_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_class
	where relname=tname and relkind='v';
	return (_check = 1);
end;
$$ language plpgsql;

create or replace function
	proj1_function_exists(tname text) returns boolean
as $$
declare
	_check integer := 0;
begin
	select count(*) into _check from pg_proc
	where proname=tname;
	return (_check > 0);
end;
$$ language plpgsql;

-- proj1_check_result:
-- * determines appropriate message, based on count of
--   excess and missing tuples in user output vs expected output

create or replace function
	proj1_check_result(nexcess integer, nmissing integer) returns text
as $$
begin
	if (nexcess = 0 and nmissing = 0) then
		return 'correct';
	elsif (nexcess > 0 and nmissing = 0) then
		return 'too many result tuples';
	elsif (nexcess = 0 and nmissing > 0) then
		return 'missing result tuples';
	elsif (nexcess > 0 and nmissing > 0) then
		return 'incorrect result tuples';
	end if;
end;
$$ language plpgsql;

-- proj1_check:
-- * compares output of user view/function against expected output
-- * returns string (text message) containing analysis of results

create or replace function
	proj1_check(_type text, _name text, _res text, _query text) returns text
as $$
declare
	nexcess integer;
	nmissing integer;
	excessQ text;
	missingQ text;
begin
	if (_type = 'view' and not proj1_view_exists(_name)) then
		return 'No '||_name||' view; did it load correctly?';
	elsif (_type = 'function' and not proj1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (not proj1_table_exists(_res)) then
		return _res||': No expected results!';
	else
		excessQ := 'select count(*) '||
			   'from (('||_query||') except '||
			   '(select * from '||_res||')) as X';
		-- raise notice 'Q: %',excessQ;
		execute excessQ into nexcess;
		missingQ := 'select count(*) '||
			    'from ((select * from '||_res||') '||
			    'except ('||_query||')) as X';
		-- raise notice 'Q: %',missingQ;
		execute missingQ into nmissing;
		return proj1_check_result(nexcess,nmissing);
	end if;
	return '???';
end;
$$ language plpgsql;

-- proj1_rescheck:
-- * compares output of user function against expected result
-- * returns string (text message) containing analysis of results

create or replace function
	proj1_rescheck(_type text, _name text, _res text, _query text) returns text
as $$
declare
	_sql text;
	_chk boolean;
begin
	if (_type = 'function' and not proj1_function_exists(_name)) then
		return 'No '||_name||' function; did it load correctly?';
	elsif (_res is null) then
		_sql := 'select ('||_query||') is null';
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	else
		_sql := 'select ('||_query||') = '||quote_literal(_res);
		-- raise notice 'SQL: %',_sql;
		execute _sql into _chk;
		-- raise notice 'CHK: %',_chk;
	end if;
	if (_chk) then
		return 'correct';
	else
		return 'incorrect result';
	end if;
end;
$$ language plpgsql;

-- check_all:
-- * run all of the checks and return a table of results

drop type if exists TestingResult cascade;
create type TestingResult as (test text, result text);

create or replace function
	check_all() returns setof TestingResult
as $$
declare
	i int;
	testQ text;
	result text;
	out TestingResult;
	tests text[] := array['q1', 'q2', 'q3', 'q4', 'q5a', 'q5b', 'q5c','q6','q7','q8','q9','q10'];
begin
	for i in array_lower(tests,1) .. array_upper(tests,1)
	loop
		testQ := 'select check_'||tests[i]||'()';
		execute testQ into result;
		out := (tests[i],result);
		return next out;
	end loop;
	return;
end;
$$ language plpgsql;


--
-- Check functions for specific test-cases in Project 1
--

create or replace function check_q1() returns text
as $chk$
select proj1_check('view','q1','q1_expected',
                   $$select * from q1$$)
$chk$ language sql;

create or replace function check_q2() returns text
as $chk$
select proj1_check('view','q2','q2_expected',
                   $$select * from q2$$)
$chk$ language sql;

create or replace function check_q3() returns text
as $chk$
select proj1_check('view','q3','q3_expected',
                   $$select * from q3$$)
$chk$ language sql;

create or replace function check_q4() returns text
as $chk$
select proj1_check('view','q4','q4_expected',
                   $$select * from q4$$)
$chk$ language sql;

create or replace function check_q5a() returns text
as $chk$
select proj1_check('view','q5a','q5a_expected',
                   $$select * from q5a$$)
$chk$ language sql;

create or replace function check_q5b() returns text
as $chk$
select proj1_check('view','q5b','q5b_expected',
                   $$select * from q5b$$)
$chk$ language sql;

create or replace function check_q5c() returns text
as $chk$
select proj1_check('view','q5c','q5c_expected',
                   $$select * from q5c$$)
$chk$ language sql;

create or replace function check_q6() returns text
as $chk$
select proj1_check('function','q6','q6_expected',
                   $$select * from q6(123)$$)
$chk$ language sql;

create or replace function check_q7() returns text
as $chk$
select proj1_check('view','q7','q7_expected',
                   $$select * from q7$$)
$chk$ language sql;

create or replace function check_q8() returns text
as $chk$
select proj1_check('view','q8','q8_expected',
                   $$select * from q8$$)
$chk$ language sql;

create or replace function check_q9() returns text
as $chk$
select proj1_check('view','q9','q9_expected',
                   $$select * from q9$$)
$chk$ language sql;

create or replace function check_q10() returns text
as $chk$
select proj1_check('view','q10','q10_expected',
                   $$select * from q10$$)
$chk$ language sql;

--
-- Tables of expected results for test cases
--

drop table if exists q1_expected;
create table q1_expected (
     unswid  integer,
     name LongName
);

drop table if exists q2_expected;
create table q2_expected (
	name LongName,
	school LongString,
	starting date
);

drop table if exists q3_expected;
create table q3_expected (
	ratio numeric(4,1),
	nsubjects integer
);

drop table if exists q4_expected;
create table q4_expected (
    name LongName,
	ncourses integer
);

drop table if exists q5a_expected;
create table q5a_expected (
    id  integer
);
drop table if exists q5b_expected;
create table q5b_expected (
    id  integer
);
drop table if exists q5c_expected;
create table q5c_expected (
    id  integer
);


drop table if exists q6_expected;
create table q6_expected (
    semester text
);

drop table if exists q7_expected;
create table q7_expected (
    semester text,
    percent numeric(4,2)
);

drop table if exists q8_expected;
create table q8_expected (
    subject text,
    nofferings bigint
);

drop table if exists q9_expected;
create table q9_expected (
    unswid  integer,
    name LongName
);

drop table if exists q10_expected;
create table q10_expected (
    unswid  integer,
    name LongName
);




COPY q1_expected (unswid, name) FROM stdin;
3000010	Tamsin Rockwell
3012907	Jordan Sayed
3018513	Joshua Rechichi
3049318	Thu Ha
3055245	Yutong Li Yan
3058720	Abdo Lie
3078636	Daud Rawalpindiwala
3087372	Philip Lun
3092300	Tianxing You Jia
3101627	Yiu Man
3102214	Huihong Leng
3106928	Juniyati Rama Dass
3108512	Teri Tzifas
3113968	Alice Dai
3120361	Sani Diaz
3121077	Alex Benek
3123175	Danny Vegh
3125185	Rosanna Nippard
3126996	Raina Ignacio
3130081	Michael Freudenberg
3130445	Corey O'Loughlan
3134476	Briony Visser
3135602	Shirley Caws
3137719	Vu-Minh Samarasekera
3139456	Minna Henry-May
3141484	Andrew Landry
3141682	Madhuri Treloar
3144978	Kathryn Packham
3148169	Ka Kim
3149727	Mandy Panickar
3152913	Lee-Anne Wood
3157567	Chung Chuang
3157793	Patricia Birchmeier
3158621	Sanam Sam
3159514	Oi Cham
3163349	Kerry Plant
3165935	Theresa Crymble
3167164	Masao Chin
3171814	Linn Szeto
3173772	Fouad Moreira
3174355	Gerald Zih
3175286	James Brotherton
3177768	Thomas Crino
3178513	David Minikus
3179372	Dustin Johnsen
3179813	Georgia Feng Tian
3181454	Matthew Eley
3183557	Sophie Loughrey
3184772	Julian Ramasundara
3187037	Meredith Ganora
3187169	Giles Erol
3187681	Hai Jugueta
3191768	Alastair Thackray
3193072	Ivan Tsitsiani
3193876	An Kelly
3195354	Marliana Sondhi
3196636	Aimie Domicelj
3220521	Terri Miao
3235197	Li Woo
3245227	Pollyanna Risk
3247708	Jenni Sam
3252075	Zara Mansour
3275200	Rufino Notarnicola
3298289	Simon Liontos
\.


COPY q2_expected (name, school, starting) FROM stdin;
Christopher Taylor	Australian School of Taxation and Business Law	2011-03-07
Nicholas Hawkins	School of Medical Sciences	2001-01-01
Richard Newbury	School of Physics	2001-01-01
Robyn Ward	Clinical School - Prince of Wales Hospital	2011-05-11
Sylvia Ross	School of Art - COFA	2001-01-01
Christine Davison	School of Education	2001-01-01
Philip Mitchell	School of Psychiatry	2010-03-05
Kim Snepvangers	School of Art History & Art Education - COFA	2010-03-05
Bruce Hebblewhite	School of Mining Engineering	2010-03-05
Barbara Messerle	School of Chemistry	2010-03-05
Andrew Schultz	School of the Arts and Media	2010-03-05
Jerry Parwada	School of Banking and Finance	2011-09-19
David Cohen	School of Biological, Earth and Environmental Sciences	2010-03-05
Michael Chapman	School of Women's and Children's Health	2010-03-05
Richard Corkish	School of Photovoltaic and Renewable Engineering	2010-03-05
David Lovell	School of Humanities and Social Sciences (ADFA)	2010-03-19
Maurice Pagnucco	School of Computer Science and Engineering	2010-07-15
John Ballard	School of Biotechnology and Biomolecular Sciences	2010-03-05
Elanor Huntington	School of Engineering and Information Technology (ADFA)	2011-02-28
Patrick Finnegan	School of Information Systems, Technology and Management	2011-09-27
Warrick Lawson	School of Physical, Environmental and Mathematical Sciences (ADFA)	2011-09-06
Anne Simmons	School of Mechanical and Manufacturing Engineering	2011-10-10
Eliathamby Ambikairajah	School of Electrical Engineering & Telecommunications	2001-01-01
Robert Burford	School of Chemical Engineering	2001-01-01
Chandini MacIntyre	School of Public Health & Community Medicine	2001-01-01
Roger Read	School of Risk & Safety Science	2001-01-01
Susan Forster	Rural Clinical School	2001-01-01
John Whitelock	Graduate School of Biomedical Engineering	2011-10-10
Vanessa Lemm	School of Humanities and Languages	2012-02-20
Fiona Stapleton	School of Optometry and Vision Science	2001-01-01
Johann Murmann	School of Strategy and Entrepreneurship	2001-01-01
Simon Killcross	School of Psychology	2001-01-01
Peter Roebuck	School of Accounting	2011-03-07
Val Pinczewski	School of Petroleum Engineering	2010-03-05
Christopher Rizos	School of Surveying and Spatial Information Systems	2001-01-01
Denise Doiron	School of Economics	2013-02-25
Bruce Henry	School of Mathematics & Statistics	2013-04-10
James Lee	School of International Studies	2013-03-18
Caleb Kelly	School of Media Arts	2013-04-15
Stephen Foster	School of Civil and Environmental Engineering	2013-05-08
\.


COPY q3_expected (ratio,nsubjects) FROM stdin;
18.5	1
20.0	2
21.3	1
22.8	3
50.3	2
80.0	1
24.1	113
24.0	8866
23.8	11
48.0	9200
\.


COPY q4_expected (name, ncourses) FROM stdin;
Susan Hagon	248
\.


COPY q5a_expected (id) FROM stdin;
3040773
3172526
3144015
3124711
3131729
3173265
3159387
3124015
3126551
3183655
3128290
3192680
\.


COPY q5b_expected (id) FROM stdin;
3032185
3168474
3162463
3171891
3189546
3032240
3074135
3002883
3186595
3062680
3127217
3103918
3176369
3195695
3171566
3137680
3192533
3195008
3104466
3197893
3122796
3171666
3198807
3107927
3109365
3199922
3123330
3145518
3137777
\.


COPY q5c_expected (id) FROM stdin;
2127746
2106821
2101317
2274227
3058210
3002104
3040773
3064466
3039566
3170994
3160054
3066859
3058056
3040854
3032185
3028145
3168474
3162463
3171891
3172526
3044547
3189546
3095209
3032240
3074135
3144015
3071040
3002883
3124711
3186595
3150439
3037496
3038440
3075924
3062680
3003813
3055818
3034183
3113378
3131729
3173265
3127217
3103918
3176369
3118164
3195695
3165795
3159387
3171566
3137680
3192533
3195008
3199764
3119189
3156293
3124015
3126551
3044434
3104466
3197893
3182603
3171417
3183655
3105389
3177106
3152729
3143864
3166499
3107617
3192671
3122796
3171666
3109043
3198807
3125057
3107927
3128290
3109365
3192680
3199922
3159514
3152664
3129900
3123330
3145518
3137777
3179898
3112493
3138098
3162743
\.


-- select * from q6(123);
COPY q6_expected (semester) FROM stdin;
02s2
\.


COPY q7_expected (semester, percent) FROM stdin;
05s1	0.17
05s2	0.17
06s1	0.15
06s2	0.16
07s1	0.13
07s2	0.15
08s1	0.14
08s2	0.18
09s1	0.17
09s2	0.20
10s1	0.21
10s2	0.24
11s1	0.24
11s2	0.24
12s1	0.24
12s2	0.22
13s1	0.21
\.


COPY q8_expected (subject, nOfferings) FROM stdin;
GEND1203 Draw the World Within/Without	27
MATH3000 Mathematics/Statistics Project	26
MATH3001 Mathematics/Statistics Project	26
SDES5491 Professional Experience	29
\.


COPY q9_expected (unswid, name) FROM stdin;
3171566	Brigid Macks
\.


COPY q10_expected (unswid, name) FROM stdin;
3260955	Myall Kozelj
3232407	Aliz Balogh
3354047	Jacqueline Pring
3329420	Amanda Hollis
3349178	Eric Chik
3199879	Nonna Ballantyne
3269260	Einat Rosenberg
3380439	Seoh Ho
3201219	Jolly Duorina
3234675	Tomas Beer
3356955	Karen Kerr
3278144	Robert McElroy
\.





