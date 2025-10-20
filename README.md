# Disclaimer
This repository is provided "as is" without any warranties. Use at your own risk. The author is not responsible for any damage or data loss that may occur from using this code. This documentation was generated automatically and may contain errors or omissions and is subject to change without notice. I will try to keep it up to date, but cannot guarantee its accuracy or completeness.

# Homelab Ansible Automation

This repository contains Ansible playbooks and roles for automating the setup and management of a homelab environment running a single node K3s (Kubernetes), Traefik (ingress controller), and various supporting services.

## Features

- **K3s Installation**: Automated lightweight Kubernetes distribution setup
- **Traefik Ingress**: Reverse proxy with automatic SSL certificates via Let's Encrypt
- **Dual Certificate Resolvers**: Production and staging Let's Encrypt certificates
- **External DNS**: Automatic DNS record management with Cloudflare
- **Multi-tier Storage**: NVMe, SSD, and NFS storage classes
- **Security Hardening**: SSH key management, sudo configuration, and user setup
- **Monitoring**: UPS monitoring with NUT, system monitoring tools
- **VPN**: Tailscale integration for secure remote access
- **CI/CD**: GitHub Actions runner setup
- **Shell Enhancement**: Starship shell prompt customization

## Quick Start

### Prerequisites

- **Ansible Engine** installed on your control workstation
- **Ubuntu LTS** (or compatible Debian-based distribution) on target nodes
- **Secrets Management** configured (see [Secrets Configuration](#secrets-configuration))
- **Tailscale Account** (optional, for VPN access)
- **Cloudflare Account** with API token (for DNS and SSL certificates)
- **Domain Name** configured in Cloudflare

### Basic Setup

1. **Clone this repository:**
   ```bash
   git clone <repository-url>
   cd homelab
   ```

2. **Configure your inventory:**
   ```bash
   cp inventories/example.yml inventories/production.yml
   # Edit inventories/production.yml with your host information
   ```

3. **Configure secrets management:**
   ```bash
   cp roles/get-secrets/tasks/example.main.yml roles/get-secrets/tasks/main.yml
   # Edit roles/get-secrets/tasks/main.yml to integrate with your secrets manager
   ```

4. **Run the new server playbook:**
   ```bash
   ansible-playbook -i inventories/production.yml playbooks/new-server.yml
   ```

5. **Deploy K3s and services:**
   ```bash
   ansible-playbook -i inventories/production.yml playbooks/deploy-apps.yml
   ```

## Inventory Configuration

Create an inventory file based on `inventories/example.yml`. The inventory defines your homelab nodes and their roles.

### Host Variables

Each host should have these variables configured:

```yaml
servers:
  hosts:
    node1:
      ansible_host: 192.168.1.100
      ansible_hostname: node1
      local_user: admin
      ansible_user: ansible
      ansible_user_home: "/home/ansible"
      ansible_python_interpreter: "/venvs/default/bin/python"
      arch: amd64
      fqdn: node1.yourdomain.com
      tailscale:
        routes: 192.168.0.0/24
        tags:
          - "tag:server"

powerpanel:
  hosts:
    node1:  # Node with UPS USB connection

secondary_storage_nodes:
  hosts:
    node1:  # Nodes providing NFS secondary storage
```

### Special Groups

- **`servers`**: All homelab nodes

## Secrets Configuration

This playbook requires various secrets for authentication, certificates, and service configuration. The `get-secrets` role provides a framework for integrating with your preferred secrets management solution.

### Required Secrets Structure

Your secrets manager must provide a `secrets` dictionary with this structure:

```yaml
secrets:
  # User account information
  username: "system_user"                    # System administration user
  interactive_username: "admin"              # Interactive login user
  email: "admin@yourdomain.com"              # Contact email for certificates

  # SSH and authentication
  ssh_key: "-----BEGIN OPENSSH PRIVATE KEY-----..."  # Private SSH key
  temp_password: "temporary_password"        # Initial password for setup
  new_password: "secure_password"            # Final secure password

  # Network configuration
  server_network: "192.168.1.0/24"          # Server network CIDR
  lan_network: "192.168.0.0/24"             # LAN network CIDR

  # Base domain for external DNS and certificates
  base_domain: "yourdomain.com"              # Your domain name

  # Git/GitHub configuration
  git:
    username: "github_username"             # Git username
    gh_user: "github_username"              # GitHub username for SSH keys
    runner_org_id: "your-org"               # GitHub organization/user for runners
    runner_client_id: "client_id"           # GitHub App client ID
    runner_install_id: "install_id"         # GitHub App installation ID
    runner_registration_pem: "-----BEGIN RSA PRIVATE KEY-----..."  # GitHub App private key

  # Cloudflare DNS and certificates
  cloudflare:
    email: "cloudflare@yourdomain.com"      # Cloudflare account email
    token: "your_api_token"                 # Cloudflare API token

  # NUT (Network UPS Tools) for UPS monitoring
  nut:
    user: "ups_monitor"                     # UPS monitoring username
    pass: "ups_password"                    # UPS monitoring password

  # Tailscale VPN configuration
  tailscale:
    client_id: "client_id"                  # Tailscale OAuth client ID
    client_secret: "client_secret"          # Tailscale OAuth client secret
    tailnet_id: "your-tailnet"              # Tailscale tailnet identifier
```

### Secrets Manager Integration

The `roles/get-secrets/tasks/main.yml` file contains the logic for retrieving secrets. By default, it uses an example structure. You need to modify this file to integrate with your secrets management system.

Example integrations:
- **HashiCorp Vault**: Use `hashi_vault` lookup
- **AWS Secrets Manager**: Use `aws_secret` lookup
- **Azure Key Vault**: Use `azure_keyvault_secret` lookup
- **Custom**: Implement your own lookup logic

## Playbooks

### new-server.yml
Initial server setup playbook that:
- Applies security hardening (SSH, sudo, user setup)
- Installs required pre-requisite packages
- Configures secondary storage
- Installs system patches
- Installs and configures Starship shell prompt
- Sets up NUT for UPS monitoring
- Configures Tailscale VPN for secure remote access
- Sets up GitHub Actions runner for CI/CD
- Installs K3s (lightweight Kubernetes)
### deploy-apps.yml
Application deployment playbook that:
- Installs K3s Kubernetes
- Deploys Traefik ingress controller
- Configures external DNS
- Sets up storage provisioners
- Deploys monitoring services

## Roles

### Core Roles
- **`get-secrets`**: Secrets management integration
- **`pre-reqs`**: System prerequisites and environment setup
- **`k3s-install`**: K3s installation and configuration
- **`security`**: User management and security hardening
- **`ssh`**: SSH key distribution and configuration

### Service Roles
- **`tailscale`**: VPN setup and configuration
- **`external-dns`**: DNS record management
- **`secondary-storage`**: NFS storage configuration
- **`nut`**: UPS monitoring with NUT
- **`github-runner`**: GitHub Actions self-hosted runners
- **`starship`**: Shell prompt customization

## SSL Certificates

The setup automatically provisions SSL certificates using Let's Encrypt with Cloudflare DNS challenges. Two certificate resolvers are configured:

- **`letsencrypt-prod`**: Production certificates (rate limited)
- **`letsencrypt-staging`**: Staging certificates (no rate limits, for testing)

### Certificate Configuration

- **DNS Provider**: Cloudflare with API token authentication
- **Challenge Type**: DNS-01 (automatic DNS record creation)
- **Storage**: Certificates stored in persistent volumes
- **Renewal**: Automatic renewal handled by Traefik

### Cloudflare Requirements

Your Cloudflare API token must have these permissions:
- **Zone:DNS:Edit** - Create/delete DNS records for ACME challenges
- **Zone:Zone:Read** - Find your domain zone

Certificates are automatically renewed and managed by Traefik.

## Storage

### Local Storage
K3s uses `local-path-provisioner` for local storage with multiple storage classes:

- **`local-path-nvme`** (default): High-performance NVMe storage at `/mnt/secondary-storage`
- **`local-path-ssd`**: SATA SSD storage at `/opt/local-path-provisioner`

### NFS Storage
Secondary storage nodes provide NFS exports for backups pulled by the NAS:
- Default path: `/mnt/secondary-storage`
- Configurable per deployment

### Storage Class Selection

Different applications use different storage classes based on performance requirements:
- **High-performance apps**: Use `local-path-nvme`
- **Reliable storage**: Use `local-path-ssd`

## Networking

### Ingress
Traefik serves as the ingress controller with:
- Automatic SSL termination
- Path and host-based routing
- Dashboard access (protected)

### VPN
Tailscale provides secure remote access with:
- Subnet routing
- Exit Node support
- Device authorization

## Monitoring

### UPS Monitoring
Network UPS Tools (NUT) monitors CyberPower UPS units with:
- USB connectivity
- Web interface
- Client access for other devices

### System Monitoring
Basic system monitoring and logging is configured for all services.

## Troubleshooting

### Common Issues

**K3s Installation Fails**
- Ensure iptables is configured correctly on Debian
- Check network connectivity
- Verify firewall settings

**SSL Certificate Issues**
- Verify Cloudflare API token permissions (Zone:DNS:Edit, Zone:Zone:Read)
- Check that your domain exists in Cloudflare
- Ensure API token is not expired
- Use staging certificates for testing to avoid rate limits

**Storage Provisioning Issues**
- Verify NFS exports are accessible
- Check local-path-provisioner configuration includes required paths
- Ensure storage classes are properly defined
- Check PVC events for binding failures
- Check mount permissions
- Ensure local-path-provisioner is running
- Check DNS zone configuration
- Ensure domain points to correct IP
**Secrets Not Found**
- Verify secrets manager integration
- Check secret paths and permissions
- Ensure all required secrets are defined

### Logs and Debugging

Enable verbose logging:
```bash
ansible-playbook -i inventories/production.yml -vvv playbooks/deploy-apps.yml
```

Check service logs:
```bash
kubectl logs -n kube-system deployment/traefik
kubectl logs -n kube-system -l app=external-dns
```

## Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Test thoroughly
5. Submit a pull request

## License

This project is licensed under the MIT License - see the LICENSE file for details.