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
# Disable old nodejs
#########################################
dnf module disable nodejs -y &>> $LOG_FILE_NAME
VALIDATE $? "Disabling old Nodejs"
echo ===========================================

#########################################
# Enable latest nodejs
#########################################
dnf module enable nodejs:20 -y &>> $LOG_FILE_NAME
VALIDATE $? "Enabling latest Nodejs"
echo ===========================================

#########################################
# Install latest nodejs
#########################################
dnf install nodejs -y &>> $LOG_FILE_NAME
VALIDATE $? "Installing latest Nodejs"
echo ===========================================

#########################################
# Adding expense user
#########################################
id expense &>> $LOG_FILE_NAME
if [ $? -ne 0 ]
then
    useradd expense &>> $LOG_FILE_NAME
    VALIDATE $? "Adding Expense user"
else
    echo -e "Expense user already exists ... $Y SKIPPING $N"
fi
echo ===========================================

#########################################
# Creating app directory
#########################################
mkdir /app
VALIDATE $? "Creating app directory"
echo ===========================================

##################################################################################
# Download backend code
##################################################################################
curl -o /tmp/backend.zip https://expense-builds.s3.us-east-1.amazonaws.com/expense-backend-v2.zip  &>> $LOG_FILE_NAME
VALIDATE $? "Downloading Backend code"
echo ===========================================

#########################################
# Remove everything from /app dir
#########################################
cd /app
rm -rf /app/*
echo ===========================================

#########################################
# Unzip backend code
#########################################
unzip /tmp/backend.zip &>> $LOG_FILE_NAME
VALIDATE $? "Unzipping backend code"
echo ===========================================

#########################################
# Install npm dependencies 
#########################################
npm install &>> $LOG_FILE_NAME
VALIDATE $? "Install the dependencies"
echo ===========================================

################################################
# Copy backend.service to /etc/systemd/system
################################################
cp /home/ec2-user/practice-expense-shell-3/backend.service /etc/systemd/system/backend.service
VALIDATE $? "Copy backend.service"
echo ===========================================

#########################################
# Setting up mysql
#########################################
dnf install mysql -y  &>> $LOG_FILE_NAME
VALIDATE $? "Install MySQL"
echo ===========================================

mysql -h mysql.sreeaws.space -uroot -pExpenseApp@1 < /app/schema/backend.sql &>> $LOG_FILE_NAME
VALIDATE $? "Setting up transactions chema"
echo ===========================================

systemctl daemon-reload  &>> $LOG_FILE_NAME
VALIDATE $? "Deamon Reload"
echo ===========================================

systemctl enable backend  &>> $LOG_FILE_NAME
VALIDATE $? "Enable Backend"
echo ===========================================

systemctl restart backend  &>> $LOG_FILE_NAME
VALIDATE $? "Restart Backend"
echo ===========================================