#!/bin/bash

ROOTDN="cn= ,dc= ,dc= "
ROOTPW=' LDAP PASSWORD '
MAXPWDAGE=60
RESTOU=dummy
ADMINMAILID=" FROM MAIL ID"
ADMINID=" ADMINISTRATOR MAIL ID"
USRLST=/root/userlist.csv



echo "UserName;Email;Expire in / days" > $USRLST

usermail() {
MAILID=`ldapsearch -xw $ROOTPW -D $ROOTDN -b $i mail -LLL |grep -i ^mail|awk '{print $2}'`
 if [ -n "$MAILID" ]; then
 echo "$USERID;$MAILID;$EXP" >> $USRLST
 echo -e "Hi ${USERID^} \n\nYour LDAP password will get expired in $EXP days. Please reset the password ASAP. The password will be expire automatically in every 2 months. \n\nThanks!"|mailx -s "$SUB" -r $ADMINMAILID $MAILID
 fi
}

adminmail() {
echo -e "Hi \n\nPlease find the list of LDAP users whose password expiring within 10 days or less.\n\nThanks!."|mailx -a $USRLST -s "$SUB"  -r $ADMINMAILID $ADMINID
}

for i in `ldapsearch -xw $ROOTPW -D $ROOTDN -b dc= ,dc= -LLL "(&(userpassword=*)(pwdchangedtime=*)(!(ou:dn:=$RESTOU)))" dn|awk '{print $2}'`
do
 USERID=`echo $i|awk -F, '($1~uid){print $1}'|awk -F= '{print $2}'`
 PWCGE=`ldapsearch -xw $ROOTPW -D $ROOTDN -b $i -LLL pwdchangedtime|grep -i ^pwdchangedtime|awk '{print $2}'|sed 's/Z//'`
 EXDTE=`echo $PWCGE |cut -c 1-8`
 EXTME=`echo $PWCGE |cut -c 9- |sed 's/.\{2\}/&:/g' |cut -c -8`
 EXSEC=`date -d "$EXDTE $EXTME" +%s`
 CDSEC=`date +%s`
 DIFF=`expr \( $CDSEC / 86400 \) - \( $EXSEC / 86400 \)`
 EXP=`expr $MAXPWDAGE - $DIFF`
 if [ "$EXP" -le 10 ]; then
 	 if [ "$EXP" -ge 0 ]; then
 SUB="LDAP Password Expiry"
	usermail
fi
fi
 unset USERID PWCGE EXDTE EXTME EXSEC CDSEC DIFF i
done

adminmail
