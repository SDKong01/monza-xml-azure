# VPC Ports & Security Group Configuration
## ETL Infrastructure Network Requirements

**Last Updated**: 2025-08-26  
**Environment**: Kimball Delta ETL Development Server  
**Server IP**: 3.144.122.44 (kimball-delta-dev workspace)  
**VPC**: `kimball-delta-dev-development-vpc`  
**Region**: us-east-2

---

## 🔓 **Required Ports for ETL Infrastructure**

### **🌐 External Access Ports (Public)**
These ports need to be accessible from the internet for external connections:

| Port | Service | Purpose | Access Level | Status |
|------|---------|---------|--------------|---------|
| **22** | SSH | Secure shell access | **PUBLIC** | ✅ Open |
| **80** | HTTP | Web redirect to HTTPS | **PUBLIC** | ✅ Open |
| **443** | HTTPS | Main web interface | **PUBLIC** | ✅ Open |
| **3306** | MySQL | Database access (DBeaver) | **PUBLIC** | ✅ Open |
| **8088** | Airflow | Workflow management interface | **PUBLIC** | ✅ Open |
| **9000** | MinIO API | S3-compatible object storage API | **PUBLIC** | ✅ Open |
| **9001** | MinIO Console | Web management interface | **PUBLIC** | ✅ Open |
| **9083** | Hive Metastore | Metadata service (DBeaver) | **PUBLIC** | ✅ Open |
| **10000** | HiveServer2 | SQL query service (DBeaver) | **PUBLIC** | ✅ Open |

### **🔒 Internal Access Ports (VPC Only)**
These ports are for internal cluster communication:

| Port | Service | Purpose | Access Level | Status |
|------|---------|---------|--------------|---------|
| **6379** | Redis | Airflow Celery broker | **VPC INTERNAL** | ✅ Open |
| **7077** | Spark Master | Spark cluster coordination | **VPC INTERNAL** | ✅ Open |
| **8080** | Spark Master UI | Spark cluster monitoring | **VPC INTERNAL** | ✅ Open |
| **8081** | Spark Worker UI | Spark worker monitoring | **VPC INTERNAL** | ✅ Open |
| **40000-50000** | Spark Executors | Dynamic executor ports | **VPC INTERNAL** | ✅ Open |

---

## 📋 **Security Group Configuration**

### **Security Group Details**
- **Name**: `kimball-delta-dev-development-sg`
- **Description**: Security group for ETL development server
- **VPC**: `kimball-delta-dev-development-vpc`
- **Region**: us-east-2

### **Inbound Rules (Ingress)**

#### **External Access Rules**
```hcl
# SSH Access
ingress {
  description = "SSH"
  from_port   = 22
  to_port     = 22
  protocol    = "tcp"
  cidr_blocks = var.allowed_client_cidrs
}

# HTTP/HTTPS
ingress {
  description = "HTTP/HTTPS"
  from_port   = 80
  to_port     = 443
  protocol    = "tcp"
  cidr_blocks = var.allowed_client_cidrs
}

# MySQL Database
ingress {
  description = "MySQL"
  from_port   = 3306
  to_port     = 3306
  protocol    = "tcp"
  cidr_blocks = var.allowed_client_cidrs
}

# Airflow Web Interface
ingress {
  description = "Airflow Web"
  from_port   = 8088
  to_port     = 8088
  protocol    = "tcp"
  cidr_blocks = var.allowed_client_cidrs
}

# MinIO Object Storage
ingress {
  description = "MinIO API"
  from_port   = 9000
  to_port     = 9000
  protocol    = "tcp"
  cidr_blocks = var.allowed_client_cidrs
}

ingress {
  description = "MinIO Console"
  from_port   = 9001
  to_port     = 9001
  protocol    = "tcp"
  cidr_blocks = var.allowed_client_cidrs
}

# Hive Services
ingress {
  description = "Hive Metastore"
  from_port   = 9083
  to_port     = 9083
  protocol    = "tcp"
  cidr_blocks = var.allowed_client_cidrs
}

ingress {
  description = "HiveServer2"
  from_port   = 10000
  to_port     = 10000
  protocol    = "tcp"
  cidr_blocks = var.allowed_client_cidrs
}
```

#### **Internal Access Rules**
```hcl
# Spark Cluster (Internal)
ingress {
  description = "Spark Master"
  from_port   = 7077
  to_port     = 7077
  protocol    = "tcp"
  cidr_blocks = [local.vpc_cidr]  # VPC internal only
}

ingress {
  description = "Spark Master UI"
  from_port   = 8080
  to_port     = 8080
  protocol    = "tcp"
  cidr_blocks = [local.vpc_cidr]  # VPC internal only
}

ingress {
  description = "Spark Worker UI"
  from_port   = 8081
  to_port     = 8081
  protocol    = "tcp"
  cidr_blocks = [local.vpc_cidr]  # VPC internal only
}

# Redis (Internal)
ingress {
  description = "Redis"
  from_port   = 6379
  to_port     = 6379
  protocol    = "tcp"
  cidr_blocks = [local.vpc_cidr]  # VPC internal only
}

# Spark Executors (Dynamic range)
ingress {
  description = "Spark Executors"
  from_port   = 40000
  to_port     = 50000
  protocol    = "tcp"
  cidr_blocks = [local.vpc_cidr]  # VPC internal only
}
```

### **Outbound Rules (Egress)**
```hcl
# Allow all outbound traffic
egress {
  from_port   = 0
  to_port     = 0
  protocol    = "-1"
  cidr_blocks = ["0.0.0.0/0"]
}
```

---

## 🔐 **Access Control Variables**

### **Client IP Ranges**
```hcl
variable "allowed_client_cidrs" {
  description = "CIDR blocks allowed to access ETL services"
  type        = list(string)
  default     = [
    "0.0.0.0/0",  # WARNING: Allows all IPs - restrict for production
    # "YOUR_OFFICE_IP/32",  # Restrict to specific IPs in production
    # "YOUR_VPN_RANGE/24"   # Restrict to VPN range in production
  ]
}
```

### **VPC Configuration**
```hcl
locals {
  vpc_cidr = "10.0.0.0/16"
  name_prefix = "kimball-delta-dev"
}

# VPC
resource "aws_vpc" "main" {
  cidr_block           = local.vpc_cidr
  enable_dns_hostnames = true
  enable_dns_support   = true

  tags = {
    Name = "${local.name_prefix}-development-vpc"
  }
}

# Public Subnet
resource "aws_subnet" "public" {
  vpc_id                  = aws_vpc.main.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-2a"
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-development-public-subnet"
  }
}
```

---

## ⚠️ **Security Considerations**

### **Production Hardening**
1. **Restrict External Access**: Limit `allowed_client_cidrs` to specific IP ranges
2. **VPN Access**: Consider using VPN for secure access to internal ports
3. **Network ACLs**: Add additional network-level access controls
4. **Monitoring**: Enable VPC Flow Logs for traffic monitoring
5. **Logging**: Enable CloudTrail for API call logging

### **Current Configuration**
- **Development Mode**: Most ports are publicly accessible for testing
- **Production Mode**: Should restrict access to authorized IP ranges only
- **Access Level**: Currently allows all IPs (0.0.0.0/0) for development

### **Recommended Production Settings**
```hcl
variable "allowed_client_cidrs" {
  description = "CIDR blocks allowed to access ETL services"
  type        = list(string)
  default     = [
    "YOUR_OFFICE_IP/32",      # Specific office IP
    "YOUR_VPN_RANGE/24",      # VPN range
    "YOUR_CLOUD_IP/32",       # Cloud development environment
    # Remove "0.0.0.0/0" for production
  ]
}
```

---

## 🧪 **Testing Port Access**

### **Port Verification Commands**
```bash
# Check if ports are listening
sudo netstat -tulpn | grep -E ':(22|80|443|3306|8088|9000|9001|9083|10000)'

# Test external connectivity (from your machine)
telnet 3.144.122.44 3306    # MySQL
telnet 3.144.122.44 8088    # Airflow
telnet 3.144.122.44 9001    # MinIO Console
telnet 3.144.122.44 9083    # Hive Metastore
telnet 3.144.122.44 10000   # HiveServer2

# Test internal ports (from server)
telnet localhost 6379        # Redis
telnet localhost 7077        # Spark Master
telnet localhost 8080        # Spark Master UI
telnet localhost 8081        # Spark Worker UI
```

### **Service Status Check**
```bash
# Check all services
sudo systemctl status mysql redis-server minio hive-metastore hive-server2 spark-master spark-worker airflow-webserver airflow-scheduler

# Check specific ports
sudo ss -tulpn | grep -E ':(3306|6379|7077|8080|8081|8088|9000|9001|9083|10000)'
```

---

## 📊 **Current Status Summary**

### **✅ All Required Ports Open**
- **External Services**: 9 ports accessible from internet
- **Internal Services**: 5 port ranges accessible within VPC
- **Security Group**: Properly configured with all necessary rules
- **VPC Configuration**: Correctly set up with public/private subnets

### **🔧 Services Using These Ports**
- **SSH**: Secure server access
- **Web Services**: Airflow, MinIO, Hive interfaces
- **Database**: MySQL for metadata storage
- **Data Processing**: Spark cluster management
- **Object Storage**: MinIO S3-compatible API
- **Data Warehouse**: Hive metastore and server
- **Message Broker**: Redis for Airflow tasks

### **🚀 Ready for Use**
The current configuration allows:
- **External Access**: Web interfaces, database connections, file transfers
- **Internal Communication**: Spark cluster, Redis broker, service coordination
- **Development Workflow**: Full ETL pipeline execution
- **Monitoring**: Service health checks and debugging

---

## 📝 **Documentation References**

- **Main Project**: [README.md](README.md)
- **Installation Guide**: [INSTALL.md](INSTALL.md)
- **ETL Guide**: [KAINAM_ETL_GUIDE.md](KAINAM_ETL_GUIDE.md)
- **Version Specs**: [VERSION_SPECIFICATION.md](VERSION_SPECIFICATION.md)
- **Deployment History**: [re-install 08092025.md](re-install%2008092025.md)

---

**Note**: This configuration is optimized for development and testing. For production use, restrict external access to authorized IP ranges only and implement additional security measures.
