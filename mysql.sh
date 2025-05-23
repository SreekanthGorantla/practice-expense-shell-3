#!/bin/bash

USERID=$(id -u)

R="\e[31m"
G="\e[32m"
Y="\e[33m"
N="\e[0m"

VALIDATE(){
    if [ $1 -ne 0 ]
    then
        echo -e "$2 ... $R FAILURE $N"
        exit 1
    else
        echo -e "$2 ... $G SUCCESS $N"
    fi
}

CHECK_ROOT(){
    if [ $USERID -ne 0 ]
    then
        echo "Error:: You must have sudo access to execute this command!"
        exit 1
    fi
}

#########################################
# Main
#########################################
# Log file location

LOGS_FOLDER="/var/logs/expense-shell-3"
LOG_FILE=$(echo $0 | cut -d "." -f1)
TIMESTAMP=$(date +%Y-%m-%d-%H-%M-%S)
LOG_FILE_NAME="$LOGS_FOLDER/$LOG_FILE-$TIMESTAMP.log"

# Create log file directory if not exists
mkdir -p $LOGS_FOLDER
echo ===========================================

echo "Script started executing at: $TIMESTAMP" &>> $LOG_FILE_NAME

# Call CHECK_ROOT function
CHECK_ROOT
echo ===========================================

#########################################
# Install MySQL server
#########################################
dnf install mysql-server -y  &>> $LOG_FILE_NAME
VALIDATE $? "Installing MySQL server"
echo ===========================================

#########################################
# Enable mysqld
#########################################
systemctl enable mysqld  &>> $LOG_FILE_NAME
VALIDATE $? "Enabling mysqld"
echo ===========================================

#########################################
# Starting MYSQLD server
#########################################
systemctl start mysqld  &>> $LOG_FILE_NAME
VALIDATE $? "Start mysqld"
echo ===========================================

##################################################################################
# MySQL server root password setup
##################################################################################
mysql -h mysql.sreeaws.space -u root -pExpenseApp@1 -e 'show databases;' &>> $LOG_FILE_NAME 

if [ $? -ne 0 ]
then
    echo "MySQL Root password not setup" &>> $LOG_FILE_NAME
    mysql_secure_installation --set-root-pass ExpenseApp@1
    VALIDATE $? "Setting root password"
else
    echo -e "MySQL root password already setup ... $Y SKIPPING $N"
fi
echo ===========================================