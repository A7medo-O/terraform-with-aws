# 🚀 Terraform AWS Adventure: EC2, RDS & RabbitMQ

Hey there! Welcome to my **Terraform AWS playground** 😎
This project spins up a mini AWS ecosystem with:

* 🖥️ **EC2 Instance** – ready to rock with Java & Tomcat
* 🗄️ **RDS MySQL** – your database buddy
* 🐰 **RabbitMQ Broker** – messaging made easy
* 🌐 **VPC & Public Subnets** – networking vibes

Everything is automated, and your EC2 comes **preloaded with my setup script** (`setup.sh`) 💥

---

## 🔧 Requirements

* Terraform >= 1.5
* AWS CLI with credentials configured
* Your SSH key (`.pem`) – you’ll need it to jump into the EC2

---

## 📂 Files

* `ahmed.tf` – the Terraform magic 🪄
* `setup.sh` – the provisioning wizard 🧙‍♂️
* `terraform.tfstate` / `terraform.tfstate.backup` – Terraform memory (don’t commit!)
* `.gitignore` – keeps the mess away 😅

---

## ⚡ Quick Start

1. **Initialize Terraform**

```bash
terraform init
```

2. **See what’s coming**

```bash
terraform plan
```

3. **Launch everything** 🚀

```bash
terraform apply
```

Sit back ☕, Terraform will:

* Create VPC, subnets, IGW, and routes
* Launch EC2 and run `setup.sh` automatically
* Spin up RDS MySQL
* Deploy RabbitMQ broker

---

## 🖥️ Access Your EC2

```bash
ssh -i /path/to/project.pem ubuntu@<EC2_PUBLIC_IP>
```

## 🗄️ Access Your RDS

```bash
mysql -h <RDS_ENDPOINT> -u admin -p
```

---

## 📦 About `setup.sh`

* Installs **Java 17**, **Maven**, **Tomcat**
* Clones and builds a sample backend app from GitHub
* Deploys `.war` to Tomcat automatically
* Makes your EC2 a tiny app server ready to go

💡 Tip: If provisioners fail, try destroying the EC2 and let Terraform recreate it.

---

## 🤓 Author

* Ahmed O_O – the wizard behind the magic ✨

---

## 📝 License

Just for fun & learning. Use it wisely 😇

---

🎉 That’s it! Your AWS playground is now live – enjoy! 🚀
