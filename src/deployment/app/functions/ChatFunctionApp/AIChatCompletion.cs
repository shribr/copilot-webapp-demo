using System.Threading.Tasks;
using Microsoft.SemanticKernel.ChatCompletion;

public class AIChatCompletion : IChatCompletion
{
    private readonly IChatCompletion _chatCompletion;

    public AIChatCompletion()
    {
        // Initialize your chat completion implementation here
        // For example, you might use a specific implementation of IChatCompletion
        _chatCompletion = new AIChatCompletion(); // Replace with your actual implementation
    }

    public async Task<string> CompleteAsync(ChatContext chatContext)
    {
        var response = await _chatCompletion.CompleteAsync(chatContext);
        return response;
    }
}