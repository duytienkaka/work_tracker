using Microsoft.EntityFrameworkCore;
using Microsoft.EntityFrameworkCore.Design;

namespace WorkTracker.Api.Data;

public sealed class WorkTrackerDbContextFactory : IDesignTimeDbContextFactory<WorkTrackerDbContext>
{
    public WorkTrackerDbContext CreateDbContext(string[] args)
    {
        var options = new DbContextOptionsBuilder<WorkTrackerDbContext>()
            .UseSqlServer("Server=(localdb)\\mssqllocaldb;Database=WorkTrackerDesign;Trusted_Connection=True;TrustServerCertificate=True")
            .Options;
        return new WorkTrackerDbContext(options);
    }
}
