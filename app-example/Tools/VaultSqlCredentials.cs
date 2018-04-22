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
        public int? SecretIdNumUses { get; set; }
        public string Token { get; set; }
        public DateTime? TokenExpiration { get; set; }
        public int? TokenUsesRemaining { get; set; }
        public string SqlLoginUsername { get; set; }
        public string SqlLoginPassword { get; set; }
        public DateTime? SqlLoginExpiration { get; set; }


        public VaultSqlCredentials(IConfiguration config)
        {
            VaultUri = new Uri(config["Vault:Uri"]); ;
            AppRoleMountpoint = config["Vault:AppRole:Mountpoint"];
            BootstrapToken = config["Vault:BootstrapToken"];
            AppRoleName = config["Vault:AppRole:Name"];
            DatabaseMountpoint = config["Vault:Database:Mountpoint"];
            DatabaseRole = config["Vault:Database:RoleName"];

            vaultClient = new VaultClient(VaultUri, BootstrapToken);
            Console.WriteLine($"Attempting to retrieve role id from {VaultUri}");
            var roleIdResponse = vaultClient.Auth.Read<Vault.Models.Auth.AppRole.RoleIdResponse>($"{AppRoleMountpoint}/role/{AppRoleName}/role-id");
            RoleId = roleIdResponse.Result.Data.RoleId;
            Console.WriteLine($"RoleId: {RoleId}");

            Console.WriteLine($"Attempting to retrieve secret id from {VaultUri}");
            var secretIdResponse = vaultClient.Auth.Write<Vault.Models.Auth.AppRole.SecretIdResponse>($"{AppRoleMountpoint}/role/{AppRoleName}/secret-id");
            SecretId = secretIdResponse.Result.Data.SecretId;
            Console.WriteLine($"SecretId: {SecretId}");

            var appRole = new Vault.Models.Auth.AppRole.LoginRequest()
            {
                RoleId = RoleId,
                SecretId = SecretId
            };

            Console.WriteLine($"Attempting to retrieve token from {VaultUri}");
            var loginResponse = vaultClient.Auth.Write<Vault.Models.Auth.AppRole.LoginRequest, Vault.Models.NoData>("approle/login", appRole);
            Token = loginResponse.Result.Auth.ClientToken;
            Console.WriteLine($"Token: {Token}");

            if (loginResponse.Result.Auth.LeaseDuration != 0)
            {
                TokenExpiration = DateTime.Now.AddSeconds(loginResponse.Result.Auth.LeaseDuration);
            }
            vaultClient.Token = Token;

            var secretIdLookupRequest = new Vault.Models.Auth.AppRole.SecretIdLookupRequest
            {
                SecretId = SecretId
            };
            Console.WriteLine($"Attempting to retrieve secret id information from {VaultUri}");
            var secretInfo = vaultClient.Auth.Write<Vault.Models.Auth.AppRole.SecretIdLookupRequest, SecretInfo>($"{AppRoleMountpoint}/role/{AppRoleName}/secret-id/lookup", secretIdLookupRequest);
            SecretIdExpiration = secretInfo.Result.Data.expiration_time.LocalDateTime;
            SecretIdNumUses = secretInfo.Result.Data.secret_id_num_uses;

            Console.WriteLine($"Attempting to retrieve token info from {VaultUri}");
            var tokenInfoResponse = vaultClient.Auth.Read<Vault.Models.Auth.Token.LookupResponse>("token/lookup-self");
            TokenUsesRemaining = tokenInfoResponse.Result.Data.NumUses;
        }

        public void RefreshToken()
        {
            if (DateTime.Now > SecretIdExpiration || SecretIdNumUses <= 0)
            {
                vaultClient.Token = BootstrapToken;
                Console.WriteLine($"Secret Id Expired.  Attempting to retrieve new secret id from {VaultUri}");
                var secretIdResponse = vaultClient.Auth.Write<Vault.Models.Auth.AppRole.SecretIdResponse>($"{AppRoleMountpoint}/role/{AppRoleName}/secret-id");
                SecretId = secretIdResponse.Result.Data.SecretId;
                vaultClient.Token = Token;

                SecretIdNumUses = null;
                SecretIdExpiration = null;
            }

            if (TokenExpiration == null || TokenUsesRemaining == null || SecretIdNumUses == null|| TokenUsesRemaining <= 0 || DateTime.Now > TokenExpiration)
            {
                vaultClient.Token = null;
                var appRole = new Vault.Models.Auth.AppRole.LoginRequest()
                {
                    RoleId = RoleId,
                    SecretId = SecretId
                };
                Console.WriteLine($"Token Expired.  Attempting to retrieve new token from {VaultUri}");
                var loginResponse = vaultClient.Auth.Write<Vault.Models.Auth.AppRole.LoginRequest, Vault.Models.NoData>("approle/login", appRole);
                SecretIdNumUses--;
                Token = loginResponse.Result.Auth.ClientToken;
                if (loginResponse.Result.Auth.LeaseDuration != 0)
                {
                    TokenExpiration = DateTime.Now.AddSeconds(loginResponse.Result.Auth.LeaseDuration);
                }
                vaultClient.Token = Token;

                var secretIdLookupRequest = new Vault.Models.Auth.AppRole.SecretIdLookupRequest
                {
                    SecretId = SecretId
                };

                Console.WriteLine($"Attempting to retrieve secret id information from {VaultUri}");
                var secretInfo = vaultClient.Auth.Write<Vault.Models.Auth.AppRole.SecretIdLookupRequest, SecretInfo>($"{AppRoleMountpoint}/role/{AppRoleName}/secret-id/lookup", secretIdLookupRequest);
                SecretIdExpiration = secretInfo.Result.Data.expiration_time.LocalDateTime;
                SecretIdNumUses = secretInfo.Result.Data.secret_id_num_uses;

                Console.WriteLine($"Attempting to retrieve token info from {VaultUri}");
                var tokenInfoResponse = vaultClient.Auth.Read<Vault.Models.Auth.Token.LookupResponse>("token/lookup-self");
                TokenUsesRemaining = tokenInfoResponse.Result.Data.NumUses;
            }
        }

        public SqlLoginCredentials GetCredentials()
        {
            if (Token != null && TokenUsesRemaining <= 1)
            {
                Console.WriteLine($"Attempting to retrieve token info from {VaultUri}");
                var tokenInfoResponse = vaultClient.Auth.Read<Vault.Models.Auth.Token.LookupResponse>("token/lookup-self");
                TokenUsesRemaining = tokenInfoResponse.Result.Data.NumUses;
            }
            RefreshToken();

            if (string.IsNullOrWhiteSpace(SqlLoginUsername) || DateTime.Now > SqlLoginExpiration)
            {
                Console.WriteLine($"Attempting to retrieve sql credentials from {VaultUri}");
                var credentialResponse = vaultClient.Secret.Read<SqlLoginCredentials>($"{DatabaseMountpoint}/creds/{DatabaseRole}");
                TokenUsesRemaining--;

                SqlLoginUsername = credentialResponse.Result.Data.username;
                SqlLoginPassword = credentialResponse.Result.Data.password;
                SqlLoginExpiration = DateTime.Now.AddSeconds(credentialResponse.Result.LeaseDuration);
            }

            return new SqlLoginCredentials
            {
                password = SqlLoginPassword,
                username = SqlLoginUsername
            };
        }
    }
}
