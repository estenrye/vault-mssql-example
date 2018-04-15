using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Tools;

namespace vault_example.Controllers
{
    public class HomeController : Controller
    {
        public IVaultSqlCredentials CredentialManager { get; set; }

        public HomeController(IVaultSqlCredentials creds)
        {
            CredentialManager = creds;
        }

        public IActionResult Index()
        {
            return View(CredentialManager);
        }

        [HttpPost]
        public IActionResult GetSqlCredentials()
        {
            CredentialManager.GetCredentials();
            return View("Index", CredentialManager);
        }
    }
}