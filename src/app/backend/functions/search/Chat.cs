// Install the .NET library via NuGet: dotnet add package Azure.AI.OpenAI --prerelease
using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Azure;
using Azure.AI.OpenAI;
using Azure.AI.OpenAI.Chat;
using Azure.Identity;
using OpenAI.Chat;
using static System.Environment;

string endpoint = GetEnvironmentVariable("AZURE_OPENAI_ENDPOINT");
string deploymentName = GetEnvironmentVariable("AZURE_OPENAI_DEPLOYMENT_ID");
string searchEndpoint = GetEnvironmentVariable("AZURE_AI_SEARCH_ENDPOINT");
string searchIndex = GetEnvironmentVariable("AZURE_AI_SEARCH_INDEX");
string openAiApiKey = GetEnvironmentVariable("AZURE_OPENAI_KEY");


#pragma warning disable AOAI001 // Suppress the diagnostic warning
AzureKeyCredential credential = new(openAiApiKey); // Add your OpenAI API key here
AzureOpenAIClient azureClient = new(
    new Uri(endpoint),
    credential
);
ChatClient chatClient = azureClient.GetChatClient(deploymentName);

// Setup chat completion options with Azure Search data source
ChatCompletionOptions options = new ChatCompletionOptions();
options.AddDataSource(new AzureSearchChatDataSource()
{
    Endpoint = new Uri(searchEndpoint),
    IndexName = searchIndex,
    Authentication = DataSourceAuthentication.FromApiKey(GetEnvironmentVariable("OYD_SEARCH_KEY")), // Add your Azure AI Search admin key here
});

// Create chat completion request
ChatCompletion completion = chatClient.CompleteChat(
    new List<ChatMessage>()
    {
        new UserChatMessage("")
    },
    new ChatCompletionOptions
    {
        PastMessages = 10,
        Temperature = (float)0.7,
        TopP = (float)0.95,
        FrequencyPenalty = (float)0,
        PresencePenalty = (float)0,
        MaxTokens = 4096,
        StopSequences = new List<string>(),
    }
);
// Process and print the response
AzureChatMessageContext onYourDataContext = completion.GetAzureMessageContext();
Console.WriteLine(completion.Role + ": " + completion.Content[0].Text);
if (onYourDataContext?.Intent is not null)
{
    Console.WriteLine($"Intent: {onYourDataContext.Intent}");
}
foreach (AzureChatCitation citation in onYourDataContext?.Citations ?? new List<AzureChatCitation>())
{
    Console.WriteLine($"Citation: {citation.Content}");
}

#pragma warning restore AOAI001 // Restore the diagnostic warning
