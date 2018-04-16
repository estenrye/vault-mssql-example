using Microsoft.Extensions.Configuration;

namespace Tools
{
    public class MockVaultSqlCredentials : IVaultSqlCredentials
    {
        private readonly IConfiguration Configuration;
        public MockVaultSqlCredentials (IConfiguration config)
        {
            Configuration = config;
        }

        public SqlLoginCredentials GetCredentials()
        {
            var result = new SqlLoginCredentials
            {
                password = Configuration["DatabaseConnection:DesignTimePassword"],
                username = Configuration["DatabaseConnection:DesignTimeUsername"]
            };

            return result;
        }

        public void RefreshToken()
        {}
    }
}
