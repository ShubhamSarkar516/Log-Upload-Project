# 📦 Log File Auto Upload to S3 via Jenkins

This project automates the monitoring of a log file. If its size exceeds **1GB**, it triggers a Jenkins pipeline to upload the file to **AWS S3** and then clears the log.

---

## 🧰 Tools Used

- **Jenkins** (Pipeline + Credential Plugin)
- **AWS CLI**
- **Bash Scripting**
- **Crontab** (for scheduling checks)

---

## 📁 Project Structure

```
log-upload-project/
├── monitor_log_size.sh         # Shell script to monitor and trigger Jenkins
├── README.md                   # Project documentation
├── .gitignore                  # Files to ignore in git
└── aws/                        # Optional: AWS CLI setup files
```

---

## 🔧 Setup Instructions

### 1️⃣ Install Tools

```bash
sudo apt update
sudo apt install default-jre unzip curl -y
curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
unzip awscliv2.zip
sudo ./aws/install
```

Install Jenkins and start it:

```bash
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install jenkins -y
sudo systemctl enable jenkins
sudo systemctl start jenkins
```

➡️ Open Jenkins UI at `http://localhost:8080`

---

### 2️⃣ Install Plugin

- ✅ Install **AWS Credentials Plugin** in Jenkins

---

### 3️⃣ Create Jenkins Credentials

Go to: `Manage Jenkins → Credentials → Global → Add Credentials`

- Kind: AWS Credentials
- ID: `aws-creds`
- Access Key ID & Secret Access Key: *(from your AWS IAM)*

---

### 4️⃣ Create Jenkins Pipeline Job

- Name: `log-file-upload-job`
- Type: Pipeline

Paste this in Pipeline Script:

```groovy
pipeline {
  agent any

  environment {
    LOG_FILE = "/tmp/test.log"
    S3_BUCKET = "log-bucket-for-backup"
    AWS_REGION = "ap-south-1"
    TIMESTAMP = "${new Date().format('yyyyMMdd-HHmmss')}"
  }

  stages {
    stage('Upload to S3') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          sh '''
            echo "Uploading $LOG_FILE to S3..."
            aws s3 cp $LOG_FILE s3://$S3_BUCKET/${TIMESTAMP}_test.log --region $AWS_REGION
          '''
        }
      }
    }

    stage('Verify Upload') {
      steps {
        withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', credentialsId: 'aws-creds']]) {
          sh '''
            echo "Verifying uploaded log in S3..."
            aws s3 ls s3://$S3_BUCKET/${TIMESTAMP}_test.log --region $AWS_REGION || exit 1
          '''
        }
      }
    }

    stage('Clear Log File') {
      steps {
        echo "Clearing the original log file..."
        sh 'truncate -s 0 $LOG_FILE'
      }
    }
  }

  post {
    success {
      echo " Pipeline completed successfully"
    }
    failure {
      echo " Pipeline failed"
    }
  }
}
```

---

### 5️⃣ Create `monitor_log_size.sh` Script

```bash
#!/bin/bash

LOG_FILE="/tmp/test.log"
MAX_SIZE_MB=1024
JENKINS_URL="http://localhost:8080"
JENKINS_JOB="log-file-upload-job"
JENKINS_USER="admin"
JENKINS_API_TOKEN="your-token-here"

SIZE_MB=$(du -m "$LOG_FILE" | cut -f1)

if [ "$SIZE_MB" -ge "$MAX_SIZE_MB" ]; then
  echo "$(date) - Triggering Jenkins job. File size: $SIZE_MB MB"
  curl -X POST "$JENKINS_URL/job/$JENKINS_JOB/build"     --user "$JENKINS_USER:$JENKINS_API_TOKEN"
else
  echo "$(date) - Size ok: $SIZE_MB MB. No action."
fi
```

Make it executable:

```bash
chmod +x monitor_log_size.sh
```

---

### 6️⃣ Setup Cron Job

Edit cron:

```bash
crontab -e
```

Add:

```bash
*/5 * * * * /home/ubuntu/log-upload-project/monitor_log_size.sh >> /var/log/monitor_log_size.log 2>&1
```

---

### ✅ Test by Creating a Dummy 2GB Log File

```bash
fallocate -l 2G /tmp/test.log
```

This will trigger the job on next cron run if the log file is larger than 1GB.

---

## 📌 Notes

- Make sure Jenkins is running and reachable at the URL you provide in the script.
- Replace credentials and URLs with real values.
- Ensure the AWS CLI is configured and working inside Jenkins pipeline.
- Adjust permissions if `jenkins` user can’t access required files.

---

## 📂 GitHub Setup

To push this project:

```bash
git init
git add .
git commit -m "Initial commit"
git remote add origin https://github.com/your-username/log-upload-project.git
git push -u origin main
```

---

## 📬 Author

**Shubham Sarkar**  
DevOps Engineer | GitHub: [ShubhamSarkar516](https://github.com/ShubhamSarkar516)

---

MIT License
