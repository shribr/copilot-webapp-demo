using Microsoft.AspNetCore.Http;
using Microsoft.AspNetCore.Mvc;
using Microsoft.Azure.Functions.Worker;
using Microsoft.Extensions.Logging;

namespace AzureAiDemo.Functions
{
    public class HttpTriggerAlerts
    {
        private readonly ILogger<HttpTriggerAlerts> _logger;

        public HttpTriggerAlerts(ILogger<HttpTriggerAlerts> logger)
        {
            _logger = logger;
        }

        [Function("HttpTriggerAlerts")]
        public IActionResult Run([HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req)
        {
            _logger.LogInformation("C# HTTP trigger function processed a request.");
            return new OkObjectResult("Welcome to Azure Functions!");
        }
    }
}
