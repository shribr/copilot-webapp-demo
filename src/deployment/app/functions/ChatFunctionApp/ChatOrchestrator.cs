using System.Threading.Tasks;
using Microsoft.Azure.WebJobs;
using Microsoft.Azure.WebJobs.Extensions.Http;
using Microsoft.AspNetCore.Http;
using Microsoft.Extensions.Logging;
using Microsoft.Azure.WebJobs.Extensions.DurableTask;
using Microsoft.SemanticKernel.ChatCompletion;

public static class ChatOrchestrator
{
    [FunctionName("ChatOrchestrator")]
    public static async Task<string> RunOrchestrator(
        [OrchestrationTrigger] IDurableOrchestrationContext context)
    {
        var chatHistory = context.GetInput<ChatHistory>() ?? new ChatHistory();
        var userMessage = context.GetInput<string>();

        chatHistory.AddMessage($"User: {userMessage}");

        var chatContext = new ChatContext
        {
            History = chatHistory.GetHistory(),
            UserMessage = userMessage
        };

        var response = await context.CallActivityAsync<string>("ChatActivity", chatContext);

        chatHistory.AddMessage($"Bot: {response}");

        return response;
    }

    [FunctionName("ChatActivity")]
    public static async Task<string> ChatActivity([ActivityTrigger] ChatContext chatContext, ILogger log)
    {
        var chatCompletion = new YourChatCompletionImplementation(); // Replace with your actual implementation
        return await chatCompletion.CompleteAsync(chatContext);
    }

    [FunctionName("ChatHttpStart")]
    public static async Task<IActionResult> HttpStart(
        [HttpTrigger(AuthorizationLevel.Function, "get", "post")] HttpRequest req,
        [DurableClient] IDurableOrchestrationClient starter,
        ILogger log)
    {
        string userMessage = req.Query["message"];

        string instanceId = await starter.StartNewAsync("ChatOrchestrator", userMessage);

        log.LogInformation($"Started orchestration with ID = '{instanceId}'.");

        return starter.CreateCheckStatusResponse(req, instanceId);
    }
}