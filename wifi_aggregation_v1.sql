--All venues in 2016--
drop table jm496d_wifi_brands_2016;
create table jm496d_wifi_brands_2016 as 
select service_provider_brand, count(distinct location_identifier) as count from feed_db.aws_venue_decommit_2
where ds like '2016%'
group by service_provider_brand;

--McDonalds and WalMart--
drop table jm496d_wifi_drivebys_1;
create table jm496d_wifi_drivebys_1 as 
select distinct
location_identifier as venue_code, 
case 
when service_provider_brand = "McDonald's" then 'McDonalds'
when service_provider_brand = "Wal-Mart Stores" then 'Walmart'
end as 
service_provider_brand, 
latitude, 
longitude, 
location_address1 as address, 
english_location_city as city, 
location_state_province_name as state, 
location_zip_postal_code as zip,
utc_timezone
from feed_db.aws_venue_decommit_2
where ds = '2016040100'
and service_provider_brand in ("McDonald's", "Wal-Mart Stores");

--WIFI SESSIONS--
drop table jm496d_wifi_drivebys_2;
create table jm496d_wifi_drivebys_2 as
select a.venue_code, b.service_provider_brand, a.phone, a.start_date, a.stop_date 
from feed_db.safe_wifi_session_opt_in a 
join jm496d_wifi_drivebys_1 b 
on a.venue_code=b.venue_code
where a.ds between '2016040200' and '2016041000';

drop table jm496d_wifi_drivebys_3;
create table jm496d_wifi_drivebys_3 as select 
a.venue_code, a.service_provider_brand, phone, start_date, stop_date, 
case
when b.utc_timezone = 'ET' then 'EST'
when b.utc_timezone = 'PT' then 'PST'
when b.utc_timezone = 'CT' then 'CST'
when b.utc_timezone = 'MT' then 'MST'
else b.utc_timezone end as utc_timezone
from jm496d_wifi_drivebys_2 a 
join jm496d_wifi_drivebys_1 b 
on a.venue_code=b.venue_code
and utc_timezone != 'AKT'
and utc_timezone != 'AT';

drop table jm496d_wifi_drivebys_4;
create table jm496d_wifi_drivebys_4 as select 
venue_code, service_provider_brand, phone, start_date, stop_date, 
from_utc_timestamp(start_date, utc_timezone) as start_date_local,
from_utc_timestamp(stop_date, utc_timezone) as stop_date_local, 
utc_timezone
from jm496d_wifi_drivebys_3
where to_date(from_utc_timestamp(start_date, utc_timezone)) between '2016-04-03' and '2016-04-09';

---------------------------------

drop table jm496d_wifi_drivebys_5;
create table jm496d_wifi_drivebys_5 as select 
venue_code, service_provider_brand, phone, start_date, stop_date, start_date_local, stop_date_local, to_date(start_date_local) as date, 
case
when hour(start_date_local) >=0 and hour(start_date_local) < 6 then 1 
when hour(start_date_local) >=6 and hour(start_date_local) < 10 then 2 
when hour(start_date_local) >=10 and hour(start_date_local) < 15 then 3
when hour(start_date_local) >=15 and hour(start_date_local) < 19 then 4
else 5 end as daypart, 
utc_timezone
from jm496d_wifi_drivebys_4;

--CELLULAR SESSIONS--

--non coverage antennas by venue_code--
drop table jm496d_wifi_drivebys_6;  
create table jm496d_wifi_drivebys_6 (
venue_code string,
service_provider_brand string,
venue_lat string,
venue_long string,
address string,
city string,
state string,
zip string,
radius_size string,
lacci string,
tower_lat string,
tower_long string,
utc_timezone string, 
distance_miles string,
distance_miles_grouped string
)
ROW FORMAT DELIMITED
FIELDS TERMINATED BY ","
ESCAPED BY '\\'
STORED AS TEXTFILE
TBLPROPERTIES("skip.header.line.count"="1");  

LOAD DATA LOCAL INPATH 'mcd_wmt_antennas_3.csv' OVERWRITE INTO TABLE jm496d_wifi_drivebys_6;

--distinct non coverage antennas--
drop table jm496d_wifi_drivebys_7;
create table jm496d_wifi_drivebys_7 as 
select distinct lacci as laccid, distance_miles from jm496d_wifi_drivebys_6;

--SCAMP records from non coverage antennas--
drop table jm496d_wifi_drivebys_8;
create table jm496d_wifi_drivebys_8 as 
select * from derived_db.common_location_format_et a 
join jm496d_wifi_drivebys_7 b 
on a.source_network_element_id=b.laccid
where et between '2016040200' and '2016041000'
and (source = 'AWSD' OR source = 'AWSV' OR source = 'SMSD');

--get imsis for wifi/macro data join--
drop table jm496d_wifi_drivebys_9;
create table jm496d_wifi_drivebys_9 as 
select a.*, b.imsi 
from jm496d_wifi_drivebys_5 a 
left join feed_db.safe_universal_bridge b  
on a.phone= b.subscriber_number
and b.ds = '2016040100';

select count, count(*) as freq from 
(select phone, count(*) as count from (select distinct phone, imsi from jm496d_wifi_drivebys_9) a group by phone, imsi) a 
group by count;

--jm496d_wifi_drivebys_9: wifi imsis
--jm496d_wifi_drivebys_6: laccid by venue_code
--jm496d_wifi_drivebys_8: scamp records

--wifi/macro data join
drop table jm496d_wifi_drivebys_10;
create table jm496d_wifi_drivebys_10 as select
a.venue_code, a.service_provider_brand, a.phone, a.start_date_local, a.stop_date_local, a.daypart, unix_timestamp(a.start_date) as start_date_utc, unix_timestamp(a.stop_date) as stop_date_utc, d.event_timestamp_utc_epoch_sec, d.distance_miles_grouped, d.source_network_element_id as laccid, latitude_dec_deg as tower_lat, longitude_dec_deg as tower_long
from jm496d_wifi_drivebys_9 a
join jm496d_wifi_drivebys_6 c 
on a.venue_code=c.venue_code
join jm496d_wifi_drivebys_8 d 
on a.imsi = d.device_id
and c.lacci = d.source_network_element_id
and to_date(to_utc_timestamp(a.start_date, a.utc_timezone)) = to_date(from_unixtime(d.event_timestamp_utc_epoch_sec));
1,599,142,792

---filter drivebys 10 table--
drop table jm496d_wifi_drivebys_10_1;
create table jm496d_wifi_drivebys_10_1 as 
select a.* from jm496d_wifi_drivebys_10 a 
join jm496d_wifi_drivebys_6 c 
on a.venue_code = c.venue_code
and a.laccid = c.lacci
and a.distance_miles_grouped = c.distance_miles_grouped;
351,141,426

--calculate time between max(wifi start time) and min(macro start time), with macro start time >= max(wifi start time)
drop table jm496d_wifi_drivebys_11;
create table jm496d_wifi_drivebys_11 as select 
venue_code, service_provider_brand, phone, to_date(start_date_local) as date, daypart, 
min(start_date_local) as min_wifi_ts, 
min(start_date_utc) as min_wifi_ts_utc_epo,
max(start_date_local) as max_wifi_ts, 
max(start_date_utc) as max_wifi_ts_utc_epo,
max(stop_date_utc) as max_wifi_stop_ts_utc_epo,
min(event_timestamp_utc_epoch_sec) as min_macro_ts_utc_epo,
max(stop_date_utc) - min(start_date_utc) as wifi_duration,
max(start_date_utc) - min(start_date_utc) as wifi_duration_imptd,
min(event_timestamp_utc_epoch_sec) - min(start_date_utc) as macro_duration,
min(event_timestamp_utc_epoch_sec) - max(start_date_utc) as macro_timelapse, 
distance_miles_grouped, laccid, tower_lat, tower_long
from jm496d_wifi_drivebys_10_1  
where event_timestamp_utc_epoch_sec >= start_date_utc
group by venue_code, service_provider_brand, phone, to_date(start_date_local), daypart, distance_miles_grouped, laccid, tower_lat, tower_long;

--remove records where macro start is before max wifi
drop table jm496d_wifi_drivebys_12;
create table jm496d_wifi_drivebys_12 as select 
venue_code, service_provider_brand, phone, date, daypart, min_wifi_ts_utc_epo, max_wifi_stop_ts_utc_epo, min_macro_ts_utc_epo, wifi_duration, macro_duration, macro_timelapse, distance_miles_grouped, laccid, tower_lat, tower_long 
from jm496d_wifi_drivebys_11
where macro_timelapse >=0;
96792399

--remove macro records beyond the *first seen macro record*
 
drop table jm496d_wifi_drivebys_13;
create table jm496d_wifi_drivebys_13 as select 
a.venue_code, a.service_provider_brand, a.phone, a.date, a.daypart, a.min_wifi_ts_utc_epo, a.max_wifi_stop_ts_utc_epo, a.min_macro_ts_utc_epo, a.wifi_duration, a.macro_duration, 
b.macro_timelapse, a.distance_miles_grouped, a.laccid, a.tower_lat, a.tower_long 
from jm496d_wifi_drivebys_12 a 
join (select venue_code, service_provider_brand, phone, date, daypart, min(macro_timelapse) as macro_timelapse from jm496d_wifi_drivebys_12
group by venue_code, service_provider_brand, phone, date, daypart) b 
on a.venue_code = b.venue_code
and a.phone = b.phone
and a.date = b.date
and a.daypart = b.daypart
and a.macro_timelapse = b.macro_timelapse;
8821535

 drop table jm496d_wifi_drivebys_14;
 create table jm496d_wifi_drivebys_14 as select 
 venue_code, service_provider_brand, date, daypart, distance_miles_grouped, driveby_flag, count(*) as count 
 from 
 (select venue_code, service_provider_brand, phone, date, daypart, distance_miles_grouped, case when macro_duration < 90 then 1 else 0 end as driveby_flag from jm496d_wifi_drivebys_13) a 
 group by venue_code, service_provider_brand, date, daypart, distance_miles_grouped, driveby_flag;
 
 
 
 




































