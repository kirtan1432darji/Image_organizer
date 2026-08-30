namespace AI.ScreenshotOrganizer.Shared.Constants;

public static class SystemCategories
{
    public static readonly (string Name, string Icon, string Color, string[] SubCategories)[] Defaults = new[]
    {
        ("Receipts & Invoices", "receipt", "#4CAF50", new[] { "Groceries", "Dining", "Utilities", "Shopping", "Travel" }),
        ("Finance & Banking", "account_balance", "#2196F3", new[] { "Bank Statements", "Crypto", "Investments", "UPI & Transfers" }),
        ("Social & Chat", "forum", "#E91E63", new[] { "WhatsApp", "Instagram", "Twitter/X", "Telegram", "Discord" }),
        ("Documents & IDs", "description", "#9C27B0", new[] { "Passports", "IDs", "Certificates", "Contracts" }),
        ("Code & Tech", "code", "#607D8B", new[] { "Error Logs", "Code Snippets", "Architecture", "Terminal" }),
        ("Memes & Humor", "sentiment_very_satisfied", "#FF9800", new[] { "Jokes", "Comics", "Funny Screenshots" }),
        ("Notes & Knowledge", "note", "#00BCD4", new[] { "Book Quotes", "Articles", "Meeting Notes", "Reminders" }),
        ("Shopping & Wishlist", "shopping_cart", "#F44336", new[] { "Amazon", "Fashion", "Electronics", "Deals" }),
        ("Travel & Tickets", "flight", "#3F51B5", new[] { "Boarding Passes", "Hotels", "Train Tickets", "Maps" })
    };
}
