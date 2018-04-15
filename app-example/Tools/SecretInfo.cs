using System;
using System.Collections.Generic;
using System.Text;

namespace Tools
{
    public class SecretInfo
    {
        public DateTimeOffset expiration_time { get; set; }
        public int secret_id_num_uses { get; set; }
    }
}
