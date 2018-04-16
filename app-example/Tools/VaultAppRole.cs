using System;
using Vault;
using Microsoft.Extensions.Configuration;

namespace Tools
{
    public class VaultAppRole
    {
        public Uri VaultUri { get; set; }
        public string AppRoleMountpoint { get; set; }
        public string AppRoleName { get; set; }
        public string BootstrapToken { get; set; }
        public string RoleId { get; set; }
        public string SecretId { get; set; }
        public string Token { get; set; }
        public string DatabaseMountpoint { get; set; }
        public string DatabaseRole { get; set; }
        public SqlLoginCredentials Credentials { get; set; }

        public VaultAppRole()
        {
            Credentials = new SqlLoginCredentials();
        }

        public VaultAppRole(IConfiguration config)
        {
            VaultUri = new Uri(config["Vault:Uri"]); ;
            AppRoleMountpoint = config["Vault:AppRole:Mountpoint"];
            BootstrapToken = config["Vault:BootstrapToken"];
            AppRoleName = config["Vault:AppRole:Name"];
            DatabaseMountpoint = config["Vault:Database:Mountpoint"];
            DatabaseRole = config["Vault:Database:RoleName"];
            Credentials = new SqlLoginCredentials();
        }

        public void GetSecrets()
        {
            var vaultClient = new VaultClient
            {
                Address = VaultUri,
                Token = BootstrapToken
            };
            var roleIdResponse = vaultClient.Auth.Read<Vault.Models.Auth.AppRole.RoleIdResponse>($"{AppRoleMountpoint}/role/{AppRoleName}/role-id");
            var secretIdResponse = vaultClient.Auth.Write<Vault.Models.Auth.AppRole.SecretIdResponse>($"{AppRoleMountpoint}/role/{AppRoleName}/secret-id");
            RoleId = roleIdResponse.Result.Data.RoleId;
            SecretId = secretIdResponse.Result.Data.SecretId;
        }

        public void GetToken()
        {
            var vaultClient = new VaultClient
            {
                Address = VaultUri
            };

            var appRole = new Vault.Models.Auth.AppRole.LoginRequest()
            {
                RoleId = RoleId,
                SecretId = SecretId
            };

            var loginResponse = vaultClient.Auth.Write<Vault.Models.Auth.AppRole.LoginRequest, Vault.Models.NoData>("approle/login", appRole);

            Token = loginResponse.Result.Auth.ClientToken;
        }

        public void GetCredentials()
        {
            var vaultClient = new VaultClient
            {
                Address = VaultUri,
                Token = Token
            };

            var credentialResponse = vaultClient.Secret.Read<SqlLoginCredentials>($"{DatabaseMountpoint}/creds/{DatabaseRole}");
            Credentials = credentialResponse.Result.Data;
        }

    }
}
