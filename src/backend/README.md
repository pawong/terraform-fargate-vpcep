# GoLang Example

### Run locally

```bash
% cd api
% go run .
```

### Build and push to AWS ECR

```bash
% aws ecr get-login-password --region us-west-2 --profile <profile_name> | docker login --username AWS --password-stdin <acount_id>.dkr.ecr.us-west-2.amazonaws.com
% docker build --build-arg GIT_COMMIT_HASH=$(git rev-parse --short HEAD) -t terraform-fargate-vpcep .
% docker tag terraform-fargate-vpcep:latest <acount_id>.dkr.ecr.us-east-1.amazonaws.com/terraform-fargate-vpcep:latest
```
