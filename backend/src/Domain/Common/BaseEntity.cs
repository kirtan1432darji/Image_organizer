namespace AI.ScreenshotOrganizer.Domain.Common;

public interface IAuditableEntity
{
    DateTime CreatedOn { get; set; }
    DateTime? UpdatedOn { get; set; }
    Guid? CreatedBy { get; set; }
    Guid? UpdatedBy { get; set; }
    bool IsDeleted { get; set; }
    DateTime? DeletedOn { get; set; }
    byte[]? RowVersion { get; set; }
}

public abstract class BaseEntity : IAuditableEntity
{
    public Guid Id { get; set; } = Guid.NewGuid();
    public DateTime CreatedOn { get; set; } = DateTime.UtcNow;
    public DateTime? UpdatedOn { get; set; }
    public Guid? CreatedBy { get; set; }
    public Guid? UpdatedBy { get; set; }
    public bool IsDeleted { get; set; } = false;
    public DateTime? DeletedOn { get; set; }
    public byte[]? RowVersion { get; set; }

    // Backwards-compatibility aliases for existing queries and migrations
    public DateTime CreatedDate
    {
        get => CreatedOn;
        set => CreatedOn = value;
    }

    public DateTime? UpdatedDate
    {
        get => UpdatedOn;
        set => UpdatedOn = value;
    }
}
