namespace WorkTracker.Api.Domain;

public sealed record User(
    Guid Id,
    string Email,
    string DisplayName,
    DateTimeOffset CreatedAt);
