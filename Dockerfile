# ─── Build Stage ─────────────────────────────────────────────────────────────
# Use the full .NET 10 SDK image which includes build tools, CLI, and NuGet
FROM mcr.microsoft.com/dotnet/sdk:10.0 AS build
WORKDIR /src

# Copy solution and all .csproj files first.
# This allows Docker to cache the layer — if no .csproj changes,
# the restore/build cache is reused on subsequent builds.
COPY MyApp.slnx .
COPY MyApp.Api/MyApp.Api.csproj MyApp.Api/
COPY MyApp.Core/MyApp.Core.csproj MyApp.Core/
COPY MyApp.Tests/MyApp.Tests.csproj MyApp.Tests/

# Copy all remaining source files into the container
COPY . .

# Build the entire solution in Release mode.
# NOTE: dotnet restore is intentionally omitted as a separate step —
# dotnet build runs restore implicitly, which avoids NuGet package
# cache path issues (NETSDK1064) that occur when restore and build
# run in separate Docker layers with different working contexts.
RUN dotnet build MyApp.slnx --configuration Release

# Publish only the API project output to /app/publish.
# --no-build skips rebuilding since we already built above.
RUN dotnet publish MyApp.Api/MyApp.Api.csproj \
    --configuration Release \
    --output /app/publish \
    --no-build

# ─── Runtime Stage ───────────────────────────────────────────────────────────
# Use the lightweight ASP.NET runtime image — no SDK, smaller attack surface.
# This is the image that actually runs in production.
FROM mcr.microsoft.com/dotnet/aspnet:10.0 AS runtime
WORKDIR /app

# Copy only the published output from the build stage.
# Everything else (SDK, source code, test projects) is left behind.
COPY --from=build /app/publish .

# Start the API on container launch
ENTRYPOINT ["dotnet", "MyApp.Api.dll"]