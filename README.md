
---

# Triforge
> Multi-tool IaC pipeline deploying an English to Spanish translation AI inference endpoint on AWS using Pulumi, Terraform, and OpenTofu across isolated infrastructure layers.

## Architecture
```
Pulumi (Python)     → SageMaker endpoint + IAM + Secrets Manager
Terraform (HCL)     → EC2 instance + Security Groups
OpenTofu (HCL)      → S3 remote state backend
Flask (Python)      → Proxy server bridging UI ↔ SageMaker
```

**State backend:** S3 (`remote-state-h1`)  
**Config passing:** AWS Secrets Manager → Flask → UI  
**Model:** [`Helsinki-NLP/opus-mt-en-es`](https://huggingface.co/Helsinki-NLP/opus-mt-en-es) via HuggingFace inference container

## Why 3 Tools?
Each tool owns a layer that suits its philosophy:
- **Pulumi** — Python flexibility for SageMaker's complex conditional resources
- **Terraform** — battle-tested HCL for standard compute provisioning
- **OpenTofu** — FOSS Terraform fork managing shared state infrastructure (i honestly just wanted to try it out as it looked kinda cool)

## Structure
```
triforge/
├── sagemkaer/        # Pulumi — SageMaker + Secrets
├── compute/          # Terraform — EC2
├── storage/          # OpenTofu — S3
└── ui/
    ├── proxy/        # Flask proxy app
    └── public/       # HTML/CSS/JS frontend
```

## Prerequisites
- AWS CLI configured
- Pulumi CLI, Terraform, OpenTofu installed
- Python 3.10+, pip

## Deploy
```bash
# 1. Storage (OpenTofu)
cd storage && tofu init && tofu apply

# 2. SageMaker (Pulumi)
cd sagemkaer && pulumi up

# 3. Compute (Terraform)
cd compute && tf init && tf apply

# 4. UI runs via CI/CD on push to main
```

## Links
*Blog @ [Triforge](https://dub.sh/triforge)* 

*Github @ [Triforge-Code](https://git.new/triforge)*  

*Live @ [Triforge-chat](https://chat.elijahu.me)*

---
