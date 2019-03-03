#!/bin/bash
#set -x

#############################################################
# Install in cron like so
# */5 * * * * ~/bin/intelli_runner.sh
#############################################################



block=$(dash-cli getblockcount)||{ echo "dashd error getting block height.";exit 2;}
remainder=$((($block-880648+1662) % 16616))
run_prog=~/bin/vote_tracker.sh
test -x "$run_prog"||{ echo "Cannot execute $run_prog";exit 3;}
cd

# We want to run mnowatch just after the voting has closed.
if [ $remainder -le 10 ];then
	# Spin lock until any running instances of $run_prog are terminated
	num_instances_prog=1
	until [ $num_instances_prog -eq 0 ];do
		procs=$(ps aux)
		num_instances_prog=$(echo "$procs"|grep "$run_prog"|wc -l)
		sleep 3
	done
	"$run_prog"
	exit 0
fi


# We want to run mnowatch at regular intervals the day before voting closes to catch last minute vote changes.
# DASH block time is 2.625 mins on average, 60*24 mins in a day, 16616 blocks between cycles.
# Thus, 16616 - (24*60/2.625) = 16068.  We run more often if the remainder is larger than this number.

procs=$(ps aux)
num_instances_this=$(echo "$procs"|grep "$0"|wc -l)
num_instances_prog=$(echo "$procs"|grep "$run_prog"|wc -l)

if [ $num_instances_this -le 1 -a $num_instances_prog -eq 0 ];then
	# Run every 20 mins if <4 hours to go til the end of voting.
	if [ $remainder -ge 16524 ];then
		"$run_prog"
		sleep 1200
		exit
	# Run every hour if <1.5 days to go til the end of voting.
	elif [ $remainder -ge 15800 ];then
		"$run_prog"
		sleep 3600
		exit
	# Run every day if <20 days to go til the end of voting.
	elif [ $remainder -ge 5644 ];then
		"$run_prog"
		sleep 86400
		exit
	fi
fi

