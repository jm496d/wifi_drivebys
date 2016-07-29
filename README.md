# wifi_drivebys
Flagging potential drivebys from McDonalds and Walmart wifi sessions

WiFi driveby filtering refers to  the methodology of providing an alternate wifi session end time by levering CDR locates from nearby macrocellular antennas. 

Interface Specifications

1.	WiFi Sessions Data

Locates are loaded from feed_db.safe_wifi_session_opt_in and aggregated by venue, day and day part, selecting the minimum and maximum session start date and end date, respectively, for each device. Store aggregates in a similar format:
venue_code          		string
phone               		string
date                		string
daypart             		string
wifi_session_start_date  	string
wifi_session_end_date 		string

2.	Identification of Deterministic Antennas (NOTE: THIS STEP WAS DONE OUTSIDE OF THIS CODE)

Identify the antennas within 5 miles that do not provide coverage to the venue. These are referred to as the “non-coverage” antennas. The “coverage” antennas are initially identified as being associated with the the 3 nearest towers (using Euclidian distance) to a given venue. 

3.	Calculation of Adjusted WiFi Session Duration

The timestamp of the first cellular locate on a non-coverage antenna should be used as a proxy for the wifi session end time, but only if the cellular locate timestamp is less than the wifi end timestamp. 

4.	Population of WiFi Drivebys Flag

A “driveby” flag should be created if the session duration (session end time minus session start time) is less than the minimum required duration as defined for that venue type.

5.	Adjustment of Deterministed Antennas

For a large portion of venues (~50% in the case of McDonalds), antennas on the fourth and sometimes fifth nearest towers needs to be considered as coverage antennas as well. The process to identify coverage antennas beyond the 3 nearest towers is iterative, and should only be done when the removal rate for that venue is greater than 15 basis points from the median removal rate for all venues of that brand.
