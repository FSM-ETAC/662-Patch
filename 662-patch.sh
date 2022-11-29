#!/bin/bash

if [ $PWD != "/tmp" ] ; then
  echo "extract patch into /tmp"
  exit 1
fi

if [ ! -f "./ETACRuleworkerPatch.zip" ] ; then 
  echo "Need to have Patch file ETACRuleworkerPatch.zip in current directory : $PWD" 
fi

if [ `md5sum /tmp/ETACRuleworkerPatch.zip | awk '{print $1}'` != "57411be38d764d85708abcc3d75bdbc7" ] ; then
  echo "/tmp/ETACRuleworkerPatch.zip  md5sum does not match ; retry Download else work with FortiSIEM Support "
  exit 1
fi

  unzip ./ETACRuleworkerPatch.zip


MD5SUM_FILE="/tmp/md5sums"

## md5sum Checks:


## Create md5sum file : 
echo "7e3d0769af8ba4e997055d29ffb09170  redis.js" >  $MD5SUM_FILE
echo "590d7eba055c785e6ad3b5b2cd971460  get.js" >> $MD5SUM_FILE
echo "116ded54f3b05a40d900764f08f32e05  named-value.js" >>  $MD5SUM_FILE
echo "8191a4f78bf8baa0dd2efc70acc61584  libphUtils.so" >>  $MD5SUM_FILE

echo "Verifying md5 Checksums for critical patch files: "
md5sum -c $MD5SUM_FILE

if [ $? -ne 0 ] ; then 
  echo "md5sum does not match Patch for one or more critical files"
  exit 1
fi


## Backup redis javascripts and libphUtils.so
if [ -f /opt/node-rest-service/models/redis/redis.js.old ] ; then
   mv /opt/node-rest-service/models/redis/redis.js.old /opt/node-rest-service/models/redis/redis.js.old-
fi

if [ -f /opt/node-rest-service/web/router/api/named-value/get.js.old ] ; then 
   mv /opt/node-rest-service/web/router/api/named-value/get.js.old /opt/node-rest-service/web/router/api/named-value/get.js.old-
fi 

if [ -f /opt/node-rest-service/web/router/api/named-value/named-value.js.old ] ; then 
   mv /opt/node-rest-service/web/router/api/named-value/named-value.js.old /opt/node-rest-service/web/router/api/named-value/named-value.js.old-
fi 

if [ -f /opt/phoenix/lib64/libphUtils.so.old ] ; then 
   mv /opt/phoenix/lib64/libphUtils.so.old /opt/phoenix/lib64/libphUtils.so.old-
fi

cd /tmp
cp /opt/node-rest-service/models/redis/redis.js /opt/node-rest-service/models/redis/redis.js.old
cp /opt/node-rest-service/web/router/api/named-value/get.js /opt/node-rest-service/web/router/api/named-value/get.js.old
cp /opt/node-rest-service/web/router/api/named-value/named-value.js /opt/node-rest-service/web/router/api/named-value/named-value.js.old
cp /opt/phoenix/lib64/libphUtils.so /opt/phoenix/lib64/libphUtils.so.old

## Patch redis.js:
mv /tmp/redis.js /opt/node-rest-service/models/redis/redis.js
chmod a+x /opt/node-rest-service/models/redis/redis.js
chown admin.admin /opt/node-rest-service/models/redis/redis.js

## Patch get.js:
mv /tmp/get.js /opt/node-rest-service/web/router/api/named-value/get.js
chmod a+x /opt/node-rest-service/web/router/api/named-value/get.js
chown admin.admin /opt/node-rest-service/web/router/api/named-value/get.js

## patch named-value.js:
mv /tmp/named-value.js /opt/node-rest-service/web/router/api/named-value/named-value.js
chmod a+x /opt/node-rest-service/web/router/api/named-value/named-value.js
chown admin.admin /opt/node-rest-service/web/router/api/named-value/named-value.js

## patch libphUtils.so
mv /tmp/libphUtils.so /opt/phoenix/lib64/libphUtils.so
chmod a+x /opt/phoenix/lib64/libphUtils.so
chown admin.admin /opt/phoenix/lib64/libphUtils.so


## Restart redis:
/opt/phoenix/redis/bin/redis_ops.sh stop
killall -9 redis-server

## Restart RuleWorker on all nodes:
# su -c "phtools --start phRuleWorker" admin

killall -9 phRuleWorker

## Ensure modified services start
# /opt/phoenix/phscripts/bin/phxctl start
/opt/phoenix/phscripts/bin/phxctl start

