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
# Install Nginx
#########################################
dnf install nginx -y  &>> $LOG_FILE_NAME
VALIDATE $? "Install Nginx"
echo ===========================================

#########################################
# Enable nginx
#########################################
systemctl enable nginx &>> $LOG_FILE_NAME
VALIDATE $? "Enable Nginx"
echo ===========================================

#########################################
# Start nginx
#########################################
systemctl start nginx &>> $LOG_FILE_NAME
VALIDATE $? "Start Nginx"
echo ===========================================

##################################################################################
# Remove the default content that web server is serving.
##################################################################################
rm -rf /usr/share/nginx/html/*  &>> $LOG_FILE_NAME
VALIDATE $? "Removing old content from HTML"
echo ===========================================

##################################################################################
# Download the frontend content
##################################################################################
curl -o /tmp/frontend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-frontend-v2.zip  &>> $LOG_FILE_NAME
VALIDATE $? "Download frontend content code"
echo ===========================================

#########################################
# Extract the frontend content.
#########################################
cd /usr/share/nginx/html  &>> $LOG_FILE_NAME
echo ===========================================

unzip /tmp/frontend.zip  &>> $LOG_FILE_NAME
VALIDATE $? "Unzipping frontend code"
echo ===========================================

#########################################################
# Create Nginx Reverse Proxy Configuration. Copy code
#########################################################
cp /home/ec2-user/practice-expense-shell-3/expense.conf /etc/nginx/default.d/expense.conf
VALIDATE $? "Copy expense config"
echo ===========================================

#########################################
# Restart nginx
#########################################
systemctl restart nginx  &>> $LOG_FILE_NAME
VALIDATE $? "Restart Nginx"
echo ===========================================