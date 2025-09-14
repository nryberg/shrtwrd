# DNS Configuration for shrtwrd.com

Configure your DNS records to point to your DigitalOcean droplet at **YOUR_DROPLET_IP**.

## Required DNS Records

Add the following A records in your domain registrar's DNS management panel:

| Hostname | Type | Value | TTL |
|----------|------|-------|-----|
| @ | A | YOUR_DROPLET_IP | 300 |
| one | A | YOUR_DROPLET_IP | 300 |
| two | A | YOUR_DROPLET_IP | 300 |
| three | A | YOUR_DROPLET_IP | 300 |
| four | A | YOUR_DROPLET_IP | 300 |
| five | A | YOUR_DROPLET_IP | 300 |

**Note:** The `@` symbol represents your root domain (yourdomain.com).

## Step-by-Step Instructions

### 1. Access Your Domain Registrar
Log into your domain registrar's control panel where you purchased your domain.

### 2. Find DNS Management
Look for one of these sections:
- DNS Management
- DNS Settings
- Name Servers
- Zone File
- Advanced DNS

### 3. Add A Records
For each hostname listed above:
1. Click "Add Record" or "New Record"
2. Select "A Record" as the type
3. Enter the hostname (@ for root, one, two, etc.)
4. Enter the IP address: `YOUR_DROPLET_IP`
5. Set TTL to 300 (5 minutes) for faster propagation
6. Save the record

### 4. Remove Conflicting Records
Delete any existing A or CNAME records that might conflict with these subdomains.

## Verification

### Check DNS Propagation
Wait 5-15 minutes after making changes, then test:

```bash
# Test root domain
nslookup yourdomain.com
dig yourdomain.com

# Test subdomains
nslookup one.yourdomain.com
nslookup two.yourdomain.com
nslookup three.yourdomain.com
nslookup four.yourdomain.com
nslookup five.yourdomain.com
```

All should return: `YOUR_DROPLET_IP`

### Online DNS Checkers
Use these tools to verify propagation:
- https://www.whatsmydns.net/
- https://dnschecker.org/
- https://www.dnswatch.info/

### Test Your Application
Once DNS propagates (usually 5-60 minutes):

```bash
# Test different word counts
curl http://yourdomain.com
curl http://one.yourdomain.com
curl http://two.yourdomain.com
curl http://three.yourdomain.com
curl http://four.yourdomain.com
curl http://five.yourdomain.com

# Test with multiple lines
curl http://yourdomain.com/5
curl http://two.yourdomain.com/10
```

## Expected Results

- `yourdomain.com` → 3 words per line (default)
- `one.yourdomain.com` → 1 word per line
- `two.yourdomain.com` → 2 words per line
- `three.yourdomain.com` → 3 words per line
- `four.yourdomain.com` → 4 words per line
- `five.yourdomain.com` → 5 words per line

Adding `/N` to any URL generates N lines.

## Troubleshooting

### DNS Not Propagating
- Wait longer (up to 24 hours in some cases)
- Check TTL values are low (300 seconds)
- Verify no typos in IP address
- Clear your local DNS cache: `sudo dscacheutil -flushcache` (macOS)

### Wrong IP Address Returned
- Double-check the A record values
- Make sure you didn't accidentally create AAAA (IPv6) records
- Remove any conflicting CNAME records

### Domain Not Loading
- Verify your server is running: `curl http://YOUR_DROPLET_IP`
- Check firewall allows HTTP traffic on port 80
- Ensure Docker container is running on the droplet

### Still Not Working?
1. Test direct IP first: `curl http://YOUR_DROPLET_IP`
2. Check DNS: `nslookup yourdomain.com`
3. Verify server logs: `ssh root@YOUR_DROPLET_IP 'docker logs shrtwrd-server'`

## Common DNS Providers

### Hover (Your Registrar)
1. Log into your Hover account at https://www.hover.com/
2. Click on "Domains" in the top navigation
3. Find and click on your domain name
4. Click the "DNS" tab
5. For each A record needed:
   - Click "Add a Record"
   - Select "A" from the dropdown
   - Enter the hostname (leave blank for @, or enter one, two, three, four, five)
   - Enter IP: `YOUR_DROPLET_IP`
   - Leave TTL as default
   - Click "Save"
6. Delete any existing A records that conflict with your new ones

**Note:** In Hover, use a blank hostname field for the root domain (@) record.

### Namecheap
1. Dashboard → Domain List → Manage
2. Advanced DNS tab
3. Add A Records as shown above

### GoDaddy
1. My Products → DNS → Manage Zones
2. Select your domain
3. Add A Records as shown above

### Cloudflare
1. DNS → Records
2. Add A Records as shown above
3. Make sure "Proxy status" is set to "DNS only" (gray cloud)

### Google Domains
1. DNS tab
2. Custom Records section
3. Add A Records as shown above

## Security Note
Once DNS is working, set up SSL certificates using the provided `ssl-setup.sh` script for HTTPS encryption.