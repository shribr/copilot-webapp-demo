using System.Collections.Generic;

public class ChatHistory
{
    public List<string> Messages { get; private set; }

    public ChatHistory()
    {
        Messages = new List<string>();
    }

    public void AddMessage(string message)
    {
        Messages.Add(message);
    }

    public string GetHistory()
    {
        return string.Join("\n", Messages);
    }
}