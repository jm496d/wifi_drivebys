# wifi_drivebys
Flagging potential drivebys from McDonalds and Walmart wifi sessions

WiFi driveby filtering refers to  the methodology of providing an alternate wifi session end time by levering CDR locates from nearby macrocellular antennas. 

Interface Specifications

WiFi Sessions Data
Locates are loaded from feed_db.safe_wifi_session_opt_in and aggregated by venue, day and day part, selecting the minimum and maximum session start date and end date, respectively, for each device. Store aggregates in a similar format:
venue_code          		string
phone               		string
date                		string
daypart             		string
wifi_session_start_date  	string
wifi_session_end_date 		string

Identification of Deterministic Antennas
Identify the antennas within 5 miles that do not provide coverage to the venue. These are referred to as the “non-coverage” antennas. The “coverage” antennas are initially identified as being associated with the towers whose centroid is between 3-5 miles from the venue, excluding the 3 nearest towers to the venue. 

Calculation of Adjusted WiFi Session Duration
The timestamp of the first cellular locate on a non-coverage antenna should be used as a proxy for the wifi session end time, but only if the cellular locate timestamp is less than the wifi end timestamp. 

Population of WiFi Drivebys Flag
A “driveby” flag should be created if the session duration (session end time minus session start time) is less than the minimum required duration as defined for that venue type.
Note: The processes listed in steps 1, 3 and 4 have been run for McDonalds and Walmart for one week in April. 

A summary of results for McDonalds is available here: 

https://wiki.web.att.com/display/CIP/Wi-Fi+Data+Cleansing 

Adjustment of Deterministed Antennas
For a large portion of venues (~50% in the case of McDonalds), antennas on the fourth and sometimes fifth nearest towers needs to be designated as coverage antennas as well. The process to identify coverage antennas beyond the 3 nearest towers is iterative, and should only be done when the removal rate for that venue is greater than 10 percentage points from the median removal rate for all venues within the same brand.
