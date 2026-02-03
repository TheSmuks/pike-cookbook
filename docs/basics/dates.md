---
id: dates
title: Dates and Times
sidebar_label: Dates and Times
---

## Introduction

Pike has an extensive Calendar module that provides all manners of manipulating dates and times.

```pike
// Pike has an extensive Calendar module that provides all manners of
// manipulating dates and times.
write("Today is day %d of the current year.\n", localtime(time())->yday+1);
// Today is day 325 of the current year.

write("Today is day %d of the current year.\n", Calendar.now()->year_day());
// Today is day 325 of the current year.
```

## Finding Today's Date

```pike
int day, month, year;
mapping now=localtime(time());
year  = now->year+1900;
month = now->mon+1;
day   = now->mday;

write("The current date is %04d %02d %02d\n", year, month, day);

object now=Calendar.now();
year  = now->year_no();
month = now->month_no();
day   = now->month_day();

write("The current date is %04d %02d %02d\n", year, month, day);

write("The current date is %04d %02d %02d\n", @lambda(){ return ({ now->year_no(), now->month_no(), now->month_day() }); }(Calendar.now()));
// this is essentially the same as the respective perl code:
// lambda creates an anonymous function, which in this case takes one argument
// and returns an array. the array is the spliced into the arguments of write().
// if the goal is to get by without a temporary variable this is a rather
// pointless exercise, as there is still a temporary variable (in the function)
// and the temporary function on top of that. more interresting is the
// functional approach aspect.
```

## Converting DMYHMS to Epoch Seconds

```pike
// dwim_time() handles most common date and time formats.
Calendar.dwim_time("2:40:25 23.11.2004");
// Result: Second(Tue 23 Nov 2004 2:40:25 CET)
Calendar.dwim_time("2:40:25 23.11.2004")->unix_time();
// Result: 1101174025

Calendar.dwim_time("2:40:25 UTC 23.11.2004");
// Result: Second(Tue 23 Nov 2004 2:40:25 UTC)

// faster, because there is no need for guessing:
Calendar.parse("%Y-%M-%D %h:%m:%s %z","2004-11-23 2:40:25 UTC");
// Result: Second(Tue 23 Nov 2004 2:40:25 UTC)

// without parsing
Calendar.Second(2004, 11, 23, 2, 40, 25);
// Result: Second(Tue 23 Nov 2004 2:40:25 CET)

// functional
Calendar.Year(2004)->month(11)->day(23)->hour(2)->minute(40)->second(25);
// Result: Second(Tue 23 Nov 2004 2:40:25 CET)

Calendar.Day(2004, 11, 23)->set_timezone("UTC")->hour(2)->minute(40)->second(25);
// Result: Second(Tue 23 Nov 2004 2:40:25 UTC)

// set a time today
Calendar.dwim_time("2:40:25");
// Result: Second(Tue 23 Nov 2004 2:40:25 CET)
Calendar.dwim_time("2:40:25 UTC");
// Result: Second(Tue 23 Nov 2004 2:40:25 UTC)

Calendar.parse("%h:%m:%s %z","2:40:25 UTC");
// Result: Second(Tue 23 Nov 2004 2:40:25 UTC)
Calendar.Day()->set_timezone("UTC")->hour(2)->minute(40)->second(25);
// Result: Second(Tue 23 Nov 2004 2:40:25 UTC)
```

## Converting Epoch Seconds to DMYHMS

```pike
int unixtime=1101174025;
int day, month, year;
mapping then=localtime(unixtime);
year  = then->year+1900;
month = then->mon+1;
day   = then->mday;

write("Dateline: %02d:%02d:%02d-%04d/%02d/%02d\n", then->hour, then->min, then->sec, then->year+1900, then->mon+1, then->mday);
// Dateline: 02:40:25-2004/11/23

object othen=Calendar.Second(unixtime);
// Result: Second(Tue 23 Nov 2004 2:40:25 CET)

write("Dateline: %02d:%02d:%02d-%04d/%02d/%02d\n", othen->hour_no(),
      othen->minute_no(), othen->second_no(), othen->year_no(),
      othen->month_no(), othen->month_day());
// Dateline: 02:40:25-2004/11/23
```

## Adding to or Subtracting from a Date

```pike
int days_offet=55;
int hour_offset=2;
int minute_offset=17;
int second_offset=5;

object then=Calendar.parse("%D/%M/%Y, %h:%m:%s %p","18/Jan/1973, 3:45:50 pm")
            +Calendar.Day()*days_offet
            +Calendar.Hour()*hour_offset
            +Calendar.Minute()*minute_offset
            +Calendar.Second()*second_offset;
write("Then is %s\n", then->format_ctime());
// Then is Wed Mar 14 18:02:55 1973
write("To be precise: %d:%d:%d, %d/%d/%d\n",
             then->hour_no(), then->minute_no(), then->second_no(),
             then->month_no(), then->month_day(), then->year_no());
// To be precise: 18:2:55, 3/14/1973

int years   = 1973;
int months  = 1;
int days    = 18;
int offset  = 55;
object then = Calendar.Day(years, months, days)+offset;
write("Nat was 55 days old on: %d/%d/%d\n", then->month_no(), then->month_day(),then->year_no());
// Nat was 55 days old on: 3/14/1973
```

## Difference of Two Dates

```pike
int bree = 361535725;         // 16 Jun 1981, 4:35:25
int nat  = 96201950;          // 18 Jan 1973, 3:45:50

int difference = bree-nat;
write("There were %d seconds between Nat and Bree\n", difference);
// There were 265333775 seconds between Nat and Bree

int seconds =  difference                % 60;
int minutes = (difference / 60)          % 60;
int hours   = (difference / (60*60) )    % 24;
int days    = (difference / (60*60*24) ) % 7;
int weeks   =  difference / (60*60*24*7);

write("(%d weeks, %d days, %d:%d:%d)\n", weeks, days, hours, minutes, seconds);
// (438 weeks, 4 days, 23:49:35)

object bree = Calendar.dwim_time("16 Jun 1981, 4:35:25");
// Result: Second(Tue 16 Jun 1981 4:35:25 CEST)
object nat  = Calendar.dwim_time("18 Jan 1973, 3:45:50");
// Result: Second(Thu 18 Jan 1973 3:45:50 CET)
object difference = nat->range(bree);
// Result: Second(Thu 18 Jan 1973 3:45:50 CET - Tue 16 Jun 1981 4:35:26 CEST)

write("There were %d days between Nat and Bree\n", difference/Calendar.Day());
// There were 3071 days between Nat and Bree

int days=difference/Calendar.Day();
object left=difference->add(days,Calendar.Day)->range(difference->end());

// Calendar handles timezone differences, and since the range crosses from
// normal to daylight savings time, there is one day which has only 23 hours.
// by adding the number of days we effectively move the beginning of the range
// to the same day as the end, leaving us with a range that is less than a day
// long. when adding the days, the daylight savings switch will be taken into
// account.

write("Bree came %d days, %d:%d:%d after Nat\n",
                   days,
                   (left/Calendar.Hour())%24,
                   (left/Calendar.Minute())%60,
                   (left/Calendar.Second())%60,
                   );

// Bree came 3071 days, 0:49:36 after Nat

// the following is more accurate, taking into account that the days where
// daylight savings time is switched do not have 24, but 23 and 25 hours.
// thanks to mirar on the pike list for pointing this out and providing a
// correct solution.

array(int) breakdown_elapsed(object u, void|array on)
{
  array res=({});
  if (!on) on=({Day,Hour,Minute,Second});
  foreach (on;;program|TimeRange p)
  {
    if (u==u->end()) { res+=({0}); continue; }
    int x=u/p;
    u=u->add(x,p)->range(u->end());
    res+=({x});
  }
  return res;
}

write("Bree came %d days, %d:%d:%d after Nat\n",
      @breakdown_elapsed(difference));

// Bree came 3071 days, 0:49:36 after Nat
```

## Day in a Week/Month/Year or Week Number

```pike
mapping day=localtime(time());
day->mday;
// Result: 2
day->wday;
// Result: 4
day->yday;
// Result: 336

int year=1981;
int month=6;
int day=16;
object date;
date = Calendar.Day(year, month, day);
// Result: Day(Tue 16 Jun 1981)

date->week_day();
// Result: 3
date->week_no();
// Result: 24
date->year_day();
// Result: 167
write("%d/%d/%d was a %s\n", month, day, year, date->week_day_name());
// 6/16/1981 was a Tuesday

write("in the week number %d.\n", date->week_no());
// in the week number 25.
```

## Parsing Dates and Times from Strings

```pike
string date = "1998-06-03";
int yyyy;
int mm;
int dd;
[yyyy, mm, dd] = array_sscanf(date, "%d-%d-%d");

object day;
day=Calendar.dwim_day(date);
day=Calendar.parse("%Y-%M-%D", date);

day->unix_time();
// Result: 896824800
day->year_no();
// Result: 1998
day->month_no();
// Result: 6
day->month_day();
// Result: 3
```

## Printing a Date

```pike
object now=Calendar.dwim_time("Sun Sep 21 15:33:36 1997");
// Result: Second(Sun 21 Sep 1997 15:33:36 CEST)

now->format_ctime();
// Result: "Sun Sep 21 15:33:36 1997\n"

// there is no equivalent to scalar localtime

now = Calendar.Second(1973, 1, 18, 3, 45, 50);
write("strftime gives: %s %02d/%02d/%!2d\n", now->week_day_name(),
        now->month_no(), now->month_day(), now->year_no());
// strftime gives: Sunday 01/18/73
// pike doesn't have strftime, but hey.

// instead Calendar provides a large array of predefined formats:

// format_nice() and format_nicez() depend on the unit:
now->format_nice();           // "18 Jan 1973 3:45:50"
now->week()->format_nice();   // "w3 1973"
now->format_nicez();          // "18 Jan 1973 3:45:50 CET"
now->hour()->format_nicez();  // "18 Jan 1973 3:00 CET"

// others are unit independant.
now->format_ext_time();       // "Thursday, 18 January 1973 03:45:50"
now->format_ext_ymd();        // "Thursday, 18 January 1973"
now->format_iso_time();       // "1973-01-18 (Jan) -W03-4 (Thu) 03:45:50 UTC+1"
now->format_iso_ymd();        // "1973-01-18 (Jan) -W03-4 (Thu)"
now->format_mod();            // "03:45"
now->format_month();          // "1973-01"
now->format_month_short();    // "197301"
now->format_mtime();          // "1973-01-18 03:45"
now->format_time();           // "1973-01-18 03:45:50"
now->format_time_short();     // "19730118 03:45:50"
now->format_time_xshort();    // "730118 03:45:50"
now->format_tod();            // "03:45:50"
now->format_tod_short();      // "034550"
now->format_todz();           // "03:45:50 CET"
now->format_todz_iso();       // "03:45:50 UTC+1"
now->format_week();           // "1973-w3"
now->format_week_short();     // "1973w3"
now->format_iso_week();       // "1973-W03"
now->format_iso_week_short(); // "197303"
now->format_xtime();          // "1973-01-18 03:45:50.000000"
now->format_xtod();           // "03:45:50.000000"
now->format_ymd();            // "1973-01-18"
now->format_ymd_short();      // "19730118"
now->format_ymd_xshort();     // "730118"

now->format_ctime();          // "Thu Jan 18 03:45:50 1973\n"
now->format_smtp();           // "Thu, 18 Jan 1973 3:45:50 +0100"
now->format_http();           // "Thu, 18 Jan 1973 02:45:50 GMT"
```

## High-Resolution Timers

```pike
int t=time();                 // current time in unixtime seconds
float t0=time(t);             // higher precision time passed since t
float t1=time(t);
float elapsed=t1-t0;
// Result: 0.009453

//-------------------------------------------
write("Press return when ready: ");
array(int) before=System.gettimeofday();
Stdio.stdin->gets();
array(int) after=System.gettimeofday();
int elapsed_sec=after[0]-before[0];
int elapsed_usec=after[1]-before[1];
if(elapsed_usec<0)
{
  elapsed_sec--;
  elapsed_usec+=1000000;
}

write("You took %d.%d seconds.\n", elapsed_sec, elapsed_usec);
//-------------------------------------
// this is an expanded example compared to the one given for perl
// to allow comparison of different types.
// bignum are objects of the gmp library, which are seamlessly integrated with
// regular integers.

int main()
{
  // size values are adjusted so that each run takes about the same length.
  gaugethis(5000000, 100, lambda(){ return random(pow(2,31)-1); });
               // values to fit into a signed 32bit int.
  gaugethis(50000, 100, lambda(){ return pow(2,64)+random(pow(2,64)); });
               // make sure values are bignum even in case 64bit ints are used.
  gaugethis(500000, 100, lambda(){ return random_string(10); });
               // might be interresting to compare longer strings too.
}

void gaugethis(int size, int number_of_times, function rand)
{
  array gauged_times = ({});
  float average;

  int swidth=sizeof((string)size);
  int nwidth=sizeof((string)number_of_times);
  for(int i; i<number_of_times; i++)
  {
    write("%*d: ", nwidth, i);
    array(int) arr=({});
    write("creating array: ");
    for(int j; j<size; j++)
    {
      arr += ({ rand() });
    }
    write(" sorting: ");

    float gaugetime=gauge // gauge measures cpu time, giving better results
    {
      arr=sort(arr);
    };
    gauged_times += ({ gaugetime });
    write(" %f          \r", gaugetime);
  }
  average=`+(@gauged_times)/(float)number_of_times;
  gauged_times=sort(gauged_times);

  write("average: %O, min: %O, max: %O                           \n",
        average, gauged_times[0], gauged_times[-1]);
}
```

## Short Sleeps

```pike
int abort_on_signal=1;         // if true, aport on signal
sleep(0.25, abort_on_signal);

delay(0.25); // uses busy-wait for accuracy,
             // may be interrupted by signal handlers
```

## Program: hopdelta

```pike
Calendar.dwim_time("Tue, 26 May 1998 23:57:38 -0400")->distance(
    Calendar.dwim_time("Wed, 27 May 1998 05:04:03 +0100"))->format_elapsed();
// Result: "0:06:25"

// <font size="-1"><a href="../include/pike/ch03/hopdelta.html">download the following standalone program</a></font>
#!/usr/bin/pike
// chapter 3.11
// hopdelta - feed mail header, produce lines
//            showing delay at each hop.
int main()
{
  MIME.Message        mail = MIME.Message(Stdio.stdin.read());

  array           received = reverse(mail->headers->received/"\0");
  Calendar.Second lasttime = Calendar.dwim_time(mail->headers->date);

  array delays=({ ({ "Sender", "Recipient", "Time", "Delta" }) });
  delays+=({ ({ mail->headers->from,
                array_sscanf(received[0], "from %[^ ]")[0],
                mail->headers->date,
                ""
          }) });


  foreach(received;; string hop)
  {
    string fromby, date;
    [fromby, date] = hop/";";
    Calendar.Second thistime = Calendar.dwim_time(date);

    delays+= ({ array_sscanf(fromby, "from %[^ ]%*sby %[^ ]%*s") +
                ({ date, lasttime->distance(thistime)->format_elapsed() })
             });

    lasttime=thistime;
  }

  write("%{%-=22s %-=22s %-=20s %=10s\n%}\n", delays);
  return 0;
}
```