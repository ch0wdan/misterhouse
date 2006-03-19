# Category = Weather

#@ This script parses rain and snow info for the next week from the weather forecasts
#@ downloaded by internet_weather.pl (US only).  If precipitation is forecasted, it will be
#@ announced.  There is also some example code for skipping sprinkler cycles
#@ based on the forecast.
#@ The rain/snow forecast is updated when a new internet weather forecast is received.
#@ To modify when it is spoken (or disable it), go to the 
#@ <a href=/bin/triggers.pl> triggers page </a>
#@ and modify the 'read chance of rain' trigger.

# 12/07/2001 Created by David Norwood (dnorwood2@yahoo.com)
# 12/28/2005 added back the "announce forecast" feature and made it a trigger 


$weather_forecast = new File_Item "$config_parms{data_dir}/web/weather_forecast.txt";
set_watch $weather_forecast if $Reload;

$v_get_chance_of_rain = new Voice_Cmd 'Get the chance of rain or snow';
$v_get_chance_of_rain-> set_info('Gets chance of rain or snow from the Internet');


$v_chance_of_rain = new Voice_Cmd '[Read,Show] the forecasted chance of rain or snow';
$v_chance_of_rain-> set_info('Reports on chance of rain or snow from the Internet');
$v_chance_of_rain-> set_authority('anyone');

if ($state = said $v_chance_of_rain) {
	$Weather{chance_of_rain} = 'The weather forecast has not been received' unless $Weather{chance_of_rain};
	if ($state eq 'Read') {
		if ($Respond_Target eq 'time' or $Respond_Target eq 'unknown') {
			respond 'target=speak Notice: ' . $Weather{chance_of_rain} 
			  if $Weather{chance_of_rain} =~ /chance/;
		}
		else {
			respond 'target=speak ' . $Weather{chance_of_rain};
		}
	}
	else {		
		respond $Weather{chance_of_rain};	
	}
}

if (said $v_get_chance_of_rain or changed $weather_forecast) {
	set_watch $weather_forecast;

	my (%forecasts);
	my @days = ("Sunday", "Monday", "Tuesday", "Wednesday", "Thursday", "Friday", "Saturday");

	if ((stat($weather_forecast->name))[7] < 100) {
		$Weather{chance_of_rain} = 'Incomplete weather forecast received';
		return;
	}
	foreach my $key (keys %Weather) {
		undef $Weather{$key} if $key =~ /^chance of (rain|snow) /i;
	}
	undef $Weather{"Forecast Days"};

=begin comment

As of 9:10pm Mon Dec 12, 2005:
WARNING: Update
Tonight: Patchy low clouds and fog...Otherwise mostly clear. Lows in the
	40s. 
Tuesday: Mostly sunny except for patchy morning low clouds and fog. Highs
	in the 60s. 

=cut

	my $current_day;
	foreach my $line (read_all $weather_forecast) {
		next if $line =~ /^as of/i;
		next if $line =~ /^warning:/i;
		if (my ($day, $forecast) = $line =~ /^([\w ]+): (.+)/) {
			$forecasts{$day} = $forecast;
			$Weather{"Forecast Days"} .= $day . '|';
			$current_day = $day;
		}
		if (my ($forecast) = $line =~ /^\s*( \S.+)/) {
			$forecasts{$current_day} .= $forecast;
		}
		#print "$line\n";
		#print "$current_day : $forecasts{$current_day}\n";
	}
	$Weather{"Forecast Days"} =~ s/\|$//;
	my $text = '';
	my $days_to_read = 3;
	foreach my $day (split /\|/, $Weather{"Forecast Days"}) {
		my $chance = 0;
		$chance = 20 if $forecasts{$day} =~ 
		  /(slight|a) chance (of|for) *\S* *(rain|showers|snow|thunderstorms)/i;
		$chance = 60 if $forecasts{$day} =~ 
		  /(rain|showers|snow|thunderstorms) (becoming )?likely/i;
		$chance = $1 if $forecasts{$day} =~ 
		  /(\d+) percent chance (of|for) *\S* *(rain|showers|snow|thunderstorms)/i;
		$chance = $3 if $forecasts{$day} =~ 
		  /chance (of|for) *\S* *(rain|showers|snow|thunderstorms) (\d+) percent/i;
		$chance = $3 if $forecasts{$day} =~ 
		  /chance (of|for) *\S* *(rain|showers|snow|thunderstorms) increasing to (\d+) percent/i;
		#print "$day : $chance\n";
		$chance = 80 if $chance > 100;
		my $precip = ($forecasts{$day} =~ / snow/) ? 'snow' : 'rain';
		$Weather{"Chance of $precip $day"} = $chance;
		$Weather{"Forecast $day"} = $forecasts{$day};
		next unless $chance;
		last unless $days_to_read--;
		$text .= " a $chance percent chance of $precip $day,";
	}
	unless ($text) { 
		$Weather{chance_of_rain} = 'There is no rain or snow in the forecast.';
		return;
	}
	my $tomorrow = $days[($Wday + 1) % 7];
	$text =~ s/$tomorrow/tomorrow/g;
	$text = 'There is' . $text;
	$text =~ s/,$/./;
	$text =~ s/a 8/an 8/g;
	$text =~ s/,([^,]+)$/ and$1/;
	$Weather{chance_of_rain} = $text;
}


# lets allow the user to control via triggers

if ($Reload and $Run_Members{'trigger_code'}) { 
	eval qq(
		&trigger_set("time_cron '5 8,11,16,19 * * *'", 
		  "run_voice_cmd 'Read the forecasted chance of rain or snow'", 'NoExpire', 'read chance of rain') 
		  unless &trigger_get('read chance of rain');
	);
}

=begin comment

The following code is an example of using the rain forecast to skip sprinkler cycles before and after 
the rain.

if (time_cron "40 4,16 * * *") {
	foreach $day (split /\|/, $Weather{"Forecast Days"}) {
		$chance = $Weather{"Chance of Rain $day"};
		if ($chance > 50) {
			$Save{sprinkler_skip} = 3;
			last;
		}
	}
	return unless $Save{sprinkler_skip};
	if ($Save{sprinkler_skip} == 3) {
		speak "Rain forecasted, skipping sprinklers.";
	}
	else {
		speak "Skipping sprinklers due to recent rain.";
	}
	system 'nxacmd -v 2 -n 1';
}

$Save{sprinkler_skip}-- if $Save{sprinkler_skip} and $New_Day;

=cut