namespace WorkTracker.Api.Domain;

public sealed record Family(
    Guid Id,
    string Name,
    DateTimeOffset CreatedAt);

public sealed class FamilyStore
{
    private readonly List<Family> _families = [];

    public IReadOnlyList<Family> All() => _families;

    public Family Create(string name)
    {
        var family = new Family(Guid.NewGuid(), name, DateTimeOffset.UtcNow);
        _families.Add(family);
        return family;
    }
}
