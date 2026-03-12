# wakeboarduk-helm

Wakeboard UK Helm Chart

# Create the ghcr-login-secret to enable ArgoCD auth with Github Packages

Update the token in github when required. 

Then run:

```bash
./update-ghcr-secrets.sh NEWTOKENHERE
```