using System.IdentityModel.Tokens.Jwt;
using System.Security.Claims;
using System.Text;
using Microsoft.AspNetCore.Authentication.JwtBearer;
using Microsoft.EntityFrameworkCore;
using Microsoft.IdentityModel.Tokens;
using WorkTracker.Api.Data;
using WorkTracker.Api.Security;

var builder = WebApplication.CreateBuilder(args);
builder.Services.AddOpenApi();
builder.Services.AddSingleton<PasswordHasher>();
builder.Services.AddScoped<JwtTokenService>();

var connectionString = builder.Configuration.GetConnectionString("WorkTracker");
builder.Services.AddDbContext<WorkTrackerDbContext>(options =>
{
    if (string.IsNullOrWhiteSpace(connectionString)) options.UseInMemoryDatabase("work_tracker_dev");
    else options.UseSqlServer(connectionString);
});

var jwtKey = builder.Configuration["Jwt:Key"] ?? throw new InvalidOperationException("Jwt:Key is not configured.");
builder.Services.AddAuthentication(JwtBearerDefaults.AuthenticationScheme).AddJwtBearer(options =>
{
    options.TokenValidationParameters = new TokenValidationParameters
    {
        ValidateIssuerSigningKey = true,
        IssuerSigningKey = new SymmetricSecurityKey(Encoding.UTF8.GetBytes(jwtKey)),
        ValidateIssuer = false,
        ValidateAudience = false,
        ValidateLifetime = true,
        NameClaimType = JwtRegisteredClaimNames.Sub,
    };
});
builder.Services.AddAuthorization();

var app = builder.Build();
using (var scope = app.Services.CreateScope())
{
    var db = scope.ServiceProvider.GetRequiredService<WorkTrackerDbContext>();
    await db.Database.EnsureCreatedAsync();
    if (!string.IsNullOrWhiteSpace(connectionString))
    {
        await db.Database.ExecuteSqlRawAsync("IF OBJECT_ID(N'dbo.SharedIncomes', N'U') IS NULL CREATE TABLE dbo.SharedIncomes (Id uniqueidentifier NOT NULL PRIMARY KEY, FamilyId uniqueidentifier NOT NULL, CreatedBy uniqueidentifier NOT NULL, Title nvarchar(180) NOT NULL, Amount decimal(18,4) NOT NULL, IncomeDate date NOT NULL, Note nvarchar(1000) NULL, CreatedAt datetimeoffset NOT NULL);");
        await db.Database.ExecuteSqlRawAsync("IF OBJECT_ID(N'dbo.Budgets', N'U') IS NULL CREATE TABLE dbo.Budgets (Id uniqueidentifier NOT NULL PRIMARY KEY, FamilyId uniqueidentifier NOT NULL, Category nvarchar(80) NOT NULL, [Year] int NOT NULL, [Month] int NOT NULL, Amount decimal(18,4) NOT NULL, CreatedAt datetimeoffset NOT NULL, CONSTRAINT UQ_Budgets_Family_Period_Category UNIQUE (FamilyId, [Year], [Month], Category));");
        await db.Database.ExecuteSqlRawAsync("IF OBJECT_ID(N'dbo.ExpenseCategories', N'U') IS NULL CREATE TABLE dbo.ExpenseCategories (Id uniqueidentifier NOT NULL PRIMARY KEY, FamilyId uniqueidentifier NOT NULL, Name nvarchar(80) NOT NULL, CreatedAt datetimeoffset NOT NULL, CONSTRAINT UQ_ExpenseCategories_Family_Name UNIQUE (FamilyId, Name));");
        await db.Database.ExecuteSqlRawAsync("IF OBJECT_ID(N'dbo.FamilyWorkSnapshots', N'U') IS NULL CREATE TABLE dbo.FamilyWorkSnapshots (Id uniqueidentifier NOT NULL PRIMARY KEY, FamilyId uniqueidentifier NOT NULL, SyncedBy uniqueidentifier NOT NULL, SourceWorkId nvarchar(80) NOT NULL, WorkName nvarchar(180) NOT NULL, WorkType nvarchar(40) NOT NULL, SalaryDescription nvarchar(160) NOT NULL, SyncedAt datetimeoffset NOT NULL, CONSTRAINT UQ_FamilyWorkSnapshots_Family_Work UNIQUE (FamilyId, SourceWorkId));");
    }
}
if (app.Environment.IsDevelopment()) app.MapOpenApi();

app.MapGet("/api/health", (IConfiguration configuration) => Results.Ok(new
{
    service = "work-tracker-api",
    status = "ok",
    persistence = string.IsNullOrWhiteSpace(configuration.GetConnectionString("WorkTracker")) ? "in-memory" : "sql-server",
    version = "3.0.0-preview.3",
}));

app.MapPost("/api/auth/register", async (RegisterRequest request, WorkTrackerDbContext db, PasswordHasher hasher, JwtTokenService tokens) =>
{
    var email = request.Email.Trim().ToLowerInvariant();
    if (string.IsNullOrWhiteSpace(email) || string.IsNullOrWhiteSpace(request.Password) || request.Password.Length < 8)
        return Results.BadRequest(new { message = "Email and a password of at least 8 characters are required." });
    if (await db.Users.AnyAsync(user => user.Email == email)) return Results.Conflict(new { message = "Email is already registered." });
    var user = new UserEntity { Id = Guid.NewGuid(), Email = email, DisplayName = request.DisplayName.Trim(), PasswordHash = hasher.Hash(request.Password), CreatedAt = DateTimeOffset.UtcNow };
    db.Users.Add(user);
    await db.SaveChangesAsync();
    return Results.Ok(new AuthResponse(tokens.Create(user), user.Id, user.Email, user.DisplayName));
});

app.MapPost("/api/auth/login", async (LoginRequest request, WorkTrackerDbContext db, PasswordHasher hasher, JwtTokenService tokens) =>
{
    var email = request.Email.Trim().ToLowerInvariant();
    var user = await db.Users.SingleOrDefaultAsync(item => item.Email == email);
    if (user is null || !hasher.Verify(request.Password, user.PasswordHash)) return Results.Unauthorized();
    return Results.Ok(new AuthResponse(tokens.Create(user), user.Id, user.Email, user.DisplayName));
});

app.UseAuthentication();
app.UseAuthorization();

app.MapGet("/api/families", async (ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    var userId = UserId(principal);
    var familyIds = await db.FamilyMembers.Where(member => member.UserId == userId).Select(member => member.FamilyId).ToListAsync();
    return Results.Ok(await db.Families.Where(family => familyIds.Contains(family.Id)).OrderBy(family => family.Name).ToListAsync());
}).RequireAuthorization();

app.MapPost("/api/families", async (CreateFamilyRequest request, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    if (string.IsNullOrWhiteSpace(request.Name)) return Results.BadRequest(new { message = "Family name is required." });
    var family = new FamilyEntity { Id = Guid.NewGuid(), Name = request.Name.Trim(), CreatedAt = DateTimeOffset.UtcNow };
    db.Families.Add(family);
    db.FamilyMembers.Add(new FamilyMemberEntity { Id = Guid.NewGuid(), FamilyId = family.Id, UserId = UserId(principal), Role = "Owner", JoinedAt = DateTimeOffset.UtcNow });
    await db.SaveChangesAsync();
    return Results.Created($"/api/families/{family.Id}", family);
}).RequireAuthorization();

app.MapPost("/api/families/{familyId:guid}/members", async (Guid familyId, AddMemberRequest request, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    var currentUserId = UserId(principal);
    var owner = await db.FamilyMembers.AnyAsync(member => member.FamilyId == familyId && member.UserId == currentUserId && member.Role == "Owner");
    if (!owner) return Results.Forbid();
    var user = await db.Users.SingleOrDefaultAsync(item => item.Email == request.Email.Trim().ToLowerInvariant());
    if (user is null) return Results.NotFound(new { message = "User not found." });
    if (await db.FamilyMembers.AnyAsync(member => member.FamilyId == familyId && member.UserId == user.Id)) return Results.Conflict(new { message = "User is already a member." });
    db.FamilyMembers.Add(new FamilyMemberEntity { Id = Guid.NewGuid(), FamilyId = familyId, UserId = user.Id, Role = "Member", JoinedAt = DateTimeOffset.UtcNow });
    await db.SaveChangesAsync();
    return Results.Ok(new { user.Id, user.Email, user.DisplayName, role = "Member" });
}).RequireAuthorization();

app.MapGet("/api/families/{familyId:guid}/members", async (Guid familyId, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    if (!await IsMember(db, familyId, UserId(principal))) return Results.Forbid();
    return Results.Ok(await db.FamilyMembers.Where(member => member.FamilyId == familyId)
        .Join(db.Users, member => member.UserId, user => user.Id, (member, user) => new { user.Id, user.Email, user.DisplayName, member.Role, member.JoinedAt })
        .OrderBy(member => member.DisplayName).ToListAsync());
}).RequireAuthorization();

app.MapDelete("/api/families/{familyId:guid}/members/{memberId:guid}", async (Guid familyId, Guid memberId, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    var ownerId = UserId(principal);
    if (!await db.FamilyMembers.AnyAsync(member => member.FamilyId == familyId && member.UserId == ownerId && member.Role == "Owner")) return Results.Forbid();
    var memberToRemove = await db.FamilyMembers.SingleOrDefaultAsync(member => member.FamilyId == familyId && member.UserId == memberId);
    if (memberToRemove is null) return Results.NotFound();
    if (memberToRemove.Role == "Owner") return Results.BadRequest(new { message = "The family owner cannot be removed." });
    db.FamilyMembers.Remove(memberToRemove);
    await db.SaveChangesAsync();
    return Results.NoContent();
}).RequireAuthorization();

app.MapPatch("/api/families/{familyId:guid}/members/{memberId:guid}/role", async (Guid familyId, Guid memberId, UpdateRoleRequest request, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    var ownerId = UserId(principal);
    if (!await db.FamilyMembers.AnyAsync(item => item.FamilyId == familyId && item.UserId == ownerId && item.Role == "Owner")) return Results.Forbid();
    if (request.Role is not ("Member" or "Editor" or "Viewer")) return Results.BadRequest(new { message = "Role must be Member, Editor or Viewer." });
    var member = await db.FamilyMembers.SingleOrDefaultAsync(item => item.FamilyId == familyId && item.UserId == memberId);
    if (member is null) return Results.NotFound();
    if (member.Role == "Owner") return Results.BadRequest(new { message = "The family owner role cannot be changed." });
    member.Role = request.Role; await db.SaveChangesAsync(); return Results.Ok(new { member.UserId, member.Role });
}).RequireAuthorization();

app.MapGet("/api/families/{familyId:guid}/expenses", async (Guid familyId, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    if (!await IsMember(db, familyId, UserId(principal))) return Results.Forbid();
    return Results.Ok(await db.SharedExpenses.AsNoTracking()
        .Where(expense => expense.FamilyId == familyId)
        .OrderByDescending(expense => expense.ExpenseDate)
        .ThenByDescending(expense => expense.CreatedAt)
        .ToListAsync());
}).RequireAuthorization();

app.MapPost("/api/families/{familyId:guid}/expenses", async (Guid familyId, CreateExpenseRequest request, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    var userId = UserId(principal);
    if (!await IsMember(db, familyId, userId)) return Results.Forbid();
    if (string.IsNullOrWhiteSpace(request.Title) || request.Amount <= 0) return Results.BadRequest(new { message = "Title and a positive amount are required." });
    var expense = new SharedExpenseEntity
    {
        Id = Guid.NewGuid(), FamilyId = familyId, CreatedBy = userId,
        Title = request.Title.Trim(), Category = string.IsNullOrWhiteSpace(request.Category) ? "Other" : request.Category.Trim(),
        Amount = request.Amount, ExpenseDate = request.ExpenseDate, Note = request.Note?.Trim(),
        Visibility = request.Visibility is "Private" or "Family" ? request.Visibility : "Family",
        CreatedAt = DateTimeOffset.UtcNow,
    };
    db.SharedExpenses.Add(expense);
    await db.SaveChangesAsync();
    return Results.Created($"/api/families/{familyId}/expenses/{expense.Id}", expense);
}).RequireAuthorization();

app.MapGet("/api/families/{familyId:guid}/dashboard", async (Guid familyId, DateOnly? from, DateOnly? to, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    if (!await IsMember(db, familyId, UserId(principal))) return Results.Forbid();
    var start = from ?? new DateOnly(DateTime.UtcNow.Year, DateTime.UtcNow.Month, 1);
    var end = to ?? start.AddMonths(1).AddDays(-1);
    var expenses = await db.SharedExpenses.AsNoTracking().Where(item => item.FamilyId == familyId && item.ExpenseDate >= start && item.ExpenseDate <= end).ToListAsync();
    return Results.Ok(new { from = start, to = end, totalExpense = expenses.Sum(item => item.Amount), transactionCount = expenses.Count, byCategory = expenses.GroupBy(item => item.Category).Select(group => new { category = group.Key, total = group.Sum(item => item.Amount) }).OrderByDescending(item => item.total) });
}).RequireAuthorization();

app.MapPut("/api/families/{familyId:guid}/expenses/{expenseId:guid}", async (Guid familyId, Guid expenseId, UpdateExpenseRequest request, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    var userId = UserId(principal);
    if (!await IsMember(db, familyId, userId)) return Results.Forbid();
    var expense = await db.SharedExpenses.SingleOrDefaultAsync(item => item.Id == expenseId && item.FamilyId == familyId);
    if (expense is null) return Results.NotFound();
    if (expense.CreatedBy != userId && !await db.FamilyMembers.AnyAsync(item => item.FamilyId == familyId && item.UserId == userId && item.Role == "Owner")) return Results.Forbid();
    if (string.IsNullOrWhiteSpace(request.Title) || request.Amount <= 0) return Results.BadRequest(new { message = "Title and a positive amount are required." });
    expense.Title = request.Title.Trim(); expense.Category = request.Category.Trim(); expense.Amount = request.Amount; expense.ExpenseDate = request.ExpenseDate; expense.Note = request.Note?.Trim();
    await db.SaveChangesAsync();
    return Results.Ok(expense);
}).RequireAuthorization();

app.MapDelete("/api/families/{familyId:guid}/expenses/{expenseId:guid}", async (Guid familyId, Guid expenseId, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    var userId = UserId(principal);
    if (!await IsMember(db, familyId, userId)) return Results.Forbid();
    var expense = await db.SharedExpenses.SingleOrDefaultAsync(item => item.Id == expenseId && item.FamilyId == familyId);
    if (expense is null) return Results.NotFound();
    if (expense.CreatedBy != userId && !await db.FamilyMembers.AnyAsync(item => item.FamilyId == familyId && item.UserId == userId && item.Role == "Owner")) return Results.Forbid();
    db.SharedExpenses.Remove(expense); await db.SaveChangesAsync(); return Results.NoContent();
}).RequireAuthorization();

app.MapGet("/api/families/{familyId:guid}/incomes", async (Guid familyId, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    if (!await IsMember(db, familyId, UserId(principal))) return Results.Forbid();
    return Results.Ok(await db.SharedIncomes.Where(item => item.FamilyId == familyId).OrderByDescending(item => item.IncomeDate).ToListAsync());
}).RequireAuthorization();

app.MapPost("/api/families/{familyId:guid}/incomes", async (Guid familyId, CreateIncomeRequest request, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    var userId = UserId(principal); if (!await IsMember(db, familyId, userId)) return Results.Forbid();
    if (string.IsNullOrWhiteSpace(request.Title) || request.Amount <= 0) return Results.BadRequest(new { message = "Title and a positive amount are required." });
    var income = new SharedIncomeEntity { Id = Guid.NewGuid(), FamilyId = familyId, CreatedBy = userId, Title = request.Title.Trim(), Amount = request.Amount, IncomeDate = request.IncomeDate, Note = request.Note?.Trim(), CreatedAt = DateTimeOffset.UtcNow };
    db.SharedIncomes.Add(income); await db.SaveChangesAsync(); return Results.Created($"/api/families/{familyId}/incomes/{income.Id}", income);
}).RequireAuthorization();

app.MapGet("/api/families/{familyId:guid}/budgets", async (Guid familyId, int? year, int? month, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    if (!await IsMember(db, familyId, UserId(principal))) return Results.Forbid();
    var y = year ?? DateTime.UtcNow.Year; var m = month ?? DateTime.UtcNow.Month;
    return Results.Ok(await db.Budgets.Where(item => item.FamilyId == familyId && item.Year == y && item.Month == m).OrderBy(item => item.Category).ToListAsync());
}).RequireAuthorization();

app.MapPost("/api/families/{familyId:guid}/budgets", async (Guid familyId, CreateBudgetRequest request, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    var userId = UserId(principal); if (!await db.FamilyMembers.AnyAsync(item => item.FamilyId == familyId && item.UserId == userId && item.Role == "Owner")) return Results.Forbid();
    if (string.IsNullOrWhiteSpace(request.Category) || request.Amount <= 0 || request.Month is < 1 or > 12) return Results.BadRequest(new { message = "Category, month and a positive amount are required." });
    var budget = await db.Budgets.SingleOrDefaultAsync(item => item.FamilyId == familyId && item.Category == request.Category.Trim() && item.Year == request.Year && item.Month == request.Month);
    if (budget is null) { budget = new BudgetEntity { Id = Guid.NewGuid(), FamilyId = familyId, Category = request.Category.Trim(), Year = request.Year, Month = request.Month, Amount = request.Amount, CreatedAt = DateTimeOffset.UtcNow }; db.Budgets.Add(budget); } else budget.Amount = request.Amount;
    await db.SaveChangesAsync(); return Results.Ok(budget);
}).RequireAuthorization();

app.MapGet("/api/families/{familyId:guid}/categories", async (Guid familyId, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    if (!await IsMember(db, familyId, UserId(principal))) return Results.Forbid();
    return Results.Ok(await db.ExpenseCategories.Where(item => item.FamilyId == familyId).OrderBy(item => item.Name).ToListAsync());
}).RequireAuthorization();

app.MapGet("/api/families/{familyId:guid}/work-snapshots", async (Guid familyId, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    if (!await IsMember(db, familyId, UserId(principal))) return Results.Forbid();
    return Results.Ok(await db.FamilyWorkSnapshots.Where(item => item.FamilyId == familyId).OrderBy(item => item.WorkName).ToListAsync());
}).RequireAuthorization();

app.MapPost("/api/families/{familyId:guid}/work-snapshots/sync", async (Guid familyId, SyncWorkRequest request, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    var userId = UserId(principal); if (!await IsMember(db, familyId, userId)) return Results.Forbid();
    foreach (var item in request.Works)
    {
        var snapshot = await db.FamilyWorkSnapshots.SingleOrDefaultAsync(existing => existing.FamilyId == familyId && existing.SourceWorkId == item.SourceWorkId);
        if (snapshot is null) { snapshot = new FamilyWorkSnapshotEntity { Id = Guid.NewGuid(), FamilyId = familyId, SourceWorkId = item.SourceWorkId }; db.FamilyWorkSnapshots.Add(snapshot); }
        snapshot.SyncedBy = userId; snapshot.WorkName = item.WorkName.Trim(); snapshot.WorkType = item.WorkType.Trim(); snapshot.SalaryDescription = item.SalaryDescription.Trim(); snapshot.SyncedAt = DateTimeOffset.UtcNow;
    }
    await db.SaveChangesAsync(); return Results.Ok(await db.FamilyWorkSnapshots.Where(item => item.FamilyId == familyId).OrderBy(item => item.WorkName).ToListAsync());
}).RequireAuthorization();

app.MapPost("/api/families/{familyId:guid}/categories", async (Guid familyId, CreateCategoryRequest request, ClaimsPrincipal principal, WorkTrackerDbContext db) =>
{
    var userId = UserId(principal); if (!await db.FamilyMembers.AnyAsync(item => item.FamilyId == familyId && item.UserId == userId && item.Role == "Owner")) return Results.Forbid();
    if (string.IsNullOrWhiteSpace(request.Name)) return Results.BadRequest(new { message = "Category name is required." });
    var category = new ExpenseCategoryEntity { Id = Guid.NewGuid(), FamilyId = familyId, Name = request.Name.Trim(), CreatedAt = DateTimeOffset.UtcNow }; db.ExpenseCategories.Add(category); await db.SaveChangesAsync(); return Results.Ok(category);
}).RequireAuthorization();

app.Run();

static Guid UserId(ClaimsPrincipal principal)
{
    var value = principal.FindFirstValue(JwtRegisteredClaimNames.Sub)
        ?? principal.FindFirstValue(ClaimTypes.NameIdentifier)
        ?? principal.FindFirstValue("sub");
    return Guid.Parse(value ?? throw new UnauthorizedAccessException("Missing user id claim."));
}
static Task<bool> IsMember(WorkTrackerDbContext db, Guid familyId, Guid userId) => db.FamilyMembers.AnyAsync(member => member.FamilyId == familyId && member.UserId == userId);
public sealed record RegisterRequest(string Email, string Password, string DisplayName);
public sealed record LoginRequest(string Email, string Password);
public sealed record AuthResponse(string Token, Guid UserId, string Email, string DisplayName);
public sealed record CreateFamilyRequest(string Name);
public sealed record AddMemberRequest(string Email);
public sealed record CreateExpenseRequest(string Title, string Category, decimal Amount, DateOnly ExpenseDate, string? Note, string Visibility);
public sealed record UpdateExpenseRequest(string Title, string Category, decimal Amount, DateOnly ExpenseDate, string? Note);
public sealed record CreateIncomeRequest(string Title, decimal Amount, DateOnly IncomeDate, string? Note);
public sealed record CreateBudgetRequest(string Category, int Year, int Month, decimal Amount);
public sealed record CreateCategoryRequest(string Name);
public sealed record UpdateRoleRequest(string Role);
public sealed record SyncWorkRequest(List<SyncWorkItem> Works);
public sealed record SyncWorkItem(string SourceWorkId, string WorkName, string WorkType, string SalaryDescription);
