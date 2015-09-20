ami-retirement
==============

Gets rid of old AMIs and Snapshots that are older than X days.

Assuming you name your AMIs something like this:

`autobackup-host.example.com-2015-09-05-01-15`

Just change the date value in `$daysAgo `and run the script (with AWS secret and
key in your ENV)
