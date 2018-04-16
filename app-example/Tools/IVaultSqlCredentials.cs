using System;
using System.Collections.Generic;
using System.Text;

namespace Tools
{
    public interface IVaultSqlCredentials
    {
        void RefreshToken();
        SqlLoginCredentials GetCredentials();
    }
}
