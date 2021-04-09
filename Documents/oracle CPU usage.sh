#This script will check the top oracle process which consume high CPU from OS and map the OSPID to database spid 
_check_high_CPU(){


CPU_LOG=/tmp/CPU.f
CPU_LEVEL=15.0
CPU_FACTOR=ps -eo pcpu,pid,user,etime|grep 'oracle'|sort -nr|head -1|awk '{print $1,$2,$3}'
#echo $CPU_FACTOR > /tmp/TOP_CPU_PROCESS.f
if [ echo "$CPU_FACTOR"|head -1|awk '{print $1}' > $CPU_LEVEL ];then echo "HIGH CPU";fi
SPID=echo "$CPU_FACTOR"|awk '{print $2}'
echo "$SPID"
$ORACLE_HOME/bin/sqlplus -S "/ as sysdba" << EOF > $CPU_LOG
DEFINE SPID='$SPID'
set lines 200
set pages 1000
set echo on
column SPID format a20
column USERNAME format a20
column PROGRAM format a20
column SQL_ID format a20
SELECT se.inst_id,
       se.sid,
       se.serial#,
       se.sql_id,
       pr.spid,
       se.username,
       se.program
FROM   gv\$session se
       INNER JOIN gv\$process pr ON pr.addr = se.paddr AND pr.inst_id = se.inst_id
WHERE  p.spid='${SPID}' 
order by se.sid;
EOF
exit;


grep "sid" $CPU_LOG
if [ $? -eq 0 ];then
mailx -s "`$ORACLE_SID`:HIGH CPU USAGE" youremail.gmail.com
fi

}
_check_high_CPU