using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.Text;
using Vault;

namespace Tools
{
    public class VaultSqlCredentials : IVaultSqlCredentials
    {
        private readonly Uri VaultUri;
        private VaultClient vaultClient;
        private readonly string AppRoleMountpoint;
        private readonly string DatabaseMountpoint;
        private readonly string DatabaseRole;
        private readonly string BootstrapToken;
        private readonly string AppRoleName;

        public string RoleId { get; set; }
        public string SecretId { get; set; }
        public DateTime? SecretIdExpiration { get; set; }
        public string Token { get; set; }
        public DateTime? TokenExpiration { get; set; }
        public int? TokenUsesRemaining { get; set; }
        public SqlLoginCredentials Credentials { get; set; }


        public VaultSqlCredentials(IConfiguration config)
        {
            VaultUri = new Uri(config["Vault:Uri"]); ;
            AppRoleMountpoint = config["Vault:AppRole:Mountpoint"];
            BootstrapToken = config["Vault:BootstrapToken"];
            AppRoleName = config["Vault:AppRole:Name"];
            DatabaseMountpoint = config["Vault:Database:Mountpoint"];
            DatabaseRole = config["Vault:Database:RoleName"];

            vaultClient = new VaultClient(VaultUri, BootstrapToken);
            var roleIdResponse = vaultClient.Auth.Read<Vault.Models.Auth.AppRole.RoleIdResponse>($"{AppRoleMountpoint}/role/{AppRoleName}/role-id");
            var secretIdResponse = vaultClient.Auth.Write<Vault.Models.Auth.AppRole.SecretIdResponse>($"{AppRoleMountpoint}/role/{AppRoleName}/secret-id");
            RoleId = roleIdResponse.Result.Data.RoleId;
            SecretId = secretIdResponse.Result.Data.SecretId;
            if (secretIdResponse.Result.LeaseDuration != 0)
            {
                SecretIdExpiration = DateTime.Now.AddSeconds(secretIdResponse.Result.LeaseDuration);
            }

            Credentials = new SqlLoginCredentials();
        }

        public void RefreshToken()
        {
            if (TokenExpiration == null || TokenUsesRemaining == null || TokenUsesRemaining == 1 || DateTime.Now > TokenExpiration)
            {
                var appRole = new Vault.Models.Auth.AppRole.LoginRequest()
                {
                    RoleId = RoleId,
                    SecretId = SecretId
                };
                var loginResponse = vaultClient.Auth.Write<Vault.Models.Auth.AppRole.LoginRequest, Vault.Models.NoData>("approle/login", appRole);
                Token = loginResponse.Result.Auth.ClientToken;
                if (loginResponse.Result.Auth.LeaseDuration != 0)
                {
                    TokenExpiration = DateTime.Now.AddSeconds(loginResponse.Result.Auth.LeaseDuration);
                }
                vaultClient.Token = Token;
                var tokenInfoResponse = vaultClient.Auth.Read<Vault.Models.Auth.Token.LookupResponse>("token/lookup-self");
                TokenUsesRemaining = tokenInfoResponse.Result.Data.NumUses--;
            }
        }

        public void GetCredentials()
        {
            RefreshToken();

            var credentialResponse = vaultClient.Secret.Read<SqlLoginCredentials>($"{DatabaseMountpoint}/creds/{DatabaseRole}");
            TokenUsesRemaining--;

            Credentials = credentialResponse.Result.Data;
        }
    }
}
