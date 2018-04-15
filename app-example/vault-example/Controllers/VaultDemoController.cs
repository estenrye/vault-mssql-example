using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Extensions.Configuration;
using Tools;

namespace vault_example.Controllers
{
    public class VaultDemoController : Controller
    {
        public VaultDemoController(IConfiguration config)
        {
            Configuration = config;
        }

        public IConfiguration Configuration { get; set; }
        // GET: Home
        public ActionResult Index()
        {
            var model = new VaultAppRole(Configuration);
            return View(model);
        }

        [HttpPost]
        public ActionResult GetSecrets([FromForm]VaultAppRole model)
        {
            model.GetSecrets();
            return View("Index", model);
        }

        [HttpPost]
        public ActionResult GetToken([FromForm]VaultAppRole model)
        {
            model.GetToken();
            return View("Index", model);
        }

        [HttpPost]
        public ActionResult GetSqlCredentials([FromForm]VaultAppRole model)
        {
            model.GetCredentials();
            return View("Index", model);
        }
    }
}