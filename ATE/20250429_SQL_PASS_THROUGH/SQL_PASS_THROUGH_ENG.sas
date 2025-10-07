%let PATH=/home/student/Courses/etdp;
libname sas "&path/data";
libname db oracle path="*****" schema=ETDP
	user=student password="*****";

options sastrace=',,,d' sastraceloc=saslog nostsuffix;
options fullstimer;

/********* EXAMPLE (1) ******/
* DATA step;
data test0 ;
	set db.customers (where=(country="FR"));
run;

*PROC SQL;
proc sql;
	create table test1 as select * from db.customers where country="FR";
quit;

options sastrace=off;
options nofullstimer;

/******* EXAMPLE (2) ****/
/***** comparison KEEP and KEEP=***/
options sastrace=',,,d' sastraceloc=saslog nostsuffix;

data keep1;
	set db.orders;
	where country="US";
	keep country order_date;
run;

data keep2;
	set db.orders(keep=country order_date);
	where country="US";
run;

options sastrace=off;

/****** Positioning of the WHERE clause ****/

/**** WHERE= in output: it must be on DATETIME and not DATE  
=> filter processed by SAS on columns of type DATETIME ****/

/***** WHERE= in input (faster) and can be on DATE or DATETIME  
=> filter processed by ORACLE with implicit conversion from DATETIME to DATE ***/
options sastrace=',,,d' sastraceloc=saslog nostsuffix;


data where1 (where=(order_date between "01JAN2017"d and "31DEC2017"d ));
	set db.orders;
run;

options sastrace=',,,d' sastraceloc=saslog nostsuffix;

data where2 (where=(order_date ="02JAN2011"d ));
	*set db.orders (where=(order_date between "01JAN2017"d and "31DEC2017"d ));
	set db.orders;

	*set db.orders (where=(order_date between "01JAN2017:00:00:00"dt and "31DEC2017:00:00:00"dt));
run;

data where2_bis (where=(order_date = "02JAN2011:00:00:00"dt));
	*set db.orders (where=(order_date between "01JAN2017"d and "31DEC2017"d ));
	*set db.orders (where=(order_date between "01JAN2017:00:00:00"dt and "31DEC2017:00:00:00"dt));
	set db.orders;
run;

options sastrace=off;
options sastrace=',,,d' sastraceloc=saslog nostsuffix;

data where3 (where=(order_date between "01JAN2017:00:00:00"dt and "31DEC2017:00:00:00"dt));
	set db.orders;
run;

options sastrace=off;

/******* EXAMPLE (3) ****/
/*** Code executed by SAS due to certain functions not understood by the DBMS ***/
options sastrace=',,,d' sastraceloc=saslog nostsuffix;

proc sql;
	create table test22 as 

	select
		weekday(datepart(order_date)) as jour , sum(total_sale) as spent
	from db.orders
		where datepart(order_date) between '01JAN2017'd and '31DEC2017'd
			group by jour
				order by  jour;
quit;

options sastrace=off;

/******************************************************************************
PROC SQL Explicit Passthrough
******************************************************************************/

/******************************************************************************
Step 1 - Select * from DBMS results 
******************************************************************************/
options sastrace=',,,d' sastraceloc=saslog nostsuffix;

proc sql;
	/* connect to Oracle as db  */
	/*    (path="//server.demo.sas.com:1521/ORCL" user=student password="Metadata0"); */
	connect using db;
	select * 
		from connection to db
			(select  to_char(order_date, 'D') Weekday
				,sum(Total_Sale) as Spent 
			from etdp.orders
				where order_date between date'2017-01-01' and date'2017-12-30'
					group by to_char(order_date, 'D')
						order by to_char(order_date, 'D'))
	;
	disconnect from db;
quit;

options sastrace=off;

/******************************************************************************
Note that the code ran very fast, and that the generated SQL reported by 
SASTRACE is exactly the same as the SQL we wrote in the parentheses.  
******************************************************************************/

/******************************************************************************
Step 2 - Post-processing the DBMS result set in SAS   
******************************************************************************/
proc format;
	value $dayofweek 
		'1'='Sunday'
		'2'='Monday'
		'3'='Tuesday'
		'4'='Wednesday'
		'5'='Thursday'
		'6'='Friday'
		'7'='Saturday';
run;

proc sql;
	title "2017 Sales by Day of the Week";
	connect using db;
	create table passth1 as 
		select weekday format=$dayofweek. 'Day of the Week'
			,spent format=dollar16.2 "Total Spent in US Dollars"
		from connection to db
			(select  to_char(order_date, 'D') Weekday
				,sum(Total_Sale) as Spent 
			from etdp.orders
				where order_date between date'2017-01-01' and date'2017-12-30'
					group by to_char(order_date, 'D')
						order by to_char(order_date, 'D'))
	;
	disconnect from db;
	title;
quit;

/*************** more calculatios on SAS side **********************/
proc sql;
	title "2017 Sales by Day of the Week";
	connect using db;
	create table passth2 as 
		select weekday format=$dayofweek. 'Day of the Week'
			,spent format=dollar16.2 "Total Spent in US Dollars"
			, 'ventes' as ventes
			, spent/quantity format=dollar8.2
			, age_moyen format=best5.2  "Age moyen"
		from connection to db
			(select  to_char(order_date, 'D') Weekday
				,sum(Total_Sale) as Spent 
				,sum(quantity)   as quantity
				,avg(customer_age) as age_moyen 
			from etdp.orders
				where order_date between date'2017-01-01' and date'2017-12-30'
					group by to_char(order_date, 'D')
						order by to_char(order_date, 'D'))
	;
	disconnect from db;
	title;
quit;

/********** EXAMPLE (4) ******/
/********** SQL PASS THROUGH  EXECUTE ******/
options sastrace=',,,d' sastraceloc=saslog nostsuffix;

proc sql;
	connect using db;
	execute
		(create table etdp.result3
			as select  to_char(order_date, 'D') Weekday ,sum(Total_Sale) as Spent 
				from etdp.orders
					where order_date between date'2017-01-01' and date'2017-12-30'
						group by to_char(order_date, 'D')
							order by to_char(order_date, 'D')) by db
	;
	disconnect from db;
quit;

options sastrace=off;

/********** EXAMPLE (5)*****************/
/********** JOIN ***************/
data sas_customers;
	set db.customers;
run;

*Implicit pass-through;
options sastrace=',,,d' sastraceloc=saslog nostsuffix;

proc sql noprint;
	create table jointure1 as select 
		a.customer_id,
		b.country,
		b.customer_name,
		b.customer_age
	from sas_customers a left join db.orders b
		on a.customer_id = b.customer_id;
quit;

options sastrace=off;
options sastrace=',,,d' sastraceloc=saslog nostsuffix;

*Explicit pass-through;
proc sql noprint;
	connect using db;
	create table jointure2 as select *
		from connection to db
			(select a.customer_id,
				b.country,
				b.customer_name,
				b.customer_age
			from etdp.customers a left join etdp.orders b
				on a.customer_id = b.customer_id)
	;
	disconnect from db;
quit;

options sastrace=off;
