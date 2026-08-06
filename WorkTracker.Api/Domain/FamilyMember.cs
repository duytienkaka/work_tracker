namespace WorkTracker.Api.Domain;

public enum FamilyRole
{
    Owner,
    Admin,
    Member,
}

public sealed record FamilyMember(
    Guid Id,
    Guid FamilyId,
    Guid UserId,
    FamilyRole Role,
    DateTimeOffset JoinedAt);
