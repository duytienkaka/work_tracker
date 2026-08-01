# Architecture Guide

## High-level architecture

Work Tracker follows a layered architecture designed for a small-to-medium Flutter application:

- UI layer: screens and widgets
- State layer: Provider-based state management
- Repository layer: abstraction over local data access
- Persistence layer: SQLite database

## Data flow

1. User interacts with a screen.
2. The screen requests data through a Provider.
3. The Provider calls the appropriate Repository.
4. The Repository reads or writes data from SQLite.
5. The updated state is pushed back to the UI.

## Provider

Providers are responsible for exposing state and actions for each feature area such as:
- work management
- shift management
- dashboard summaries
- analytics calculations
- timeline grouping

## Repository

Repositories isolate the app from the underlying storage layer. This keeps the UI and providers from depending directly on database details.

## SQLite

All persistent data is stored locally using SQLite. This ensures the app works offline and keeps the user data on the device.

## Navigation

The app uses route-based navigation between major feature screens such as Home, Work, Shift, Timeline, Analytics, and Settings.

## Feature modules

- Home: dashboard and quick actions
- Work: create and manage work entries
- Shift: add, edit, and review shifts
- Timeline: grouped shift history
- Analytics: performance summaries and charts
- Settings: preferences and export options
