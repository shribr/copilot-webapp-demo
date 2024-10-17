using System.Threading.Tasks;

public interface IChatCompletion
{
    Task<string> CompleteAsync(ChatContext chatContext);
}