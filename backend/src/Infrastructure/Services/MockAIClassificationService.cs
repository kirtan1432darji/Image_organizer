using System.Text.RegularExpressions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Screenshots.DTOs;

namespace AI.ScreenshotOrganizer.Infrastructure.Services;

public class MockAIClassificationService : IAIClassificationService
{
    public Task<ClassificationResultDto> ClassifyScreenshotAsync(ClassifyScreenshotRequestDto request, CancellationToken cancellationToken = default)
    {
        var text = (request.OCRText ?? string.Empty).ToLowerInvariant();
        var desc = (request.VisionDescription ?? string.Empty).ToLowerInvariant();
        var app = (request.SourceApp ?? string.Empty).ToLowerInvariant();

        string category = "General Screenshots";
        string? subCategory = "Uncategorized";
        var tags = new List<string>();
        double confidence = 0.70;

        // 1. Receipts, Invoices & Bills
        if (text.Contains("invoice") || text.Contains("receipt") || text.Contains("subtotal") || text.Contains("total") ||
            text.Contains("tax") || text.Contains("amount paid") || text.Contains("bill") || text.Contains("due date") ||
            text.Contains("order #") || text.Contains("order id") || text.Contains("purchase") ||
            text.Contains("walmart") || text.Contains("target") || text.Contains("starbucks") || text.Contains("uber eats") ||
            text.Contains("doordash") || desc.Contains("receipt") || desc.Contains("invoice") || desc.Contains("bill"))
        {
            category = "Receipts & Invoices";
            confidence = 0.94;
            tags.Add("receipt");

            if (text.Contains("dining") || text.Contains("restaurant") || text.Contains("food") || text.Contains("starbucks") || text.Contains("eats") || text.Contains("cafe"))
            {
                subCategory = "Dining";
                tags.Add("food");
            }
            else if (text.Contains("grocery") || text.Contains("market") || text.Contains("walmart") || text.Contains("whole foods"))
            {
                subCategory = "Groceries";
                tags.Add("groceries");
            }
            else if (text.Contains("electric") || text.Contains("water") || text.Contains("internet") || text.Contains("utility") || text.Contains("bill"))
            {
                subCategory = "Utilities";
                tags.Add("bills");
            }
            else if (text.Contains("flight") || text.Contains("hotel") || text.Contains("airbnb") || text.Contains("airline"))
            {
                subCategory = "Travel";
                tags.Add("travel");
            }
            else
            {
                subCategory = "Shopping";
                tags.Add("purchase");
            }
        }
        // 2. Finance & Banking
        else if (text.Contains("account balance") || text.Contains("available balance") || text.Contains("bank statement") ||
                 text.Contains("bank account") || text.Contains("transfer") || text.Contains("upi") || text.Contains("crypto") ||
                 text.Contains("bitcoin") || text.Contains("ethereum") || text.Contains("portfolio") || text.Contains("stocks") ||
                 text.Contains("nasdaq") || text.Contains("chase") || text.Contains("wells fargo") || text.Contains("revolut") ||
                 app.Contains("bank") || app.Contains("finance") || app.Contains("crypto") || app.Contains("wallet"))
        {
            category = "Finance & Banking";
            confidence = 0.92;
            tags.Add("finance");

            if (text.Contains("crypto") || text.Contains("btc") || text.Contains("eth") || text.Contains("binance") || text.Contains("coinbase"))
            {
                subCategory = "Crypto";
                tags.Add("crypto");
            }
            else if (text.Contains("stock") || text.Contains("shares") || text.Contains("nasdaq") || text.Contains("dividend") || text.Contains("robinhood"))
            {
                subCategory = "Investments";
                tags.Add("investing");
            }
            else if (text.Contains("upi") || text.Contains("sent to") || text.Contains("transferred") || text.Contains("venmo") || text.Contains("zelle"))
            {
                subCategory = "UPI & Transfers";
                tags.Add("transfers");
            }
            else
            {
                subCategory = "Bank Statements";
                tags.Add("bank");
            }
        }
        // 3. Code & Tech
        else if (text.Contains("function") || text.Contains("public class") || text.Contains("import ") || text.Contains("exception") ||
                 text.Contains("stack trace") || text.Contains("github") || text.Contains("git commit") || text.Contains("const ") ||
                 text.Contains("npm ") || text.Contains("docker") || text.Contains("kubernetes") || text.Contains("terminal") ||
                 text.Contains("bash") || text.Contains("powershell") || app.Contains("github") || app.Contains("vscode") || app.Contains("terminal"))
        {
            category = "Code & Tech";
            confidence = 0.95;
            tags.Add("developer");

            if (text.Contains("exception") || text.Contains("error") || text.Contains("stack trace") || text.Contains("fatal") || text.Contains("failed"))
            {
                subCategory = "Error Logs";
                tags.Add("debug");
                tags.Add("error");
            }
            else if (text.Contains("terminal") || text.Contains("bash") || text.Contains("zsh") || text.Contains("command not found") || text.Contains("sudo"))
            {
                subCategory = "Terminal";
                tags.Add("cli");
            }
            else
            {
                subCategory = "Code Snippets";
                tags.Add("code");
            }
        }
        // 4. Social & Chat
        else if (app.Contains("whatsapp") || app.Contains("telegram") || app.Contains("instagram") || app.Contains("twitter") ||
                 app.Contains("x") || app.Contains("discord") || app.Contains("slack") || app.Contains("messenger") ||
                 text.Contains("online") || text.Contains("typing...") || text.Contains("message") || text.Contains("retweet") ||
                 text.Contains("replying to") || text.Contains("direct message"))
        {
            category = "Social & Chat";
            confidence = 0.91;
            tags.Add("social");

            if (app.Contains("whatsapp") || text.Contains("whatsapp"))
            {
                subCategory = "WhatsApp";
                tags.Add("whatsapp");
                tags.Add("chat");
            }
            else if (app.Contains("twitter") || app.Contains("x") || text.Contains("retweet") || text.Contains("tweet"))
            {
                subCategory = "Twitter/X";
                tags.Add("twitter");
            }
            else if (app.Contains("instagram") || text.Contains("story") || text.Contains("reels"))
            {
                subCategory = "Instagram";
                tags.Add("instagram");
            }
            else if (app.Contains("discord") || text.Contains("discord"))
            {
                subCategory = "Discord";
                tags.Add("discord");
            }
            else
            {
                subCategory = "Chat";
                tags.Add("chat");
            }
        }
        // 5. Travel & Tickets
        else if (text.Contains("boarding pass") || text.Contains("flight") || text.Contains("gate") || text.Contains("seat") ||
                 text.Contains("hotel booking") || text.Contains("reservation") || text.Contains("train ticket") || text.Contains("pnr") ||
                 text.Contains("check-in") || desc.Contains("ticket") || desc.Contains("boarding pass"))
        {
            category = "Travel & Tickets";
            confidence = 0.93;
            tags.Add("travel");

            if (text.Contains("boarding pass") || text.Contains("flight") || text.Contains("gate") || text.Contains("airline"))
            {
                subCategory = "Boarding Passes";
                tags.Add("flight");
            }
            else if (text.Contains("hotel") || text.Contains("airbnb") || text.Contains("booking confirmation"))
            {
                subCategory = "Hotels";
                tags.Add("hotel");
            }
            else if (text.Contains("train") || text.Contains("railway") || text.Contains("pnr"))
            {
                subCategory = "Train Tickets";
                tags.Add("transit");
            }
            else
            {
                subCategory = "Tickets";
                tags.Add("ticket");
            }
        }
        // 6. Documents & IDs
        else if (text.Contains("passport") || text.Contains("driver license") || text.Contains("identity card") || text.Contains("social security") ||
                 text.Contains("certificate") || text.Contains("agreement") || text.Contains("confidential") || text.Contains("contract") ||
                 desc.Contains("document") || desc.Contains("id card"))
        {
            category = "Documents & IDs";
            confidence = 0.90;
            tags.Add("document");

            if (text.Contains("passport"))
            {
                subCategory = "Passports";
                tags.Add("passport");
            }
            else if (text.Contains("license") || text.Contains("id card") || text.Contains("national id"))
            {
                subCategory = "IDs";
                tags.Add("id");
            }
            else if (text.Contains("certificate") || text.Contains("degree") || text.Contains("diploma"))
            {
                subCategory = "Certificates";
                tags.Add("certificate");
            }
            else
            {
                subCategory = "Contracts";
                tags.Add("legal");
            }
        }
        // 7. Shopping & Wishlist
        else if (text.Contains("add to cart") || text.Contains("buy now") || text.Contains("in stock") || text.Contains("amazon") ||
                 text.Contains("flipkart") || text.Contains("ebay") || text.Contains("aliexpress") || text.Contains("price drop") ||
                 app.Contains("amazon") || app.Contains("shopping") || app.Contains("flipkart"))
        {
            category = "Shopping & Wishlist";
            confidence = 0.89;
            tags.Add("shopping");

            if (text.Contains("amazon"))
            {
                subCategory = "Amazon";
                tags.Add("amazon");
            }
            else if (text.Contains("fashion") || text.Contains("size") || text.Contains("shoes") || text.Contains("clothing"))
            {
                subCategory = "Fashion";
                tags.Add("fashion");
            }
            else if (text.Contains("electronics") || text.Contains("specs") || text.Contains("gpu") || text.Contains("ram"))
            {
                subCategory = "Electronics";
                tags.Add("gadgets");
            }
            else
            {
                subCategory = "Deals";
                tags.Add("deals");
            }
        }
        // 8. Notes & Knowledge
        else if (text.Contains("chapter") || text.Contains("quote") || text.Contains("summary") || text.Contains("highlight") ||
                 text.Contains("meeting notes") || text.Contains("to-do") || text.Contains("agenda") || app.Contains("notes") ||
                 app.Contains("notion") || app.Contains("evernote") || app.Contains("keep") || app.Contains("kindle"))
        {
            category = "Notes & Knowledge";
            confidence = 0.88;
            tags.Add("notes");

            if (text.Contains("book") || text.Contains("kindle") || text.Contains("quote") || text.Contains("author"))
            {
                subCategory = "Book Quotes";
                tags.Add("reading");
            }
            else if (text.Contains("meeting") || text.Contains("action items") || text.Contains("agenda"))
            {
                subCategory = "Meeting Notes";
                tags.Add("work");
            }
            else
            {
                subCategory = "Articles";
                tags.Add("knowledge");
            }
        }
        // 9. Memes & Humor
        else if (desc.Contains("meme") || desc.Contains("funny") || text.Contains("when you") || text.Contains("me trying to") ||
                 text.Contains("nobody:") || text.Contains("pov:") || text.Contains("lol") || text.Contains("lmao") ||
                 app.Contains("reddit") || app.Contains("9gag") || app.Contains("ifunny"))
        {
            category = "Memes & Humor";
            confidence = 0.87;
            tags.Add("meme");
            subCategory = "Funny Screenshots";
        }

        // Add source app as a tag if provided
        if (!string.IsNullOrEmpty(request.SourceApp) && !tags.Contains(request.SourceApp.ToLowerInvariant()))
        {
            tags.Add(request.SourceApp.ToLowerInvariant().Replace(" ", "_"));
        }

        var result = new ClassificationResultDto
        {
            Category = category,
            SubCategory = subCategory,
            Tags = tags.Distinct().ToList(),
            Confidence = Math.Round(confidence, 2),
            ModelName = "gemini-1.5-flash-screenshot-v1"
        };

        return Task.FromResult(result);
    }
}
