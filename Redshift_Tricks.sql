Easy Redshift Export

	WbExport -file={fileName.extension} =type=test -delimiter=\test;
	{query};


Testing for stddev
	-- Test Performed in MAP cluster against manual COST/COOP upload
	-- Gets last week date range:
	with t1 as ( --t1 just gets row counts per day
	    select count(1) as cnt
	    from mktg_usr.sp_restated_orders
	    where odate between '{}' and '{}'
	    group by odate
	), t2 as ( --agg t1
	    select
	        min(cnt) as min0,
	        max(cnt) as max0,
	        avg(cnt) as avg0,
	        stddev(cnt) as std,
	        count(cnt) as num_days
	    from t1
	) select
	    -- 1 std dev failed with good counts, 3+ std dev passed with one day = very low number, like 10
	    (min0 > (avg0 - (2*std))) and       -- lower_ok, to catch incompletely loaded days
	    (max0 < (avg0 + (2*std))) and       -- upper_ok, to catch insanity
	    num_days = 7 as ok                  -- count_ok, to catch completely unloaded days
	from t2;

	--lower_ok line would trigger (be false) if one day was at say 1100 rows because its only partially loaded. upper_ok would trigger if one day had a million rows because of some bug. and the count_ok just makes sure each of the seven days has at least one row.
	--standard deviation means I don’t have to guess what the minimum should be, it’s calculated from the counts. There is a risk there that if multiple days weren’t completely loaded, the average would drop AND the standard deviation would grow and it might pass when it shouldn’t.
