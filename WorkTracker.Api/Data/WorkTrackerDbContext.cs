using Microsoft.EntityFrameworkCore;

namespace WorkTracker.Api.Data;

public sealed class WorkTrackerDbContext(DbContextOptions<WorkTrackerDbContext> options)
    : DbContext(options)
{
    public DbSet<FamilyEntity> Families => Set<FamilyEntity>();
    public DbSet<UserEntity> Users => Set<UserEntity>();
    public DbSet<FamilyMemberEntity> FamilyMembers => Set<FamilyMemberEntity>();
    public DbSet<SharedExpenseEntity> SharedExpenses => Set<SharedExpenseEntity>();
    public DbSet<SharedIncomeEntity> SharedIncomes => Set<SharedIncomeEntity>();
    public DbSet<BudgetEntity> Budgets => Set<BudgetEntity>();
    public DbSet<ExpenseCategoryEntity> ExpenseCategories => Set<ExpenseCategoryEntity>();
    public DbSet<FamilyWorkSnapshotEntity> FamilyWorkSnapshots => Set<FamilyWorkSnapshotEntity>();

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<FamilyEntity>(entity =>
        {
            entity.HasKey(item => item.Id);
            entity.Property(item => item.Name).HasMaxLength(160).IsRequired();
            entity.Property(item => item.CreatedAt).IsRequired();
        });
        modelBuilder.Entity<UserEntity>(entity =>
        {
            entity.HasKey(item => item.Id);
            entity.HasIndex(item => item.Email).IsUnique();
            entity.Property(item => item.Email).HasMaxLength(320).IsRequired();
            entity.Property(item => item.DisplayName).HasMaxLength(160).IsRequired();
            entity.Property(item => item.PasswordHash).IsRequired();
        });
        modelBuilder.Entity<FamilyMemberEntity>(entity =>
        {
            entity.HasKey(item => item.Id);
            entity.HasIndex(item => new { item.FamilyId, item.UserId }).IsUnique();
            entity.Property(item => item.Role).HasMaxLength(24).IsRequired();
        });
        modelBuilder.Entity<SharedExpenseEntity>(entity =>
        {
            entity.HasKey(item => item.Id);
            entity.Property(item => item.Title).HasMaxLength(180).IsRequired();
            entity.Property(item => item.Category).HasMaxLength(80).IsRequired();
            entity.Property(item => item.Note).HasMaxLength(1000);
            entity.Property(item => item.Visibility).HasMaxLength(24).IsRequired();
            entity.Property(item => item.Amount).HasPrecision(18, 4);
        });
        modelBuilder.Entity<SharedIncomeEntity>(entity => { entity.HasKey(item => item.Id); entity.Property(item => item.Title).HasMaxLength(180).IsRequired(); entity.Property(item => item.Amount).HasPrecision(18, 4); entity.Property(item => item.Note).HasMaxLength(1000); });
        modelBuilder.Entity<BudgetEntity>(entity => { entity.HasKey(item => item.Id); entity.Property(item => item.Amount).HasPrecision(18, 4); entity.Property(item => item.Category).HasMaxLength(80).IsRequired(); entity.HasIndex(item => new { item.FamilyId, item.Year, item.Month, item.Category }).IsUnique(); });
        modelBuilder.Entity<ExpenseCategoryEntity>(entity => { entity.HasKey(item => item.Id); entity.Property(item => item.Name).HasMaxLength(80).IsRequired(); entity.HasIndex(item => new { item.FamilyId, item.Name }).IsUnique(); });
        modelBuilder.Entity<FamilyWorkSnapshotEntity>(entity => { entity.HasKey(item => item.Id); entity.Property(item => item.WorkName).HasMaxLength(180).IsRequired(); entity.Property(item => item.WorkType).HasMaxLength(40).IsRequired(); entity.Property(item => item.SalaryDescription).HasMaxLength(160).IsRequired(); entity.HasIndex(item => new { item.FamilyId, item.SourceWorkId }).IsUnique(); });
    }
}

public sealed class FamilyEntity
{
    public Guid Id { get; set; }
    public string Name { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; }
}

public sealed class UserEntity
{
    public Guid Id { get; set; }
    public string Email { get; set; } = string.Empty;
    public string DisplayName { get; set; } = string.Empty;
    public string PasswordHash { get; set; } = string.Empty;
    public DateTimeOffset CreatedAt { get; set; }
}

public sealed class FamilyMemberEntity
{
    public Guid Id { get; set; }
    public Guid FamilyId { get; set; }
    public Guid UserId { get; set; }
    public string Role { get; set; } = "Member";
    public DateTimeOffset JoinedAt { get; set; }
}

public sealed class SharedExpenseEntity
{
    public Guid Id { get; set; }
    public Guid FamilyId { get; set; }
    public Guid CreatedBy { get; set; }
    public string Title { get; set; } = string.Empty;
    public string Category { get; set; } = "Other";
    public decimal Amount { get; set; }
    public DateOnly ExpenseDate { get; set; }
    public string? Note { get; set; }
    public string Visibility { get; set; } = "Family";
    public DateTimeOffset CreatedAt { get; set; }
}

public sealed class SharedIncomeEntity { public Guid Id { get; set; } public Guid FamilyId { get; set; } public Guid CreatedBy { get; set; } public string Title { get; set; } = string.Empty; public decimal Amount { get; set; } public DateOnly IncomeDate { get; set; } public string? Note { get; set; } public DateTimeOffset CreatedAt { get; set; } }
public sealed class BudgetEntity { public Guid Id { get; set; } public Guid FamilyId { get; set; } public string Category { get; set; } = string.Empty; public int Year { get; set; } public int Month { get; set; } public decimal Amount { get; set; } public DateTimeOffset CreatedAt { get; set; } }
public sealed class ExpenseCategoryEntity { public Guid Id { get; set; } public Guid FamilyId { get; set; } public string Name { get; set; } = string.Empty; public DateTimeOffset CreatedAt { get; set; } }
public sealed class FamilyWorkSnapshotEntity { public Guid Id { get; set; } public Guid FamilyId { get; set; } public Guid SyncedBy { get; set; } public string SourceWorkId { get; set; } = string.Empty; public string WorkName { get; set; } = string.Empty; public string WorkType { get; set; } = string.Empty; public string SalaryDescription { get; set; } = string.Empty; public DateTimeOffset SyncedAt { get; set; } }
