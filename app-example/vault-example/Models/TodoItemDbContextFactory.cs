using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;
using Microsoft.Extensions.Configuration;
using System;
using Tools;

namespace vault_example.Models
{
    public class TodoItemDbContextFactory : ITodoItemDesignTimeDbContextFactory
    {
        private readonly IVaultSqlCredentials CredentialVault;
        private readonly IConfiguration Configuration;

        public TodoItemDbContextFactory()
        {
            var basePath = AppContext.BaseDirectory;
            var environmentName = Environment.GetEnvironmentVariable("Hosting:Environment");
            var builder = new ConfigurationBuilder()
                .SetBasePath(basePath)
                .AddUserSecrets<Startup>()
                .AddEnvironmentVariables();

            Configuration = builder.Build();

            CredentialVault = new MockVaultSqlCredentials(Configuration);
        }

        public TodoItemDbContextFactory(IConfiguration config, IVaultSqlCredentials vault)
        {
            Configuration = config;
            CredentialVault = vault;
        }

        public TodoItemDbContext CreateDbContext(string[] args)
        {
            return new TodoItemDbContext(GetDbContextOptions(), null);
        }

        public DbContextOptions<TodoItemDbContext> GetDbContextOptions()
        {
            var credentials = CredentialVault.GetCredentials();
            var instance = Configuration["DatabaseConnection:Instance"];
            var database = Configuration["DatabaseConnection:Database"];
            var encrypt = bool.Parse(Configuration["DatabaseConnection:Encrypt"]);
            var trustServerCertificate = bool.Parse(Configuration["DatabaseConnection:TrustServerCertificate"]);
            var connectionString = $"Server={instance};Database={database};User Id={credentials.username};Password={credentials.password};Encrypt={encrypt};TrustServerCertificate={trustServerCertificate}";
            var optionsBuilder = new DbContextOptionsBuilder<TodoItemDbContext>();
            optionsBuilder.UseSqlServer(connectionString);

            return optionsBuilder.Options;
        }
    }
}
