# Tailscale Ansible Role

This role manages Tailscale installation and configuration using OAuth authentication for improved security.

## Features

- **OAuth Authentication**: Uses OAuth client credentials instead of static API keys
- **Dynamic Auth Key Generation**: Creates one-time use auth keys for each device
- **Automation Tag**: Automatically tags devices with `tag:automation` for proper OAuth scope management
- **Secure Cleanup**: Removes generated auth keys and clears sensitive variables after use
- **DNS Integration**: Automatically manages DNS rewrites in AdGuard Home for Tailscale devices

## Requirements

1. A Tailscale OAuth client with the following scopes:
   - `auth_keys`
   - `devices:core`
   - `devices:routes`
2. The OAuth client must have access to devices tagged with `tag:automation`

## Variables

### Required Variables

```yaml
secrets:
  tailscale:
    client_id: "your-oauth-client-id"
    client_secret: "your-oauth-client-secret"
    tailnet_id: "your-tailnet-id"
  adguard:  # Optional: for DNS rewrite management
    api_url: "http://your-adguard-server:3000"
    username: "your-adguard-username"
    password: "your-adguard-password"
    domain_suffix: "ts.local"  # Optional: defaults to "ts.local"

tailscale_routes: "192.168.1.0/24,10.0.0.0/8"  # Comma-separated list of routes to advertise
```

## OAuth Client Setup

1. Go to the Tailscale admin console
2. Navigate to Settings > OAuth clients
3. Create a new OAuth client with:
   - **Scopes**: `auth_keys`, `devices:core`, `devices:routes`
   - **Tags**: `tag:automation` (this tag will be applied to all devices registered by this client)
4. Save the client ID and secret in your secrets management system

## Security Benefits

- **No Static Keys**: No need to manage long-lived API keys or auth keys
- **Scoped Access**: OAuth client only has access to devices it creates with the automation tag
- **Automatic Cleanup**: Auth keys are automatically deleted after use
- **Audit Trail**: OAuth provides better logging and audit capabilities

## Migration from Static Keys

If you're migrating from the previous version that used static API keys:

1. Create an OAuth client as described above
2. Update your secrets to use `client_id` and `client_secret` instead of `api_key` and `auth_key`
3. Remove the old `api_key` and `auth_key` variables
4. Run the playbook - existing devices will continue to work, new devices will use OAuth

## Example Playbook

```yaml
- hosts: servers
  roles:
    - role: tailscale
      vars:
        tailscale_routes: "192.168.1.0/24,10.0.0.0/16"
```

## Tags Applied

All devices registered through this role will automatically receive:
- `tag:automation` - Required for OAuth client access
- Any additional tags can be configured in the OAuth client settings

## Error Handling

The role includes comprehensive error handling for:
- Missing OAuth credentials
- Failed OAuth authentication
- Invalid OAuth token
- Device registration failures
- API communication errors

## AdGuard Home DNS Integration

The role can optionally manage DNS rewrites in AdGuard Home for Tailscale devices:

### Features
- **Automatic DNS Rewrites**: Creates hostname.domain_suffix -> Tailscale IP mappings
- **Cleanup on Removal**: Automatically removes DNS rewrites when devices are deleted
- **Conflict Resolution**: Updates existing rewrites if they already exist

### Setup
1. Enable the AdGuard Home API in your AdGuard Home settings
2. Create a username/password for API access
3. Add the AdGuard credentials to your secrets as shown in the variables section above

### DNS Rewrite Format
- **Domain**: `hostname.domain_suffix` (e.g., `server1.ts.local`)
- **Answer**: Device's Tailscale IP address
- **Default Suffix**: `ts.local` (configurable via `secrets.adguard.domain_suffix`)

## Example Playbook

```yaml
- hosts: servers
  roles:
    - role: tailscale
      vars:
        tailscale_routes: "192.168.1.0/24,10.0.0.0/16"
```
