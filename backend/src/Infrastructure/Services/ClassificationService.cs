using System.Text.Json;
using System.Text.RegularExpressions;
using Microsoft.EntityFrameworkCore;
using AI.ScreenshotOrganizer.Application.Common.Exceptions;
using AI.ScreenshotOrganizer.Application.Common.Interfaces;
using AI.ScreenshotOrganizer.Application.Features.Classification.DTOs;
using AI.ScreenshotOrganizer.Domain.Entities;

namespace AI.ScreenshotOrganizer.Infrastructure.Services;

public class ClassificationService : IClassificationService
{
    private readonly IApplicationDbContext _context;

    public ClassificationService(IApplicationDbContext context)
    {
        _context = context;
    }

    public async Task<ClassificationResponseDto> ClassifyAsync(ClassifyRequestDto request, Guid? userId = null, CancellationToken cancellationToken = default)
    {
        var rawText = (request.OCRText ?? string.Empty).Trim();
        var text = rawText.ToLowerInvariant();
        var fileName = (request.FileName ?? string.Empty).ToLowerInvariant();
        var filePath = (request.FilePath ?? string.Empty).ToLowerInvariant();
        var sourceApp = (request.SourceApp ?? string.Empty).ToLowerInvariant();
        var desc = (request.VisionDescription ?? string.Empty).ToLowerInvariant();

        // 1. Detect Source App & Signature
        var detectedApp = InferApp(sourceApp, filePath, fileName, text);

        // 2. Extract Keywords & Entities
        var keywords = ExtractKeywords(rawText, detectedApp);

        // 3. Classify into Hierarchy (Category -> SubCategory -> Leaf)
        var (folderPath, tags, confidence, summary) = ClassifyScreenshotContent(text, fileName, filePath, detectedApp, desc, rawText);

        var rootCategoryName = folderPath.Count > 0 ? folderPath[0] : "General";
        var subCategoryName = folderPath.Count > 1 ? folderPath[1] : null;

        // 4. Resolve or create Categories in SQL Server
        var rootCategory = await GetOrCreateCategoryAsync(rootCategoryName, null, userId, cancellationToken);
        Category? subCategory = null;
        if (!string.IsNullOrEmpty(subCategoryName))
        {
            subCategory = await GetOrCreateCategoryAsync(subCategoryName, rootCategory.Id, userId, cancellationToken);
        }

        // If there's a 3rd segment (e.g. Projects -> NHDC -> Payroll)
        Category? leafCategory = subCategory;
        if (folderPath.Count > 2)
        {
            var leafName = folderPath[2];
            leafCategory = await GetOrCreateCategoryAsync(leafName, subCategory?.Id ?? rootCategory.Id, userId, cancellationToken);
        }

        var assignedCategory = leafCategory ?? subCategory ?? rootCategory;

        // 5. Update Screenshot & ClassificationHistory if screenshot exists
        Screenshot? screenshot = null;
        if (!string.IsNullOrEmpty(request.ScreenshotId) && Guid.TryParse(request.ScreenshotId, out var screenshotGuid))
        {
            screenshot = await _context.Screenshots
                .Include(s => s.ClassificationHistories)
                .FirstOrDefaultAsync(s => s.Id == screenshotGuid, cancellationToken);

            if (screenshot != null)
            {
                screenshot.CategoryId = assignedCategory.Id;
                screenshot.SubCategoryId = subCategory?.Id;
                screenshot.Confidence = confidence;
                screenshot.ClassificationConfidence = confidence;
                screenshot.DetectedApp = detectedApp;
                screenshot.KeywordsJson = JsonSerializer.Serialize(keywords);
                screenshot.IsAutoCategorized = true;

                // Record in ClassificationHistory
                var history = new ClassificationHistory
                {
                    Id = Guid.NewGuid(),
                    ScreenshotId = screenshot.Id,
                    Category = rootCategoryName,
                    SubCategory = subCategoryName,
                    TagsJson = JsonSerializer.Serialize(tags),
                    Confidence = confidence,
                    ModelName = "contextvault-ai-engine-v1.3",
                    CreatedDate = DateTime.UtcNow
                };

                _context.ClassificationHistories.Add(history);
                await _context.SaveChangesAsync(cancellationToken);
            }
        }

        return new ClassificationResponseDto
        {
            ScreenshotId = request.ScreenshotId ?? (screenshot?.Id.ToString() ?? string.Empty),
            CategoryId = assignedCategory.Id.ToString(),
            CategoryName = rootCategoryName,
            SubCategoryId = subCategory?.Id.ToString(),
            SubCategoryName = subCategoryName,
            FolderPath = folderPath,
            DetectedApp = detectedApp,
            Tags = tags,
            Keywords = keywords,
            Confidence = confidence,
            Summary = summary,
            ModelName = "contextvault-ai-engine-v1.3",
            IsAutoCategorized = true
        };
    }

    public async Task<ClassificationResponseDto> ReclassifyAsync(ReclassifyRequestDto request, Guid? userId = null, CancellationToken cancellationToken = default)
    {
        if (!Guid.TryParse(request.ScreenshotId, out var screenshotGuid))
        {
            throw new ValidationException("ScreenshotId", "Invalid screenshot GUID.");
        }

        var screenshot = await _context.Screenshots
            .FirstOrDefaultAsync(s => s.Id == screenshotGuid, cancellationToken)
            ?? throw new NotFoundException($"Screenshot with ID '{request.ScreenshotId}' not found.");

        var classifyReq = new ClassifyRequestDto
        {
            ScreenshotId = screenshot.Id.ToString(),
            FileName = screenshot.FileName,
            FilePath = screenshot.ImagePath,
            OCRText = string.IsNullOrEmpty(request.UserHint) ? screenshot.OCRText : $"{request.UserHint}\n{screenshot.OCRText}",
            VisionDescription = screenshot.VisionDescription,
            SourceApp = screenshot.SourceApp
        };

        return await ClassifyAsync(classifyReq, userId ?? screenshot.UserId, cancellationToken);
    }

    public async Task<IReadOnlyList<ClassificationHistoryDto>> GetHistoryAsync(Guid screenshotId, CancellationToken cancellationToken = default)
    {
        var histories = await _context.ClassificationHistories
            .Where(h => h.ScreenshotId == screenshotId && !h.IsDeleted)
            .OrderByDescending(h => h.CreatedDate)
            .ToListAsync(cancellationToken);

        return histories.Select(h =>
        {
            List<string> tags = new();
            try
            {
                if (!string.IsNullOrEmpty(h.TagsJson))
                {
                    tags = JsonSerializer.Deserialize<List<string>>(h.TagsJson) ?? new();
                }
            }
            catch {}

            return new ClassificationHistoryDto
            {
                Id = h.Id,
                ScreenshotId = h.ScreenshotId,
                Category = h.Category,
                SubCategory = h.SubCategory,
                Tags = tags,
                Confidence = h.Confidence,
                ModelName = h.ModelName,
                CreatedAt = h.CreatedDate
            };
        }).ToList();
    }

    private async Task<Category> GetOrCreateCategoryAsync(string name, Guid? parentCategoryId, Guid? userId, CancellationToken cancellationToken)
    {
        var lowerName = name.Trim().ToLower();
        var existing = await _context.Categories
            .FirstOrDefaultAsync(c => c.Name.ToLower() == lowerName &&
                                      c.ParentCategoryId == parentCategoryId &&
                                      (c.UserId == userId || c.UserId == null) &&
                                      !c.IsDeleted, cancellationToken);

        if (existing != null)
        {
            return existing;
        }

        var (icon, color) = InferCategoryIconAndColor(name);
        var newCategory = new Category
        {
            Id = Guid.NewGuid(),
            Name = name.Trim(),
            ParentCategoryId = parentCategoryId,
            UserId = userId,
            Icon = icon,
            Color = color,
            CreatedByAI = true,
            Description = parentCategoryId == null ? $"Smart Folder: {name}" : $"Subfolder: {name}",
            CreatedDate = DateTime.UtcNow
        };

        _context.Categories.Add(newCategory);
        await _context.SaveChangesAsync(cancellationToken);
        return newCategory;
    }

    private static (List<string> FolderPath, List<string> Tags, double Confidence, string Summary) ClassifyScreenshotContent(
        string text, string fileName, string filePath, string detectedApp, string desc, string rawText)
    {
        var tags = new List<string>();

        // 1. Projects / Payroll / Work
        // Example: WhatsApp payroll screenshot -> Projects -> NHDC -> Payroll
        var isPayroll = text.Contains("payroll") || text.Contains("payslip") || text.Contains("salary") ||
                        text.Contains("disbursed") || text.Contains("earnings & deductions") || text.Contains("basic pay");

        var isProject = text.Contains("project") || text.Contains("sprint") || text.Contains("jira") ||
                        text.Contains("trello") || text.Contains("asana") || text.Contains("nhdc") ||
                        detectedApp == "Jira" || detectedApp == "Asana" || detectedApp == "Slack";

        if (isPayroll || isProject)
        {
            tags.AddRange(new[] { "work", "project" });
            string entityName = "Work";

            var entityMatch = Regex.Match(rawText, @"\b(NHDC|TCS|INFOSYS|WIPRO|HCL|GOOGLE|META|AMAZON|MICROSOFT|RELIANCE|TATA|[A-Z]{3,8})\b");
            if (entityMatch.Success)
            {
                entityName = entityMatch.Value;
            }

            if (isPayroll)
            {
                tags.Add("payroll");
                return (new List<string> { "Projects", entityName, "Payroll" }, tags, 0.96, $"Payroll & salary breakdown for {entityName}");
            }

            return (new List<string> { "Projects", entityName }, tags, 0.94, $"Project deliverables & sprint notes for {entityName}");
        }

        // 2. Shopping (e.g. Amazon shoes screenshot -> Shopping -> Shoes)
        var isShopping = text.Contains("amazon") || text.Contains("flipkart") || text.Contains("cart") ||
                         text.Contains("buy now") || text.Contains("order placed") || text.Contains("order #") ||
                         detectedApp == "Amazon" || detectedApp == "Flipkart" || detectedApp == "Myntra";

        if (isShopping)
        {
            tags.AddRange(new[] { "shopping", "ecommerce" });
            string subCat = "Deals";

            if (text.Contains("shoe") || text.Contains("shoes") || text.Contains("sneaker") || text.Contains("running shoes") || text.Contains("nike") || text.Contains("adidas") || text.Contains("puma"))
            {
                subCat = "Shoes";
                tags.Add("shoes");
            }
            else if (text.Contains("laptop") || text.Contains("phone") || text.Contains("electronics") || text.Contains("headphone") || text.Contains("charger"))
            {
                subCat = "Electronics";
                tags.Add("electronics");
            }
            else if (text.Contains("shirt") || text.Contains("dress") || text.Contains("jeans") || text.Contains("clothing") || text.Contains("fashion"))
            {
                subCat = "Clothing";
                tags.Add("fashion");
            }

            return (new List<string> { "Shopping", subCat }, tags, 0.95, $"Product page or order in {subCat}");
        }

        // 3. Learning (e.g. Flutter tutorial screenshot -> Learning -> Flutter)
        var isLearning = text.Contains("tutorial") || text.Contains("course") || text.Contains("lecture") ||
                         text.Contains("udemy") || text.Contains("coursera") || text.Contains("learn") ||
                         text.Contains("documentation") || text.Contains("guide") || text.Contains("state management");

        if (isLearning)
        {
            tags.AddRange(new[] { "learning", "education" });
            string topic = "General";

            if (text.Contains("flutter") || text.Contains("riverpod") || text.Contains("dart"))
            {
                topic = "Flutter";
                tags.AddRange(new[] { "flutter", "dart" });
            }
            else if (text.Contains("python") || text.Contains("django") || text.Contains("fastapi"))
            {
                topic = "Python";
                tags.Add("python");
            }
            else if (text.Contains("react") || text.Contains("javascript") || text.Contains("typescript"))
            {
                topic = "Web";
                tags.Add("frontend");
            }

            return (new List<string> { "Learning", topic }, tags, 0.95, $"Educational tutorial or study note for {topic}");
        }

        // 4. Finance & Payments (e.g. UPI payment screenshot -> Finance -> Payments)
        var isFinance = text.Contains("upi") || text.Contains("gpay") || text.Contains("phonepe") ||
                        text.Contains("paytm") || text.Contains("paid to") || text.Contains("transferred") ||
                        text.Contains("account balance") || text.Contains("bank statement") || text.Contains("crypto") ||
                        text.Contains("bitcoin") || detectedApp == "Google Pay" || detectedApp == "PhonePe" || detectedApp == "Paytm";

        if (isFinance)
        {
            tags.AddRange(new[] { "finance", "money" });
            string subCat = "Payments";

            if (text.Contains("crypto") || text.Contains("btc") || text.Contains("eth") || text.Contains("binance"))
            {
                subCat = "Crypto";
                tags.Add("crypto");
            }
            else if (text.Contains("stock") || text.Contains("shares") || text.Contains("dividend") || text.Contains("zerodha"))
            {
                subCat = "Investments";
                tags.Add("stocks");
            }
            else
            {
                tags.Add("payments");
            }

            return (new List<string> { "Finance", subCat }, tags, 0.96, $"Financial transaction or {subCat} record");
        }

        // 5. Meetings (e.g. Meeting screenshot -> Meetings -> Client Meeting)
        var isMeeting = text.Contains("meeting") || text.Contains("zoom") || text.Contains("google meet") ||
                        text.Contains("teams") || text.Contains("agenda") || text.Contains("attendees") ||
                        detectedApp == "Zoom" || detectedApp == "Teams" || detectedApp == "Google Meet";

        if (isMeeting)
        {
            tags.AddRange(new[] { "meeting", "work" });
            string subCat = "Team Meeting";

            if (text.Contains("client") || text.Contains("customer") || text.Contains("presentation") || text.Contains("demo"))
            {
                subCat = "Client Meeting";
                tags.Add("client");
            }

            return (new List<string> { "Meetings", subCat }, tags, 0.93, $"Meeting capture: {subCat}");
        }

        // 6. Travel & Flights
        var isTravel = text.Contains("boarding pass") || text.Contains("flight") || text.Contains("gate") ||
                       text.Contains("seat") || text.Contains("hotel") || text.Contains("pnr") ||
                       detectedApp == "MakeMyTrip" || detectedApp == "Booking.com" || detectedApp == "Airbnb";

        if (isTravel)
        {
            tags.AddRange(new[] { "travel", "tickets" });
            string subCat = "Flights";
            if (text.Contains("hotel") || text.Contains("resort"))
            {
                subCat = "Hotels";
            }
            else if (text.Contains("train") || text.Contains("irctc"))
            {
                subCat = "Trains";
            }

            return (new List<string> { "Travel", subCat }, tags, 0.95, $"Travel reservation: {subCat}");
        }

        // 7. Code & Tech
        var isCode = text.Contains("public class") || text.Contains("function") || text.Contains("import ") ||
                     text.Contains("exception") || text.Contains("stack trace") || text.Contains("git ") ||
                     detectedApp == "GitHub" || detectedApp == "VS Code";

        if (isCode)
        {
            tags.AddRange(new[] { "developer", "tech" });
            string subCat = "Snippets";
            if (text.Contains("dart") || text.Contains("flutter"))
            {
                subCat = "Dart";
            }
            else if (text.Contains("c#") || text.Contains(".net"))
            {
                subCat = "C#";
            }

            return (new List<string> { "Code & Tech", subCat }, tags, 0.94, $"Developer snippet or {subCat} log");
        }

        // 8. Social & Chat
        if (detectedApp == "WhatsApp" || detectedApp == "Telegram" || detectedApp == "Instagram" || detectedApp == "Twitter")
        {
            tags.AddRange(new[] { "social", "chat", detectedApp.ToLower() });
            return (new List<string> { "Social", detectedApp }, tags, 0.92, $"Social conversation from {detectedApp}");
        }

        // Clean Topic Fallback: Never locked to static "Notes & Knowledge"
        var cleanKeywords = ExtractKeywords(rawText, detectedApp);
        if (cleanKeywords.Count > 0)
        {
            var dynamicTopic = cleanKeywords[0];
            tags.Add(dynamicTopic.ToLower());
            return (new List<string> { "General", dynamicTopic }, tags, 0.85, $"Screen content related to {dynamicTopic}");
        }

        return (new List<string> { "Unsorted" }, new List<string> { "unsorted" }, 0.50, "Uncategorized screenshot requiring review");
    }

    private static string InferApp(string sourceApp, string filePath, string fileName, string text)
    {
        var combined = $"{sourceApp} {filePath} {fileName} {text}".ToLowerInvariant();

        if (combined.Contains("whatsapp")) return "WhatsApp";
        if (combined.Contains("instagram")) return "Instagram";
        if (combined.Contains("telegram")) return "Telegram";
        if (combined.Contains("twitter") || combined.Contains(" x ")) return "Twitter";
        if (combined.Contains("amazon")) return "Amazon";
        if (combined.Contains("flipkart")) return "Flipkart";
        if (combined.Contains("youtube")) return "YouTube";
        if (combined.Contains("chrome")) return "Chrome";
        if (combined.Contains("gpay") || combined.Contains("google pay")) return "Google Pay";
        if (combined.Contains("phonepe")) return "PhonePe";
        if (combined.Contains("paytm")) return "Paytm";
        if (combined.Contains("zoom")) return "Zoom";
        if (combined.Contains("teams")) return "Teams";
        if (combined.Contains("slack")) return "Slack";
        if (combined.Contains("github")) return "GitHub";
        if (combined.Contains("vscode") || combined.Contains("vs code")) return "VS Code";
        if (combined.Contains("linkedin")) return "LinkedIn";
        if (combined.Contains("reddit")) return "Reddit";

        if (!string.IsNullOrEmpty(sourceApp))
        {
            return Capitalize(sourceApp);
        }

        return "Android System";
    }

    private static List<string> ExtractKeywords(string text, string detectedApp)
    {
        var keywords = new List<string>();
        if (!string.IsNullOrEmpty(detectedApp) && detectedApp != "Android System")
        {
            keywords.Add(detectedApp);
        }

        var matches = Regex.Matches(text, @"\b[A-Z][a-zA-Z0-9]{3,20}\b");
        foreach (Match match in matches)
        {
            var word = match.Value;
            if (!keywords.Contains(word, StringComparer.OrdinalIgnoreCase) &&
                !IsCommonStopword(word))
            {
                keywords.Add(word);
                if (keywords.Count >= 10) break;
            }
        }

        return keywords;
    }

    private static bool IsCommonStopword(string word)
    {
        var stops = new HashSet<string>(StringComparer.OrdinalIgnoreCase)
        {
            "This", "That", "There", "Where", "Which", "When", "From", "With", "About",
            "Screen", "Screenshot", "Image", "Photo", "Settings", "Cancel", "Done", "Okay",
            "Next", "Back", "Share", "View", "Edit", "Save"
        };
        return stops.Contains(word);
    }

    private static (string Icon, string Color) InferCategoryIconAndColor(string categoryName)
    {
        var lower = categoryName.ToLowerInvariant();
        if (lower.Contains("project")) return ("folder_special", "#6366F1");
        if (lower.Contains("payroll") || lower.Contains("finance") || lower.Contains("payment")) return ("payments", "#10B981");
        if (lower.Contains("shopping") || lower.Contains("shoes")) return ("shopping_cart", "#EC4899");
        if (lower.Contains("learning") || lower.Contains("flutter")) return ("school", "#3B82F6");
        if (lower.Contains("meeting")) return ("groups", "#F59E0B");
        if (lower.Contains("travel") || lower.Contains("flight")) return ("flight", "#06B6D4");
        if (lower.Contains("code") || lower.Contains("tech")) return ("code", "#8B5CF6");
        if (lower.Contains("social") || lower.Contains("chat")) return ("chat", "#25D366");

        return ("folder", "#64748B");
    }

    private static string Capitalize(string str)
    {
        if (string.IsNullOrEmpty(str)) return str;
        return char.ToUpper(str[0]) + str.Substring(1);
    }
}
