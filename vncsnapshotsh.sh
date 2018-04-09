#!/bin/bash

pass[1]="password1"
pass[2]="password2"
pass[3]="password3"
dst="/tmp/snapshots/"`date +%d`
network="192.168"
currenthour=`date +%H`
COMPSTART="1"


function createpass {
  vncpasswd_spawn=`echo "set timeout -1; spawn vncpasswd "``echo "/tmp/pass$I"`
  vncpasswd_expect=' ;expect "Password:"; send "'${pass[$I]}'\r"; expect "Verify:";send "'${pass[$I]}'\r";expect eof'
  echo "$vncpasswd_spawn $vncpasswd_expect" | /usr/bin/expect --
}

function check_dst {
  if [ ! -e $dst ]
  then
    dst_dir_list=`echo $dst | sed -e 's/\//\ /g'`
    path2check=""
    for DIR in $dst_dir_list; do
      path2check=$path2check/$DIR
#      echo $path2check
      if [ ! -e $path2check ]; then
        mkdir $path2check
#        echo "Directory $path2check was created"
      fi
    done
  fi
}

function snapshot {
  for PASS in 1 2 3
  do
    imagename=`echo "$dst/$ip.$currenthour.jpeg"`
    vncsnapshot_spawn=`echo "set timeout -1; spawn vncsnapshot $ip "``echo $imagename`
    vncsnapshot_expect=' ;expect "Password:"; send "'${pass[$PASS]}'\r";expect eof'
#    echo "$vncsnapshot_spawn $vncsnapshot_expect" | /usr/bin/expect --
#    echo "?= $?"
  done
  timestamp=`/bin/date +%Y%m%d-%T`
  convert $imagename -font /usr/share/fonts/truetype/msttcorefonts/Arial.ttf -pointsize 70 -draw "gravity north fill white  text 1,11 '$timestamp'" $imagename
  convert $imagename -font /usr/share/fonts/truetype/msttcorefonts/Arial_Bold.ttf -pointsize 50 -draw "gravity south fill red text 1,11 '$ip'" $imagename
}

function networks {
  for NET in 20 21 22 23; do
    echo $NET
    check_dst
    COMP=$COMPSTART
    while [ $COMP -lt 170 ]; do
      ip=`echo "$network.$NET.$COMP"`
#      echo $ip
      pingresult=`ping -c1 $ip | grep "bytes from"`
      if [ `echo $pingresult | wc -m` -gt 1 ]; then snapshot; fi
      COMP=$(( COMP + 1 ))
    done
  done
}

networks

if [ $currenthour -eq 23 ]; then
  cd $dst; mencoder mf://*.jpeg -mf w=1280:h=1024:fps=0.5:type=jpg -ovc lavc -lavcopts vcodec=mpeg4:mbd=2:trell -oac copy -o output.avi
fi

#echo "sovnc "`date +%T`