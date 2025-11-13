# 🗄️ Automated S3 Database Backup (Disaster Recovery)

A highly reusable, automated bash script designed for zero-touch Disaster Recovery. This script safely dumps a MySQL/MariaDB database, compresses it, securely uploads it to an Amazon S3 bucket, and automatically rotates out old backups to save costs.

---

## 🛑 The Problem

In a production environment, taking manual database backups is tedious, easily forgotten, and prone to human error. Furthermore, storing backups on the *same* server as the database is incredibly dangerous — if the server completely crashes or the hard drive gets corrupted, you lose both your live database **and** your backups simultaneously. 

## 💡 The Solution

This automation script establishes a hands-free **off-site Disaster Recovery** workflow.
By utilizing Linux `cron`, this script runs automatically every night while you sleep. It exports the data, compresses it to save bandwidth, forcefully pushes it out of the server infrastructure and into highly-durable AWS S3 storage, and aggressively cleans up both local systems and old S3 objects, resulting in peace of mind and minimal cloud costs.

---

## 🚀 How to Use (For Yourself or Your Company)

### Step 1: Prerequisites
You will need the following installed on your server:
1. `mysqldump` (comes with MySQL/MariaDB client tools)
2. `aws` (The AWS Command Line Interface)
3. An active Amazon S3 Bucket

### Step 2: Download the Script
```bash
# Clone the repository
git clone https://github.com/ajayautade/s3-db-backup-automation.git
cd s3-db-backup-automation

# Make the script executable
chmod +x db-backup-s3.sh
```

### Step 3: Configure AWS CLI & S3 Access
The script needs permission to write to your AWS S3 bucket.
```bash
aws configure
# Enter your AWS Access Key ID
# Enter your AWS Secret Access Key
# Enter your Region (e.g., ap-south-1)
```

### Step 4: Add Your Personal Configuration
Open the script using your favorite text editor (like `nano` or `vim`):
```bash
nano db-backup-s3.sh
```

Find the `CONFIGURATION` section at the top of the file and replace the `YOUR_...` placeholders with your actual details:
```bash
DB_USER="root"                           # ⚠️ Change this
DB_PASS="MySecurePass123"                # ⚠️ Change this
DB_NAME="production_db"                  # ⚠️ Change this
S3_BUCKET_NAME="my-company-backups-bucket" # ⚠️ Change this

RETENTION_DAYS=7                         # How many days of backups to keep
```

### Step 5: Test the Script Manually
Before automating it, ensure it works! Run it manually:
```bash
./db-backup-s3.sh
```
Check your AWS S3 Console — you should see a `.tar.gz` file sitting in your bucket!

---

## ⏰ Automating with Cron (The Magic!)

The true power of this script is running it automatically every single day. We use Linux `cron` for this.

1. Open the cron editor:
```bash
crontab -e
```

2. Add this line at the very bottom to run the script automatically **every day at 2:00 AM**:
*(Make sure to change the paths to wherever you downloaded the script)*
```text
0 2 * * * /bin/bash /path/to/s3-db-backup-automation/db-backup-s3.sh >> /var/log/db-backup.log 2>&1
```

**That's it!** You now have a fully functional, zero-touch Disaster Recovery strategy.

---

## 🛠️ Personalizing This Project For Your Resume

If you are using this code from my repository to show off your own skills in an interview or portfolio, I highly recommend making the following changes to demonstrate advanced knowledge:

1. **Environment Variables (.env):** Storing database passwords in plain text is a security risk. Modify the bash script to source a `.env` file containing the credentials instead of hardcoding them.
2. **Slack/Discord Notifications:** Add a Webhook `curl` command at the bottom of the script to send a message to a Slack channel saying *"✅ Database Backup Successful!"*.
3. **IAM Roles (Best Practice):** Instead of using `aws configure` (which uses permanent access keys), attach an **IAM EC2 Role** directly to your server with `s3:PutObject` permissions. This is far more secure.

---

## 📄 License

Open source — free to use, modify, and distribute.
