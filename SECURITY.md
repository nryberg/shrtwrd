# Security Guidelines

This document outlines security best practices for the shrtwrd multi-service platform to protect sensitive information and maintain secure deployments.

## 🔒 Sensitive Information Protection

### What Information to Protect

The following information should **NEVER** be committed to version control:

- **Server IP addresses** (DigitalOcean droplet IPs)
- **Email addresses** (Let's Encrypt registration emails)
- **Domain names** (if you want to keep them private)
- **SSH keys** (private keys, key pairs)
- **API keys and tokens**
- **Database credentials**
- **SSL certificates** (private keys)
- **Environment-specific configurations**

### Environment Variables System

This project uses a template-based environment system:

1. **`.env.template`** - Safe template file (committed to git)
2. **`.env`** - Your actual configuration (excluded from git)
3. **`setup.sh`** - Interactive setup script to create your `.env`

### Quick Setup

```bash
# 1. Run the setup script
./setup.sh

# 2. This creates your .env file with your actual values
# 3. Deploy safely using environment variables
./deploy-multi.sh
```

## 🛡️ File Protection Strategy

### Protected Files

These files are automatically excluded from git via `.gitignore`:

```
.env                    # Your actual environment variables
.env.local             # Local environment overrides  
.env.production        # Production environment vars
*.tar.gz               # Deployment packages
*.pem                  # SSL certificates
*.key                  # Private keys
id_rsa*                # SSH keys
*.log                  # Log files
logs/                  # Log directories
*.bak                  # Backup files
```

### Safe Template Files

These template files ARE committed and are safe:

```
.env.template          # Environment variable template
Caddyfile.template     # Caddy configuration template
deploy-multi.template.sh # Deployment script template
setup.sh               # Interactive setup script
```

## 🔑 SSH Key Management

### Best Practices

1. **Generate dedicated SSH keys** for your droplet:
   ```bash
   ssh-keygen -t ed25519 -C "your-email@example.com" -f ~/.ssh/shrtwrd_droplet
   ```

2. **Add to SSH config** (`~/.ssh/config`):
   ```
   Host shrtwrd-droplet
       HostName YOUR_DROPLET_IP
       User root
       IdentityFile ~/.ssh/shrtwrd_droplet
   ```

3. **Copy public key to droplet**:
   ```bash
   ssh-copy-id -i ~/.ssh/shrtwrd_droplet.pub root@YOUR_DROPLET_IP
   ```

### SSH Security

- Use key-based authentication (disable password auth)
- Use strong passphrases on private keys
- Rotate keys regularly
- Use different keys for different environments

## 🌐 Domain and DNS Security

### DNS Configuration

Set these A records for your domain:
```
yourdomain.com     -> YOUR_DROPLET_IP
*.yourdomain.com   -> YOUR_DROPLET_IP
```

Or individually:
```
one.yourdomain.com   -> YOUR_DROPLET_IP
two.yourdomain.com   -> YOUR_DROPLET_IP
three.yourdomain.com -> YOUR_DROPLET_IP
four.yourdomain.com  -> YOUR_DROPLET_IP
five.yourdomain.com  -> YOUR_DROPLET_IP
six.yourdomain.com   -> YOUR_DROPLET_IP
```

### DNS Security Best Practices

- Use DNS providers with good security records
- Enable DNSSEC if available
- Monitor DNS changes
- Use CAA records to restrict certificate authorities

## 🔐 SSL/TLS Security

### Automatic HTTPS with Caddy

Caddy automatically:
- Obtains Let's Encrypt certificates
- Renews certificates before expiration
- Redirects HTTP to HTTPS
- Uses strong TLS configurations

### Certificate Security

- Certificates are stored in Docker volumes
- Private keys never leave the server
- Automatic renewal prevents expiration
- Strong cipher suites enabled by default

## 🚫 What NOT to Do

### ❌ Never Commit These

```bash
# DON'T do this
git add .env
git add deploy-multi.sh  # if it has hardcoded values
git add id_rsa*
git add *.pem
```

### ❌ Avoid Hardcoded Values

```bash
# DON'T do this in scripts
DROPLET_IP="167.172.193.225"
EMAIL="your-real-email@example.com"

# DO this instead
DROPLET_IP="${DROPLET_IP}"
EMAIL="${EMAIL}"
```

### ❌ Don't Share Sensitive Files

- Don't send `.env` files via email/chat
- Don't store credentials in shared documents
- Don't commit temporary files with secrets

## ✅ Security Checklist

Before each deployment:

- [ ] `.env` file is configured and not committed
- [ ] SSH keys are properly configured
- [ ] DNS records are set correctly
- [ ] Firewall rules are configured (ports 80, 443, 22 only)
- [ ] Let's Encrypt email is valid
- [ ] No hardcoded secrets in committed files
- [ ] `.gitignore` is properly configured

Before each git commit:

- [ ] Run `git status` to check what's being committed
- [ ] Verify no `.env` or sensitive files are staged
- [ ] Check that only template files are included
- [ ] Review changes for accidentally hardcoded values

## 🔄 Environment Management

### Development vs Production

```bash
# Development
cp .env.template .env.dev
# Configure with staging values

# Production  
cp .env.template .env.prod
# Configure with production values

# Use different files for different environments
ENV_FILE=.env.dev ./deploy-multi.sh
ENV_FILE=.env.prod ./deploy-multi.sh
```

### Team Collaboration

1. **Share templates**, not actual config files
2. **Document required variables** in `.env.template`
3. **Use different domains/IPs** per team member
4. **Never commit anyone's actual credentials**

## 🚨 Incident Response

### If Secrets are Accidentally Committed

1. **Immediately rotate** all exposed credentials
2. **Remove from git history**:
   ```bash
   git filter-branch --force --index-filter 'git rm --cached --ignore-unmatch .env' --prune-empty --tag-name-filter cat -- --all
   ```
3. **Force push** (if safe to do so)
4. **Notify team members** to pull latest changes
5. **Update DNS, SSH keys, certificates** as needed

### If Server is Compromised

1. **Isolate** the droplet immediately
2. **Rotate** all SSH keys and passwords
3. **Recreate** the droplet from scratch
4. **Audit** logs for suspicious activity
5. **Review** access controls and permissions

## 📚 Additional Resources

- [DigitalOcean Security Best Practices](https://docs.digitalocean.com/tutorials/recommended-security-measures/)
- [Let's Encrypt Best Practices](https://letsencrypt.org/docs/)
- [SSH Security Best Practices](https://infosec.mozilla.org/guidelines/openssh)
- [Git Security Best Practices](https://github.com/OWASP/CheatSheetSeries/blob/master/cheatsheets/Git_Secrets_Cheat_Sheet.md)

## 📞 Support

If you have security concerns or questions:

1. Check this document first
2. Review the setup scripts and templates
3. Test in a development environment
4. Create an issue in the repository (without sensitive details)

Remember: **Security is everyone's responsibility**. When in doubt, err on the side of caution and ask for help.