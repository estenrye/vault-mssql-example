using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Metadata;
using Microsoft.Extensions.Configuration;
using Microsoft.Extensions.Options;
using Vault;
using Vault.Models.Auth.AppRole;

namespace TodoApi.Models
{
	public class TodoContext: DbContext
	{
        private readonly IConfiguration configuration;

		public TodoContext(DbContextOptions<TodoContext> options, IConfiguration configuration)
			:base(options)
		{
			this.configuration = configuration;
		}

		public DbSet<TodoItem> TodoItems { get; set; }

		protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
		{
            var connectionStringFormat = configuration.GetConnectionString("TodoConnectionString");
			var mountPoint = configuration.GetValue<string>("Vault:MountPoint");
			var roleId = configuration.GetValue<string>("Vault:RoleId");
			var secretId = configuration.GetValue<string>("Vault:SecretId");
			var vaultUriWithPort = configuration.GetValue<System.Uri>("Vault:UriWithPort");
			var roleName = configuration.GetValue<string>("Vault:RoleName");

            var appRole = new LoginRequest() 
			{
				RoleId = roleId,
				SecretId = secretId
			};
			var vaultClient = new VaultClient();
			var loginResponse = vaultClient.Auth.Write<LoginRequest>("auth/approle/login", appRole).Result;
			// IOptions<VaultOptions> vaultOptions = new 
            // IVaultClient vaultClient = VaultClientFactory.CreateVaultClient(vaultUriWithPort, appRoleAuthenticationInfo);
            // var msSqlCredentials = vaultClient.MicrosoftSqlGenerateDynamicCredentialsAsync(roleName, mountPoint).Result;

            // var msSqlUsername = msSqlCredentials.Data.Username;
            // var msSqlPassword = msSqlCredentials.Data.Password;

			// var connectionString = string.Format(connectionStringFormat, msSqlUsername, msSqlPassword);
            // optionsBuilder.UseSqlServer(connectionString);		
		}
		protected override void OnModelCreating(ModelBuilder builder) {
			builder.Entity<TodoItem>(entity =>
			{
				entity.Property(e => e.Id).HasColumnType("bigint");
				entity.Property(e => e.Name).HasColumnType("nvarchar(256)");
				entity.Property(e => e.IsComplete).HasColumnType("bit");
			});
		}
	}
}