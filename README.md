# WorkTracker.Api

Backend foundation for Work Tracker v3.

The API is intentionally separated from the Flutter application. The v3 migration will introduce:

- user accounts and authentication;
- family spaces and member roles;
- private versus shared work data;
- shared household expenses;
- synchronization between local SQLite and the server.

Current milestone exposes a health endpoint and an in-memory family contract. SQL Server persistence and authentication are added in the next milestone.

Run locally:

```powershell
dotnet run --project WorkTracker.Api
```
