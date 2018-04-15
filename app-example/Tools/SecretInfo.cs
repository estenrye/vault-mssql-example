using System;

namespace Tools
{
    public class SecretInfo
    {
#pragma warning disable IDE1006 // Naming Styles
        public DateTimeOffset expiration_time { get; set; }
        public int secret_id_num_uses { get; set; }
#pragma warning restore IDE1006 // Naming Styles
    }
}
